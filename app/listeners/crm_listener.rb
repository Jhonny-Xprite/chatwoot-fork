class CrmListener < BaseListener
  def conversation_updated(event)
    conversation = event.data[:conversation]
    changed_attributes = event.data[:changed_attributes]

    return unless changed_attributes.key?(:label_list)

    # Check for GADS-Qualified label
    previous_labels, current_labels = changed_attributes[:label_list]
    new_labels = current_labels - (previous_labels || [])

    return unless new_labels.include?('GADS-Qualified')

    move_to_stage(conversation, 'Qualified')
  end

  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless message.incoming?

    # Check for GADS Masterclass automation triggers
    # Trigger 1: Waitlist registration (specific keyword or button)
    if message.content.to_s.downcase.include?('lista de espera') || 
       message.content_attributes.dig('data', 'button_text')&.downcase&.include?('lista de espera')
      move_to_stage(conversation, 'Waitlist')
    end

    # Trigger 2: Registration completed
    if message.content.to_s.downcase.include?('inscrito') || 
       message.content_attributes.dig('data', 'button_text')&.downcase&.include?('finalizar inscrição')
      move_to_stage(conversation, 'Registration')
    end

    # Trigger 3: Joined Groups
    if message.content.to_s.downcase.include?('entrei no grupo') || 
       message.content_attributes.dig('data', 'button_text')&.downcase&.include?('acessar grupo')
      move_to_stage(conversation, 'Groups')
    end
  end

  private

  def move_to_stage(conversation, stage_name)
    # Find the stage in the conversation's account
    stage = conversation.account.crm_pipeline_stages.find_by('name ILIKE ?', stage_name)
    
    return unless stage

    # Move conversation to the stage
    conversation.update!(
      pipeline_id: stage.pipeline_id,
      pipeline_stage_id: stage.id
    )
  end
end
