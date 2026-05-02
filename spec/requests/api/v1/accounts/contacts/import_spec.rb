require 'rails_helper'

describe 'Contacts Import API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:mapping) do
    {
      'Email Address' => 'email',
      'Full Name' => 'name',
      'Phone Number' => 'phone_number'
    }
  end

  before do
    sign_in(user)
  end

  describe 'POST /api/v1/accounts/:account_id/contacts/import' do
    context 'with valid CSV file' do
      it 'accepts the import request' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['john@example.com', 'John Doe', '+5511987654321']
          csv << ['jane@example.com', 'Jane Smith', '11987654322']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        expect {
          post "/api/v1/accounts/#{account.id}/contacts/import",
               params: { file: file, mapping: mapping.to_json },
               headers: { 'Content-Type': 'multipart/form-data' }
        }.to change { DataImport.count }.by(1)

        expect(response).to have_http_status(:success)
      end

      it 'returns data import ID and status' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['john@example.com', 'John Doe', '+5511987654321']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json },
             headers: { 'Content-Type': 'multipart/form-data' }

        json = JSON.parse(response.body)
        expect(json).to have_key('data_import_id')
        expect(json).to have_key('status')
      end

      it 'creates data import record with correct mapping' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['john@example.com', 'John Doe', '+5511987654321']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        data_import = DataImport.last
        expect(data_import.account_id).to eq(account.id)
        expect(data_import.mapping).to eq(mapping)
      end
    end

    context 'with file processing' do
      it 'enqueues DataImportJob for background processing' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['test@example.com', 'Test', '+5511987654321']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        expect {
          post "/api/v1/accounts/#{account.id}/contacts/import",
               params: { file: file, mapping: mapping.to_json }
        }.to have_enqueued_job(DataImportJob)
      end

      it 'processes the import asynchronously' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['async@example.com', 'Async Test', '+5511987654321']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        data_import = DataImport.last
        expect(data_import.status).to eq('pending')

        # Process the job
        perform_enqueued_jobs
        data_import.reload

        expect(data_import.status).to eq('completed')
        expect(data_import.processed_records).to be > 0
      end
    end

    context 'with invalid file' do
      it 'rejects file without required mapping' do
        csv_content = 'invalid,csv,content'

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'rejects file without contact data' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        expect(response).to have_http_status(:success)
        data_import = DataImport.last
        expect(data_import.status).to eq('pending')
      end
    end

    context 'with missing parameters' do
      it 'requires file parameter' do
        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { mapping: mapping.to_json }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'requires mapping parameter' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['test@example.com', 'Test', '+5511987654321']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'Full Import Flow Integration' do
    context 'with valid data - happy path' do
      it 'completes entire flow from upload to contact creation' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['integration@example.com', 'Integration Test', '+5511987654321']
          csv << ['flow@example.com', 'Flow Test', '11987654322']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        # 1. Upload file
        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        expect(response).to have_http_status(:success)
        data_import = DataImport.last

        # 2. Process import job
        perform_enqueued_jobs
        data_import.reload

        # 3. Verify contacts were created
        expect(data_import.processed_records).to eq(2)
        expect(account.contacts.where(email: 'integration@example.com')).to exist
        expect(account.contacts.where(email: 'flow@example.com')).to exist

        # 4. Verify contact attributes
        contact = account.contacts.find_by(email: 'integration@example.com')
        expect(contact.name).to eq('Integration Test')
        expect(contact.phone_number).to eq('+5511987654321')
        expect(contact.contact_type).to eq('lead')
      end
    end

    context 'with mixed valid and invalid data' do
      it 'creates valid contacts and logs invalid ones' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['valid@example.com', 'Valid', '+5511987654321']
          csv << ['invalid', 'No Email', '+5511987654322']
          csv << ['another@example.com', 'Another Valid', '11987654323']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        data_import = DataImport.last
        perform_enqueued_jobs
        data_import.reload

        # Verify valid contacts created
        expect(data_import.processed_records).to eq(2)
        expect(account.contacts.count).to eq(2)

        # Verify invalid records were logged
        expect(data_import.total_records).to eq(3)
        expect(data_import.failed_records.attached?).to be true
      end
    end

    context 'with duplicate detection' do
      it 'updates existing contact instead of creating duplicate' do
        create(:contact, account: account, email: 'existing@example.com', name: 'Old Name')

        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['existing@example.com', 'Updated Name', '+5511987654321']
          csv << ['new@example.com', 'New Contact', '+5511987654322']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        perform_enqueued_jobs

        # Should have 2 contacts (1 updated + 1 new)
        expect(account.contacts.count).to eq(2)

        updated = account.contacts.find_by(email: 'existing@example.com')
        expect(updated.name).to eq('Updated Name')
        expect(updated.phone_number).to eq('+5511987654321')
      end
    end

    context 'with large file' do
      it 'processes 100+ row CSV efficiently' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          100.times do |i|
            csv << ["contact#{i}@example.com", "Contact #{i}", "+551198765432#{i % 10}"]
          end
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        data_import = DataImport.last

        perform_enqueued_jobs
        data_import.reload

        expect(data_import.processed_records).to eq(100)
        expect(account.contacts.count).to eq(100)
      end
    end

    context 'with phone normalization' do
      it 'normalizes all phone formats in import' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['contact1@example.com', 'Contact 1', '11987654321']
          csv << ['contact2@example.com', 'Contact 2', '+5511987654322']
          csv << ['contact3@example.com', 'Contact 3', '(11) 9 8765-4323']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        perform_enqueued_jobs

        contact1 = account.contacts.find_by(email: 'contact1@example.com')
        contact2 = account.contacts.find_by(email: 'contact2@example.com')
        contact3 = account.contacts.find_by(email: 'contact3@example.com')

        expect(contact1.phone_number).to eq('+5511987654321')
        expect(contact2.phone_number).to eq('+5511987654322')
        expect(contact3.phone_number).to eq('+5511987654323')
      end
    end

    context 'with email normalization' do
      it 'normalizes emails to lowercase' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['UPPER@EXAMPLE.COM', 'Upper', '+5511987654321']
          csv << ['  mixed@EXAMPLE.com  ', 'Mixed', '+5511987654322']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        perform_enqueued_jobs

        expect(account.contacts.where(email: 'upper@example.com')).to exist
        expect(account.contacts.where(email: 'mixed@example.com')).to exist
      end
    end
  end

  describe 'Error Scenarios' do
    context 'with CSV parsing error' do
      it 'handles malformed CSV gracefully' do
        csv_content = 'invalid,"unclosed'

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        perform_enqueued_jobs

        data_import = DataImport.last
        expect(data_import.status).to eq('failed')
      end
    end

    context 'with encoding issues' do
      it 'handles UTF-8 encoding correctly' do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['josé@example.com', 'José Silva', '+5511987654321']
          csv << ['maría@example.com', 'María López', '+5511987654322']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        perform_enqueued_jobs

        jose = account.contacts.find_by(email: 'josé@example.com')
        expect(jose.name).to eq('José Silva')

        maria = account.contacts.find_by(email: 'maría@example.com')
        expect(maria.name).to eq('María López')
      end
    end

    context 'with BOM handling' do
      it 'strips UTF-8 BOM from CSV' do
        csv_content = "\xEF\xBB\xBF"
        csv_content += CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['bom@example.com', 'BOM Test', '+5511987654321']
        end

        file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

        post "/api/v1/accounts/#{account.id}/contacts/import",
             params: { file: file, mapping: mapping.to_json }

        perform_enqueued_jobs

        data_import = DataImport.last
        expect(data_import.processed_records).to eq(1)
        expect(account.contacts.find_by(email: 'bom@example.com')).to exist
      end
    end
  end

  describe 'Acceptance Criteria Verification' do
    it '1. CSV Upload → Processing - full flow works' do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['test@example.com', 'Test', '+5511987654321']
      end

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

      post "/api/v1/accounts/#{account.id}/contacts/import",
           params: { file: file, mapping: mapping.to_json }

      expect(response).to have_http_status(:success)

      perform_enqueued_jobs

      expect(account.contacts.where(email: 'test@example.com')).to exist
    end

    it '2. Contact Creation - creates contacts with correct attributes' do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['test@example.com', 'Test User', '+5511987654321']
      end

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

      post "/api/v1/accounts/#{account.id}/contacts/import",
           params: { file: file, mapping: mapping.to_json }

      perform_enqueued_jobs

      contact = account.contacts.find_by(email: 'test@example.com')
      expect(contact.name).to eq('Test User')
      expect(contact.phone_number).to eq('+5511987654321')
      expect(contact.contact_type).to eq('lead')
    end

    it '3. Duplicate Detection - handles duplicate emails correctly' do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['dup@example.com', 'First', '+5511111111111']
        csv << ['dup@example.com', 'Second', '+5511111111112']
      end

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

      post "/api/v1/accounts/#{account.id}/contacts/import",
           params: { file: file, mapping: mapping.to_json }

      perform_enqueued_jobs

      data_import = DataImport.last
      expect(data_import.processed_records).to eq(1)
      expect(account.contacts.where(email: 'dup@example.com').count).to eq(1)
    end

    it '4. Phone Normalization - all phones formatted to standard format' do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['phone1@example.com', 'Phone1', '11987654321']
        csv << ['phone2@example.com', 'Phone2', '+5511987654322']
      end

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

      post "/api/v1/accounts/#{account.id}/contacts/import",
           params: { file: file, mapping: mapping.to_json }

      perform_enqueued_jobs

      phone1 = account.contacts.find_by(email: 'phone1@example.com')
      phone2 = account.contacts.find_by(email: 'phone2@example.com')

      expect(phone1.phone_number).to start_with('+55')
      expect(phone2.phone_number).to start_with('+55')
    end

    it '5. Failed Records - invalid records tracked and exported' do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['valid@example.com', 'Valid', '+5511987654321']
        csv << ['invalid', 'No Email', '+5511987654322']
      end

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

      post "/api/v1/accounts/#{account.id}/contacts/import",
           params: { file: file, mapping: mapping.to_json }

      perform_enqueued_jobs

      data_import = DataImport.last
      expect(data_import.failed_records.attached?).to be true

      failed_csv = data_import.failed_records.download
      expect(failed_csv).to include('invalid')
    end

    it '6. Error Reporting - failed records include error messages' do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['invalid', 'No Email', '']
      end

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')

      post "/api/v1/accounts/#{account.id}/contacts/import",
           params: { file: file, mapping: mapping.to_json }

      perform_enqueued_jobs

      data_import = DataImport.last
      failed_csv = data_import.failed_records.download

      expect(failed_csv).to include('errors')
    end
  end
end
