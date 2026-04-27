class CrmListener < BaseListener
  def conversation_updated(event)
    conversation = event.data[:conversation]
    changed_attributes = event.data[:changed_attributes]

    return unless changed_attributes.key?(:label_list)

    # Check for GADS-Qualified label
    previous_labels, current_labels = changed_attributes[:label_list]
    new_labels = current_labels - previous_labels

    if new_labels.include?('GADS-Qualified')
      move_to_qualified_stage(conversation)
    end
  end

  private

  def move_to_qualified_stage(conversation)
    # Find the "Qualified" stage in the conversation's account
    # We assume there might be multiple pipelines, so we find the first one with a stage named "Qualified"
    stage = conversation.account.crm_pipeline_stages.find_by('name ILIKE ?', 'Qualified')
    
    return unless stage

    # Move conversation to the stage
    # Using a service or direct update since it's a simple movement
    conversation.update!(
      pipeline_id: stage.pipeline_id,
      pipeline_stage_id: stage.id
    )
  end
end
