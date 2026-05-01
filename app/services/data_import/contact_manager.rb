class DataImport < ApplicationRecord
  class ContactManager
    def initialize(account, mapping)
      @account = account
      # Normaliza o mapping: garante que todas as chaves são strings e valores são strings
      @mapping = normalize_mapping(mapping || {})
    end

    private

    def normalize_mapping(mapping)
      return {} if mapping.blank?

      # Se for hash, converte para hash com chaves strings
      mapping.to_h.each_with_object({}) do |(key, value), normalized|
        normalized[key.to_s.strip] = value.to_s.strip if key.present? && value.present?
      end
    end

    def build_contact(row)
      params = transform_row(row)
      
      # Busca contato existente para evitar duplicidade
      contact = find_existing_contact(params) || @account.contacts.new
      
      # Define como 'lead' por padrão se for novo, seguindo a lógica de CRM
      contact.contact_type = :lead if contact.new_record?

      # Lógica de Merge: Mantém dados antigos e adiciona os novos (CSV ganha em conflito)
      if contact.persisted?
        params[:custom_attributes] = (contact.custom_attributes || {}).merge(params[:custom_attributes] || {})
        params[:additional_attributes] = (contact.additional_attributes || {}).merge(params[:additional_attributes] || {})
      end

      # Atribui os parâmetros
      contact.assign_attributes(params.merge(account_id: @account.id))
      
      # Fallback de Nome: Se name for vazio, usa o Email ou Telefone como nome temporário
      # Isso evita que o registro seja rejeitado por falta de nome (obrigatório no Chatwoot)
      if contact.name.blank?
        contact.name = contact.email.presence || contact.phone_number.presence || "Contact #{Time.now.to_i}"
      end

      # Logs de auditoria para o desenvolvedor
      unless contact.valid?
        Rails.logger.error "[Import] Final Validation Failed: #{contact.errors.full_messages} | Data: #{params.slice(:email, :phone_number)}"
      end
      
      contact
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
          # Tratamento especial para telefone
          value = format_phone_number(value) if attribute == 'phone_number'
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

    def format_phone_number(phone)
      return nil if phone.blank?

      phone = phone.to_s.strip
      # Se já tem +, apenas remove espaços e caracteres inválidos
      return phone if phone.match?(/^\+\d{1,15}$/)

      # Remove tudo exceto números
      cleaned = phone.gsub(/[^\d]/, '')
      return nil if cleaned.blank?

      # Se começa com 0, provavelmente é Brasil - remove o 0 e adiciona +55
      if cleaned.start_with?('0')
        cleaned = cleaned[1..-1]
        return "+55#{cleaned}"
      end

      # Se tem menos de 10 dígitos, é inválido
      return nil if cleaned.length < 10

      # Se não tem prefixo internacional, tenta adicionar +55 (Brasil)
      return "+55#{cleaned}" unless cleaned.match?(/^[1-9]\d{1,14}$/)

      "+#{cleaned}"
    end
  end
end
