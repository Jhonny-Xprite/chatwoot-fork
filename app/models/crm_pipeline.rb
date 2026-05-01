class CrmPipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'CrmPipelineStage', foreign_key: 'pipeline_id', dependent: :destroy, inverse_of: :pipeline
  has_many :conversations, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :position, presence: true

  before_validation :ensure_default_pipeline
  after_save_commit :clear_other_default_pipelines, if: :is_default?
  before_destroy :migrate_conversations_and_ensure_default

  default_scope { order(:position) }

  private

  def ensure_default_pipeline
    self.is_default = true if account.present? && account.crm_pipelines.where.not(id: id).none?
    self.position ||= (account.crm_pipelines.maximum(:position) || -1) + 1 if account.present?
  end

  def clear_other_default_pipelines
    # Remove o estado de padrão dos outros funis desta conta
    account.crm_pipelines.where.not(id: id).where(is_default: true).update_all(is_default: false)
  end

  def migrate_conversations_and_ensure_default
    # 1. Escolhe um funil de destino (o novo padrão ou o primeiro disponível)
    target_pipeline = account.crm_pipelines.where.not(id: id).find_by(is_default: true)
    target_pipeline ||= account.crm_pipelines.where.not(id: id).first

    return unless target_pipeline

    # 2. Busca o primeiro estágio disponível no funil de destino
    target_stage = target_pipeline.stages.first
    return unless target_stage

    # 3. Migra todas as conversas/leads para o novo funil/estágio
    # Usamos update_all por performance e para evitar disparar callbacks durante o destroy
    conversations.update_all(pipeline_id: target_pipeline.id, pipeline_stage_id: target_stage.id)

    # 4. Se este funil era o padrão, passa o bastão para o próximo
    if is_default?
      target_pipeline.update_column(:is_default, true)
    end
  end
end
