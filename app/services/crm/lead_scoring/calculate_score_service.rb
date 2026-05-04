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
      evaluate_attribute(rule, @contact)
    when 'conversation_attribute'
      # We check all conversations and return true if any matches
      @contact.conversations.any? { |conv| evaluate_attribute(rule, conv) }
    when 'label'
      evaluate_label(rule)
    else
      false
    end
  end

  def evaluate_attribute(rule, record)
    # Priority: Standard DB Column -> Custom Attribute
    value = if record.class.column_names.include?(rule.attribute_key)
              record.public_send(rule.attribute_key)
            else
              record.custom_attributes.to_h[rule.attribute_key]
            end

    # Handle nil and empty cases based on operator
    return true if rule.filter_operator == 'is_not_present' && value.blank?
    return false if value.nil? && rule.filter_operator != 'is_not_present'

    case rule.filter_operator
    when 'equal_to'
      rule.values.include?(value.to_s)
    when 'not_equal_to'
      !rule.values.include?(value.to_s)
    when 'contains'
      rule.values.any? { |v| value.to_s.downcase.include?(v.downcase) }
    when 'does_not_contain'
      rule.values.none? { |v| value.to_s.downcase.include?(v.downcase) }
    when 'is_present'
      value.present?
    when 'is_not_present'
      value.blank?
    else
      false
    end
  end

  def evaluate_label(rule)
    # Check labels on contact and all its conversations, using downcase for safety
    all_labels = (@contact.label_list + @contact.conversations.flat_map(&:label_list)).map(&:downcase).uniq
    rule_values = rule.values.map(&:downcase)

    case rule.filter_operator
    when 'equal_to', 'contains'
      (all_labels & rule_values).any?
    when 'not_equal_to', 'does_not_contain'
      (all_labels & rule_values).empty?
    when 'is_present'
      all_labels.present?
    when 'is_not_present'
      all_labels.empty?
    else
      false
    end
  end
end
