# Template Chatwoot CRM para EasyPanel

Este é um template **PERSONALIZADO** para deploy automático do Chatwoot com CRM no EasyPanel.

## 📁 Estrutura

```
templates/chatwoot/
├── meta.yaml          ← Define as propriedades e variáveis do template
├── index.ts           ← Lógica que gera os serviços automaticamente
├── assets/
│   └── logo.svg       ← Logo que aparece no EasyPanel
└── README.md          ← Este arquivo
```

## 🚀 Como Usar

### Opção 1: Via EasyPanel Dashboard (RECOMENDADO)

1. **Acesse seu EasyPanel**
   ```
   https://seu-easypanel.com
   ```

2. **Navegue até Templates/Applications**

3. **Opção A - Template Local:**
   - Clique em "Add Custom Template"
   - Selecione sua source como **Git**
   - URL: `https://github.com/seu-user/chatwoot-fork.git`
   - Path: `templates/chatwoot`
   - Clique "Create"

4. **Opção B - Deploy Direto:**
   - Procure por "Chatwoot CRM" nos templates
   - Clique "Deploy"
   - Customize as variáveis (opcional):
     - `Docker Image`: sua imagem customizada
     - `Default Locale`: seu idioma
     - Nomes dos serviços

5. **Aguarde 5-10 minutos**
   - PostgreSQL criado ✅
   - Redis criado ✅
   - Chatwoot rodando ✅
   - Migrations executadas ✅

6. **Acesse**
   ```
   https://seu-dominio.com
   ```

---

## 🔧 Variáveis Customizáveis

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `Docker Image` | `seu-dockerhub-user/chatwoot-crm:latest` | Sua imagem customizada |
| `Default Locale` | `pt-br` | Idioma (en, pt-br, etc) |
| `App Service Name` | `chatwoot-crm` | Nome do app no EasyPanel |
| `Database Service Name` | `chatwoot-db` | Nome do PostgreSQL |
| `Redis Service Name` | `chatwoot-redis` | Nome do Redis |

---

## ✨ O Que É Criado Automaticamente

### Serviços
- **Chatwoot App** — sua imagem customizada com CRM
- **Sidekiq** — processamento de background jobs
- **PostgreSQL** — banco de dados persistente
- **Redis** — cache e sessions

### Variáveis de Ambiente (auto-geradas)
- `SECRET_KEY_BASE` — chave aleatória segura
- `REDIS_PASSWORD` — senha aleatória
- `POSTGRES_PASSWORD` — senha aleatória
- `FEATURE_CRM_ENABLED=true` — seu CRM habilitado por padrão

### Volumes (Persistência)
- `/app/storage` — arquivos da aplicação
- `/data/storage` — dados do sistema
- Database PostgreSQL → volume persistente
- Redis → volume persistente

---

## 📝 Como Atualizar

Se você mudar algo no `meta.yaml` ou `index.ts`:

```bash
# 1. Commit as mudanças
git add templates/chatwoot/
git commit -m "update: template chatwoot improvements"
git push

# 2. No EasyPanel, refaça o deploy ou atualize o template
```

---

## 🐛 Troubleshooting

### Migrations falhando?
```bash
# Você pode rodar manualmente:
docker-compose exec chatwoot-crm bundle exec rails db:migrate
```

### Redis/Postgres não conectam?
```bash
# Verifique os nomes dos serviços no meta.yaml
# Eles devem corresponder aos que você digitou no EasyPanel
```

### Imagem customizada não encontrada?
```bash
# Garanta que:
1. Você fez push: docker push seu-user/chatwoot-crm:latest
2. A imagem é pública no DockerHub
3. O nome está correto no template
```

---

## 🎯 Próximos Passos

1. ✅ Template criado no seu repo
2. ⏭️ Push para GitHub
3. ⏭️ No EasyPanel, adicione como custom template
4. ⏭️ Deploy e customize
5. ⏭️ **PRONTO!** 🎉

---

## 📚 Recursos

- [Documentação EasyPanel](https://easypanel.io/docs)
- [Seu CRM Pipeline Plan](../docs/CRM-PIPELINE-PLAN.md)
- [GitHub Fork](https://github.com/seu-user/chatwoot-fork)

---

**Template criado em:** 2026-04-30  
**Seu nome:** seu-user  
**Status:** ✅ Pronto para usar!
