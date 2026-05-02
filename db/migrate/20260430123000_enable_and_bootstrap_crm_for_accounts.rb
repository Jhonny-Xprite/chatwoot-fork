class EnableAndBootstrapCrmForAccounts < ActiveRecord::Migration[7.0]
  def up
    ConfigLoader.new.process

    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each do |account|
        account.enable_features!('crm') unless account.feature_enabled?('crm')
        Crm::PipelineBootstrapService.new(account: account).perform!
      end
    end

    GlobalConfig.clear_cache
  end

  def down; end
end
