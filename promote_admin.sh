docker exec $(docker ps -q -f name=chatwoot | head -n 1) bundle exec rails runner "User.find_by(email: 'equipe@jhonnyxprite.com').update_columns(type: 'SuperAdmin')" 
