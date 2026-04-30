# 🎯 Como Usar "Create from Schema" no EasyPanel

## ⚠️ IMPORTANTE: Cole APENAS Este JSON!

Se você colar o arquivo inteiro `meta.yaml`, vai dar erro React #31.

**Cole APENAS o schema abaixo:**

---

## 📋 COPIE E COLE ISTO:

```json
{
  "type": "object",
  "required": [
    "defaultLocale",
    "appServiceName",
    "appServiceImage",
    "sidekiqServiceName",
    "databaseServiceName",
    "redisServiceName"
  ],
  "properties": {
    "defaultLocale": {
      "type": "string",
      "title": "Idioma Padrão",
      "default": "pt-br"
    },
    "appServiceName": {
      "type": "string",
      "title": "Nome do Serviço App",
      "default": "chatwoot-crm"
    },
    "appServiceImage": {
      "type": "string",
      "title": "Docker Image",
      "default": "jhonnyxprite/chatwoot-crm:latest"
    },
    "sidekiqServiceName": {
      "type": "string",
      "title": "Nome do Serviço Sidekiq",
      "default": "chatwoot-sidekiq"
    },
    "databaseServiceName": {
      "type": "string",
      "title": "Nome do Serviço Database",
      "default": "chatwoot-db"
    },
    "redisServiceName": {
      "type": "string",
      "title": "Nome do Serviço Redis",
      "default": "chatwoot-redis"
    }
  }
}
```

---

## 📝 Passo-a-Passo

1. **Selecione o JSON acima** (da primeira `{` até a última `}`)
2. **Copie** (Ctrl+C ou Cmd+C)
3. **No EasyPanel**, clique em "Create from Schema"
4. **Cole no campo de Schema** (Ctrl+V ou Cmd+V)
5. **Clique "Validate"** ou "Check"
6. **Clique "Create Template"**
7. **Preencha o formulário** que vai aparecer (deixa padrão!)
8. **Clique "Deploy"**
9. **Aguarde 5-10 minutos** ✅

---

## ✨ Depois do Deploy

Você vai ter:
- ✅ PostgreSQL rodando
- ✅ Redis rodando
- ✅ Chatwoot App rodando (porta 3000)
- ✅ Sidekiq rodando

**Acesse:** `https://seu-dominio.com`

---

## 🆘 Se Ainda Desse Erro?

Se receber "Minified React error #31" novamente:

1. **Limpe o navegador:** F12 → Console → Delete cookies
2. **Tente incógnito:** Ctrl+Shift+P (ou Cmd+Shift+P)
3. **Tente outro navegador:** Chrome, Firefox, Safari, Edge

Se ainda não funcionar, entre em contato com suporte do EasyPanel.

---

**Pronto! Cole o JSON acima e era!** 🚀
