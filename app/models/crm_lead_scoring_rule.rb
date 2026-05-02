class CrmLeadScoringRule < ApplicationRecord
  belongs_to :account

  validates :attribute_model, presence: true, inclusion: { in: %w[contact_attribute conversation_attribute label] }
  validates :attribute_key, presence: true
  validates :filter_operator, presence: true
  validates :score, presence: true, numericality: { only_integer: true }

  def self.attribute_models
    {
      contact_attribute: 'Contact Attribute',
      conversation_attribute: 'Conversation Attribute',
      label: 'Label'
    }
  end
end
