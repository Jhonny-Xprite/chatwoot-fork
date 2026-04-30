# CRM Pipeline — Implementation Plan

> **Gerado por:** `@aiox-master` orquestrando brownfield-discovery — FASES 4-10  
> **Data:** 2026-04-27  
> **Status:** ✅ PRONTO PARA IMPLEMENTAÇÃO  
> **Meta:** CRM com Pipeline Kanban funcional no fork Chatwoot → EasyPanel

---

## Brownfield Discovery — Summary

### Documentos Gerados

| Fase | Output | Path |
|------|--------|------|
| FASE 1 — Arquitetura | `system-architecture.md` | `docs/architecture/` |
| FASE 2 — DB Audit | `DB-AUDIT.md` | `docs/database/` |
| FASE 3 — Frontend Spec | `FRONTEND-SPEC.md` | `docs/frontend/` |

### Descobertas Críticas

| Área | Descoberta |
|------|-----------|
| ✅ DB | `contacts.contact_type` já tem `lead` enum |
| ✅ DB | `conversations.custom_attributes` é hook natural para pipeline |
| ✅ Frontend | `vuedraggable` já instalado — Kanban sem nova dep |
| ✅ Frontend | Todos os componentes base em `components-next/` disponíveis |
| ✅ Backend | `app/services/crm/` existe — estrutura pronta para expandir |
| ✅ Backend | `AutomationRule` pode mover deals automaticamente |
| 🔴 Missing | Zero tabelas de pipeline no DB |
| 🔴 Missing | Zero rotas/views de CRM no frontend |
| 🔴 Missing | Zero endpoints API de pipeline |

---

## Technical Debt Consolidado

### Backend (Ruby/Rails)

| ID | Débito | Prioridade |
|----|--------|-----------|
| TD-BE-01 | Criar tabelas `crm_pipelines` + `crm_pipeline_stages` | P0 🔴 |
| TD-BE-02 | Adicionar `pipeline_stage_id` em `conversations` | P0 🔴 |
| TD-BE-03 | Criar API endpoints CRM (pipelines, stages, deals) | P0 🔴 |
| TD-BE-04 | Pundit policies para CRM resources | P1 🟡 |
| TD-BE-05 | Conversation status sem state machine formal (FIXME) | P2 🟠 |

### Database

| ID | Débito | Prioridade |
|----|--------|-----------|
| TD-DB-01 | Índice faltando: `(account_id, pipeline_stage_id, last_activity_at)` | P0 🔴 |
| TD-DB-02 | Índice faltando: `(account_id, contact_type, last_activity_at)` | P1 🟡 |
| TD-DB-03 | Seed de pipeline padrão (6 stages) | P1 🟡 |

### Frontend (Vue 3)

| ID | Débito | Prioridade |
|----|--------|-----------|
| TD-FE-01 | Criar rotas CRM (`/crm/pipelines`) | P0 🔴 |
| TD-FE-02 | Criar `PipelineBoard.vue` Kanban | P0 🔴 |
| TD-FE-03 | Criar `PipelineColumn.vue` + `DealCard.vue` | P0 🔴 |
| TD-FE-04 | Criar Pinia store `crm-pipeline.js` | P0 🔴 |
| TD-FE-05 | Criar API client `crm-pipeline.js` | P0 🔴 |
| TD-FE-06 | Adicionar nav item CRM na sidebar | P1 🟡 |
| TD-FE-07 | Strings i18n para CRM (`en.json`) | P1 🟡 |
| TD-FE-08 | `CreateDealDialog.vue` | P1 🟡 |
| TD-FE-09 | Vuex → Pinia migration (ongoing) | P3 🟠 |

---

## Plano de Implementação MVP

### Decisão de Arquitetura

**✅ Opção A — Conversations como Deals (MVP)**
- `Conversation` = Deal/Oportunidade
- `conversations.pipeline_stage_id` → FK para `crm_pipeline_stages`
- `conversations.custom_attributes` armazena `deal_value`, `close_date`
- Kanban mostra conversas agrupadas por stage
- Vantagem: menor esforço, integração natural com chat

---

## FASE 1 — Database & Backend API

**Estimativa:** 8-12 horas  
**Objetivo:** Schema + API funcionais para o Kanban consumir

### Tarefas

