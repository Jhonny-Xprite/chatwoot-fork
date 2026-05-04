class ContactMergeLog < ApplicationRecord
  belongs_to :source_contact, class_name: 'Contact'
  belongs_to :target_contact, class_name: 'Contact'

  validates :source_contact_id, :target_contact_id, presence: true
  validate :source_and_target_must_be_different

  scope :recent_first, -> { order(merged_at: :desc) }
  scope :for_contact, lambda { |contact_id|
    where('source_contact_id = ? OR target_contact_id = ?', contact_id, contact_id)
  }

  private

  def source_and_target_must_be_different
    return unless source_contact_id == target_contact_id

    errors.add(:base, 'Cannot merge contact with itself')
  end
end
