require 'levenshtein'

class Contacts::DeduplicationService
  FUZZY_MATCH_THRESHOLD = 0.95

  def initialize(contact)
    @contact = contact
  end

  # Find exact match duplicates (email, phone, or both)
  def find_exact_duplicates
    duplicates = []

    # Exact email match
    if @contact.email.present?
      email_matches = Contact.where(email: @contact.email)
        .where.not(id: @contact.id)
        .where(is_deleted: false)

      email_matches.each do |match|
        duplicates << {
          contact: match,
          confidence: 'HIGH',
          reason: 'Exact email match'
        }
      end
    end

    # Exact phone match
    if @contact.phone_number.present?
      phone_matches = Contact.where(phone_number: @contact.phone_number)
        .where.not(id: @contact.id)
        .where(is_deleted: false)

      phone_matches.each do |match|
        next if duplicates.any? { |d| d[:contact].id == match.id }
        duplicates << {
          contact: match,
          confidence: 'HIGH',
          reason: 'Exact phone match'
        }
      end
    end

    duplicates
  end

  # Find fuzzy match duplicates (name similarity using Levenshtein distance)
  def find_fuzzy_duplicates
    return [] if @contact.name.blank?

    duplicates = []
    similarity_threshold = FUZZY_MATCH_THRESHOLD

    Contact.where(is_deleted: false)
      .where.not(id: @contact.id)
      .find_each do |potential_match|
        next if potential_match.name.blank?

        # Calculate similarity using Levenshtein distance
        distance = Levenshtein.distance(@contact.name.downcase, potential_match.name.downcase)
        max_length = [@contact.name.length, potential_match.name.length].max
        similarity = 1.0 - (distance.to_f / max_length)

        if similarity >= similarity_threshold
          duplicates << {
            contact: potential_match,
            confidence: 'MEDIUM',
            reason: "Name similarity: #{(similarity * 100).round(1)}%",
            similarity_score: similarity
          }
        end
      end

    duplicates.sort_by { |d| -d[:similarity_score] }
  end

  # Merge source contact into target contact
  # Returns: true if successful, raises StandardError if validation fails
  def merge_contacts(source_id, target_id, merged_by = nil)
    raise StandardError, 'Cannot merge contact with itself' if source_id == target_id

    source = Contact.find(source_id)
    target = Contact.find(target_id)

    raise StandardError, 'Source contact already deleted' if source.is_deleted?
    raise StandardError, 'Target contact already deleted' if target.is_deleted?

    # Check if this merge has already been performed
    existing_merge = ContactMergeLog.where(source_contact_id: source_id, target_contact_id: target_id).first
    raise StandardError, 'Contacts already merged' if existing_merge.present?

    # Validate merge chain (prevent circular merges)
    validate_no_circular_merge(source_id, target_id)

    # Get message counts before merge (for audit)
    source_message_count = Conversation.where(contact_id: source_id).count
    target_message_count = Conversation.where(contact_id: target_id).count

    # Move all conversations from source to target
    Conversation.where(contact_id: source_id).update_all(contact_id: target_id)

    # Mark source as deleted (soft delete)
    source.update!(
      is_deleted: true,
      deleted_at: Time.current
    )

    # Create audit log entry
    ContactMergeLog.create!(
      source_contact_id: source_id,
      target_contact_id: target_id,
      merged_by: merged_by,
      merge_data: {
        source_message_count: source_message_count,
        target_message_count: target_message_count,
        total_message_count: source_message_count + target_message_count
      }
    )

    # Verify no data loss
    merged_message_count = Conversation.where(contact_id: target_id).count
    expected_count = source_message_count + target_message_count

    unless merged_message_count == expected_count
      raise StandardError, "Data loss detected! Expected #{expected_count} messages, found #{merged_message_count}"
    end

    true
  end

  # Rollback a merge by restoring the source contact
  def rollback_merge(merge_log_id)
    merge_log = ContactMergeLog.find(merge_log_id)
    source = Contact.find(merge_log.source_contact_id)

    # Restore source contact
    source.update!(
      is_deleted: false,
      deleted_at: nil
    )

    # Move conversations back to source (optional, depends on business logic)
    # For now, we leave them in target to maintain message thread continuity

    merge_log.update!(
      merge_data: merge_log.merge_data.merge(restored_at: Time.current)
    )

    true
  end

  private

  # Prevent circular merges: A→B, B→C, then C→A would be circular
  def validate_no_circular_merge(source_id, target_id)
    # Check if target_id has already been merged as a source
    # (i.e., target_id → X, then we can't do X → source_id)
    target_as_source = ContactMergeLog.where(source_contact_id: target_id).pluck(:target_contact_id)

    if target_as_source.include?(source_id)
      raise StandardError, 'Circular merge detected: these contacts have already been merged in reverse order'
    end

    # Also check deeper chains
    check_merge_chain(target_id, source_id)
  end

  def check_merge_chain(current_id, forbidden_id, visited = Set.new)
    return if visited.include?(current_id)
    visited.add(current_id)

    # Get all contacts that current_id has been merged into
    next_merges = ContactMergeLog.where(source_contact_id: current_id).pluck(:target_contact_id)

    next_merges.each do |next_id|
      raise StandardError, 'Circular merge detected in chain' if next_id == forbidden_id
      check_merge_chain(next_id, forbidden_id, visited)
    end
  end
end