```
[ ] 1.1 Migration: create_crm_pipelines
[ ] 1.2 Migration: create_crm_pipeline_stages  
[ ] 1.3 Migration: add_pipeline_stage_id_to_conversations
[ ] 1.4 Migration: add_indexes_for_crm_pipeline
[ ] 1.5 Model: CrmPipeline (validações + belongs_to :account)
[ ] 1.6 Model: CrmPipelineStage (validações + ordenação)
[ ] 1.7 Model scope: Conversation.in_pipeline(id), .in_stage(id)
[ ] 1.8 Controller: Api::V1::Accounts::Crm::PipelinesController
[ ] 1.9 Controller: Api::V1::Accounts::Crm::PipelineStagesController
[ ] 1.10 Controller: update conversations#update para aceitar pipeline_stage_id
[ ] 1.11 Policy: CrmPipelinePolicy (Pundit — admins e agents)
[ ] 1.12 Routes: namespace :crm dentro de accounts
[ ] 1.13 Seed: Pipeline padrão "Sales Pipeline" com 6 stages
[ ] 1.14 i18n backend: strings em en.yml
```

### Estrutura de Routes Rails

```ruby
# config/routes.rb
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    resources :accounts do
      namespace :crm do
        resources :pipelines do
          resources :stages, controller: 'pipeline_stages'
          get 'conversations', to: 'pipeline_conversations#index'
        end
      end
    end
  end
end
```

### Models a Criar

```ruby
# app/models/crm_pipeline.rb
class CrmPipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'CrmPipelineStage', 
           foreign_key: :pipeline_id, dependent: :destroy
  has_many :conversations, foreign_key: :pipeline_id
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :account_id }
  
  scope :active, -> { where(active: true) }
  default_scope { order(:position) }
end

# app/models/crm_pipeline_stage.rb
class CrmPipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline, class_name: 'CrmPipeline'
  has_many :conversations, foreign_key: :pipeline_stage_id
  
  validates :name, presence: true
  validates :position, presence: true
  
  scope :active, -> { where(active: true) }
  default_scope { order(:position) }
end
```

### Response Format (JSON)

```json
// GET /api/v1/accounts/:id/crm/pipelines
{
  "payload": [
    {
      "id": 1,
      "name": "Sales Pipeline",
      "position": 0,
      "active": true,
      "stages": [
        { "id": 1, "name": "New Lead", "position": 0, "color": "#6366f1", "conversations_count": 5 },
        { "id": 2, "name": "Qualified", "position": 1, "color": "#3b82f6", "conversations_count": 3 }
      ]
    }
  ]
}

// GET /api/v1/accounts/:id/crm/pipelines/:pid/conversations?stage_id=1&page=1
{
  "payload": [...conversations],
  "meta": { "current_page": 1, "total_count": 5 }
}
```

---

## FASE 2 — Frontend Kanban Board

**Estimativa:** 15-20 horas  
**Objetivo:** Kanban board funcional com drag & drop

### Tarefas

```
[ ] 2.1 API client: app/javascript/dashboard/api/crm-pipeline.js
[ ] 2.2 Pinia store: app/javascript/dashboard/stores/crm-pipeline.js
[ ] 2.3 i18n: adicionar CRM strings em en.json
[ ] 2.4 Routes: app/javascript/dashboard/routes/dashboard/crm/routes.js
[ ] 2.5 Register routes in dashboard.routes.js
[ ] 2.6 Component: PipelineHeader.vue (pipeline selector + view toggle)
[ ] 2.7 Component: PipelineBoard.vue (board container)
[ ] 2.8 Component: PipelineColumn.vue (stage column + vuedraggable)
[ ] 2.9 Component: DealCard.vue (conversation card)
[ ] 2.10 Component: DealCardSkeleton.vue (loading state)
[ ] 2.11 Component: CreateDealDialog.vue (modal create conversation)
[ ] 2.12 Sidebar: adicionar CRM nav item
[ ] 2.13 Drag & Drop: mover deal entre stages via patch conversation
[ ] 2.14 Empty state: EmptyStateLayout para stage vazia
[ ] 2.15 Testes manuais: criar deal, mover, filtrar
```

### PipelineBoard.vue — Estrutura

