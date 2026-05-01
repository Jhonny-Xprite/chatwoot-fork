class Crm::ConversationPlacementService
  def initialize(conversation:)
    @conversation = conversation
    @account = conversation.account
  end

  def perform!
    return @conversation unless placeable?

    pipeline = default_pipeline
    return @conversation unless pipeline

    stage = pipeline.stages.where(active: true).first || pipeline.stages.first
    return @conversation unless stage

    @conversation.update!(
      pipeline_id: pipeline.id,
      pipeline_stage_id: stage.id
    )

    @conversation
  end

  private

  def placeable?
    @account.present? &&
      @account.feature_enabled?('crm') &&
      @conversation.pipeline_stage_id.blank?
  end

  def default_pipeline
    Crm::PipelineBootstrapService.new(account: @account).perform!
    @account.crm_pipelines.find_by(is_default: true) || @account.crm_pipelines.first
  end
end
