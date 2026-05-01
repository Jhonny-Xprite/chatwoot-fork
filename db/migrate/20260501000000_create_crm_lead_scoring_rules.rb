class CreateCrmLeadScoringRules < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_lead_scoring_rules do |t|
      t.references :account, null: false, foreign_key: true
      t.string :attribute_model, null: false # contact_attribute, conversation_attribute, label
      t.string :attribute_key, null: false
      t.string :filter_operator, null: false
      t.jsonb :values, default: []
      t.integer :score, default: 0

      t.timestamps
    end

    add_column :contacts, :lead_score, :integer, default: 0
    add_index :contacts, :lead_score
  end
end
