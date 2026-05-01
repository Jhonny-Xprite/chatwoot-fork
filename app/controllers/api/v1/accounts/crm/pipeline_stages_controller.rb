class Api::V1::Accounts::Crm::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline
  before_action :set_stage, only: [:show, :update, :destroy]

  def index
    @stages = Rails.cache.fetch("pipeline_#{@pipeline.id}_stages", expires_in: 1.hour) do
      @pipeline.stages.to_a
    end
    authorize @stages
    render json: @stages
  end

  def create
    @stage = @pipeline.stages.build(stage_params.merge(account_id: current_account.id))
    authorize @stage
    if @stage.save
      Rails.cache.delete("pipeline_#{@pipeline.id}_stages")
      render json: @stage, status: :created
    else
      render json: @stage.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @stage
    if @stage.update(stage_params)
      Rails.cache.delete("pipeline_#{@pipeline.id}_stages")
      render json: @stage
    else
      render json: @stage.errors, status: :unprocessable_entity
    end
  end

  def reorder
    authorize @pipeline, :update?
    
    # ATENÇÃO: MANTER COMO 'stages'. NÃO MUDAR PARA 'positions'.
    # O frontend envia o array completo de estágios para permitir renomear e reordenar simultaneamente.
    stages_params = params[:stages]

    if stages_params.blank? || !stages_params.is_a?(Array)
      render json: { error: 'Stages array must be provided' }, status: :bad_request
      return
    end

    ActiveRecord::Base.transaction do
      stages_params.each_with_index do |stage_data, index|
        stage = @pipeline.stages.find(stage_data[:id])
        stage.update!(
          name: stage_data[:name],
          color: stage_data[:color],
          position: index + 1,
          active: true
        )
      end
    end

    Rails.cache.delete("pipeline_#{@pipeline.id}_stages")
    render json: @pipeline.stages
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    authorize @stage
    @stage.destroy
    Rails.cache.delete("pipeline_#{@pipeline.id}_stages")
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
