class Api::V1::Admin::ContactsDeduplicationController < Api::V1::BaseController
  before_action :require_admin!
  before_action :set_contact, only: [:detect_duplicates]

  # POST /api/v1/admin/contacts/deduplicate
  # Detect potential duplicate contacts for a given contact
  def detect_duplicates
    service = Contacts::DeduplicationService.new(@contact)

    exact_duplicates = service.find_exact_duplicates
    fuzzy_duplicates = service.find_fuzzy_duplicates

    # Combine and deduplicate results
    all_duplicates = (exact_duplicates + fuzzy_duplicates)
      .uniq { |d| d[:contact].id }
      .sort_by { |d| d[:confidence] == 'HIGH' ? 0 : 1 }

    duplicates_response = all_duplicates.map do |dup|
      {
        source: serialize_contact(@contact),
        target: serialize_contact(dup[:contact]),
        confidence: dup[:confidence],
        reason: dup[:reason]
      }
    end

    render json: {
      duplicates: duplicates_response,
      count: duplicates_response.length
    }
  end

  # POST /api/v1/admin/contacts/merge
  # Execute merge of source contact into target contact
  def merge_contacts
    validate_merge_params!

    source_id = merge_params[:source_contact_id]
    target_id = merge_params[:target_contact_id]

    begin
      service = Contacts::DeduplicationService.new(Contact.find(target_id))
      service.merge_contacts(source_id, target_id, current_user.email)

      target_contact = Contact.find(target_id)
      render json: {
        merged: true,
        contact: serialize_contact(target_contact),
        message: 'Contacts merged successfully'
      }
    rescue StandardError => e
      render json: {
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/admin/contacts/merge-logs
  # Get merge history with pagination
  def merge_logs
    page = params[:page] || 1
    per_page = params[:per_page] || 50

    logs = ContactMergeLog.recent_first
      .page(page)
      .per(per_page)

    logs_response = logs.map do |log|
      {
        id: log.id,
        source: serialize_contact(log.source_contact),
        target: serialize_contact(log.target_contact),
        merged_at: log.merged_at,
        merged_by: log.merged_by,
        merge_data: log.merge_data
      }
    end

    render json: {
      logs: logs_response,
      total_count: ContactMergeLog.count,
      page: page,
      per_page: per_page
    }
  end

  # POST /api/v1/admin/contacts/rollback-merge
  # Rollback a merge operation
  def rollback_merge
    merge_log = ContactMergeLog.find(params[:merge_log_id])

    begin
      service = Contacts::DeduplicationService.new(Contact.find(merge_log.source_contact_id))
      service.rollback_merge(merge_log.id)

      render json: {
        rolled_back: true,
        message: 'Merge rolled back successfully'
      }
    rescue StandardError => e
      render json: {
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def merge_params
    params.require(:merge).permit(:source_contact_id, :target_contact_id)
  end

  def validate_merge_params!
    unless merge_params[:source_contact_id].present? && merge_params[:target_contact_id].present?
      render json: { error: 'source_contact_id and target_contact_id required' }, status: :bad_request
    end
  end

  def serialize_contact(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      message_count: Conversation.where(contact_id: contact.id).count,
      is_deleted: contact.is_deleted,
      deleted_at: contact.deleted_at
    }
  end

  def require_admin!
    return if current_user.admin?

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
