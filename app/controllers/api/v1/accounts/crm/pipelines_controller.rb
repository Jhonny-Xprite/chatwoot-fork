class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline, only: [:show, :update, :destroy]

  def index
    @pipelines = Rails.cache.fetch("account_#{current_account.id}_crm_pipelines", expires_in: 1.hour) do
      bootstrap_service = Crm::PipelineBootstrapService.new(account: current_account)
      if current_account.feature_enabled?('crm')
        bootstrap_service.perform!
        bootstrap_service.heal_orphaned_conversations!
      end
      current_account.crm_pipelines.to_a
    end
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
      Rails.cache.delete("account_#{current_account.id}_crm_pipelines")
      render json: @pipeline, status: :created
    else
      render json: @pipeline.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @pipeline
    if @pipeline.update(pipeline_params)
      Rails.cache.delete("account_#{current_account.id}_crm_pipelines")
      render json: @pipeline
    else
      render json: @pipeline.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pipeline
    @pipeline.destroy!
    Rails.cache.delete("account_#{current_account.id}_crm_pipelines")
    head :no_content
  rescue ActiveRecord::InvalidForeignKey => e
    render json: { error: "Não é possível excluir esta pipeline porque existem registros associados que não puderam ser migrados. Detalhes: #{e.message}" }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :position, :active, :is_default)
  end
end
