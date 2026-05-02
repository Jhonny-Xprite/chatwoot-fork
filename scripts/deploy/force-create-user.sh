#!/bin/bash
docker exec -i clientes-tools_a2-a2-chatwoot-1 bundle exec rails runner - <<EOF
user = User.find_by(email: 'equipe@jhonnyxprite.com')
if user
  user.password = 'Jhonn@2026!'
  user.password_confirmation = 'Jhonn@2026!'
  user.role = :super_admin
  user.save!
  puts 'SUCCESS: User updated!'
else
  user = User.new(email: 'equipe@jhonnyxprite.com', password: 'Jhonn@2026!', password_confirmation: 'Jhonn@2026!', role: :super_admin, name: 'Jhonn')
  if user.save
    puts 'SUCCESS: User created!'
  else
    puts 'ERROR: ' + user.errors.full_messages.join(', ')
  end
end
EOF
