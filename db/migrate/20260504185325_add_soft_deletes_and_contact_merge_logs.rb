class AddSoftDeletesAndContactMergeLogs < ActiveRecord::Migration[6.1]
  def change
    # Phase 1.1: Add soft delete columns to contacts table
    add_column :contacts, :is_deleted, :boolean, default: false, null: false
    add_column :contacts, :deleted_at, :datetime

    # Add indexes for soft delete filtering and sorting
    add_index :contacts, :is_deleted
    add_index :contacts, :deleted_at

    # Phase 1.2: Create contact_merge_logs table for audit trail
    create_table :contact_merge_logs do |t|
      t.bigint :source_contact_id, null: false
      t.bigint :target_contact_id, null: false
      t.string :merged_by
      t.json :merge_data, default: {}
      t.timestamp :merged_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    # Add indexes for merge log queries and sorting
    add_index :contact_merge_logs, [:source_contact_id, :target_contact_id]
    add_index :contact_merge_logs, :merged_at
    add_index :contact_merge_logs, :source_contact_id
    add_index :contact_merge_logs, :target_contact_id

    # Add foreign keys for data integrity
    add_foreign_key :contact_merge_logs, :contacts, column: :source_contact_id
    add_foreign_key :contact_merge_logs, :contacts, column: :target_contact_id
  end
end
