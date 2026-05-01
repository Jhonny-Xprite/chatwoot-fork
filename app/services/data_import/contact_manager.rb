class ContactImportManager
  def initialize(account, mapping)
    @account = account
    @mapping = mapping || {}
  end

  def build_contact(row)
    params = transform_row(row)
    
    # Procura contato existente por email ou telefone se disponível
    contact = find_existing_contact(params) || @account.contacts.new
    
    # Aplica os atributos usando a lógica padrão do Rails/Chatwoot
    # mesclando os atributos customizados se o contato já existir
    if contact.persisted?
      params[:custom_attributes] = (contact.custom_attributes || {}).merge(params[:custom_attributes] || {})
      params[:additional_attributes] = (contact.additional_attributes || {}).merge(params[:additional_attributes] || {})
    end

    contact.assign_attributes(params.merge(account_id: @account.id))
    contact
  end

  private

  def transform_row(row)
    params = { additional_attributes: {}, custom_attributes: {} }

    @mapping.each do |header, attribute|
      next if attribute.blank? || row[header].blank?

      value = row[header]

      if Contact.column_names.include?(attribute)
        params[attribute.to_sym] = value
      elsif attribute.start_with?('custom_attribute_')
        key = attribute.sub('custom_attribute_', '')
        params[:custom_attributes][key] = value
      else
        params[:additional_attributes][attribute.to_sym] = value
      end
    end

    # Trata First Name e Last Name se mapeados separadamente
    handle_name_fields(params)
    
    # Limpa hashes vazios para não sobrescrever o que já existe no banco desnecessariamente
    params.delete(:custom_attributes) if params[:custom_attributes].blank?
    params.delete(:additional_attributes) if params[:additional_attributes].blank?
    
    params
  end

  def find_existing_contact(params)
    contact = nil
    contact = @account.contacts.from_email(params[:email]) if params[:email].present?
    contact ||= @account.contacts.find_by(phone_number: format_phone_number(params[:phone_number])) if params[:phone_number].present?
    contact
  end

  def handle_name_fields(params)
    return if params[:name].present?

    first_name = params.delete(:first_name)
    last_name = params.delete(:last_name)

    if first_name.present? || last_name.present?
      params[:name] = "#{first_name} #{last_name}".strip
    end
  end

  def format_phone_number(phone)
    return nil if phone.blank?
    phone.start_with?('+') ? phone : "+#{phone}"
  end
end
