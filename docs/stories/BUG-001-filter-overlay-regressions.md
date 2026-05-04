# Bug BUG-001

## Status
- [x] Draft
- [x] Ready for Development
- [x] In Progress
- [x] In Review
- [x] QA Review
- [x] Done

**Current Phase:** DONE  
**Area:** Dashboard + CRM Filters + Shared Overlay System  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Title

**Filter Overlay Regressions and Z-Index Debt**

---

## Summary

There are multiple related UI defects affecting filters and floating overlays across the dashboard:

1. The conversation filter in the dashboard view has brittle focus and close behavior tied to duplicated DOM ids.
2. The CRM pipeline filter uses a different implementation and still lacks safe dropdown positioning near viewport edges and during horizontal scroll.
3. Shared dropdown primitives do not consistently support `Escape` close and focus restoration.
4. The dashboard contains multiple ad hoc high `z-index` values (`z-[1000]`, `z-[9999]`, `z-[10001]`, `z-[99999]`), which increases overlay conflicts and makes filter fixes unreliable.
5. The dashboard quick conversation menu uses nested side menus without viewport-safe positioning.
6. CRM deal-card inline selectors reuse the same menu foundation and can inherit clipping and stacking problems inside horizontally scrollable columns.
7. CRM drag layers use very high stacking priority and can conflict with popovers and dropdowns during board interactions.

This should be handled as a bug stream, not as a single CSS tweak.

---

## Business Impact

- Filter interactions can feel broken or inconsistent.
- Users can lose focus context when opening or closing filters.
- Dropdowns may be clipped or hidden in CRM pipeline views.
- Future overlay fixes become slower and riskier because the stacking model is not predictable.

---

## Evidence

### Dashboard Conversation Filter
- [app/javascript/dashboard/components/ChatListHeader.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/ChatListHeader.vue:132) repeats `id="toggleConversationFilterButton"` three times.
- [app/javascript/dashboard/components-next/filter/ConversationFilter.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/ConversationFilter.vue:101) uses `#toggleConversationFilterButton` in the click-outside ignore list.

### CRM Pipeline Filter
- [app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue:596) renders [FilterBar.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/crm/FilterBar.vue:116).
- [app/javascript/dashboard/components-next/filter/inputs/FilterSelect.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/inputs/FilterSelect.vue:57) only flips vertically and does not handle right-edge clipping.

### Shared Dropdown Stack
- [app/javascript/dashboard/components-next/dropdown-menu/base/DropdownContainer.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/dropdown-menu/base/DropdownContainer.vue:24) only closes on click-outside.
- [app/javascript/dashboard/composables/useDropdownPosition.js](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/composables/useDropdownPosition.js:19) already contains a more robust positioning model that is not consistently adopted.

### Z-Index Debt
- [app/javascript/dashboard/components-next/filter/ConversationFilter.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/ConversationFilter.vue:108) uses `z-[1000]`.
- [app/javascript/dashboard/assets/scss/plugins/_date-picker.scss](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/assets/scss/plugins/_date-picker.scss:88) uses `z-[99999]`.
- [app/javascript/dashboard/components-next/year-in-review/ShareModal.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/year-in-review/ShareModal.vue:179) uses `z-[10001]`.
- [app/javascript/dashboard/assets/scss/_z-index-tokens.scss](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/assets/scss/_z-index-tokens.scss:79) reserves `999` for debug usage.

---

## Execution Plan

This bug should be implemented through the following stories:

- [x] BUG-001-S1: dashboard conversation filter focus layering
- [x] BUG-001-S2: shared dropdown accessibility positioning
- [x] BUG-001-S3: crm pipeline filter overlay fix
- [x] BUG-001-S4: z-index normalization audit
- [x] BUG-001-S5: dashboard quick menu submenu hardening
- [x] BUG-001-S6: crm-inline-selector-menu-hardening.md
- [x] BUG-001-S7: crm-board-drag-layer-conflict.md

---

## Recommendation

Do not close this bug with a single `z-index` bump. The correct path is:

1. fix the dashboard conversation filter behavior
2. stabilize the shared dropdown foundation
3. apply the corrected behavior to CRM pipeline filters
4. normalize the overlay hierarchy

---

## QA Results

### Review Date: 2026-05-04
### Reviewed By: Quinn (Test Architect)

### Code Quality Assessment

A implementação atingiu a maturidade necessária para estabilizar o sistema de overlays do dashboard. A migração de IDs frágeis para classes utilitárias (`js-filter-modal-trigger`) e a padronização do `useDropdownPosition` eliminam a dívida técnica acumulada. A acessibilidade foi significativamente aprimorada com suporte a `Escape` e restauração de foco em todos os dropdowns baseados em `DropdownContainer` e `Popover`.

### Refactoring Performed

Foram realizados refactorings adicionais durante a fase de QA para garantir que os critérios de aceitação de todas as sub-estórias (S1-S7) fossem plenamente atendidos:

- **File**: `app/javascript/dashboard/components-next/selectmenu/SelectMenu.vue`
  - **Change**: Refatorado para usar `useDropdownPosition` e `TeleportWithDirection`.
  - **Why**: Evitar clipping em colunas com scroll horizontal (CRM) e remover z-index hardcoded.
- **File**: `app/javascript/dashboard/components/crm/PipelineColumn.vue`
  - **Change**: Normalizado o z-index da classe `.sortable-drag` para `60`.
  - **Why**: Alinhar com a nova hierarquia de camadas e evitar conflitos com overlays globais.
- **File**: `app/javascript/dashboard/components-next/popover/Popover.vue`
  - **Change**: Normalizado o z-index do backdrop mobile para `5000`.
  - **Why**: Padronização com o tier de Modais/Filtros.

### Compliance Check

- Coding Standards: [✓]
- Project Structure: [✓]
- Testing Strategy: [✓] Manual verification of viewport boundaries and horizontal scroll.
- All ACs Met: [✓] Sub-stories S1 through S7 validated.

### Improvements Checklist

- [x] Refatorado `SelectMenu` para segurança de viewport (S6/S5)
- [x] Normalizado z-index de arrasto no CRM (S7)
- [x] Corrigido z-index de popover mobile (S4)
- [x] Implementado fechamento via Escape e foco automático (S2)

### Gate Status

Gate: **PASS** → `docs/qa/gates/BUG-001-filter-overlay-regressions.yml`

### Recommended Status

[✓ Ready for Done]

— Quinn, guardião da qualidade 🛡️
