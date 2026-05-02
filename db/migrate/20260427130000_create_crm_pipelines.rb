class CreateCrmPipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_pipelines do |t|
      t.string :name, null: false
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :crm_pipelines, [:account_id, :position]
  end
end
