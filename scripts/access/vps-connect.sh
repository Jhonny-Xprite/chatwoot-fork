#!/bin/bash

# Script para conectar na VPS via SSH (Linux/WSL/Git Bash)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ ! -f "$SCRIPT_DIR/.env.access" ]; then
    echo "[ERRO] Arquivo .env.access nao encontrado!"
    echo "Por favor, copie .env.access.example para .env.access e preencha os dados."
    exit 1
fi

# Carrega variaveis
source "$SCRIPT_DIR/.env.access"

echo "[INFO] Conectando a VPS: $VPS_USER@$VPS_IP..."

if [ -n "$SSH_KEY_PATH" ]; then
    ssh -i "$SSH_KEY_PATH" "$VPS_USER@$VPS_IP"
else
    ssh "$VPS_USER@$VPS_IP"
fi
