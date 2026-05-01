class Crm::PipelineBootstrapService
  DEFAULT_PIPELINE_NAME = 'Sales Pipeline'.freeze
  DEFAULT_STAGES = [
    { name: 'New Lead', color: '#64748b' },
    { name: 'Qualified', color: '#2563eb' },
    { name: 'Proposal', color: '#7c3aed' },
    { name: 'Negotiation', color: '#f59e0b' },
    { name: 'Won', color: '#16a34a' },
    { name: 'Lost', color: '#dc2626' }
  ].freeze

  def initialize(account:)
    @account = account
  end

  def perform!
    return unless @account

    pipeline = @account.crm_pipelines.order(:position).first
    return pipeline if pipeline.present? && @account.crm_pipeline_stages.exists?

    ActiveRecord::Base.transaction do
      pipeline ||= @account.crm_pipelines.create!(
        name: DEFAULT_PIPELINE_NAME,
        position: next_pipeline_position,
        active: true,
        is_default: @account.crm_pipelines.none?
      )

      create_default_stages!(pipeline) unless @account.crm_pipeline_stages.exists?
      pipeline
    end
  end

  private

  def next_pipeline_position
    @account.crm_pipelines.maximum(:position).to_i + 1
  end

  def create_default_stages!(pipeline)
    DEFAULT_STAGES.each_with_index do |stage, index|
      pipeline.stages.create!(
        account: @account,
        name: stage[:name],
        color: stage[:color],
        position: index,
        active: true
      )
    end
  end
end
