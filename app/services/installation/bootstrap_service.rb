class Installation::BootstrapService
  DEFAULT_ACCOUNT_NAME = 'Primary Workspace'.freeze
  DEFAULT_OWNER_NAME = 'Workspace Owner'.freeze

  def perform
    return unless bootstrap_requested?

    account = nil
    user = nil

    ActiveRecord::Base.transaction do
      account = find_or_create_account!
      Current.account = account

      user = find_or_create_or_update_user!
      link_user_to_account!(user, account)
      enable_crm_for_account!(account)
      Crm::PipelineBootstrapService.new(account: account).perform!
    end

    finish_installation_onboarding
    [user, account]
  ensure
    Current.account = nil
  end

  private

  def bootstrap_requested?
    owner_email.present? && owner_password.present?
  end

  def find_or_create_account!
    return Account.find_by(id: owner_account_id) if owner_account_id.present? && Account.exists?(owner_account_id)

    Account.find_by(name: owner_account_name) || Account.first || Account.create!(name: owner_account_name, locale: I18n.locale)
  end

  def find_or_create_or_update_user!
    user = User.from_email(owner_email) || User.new(email: owner_email)

    user.name = owner_name
    user.password = owner_password
    user.password_confirmation = owner_password
    user.type = 'SuperAdmin'
    user.skip_confirmation! unless user.confirmed?
    user.skip_reconfirmation! if user.persisted? && user.respond_to?(:skip_reconfirmation!)
    user.save!
    user
  end

  def link_user_to_account!(user, account)
    account_user = AccountUser.find_or_initialize_by(account_id: account.id, user_id: user.id)
    account_user.role = AccountUser.roles['administrator']
    account_user.save! if account_user.changed?
  end

  def enable_crm_for_account!(account)
    return if account.feature_enabled?('crm')

    account.enable_features!('crm')
    account.reload
  end

  def finish_installation_onboarding
    Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end

  def owner_email
    @owner_email ||= ENV.fetch('INSTALLATION_OWNER_EMAIL', '').strip.downcase
  end

  def owner_password
    @owner_password ||= ENV.fetch('INSTALLATION_OWNER_PASSWORD', '')
  end

  def owner_name
    @owner_name ||= ENV.fetch('INSTALLATION_OWNER_NAME', DEFAULT_OWNER_NAME).strip.presence || DEFAULT_OWNER_NAME
  end

  def owner_account_name
    @owner_account_name ||= ENV.fetch('INSTALLATION_OWNER_ACCOUNT_NAME', DEFAULT_ACCOUNT_NAME).strip.presence || DEFAULT_ACCOUNT_NAME
  end

  def owner_account_id
    @owner_account_id ||= ENV.fetch('INSTALLATION_OWNER_ACCOUNT_ID', '').presence
  end
end
