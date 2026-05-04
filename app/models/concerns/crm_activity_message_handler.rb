module CrmActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def handle_crm_stage_change(user_name)
    return unless saved_change_to_pipeline_stage_id?

    crm_stage_change_activity(user_name)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def crm_stage_change_activity(user_name)
    old_stage_id, new_stage_id = previous_changes.values_at('pipeline_stage_id')[0]
    return if old_stage_id == new_stage_id

    user = Current.executed_by.instance_of?(AutomationRule) ? I18n.t('automation.system_name') : user_name

    old_stage_name = CrmPipelineStage.find_by(id: old_stage_id)&.name || I18n.t('crm.pipeline.unknown_stage')
    new_stage_name = CrmPipelineStage.find_by(id: new_stage_id)&.name || I18n.t('crm.pipeline.unknown_stage')

    content = I18n.t('conversations.activity.crm_stage_changed', user_name: user, old_stage: old_stage_name, new_stage: new_stage_name)

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
