class CreateCrmPipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_pipeline_stages do |t|
      t.string :name, null: false
      t.string :color, default: '#6366f1'
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.references :account, null: false, foreign_key: true
      t.references :pipeline, null: false, foreign_key: { to_table: :crm_pipelines }
      t.integer :conversations_count, default: 0

      t.timestamps
    end

    add_index :crm_pipeline_stages, [:pipeline_id, :position]
  end
end
