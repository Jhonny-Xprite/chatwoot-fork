class CrmPipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline, class_name: 'CrmPipeline'
  has_many :conversations, foreign_key: 'pipeline_stage_id', dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: [:account_id, :pipeline_id] }
  validates :position, presence: true

  default_scope { order(:position) }
  before_validation :set_position, on: :create
  before_destroy :move_conversations_to_default_stage

  private

  def set_position
    self.position ||= (pipeline.stages.maximum(:position) || -1) + 1
  end

  def move_conversations_to_default_stage
    Rails.logger.info "[CRM] Estágio ##{id} sendo excluído. Movendo conversas para o próximo estágio disponível no pipeline ##{pipeline_id}."
    default_stage = pipeline.stages.where.not(id: id).first
    if default_stage
      count = conversations.count
      conversations.update_all(pipeline_stage_id: default_stage.id)
      Rails.logger.info "[CRM] #{count} conversas movidas para o estágio ##{default_stage.id}."
    else
      Rails.logger.warn "[CRM] Nenhum outro estágio disponível no pipeline ##{pipeline_id}. Conversas ficarão sem estágio."
    end
  end
end
