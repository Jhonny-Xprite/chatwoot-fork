# Chatwoot Fork — Frontend Spec & UX Audit

> **Gerado por:** `@ux-design-expert` via `brownfield-discovery` workflow — FASE 3  
> **Data:** 2026-04-27  
> **Versão:** 1.0  
> **Foco:** Análise frontend + spec para CRM Pipeline Kanban

---

## 1. Stack Frontend — Estado Real

| Tecnologia | Versão | Status |
|-----------|--------|--------|
| Vue 3 | ^3.5.12 | ✅ Ativo |
| Vue Router 4 | ~4.4.5 | ✅ Ativo |
| Vuex 4 (legado) | ~4.1.0 | ⚠️ Em migração |
| Pinia 3 | ^3.0.4 | ✅ Novo padrão |
| Tailwind CSS | ^3.4.19 | ✅ Único sistema de estilo |
| Vite 5 | ^5.4.21 | ✅ Build |
| Axios | ^1.15.0 | ✅ HTTP client |
| VueUse | ^12.0.0 | ✅ Composables utilitários |
| vue-i18n | 9.14.5 | ✅ I18n |
| vuedraggable | ^4.1.0 | ✅ **Drag & Drop disponível!** |
| @tanstack/vue-table | ^8.20.5 | ✅ Tabelas |

> 🎯 **`vuedraggable` já instalado** — pode ser usado diretamente para o Kanban board sem nova dependência.

---

## 2. Design System — Padrões Existentes

### 2.1 Fonte de Verdade dos Componentes

```
app/javascript/dashboard/components-next/   ← NOVO PADRÃO (usar sempre)
app/javascript/dashboard/components/        ← LEGADO (sendo deprecado)
```

### 2.2 Componentes Disponíveis em `components-next/`

| Componente | Localização | Uso CRM |
|-----------|------------|---------|
| `button/` | Botões — primário, secundário, ghost | ✅ Cards, actions |
| `input/` | Inputs text, search | ✅ Filtros |
| `select/` | Select dropdown | ✅ Stage selector |
| `combobox/` | Combobox com search | ✅ Assignee picker |
| `dialog/` | Modal dialog | ✅ Create deal |
| `dropdown-menu/` | Dropdown menu | ✅ Card actions |
| `popover/` | Popover | ✅ Quick edit |
| `badge` / `label/` | Labels coloridos | ✅ Stage badge |
| `avatar/` | Avatar com iniciais | ✅ Contact avatar |
| `table/` | TanStack table wrapper | ✅ Deal list view |
| `filter/` | Sistema de filtros | ✅ Pipeline filters |
| `spinner/` | Loading states | ✅ Async |
| `pagination/` | Paginação | ✅ Deal cards por page |
| `sidebar/` | Sidebar navigation | ✅ Nav CRM |
| `tabbar/` | Tabs | ✅ Pipeline / List view toggle |
| `inline-input/` | Inline edit | ✅ Deal title edit |
| `CardLayout.vue` | Layout card genérico | ✅ Deal card base |
| `EmptyStateLayout.vue` | Estado vazio | ✅ Pipeline vazio |

### 2.3 Padrões de Cores (Tailwind)

> Ver `tailwind.config.js` para palette completa. Padrões CRM esperados:

```js
// Cores de status / pipeline stages
'woot-500'   // primário — azul Chatwoot
'green-500'  // success — Closed Won
'red-500'    // danger — Closed Lost
'yellow-500' // warning — Em risco
'gray-200'   // borders, backgrounds
```

### 2.4 Sidebar Navigation Pattern

```
app/javascript/dashboard/components-next/sidebar/
```
- Sidebar usa ícones do sistema `@egoist/tailwindcss-icons` (Lucide, Phosphor, Material Symbols)
- Novos itens de nav CRM devem seguir o mesmo padrão de `sidebar/`

---

## 3. Routing — Padrão Atual

### 3.1 Como uma rota é adicionada

```js
// dashboard.routes.js
import { routes as crmRoutes } from './crm/routes';

// Adicionar em children:
...crmRoutes,
```

### 3.2 Padrão de route file

```js
// crm/routes.js
import { frontendURL } from '../../../helper/URLHelper';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm'),
    name: 'crm_index',
    component: () => import('./CrmIndex.vue'),
    meta: { permissions: ['administrator', 'agent'] },
  },
  {
    path: frontendURL('accounts/:accountId/crm/pipelines/:pipelineId'),
    name: 'crm_pipeline',
    component: () => import('./PipelineBoard.vue'),
    meta: { permissions: ['administrator', 'agent'] },
  },
];
```

### 3.3 Rotas Existentes Relevantes

