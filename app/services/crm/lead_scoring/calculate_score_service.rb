class Crm::LeadScoring::CalculateScoreService
  def initialize(contact:)
    @contact = contact
    @account = contact.account
    @rules = @account.crm_lead_scoring_rules
  end

  def perform!
    return if @rules.empty?

    total_score = 0

    @rules.each do |rule|
      total_score += rule.score if rule_matches?(rule)
    end

    Rails.logger.debug { "[CRM] Calculando Lead Score para Contato ##{@contact.id}: #{total_score}" }
    @contact.update!(lead_score: total_score)
  end

  private

  def rule_matches?(rule)
    case rule.attribute_model
    when 'contact_attribute'
      evaluate_attribute(rule, @contact.custom_attributes)
    when 'conversation_attribute'
      # We check the most recent conversation
      last_conversation = @contact.conversations.last
      return false unless last_conversation

      evaluate_attribute(rule, last_conversation.custom_attributes)
    when 'label'
      evaluate_label(rule)
    else
      false
    end
  end

  def evaluate_attribute(rule, custom_attributes)
    return false unless custom_attributes.present?

    value = custom_attributes[rule.attribute_key]
    return false if value.nil?

    case rule.filter_operator
    when 'equal_to'
      rule.values.include?(value.to_s)
    when 'not_equal_to'
      !rule.values.include?(value.to_s)
    when 'contains'
      rule.values.any? { |v| value.to_s.include?(v) }
    when 'does_not_contain'
      rule.values.none? { |v| value.to_s.include?(v) }
    when 'is_present'
      value.present?
    when 'is_not_present'
      value.blank?
    else
      false
    end
  end

  def evaluate_label(rule)
    # Check labels on contact and all its conversations
    all_labels = @contact.label_list + @contact.conversations.flat_map(&:label_list)

    case rule.filter_operator
    when 'equal_to', 'contains'
      (all_labels & rule.values).any?
    when 'not_equal_to', 'does_not_contain'
      (all_labels & rule.values).empty?
    when 'is_present'
      all_labels.present?
    when 'is_not_present'
      all_labels.empty?
    else
      false
    end
  end
end
