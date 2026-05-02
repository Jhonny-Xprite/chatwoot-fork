class DataImport < ApplicationRecord
  class ContactManager
    def initialize(account, mapping)
      @account = account
      # Normaliza o mapping: garante que todas as chaves são strings e valores são strings
      @mapping = normalize_mapping(mapping || {})
    end

    def build_contact(row)
      params = transform_row(row)

      # Remove valores nil para evitar sobrescrever campos com nil
      params.compact!
      params[:custom_attributes]&.compact!
      params[:additional_attributes]&.compact!

      # Busca contato existente para evitar duplicidade
      contact = find_existing_contact(params) || @account.contacts.new
      is_new = contact.new_record?

      # Define como 'lead' por padrão se for novo, seguindo a lógica de CRM
      contact.contact_type = :lead if is_new

      # Lógica de Merge: Mantém dados antigos e adiciona os novos (CSV ganha em conflito)
      if contact.persisted?
        Rails.logger.debug "[Import] Mesclando dados para contato existente ID #{contact.id} (Email: #{contact.email})"
        params[:custom_attributes] = (contact.custom_attributes || {}).merge(params[:custom_attributes] || {})
        params[:additional_attributes] = (contact.additional_attributes || {}).merge(params[:additional_attributes] || {})
      else
        Rails.logger.debug "[Import] Criando novo Lead para a conta #{@account.id}"
      end

      # Atribui os parâmetros
      contact.assign_attributes(params.merge(account_id: @account.id))

      # Fallback de Nome: Se name for vazio, usa o Email ou Telefone como nome temporário
      if contact.name.blank?
        contact.name = contact.email.presence || contact.phone_number.presence || "Contact #{Time.now.to_i}"
      end

      # Debug logging
      unless contact.valid?
        error_details = {
          errors: contact.errors.full_messages,
          email: contact.email,
          phone_number: contact.phone_number,
          name: contact.name,
          identifier: contact.identifier,
          contact_type: contact.contact_type
        }
        Rails.logger.error "[Import] Validação falhou para a linha do CSV: #{error_details.inspect}"
      end

      contact
    end

    private

    def normalize_mapping(mapping)
      return {} if mapping.blank?

      # Se for hash, converte para hash com chaves strings
      # Mantém o valor mesmo que seja vazio (o import vai validar depois)
      mapping.to_h.each_with_object({}) do |(key, value), normalized|
        next if key.blank?

        normalized_key = key.to_s.strip
        normalized_value = value.to_s.strip

        # Aceita o mapping mesmo que valor seja vazio (validação ocorre na importação)
        # Isso permite debugging melhor de qual campo não foi mapeado
        normalized[normalized_key] = normalized_value if normalized_key.present?
      end
    end

    def transform_row(row)
      transformed = { additional_attributes: {}, custom_attributes: {} }

      @mapping.each do |header, attribute|
        next if attribute.blank?

        # Normaliza header: remove espaços e trata indifferent_access
        normalized_header = header.to_s.strip
        value = (row[normalized_header] || row[header]).to_s.strip
        next if value.blank?

        if Contact.column_names.include?(attribute) || ['first_name', 'last_name'].include?(attribute)
          # Tratamento especial para telefone: usa PhoneFormatter service
          if attribute == 'phone_number'
            begin
              formatted = PhoneFormatter.format(value)
              transformed[attribute.to_sym] = formatted if formatted.present?
            rescue PhoneFormatter::PhoneFormatterError => e
              # Log o erro mas não falha - permite importação com email válido
              Rails.logger.warn "[Import] Erro ao formatar telefone '#{value}': #{e.message}"
              # Mantém valor original apenas se estiver vazio após formatting
              # Isso garante validação pelo Contact model
            end
            next
          end
          # Tratamento especial para email: trim e downcase
          if attribute == 'email'
            value = value.strip.downcase
          end
          transformed[attribute.to_sym] = value
        elsif attribute.start_with?('custom_attribute:')
          key = attribute.sub('custom_attribute:', '')
          transformed[:custom_attributes][key] = value
        else
          transformed[:additional_attributes][attribute.to_sym] = value
        end
      end

      # Sincroniza cidade e país para colunas nativas se presentes
      sync_location_fields(transformed)

      # Processa lógica de composição de nome
      handle_name_logic(transformed)

      transformed.delete(:custom_attributes) if transformed[:custom_attributes].blank?
      transformed.delete(:additional_attributes) if transformed[:additional_attributes].blank?

      transformed
    end

    def sync_location_fields(params)
      # Chatwoot usa colunas 'location' e 'country_code' para filtros rápidos
      params[:location] = params[:city] if params[:city].present?
      
      # Mapeia campos comuns de cidade/país para o JSON de atributos adicionais
      if params[:city].present? || params[:country].present?
        params[:additional_attributes][:city] ||= params[:city]
        params[:additional_attributes][:country] ||= params[:country]
      end
    end

    def handle_name_logic(params)
      return if params[:name].present?

      fname = params.delete(:first_name)
      lname = params.delete(:last_name)

      if fname.present? || lname.present?
        params[:name] = "#{fname} #{lname}".strip
      end
    end

    def find_existing_contact(params)
      return nil if params[:email].blank? && params[:phone_number].blank? && params[:identifier].blank?

      # Busca exata e segura
      if params[:email].present?
        email = params[:email].to_s.strip.downcase
        contact = @account.contacts.find_by('LOWER(email) = ?', email)
        return contact if contact
      end

      contact = @account.contacts.find_by(phone_number: params[:phone_number]) if params[:phone_number].present?
      return contact if contact

      contact = @account.contacts.find_by(identifier: params[:identifier]) if params[:identifier].present?
      contact
    end

  end
end