| Rota | Name | Componente |
|------|------|-----------|
| `/accounts/:id/contacts` | `contacts` | `contacts/Index.vue` |
| `/accounts/:id/companies` | `companies` | `companies/Index.vue` |
| `/accounts/:id/conversations` | `conversations` | `conversation/` |

---

## 4. State Management — Padrão Pinia (Novo)

### 4.1 `storeFactory` — O Padrão Reutilizável

```js
// Padrão companies.js → referência para CRM stores
import { createStore } from 'dashboard/store/storeFactory';

export const usePipelineStore = createStore({
  name: 'crm-pipeline',
  type: 'pinia',
  API: CrmPipelineAPI,
  getters: {
    getPipelineById: state => id => state.records.find(p => p.id === id),
    getPipelineList: state => state.records,
  },
  actions: () => ({
    async loadDeals({ pipelineId, stageId, page = 1 }) {
      this.setUIFlag({ fetchingList: true });
      try {
        const { data } = await CrmPipelineAPI.getDeals({ pipelineId, stageId, page });
        this.records = data.payload;
        this.setMeta(data.meta);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },
    async moveDeal({ dealId, stageId }) {
      await CrmPipelineAPI.updateDeal(dealId, { pipeline_stage_id: stageId });
    },
  }),
});
```

### 4.2 API Client — Padrão

```js
// api/crm-pipeline.js
import ApiClient from './ApiClient';

class CrmPipelineAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  getPipelines() {
    return axios.get(this.url);
  }

  getDeals({ pipelineId, stageId, page = 1, status = 'open' }) {
    return axios.get(
      `${this.url}/${pipelineId}/conversations?stage_id=${stageId}&page=${page}&status=${status}`
    );
  }

  updateDeal(conversationId, data) {
    return axios.patch(
      `/api/v1/accounts/${this.accountId}/conversations/${conversationId}`,
      data
    );
  }
}

export default new CrmPipelineAPI();
```

---

## 5. I18n — Padrão de Tradução

### 5.1 Regras

- **Frontend:** Editar APENAS `app/javascript/dashboard/i18n/en.json`
- **Backend:** Editar APENAS `config/locales/en.yml`
- Nunca strings literais em templates Vue

### 5.2 Strings CRM a Adicionar (`en.json`)

```json
{
  "CRM": {
    "PIPELINE": {
      "TITLE": "Pipeline",
      "BOARD_VIEW": "Board",
      "LIST_VIEW": "List",
      "NEW_DEAL": "New Deal",
      "EMPTY_STATE": "No deals in this stage",
      "MOVE_DEAL": "Move deal",
      "STAGES": {
        "NEW_LEAD": "New Lead",
        "QUALIFIED": "Qualified",
        "PROPOSAL": "Proposal",
        "NEGOTIATION": "Negotiation",
        "CLOSED_WON": "Closed Won",
        "CLOSED_LOST": "Closed Lost"
      }
    }
  }
}
```

---

## 6. UX Audit — Features CRM Existentes

### 6.1 O que já tem UX de CRM

| Feature | Path | UX Quality |
|---------|------|-----------|
| Contact List | `/contacts` | ✅ Bom — search, sort, filter |
| Contact Detail | `/contacts/:id` | ✅ Bom — notas, conversas, custom attrs |
| Companies | `/companies` | 🟡 Básico — lista simples |
| Contact Labels | UI presente | ✅ Funcional |
| Custom Attributes (Contact/Conv) | Settings | ✅ Configurável |
| Conversation Filters | Dashboard | ✅ Robusto |
| Conversation Priority | Dashboard | ✅ Funcional |
| Team Assignment | Dashboard | ✅ Funcional |

### 6.2 Gaps UX para CRM Pipeline

| Gap | Severidade | Solução |
|-----|-----------|---------|
| Sem Kanban/Pipeline board | 🔴 Crítico | PipelineBoard.vue |
| Sem "Deal value" field | 🟡 Importante | Custom attribute ou coluna |
| Sem "Close date" field | 🟡 Importante | Custom attribute |
| Sem pipeline-specific nav | 🔴 Crítico | Sidebar item + rota |
| Sem stage movement UX | 🔴 Crítico | Drag & Drop (vuedraggable) |
| Sem pipeline analytics | 🟠 Desejável | Fase futura |
| Companies sem deals view | 🟡 Importante | Link company → pipeline |

---

## 7. Spec Técnico — CRM Pipeline Board

### 7.1 Estrutura de Arquivos a Criar

