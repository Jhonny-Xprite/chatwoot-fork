FactoryBot.define do
  factory :crm_pipeline do
    sequence(:name) { |n| "Pipeline #{n}" }
    account
    is_default { false }
  end

  factory :crm_pipeline_stage do
    sequence(:name) { |n| "Stage #{n}" }
    crm_pipeline
    account { crm_pipeline.account }
  end

  factory :crm_lead_scoring_rule do
    account
    attribute_model { 'contact_attribute' }
    attribute_key { 'source' }
    filter_operator { 'equal_to' }
    values { ['website'] }
    score { 10 }
  end
end
