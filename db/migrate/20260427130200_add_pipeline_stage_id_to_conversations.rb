class AddPipelineStageIdToConversations < ActiveRecord::Migration[7.0]
  def change
    add_reference :conversations, :pipeline_stage, foreign_key: { to_table: :crm_pipeline_stages }
    add_reference :conversations, :pipeline, foreign_key: { to_table: :crm_pipelines }

    add_index :conversations, [:account_id, :pipeline_stage_id, :last_activity_at], name: 'index_conversations_on_crm_pipeline_lookup',
                                                                                    order: { last_activity_at: :desc }
  end
end
