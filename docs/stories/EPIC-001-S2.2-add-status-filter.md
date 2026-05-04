# Story 2.2: Add Filtro por Status no Kanban

**ID:** EPIC-001-S2.2  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 2 - Funcionalidade  
**Status:** 📝 Ready for Dev  
**Priority:** 🔴 Critical  

---

## User Story

```gherkin
Como agente,
Quero filtrar leads na pipeline por status específico (estágio),
Para que eu veja apenas o que me interessa no momento.
```

---

## Descrição

Adicionar dropdown de filtro por status/stage no Kanban FilterBar. Usuário pode filtrar para ver apenas cards de um estágio específico ou "Todos os estágios". Integra com Story 1.3 (filtro "Não lidos").

---

## Acceptance Criteria

- [ ] Dropdown "Filtrar por Status" ou "Estágio" aparece no FilterBar
- [ ] Lista todos os stages da pipeline ativa
- [ ] "Todos os estágios" é a opção padrão (sem filtro)
- [ ] Seleção filtra cards em tempo real (sem reload)
- [ ] Filtro persiste na URL (queryParam `?status=stage-id`)
- [ ] Pode combinar com outros filtros (assignee, labels, lead score, não lidos)
- [ ] Mostra contagem de cards por status (ex: "Novo (15)")
- [ ] Z-INDEX funciona corretamente (Story 2.1 foi feito)
- [ ] Mobile: dropdown colapsível para economizar espaço
- [ ] Tooltip: "Filtrar por estágio atual" / "Mostrar todos"

---

## Estimativa & Complexidade

**Complexity:** 🟡 Média  
**Story Points:** 5  
**Estimate:** 2-3 dias  
**Dependências:** Story 2.1 (Z-INDEX fix) - para dropdown ser acessível

---

## Arquivos Afetados

```
app/javascript/dashboard/components/crm/FilterBar.vue
app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue
app/javascript/dashboard/store/crm/pipeline.js
app/javascript/dashboard/store/mutation-types.js
```

---

## Store Changes

**In `pipeline.js`:**
```javascript
// Add to filters object:
filters: {
  // ... existing filters
  stageFilter: null,  // null = all stages
}

// Add mutation:
SET_STAGE_FILTER(_state, stageId) {
  _state.filters.stageFilter = stageId;
}

// Update getter:
appliedFilters: _state => _state.filters
```

---

## API Changes

**In `ContactsAPI` or stage filtering:**
- Include `?stage_id=X` in request when `stageFilter` is set
- Backend should filter conversations by `pipeline_stage_id`

---

## Notas Técnicas

- Watch filter change → trigger `refreshAllStages()` and reload contacts
- Loader icon while loading filtered results
- Show "(15)" badge next to each stage option showing count
- Integrate with existing filters (assignee, labels, etc.)
- Mobile: collapse long filter bar or use "Show filters" button

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] Store mutation/action validation
- [ ] URL queryParam handling (encodeURIComponent)
- [ ] Filter combination logic (no conflicts)
- [ ] Loading state management
- [ ] Mobile breakpoint responsive

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**What to change:**
1. Update `pipeline.js` store:
   - Add `stageFilter: null` to filters object
   - Add `SET_STAGE_FILTER` mutation
2. Update `FilterBar.vue`:
   - Add new `<select>` or `<FilterSelect>` component for status/stage
   - v-model bind to store filter
   - List all stages from `getStages` getter
   - Show count: `Stage Name (15)`
3. Add watch in `Pipelines.vue`:
   - When `stageFilter` changes → call `refreshAllStages()`
4. Update URL: add `?stage_id=X` to query params when filter applied
5. Integrate "Não lidos" filter option (from Story 1.3)

**Testing:**
- Open pipeline with multiple stages
- Select filter → cards update instantly
- URL changes to include `?stage_id=X`
- Reload page → filter persists
- Combine filters (assignee + stage) → works together
- Mobile: filter bar responsive

**PR Title:** `feat(kanban): add stage/status filter to pipeline`

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Blocks:** None  
**Blocked By:** Story 2.1 (Z-INDEX fix)  
**Story Template Version:** 1.0
