class CrmPipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline, class_name: 'CrmPipeline'
  has_many :conversations, foreign_key: 'pipeline_stage_id', dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: [:account_id, :pipeline_id] }
  validates :position, presence: true

  default_scope { order(:position) }

  before_destroy :move_conversations_to_default_stage

  private

  def move_conversations_to_default_stage
    default_stage = pipeline.stages.where.not(id: id).first
    return unless default_stage

    conversations.update_all(pipeline_stage_id: default_stage.id)
  end
end
