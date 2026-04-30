#!/bin/bash
# Sync local docker-compose.yml to VPS
# Usage: ./scripts/deploy/sync-configs.sh

REMOTE_PATH="/etc/easypanel/projects/clientes-tools/a2/code/docker-compose.yml"
REMOTE_USER="root"
REMOTE_HOST="92.112.176.118"

echo "🚀 Sincronizando docker-compose.yml para o VPS..."
scp -o StrictHostKeyChecking=no docker-compose.yml ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}

echo "🔄 Disparando webhook de deploy no Easypanel..."
curl -X GET http://92.112.176.118:3000/api/compose/deploy/26e3f693706a3eb344d754d8815e29a6d02b5ee0c9f557e1

echo ""
echo "✅ Configurações sincronizadas e deploy disparado!"
