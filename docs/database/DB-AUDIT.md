# Chatwoot Fork — DB Schema Audit

> **Gerado por:** `@data-engineer` via `brownfield-discovery` workflow — FASE 2  
> **Data:** 2026-04-27  
> **Versão:** 1.0  
> **Schema version:** `2026_04_27_094500`  
> **Total de tabelas:** ~65 tabelas

---

## 1. Extensões PostgreSQL Ativas

| Extensão | Uso |
|----------|-----|
| `pg_stat_statements` | Query performance monitoring |
| `pg_trgm` | Trigram full-text search (usado em contacts, messages, tags) |
| `pgcrypto` | `gen_random_uuid()` para conversation.uuid |
| `plpgsql` | Funções e triggers |
| `vector` | pgvector — embeddings para Captain AI (RAG) |

> ✅ **Todas as extensões são produção-ready.** `pgvector` disponível para feature de AI no CRM (ex: lead scoring semântico no futuro).

---

## 2. DB Triggers Ativos

| Trigger | Tabela | Evento | Efeito |
|---------|--------|--------|--------|
| `accounts_after_insert_row_tr` | `accounts` | AFTER INSERT | Cria sequence `conv_dpid_seq_<id>` |
| `camp_dpid_before_insert` | `accounts` | AFTER INSERT | Cria sequence `camp_dpid_seq_<id>` |
| `conversations_before_insert_row_tr` | `conversations` | BEFORE INSERT | Define `display_id` via sequence |
| `campaigns_before_insert_row_tr` | `campaigns` | BEFORE INSERT | Define `display_id` via sequence |

> ⚠️ **CRÍTICO:** Ao criar tabela `crm_pipelines` ou `crm_deals`, se precisar de `display_id` sequencial por conta, replicar o mesmo padrão de trigger. Não tente definir `display_id` via Ruby.

---

## 3. Foreign Keys Existentes

```
active_storage_attachments.blob_id → active_storage_blobs.id
active_storage_variant_records.blob_id → active_storage_blobs.id
inboxes.portal_id → portals.id
```

> ⚠️ **Maioria das FKs NÃO está declarada no schema** — Chatwoot usa referências sem FK constraint explícita (padrão histórico do projeto). Ao criar tabelas CRM, seguir o mesmo padrão: `references` sem `foreign_key: true` declarado no schema (mas indexar corretamente).

---

## 4. Tabelas Core — Análise CRM

### 4.1 `contacts` — ⭐ Entidade Central do CRM

```sql
contacts
  id             serial PK
  name           varchar  default ''
  email          varchar  UNIQUE(email, account_id)
  phone_number   varchar  UNIQUE(phone_number, account_id)
  account_id     integer  NOT NULL
  additional_attributes  jsonb  default {}
  identifier     varchar  UNIQUE(identifier, account_id)
  custom_attributes      jsonb  default {}
  last_activity_at       datetime
  contact_type           integer  default 0   -- visitor:0, lead:1, customer:2
  middle_name    varchar  default ''
  last_name      varchar  default ''
  location       varchar  default ''
  country_code   varchar  default ''
  blocked        boolean  default false
  company_id     bigint   -- FK→companies (sem constraint)
```

**Índices:**
| Índice | Colunas | Tipo | Status |
|--------|---------|------|--------|
| `uniq_email_per_account_contact` | (email, account_id) | UNIQUE | ✅ |
| `uniq_identifier_per_account_contact` | (identifier, account_id) | UNIQUE | ✅ |
| `index_contacts_on_account_id_and_contact_type` | (account_id, contact_type) | BTree | ✅ CRM |
| `index_contacts_on_account_id_and_last_activity_at` | (account_id, last_activity_at DESC NULLS LAST) | BTree | ✅ |
| `index_contacts_on_name_email_phone_number_identifier` | (name, email, phone, identifier) | GIN trgm | ✅ Search |
| `index_contacts_on_lower_email_account_id` | (lower(email), account_id) | BTree | ✅ |
| `index_contacts_on_nonempty_fields` | partial WHERE nonempty | BTree | ✅ |
| `index_resolved_contact_account_id` | partial WHERE nonempty | BTree | ✅ |

