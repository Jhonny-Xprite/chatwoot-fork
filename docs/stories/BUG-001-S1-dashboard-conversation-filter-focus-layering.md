# Story BUG-001-S1

## Status
- [x] Draft
- [ ] Ready for Development
- [ ] In Progress
- [ ] In Review
- [ ] QA Review
- [x] Done

**Current Phase:** DONE  
**Bug:** BUG-001  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Title

**Fix Dashboard Conversation Filter Focus and Close Behavior**

---

## Problem

The conversation filter opened from the dashboard toolbar has unstable close and focus behavior because the click-outside ignore logic is bound to a duplicated DOM id.

### Evidence
- [app/javascript/dashboard/components/ChatListHeader.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/ChatListHeader.vue:132)
- [app/javascript/dashboard/components/ChatListHeader.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/ChatListHeader.vue:147)
- [app/javascript/dashboard/components/ChatListHeader.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/ChatListHeader.vue:158)
- [app/javascript/dashboard/components-next/filter/ConversationFilter.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/ConversationFilter.vue:101)

---

## Acceptance Criteria

1. The conversation filter trigger has a unique and stable selector.
2. Opening the filter from the list-filter button does not interfere with other buttons in the same header.
3. Clicking outside closes the filter reliably.
4. Closing the filter returns focus to the correct trigger button.
5. The implementation does not rely on duplicated ids.

---

## Scope

### In Scope
- `ChatListHeader.vue`
- `ConversationFilter.vue`
- trigger reference / selector cleanup
- focus restoration behavior

### Out of Scope
- CRM pipeline filter positioning
- global z-index audit

---

## Suggested Tasks

- [x] replace duplicated trigger ids with a single dedicated selector or ref for the filter button
- [x] update click-outside ignore logic to target the correct element only
- [x] restore focus to the same trigger after close
- [x] verify behavior for default view and folder view variants

---

## QA Notes

- Open and close the dashboard conversation filter repeatedly.
- Verify the edit and delete custom-view buttons do not affect filter behavior.
- Confirm keyboard users can reopen the filter without losing context.

## QA Results

### Review Date: 2026-05-04
### Reviewed By: Quinn (Test Architect)

### Code Quality Assessment

A implementação resolve a fragilidade do seletor de fechamento do filtro de conversas. A substituição de IDs duplicados por uma classe utilitária dedicada (`.js-filter-modal-trigger`) garante que o comportamento de "click-outside" seja consistente em todos os estados do header (visualização padrão vs. pastas). A restauração de foco foi implementada de forma robusta no `ConversationFilter.vue`, capturando o elemento ativo na montagem.

### Compliance Check

- Coding Standards: [✓]
- Project Structure: [✓]
- Testing Strategy: [✓]
- All ACs Met: [✓]

### Improvements Checklist

- [x] Deduplicação de IDs no Header
- [x] Implementação de classe estável para ignore do click-outside
- [x] Restauração de foco para acessibilidade (A11y)

### Gate Status

Gate: **PASS** → `docs/qa/gates/BUG-001-S1-dashboard-conversation-filter.yml`

### Recommended Status

[✓ Ready for Done]

— Quinn, guardião da qualidade 🛡️
