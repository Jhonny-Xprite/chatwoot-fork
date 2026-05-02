# Chatwoot Fork — Brownfield Architecture Document

> **Gerado por:** `@architect` via `brownfield-discovery` workflow — FASE 1  
> **Data:** 2026-04-27  
> **Versão:** 1.0  
> **Escopo:** Full codebase — meta: CRM com pipeline funcional para deploy no EasyPanel  
> **Projeto:** Fork pessoal de Chatwoot v4.13.0

---

## Change Log

| Data | Versão | Descrição | Autor |
|------|--------|-----------|-------|
| 2026-04-27 | 1.0 | Análise brownfield inicial — FASE 1 Discovery | @architect (Orion) |

---

## Quick Reference — Arquivos e Entry Points Críticos

| Propósito | Caminho |
|-----------|---------|
| Entry Rails | `config.ru`, `app/controllers/application_controller.rb` |
| Entry Frontend | `app/javascript/entrypoints/` |
| Dashboard App Vue | `app/javascript/dashboard/App.vue` |
| Rotas Frontend | `app/javascript/dashboard/routes/dashboard/dashboard.routes.js` |
| Schema DB | `db/schema.rb` (v2026_04_27_094500) |
| Seeds Dev | `db/seeds.rb` |
| Env config | `.env.example` → `.env` |
| Enterprise overlay | `enterprise/app/` |
| Modelo Conversation | `app/models/conversation.rb` |
| Modelo Contact | `app/models/contact.rb` |
| Modelo Account | `app/models/account.rb` |
| Services CRM existentes | `app/services/crm/` |
| Tailwind config | `tailwind.config.js` |
| Vite config | `vite.config.ts` |
| Procfile dev | `Procfile.dev` |

---

## High Level Architecture

### Technical Summary

Chatwoot é uma plataforma de customer engagement open-source construída como **Rails 7.1 monolith + Vue 3 SPA** com comunicação em tempo real via ActionCable. O fork mantém 100% da base original com adições do framework AIOX no diretório `.aiox-core/` e configurações de agentes em `.antigravity/`.

### Stack Tecnológico Atual

| Categoria | Tecnologia | Versão | Notas |
|-----------|------------|--------|-------|
| **Runtime Ruby** | Ruby | 3.4.4 | Gerenciado via `rbenv` |
| **Framework Web** | Rails | ~7.1 | API + Views híbrido |
| **Frontend Framework** | Vue 3 | ^3.5.12 | Composition API + `<script setup>` |
| **Estado Frontend (legado)** | Vuex | ~4.1.0 | Ainda dominante nas stores |
| **Estado Frontend (novo)** | Pinia | ^3.0.4 | Adotado em `stores/` (migration em curso) |
| **Build Frontend** | Vite 5 | ^5.4.21 | via `vite_rails` gem |
| **CSS** | Tailwind CSS | ^3.4.19 | Único sistema de estilo |
| **Banco de Dados** | PostgreSQL | — | com extensões: `pgvector`, `pg_trgm`, `pgcrypto` |
| **Cache/PubSub** | Redis | — | Sidekiq + ActionCable |
| **Background Jobs** | Sidekiq | >=7.3.1 | + sidekiq-cron |
| **Busca Full-Text** | Searchkick + OpenSearch | — | + `pg_search` para artigos |
| **Storage** | ActiveStorage | — | S3/GCS/Azure |
| **Auth** | Devise + devise_token_auth | — | JWT tokens |
| **Authoriz.** | Pundit | — | Policies em `app/policies/` |
| **LLM/AI** | ruby_llm >= 1.8.2, ai-agents >= 0.9.1 | — | Captain AI feature |
| **Vetores** | pgvector + neighbor | — | Embeddings para RAG |
| **Events/PubSub** | Wisper 2.0.0 | — | Dispatcher event system |
| **Package Manager** | pnpm 10.x | 10.2.0 | lockado |
| **Node** | Node.js | 24.x | `.nvmrc` presente |
| **Testes Ruby** | RSpec | >=6.1.5 | em `spec/` |
| **Testes JS** | Vitest | 3.0.5 | |
| **Process Manager** | Overmind | — | `pnpm dev` → overmind |

### Repository Structure

- **Tipo:** Monorepo único (Rails + Vue no mesmo repo)
- **Package Manager:** pnpm (lockado)
- **Estrutura:** Rails MVC + Assets gerenciados pelo Vite

---

## Source Tree e Organização de Módulos

### Estrutura de Diretórios (Real)

