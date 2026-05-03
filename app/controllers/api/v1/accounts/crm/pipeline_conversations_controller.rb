class Api::V1::Accounts::Crm::PipelineConversationsController < Api::V1::Accounts::BaseController
  before_action :set_stage

  def index
    authorize @stage, :show?
    @conversations = @stage.conversations.includes(:contact, :inbox, :assignee, :pipeline_stage, :pipeline)
    @conversations = @conversations.search_by_contact_name(params[:q]) if params[:q].present?
    @conversations = @conversations.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
    @conversations = @conversations.tagged_with(params[:labels], any: true) if params[:labels].present?
    @conversations = @conversations.where(status: params[:status]) if params[:status].present?
    @conversations = @conversations.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    @conversations = @conversations.where(team_id: params[:team_id]) if params[:team_id].present?
    @conversations = @conversations.where(priority: params[:priority]) if params[:priority].present?

    @conversations = @conversations.page(params[:page])
                                   .per(params[:per_page] || 25)
                                   .order(last_activity_at: :desc)
  end

  # Handle moving a conversation between stages
  def update
    authorize @stage, :show?
    @conversation = current_account.conversations.find_by!(display_id: params[:id])
    old_stage_id = @conversation.pipeline_stage_id
    Rails.logger.info "[CRM] Movendo conversa ##{@conversation.display_id} do estágio #{old_stage_id} para #{@stage.id} no pipeline ##{@stage.pipeline_id}"
    @conversation.update!(pipeline_stage_id: @stage.id, pipeline_id: @stage.pipeline_id)
    render :update
  end

  private

  def set_stage
    @stage = current_account.crm_pipeline_stages.find(params[:stage_id])
  end
end
