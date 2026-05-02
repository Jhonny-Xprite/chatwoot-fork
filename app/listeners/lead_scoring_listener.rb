class LeadScoringListener < BaseListener
  def contact_updated(event)
    contact = event.data[:contact]
    changed_attributes = event.data[:changed_attributes]

    # Only trigger if relevant fields changed (custom_attributes or label_list)
    return unless changed_attributes.key?('custom_attributes') || changed_attributes.key?('label_list')

    Crm::LeadScoringCalculationJob.perform_later(contact.id)
  end

  def conversation_updated(event)
    conversation = event.data[:conversation]
    changed_attributes = event.data[:changed_attributes]

    # Only trigger if relevant fields changed (custom_attributes or label_list)
    return unless changed_attributes.key?('custom_attributes') || changed_attributes.key?(:label_list)

    Crm::LeadScoringCalculationJob.perform_later(conversation.contact_id)
  end

  def conversation_created(event)
    conversation = event.data[:conversation]
    Crm::LeadScoringCalculationJob.perform_later(conversation.contact_id)
  end
end
