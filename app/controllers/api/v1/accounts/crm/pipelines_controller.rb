class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline, only: [:show, :update, :destroy]

  def index
    Crm::PipelineBootstrapService.new(account: current_account).perform! if current_account.feature_enabled?('crm')
    @pipelines = current_account.crm_pipelines
    authorize @pipelines
    render json: @pipelines
  end

  def show
    authorize @pipeline
    render json: @pipeline, include: :stages
  end

  def create
    @pipeline = current_account.crm_pipelines.build(pipeline_params)
    authorize @pipeline
    if @pipeline.save
      render json: @pipeline, status: :created
    else
      render json: @pipeline.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @pipeline
    if @pipeline.update(pipeline_params)
      render json: @pipeline
    else
      render json: @pipeline.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pipeline
    @pipeline.destroy
    head :no_content
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :position, :active, :is_default)
  end
end