**Débitos CRM identificados:**
- ❌ **FALTANDO:** Índice em `(account_id, contact_type, last_activity_at)` — consultas de leads ordenados por atividade farão seq scan
- ❌ **FALTANDO:** Índice em `custom_attributes` — se pipeline_stage for armazenado aqui, queries sem índice

---

### 4.2 `conversations` — ⭐ Pipeline Deal Entity (Opção A)

```sql
conversations
  id             serial PK
  account_id     integer  NOT NULL
  inbox_id       integer  NOT NULL
  status         integer  default 0  -- open:0, resolved:1, pending:2, snoozed:3
  assignee_id    integer              -- FK→users
  contact_id     bigint               -- FK→contacts
  contact_inbox_id bigint             -- FK→contact_inboxes
  display_id     integer  NOT NULL   -- via trigger (per-account sequence)
  uuid           uuid     UNIQUE      -- gen_random_uuid()
  last_activity_at datetime NOT NULL  -- default CURRENT_TIMESTAMP
  team_id        bigint               -- FK→teams
  campaign_id    bigint
  snoozed_until  datetime
  custom_attributes jsonb  default {} -- ⭐ HOOK para pipeline_stage
  additional_attributes jsonb default {}
  first_reply_created_at datetime
  priority       integer              -- low:0, medium:1, high:2, urgent:3
  sla_policy_id  bigint
  waiting_since  datetime
  cached_label_list text
  assignee_agent_bot_id bigint
```

**Índices:**
| Índice | Colunas | Status CRM |
|--------|---------|-----------|
| `conv_acid_inbid_stat_asgnid_idx` | (account_id, inbox_id, status, assignee_id) | ✅ |
| `index_conversations_on_account_id` | (account_id) | ✅ |
| `index_conversations_on_status_and_account_id` | (status, account_id) | ✅ |
| `index_conversations_on_contact_id` | (contact_id) | ✅ |
| `index_conversations_on_team_id` | (team_id) | ✅ |
| `index_conversations_on_priority` | (priority) | ✅ |

**Débitos CRM identificados:**
- ❌ **FALTANDO:** Índice em `custom_attributes->>'pipeline_stage_id'` — necessário para Kanban queries
- ⚠️ `custom_attributes` é JSONB sem schema enforcement — risco de dados inconsistentes no pipeline

---

### 4.3 `companies` — Conta Empresarial

```sql
companies
  id             bigint PK
  name           varchar NOT NULL
  domain         varchar
  description    text
  account_id     bigint  NOT NULL
  contacts_count integer
```

**Índices:**
| Índice | Status |
|--------|--------|
| `index_companies_on_account_and_domain` UNIQUE WHERE domain NOT NULL | ✅ |
| `index_companies_on_name_and_account_id` | ✅ |

> ✅ Companies está bem estruturada. Pode ser utilizada como "Account" no CRM pipeline B2B.

---

### 4.4 `custom_attribute_definitions` — Campo Customizável

```sql
custom_attribute_definitions
  id                       bigint PK
  attribute_display_name   varchar
  attribute_key            varchar
  attribute_display_type   integer  default 0
  default_value            integer
  attribute_model          integer  default 0  -- conversation_attribute:0, contact_attribute:1
  account_id               bigint
  attribute_description    text
  attribute_values         jsonb  default []
  regex_pattern            varchar
  regex_cue                varchar
```

**Índice único:** `(attribute_key, attribute_model, account_id)`

> 💡 **Oportunidade CRM:** Pode-se criar `attribute_key: 'pipeline_stage'`, `attribute_model: conversation_attribute` sem nova coluna. Mas é lento para queries de bulk — **não use para filtros de Kanban com muitas conversas**.

---

### 4.5 `labels` — Sistema de Tags

```sql
labels
  id          bigint PK
  title       varchar
  description text
  color       varchar  NOT NULL  default '#1f93ff'
  show_on_sidebar boolean
  account_id  bigint
```

