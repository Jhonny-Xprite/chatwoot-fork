# 🔐 Scripts de Acesso DevOps

Estes scripts facilitam o acesso à sua infraestrutura de deploy (VPS e EasyPanel).

## 🛠️ Como Configurar

1. Vá para a pasta `scripts/access/`.
2. Renomeie o arquivo `.env.access.example` para `.env.access`.
3. Preencha as variáveis:
   - `VPS_IP`: Endereço IP do seu servidor.
   - `VPS_USER`: Usuário SSH (geralmente `root`).
   - `SSH_KEY_PATH`: (Opcional) Caminho para sua chave privada se não usar senha.
   - `EASYPANEL_URL`: URL do seu EasyPanel.
   - `EASYPANEL_EMAIL`: Seu email de login no EasyPanel.

## 🚀 Como Usar

### No Windows (CMD/PowerShell):
- **Acessar VPS**: Clique duplo em `vps-connect.bat`.
- **Abrir EasyPanel**: Clique duplo em `easypanel-dashboard.bat`.

### No Linux / WSL / Git Bash:
- **Acessar VPS**: `bash scripts/access/vps-connect.sh`

---
> [!IMPORTANT]
> **SEGURANÇA**: Nunca dê commit no arquivo `.env.access`. Ele já está incluído no `.gitignore` por padrão (se não estiver, adicione manualente).
