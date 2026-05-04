class ContactMergeLog < ApplicationRecord
  belongs_to :source_contact, class_name: 'Contact', foreign_key: 'source_contact_id'
  belongs_to :target_contact, class_name: 'Contact', foreign_key: 'target_contact_id'

  validates :source_contact_id, :target_contact_id, presence: true
  validate :source_and_target_must_be_different

  scope :recent_first, -> { order(merged_at: :desc) }
  scope :for_contact, ->(contact_id) do
    where('source_contact_id = ? OR target_contact_id = ?', contact_id, contact_id)
  end

  private

  def source_and_target_must_be_different
    if source_contact_id == target_contact_id
      errors.add(:base, 'Cannot merge contact with itself')
    end
  end
end
