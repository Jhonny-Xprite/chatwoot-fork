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
    account.crm_pipelines.where.not(id: id).where(is_default: true).update_all(is_default: false)
  end

  def migrate_conversations_and_ensure_default
    # 1. Choose a target pipeline (new default or first available)
    target_pipeline = account.crm_pipelines.where.not(id: id).find_by(is_default: true)
    target_pipeline ||= account.crm_pipelines.where.not(id: id).first

    if target_pipeline
      # Ensure the target has a default if we are deleting the current default
      target_pipeline.update(is_default: true) if is_default?

      # Find a safe stage in the target pipeline
      target_stage = target_pipeline.stages.first

      if target_stage
        conversations.update_all(pipeline_id: target_pipeline.id, pipeline_stage_id: target_stage.id)
      else
        # If target has no stages, just nullify (as per has_many :conversations, dependent: :nullify)
      end
    end

    # If no other pipelines exist, conversations will be nullified by the relation definition
  end
end
