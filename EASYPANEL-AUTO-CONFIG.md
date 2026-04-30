# 🚀 EasyPanel - Deploy com Auto-Configuração

## ✅ Solução COMPLETA - EasyPanel Gera Tudo Sozinho

Agora você pode fazer deploy **sem digitar nada manualmente**! O EasyPanel vai:

1. ✅ Gerar senhas aleatórias
2. ✅ Configurar DATABASE_URL e REDIS_URL
3. ✅ Gerar SECRET_KEY_BASE (64 chars)
4. ✅ Apresentar formulário apenas para campos opcionais
5. ✅ Gerar docker-compose pronto para rodar

---

## 📋 Como Usar

### PASSO 1: No EasyPanel Dashboard

```
Applications → New Application
```

### PASSO 2: Selecione "Create from Schema"

```
Template Source:
  ○ Upload
  ○ Docker Image  
  ○ Create from Schema ← AQUI
```

### PASSO 3: Cole o Schema JSON

**Abra o arquivo:** `easypanel-schema.json`  
**Copie TUDO** (do `{` até o `}`)  
**Cole** no campo de Schema do EasyPanel

---

## 🎯 O que Aparece no Formulário

Quando você colar o schema, o EasyPanel vai mostrar um formulário com:

### 🔴 OBRIGATÓRIOS (preenchidos automaticamente):
- ✅ Nome do Serviço App (padrão: `a2-chatwoot`)
- ✅ Nome do Serviço PostgreSQL (padrão: `a2-postgres`)
- ✅ Nome do Serviço Redis (padrão: `a2-redis`)
- ✅ Nome do Serviço Sidekiq (padrão: `a2-sidekiq`)
- ✅ Senha do PostgreSQL (padrão: segura)
- ✅ SECRET_KEY_BASE (padrão: 64 chars aleatórios)
- ✅ URL Frontend (padrão: `http://localhost:3000`)

**Você não precisa mudar nada! Basta clicar Next/Deploy**

---

### 🟡 OPCIONAIS (você escolhe):

#### Email (SMTP)
- Habilitar envio de emails? (true/false)
- SMTP Address (ex: smtp.gmail.com)
- SMTP Port (587)
- SMTP Username (seu email)
- SMTP Password (app password)
- Email de Suporte

#### Uploads (S3)
- Usar S3? (true/false)
- AWS Access Key
- AWS Secret Key
- AWS Region
- AWS Bucket

#### Features
- ✅ Habilitar CRM? (padrão: true - você quer isto!)
- Permitir Signup de usuários? (padrão: false)

---

## 🎯 Deploy Agora

1. **Copia o arquivo** `easypanel-schema.json`
2. **No EasyPanel**, clica "Create from Schema"
3. **Cola** o JSON inteiro no campo
4. **Clica "Validate"** (opcional, recomendado)
5. **Preenche** apenas os opcionais que quer
6. **Clica "Deploy"**
7. **Aguarda 15-20 minutos** enquanto faz build
8. **Pronto!** 🎉

---

## 💡 O que Acontece Internamente

1. EasyPanel lê o schema JSON
2. Gera um formulário visual
3. Você preenche/valida
4. EasyPanel gera docker-compose.yml completo com TODAS as variáveis
5. EasyPanel faz `docker compose up --build`
6. Sua aplicação está rodando

**SEM COMPLICAÇÃO, SEM DIGITAÇÃO MANUAL, SEM ERROS**

---

## ⚡ Próxima Vez

Se precisar fazer deploy novamente:
1. Basta colar o schema de novo
2. As mesmas variáveis aparecem
3. Deploy em 5 minutos

---

## 📝 Customização

Se quiser mudar alguma variável depois:
1. Edite `easypanel-schema.json`
2. Mude os valores padrão (`default: "novo_valor"`)
3. Próximo deploy usa os novos padrões

---

**Agora é automático! Tudo pronto para rodar!** 🚀
