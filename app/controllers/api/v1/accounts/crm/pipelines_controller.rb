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
    # Executa a migração de dados manualmente antes do destroy para garantir segurança
    @pipeline.send(:migrate_conversations_and_ensure_default)
    
    if @pipeline.destroy
      head :no_content
    else
      render json: { error: @pipeline.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: "Erro interno ao excluir pipeline: #{e.message}" }, status: :internal_server_error
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :position, :active, :is_default)
  end
end
