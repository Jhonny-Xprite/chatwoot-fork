  def initialize(account, mapping = nil)
    @account = account
    @mapping = mapping.with_indifferent_access if mapping.present?
  end

  def build_contact(params)
    params = transform_params_with_mapping(params) if @mapping.present?
    contact = find_or_initialize_contact(params)
    update_contact_attributes(params, contact)
    contact
  end

  def transform_params_with_mapping(params)
    transformed_params = { custom_attributes: {} }
    @mapping.each do |csv_header, target_field|
      next if target_field.blank? || params[csv_header].blank?

      if target_field.start_with?('custom_attribute:')
        key = target_field.split(':', 2).last
        transformed_params[:custom_attributes][key] = params[csv_header]
      else
        transformed_params[target_field.to_sym] = params[csv_header]
      end
    end
    transformed_params.with_indifferent_access
  end

  def find_or_initialize_contact(params)
    contact = find_existing_contact(params)
    contact_params = params.slice(:email, :identifier, :phone_number)
    contact_params[:phone_number] = format_phone_number(contact_params[:phone_number]) if contact_params[:phone_number].present?
    contact ||= @account.contacts.new(contact_params)
    contact
  end

  def find_existing_contact(params)
    contact = find_contact_by_identifier(params)
    contact ||= find_contact_by_email(params)
    contact ||= find_contact_by_phone_number(params)

    update_contact_with_merged_attributes(params, contact) if contact.present? && contact.valid?
    contact
  end

  def find_contact_by_identifier(params)
    return unless params[:identifier]

    @account.contacts.find_by(identifier: params[:identifier])
  end

  def find_contact_by_email(params)
    return unless params[:email]

    @account.contacts.from_email(params[:email])
  end

  def find_contact_by_phone_number(params)
    return unless params[:phone_number]

    @account.contacts.find_by(phone_number: format_phone_number(params[:phone_number]))
  end

  def format_phone_number(phone_number)
    return nil if phone_number.blank?
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def update_contact_with_merged_attributes(params, contact)
    contact.identifier = params[:identifier] if params[:identifier].present?
    contact.email = params[:email] if params[:email].present?
    contact.phone_number = format_phone_number(params[:phone_number]) if params[:phone_number].present?
    update_contact_attributes(params, contact)
    contact.save
  end

  private

  def update_contact_attributes(params, contact)
    contact.name = params[:name] if params[:name].present?
    contact.additional_attributes ||= {}
    contact.additional_attributes[:company_name] = params[:company_name] if params[:company_name].present?
    contact.additional_attributes[:city] = params[:city] if params[:city].present?

    custom_attrs = params[:custom_attributes] || {}
    other_attrs = params.except(:identifier, :email, :name, :phone_number, :custom_attributes, :company_name, :city)
    
    current_custom_attributes = contact.custom_attributes || {}
    merged_custom_attributes = current_custom_attributes.merge(custom_attrs).merge(other_attrs)
    contact.assign_attributes(custom_attributes: merged_custom_attributes)
  end
end
