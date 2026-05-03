require 'rails_helper'

describe PhoneFormatter do
  describe '.format' do
    context 'when formatting Brazilian mobile numbers (Story 2.2 Scenario 1)' do
      it 'formats number without country code to E.164' do
        expect(described_class.format('11987654321')).to eq('+5_511_987_654_321')
      end

      it 'formats 10-digit Brazilian landline' do
        expect(described_class.format('1133334444')).to eq('+551133334444')
      end

      it 'adds country code and formats correctly' do
        expect(described_class.format('21991234567')).to eq('+5521991234567')
      end
    end

    context 'when phone already has country code (Story 2.2 Scenario 2)' do
      it 'returns phone as-is when already in E.164' do
        expect(described_class.format('+5_511_987_654_321')).to eq('+5_511_987_654_321')
      end

      it 'validates international format with country code' do
        expect(described_class.format('+551133334444')).to eq('+551133334444')
      end

      it 'handles US numbers' do
        expect(described_class.format('+12125550123')).to eq('+12125550123')
      end

      it 'handles UK numbers' do
        expect(described_class.format('+442071838750')).to eq('+442071838750')
      end

      it 'handles Japan numbers' do
        expect(described_class.format('+81312341234')).to eq('+81312341234')
      end
    end

    context 'when input is formatted with spaces or dashes (Story 2.2 Scenario 3)' do
      it 'removes parentheses and converts to E.164' do
        expect(described_class.format('(11) 9 8765-4321')).to eq('+5_511_987_654_321')
      end

      it 'removes spaces from formatted number' do
        expect(described_class.format('11 9 8765 4321')).to eq('+5_511_987_654_321')
      end

      it 'removes dashes from formatted number' do
        expect(described_class.format('11-9-8765-4321')).to eq('+5_511_987_654_321')
      end

      it 'removes dots from formatted number' do
        expect(described_class.format('11.9.8765.4321')).to eq('+5_511_987_654_321')
      end
    end

    context 'when phone has various spacing formats (Story 2.2 Scenario 4)' do
      it 'handles country code with spaces' do
        expect(described_class.format('+55 11 9 8765-4321')).to eq('+5_511_987_654_321')
      end

      it 'handles multiple space types' do
        expect(described_class.format('+55 11 98765 4321')).to eq('+5_511_987_654_321')
      end

      it 'removes all whitespace variations' do
        expect(described_class.format('+55 (11) 9 8765-4321')).to eq('+5_511_987_654_321')
      end
    end

    context 'when using old Brazilian format with leading zero (Story 2.2 Scenario 5)' do
      it 'converts old Brazilian format with leading zero' do
        expect(described_class.format('011987654321')).to eq('+5_511_987_654_321')
      end

      it 'handles landline with leading zero' do
        expect(described_class.format('01133334444')).to eq('+551133334444')
      end

      it 'removes only leading zero, keeps digits' do
        expect(described_class.format('0219912345')).to eq('+5521991234')
      end
    end

    context 'when phone number is too short (Story 2.2 Scenario 6)' do
      it 'raises error for very short number' do
        expect { described_class.format('999') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*too short/)
      end

      it 'raises error for single digit' do
        expect { described_class.format('5') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*too short/)
      end

      it 'raises error for incomplete country code' do
        expect { described_class.format('+5') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*too short/)
      end

      it 'includes original phone in error message' do
        expect { described_class.format('123') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone: 123/)
      end
    end

    context 'when phone number is too long (Story 2.2 Scenario 7)' do
      it 'raises error for excessively long number' do
        expect { described_class.format('111_111_111_111_111_111') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*too long/)
      end

      it 'raises error for number > 15 digits after country code' do
        expect { described_class.format('+5_511_999_999_999_999_999') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*too long/)
      end

      it 'includes original phone in error message' do
        expect { described_class.format('111_111_111_111_111_111') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone: 111_111_111_111_111_111/)
      end
    end

    context 'when phone contains letters (Story 2.2 Scenario 8)' do
      it 'raises error for letters in phone' do
        expect { described_class.format('abc123') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*invalid format/)
      end

      it 'raises error for mixed alphanumeric' do
        expect { described_class.format('+55abc123') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone.*invalid format/)
      end

      it 'includes original phone in error message' do
        expect { described_class.format('abc123') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /Invalid phone: abc123/)
      end
    end

    context 'when formatting for WhatsApp (Brazil region)' do
      it 'adds 9 digit for old Brazilian format (55 + DDD + 8 digits)' do
        # Input: 551187654321 (11 digits) = 55 + 11 + 87654321
        # Output: 5_511_987_654_321 (13 digits) = 55 + 11 + 9 + 87654321
        expect(described_class.format('551187654321')).to eq('+5_511_987_654_321')
      end

      it 'does not modify when already has 9 digit' do
        # Input: 5_511_987_654_321 (13 digits) = 55 + 11 + 9 + 87654321
        # Output: same
        expect(described_class.format('5_511_987_654_321')).to eq('+5_511_987_654_321')
      end

      it 'handles formatted old format' do
        # Input: (11) 8765-4321 = old format
        # Output: +5_511_987_654_321 with 9 added
        expect(described_class.format('(11) 8765-4321')).to eq('+5_511_987_654_321')
      end
    end

    context 'when handling edge cases' do
      it 'returns nil for empty string' do
        expect(described_class.format('')).to be_nil
      end

      it 'returns nil for nil' do
        expect(described_class.format(nil)).to be_nil
      end

      it 'returns nil for whitespace only' do
        expect(described_class.format('   ')).to be_nil
      end

      it 'handles numeric input (integer)' do
        expect(described_class.format(5_511_987_654_321)).to eq('+5_511_987_654_321')
      end

      it 'trims leading/trailing whitespace' do
        expect(described_class.format('  11987654321  ')).to eq('+5_511_987_654_321')
      end

      it 'handles plus sign without country digits' do
        expect { described_class.format('+') }
          .to raise_error(PhoneFormatter::PhoneFormatterError)
      end
    end

    context 'when handling international numbers' do
      it 'handles France numbers' do
        expect(described_class.format('+33123456789')).to eq('+33123456789')
      end

      it 'handles Germany numbers' do
        expect(described_class.format('+491234567890')).to eq('+491234567890')
      end

      it 'handles Canada numbers' do
        expect(described_class.format('+14165551234')).to eq('+14165551234')
      end

      it 'handles Australia numbers' do
        expect(described_class.format('+61212345678')).to eq('+61212345678')
      end

      it 'handles India numbers' do
        expect(described_class.format('+919876543210')).to eq('+919876543210')
      end
    end

    context 'when handling different regional formats' do
      it 'handles São Paulo area code' do
        expect(described_class.format('1191234567')).to eq('+551191234567')
      end

      it 'handles Rio de Janeiro area code' do
        expect(described_class.format('2191234567')).to eq('+552191234567')
      end

      it 'handles Bahia area code' do
        expect(described_class.format('7191234567')).to eq('+557191234567')
      end

      it 'handles different area codes' do
        expect(described_class.format('4591234567')).to eq('+554591234567')
      end
    end

    context 'when error messages are generated' do
      it 'includes original phone value in error for invalid phone' do
        original = '(11) 1234'
        expect { described_class.format(original) }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /#{Regexp.escape(original)}/)
      end

      it 'specifies error type: too short' do
        expect { described_class.format('123') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /too short/)
      end

      it 'specifies error type: too long' do
        expect { described_class.format('1' * 20) }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /too long/)
      end

      it 'specifies error type: invalid format' do
        expect { described_class.format('abc-def-ghij') }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /invalid format/)
      end
    end
  end

  describe 'integration with existing test expectations' do
    # Verify all Story 2.2 test scenarios work
    it 'handles all 8 story scenarios correctly' do
      scenarios = [
        ['11987654321', '+5_511_987_654_321'],               # Scenario 1
        ['+5_511_987_654_321', '+5_511_987_654_321'],           # Scenario 2
        ['(11) 9 8765-4321', '+5_511_987_654_321'],         # Scenario 3
        ['+55 11 9 8765-4321', '+5_511_987_654_321'],       # Scenario 4
        ['11 98765-4321', '+5_511_987_654_321'],            # Scenario 5
      ]

      scenarios.each do |input, expected|
        expect(described_class.format(input)).to eq(expected),
          "Failed for input: #{input}"
      end
    end

    it 'raises errors for all invalid scenarios' do
      invalid_scenarios = [
        ['999', 'too short'],
        ['111_111_111_111_111_111', 'too long'],
        ['abc123', 'invalid format'],
      ]

      invalid_scenarios.each do |input, error_type|
        expect { described_class.format(input) }
          .to raise_error(PhoneFormatter::PhoneFormatterError, /#{error_type}/),
          "Failed for input: #{input}"
      end
    end
  end
end
