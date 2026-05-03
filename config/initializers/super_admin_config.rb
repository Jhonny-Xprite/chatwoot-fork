# Este inicializador garante que o usuário definido no .env como EASYPANEL_USER
# seja automaticamente promovido a SuperAdmin no Chatwoot.
# Isso resolve o problema de acesso sem necessidade de comandos manuais.

Rails.application.config.after_initialize do
  # Usamos a variável que você já tem no .env
  admin_email = ENV.fetch('EASYPANEL_USER', 'equipe@jhonnyxprite.com')

  begin
    # Pula se estivermos compilando assets ou se o banco não estiver disponível
    next if ENV['SECRET_KEY_BASE'] == 'precompile_placeholder'
    next unless ActiveRecord::Base.connected?

    # Procuramos o usuário pelo email
    user = User.find_by(email: admin_email.downcase)

    if user
      # Se o usuário existe mas não é SuperAdmin, promovemos
      if user.type != 'SuperAdmin'
        user.update_columns(type: 'SuperAdmin')
        Rails.logger.info "[AIOX] Usuário #{admin_email} promovido a SuperAdmin com sucesso."
      end
    else
      # Se o usuário não existir ainda (primeiro boot), o log avisa
      Rails.logger.warn "[AIOX] SuperAdmin automático: Usuário #{admin_email} ainda não encontrado no banco."
    end
  rescue StandardError => e
    # Evita que erros no boot quebrem a aplicação se o banco não estiver pronto
    Rails.logger.error "[AIOX] Erro ao configurar SuperAdmin automático: #{e.message}"
  end
end