```
chatwoot-fork/
├── app/
│   ├── controllers/
│   │   ├── api/                    # REST API v1, v2, v3
│   │   ├── super_admin/            # Administrate dashboard
│   │   ├── platform/               # Platform API
│   │   └── [channel handlers]/     # webhooks, oauth callbacks
│   ├── models/
│   │   ├── conversation.rb         # ⭐ Core - status, priority, custom_attributes
│   │   ├── contact.rb              # ⭐ Core - contact_type (visitor/lead/customer)
│   │   ├── account.rb              # Multi-tenant root - feature flags, settings JSONB
│   │   ├── message.rb              # 17KB - mais complexo
│   │   ├── inbox.rb                # 8KB - multichannel abstraction
│   │   ├── user.rb                 # Agents + SuperAdmin
│   │   └── concerns/               # Mixins compartilhados
│   ├── javascript/
│   │   ├── dashboard/              # ⭐ Main SPA
│   │   │   ├── App.vue
│   │   │   ├── routes/dashboard/   # Rotas Vue Router 4
│   │   │   ├── store/              # Vuex stores (legado - em migração)
│   │   │   ├── stores/             # Pinia stores (novo padrão)
│   │   │   ├── components/         # Componentes globais (sendo deprecados)
│   │   │   ├── components-next/    # ⭐ Novo padrão - message bubbles
│   │   │   ├── composables/        # Vue 3 composables
│   │   │   ├── api/                # Axios API clients
│   │   │   ├── i18n/               # Translations (apenas en.json editável)
│   │   │   └── helper/             # Utils JS
│   │   ├── widget/                 # Chatwoot widget embed
│   │   ├── portal/                 # Help Center portal
│   │   ├── sdk/                    # SDK público
│   │   └── shared/                 # Código compartilhado entre apps
│   ├── services/
│   │   ├── conversations/          # Lógica de conversas
│   │   ├── contacts/               # Lógica de contatos
│   │   ├── crm/                    # ⭐ CRM existente (LeadSquared integration)
│   │   │   ├── base_processor_service.rb
│   │   │   └── leadsquared/        # Integração LeadSquared
│   │   ├── reports/                # Analytics e relatórios
│   │   ├── automation_rules/       # Motor de automação
│   │   └── [outros serviços]/
│   ├── jobs/                       # Sidekiq jobs
│   ├── policies/                   # Pundit authorization
│   └── listeners/                  # Wisper event listeners
├── enterprise/
│   └── app/                        # ⭐ Overlay Enterprise (prepend/include pattern)
│       ├── models/
│       ├── controllers/
│       ├── services/
│       └── policies/
├── db/
│   ├── schema.rb                   # Schema atual (version: 2026_04_27_094500)
│   ├── migrate/                    # Migrations
│   └── seeds.rb                    # Seeds dev + prod
├── config/
│   ├── routes.rb                   # Roteamento Rails
│   └── sidekiq.yml                 # Background jobs config
└── spec/                           # RSpec specs
    └── enterprise/                 # Specs enterprise-specific
```

### Routes Frontend — Dashboard

```
dashboard.routes.js
├── /                               # Dashboard principal (conversas)
├── /contacts                       # Contact list + detail
├── /companies                      # Companies CRM
├── /campaigns                      # Campaigns
├── /captain                        # AI Captain
├── /settings/                      # Settings routes
└── /notifications                  # Notificações
```

> ⚠️ **AUSENTE:** Não existe rota `/crm/pipeline` ou qualquer view de Kanban/Pipeline. **Esta é a feature a ser construída.**

---

## Data Models e APIs

### Modelos Core para CRM Pipeline

#### `Conversation` — Principal entidade de trabalho
```
Table: conversations
- status: enum { open:0, resolved:1, pending:2, snoozed:3 }
- priority: enum { low:0, medium:1, high:2, urgent:3 }
- custom_attributes: jsonb          ← ⭐ chave para pipeline stage
- additional_attributes: jsonb
- assignee_id → User
- team_id → Team
- contact_id → Contact
- inbox_id → Inbox
- last_activity_at: datetime
- waiting_since: datetime
```
> 💡 `custom_attributes` é o hook natural para armazenar `pipeline_stage`, `deal_value`, `close_date` sem nova coluna.

#### `Contact` — Lead/Cliente
```
Table: contacts
- contact_type: enum { visitor:0, lead:1, customer:2 }  ← ⭐ tipagem CRM já existe
- custom_attributes: jsonb
- additional_attributes: jsonb      ← company_name, city, country
- company_id → Company
- email, phone_number, identifier
- last_activity_at: datetime
```
> ✅ `contact_type: lead` já existe. `Contact.resolved_contacts(use_crm_v2: true)` retorna leads — **código CRM v2 experimental** presente.

