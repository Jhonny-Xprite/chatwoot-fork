class CrmPipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline, class_name: 'CrmPipeline'
  has_many :conversations, foreign_key: 'pipeline_stage_id', dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: [:account_id, :pipeline_id] }
  validates :position, presence: true

  default_scope { order(:position) }
end
