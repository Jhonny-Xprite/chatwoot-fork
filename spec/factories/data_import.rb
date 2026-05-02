FactoryBot.define do
  factory :data_import do
    data_type { 'contacts' }
    import_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/contacts.csv'), 'text/csv') }
    mapping do
      {
        'Email Address' => 'email',
        'Full Name' => 'name',
        'Phone' => 'phone_number'
      }
    end
    account

    # Trait: Standard mapping with all required fields
    trait :with_standard_mapping do
      mapping do
        {
          'Email Address' => 'email',
          'Full Name' => 'name',
          'Phone Number' => 'phone_number'
        }
      end
    end

    # Trait: Extended mapping with custom attributes
    trait :with_custom_attributes do
      mapping do
        {
          'Email Address' => 'email',
          'Full Name' => 'name',
          'Phone Number' => 'phone_number',
          'Company' => 'custom_attribute:company',
          'Title' => 'custom_attribute:job_title'
        }
      end
    end

    # Trait: Minimal mapping (only email)
    trait :with_email_only do
      mapping { { 'Email Address' => 'email' } }
    end

    # Trait: Phone and email mapping
    trait :with_phone_mapping do
      mapping do
        {
          'Email Address' => 'email',
          'Phone' => 'phone_number'
        }
      end
    end

    # Trait: First name and last name mapping
    trait :with_name_split do
      mapping do
        {
          'Email Address' => 'email',
          'First Name' => 'first_name',
          'Last Name' => 'last_name',
          'Phone' => 'phone_number'
        }
      end
    end

    # Trait: Processing status
    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      processed_records { 10 }
      total_records { 12 }
    end

    trait :failed do
      status { :failed }
    end
  end
end
