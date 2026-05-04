require 'rails_helper'

describe Contacts::DeduplicationService do
  describe '#find_exact_duplicates' do
    it 'finds contacts with exact email match' do
      contact = create(:contact, email: 'john@example.com')
      duplicate = create(:contact, email: 'john@example.com')

      service = Contacts::DeduplicationService.new(contact)
      duplicates = service.find_exact_duplicates

      expect(duplicates).to include(hash_including(contact: duplicate, confidence: 'HIGH'))
    end

    it 'finds contacts with exact phone match' do
      contact = create(:contact, phone_number: '1234567890')
      duplicate = create(:contact, phone_number: '1234567890')

      service = Contacts::DeduplicationService.new(contact)
      duplicates = service.find_exact_duplicates

      expect(duplicates).to include(hash_including(contact: duplicate, confidence: 'HIGH'))
    end

    it 'ignores deleted contacts' do
      contact = create(:contact, email: 'john@example.com')
      deleted_duplicate = create(:contact, email: 'john@example.com', is_deleted: true)

      service = Contacts::DeduplicationService.new(contact)
      duplicates = service.find_exact_duplicates

      expect(duplicates).not_to include(hash_including(contact: deleted_duplicate))
    end

    it 'does not match contact with itself' do
      contact = create(:contact, email: 'john@example.com')

      service = Contacts::DeduplicationService.new(contact)
      duplicates = service.find_exact_duplicates

      expect(duplicates).not_to include(hash_including(contact: contact))
    end
  end

  describe '#find_fuzzy_duplicates' do
    it 'finds fuzzy name matches above threshold' do
      contact = create(:contact, name: 'John Smith')
      fuzzy_match = create(:contact, name: 'Jon Smith') # 95%+ similar

      service = Contacts::DeduplicationService.new(contact)
      duplicates = service.find_fuzzy_duplicates

      expect(duplicates).to include(hash_including(contact: fuzzy_match, confidence: 'MEDIUM'))
    end

    it 'does not match names below threshold' do
      contact = create(:contact, name: 'John Smith')
      no_match = create(:contact, name: 'Jane Doe') # <95% similar

      service = Contacts::DeduplicationService.new(contact)
      duplicates = service.find_fuzzy_duplicates

      expect(duplicates).not_to include(hash_including(contact: no_match))
    end

    it 'handles nil names gracefully' do
      contact = create(:contact, name: nil)
      other = create(:contact, name: 'John Smith')

      service = Contacts::DeduplicationService.new(contact)

      expect { service.find_fuzzy_duplicates }.not_to raise_error
    end
  end

  describe '#merge_contacts' do
    let(:source) { create(:contact, name: 'Source Contact') }
    let(:target) { create(:contact, name: 'Target Contact') }

    it 'moves all conversations from source to target' do
      # Create conversations for source
      create_list(:conversation, 3, contact_id: source.id)

      service = Contacts::DeduplicationService.new(target)
      service.merge_contacts(source.id, target.id, 'admin@example.com')

      expect(Conversation.where(contact_id: source.id).count).to eq(0)
      expect(Conversation.where(contact_id: target.id).count).to eq(3)
    end

    it 'marks source as deleted' do
      service = Contacts::DeduplicationService.new(target)
      service.merge_contacts(source.id, target.id, 'admin@example.com')

      source.reload
      expect(source.is_deleted).to be true
      expect(source.deleted_at).not_to be_nil
    end

    it 'creates audit log entry' do
      service = Contacts::DeduplicationService.new(target)
      service.merge_contacts(source.id, target.id, 'admin@example.com')

      log = ContactMergeLog.find_by(source_contact_id: source.id, target_contact_id: target.id)
      expect(log).to be_present
      expect(log.merged_by).to eq('admin@example.com')
    end

    it 'prevents self-merge' do
      service = Contacts::DeduplicationService.new(source)

      expect {
        service.merge_contacts(source.id, source.id, 'admin@example.com')
      }.to raise_error(StandardError, /Cannot merge contact with itself/)
    end

    it 'prevents duplicate merge' do
      service = Contacts::DeduplicationService.new(target)

      # First merge succeeds
      service.merge_contacts(source.id, target.id, 'admin@example.com')

      # Reload source to get fresh data
      source.reload
      source.update(is_deleted: false, deleted_at: nil)

      # Second merge should fail
      expect {
        service.merge_contacts(source.id, target.id, 'admin@example.com')
      }.to raise_error(StandardError, /already merged/)
    end

    it 'prevents circular merges' do
      # Create a chain: A → B
      contact_c = create(:contact)
      contact_d = create(:contact)

      service_b = Contacts::DeduplicationService.new(target)
      service_b.merge_contacts(source.id, target.id, 'admin@example.com')

      service_c = Contacts::DeduplicationService.new(contact_c)
      service_c.merge_contacts(target.id, contact_c.id, 'admin@example.com')

      # Now try to merge C → B (which would create a circle)
      source.reload
      source.update(is_deleted: false, deleted_at: nil)
      target.reload
      target.update(is_deleted: false, deleted_at: nil)

      service_source = Contacts::DeduplicationService.new(source)
      expect {
        service_source.merge_contacts(contact_c.id, source.id, 'admin@example.com')
      }.to raise_error(StandardError, /Circular merge/)
    end

    it 'verifies no data loss' do
      create_list(:conversation, 2, contact_id: source.id)
      create_list(:conversation, 3, contact_id: target.id)

      service = Contacts::DeduplicationService.new(target)
      service.merge_contacts(source.id, target.id, 'admin@example.com')

      target.reload
      expect(Conversation.where(contact_id: target.id).count).to eq(5)
    end
  end

  describe '#rollback_merge' do
    it 'restores deleted source contact' do
      source = create(:contact, is_deleted: true, deleted_at: Time.current)
      target = create(:contact)

      merge_log = create(:contact_merge_log, source_contact_id: source.id, target_contact_id: target.id)

      service = Contacts::DeduplicationService.new(source)
      service.rollback_merge(merge_log.id)

      source.reload
      expect(source.is_deleted).to be false
      expect(source.deleted_at).to be_nil
    end
  end
end
