class AddIsDefaultToCrmPipelines < ActiveRecord::Migration[7.0]
  def up
    add_column :crm_pipelines, :is_default, :boolean, default: false, null: false
    add_index :crm_pipelines, [:account_id, :is_default]
    CrmPipeline.reset_column_information

    Account.find_each do |account|
      default_pipeline = account.crm_pipelines.order(:position).first
      default_pipeline&.update_columns(is_default: true)
    end
  end

  def down
    remove_index :crm_pipelines, [:account_id, :is_default]
    remove_column :crm_pipelines, :is_default
  end
end
