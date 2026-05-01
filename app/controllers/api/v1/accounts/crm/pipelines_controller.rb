class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline, only: [:show, :update, :destroy]

  def index
    bootstrap_service = Crm::PipelineBootstrapService.new(account: current_account)
    if current_account.feature_enabled?('crm')
      bootstrap_service.perform!
      bootstrap_service.heal_orphaned_conversations!
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
    Rails.logger.info "[CRM] Criando novo pipeline para conta #{current_account.id}: #{pipeline_params[:name]}"
    @pipeline = current_account.crm_pipelines.build(pipeline_params)
    authorize @pipeline
    if @pipeline.save
      Rails.logger.info "[CRM] Pipeline ##{@pipeline.id} criado com sucesso."
      render json: @pipeline, status: :created
    else
      Rails.logger.warn "[CRM] Falha ao criar pipeline: #{@pipeline.errors.full_messages}"
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
    Rails.logger.info "[CRM] Excluindo pipeline ##{@pipeline.id} da conta #{current_account.id}"
    authorize @pipeline
    @pipeline.destroy
    Rails.logger.info "[CRM] Pipeline ##{@pipeline.id} removido."
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
