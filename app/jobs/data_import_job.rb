# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  # Ponto de entrada do Job de importação.
  # 1. Inicializa o ContactManager com o mapeamento fornecido pelo usuário.
  # 2. Inicia o processamento do arquivo e notifica o admin ao concluir.
  def perform(data_import)
    @data_import = data_import
    @contact_manager = DataImport::ContactManager.new(@data_import.account, @data_import.mapping)
    begin
      process_import_file
      send_import_notification_to_admin
    rescue CSV::MalformedCSVError => e
      Rails.logger.error "[CRM] Arquivo CSV malformado no DataImport ##{@data_import.id}: #{e.message}"
      handle_csv_error(e)
    rescue StandardError => e
      Rails.logger.error "[CRM] Erro inesperado no DataImport ##{@data_import.id}: #{e.message}"
      @data_import.update!(status: :failed)
      raise e
    end
  end

  private

  def process_import_file
    Rails.logger.info "[CRM] Iniciando processamento do DataImport ##{@data_import.id}"
    @data_import.update!(status: :processing)
    contacts, rejected_contacts = parse_csv_and_build_contacts

    import_contacts(contacts)
    update_data_import_status(contacts.length, rejected_contacts.length)
    save_failed_records_csv(rejected_contacts)
    Rails.logger.info "[CRM] Finalizado DataImport ##{@data_import.id}: #{contacts.length} sucessos, #{rejected_contacts.length} rejeições"
  end

  # Lê o CSV e constrói objetos Contact sem salvar no DB ainda.
  # Normalização: Remove espaços em branco das chaves para bater com o mapping do frontend.
  def parse_csv_and_build_contacts
    contacts = []
    rejected_contacts = []

    with_import_file do |file|
      csv_reader(file).each do |row|
        # Normaliza os dados do row: limpa espaços nas chaves para sincronizar com o mapping
        normalized_row = row.to_h.each_with_object({}) do |(key, value), normalized|
          normalized_key = key&.strip.to_s
          normalized[normalized_key] = value
        end
        normalized_row.default_proc = proc { |h, k| h[k.to_s] if k.is_a?(Symbol) }

        current_contact = @contact_manager.build_contact(normalized_row.with_indifferent_access)
        if current_contact.valid?
          contacts << current_contact
        else
          append_rejected_contact(row, current_contact, rejected_contacts)
        end
      end
    end

    [contacts, rejected_contacts]
  end

  def append_rejected_contact(row, contact, rejected_contacts)
    line_number = rejected_contacts.length + 2 # +2 porque 1 é header, +1 para display
    error_messages = contact.errors.full_messages

    # FOCO NO TELEFONE: Enriquece mensagens com detalhes específicos
    detailed_errors = error_messages.map do |msg|
      if msg.include?('Phone number')
        # Mostra qual era o telefone que foi rejeitado
        provided = row['phone_number'] || row['telefone'] || 'vazio'
        "TELEFONE INVÁLIDO: '#{provided}' - #{msg} (necessário para WhatsApp)"
      elsif msg.include?('email')
        "Email: '#{contact.email}' - #{msg}"
      elsif msg.include?('identifier')
        "Identifier: '#{contact.identifier}' - #{msg}"
      else
        msg
      end
    end

    row['csv_line_number'] = line_number
    row['original_phone'] = row['phone_number'] || row['telefone'] || ''
    row['errors'] = detailed_errors.join(' | ')
    rejected_contacts << row

    # Log detalhado para debug de telefone
    if error_messages.any? { |m| m.include?('Phone number') }
      Rails.logger.warn "[DataImport] Line #{line_number} REJECTED - INVALID PHONE: '#{row['original_phone']}'"
    else
      Rails.logger.warn "[DataImport] Line #{line_number} rejected: #{row['errors']}"
    end
  end

  # Executa a inserção/atualização massiva (Upsert).
  # conflict_target: [:account_id, :email] garante que não duplicamos contatos na mesma conta.
  # validate: false é usado aqui porque já validamos individualmente no parse_csv.
  def import_contacts(contacts)
    return if contacts.blank?

    Rails.logger.info "[DataImport] Processing #{contacts.length} contacts..."
    contacts.each_with_index do |contact, idx|
      Rails.logger.debug "[DataImport] Contact #{idx + 1}: email=#{contact.email.inspect}, phone=#{contact.phone_number.inspect}, name=#{contact.name.inspect}"
    end

    result = Contact.import(
      contacts,
      synchronize: contacts,
      on_duplicate_key_update: {
        conflict_target: [:account_id, :email],
        columns: [:phone_number, :name, :additional_attributes, :custom_attributes, :contact_type, :updated_at]
      },
      track_validation_failures: true,
      validate: false,
      batch_size: 1000
    )
    Rails.logger.info "[DataImport] Completed - Inserted: #{result.num_inserts}, Failed: #{result.failed_instances.size}"

    if result.failed_instances.any?
      Rails.logger.error "[DataImport] Failed instances: #{result.failed_instances.inspect}"
    end
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def save_failed_records_csv(rejected_contacts)
    csv_data = generate_csv_data(rejected_contacts)
    return if csv_data.blank?

    @data_import.failed_records.attach(io: StringIO.new(csv_data), filename: "#{Time.zone.today.strftime('%Y%m%d')}_contacts.csv",
                                       content_type: 'text/csv')
  end

  def generate_csv_data(rejected_contacts)
    headers = csv_headers
    headers << 'errors'
    return if rejected_contacts.blank?

    CSV.generate do |csv|
      csv << headers
      rejected_contacts.each do |record|
        csv << record
      end
    end
  end

  def handle_csv_error(error) # rubocop:disable Lint/UnusedMethodArgument
    @data_import.update!(status: :failed)
    send_import_failed_notification_to_admin
  end

  def send_import_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_complete(@data_import).deliver_later
  end

  def send_import_failed_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_failed.deliver_later
  end

  def csv_headers
    header_row = nil
    with_import_file do |file|
      header_row = csv_reader(file).first
    end
    header_row&.headers || []
  end

  def csv_reader(file)
    file.rewind
    raw_data = file.read
    utf8_data = raw_data.force_encoding('UTF-8')
    clean_data = utf8_data.valid_encoding? ? utf8_data : utf8_data.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')
    clean_data = clean_data.delete_prefix("\xEF\xBB\xBF")

    CSV.new(StringIO.new(clean_data), headers: true)
  end

  def with_import_file
    temp_dir = Rails.root.join('tmp/imports')
    FileUtils.mkdir_p(temp_dir)

    @data_import.import_file.open(tmpdir: temp_dir) do |file|
      file.binmode
      yield file
    end
  end
end
