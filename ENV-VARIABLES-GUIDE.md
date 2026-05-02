# 🔧 Guia Completo de Variáveis de Ambiente - Chatwoot Fork

## 📋 Resumo Rápido

| Status | Variável | Necessário? | Exemplo |
|--------|----------|------------|---------|
| 🔴 | `DATABASE_URL` | **SIM** | `postgresql://postgres:pass@a2-postgres:5432/chatwoot` |
| 🔴 | `REDIS_URL` | **SIM** | `redis://a2-redis:6379` |
| 🔴 | `SECRET_KEY_BASE` | **SIM** | `xyz123abc...` (64 chars min) |
| 🔴 | `RAILS_ENV` | **SIM** | `production` |
| 🟡 | `RAILS_LOG_TO_STDOUT` | Recomendado | `true` |
| 🟡 | `RAILS_SERVE_STATIC_FILES` | Recomendado | `true` |
| 🟡 | `FRONTEND_URL` | Recomendado | `http://localhost:3000` |
| 🟢 | `FEATURE_CRM_ENABLED` | Para CRM | `true` |
| 🔵 | `SMTP_*` | Para emails | Ver seção abaixo |
| 🟣 | `AWS_*` | Para S3 | Ver seção abaixo |

---

## 🔴 OBRIGATÓRIAS (SEM ESSAS NÃO FUNCIONA)

### `DATABASE_URL`
**O que é:** Conexão com PostgreSQL
```
postgresql://usuario:senha@host:porta/database
```

**Exemplo do docker-compose:**
```
DATABASE_URL: postgresql://postgres:postgres_secure_2024@a2-postgres:5432/chatwoot
```

**Produção:** Mude a senha `postgres_secure_2024` para algo seguro!

---

### `REDIS_URL`
**O que é:** Cache e fila de jobs
```
redis://host:porta
```

**Exemplo do docker-compose:**
```
REDIS_URL: redis://a2-redis:6379
```

---

### `SECRET_KEY_BASE`
**O que é:** Chave de criptografia de sessão
```
Precisa ter MÍNIMO 64 caracteres
```

**Gerar uma nova (Unix/Mac/Linux):**
```bash
openssl rand -hex 32  # gera 64 caracteres
```

**Exemplo:**
```
SECRET_KEY_BASE: 3a2b8f9c4e1d5a7b9f2c4e6a8b0d2f4a6c8e0b2d4f6a8c0e2a4c6e8a0b2d4f
```

**⚠️ NUNCA use o padrão em produção!**

---

### `RAILS_ENV`
**O que é:** Ambiente de execução
```
production  ← Use isto no EasyPanel
```

---

## 🟡 RECOMENDADAS (Melhor deixar como está)

### `RAILS_LOG_TO_STDOUT`
```
RAILS_LOG_TO_STDOUT: "true"
```
Faz os logs aparecerem no console/Docker logs

---

### `RAILS_SERVE_STATIC_FILES`
```
RAILS_SERVE_STATIC_FILES: "true"
```
Rails serve CSS, JS, imagens direto

---

### `FRONTEND_URL`
```
FRONTEND_URL: http://localhost:3000
# ou em produção:
FRONTEND_URL: https://seu-dominio.com
```
URL que o frontend usa para links e emails

---

### `RAILS_MAX_THREADS` / `RAILS_MIN_THREADS`
```
RAILS_MAX_THREADS: "4"
RAILS_MIN_THREADS: "2"
```
Controla paralelismo de requisições

---

## 🟢 OPCIONAIS - CRM Features (Seu Projeto)

### `FEATURE_CRM_ENABLED`
```
FEATURE_CRM_ENABLED: "true"
```
Habilita o CRM Kanban board com advanced filters e stage automation

---

## 🔵 OPCIONAIS - Email (SMTP)

Se quiser que o Chatwoot **envie emails** (confirmação de conta, notificações, etc):

```yaml
SMTP_ADDRESS: smtp.gmail.com
SMTP_PORT: 587
SMTP_USERNAME: seu_email@gmail.com
SMTP_PASSWORD: sua_senha_de_app  # NÃO é a senha, é "App Password" do Gmail
SMTP_AUTHENTICATION: plain
SMTP_ENABLE_STARTTLS_AUTO: "true"
SUPPORT_EMAIL: suporte@sua-empresa.com
```

**Para Gmail:**
1. Ative 2-FA em https://myaccount.google.com/security
2. Gere "App Password" em https://myaccount.google.com/apppasswords
3. Use esse password acima

---

## 🟣 OPCIONAIS - Storage S3/Cloud

Se quiser **salvar uploads no S3 (AWS)** ao invés do disco local:

```yaml
ACTIVE_STORAGE_SERVICE: amazon
AWS_ACCESS_KEY_ID: sua_chave
AWS_SECRET_ACCESS_KEY: sua_senha
AWS_REGION: us-east-1
AWS_BUCKET: seu_bucket_name
```

**Sem isso:** uploads são salvos em `/app/storage` (volume Docker)

---

## 🟣 OPCIONAIS - OAuth (Login Social)

Se quiser permitir **login com Google ou GitHub**:

```yaml
# Google
GOOGLE_OAUTH_CLIENT_ID: seu_id
GOOGLE_OAUTH_CLIENT_SECRET: seu_secret

# GitHub
GITHUB_OAUTH_CLIENT_ID: seu_id
GITHUB_OAUTH_CLIENT_SECRET: seu_secret
```

**Como obter:**
- Google: https://console.cloud.google.com
- GitHub: https://github.com/settings/applications/new

---

## 🟣 OPCIONAIS - Integrações (Slack, Twilio, etc)

```yaml
# Slack
SLACK_CLIENT_ID: seu_id
SLACK_CLIENT_SECRET: seu_secret

# Twilio
TWILIO_ACCOUNT_SID: seu_id
TWILIO_AUTH_TOKEN: seu_token
```

---

## 🟣 OPCIONAIS - Permitir Signup

Por padrão, novos usuários NÃO podem se registrar. Para permitir:

```yaml
ENABLE_ACCOUNT_SIGNUP: "true"
```

---

## ✅ Checklist para Produção

- [ ] `SECRET_KEY_BASE` foi alterada (mínimo 64 chars)
- [ ] `POSTGRES_PASSWORD` foi alterada
- [ ] `FRONTEND_URL` aponta para seu domínio real
- [ ] `RAILS_ENV: production` está configurado
- [ ] Se usar email: SMTP configurado e testado
- [ ] Se usar uploads: S3 ou volume persistente configurado
- [ ] Database e Redis estão com backups habilitados

---

## 📚 Referência Oficial

Mais variáveis em: https://github.com/chatwoot/chatwoot/blob/develop/.env.example
