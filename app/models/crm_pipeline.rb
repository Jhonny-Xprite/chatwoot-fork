class CrmPipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'CrmPipelineStage', foreign_key: 'pipeline_id', dependent: :destroy, inverse_of: :pipeline
  has_many :conversations, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :position, presence: true

  default_scope { order(:position) }
end