#### `Account` — Multi-tenant Root
```
Table: accounts
- settings: jsonb (store_accessor pattern)
- feature_flags: bigint (FlagShihTzu)
- custom_attributes: jsonb
- internal_attributes: jsonb
```

#### Outros modelos relevantes para CRM
- **`Team`** — Agrupamento de agentes (pipeline stages podem ser mapeados por team)
- **`Label`** — Tags em conversas (alternativa a stages)
- **`CustomAttributeDefinition`** — Define campos customizados para Contact e Conversation
- **`Company`** — Empresa do contato (company_name, domain, contacts_count)
- **`AutomationRule`** — Motor de automação (trigger para mover stages)

### API REST — Estrutura Existente

```
/api/v1/accounts/:account_id/
├── contacts/                       # CRUD completo
├── contacts/:id/conversations      # Conversas por contato
├── conversations/                  # CRUD + filter
├── custom_attribute_definitions/   # Custom fields
├── companies/                      # Companies CRUD
├── teams/                          # Teams
├── automation_rules/               # Automações
└── reports/                        # Analytics
```

> ⚠️ **Pipeline API:** Não existe endpoint `/pipeline` ou `/kanban`. **Precisará ser criado.**

---

## CRM Existente — Estado Atual

### O que JÁ existe no Chatwoot com viés CRM

| Feature | Onde | Status |
|---------|------|--------|
| Contact types (visitor/lead/customer) | `Contact#contact_type` | ✅ Funcional |
| Custom Attributes (Contact + Conversation) | `CustomAttributeDefinition` | ✅ Funcional |
| Companies | `Company` model + routes | ✅ Funcional |
| Contact notes | `Note` model | ✅ Funcional |
| Conversation labels | `Label` + Labelable concern | ✅ Funcional |
| Conversation filters | `FilterService` + UI | ✅ Funcional |
| Team assignment | `Team` model | ✅ Funcional |
| Automation rules | `AutomationRule` | ✅ Funcional |
| CRM v2 experimental | `Contact.resolved_contacts(use_crm_v2: true)` | ⚠️ Parcial |
| LeadSquared CRM integration | `app/services/crm/leadsquared/` | ✅ Externo |
| Search (contacts + conversations) | `SearchService` + Searchkick | ✅ Funcional |

### O que FALTA para CRM com Pipeline funcional

| Feature | Impacto | Esforço |
|---------|---------|---------|
| Pipeline model (stages configuráveis) | 🔴 Crítico | Alto |
| Kanban/Pipeline board view | 🔴 Crítico | Alto |
| Deal/Opportunity model | 🟡 Importante | Médio |
| Pipeline stage tracking | 🟡 Importante | Médio |
| Pipeline-aware automations | 🟡 Importante | Médio |
| CRM dashboard/reports | 🟠 Desejável | Médio |
| Stage history/audit | 🟠 Desejável | Baixo |

---

## Enterprise Edition — Padrão de Extensão

### Como funciona o overlay Enterprise

```ruby
# No final de cada model OSS:
Account.prepend_mod_with('Account')
Conversation.include_mod_with('Concerns::Conversation')
```

- `prepend_mod_with` → método override (substitui)
- `include_mod_with` → method addition (adiciona)
- Arquivos enterprise em `enterprise/app/` espelham estrutura de `app/`

> ⚠️ **Para o fork pessoal:** Não é necessário manter overlay enterprise. Features novas podem ir diretamente em `app/`.

### Tabelas DB Enterprise-only relevantes

- `captain_assistants`, `captain_documents`, `captain_scenarios` — Captain AI
- `applied_slas`, `sla_policies` — SLA management
- `custom_roles`, `agent_capacity_policies` — Advanced RBAC

---

## Integration Points e Dependências Externas

### Para Deploy EasyPanel

| Serviço | Propósito | Config |
|---------|-----------|--------|
| **PostgreSQL** | DB principal | `DATABASE_URL` |
| **Redis** | Cache + Sidekiq + ActionCable | `REDIS_URL` |
| **SMTP** | Email | `SMTP_*` vars |
| **ActiveStorage** | File uploads | S3 ou local disk |
| **OpenSearch** (opcional) | Full-text search | `OPENSEARCH_URL` |