**UNIQUE:** `(title, account_id)`

> 💡 Labels podem ser usadas como lightweight pipeline stages sem nova tabela. Tradeoff: não têm ordem nem metadados de pipeline.

---

### 4.6 `teams` — Agrupamento de Agentes

```sql
teams
  id               bigint PK
  name             varchar NOT NULL
  description      text
  allow_auto_assign boolean default true
  account_id       bigint  NOT NULL
```

**UNIQUE:** `(name, account_id)`

> 💡 Teams podem representar stages de pipeline (ex: "Qualificação", "Proposta", "Fechamento"). Simples mas sem metadados de pipeline (order, color, etc).

---

### 4.7 `automation_rules` — Motor de Automação

```sql
automation_rules
  id           bigint PK
  account_id   bigint  NOT NULL
  name         varchar NOT NULL
  description  text
  event_name   varchar NOT NULL
  conditions   jsonb   NOT NULL
  actions      jsonb   NOT NULL
  active       boolean default true
```

> ✅ **Oportunidade CRM crítica:** AutomationRules pode ser usado para mover deals entre stages automaticamente baseado em eventos de conversa. Verificar eventos suportados antes de implementar pipeline automation.

---

### 4.8 `notes` — Notas do Contato

```sql
notes
  id          bigint PK
  content     text    NOT NULL
  account_id  bigint  NOT NULL
  contact_id  bigint  NOT NULL
  user_id     bigint
```

> ✅ Notes são um primitivo CRM completo. Já funciona como atividade/log do deal.

---

### 4.9 `reporting_events` — Analytics Base

```sql
reporting_events
  id              bigint PK
  name            varchar
  value           float
  account_id      integer
  inbox_id        integer
  user_id         integer
  conversation_id integer
  event_start_time datetime
  event_end_time   datetime
```

**Índices:** `(account_id, name, created_at)`, `(created_at)`, `(conversation_id)`

> 💡 **Para CRM Analytics:** Pipeline conversion metrics podem ser adicionadas como novos `name` values em `reporting_events`. Infraestrutura de aggregation já existe em `reporting_events_rollups`.

---

## 5. Tabelas Sem Relevância CRM Direta

| Grupo | Tabelas |
|-------|---------|
| **AI/Captain** | `captain_assistants`, `captain_documents`, `captain_scenarios`, `captain_assistant_responses`, `captain_custom_tools`, `captain_inboxes` |
| **Channels** | `channel_api`, `channel_email`, `channel_facebook_pages`, `channel_instagram`, `channel_line`, `channel_sms`, `channel_telegram`, `channel_tiktok`, `channel_twilio_sms`, `channel_twitter_profiles`, `channel_voice`, `channel_web_widgets`, `channel_whatsapp` |
| **Enterprise** | `sla_policies`, `applied_slas`, `sla_events`, `custom_roles`, `agent_capacity_policies`, `leaves` |
| **Infra** | `active_storage_*`, `action_mailbox_*`, `installation_configs`, `audits`, `webhooks` |
| **Help Center** | `portals`, `articles`, `categories`, `folders`, `article_embeddings` |
| **Copilot** | `copilot_messages`, `copilot_threads` |

---

## 6. JSONB Usage Pattern — Auditoria

| Tabela | Coluna JSONB | Uso Atual | Risco CRM |
|--------|-------------|-----------|-----------|
| `conversations` | `custom_attributes` | Campos customizáveis | ⚠️ Pipeline stage aqui → sem index |
| `conversations` | `additional_attributes` | Metadados de canal | 🟢 Baixo |
| `contacts` | `custom_attributes` | Campos customizáveis | ⚠️ Deal value aqui → sem index |
| `contacts` | `additional_attributes` | company_name, city, country | 🟢 Leitura apenas |
| `accounts` | `settings` | store_accessor config | 🟢 Baixo |
| `messages` | `content_attributes` | Tipo de mensagem específico | 🟢 Baixo |
| `automation_rules` | `conditions`/`actions` | Motor de regras | 🟢 Baixo |

