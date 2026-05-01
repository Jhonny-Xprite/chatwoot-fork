class Crm::LeadScoringCalculationJob < ApplicationJob
  queue_as :low

  def perform(contact_id)
    contact = Contact.find_by(id: contact_id)
    return unless contact

    Crm::LeadScoring::CalculateScoreService.new(contact: contact).perform!
  end
end
