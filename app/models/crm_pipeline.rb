class CrmPipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'CrmPipelineStage', foreign_key: 'pipeline_id', dependent: :destroy, inverse_of: :pipeline
  has_many :conversations, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :position, presence: true

  before_validation :ensure_default_pipeline
  after_save_commit :clear_other_default_pipelines, if: :is_default?

  default_scope { order(:position) }

  private

  def ensure_default_pipeline
    self.is_default = true if account.present? && account.crm_pipelines.where.not(id: id).none?
  end

  def clear_other_default_pipelines
    account.crm_pipelines.where.not(id: id).where(is_default: true).update_all(is_default: false)
  end
end