> ⚠️ **Decisão crítica:** Se armazenar `pipeline_stage_id` em `conversations.custom_attributes`, será necessário criar um índice GIN ou funcional para queries de Kanban performáticas.

---

## 7. Análise de Índices — Score por Tabela

| Tabela | Índices Atuais | Missing (CRM) | Score |
|--------|---------------|---------------|-------|
| `contacts` | 9 | 2 | 🟡 7/10 |
| `conversations` | 15 | 1-2 | 🟡 8/10 |
| `companies` | 3 | 0 | ✅ 9/10 |
| `labels` | 2 | 0 | ✅ 9/10 |
| `notes` | 3 | 0 | ✅ 8/10 |
| `custom_attribute_definitions` | 2 | 0 | ✅ 8/10 |
| `automation_rules` | 1 | 0 | 🟡 6/10 |
| `reporting_events` | 7 | 0 | ✅ 9/10 |

---

## 8. Débitos de Database — Lista Consolidada

| ID | Débito | Tabela | Severidade | Horas Estimadas |
|----|--------|--------|------------|-----------------|
| DB-01 | Índice faltando: `(account_id, contact_type, last_activity_at)` | `contacts` | 🟡 Médio | 1h |
| DB-02 | Sem índice em `custom_attributes` para pipeline queries | `conversations` | 🟡 Médio | 1h |
| DB-03 | FKs sem constraint explícita (padrão histórico) | Geral | 🟠 Baixo | N/A (padrão) |
| DB-04 | `conversations.status` sem state machine — FIXME no código | `conversations` | 🟡 Médio | 2h |
| DB-05 | Timestamps sem microsecond precision em tabelas antigas | `conversations`, `contacts` | 🟠 Baixo | Migration simples |
| DB-06 | **FALTANDO tabela `crm_pipelines`** | — | 🔴 Crítico | 4-6h |
| DB-07 | **FALTANDO tabela `crm_pipeline_stages`** | — | 🔴 Crítico | 3-4h |
| DB-08 | **FALTANDO FK `conversations.pipeline_stage_id`** | `conversations` | 🔴 Crítico | 2h |

---

## 9. Schema Proposto — Tabelas CRM Pipeline

### 9.1 Migration: `crm_pipelines`

```ruby
create_table :crm_pipelines do |t|
  t.bigint  :account_id,  null: false
  t.string  :name,        null: false
  t.text    :description
  t.boolean :active,      default: true, null: false
  t.integer :position,    default: 0,    null: false
  t.timestamps
  
  t.index [:account_id], name: 'index_crm_pipelines_on_account_id'
  t.index [:account_id, :name], unique: true,
          name: 'index_crm_pipelines_on_account_id_and_name'
end
```

### 9.2 Migration: `crm_pipeline_stages`

```ruby
create_table :crm_pipeline_stages do |t|
  t.bigint  :account_id,   null: false
  t.bigint  :pipeline_id,  null: false
  t.string  :name,         null: false
  t.text    :description
  t.string  :color,        default: '#1f93ff', null: false
  t.integer :position,     null: false
  t.boolean :active,       default: true, null: false
  t.timestamps
  
  t.index [:pipeline_id], name: 'index_crm_pipeline_stages_on_pipeline_id'
  t.index [:account_id],  name: 'index_crm_pipeline_stages_on_account_id'
  t.index [:pipeline_id, :position], 
          name: 'index_crm_pipeline_stages_on_pipeline_id_and_position'
end
```

### 9.3 Migration: `add_pipeline_to_conversations`

```ruby
add_column :conversations, :pipeline_id,       :bigint
add_column :conversations, :pipeline_stage_id, :bigint

add_index :conversations, [:account_id, :pipeline_stage_id],
          name: 'index_conversations_on_account_id_and_pipeline_stage_id'
add_index :conversations, [:pipeline_id],
          name: 'index_conversations_on_pipeline_id'
add_index :conversations, [:pipeline_stage_id],
          name: 'index_conversations_on_pipeline_stage_id'
```

