class Api::V1::Accounts::Crm::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline
  before_action :set_stage, only: [:show, :update, :destroy]

  def index
    @stages = @pipeline.stages
    authorize @stages
    render json: @stages
  end

  def create
    @stage = @pipeline.stages.build(stage_params.merge(account_id: current_account.id))
    authorize @stage
    if @stage.save
      render json: @stage, status: :created
    else
      render json: @stage.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @stage
    if @stage.update(stage_params)
      render json: @stage
    else
      render json: @stage.errors, status: :unprocessable_entity
    end
  end

  def reorder
    authorize @pipeline, :update?
    positions = params[:positions]

    if positions.blank?
      render json: { error: 'Positions must be provided' }, status: :bad_request
      return
    end

    ActiveRecord::Base.transaction do
      positions.each do |id, position|
        stage = @pipeline.stages.find(id)
        stage.update!(position: position)
      end
    end

    render json: @pipeline.stages
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    authorize @stage
    @stage.destroy
    head :no_content
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:pipeline_id])
  end

  def set_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :color, :position, :active)
  end
end
