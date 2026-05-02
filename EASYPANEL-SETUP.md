# 🚀 Como Usar Seu Template Chatwoot CRM no EasyPanel

## ✅ O Que Foi Criado

Seu template personalizado está pronto em:
```
templates/chatwoot/
├── meta.yaml          ← Schema (variáveis customizáveis)
├── index.ts           ← Lógica (cria serviços automaticamente)
├── assets/
│   └── logo.svg       ← Logo que aparece no EasyPanel
└── README.md          ← Documentação
```

**Commit:** `fab8d0012`

---

## 📝 Pré-Requisitos

1. ✅ **Imagem Docker pronta**
   ```bash
   # Você já tem isso feito:
   docker build -f Dockerfile -t seu-dockerhub-user/chatwoot-crm:latest .
   docker push seu-dockerhub-user/chatwoot-crm:latest
   ```

2. ✅ **GitHub Push**
   ```bash
   git push origin feat/crm-advanced-filters-automation
   ```

3. ✅ **EasyPanel Acesso**
   - URL: https://easypanel.jhonnyxprite.com
   - Email: equipe@jhonnyxprite.com

---

## 🎯 Instalação no EasyPanel (3 Passos)

### **Passo 1: Acesse o Dashboard**
```
https://easypanel.jhonnyxprite.com
Login com equipe@jhonnyxprite.com
```

### **Passo 2: Adicionar Template Customizado**

1. Navegue até **Applications** ou **Templates**
2. Clique em **"Add Custom Template"** ou **"New Template"**
3. Preencha:
   ```
   Source Type:    Git Repository
   Repository URL: https://github.com/seu-user/chatwoot-fork.git
   Branch:         feat/crm-advanced-filters-automation (ou main)
   Template Path:  templates/chatwoot
   ```
4. Clique **"Create"** ou **"Add"**

### **Passo 3: Deploy**

1. No dashboard, procure por **"Chatwoot CRM"** (seu novo template)
2. Clique **"Deploy"**
3. Na forma que aparecer, customize (opcional):
   ```
   App Service Name:      chatwoot-crm
   Docker Image:          seu-dockerhub-user/chatwoot-crm:latest
   Default Locale:        pt-br
   Database Service Name: chatwoot-db
   Redis Service Name:    chatwoot-redis
   ```
4. Clique **"Deploy"**
5. Aguarde 5-10 minutos

---

## ⏳ O Que Acontece Automaticamente

EasyPanel vai:

✅ **Criar PostgreSQL**
- Imagem: pgvector:pg17
- Database: seu-projeto
- User: postgres
- Password: gerada aleatoriamente

✅ **Criar Redis**
- Imagem: valkey:7.2.5-alpine
- Password: gerada aleatoriamente

✅ **Criar Chatwoot App**
- Imagem: sua-imagem:latest
- Porta: 3000
- Comando: `bundle exec rails db:chatwoot_prepare && rails s`
- Volumes: /app/storage, /data/storage

✅ **Criar Sidekiq**
- Mesmo que Chatwoot mas rodando: `bundle exec sidekiq`
- Para processamento de background jobs

✅ **Executar Migrations**
- Automaticamente ao iniciar

✅ **Gerar Variáveis de Ambiente**
```
SECRET_KEY_BASE=<aleatório>
REDIS_PASSWORD=<aleatório>
POSTGRES_PASSWORD=<aleatório>
FEATURE_CRM_ENABLED=true
RAILS_ENV=production
```

---

## 🌐 Acessar Sua Instalação

Após deploy concluído (5-10 minutos):

```
https://seu-dominio.com
```

Ou via IP do EasyPanel:
```
http://seu-ip:3000
```

**Login padrão:**
- Email: admin@chatwoot.com
- Password: será criada durante setup (verifique logs)

---

## 📋 Checklist pós-Deploy

- [ ] Consegue acessar https://seu-dominio.com
- [ ] Login funciona
- [ ] Menu CRM aparece na sidebar
- [ ] Clica em CRM → vê o Kanban Board
- [ ] Cria um novo pipeline (ex: "Sales")
- [ ] Adiciona stages (Lead, Qualified, Won, Lost)
- [ ] Cria um deal
- [ ] Arrasta deal entre stages (drag & drop)
- [ ] Filtra por labels
- [ ] Busca por contato

Se tudo ok → **PRONTO!** 🎉

---

## 🔧 Troubleshooting

### Erro: "Template not found"
```
→ Verifique URL do repositório
→ Verifique se branch existe
→ Verifique se path = templates/chatwoot
```

### Erro: "Docker image not found"
```
→ Verifique se fez push: docker push seu-user/chatwoot-crm:latest
→ Verifique se é pública no DockerHub
→ Verifique nome exato no template
```

### PostgreSQL/Redis não conectam
```
→ Aguarde mais tempo (primeiras vezes são lentas)
→ Verifique logs no EasyPanel
→ Verifique nomes dos serviços no template
```

### Migrations falhando
```
→ Acesse o container Chatwoot
→ Execute manualmente: bundle exec rails db:migrate
→ Verifique config/database.yml
```

---

## 📚 Documentação Relacionada

- [CRM Pipeline Plan](docs/CRM-PIPELINE-PLAN.md)
- [Template README](templates/chatwoot/README.md)
- [EasyPanel Docs](https://easypanel.io/docs)

---

## ✨ O Que Mudou

Antes: Tinha que fazer tudo manualmente
```bash
ssh root@seu-vps
docker run ... postgres
docker run ... redis
docker run ... chatwoot
...10+ comandos
```

Agora: Um clique no EasyPanel
```
Dashboard → Templates → Chatwoot CRM → Deploy
```

**Economia de tempo:** 30+ minutos → 2 cliques! ⏱️

---

## 🎯 Próximas Ações

1. ✅ Template criado
2. ✅ Commit feito
3. ⏭️ **AGORA:** Push para GitHub (já foi no commit anterior)
4. ⏭️ **ENTÃO:** Vá ao EasyPanel e siga os passos acima
5. ⏭️ **PRONTO:** Deploy automático!

---

**Template Status:** ✅ **PRONTO PARA USO**  
**Criado em:** 2026-04-30  
**Commit:** fab8d0012

Qualquer dúvida, é só chamar! 🚀