**Arquivos Docker disponíveis:**
- `docker-compose.yaml` — Dev
- `docker-compose.production.yaml` — Produção
- `docker/` — Dockerfiles
- `Procfile` — Produção (rails + sidekiq)

---

## Technical Debt e Issues Conhecidas

### Débitos Relevantes para CRM

| ID | Débito | Severidade | Relevância CRM |
|----|--------|------------|----------------|
| TD-01 | Vuex → Pinia migration incompleta | 🟡 Médio | Médio |
| TD-02 | `components/` sendo deprecado → `components-next/` | 🟡 Médio | Alto |
| TD-03 | Conversation sem state machine formal (FIXME no código) | 🟡 Médio | Alto |
| TD-04 | `contact_type` CRM v2 parcialmente implementado | 🟡 Médio | Crítico |
| TD-05 | Pipeline/Kanban completamente ausente | 🔴 Crítico | Crítico |
| TD-06 | Nenhuma rota CRM no frontend | 🔴 Crítico | Crítico |
| TD-07 | `app/services/crm/` só tem integração LeadSquared | 🟡 Médio | Alto |

### Workarounds e Gotchas

- **DB Triggers:** `display_id` e `uuid` de conversations são setados via trigger PostgreSQL
- **Enterprise pattern:** Verificar `enterprise/app/` antes de editar models/controllers/policies
- **I18n:** Editar APENAS `en.json` (frontend) e `en.yml` (backend)
- **Tailwind only:** Zero CSS customizado. Apenas utilities do Tailwind
- **`components-next/`:** Para novos componentes, usar SEMPRE `components-next/`
- **`<script setup>`:** Obrigatório em todos os novos componentes Vue

---

## Impact Analysis — CRM Pipeline Feature

### Decisão de Arquitetura — Approach para Pipeline

**Opção A — Conversations como Deals (recomendada para MVP):**
- Usa `Conversation` como entidade de deal
- `custom_attributes` armazena `pipeline_stage_id`, `deal_value`
- Menor esforço, integração natural com chat existente

**Opção B — Deal model separado:**
- Nova tabela `crm_deals`
- Mais flexível para múltiplos deals por contato
- Maior esforço, mais correto semanticamente

> 💡 **Recomendação:** Iniciar com **Opção A** (MVP rápido) e evoluir para B.

### Novos arquivos a criar

#### Backend
```
app/models/crm_pipeline.rb
app/models/crm_pipeline_stage.rb
app/controllers/api/v1/accounts/crm/pipelines_controller.rb
app/controllers/api/v1/accounts/crm/stages_controller.rb
app/services/crm/pipeline/
db/migrate/TIMESTAMP_create_crm_pipelines.rb
```

#### Frontend
```
app/javascript/dashboard/routes/dashboard/crm/
app/javascript/dashboard/components-next/crm/
  ├── PipelineBoard.vue
  ├── PipelineColumn.vue
  └── DealCard.vue
app/javascript/dashboard/stores/crm-pipeline.js
app/javascript/dashboard/api/crm.js
```

### Arquivos que serão modificados

| Arquivo | Motivo |
|---------|--------|
| `app/javascript/dashboard/routes/dashboard/dashboard.routes.js` | Adicionar rotas CRM |
| `config/routes.rb` | Adicionar endpoints API |
| `app/models/account.rb` | Feature flag para CRM pipeline |
| `app/javascript/dashboard/i18n/en.json` | Strings CRM |
| `config/locales/en.yml` | Strings backend |

---

## Comandos Frequentes

```bash
# Dev
pnpm dev                              # Inicia tudo (backend + worker + vite)
bundle exec rails console             # Rails console

# DB
bundle exec rails db:migrate          # Rodar migrations pendentes
bundle exec rails db:rollback         # Reverter última migration

# Lint
bundle exec rubocop -a                # Fix Ruby
pnpm eslint:fix                       # Fix JS/Vue

# Tests
bundle exec rspec spec/models/        # Specs de models
pnpm test                             # Vitest

# Seed
bundle exec rails db:seed
bundle exec rails runner "Internal::SeedAccountJob.perform_now(Account.first)"
```

---

## Apêndice

- **Chatwoot base:** v4.13.0 (commit `c8e551820`)
- **Schema version:** 2026_04_27_094500
- **Ruby:** 3.4.4 | **Node:** 24.x | **pnpm:** 10.2.0
- **API docs:** `swagger/` directory + `/swagger` route
- **Enterprise docs:** https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

---

*Gerado como parte do **Brownfield Discovery Workflow** (FASE 1). Documento de estado REAL do codebase.*
