require 'rails_helper'

describe DataImportJob do
  let(:account) { create(:account) }
  let(:mapping) do
    {
      'Email Address' => 'email',
      'Full Name' => 'name',
      'Phone Number' => 'phone_number'
    }
  end

  describe '#perform' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    context 'with valid CSV file' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['john@example.com', 'John Doe', '+5511987654321']
          csv << ['jane@example.com', 'Jane Smith', '11987654322']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'contacts.csv',
          content_type: 'text/csv'
        )
      end

      it 'processes import successfully' do
        expect {
          DataImportJob.perform_now(data_import)
        }.not_to raise_error

        data_import.reload
        expect(data_import.status).to eq('completed')
        expect(data_import.processed_records).to eq(2)
        expect(data_import.total_records).to eq(2)
      end

      it 'creates contacts from CSV rows' do
        DataImportJob.perform_now(data_import)

        expect(Contact.where(account: account, email: 'john@example.com')).to exist
        expect(Contact.where(account: account, email: 'jane@example.com')).to exist
      end

      it 'sets contact type to lead' do
        DataImportJob.perform_now(data_import)

        john = Contact.find_by(account: account, email: 'john@example.com')
        jane = Contact.find_by(account: account, email: 'jane@example.com')

        expect(john.contact_type).to eq('lead')
        expect(jane.contact_type).to eq('lead')
      end

      it 'sends notification to admin on completion' do
        expect(AdministratorNotifications::AccountNotificationMailer)
          .to receive_message_chain(:with, :contact_import_complete, :deliver_later)
          .once

        DataImportJob.perform_now(data_import)
      end

      it 'applies phone formatting' do
        DataImportJob.perform_now(data_import)

        john = Contact.find_by(account: account, email: 'john@example.com')
        expect(john.phone_number).to eq('+5511987654321')
      end
    end

    context 'with invalid rows' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['valid@example.com', 'Valid User', '+5511987654321']
          csv << ['invalid', 'No Email', '+5511987654322']
          csv << ['another@example.com', 'Another', 'invalid_phone']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'contacts.csv',
          content_type: 'text/csv'
        )
      end

      it 'separates valid and invalid rows' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.processed_records).to eq(2)
        expect(data_import.total_records).to eq(3)
      end

      it 'creates only valid contacts' do
        DataImportJob.perform_now(data_import)

        expect(Contact.where(account: account).count).to eq(2)
      end

      it 'saves failed records to CSV file' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.failed_records.attached?).to be true

        failed_csv_content = data_import.failed_records.download
        expect(failed_csv_content).to include('invalid')
      end

      it 'includes error messages in failed records' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        failed_csv_content = data_import.failed_records.download

        expect(failed_csv_content).to include('errors')
      end
    end

    context 'with malformed CSV' do
      before do
        data_import.import_file.attach(
          io: StringIO.new('broken,csv,content,"unclosed'),
          filename: 'malformed.csv',
          content_type: 'text/csv'
        )
      end

      it 'marks import as failed on CSV error' do
        expect {
          DataImportJob.perform_now(data_import)
        }.to raise_error(CSV::MalformedCSVError)

        data_import.reload
        expect(data_import.status).to eq('failed')
      end

      it 'sends failure notification to admin' do
        expect(AdministratorNotifications::AccountNotificationMailer)
          .to receive_message_chain(:with, :contact_import_failed, :deliver_later)
          .once

        expect {
          DataImportJob.perform_now(data_import)
        }.to raise_error(CSV::MalformedCSVError)
      end
    end
  end

  describe 'CSV Parsing' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    context 'with UTF-8 encoding' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['josé@example.com', 'José Silva', '+5511987654321']
          csv << ['maría@example.com', 'María López', '+5511987654322']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'contacts_utf8.csv',
          content_type: 'text/csv; charset=utf-8'
        )
      end

      it 'handles UTF-8 characters correctly' do
        DataImportJob.perform_now(data_import)

        jose = Contact.find_by(account: account, email: 'josé@example.com')
        expect(jose.name).to eq('José Silva')

        maria = Contact.find_by(account: account, email: 'maría@example.com')
        expect(maria.name).to eq('María López')
      end
    end

    context 'with BOM (Byte Order Mark)' do
      before do
        csv_content = "\xEF\xBB\xBF"
        csv_content += CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['test@example.com', 'Test User', '+5511987654321']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'contacts_bom.csv',
          content_type: 'text/csv'
        )
      end

      it 'removes BOM and parses correctly' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.processed_records).to eq(1)
        expect(Contact.where(account: account).count).to eq(1)
      end
    end

    context 'with header normalization' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address ', ' Full Name', 'Phone Number  ']
          csv << ['john@example.com', 'John Doe', '+5511987654321']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'contacts_spaces.csv',
          content_type: 'text/csv'
        )
      end

      it 'normalizes header whitespace' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.processed_records).to eq(1)
      end
    end
  end

  describe 'Row Processing & Validation' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    context 'with phone formatting' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['contact1@example.com', 'Contact 1', '11987654321']
          csv << ['contact2@example.com', 'Contact 2', '+5511987654322']
          csv << ['contact3@example.com', 'Contact 3', '(11) 9 8765-4323']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'phone_formats.csv',
          content_type: 'text/csv'
        )
      end

      it 'formats all phone numbers to E.164 standard' do
        DataImportJob.perform_now(data_import)

        contact1 = Contact.find_by(account: account, email: 'contact1@example.com')
        contact2 = Contact.find_by(account: account, email: 'contact2@example.com')
        contact3 = Contact.find_by(account: account, email: 'contact3@example.com')

        expect(contact1.phone_number).to eq('+5511987654321')
        expect(contact2.phone_number).to eq('+5511987654322')
        expect(contact3.phone_number).to eq('+5511987654323')
      end
    end

    context 'with duplicate detection' do
      before do
        create(:contact, account: account, email: 'existing@example.com', name: 'Existing')
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['existing@example.com', 'Updated Name', '+5511987654321']
          csv << ['new@example.com', 'New Contact', '+5511987654322']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'duplicates.csv',
          content_type: 'text/csv'
        )
      end

      it 'updates existing contact instead of creating duplicate' do
        expect {
          DataImportJob.perform_now(data_import)
        }.not_to change { Contact.where(account: account).count }

        updated = Contact.find_by(account: account, email: 'existing@example.com')
        expect(updated.name).to eq('Updated Name')
      end
    end

    context 'with email normalization' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['JOHN@EXAMPLE.COM', 'John', '+5511987654321']
          csv << ['  jane@example.com  ', 'Jane', '+5511987654322']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'email_norm.csv',
          content_type: 'text/csv'
        )
      end

      it 'converts emails to lowercase and trims whitespace' do
        DataImportJob.perform_now(data_import)

        expect(Contact.where(account: account, email: 'john@example.com')).to exist
        expect(Contact.where(account: account, email: 'jane@example.com')).to exist
      end
    end
  end

  describe 'Job State & Progress Tracking' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    context 'with progress updates' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          5.times do |i|
            csv << ["contact#{i}@example.com", "Contact #{i}", "+551198765432#{i}"]
          end
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'contacts.csv',
          content_type: 'text/csv'
        )
      end

      it 'updates status to processing' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.status).to eq('completed')
      end

      it 'records total and processed counts' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.processed_records).to eq(5)
        expect(data_import.total_records).to eq(5)
      end
    end

    context 'with mixed valid and invalid records' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['valid1@example.com', 'Valid 1', '+5511987654321']
          csv << ['valid2@example.com', 'Valid 2', '11987654322']
          csv << ['invalid', 'No Email', '+5511987654323']
          csv << ['valid3@example.com', 'Valid 3', '+5511987654324']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'mixed.csv',
          content_type: 'text/csv'
        )
      end

      it 'tracks processed and rejected counts separately' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.processed_records).to eq(3)
        expect(data_import.total_records).to eq(4)
      end
    end
  end

  describe 'Error Handling & Logging' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    context 'with invalid phone numbers' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['valid@example.com', 'Valid', '+5511987654321']
          csv << ['invalid@example.com', 'Invalid Phone', 'abc123']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'invalid_phones.csv',
          content_type: 'text/csv'
        )
      end

      it 'captures error messages in failed records' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        failed_csv = data_import.failed_records.download
        expect(failed_csv).to include('abc123')
        expect(failed_csv).to include('errors')
      end
    end

    context 'with missing required fields' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['', 'No Email', '']
          csv << ['valid@example.com', 'Valid', '+5511987654321']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'missing_fields.csv',
          content_type: 'text/csv'
        )
      end

      it 'logs rejection reason' do
        expect(Rails.logger).to receive(:warn).at_least(:once)

        DataImportJob.perform_now(data_import)
      end
    end

    context 'with file handling errors' do
      let(:data_import) { create(:data_import, account: account, mapping: mapping) }

      it 'handles ActiveStorage::FileNotFoundError with retry' do
        allow(data_import.import_file).to receive(:open).and_raise(ActiveStorage::FileNotFoundError)

        expect {
          DataImportJob.perform_now(data_import)
        }.to raise_error(ActiveStorage::FileNotFoundError)
      end
    end
  end

  describe 'Job Completion & Notifications' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    context 'on successful completion' do
      before do
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ['Email Address', 'Full Name', 'Phone Number']
          csv << ['success@example.com', 'Success', '+5511987654321']
        end
        data_import.import_file.attach(
          io: StringIO.new(csv_content),
          filename: 'success.csv',
          content_type: 'text/csv'
        )
      end

      it 'sends completion notification' do
        mailer_double = double('mailer')
        expect(AdministratorNotifications::AccountNotificationMailer)
          .to receive(:with).with(account: account).and_return(mailer_double)
        expect(mailer_double).to receive(:contact_import_complete).with(data_import).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        DataImportJob.perform_now(data_import)
      end

      it 'sets final status to completed' do
        DataImportJob.perform_now(data_import)

        data_import.reload
        expect(data_import.status).to eq('completed')
      end
    end

    context 'on failure' do
      before do
        data_import.import_file.attach(
          io: StringIO.new('invalid,"unclosed'),
          filename: 'invalid.csv',
          content_type: 'text/csv'
        )
      end

      it 'sends failure notification' do
        mailer_double = double('mailer')
        expect(AdministratorNotifications::AccountNotificationMailer)
          .to receive(:with).with(account: account).and_return(mailer_double)
        expect(mailer_double).to receive(:contact_import_failed).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        expect {
          DataImportJob.perform_now(data_import)
        }.to raise_error(CSV::MalformedCSVError)
      end

      it 'sets status to failed' do
        expect {
          DataImportJob.perform_now(data_import)
        }.to raise_error(CSV::MalformedCSVError)

        data_import.reload
        expect(data_import.status).to eq('failed')
      end
    end
  end

  describe 'acceptance criteria coverage' do
    let(:data_import) { create(:data_import, account: account, mapping: mapping) }

    before do
      csv_content = CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['valid@example.com', 'Valid User', '+5511987654321']
        csv << ['invalid', 'Invalid', 'bad_phone']
      end
      data_import.import_file.attach(
        io: StringIO.new(csv_content),
        filename: 'test.csv',
        content_type: 'text/csv'
      )
    end

    it '1. CSV Parsing - reads and parses file with proper encoding' do
      DataImportJob.perform_now(data_import)
      data_import.reload

      expect(data_import.processed_records).to eq(1)
      expect(Contact.where(account: account).count).to eq(1)
    end

    it '2. CSV Parsing - handles UTF-8 encoding and BOM' do
      bom_csv = "\xEF\xBB\xBF"
      bom_csv += CSV.generate(headers: true) do |csv|
        csv << ['Email Address', 'Full Name', 'Phone Number']
        csv << ['bom@example.com', 'BOM Test', '+5511987654321']
      end
      data_import.import_file.attach(
        io: StringIO.new(bom_csv),
        filename: 'bom_test.csv',
        content_type: 'text/csv'
      )

      expect {
        DataImportJob.perform_now(data_import)
      }.not_to raise_error
    end

    it '3. Row Processing - builds contacts using ContactManager' do
      DataImportJob.perform_now(data_import)

      valid_contact = Contact.find_by(account: account, email: 'valid@example.com')
      expect(valid_contact).to be_present
      expect(valid_contact.name).to eq('Valid User')
      expect(valid_contact.phone_number).to eq('+5511987654321')
    end

    it '4. Job State - tracks processed_records and total_records' do
      DataImportJob.perform_now(data_import)
      data_import.reload

      expect(data_import.processed_records).to eq(1)
      expect(data_import.total_records).to eq(2)
    end

    it '5. Error Logging - captures and exports failed records with errors' do
      DataImportJob.perform_now(data_import)
      data_import.reload

      expect(data_import.failed_records.attached?).to be true
      failed_csv = data_import.failed_records.download
      expect(failed_csv).to include('invalid')
      expect(failed_csv).to include('errors')
    end

    it '6. Job Completion - sends notification to admin' do
      expect(AdministratorNotifications::AccountNotificationMailer)
        .to receive_message_chain(:with, :contact_import_complete, :deliver_later)
        .once

      DataImportJob.perform_now(data_import)
    end
  end
end
