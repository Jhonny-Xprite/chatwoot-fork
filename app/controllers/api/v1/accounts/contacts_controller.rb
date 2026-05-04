# rubocop:disable Metrics/ClassLength
class Api::V1::Accounts::ContactsController < Api::V1::Accounts::BaseController
  include Sift
  sort_on :email, type: :string
  sort_on :name, internal_name: :order_on_name, type: :scope, scope_params: [:direction]
  sort_on :phone_number, type: :string
  sort_on :last_activity_at, internal_name: :order_on_last_activity_at, type: :scope, scope_params: [:direction]
  sort_on :created_at, internal_name: :order_on_created_at, type: :scope, scope_params: [:direction]
  sort_on :company_name, internal_name: :order_on_company_name, type: :scope, scope_params: [:direction]
  sort_on :city, internal_name: :order_on_city, type: :scope, scope_params: [:direction]
  sort_on :country, internal_name: :order_on_country_name, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 100

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :active, :search, :filter]
  before_action :fetch_contact, only: [:show, :update, :destroy, :avatar, :contactable_inboxes, :destroy_custom_attributes]
  before_action :set_include_contact_inboxes, only: [:index, :active, :search, :filter, :show, :update]

  # Lista contatos com paginação e ordenação dinâmica via Sift.
  # Etapa crucial para a visualização da tabela principal do CRM.
  def index
    Rails.logger.info "[CRM] Listando contatos para conta #{Current.account.id}, página: #{params[:page]}"
    @contacts = fetch_contacts(resolved_contacts)
    @contacts_count = @contacts.total_count
  end

  # Busca contatos por nome, email, telefone ou identificador.
  # Utiliza ILIKE para buscas case-insensitive (PostgreSQL).
  def search
    Rails.logger.info "[CRM] Pesquisa de contato iniciada: q=#{params[:q]}"
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    contacts = Current.account.contacts.where(
      'name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR contacts.identifier LIKE :search',
      search: "%#{params[:q].strip}%"
    )
    @contacts = fetch_contacts_with_has_more(contacts)
  end

  # Processa a importação massiva de contatos (Leads).
  # 1. Valida a presença do arquivo e do mapeamento de colunas.
  # 2. Cria um registro em DataImport e anexa o arquivo.
  # 3. O processamento real ocorre de forma assíncrona via DataImportJob.
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def import
    Rails.logger.info "[CRM] Importação de arquivo iniciada pela conta #{Current.account.id}"
    render json: { error: I18n.t('errors.contacts.import.failed') }, status: :unprocessable_entity and return if params[:import_file].blank?

    mapping = params[:mapping]
    # Garante que o mapping é um hash
    mapping = JSON.parse(mapping) if mapping.is_a?(String)
    mapping = {} if mapping.blank?

    # Valida se o mapping tem pelo menos um campo mapeado
    if mapping.is_a?(Hash) && mapping.empty?
      Rails.logger.warn '[CRM] Importação falhou: mapeamento de colunas vazio'
      render json: { error: 'Please map at least one column' }, status: :unprocessable_entity and return
    end

    ActiveRecord::Base.transaction do
      import = Current.account.data_imports.create!(data_type: 'contacts', mapping: mapping)
      import.import_file.attach(params[:import_file])
      Rails.logger.info "[CRM] DataImport ##{import.id} criado e aguardando processamento com mapeamento: #{mapping.inspect}"
    end

    head :ok
  end

  def export
    column_names = params['column_names']
    filter_params = { :payload => params.permit!['payload'], :label => params.permit!['label'] }
    Account::ContactsExportJob.perform_later(Current.account.id, Current.user.id, column_names, filter_params)
    head :ok, message: I18n.t('errors.contacts.export.success')
  end

  # returns online contacts
  def active
    contacts = Current.account.contacts.where(id: ::OnlineStatusTracker
                  .get_available_contact_ids(Current.account.id))
    @contacts = fetch_contacts(contacts)
    @contacts_count = @contacts.total_count
  end

  def show; end

  # Executa filtragem avançada de contatos baseada em atributos customizados e metadados.
  # Delega a lógica complexa para o FilterService para garantir separação de responsabilidades.
  def filter
    Rails.logger.info "[CRM] Aplicando filtros avançados na conta #{Current.account.id}"
    result = ::Contacts::FilterService.new(Current.account, Current.user, params.permit!).perform
    contacts = result[:contacts]
    @contacts_count = result[:count]
    @contacts = fetch_contacts(contacts)
    Rails.logger.info "[CRM] Filtro concluído: #{@contacts_count} contatos encontrados"
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    Rails.logger.error "[CRM] Erro de validação no filtro: #{e.message}"
    render_could_not_create_error(e.message)
  end

  def contactable_inboxes
    @all_contactable_inboxes = Contacts::ContactableInboxesService.new(contact: @contact).get
    @contactable_inboxes = @all_contactable_inboxes.select { |contactable_inbox| policy(contactable_inbox[:inbox]).show? }
  end

  # TODO : refactor this method into dedicated contacts/custom_attributes controller class and routes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
  end

  def create
    ActiveRecord::Base.transaction do
      @contact = Current.account.contacts.new(permitted_params.except(:avatar_url))
      @contact.save!
      @contact_inbox = build_contact_inbox
      process_avatar_from_url
    end
  end

  def update
    @contact.assign_attributes(contact_update_params)
    @contact.save!
    process_avatar_from_url
  end

  def destroy
    Rails.logger.info "[CRM] Tentativa de exclusão de contato: ID #{@contact.id}"
    if ::OnlineStatusTracker.get_presence(
      @contact.account.id, 'Contact', @contact.id
    )
      Rails.logger.warn "[CRM] Exclusão negada: contato #{@contact.id} está online"
      return render_error({ message: I18n.t('contacts.online.delete', contact_name: @contact.name.capitalize) },
                          :unprocessable_entity)
    end

    @contact.destroy!
    Rails.logger.info "[CRM] Contato #{@contact.id} excluído com sucesso"
    head :ok
  end

  def avatar
    @contact.avatar.purge if @contact.avatar.attached?
    @contact
  end

  def deduplicate
    contact_id = params[:contact_id]
    render json: { error: 'contact_id is required' }, status: :unprocessable_entity and return if contact_id.blank?

    contact = Current.account.contacts.find_by(id: contact_id)
    render json: { error: 'Contact not found' }, status: :not_found and return if contact.nil?

    service = Contacts::DeduplicationService.new(contact)
    exact_duplicates = service.find_exact_duplicates
    fuzzy_duplicates = service.find_fuzzy_duplicates

    duplicates = (exact_duplicates + fuzzy_duplicates).sort_by do |d|
      confidence_rank = { 'HIGH' => 0, 'MEDIUM' => 1 }.fetch(d[:confidence], 2)
      [confidence_rank, -(d[:similarity_score] || 1.0)]
    end

    render json: {
      duplicates: duplicates.map { |d| serialize_duplicate(d) }
    }
  end

  def merge
    source_id = params[:source_contact_id]
    target_id = params[:target_contact_id]

    if source_id.blank? || target_id.blank?
      render json: { error: 'source_contact_id and target_contact_id are required' },
             status: :unprocessable_entity and return
    end

    source = Current.account.contacts.find_by(id: source_id)
    target = Current.account.contacts.find_by(id: target_id)

    render json: { error: 'Source contact not found' }, status: :not_found and return if source.nil?
    render json: { error: 'Target contact not found' }, status: :not_found and return if target.nil?

    begin
      service = Contacts::DeduplicationService.new(target)
      service.merge_contacts(source_id, target_id, Current.user.email)

      source.reload
      target.reload

      source_messages = Conversation.where(contact_id: source_id).count
      target_messages = Conversation.where(contact_id: target_id).count

      render json: {
        status: 'merged',
        source_contact: serialize_contact(source),
        target_contact: serialize_contact(target),
        source_message_count: source_messages,
        target_message_count: target_messages,
        total_message_count: source_messages + target_messages,
        merge_log_id: ContactMergeLog.where(source_contact_id: source_id, target_contact_id: target_id).first&.id
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def merge_logs
    contact_id = params[:contact_id]
    page = params[:page] || 1
    per_page = params[:per_page] || 10

    logs = if contact_id.present?
             ContactMergeLog.for_contact(contact_id)
           else
             ContactMergeLog.all
           end

    logs = logs.recent_first.page(page).per(per_page)

    render json: {
      merge_logs: logs.map { |log| serialize_merge_log(log) },
      pagination: {
        current_page: logs.current_page,
        total_pages: logs.total_pages,
        total_count: logs.total_count
      }
    }
  end

  def rollback_merge
    merge_log_id = params[:merge_log_id]
    render json: { error: 'merge_log_id is required' }, status: :unprocessable_entity and return if merge_log_id.blank?

    merge_log = ContactMergeLog.find_by(id: merge_log_id)
    render json: { error: 'Merge log not found' }, status: :not_found and return if merge_log.nil?

    begin
      service = Contacts::DeduplicationService.new(Contact.find(merge_log.source_contact_id))
      service.rollback_merge(merge_log_id)

      source = Contact.find(merge_log.source_contact_id)
      render json: {
        status: 'rolled_back',
        source_contact: serialize_contact(source),
        merge_log_id: merge_log_id
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  # TODO: Move this to a finder class
  def resolved_contacts
    return @resolved_contacts if @resolved_contacts

    @resolved_contacts = Current.account.contacts.resolved_contacts(use_crm_v2: Current.account.feature_enabled?('crm_v2'))

    @resolved_contacts = @resolved_contacts.tagged_with(params[:labels], any: true) if params[:labels].present?
    @resolved_contacts
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_contacts(contacts)
    # Build includes hash to avoid separate query when contact_inboxes are needed
    includes_hash = { avatar_attachment: [:blob] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    filtrate(contacts)
      .includes(includes_hash)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def fetch_contacts_with_has_more(contacts)
    includes_hash = { avatar_attachment: [:blob] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    # Calculate offset manually to fetch one extra record for has_more check
    offset = (@current_page.to_i - 1) * RESULTS_PER_PAGE
    results = filtrate(contacts)
              .includes(includes_hash)
              .offset(offset)
              .limit(RESULTS_PER_PAGE + 1)
              .to_a

    @has_more = results.size > RESULTS_PER_PAGE
    results = results.first(RESULTS_PER_PAGE) if @has_more
    @contacts_count = results.size
    results
  end

  def build_contact_inbox
    return if params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: inbox,
      source_id: params[:source_id]
    ).perform
  end

  def permitted_params
    params.permit(:name, :identifier, :email, :phone_number, :avatar, :blocked, :avatar_url, additional_attributes: {}, custom_attributes: {})
  end

  def contact_custom_attributes
    return @contact.custom_attributes.merge(permitted_params[:custom_attributes]) if permitted_params[:custom_attributes]

    @contact.custom_attributes
  end

  def contact_additional_attributes
    return @contact.additional_attributes.merge(permitted_params[:additional_attributes]) if permitted_params[:additional_attributes]

    @contact.additional_attributes
  end

  def contact_update_params
    permitted_params.except(:custom_attributes, :avatar_url)
                    .merge({ custom_attributes: contact_custom_attributes })
                    .merge({ additional_attributes: contact_additional_attributes })
  end

  def set_include_contact_inboxes
    @include_contact_inboxes = if params[:include_contact_inboxes].present?
                                 params[:include_contact_inboxes] == 'true'
                               else
                                 true
                               end
  end

  def fetch_contact
    contact_scope = Current.account.contacts
    contact_scope = contact_scope.includes(contact_inboxes: [:inbox]) if @include_contact_inboxes
    @contact = contact_scope.find(params[:id])
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, params[:avatar_url]) if params[:avatar_url].present?
  end

  def render_error(error, error_status)
    render json: error, status: error_status
  end

  def serialize_contact(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      message_count: Conversation.where(contact_id: contact.id).count,
      is_deleted: contact.is_deleted,
      deleted_at: contact.deleted_at
    }
  end

  def serialize_duplicate(duplicate)
    {
      contact: serialize_contact(duplicate[:contact]),
      confidence: duplicate[:confidence],
      reason: duplicate[:reason],
      similarity_score: duplicate[:similarity_score]
    }
  end

  def serialize_merge_log(merge_log)
    {
      id: merge_log.id,
      source_contact_id: merge_log.source_contact_id,
      target_contact_id: merge_log.target_contact_id,
      source_contact_name: merge_log.source_contact&.name,
      target_contact_name: merge_log.target_contact&.name,
      merged_by: merge_log.merged_by,
      merged_at: merge_log.merged_at,
      merge_data: merge_log.merge_data
    }
  end
end
# rubocop:enable Metrics/ClassLength
