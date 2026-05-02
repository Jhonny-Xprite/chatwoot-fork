#!/usr/bin/env rails runner

# Script para inspeccionar como os contatos são armazenados no Chatwoot
# Use: rails runner inspect_contact.rb

puts "=" * 80
puts "INSPECTING CONTACT STRUCTURE IN CHATWOOT"
puts "=" * 80

# Verificar uma conta
account = Account.first
if account.nil?
  puts 'ERROR: No accounts found. Create an account first.'
  exit(1)
end

puts "\n📊 ACCOUNT: #{account.name} (ID: #{account.id})"

# Verificar se há contatos
contacts = account.contacts.limit(3)
if contacts.empty?
  puts "\n❌ No contacts found in this account. Let's create a test contact..."

  contact = account.contacts.create(
    name: 'João da Silva',
    email: 'joao@example.com',
    phone_number: '+5511987654321',
    contact_type: :lead
  )

  puts "✅ Created test contact: #{contact.name}"
  contacts = [contact]
else
  puts "\n✅ Found #{contacts.count} contacts"
end

# Exibir estrutura de cada contato
contacts.each_with_index do |contact, idx|
  puts "\n" + "-" * 80
  puts "CONTACT #{idx + 1} (ID: #{contact.id})"
  puts "-" * 80

  # Campos principais
  puts "\n📋 MAIN FIELDS:"
  puts "  • name:              #{contact.name.inspect}"
  puts "  • first_name:        #{contact.respond_to?(:first_name) ? contact.first_name.inspect : 'N/A'}"
  puts "  • middle_name:       #{contact.middle_name.inspect}"
  puts "  • last_name:         #{contact.last_name.inspect}"
  puts "  • email:             #{contact.email.inspect}"
  puts "  • phone_number:      #{contact.phone_number.inspect}"
  puts "  • identifier:        #{contact.identifier.inspect}"
  puts "  • contact_type:      #{contact.contact_type.inspect}"
  puts "  • location:          #{contact.location.inspect}"
  puts "  • country_code:      #{contact.country_code.inspect}"

  # Atributos customizados
  if contact.custom_attributes.present?
    puts "\n🏷️  CUSTOM ATTRIBUTES:"
    contact.custom_attributes.each do |key, value|
      puts "  • #{key}: #{value.inspect}"
    end
  else
    puts "\n🏷️  CUSTOM ATTRIBUTES: (none)"
  end

  # Atributos adicionais
  if contact.additional_attributes.present?
    puts "\n📝 ADDITIONAL ATTRIBUTES:"
    contact.additional_attributes.each do |key, value|
      puts "  • #{key}: #{value.inspect}"
    end
  else
    puts "\n📝 ADDITIONAL ATTRIBUTES: (none)"
  end

  # Timestamps
  puts "\n⏰ TIMESTAMPS:"
  puts "  • created_at:        #{contact.created_at.inspect}"
  puts "  • updated_at:        #{contact.updated_at.inspect}"
  puts "  • last_activity_at:  #{contact.last_activity_at.inspect}"
end

puts "\n" + "=" * 80
puts "IMPORTANT: Check how 'name', 'first_name', 'last_name' are being used"
puts "=" * 80
