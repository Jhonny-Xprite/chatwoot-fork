class Api::V1::Accounts::Crm::PipelineConversationsController < Api::V1::Accounts::BaseController
  before_action :set_stage

  def index
    authorize @stage, :show?
    @conversations = @stage.conversations.includes(:contact, :inbox, :assignee)
    @conversations = @conversations.search_by_contact_name(params[:q]) if params[:q].present?
    @conversations = @conversations.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
    @conversations = @conversations.tagged_with(params[:labels], any: true) if params[:labels].present?

    @conversations = @conversations.page(params[:page])
                                   .per(params[:per_page] || 25)
                                   .order(last_activity_at: :desc)
  end

  # Handle moving a conversation between stages
  def update
    @conversation = current_account.conversations.find(params[:id])
    authorize @conversation
    @conversation.update!(pipeline_stage_id: @stage.id, pipeline_id: @stage.pipeline_id)
  end

  private

  def set_stage
    @stage = current_account.crm_pipeline_stages.find(params[:stage_id])
  end
end