```
app/javascript/dashboard/
├── routes/dashboard/crm/
│   ├── routes.js
│   ├── CrmIndex.vue          # Container / redirect
│   └── PipelineBoard.vue     # Kanban view
├── components-next/
│   └── crm/
│       ├── PipelineBoard.vue      # Board container (stages)
│       ├── PipelineColumn.vue     # Uma coluna/stage
│       ├── DealCard.vue           # Card de deal (conversa)
│       ├── DealCardSkeleton.vue   # Loading skeleton
│       ├── PipelineHeader.vue     # Header com pipeline selector
│       ├── CreateDealDialog.vue   # Modal criar deal
│       └── MoveDealDropdown.vue   # Dropdown para mover stage
├── stores/
│   └── crm-pipeline.js       # Pinia store
└── api/
    └── crm-pipeline.js       # API client
```

### 7.2 PipelineColumn.vue — Spec de Comportamento

```
┌─────────────────────────────────┐
│ Stage Name              (3)      │  ← badge com count
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 👤 Contact Name             │ │
│ │ 💬 Last message preview... │ │
│ │ 🏷️  Label  📅 3d ago       │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ...                         │ │
│ └─────────────────────────────┘ │
│                                  │
│ [+ Add Deal]                     │
└─────────────────────────────────┘
```

### 7.3 DealCard.vue — Props Interface

```ts
interface DealCardProps {
  conversation: {
    id: number
    displayId: number
    contact: { id: number; name: string; email: string; avatarUrl: string }
    assignee: { id: number; name: string } | null
    lastActivityAt: string
    priority: 'low' | 'medium' | 'high' | 'urgent' | null
    customAttributes: {
      pipeline_stage_id?: number
      deal_value?: number
      close_date?: string
    }
    cachedLabelList: string
  }
  stageId: number
  isDragging: boolean
}
```

### 7.4 Drag & Drop — Implementação com vuedraggable

```vue
<!-- PipelineColumn.vue -->
<template>
  <draggable
    v-model="localDeals"
    group="deals"
    item-key="id"
    @change="onDealMoved"
    ghost-class="opacity-50"
    drag-class="shadow-2xl rotate-2"
  >
    <template #item="{ element }">
      <DealCard :conversation="element" :stage-id="stageId" />
    </template>
  </draggable>
</template>
```

### 7.5 Padrão de Sidebar Nav para CRM

```vue
<!-- Adicionar em sidebar navigation -->
<SidebarItem
  icon="ph:kanban"
  :label="$t('CRM.PIPELINE.TITLE')"
  :to="{ name: 'crm_index' }"
/>
```

---

## 8. Débitos UX/Frontend Identificados

| ID | Débito | Área | Severidade | Horas |
|----|--------|------|------------|-------|
| FE-01 | Vuex → Pinia migration incompleta | State | 🟡 Médio | Ongoing |
| FE-02 | `components/` misturado com `components-next/` | Estrutura | 🟡 Médio | Ongoing |
| FE-03 | Zero UX de Pipeline/Kanban | Produto | 🔴 Crítico | 20-30h |
| FE-04 | Sem entrada de nav para CRM | Produto | 🔴 Crítico | 2h |
| FE-05 | Companies page sem vínculo a deals | UX | 🟡 Médio | 4h |
| FE-06 | Sem view de "todos os deals" por contato | UX | 🟡 Médio | 4h |
| FE-07 | Sem filtros CRM (por stage, por valor) | UX | 🟡 Médio | 6h |
| FE-08 | Sem analytics de funil de conversão | UX | 🟠 Baixo | 10h+ |

---

## 9. Dependências Frontend Disponíveis para CRM

| Dependência | Uso CRM | Já instalado? |
|-------------|---------|--------------|
| `vuedraggable` | Kanban drag & drop | ✅ SIM |
| `@tanstack/vue-table` | Deal list view | ✅ SIM |
| `chart.js` + `vue-chartjs` | Funil analytics | ✅ SIM |
| `date-fns` | Deal dates, relative time | ✅ SIM |
| `@vueuse/core` | Composables utilitários | ✅ SIM |
| `floating-vue` | Tooltips, popovers | ✅ SIM |

> ✅ **Zero dependências novas necessárias** — todas as ferramentas para construir o Kanban já estão instaladas.

---

## 10. Responsividade e Acessibilidade

### Padrões Chatwoot

- Dashboard é desktop-first (não mobile)
- Kanban board pode ser horizontal scroll no mobile
- Todos os elementos interativos devem ter `aria-label` quando sem texto

### Kanban — Comportamento Responsivo

```
Desktop (≥1280px): Todas as colunas visíveis com scroll horizontal
Tablet (768-1280px): Scroll horizontal, 2-3 colunas visíveis
Mobile (<768px): Stack vertical ou single column view
```

---

*Gerado como parte do **Brownfield Discovery Workflow** (FASE 3). Para consolidação dos débitos, ver FASE 4.*