```vue
<template>
  <div class="flex flex-col h-full">
    <PipelineHeader
      :pipelines="pipelines"
      :selected-pipeline="selectedPipeline"
      @select-pipeline="onSelectPipeline"
      @create-deal="showCreateDialog = true"
    />
    
    <div class="flex flex-1 gap-4 overflow-x-auto p-4">
      <PipelineColumn
        v-for="stage in selectedPipeline.stages"
        :key="stage.id"
        :stage="stage"
        :deals="dealsByStage[stage.id]"
        @move-deal="onMoveDeal"
      />
    </div>
    
    <CreateDealDialog
      v-if="showCreateDialog"
      :pipeline="selectedPipeline"
      @close="showCreateDialog = false"
      @created="onDealCreated"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { usePipelineStore } from '@/stores/crm-pipeline';
import PipelineHeader from '@/components-next/crm/PipelineHeader.vue';
import PipelineColumn from '@/components-next/crm/PipelineColumn.vue';
import CreateDealDialog from '@/components-next/crm/CreateDealDialog.vue';

const store = usePipelineStore();
const showCreateDialog = ref(false);
const selectedPipelineId = ref(null);

const pipelines = computed(() => store.getPipelineList);
const selectedPipeline = computed(() =>
  store.getPipelineById(selectedPipelineId.value)
);
const dealsByStage = computed(() => store.getDealsByStage);

onMounted(async () => {
  await store.loadPipelines();
  selectedPipelineId.value = pipelines.value[0]?.id;
});
</script>
```

---

## FASE 3 — Polimento & Automação (Futuro)

**Estimativa:** 10-15 horas  
**Objetivo:** Automações e UX refinements

### Tarefas

```
[ ] 3.1 AutomationRule: action "move_to_pipeline_stage"
[ ] 3.2 Webhook events: pipeline_stage_changed
[ ] 3.3 Deal filters: filtrar por stage, assignee, label, data
[ ] 3.4 Deal search: busca dentro do pipeline
[ ] 3.5 Contact page: link para deals do contato
[ ] 3.6 Company page: link para todos os deals da empresa
[ ] 3.7 Deal analytics: funil de conversão por stage
[ ] 3.8 Stage history: log de quando deal mudou de stage
```

---

## Deploy — EasyPanel

### Checklist Pré-Deploy

```bash
# 1. Rodar migrations em produção
bundle exec rails db:migrate RAILS_ENV=production

# 2. Seed do pipeline padrão (se necessário)
bundle exec rails runner "require_relative 'db/seeds/crm_pipeline_seed'"

# 3. Build assets
bundle exec rails assets:precompile RAILS_ENV=production

# 4. Reiniciar serviços
# Via EasyPanel UI → Restart
```

### Variáveis de Ambiente Necessárias

```bash
# Existentes (não mudam)
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
SECRET_KEY_BASE=...
FRONTEND_URL=https://seu-dominio.com
RAILS_ENV=production

# CRM Pipeline — sem novas variáveis necessárias!
```

---

## Critérios de Aceite MVP

### FASE 1 ✅ quando:
- [ ] `rails db:migrate` roda sem erros
- [ ] `GET /api/v1/accounts/1/crm/pipelines` retorna pipeline com stages
- [ ] `GET /api/v1/accounts/1/crm/pipelines/1/conversations?stage_id=1` retorna deals
- [ ] `PATCH /api/v1/accounts/1/conversations/1` aceita `pipeline_stage_id`
- [ ] Pundit bloqueia acesso cross-account

### FASE 2 ✅ quando:
- [ ] Rota `/crm` acessível via sidebar
- [ ] Kanban renderiza colunas com deals
- [ ] Drag & drop move deal entre stages
- [ ] "New Deal" abre modal e cria conversa no stage correto
- [ ] Cards exibem: nome do contato, avatar, último contato, assignee, labels
- [ ] Stage columns exibem contagem de deals no header
- [ ] Loading states com skeleton cards

---

## Próximos Passos Imediatos

> **Iniciar FASE 1 agora** — criar as migrations e models do pipeline.

```bash
# Sequência de implementação
bundle exec rails g migration CreateCrmPipelines
bundle exec rails g migration CreateCrmPipelineStages  
bundle exec rails g migration AddPipelineStageIdToConversations
# → editar migrations
bundle exec rails db:migrate
# → criar models + controllers + routes
# → testar via curl ou Swagger
# → iniciar FASE 2 frontend
```

---

*Documento gerado ao final do **Brownfield Discovery Workflow** (Fases 1-4). Pronto para handoff ao time de desenvolvimento.*
