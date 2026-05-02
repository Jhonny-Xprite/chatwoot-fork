# PhoneFormatter: E.164 normalization and validation for phone numbers
# Handles diverse formats: 11987654321, +5511987654321, (11) 9 8765-4321, +55 11 9 8765-4321
# Returns: +5511987654321 (E.164 format) or raises PhoneFormatterError
class PhoneFormatter
  class PhoneFormatterError < StandardError; end

  # Format phone number to E.164 standard: +[country_code][number]
  # @param phone [String] Phone number in any format
  # @return [String] Formatted phone in E.164 format (+5511987654321)
  # @raises PhoneFormatterError if phone is invalid
  def self.format(phone)
    new(phone).format
  end

  def initialize(phone)
    @original_phone = phone
    @phone = phone.to_s.strip
  end

  def format
    return nil if @phone.blank?

    cleaned = clean_phone
    return nil if cleaned.blank?

    # If already has country code, validate and return E.164
    if cleaned.start_with?('+')
      validate_and_format_international(cleaned)
    else
      # Assume Brazil for numbers without country code
      validate_and_format_as_brazil(cleaned)
    end
  end

  private

  # Remove all non-digit characters except +
  def clean_phone
    @phone.gsub(/[^\d+]/, '')
  end

  # Validate international format (with country code)
  # @param phone [String] Phone with country code (e.g., +5511987654321)
  def validate_and_format_international(phone)
    plus_sign = phone[0]
    digits = phone[1..-1]

    # Validate: must have 1-15 digits after +
    unless digits.match?(/^\d{1,15}$/)
      raise PhoneFormatterError, "Invalid phone: #{@original_phone} (invalid format)"
    end

    # Validate length (E.164 standard: 7-15 digits after country code)
    if digits.length < 7
      raise PhoneFormatterError, "Invalid phone: #{@original_phone} (too short)"
    elsif digits.length > 15
      raise PhoneFormatterError, "Invalid phone: #{@original_phone} (too long)"
    end

    # Format as E.164
    formatted = "+#{digits}"

    # Apply WhatsApp normalization for Brazil
    apply_whatsapp_normalization(formatted)
  end

  # Validate Brazilian format (without country code)
  # @param digits [String] Pure digits (e.g., 11987654321)
  def validate_and_format_as_brazil(digits)
    # Remove leading zero if present (Brazilian landlines may have it)
    digits = digits[1..-1] if digits.start_with?('0')

    # Validate length (Brazilian: 10-11 digits, or international: any valid E.164)
    if digits.length < 7
      raise PhoneFormatterError, "Invalid phone: #{@original_phone} (too short)"
    elsif digits.length > 15
      raise PhoneFormatterError, "Invalid phone: #{@original_phone} (too long)"
    end

    # If 10-11 digits, assume Brazil (+55)
    if digits.length.between?(10, 11)
      formatted = "+55#{digits}"
      return apply_whatsapp_normalization(formatted)
    end

    # If 7-9 digits, assume Brazil (missing country code)
    if digits.length.between?(7, 9)
      formatted = "+55#{digits}"
      return apply_whatsapp_normalization(formatted)
    end

    # If 12-15 digits, assume already has country code embedded
    if digits.length.between?(12, 15)
      formatted = "+#{digits}"
      return apply_whatsapp_normalization(formatted)
    end

    # Shouldn't reach here, but handle edge case
    "+55#{digits}"
  end

  # Apply WhatsApp normalization: Brazilian number with 12 digits needs 9 added
  # Example: +5511987654321 (12 digits) → +5511987654321 (correct)
  #          +551187654321 (11 digits) → +5511987654321 (add 9)
  # @param phone [String] Phone in format +[country_code][number]
  def apply_whatsapp_normalization(phone)
    return phone unless phone.start_with?('+55')

    # Remove + and analyze
    waid = phone[1..-1]

    # Brazilian number with 12 digits (55 + DDD + 8 digits) needs 9 added
    if waid.length == 12 && waid.start_with?('55')
      ddd = waid[2, 2]
      number = waid[4..-1]
      return "+55#{ddd}9#{number}"
    end

    # If already 13 digits, it's complete (correct)
    return phone if waid.length == 13

    # Return as-is (will be validated by WhatsApp or Contact model)
    phone
  end
end
