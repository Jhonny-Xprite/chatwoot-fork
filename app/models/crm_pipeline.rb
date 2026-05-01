class CrmPipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'CrmPipelineStage', foreign_key: 'pipeline_id', dependent: :delete_all, inverse_of: :pipeline
  has_many :conversations, foreign_key: 'pipeline_id', dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :position, presence: true

  before_validation :ensure_default_pipeline
  after_save_commit :clear_other_default_pipelines, if: :is_default?
  before_destroy :migrate_conversations_and_ensure_default

  default_scope { order(:position) }

  private

  def ensure_default_pipeline
    return unless account.present?

    self.is_default = true if account.crm_pipelines.where.not(id: id).none?
    self.position ||= (account.crm_pipelines.maximum(:position) || -1) + 1
  end

  def clear_other_default_pipelines
    # Remove o estado de padrão dos outros funis desta conta de forma segura
    account.crm_pipelines.where.not(id: id).where(is_default: true).update_all(is_default: false)
  end

  def migrate_conversations_and_ensure_default
    # MODO DE SEGURANÇA MÁXIMA
    # 1. Busca um funil de destino que não seja este mesmo
    remaining_pipelines = account.crm_pipelines.where.not(id: id)
    target_pipeline = remaining_pipelines.find_by(is_default: true) || remaining_pipelines.first

    if target_pipeline
      # 2. Busca o primeiro estágio disponível no funil de destino
      target_stage = target_pipeline.stages.first
      
      if target_stage
        # 3. Migra todas as conversas/leads para o novo funil/estágio via SQL direto (ultra seguro)
        Conversation.where(pipeline_id: id).update_all(
          pipeline_id: target_pipeline.id, 
          pipeline_stage_id: target_stage.id
        )
      end

      # 4. Se este funil era o padrão, passa o bastão para o próximo
      if is_default?
        target_pipeline.update_column(:is_default, true)
      end
    else
      # Se não houver mais nenhum funil, apenas limpa as referências para evitar erro de FK
      Conversation.where(pipeline_id: id).update_all(pipeline_id: nil, pipeline_stage_id: nil)
    end
  rescue StandardError => e
    Rails.logger.error "[CRM] Erro durante a migração preventiva da pipeline ##{id}: #{e.message}"
  end
end
