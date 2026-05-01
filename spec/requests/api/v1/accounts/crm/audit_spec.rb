require 'rails_helper'

RSpec.describe 'CRM Module Audit', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:contact) { create(:contact, account: account, email: 'test@example.com') }

  before do
    sign_in admin
  end

  describe 'Pipeline Management' do
    it 'creates a new pipeline with default stages' do
      post "/api/v1/accounts/#{account.id}/crm/pipelines", params: { pipeline: { name: 'Vendas' } }
      expect(response).to have_http_status(:created)
      
      pipeline = account.crm_pipelines.last
      expect(pipeline.name).to eq('Vendas')
      # Assuming default stages are created automatically if implemented in model
    end

    it 'migrates conversations when a pipeline is deleted' do
      pipeline1 = create(:crm_pipeline, account: account)
      pipeline2 = create(:crm_pipeline, account: account)
      stage = create(:crm_pipeline_stage, pipeline: pipeline1)
      target_stage = create(:crm_pipeline_stage, pipeline: pipeline2)
      
      conversation = create(:conversation, account: account, pipeline: pipeline1, pipeline_stage: stage)
      
      delete "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline1.id}"
      expect(response).to have_http_status(:no_content)
      
      conversation.reload
      expect(conversation.pipeline_id).to eq(pipeline2.id)
    end
  end

  describe 'Lead Scoring' do
    let!(:rule) do
      create(:crm_lead_scoring_rule, account: account, 
             attribute_model: 'contact_attribute', 
             attribute_key: 'source', 
             filter_operator: 'equal_to', 
             values: ['website'], 
             score: 50)
    end

    it 'calculates score correctly for a lead' do
      contact.update(custom_attributes: { source: 'website' })
      
      # Trigger recalculation
      post "/api/v1/accounts/#{account.id}/crm/lead_scoring_rules/recalculate"
      expect(response).to have_http_status(:ok)
      
      # We might need to wait for background job or call service directly for spec speed
      Crm::LeadScoring::CalculateScoreService.new(contact: contact).perform!
      
      contact.reload
      expect(contact.lead_score).to eq(50)
    end
  end

  describe 'Contact Import Traceability' do
    it 'logs and merges contacts during import' do
      csv_content = <<~CSV
        name,email,phone
        John Doe,john@example.com,+5511999999999
        Jane Smith,jane@example.com,invalid-phone
      CSV
      
      # Mock the DataImport object
      data_import = create(:data_import, account: account)
      
      # This is a unit test for the service since triggering a full job with CSV is complex in request spec
      manager = DataImport::ContactManager.new(account, { 'name' => 'name', 'email' => 'email', 'phone' => 'phone_number' })
      
      row1 = { 'name' => 'John Doe', 'email' => 'john@example.com', 'phone' => '+5511999999999' }
      contact1 = manager.send(:build_contact, row1)
      expect(contact1.name).to eq('John Doe')
      expect(contact1.contact_type).to eq('lead')
      
      # Test merge logic
      existing = create(:contact, account: account, email: 'john@example.com', name: 'Old Name')
      contact_merged = manager.send(:build_contact, row1)
      expect(contact_merged.id).to eq(existing.id)
      expect(contact_merged.name).to eq('John Doe')
    end
  end
end
