class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline, only: [:show, :update, :destroy]

  def index
    # MODO DE SEGURANÇA: O bootstrap e o healer não podem derrubar a listagem principal
    begin
      if current_account.feature_enabled?('crm')
        bootstrap_service = Crm::PipelineBootstrapService.new(account: current_account)
        bootstrap_service.perform!
        bootstrap_service.heal_orphaned_conversations!
      end
    rescue StandardError => e
      Rails.logger.error "[CRM] Falha crítica no bootstrap/healer: #{e.message}"
    end

    @pipelines = current_account.crm_pipelines.to_a
    authorize :crm_pipeline, :index?
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
      invalidate_cache
      render json: @pipeline, status: :created
    else
      render json: @pipeline.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @pipeline
    if @pipeline.update(pipeline_params)
      invalidate_cache
      render json: @pipeline
    else
      render json: @pipeline.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pipeline

    # Tentativa de migração atômica via modelo
    begin
      @pipeline.destroy!
      invalidate_cache
      head :no_content
    rescue StandardError => e
      Rails.logger.error "[CRM] Erro ao deletar pipeline ##{@pipeline.id}: #{e.message}"
      render json: { error: "Erro interno ao excluir pipeline: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:id])
  end

  def invalidate_cache
    Rails.cache.delete("account_#{current_account.id}_crm_pipelines")
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :position, :active, :is_default)
  end
end