### 9.4 Índices Adicionais Recomendados

```ruby
# Para queries de leads por contact_type
add_index :contacts, [:account_id, :contact_type, :last_activity_at],
          order: { last_activity_at: :desc },
          name: 'index_contacts_crm_type_activity'

# Para pipeline board queries (paginação por stage)
add_index :conversations, 
          [:account_id, :pipeline_stage_id, :last_activity_at],
          order: { last_activity_at: :desc },
          name: 'index_conversations_pipeline_stage_activity'
```

---

## 10. Estratégia de Migration

### Ordem Recomendada

```
Migration 1: create_crm_pipelines
Migration 2: create_crm_pipeline_stages
Migration 3: add_pipeline_stage_to_conversations
Migration 4: add_index_contacts_crm_type_activity
Migration 5: seed_default_pipeline (via seeds ou migration data)
```

### Seed de Pipeline Padrão

```ruby
# db/seeds.rb ou via SeedAccountJob
Account.find_each do |account|
  pipeline = CrmPipeline.create!(
    account: account,
    name: 'Sales Pipeline',
    position: 0
  )
  
  ['New Lead', 'Qualified', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost'].each_with_index do |stage_name, idx|
    CrmPipelineStage.create!(
      account: account,
      pipeline: pipeline,
      name: stage_name,
      position: idx,
      color: ['#6366f1', '#3b82f6', '#f59e0b', '#ef4444', '#10b981', '#6b7280'][idx]
    )
  end
end
```

---

## 11. Verificação de RLS / Segurança

> Chatwoot NÃO usa Row Level Security (RLS) do PostgreSQL. Toda segurança por tenant é feita via `account_id` em cada query (Rails multi-tenant via scope).

**Padrão obrigatório para tabelas CRM:**
```ruby
# Sempre filtrar por account_id
CrmPipeline.where(account_id: current_account.id)
# Nunca:
CrmPipeline.find(id)  # ← vazamento cross-tenant
```

> ⚠️ **Débito de Segurança:** Sem RLS no DB — depende 100% da aplicação para isolation de tenant. Para uso pessoal (single account) o risco é baixo.

---

## 12. Performance — Consultas Críticas do Kanban

### Query Projetada: Carregar Kanban Board

```sql
-- Eficiente com índice proposto
SELECT c.*, ct.name as contact_name, ct.email
FROM conversations c
JOIN contacts ct ON ct.id = c.contact_id  
WHERE c.account_id = $1
  AND c.pipeline_id = $2
  AND c.status = 0  -- open
ORDER BY c.pipeline_stage_id, c.last_activity_at DESC
LIMIT 50;
-- Usa: index_conversations_on_account_id_and_pipeline_stage_id
```

### Query Projetada: Contagem por Stage (Kanban Header)

```sql
SELECT pipeline_stage_id, COUNT(*) as count
FROM conversations
WHERE account_id = $1
  AND pipeline_id = $2
  AND status = 0
GROUP BY pipeline_stage_id;
-- Usa: índice composto account_id + pipeline_stage_id
```

> 💡 Ambas as queries serão performáticas com os índices propostos.

---

## 13. Recomendações Prioritárias

| Prioridade | Ação | Justificativa |
|-----------|------|---------------|
| P0 | Criar migrations `crm_pipelines` + `crm_pipeline_stages` | Blocker para qualquer feature CRM |
| P0 | Adicionar `pipeline_stage_id` em conversations | Blocker para Kanban queries |
| P1 | Índice em `(account_id, pipeline_stage_id, last_activity_at)` | Performance Kanban |
| P1 | Índice em `(account_id, contact_type, last_activity_at)` | Performance lead list |
| P2 | Seed pipeline padrão | UX — usuário precisa de pipeline para testar |
| P3 | Avaliar RLS no PostgreSQL | Segurança para futuro multi-tenant |

---

*Gerado como parte do **Brownfield Discovery Workflow** (FASE 2). Para análise de frontend, ver FASE 3.*
