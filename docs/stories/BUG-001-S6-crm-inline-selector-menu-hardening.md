# Story BUG-001-S6

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

**Harden CRM Inline Selector Menus Inside Deal Cards**

---

## Problem

CRM deal cards use inline selector menus inside a horizontally scrollable board. Those selectors reuse the same `SelectMenu` foundation as the dashboard quick menu, so they can inherit clipping, off-screen rendering, and keyboard-close gaps when opened near the edge of a column or viewport.

### Evidence
- [app/javascript/dashboard/components/crm/DealCard.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/crm/DealCard.vue:374)
- [app/javascript/dashboard/components-next/selectmenu/SelectMenu.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/selectmenu/SelectMenu.vue:60)
- [app/javascript/dashboard/components/crm/PipelineBoard.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/crm/PipelineBoard.vue:70)

---

## Acceptance Criteria

1. The assignee selector in deal cards stays fully visible inside the board.
2. Opening the selector near the far-right side of the board does not clip the menu.
3. Keyboard users can close the selector with `Escape`.
4. The selector remains usable while the board is horizontally scrolled.
5. The fix reuses the shared solution, not a CRM-only workaround.

---

## Scope

### In Scope
- `DealCard.vue`
- shared `SelectMenu.vue` behavior as used in CRM cards
- inline selector QA in pipeline columns

### Out of Scope
- priority popover redesign
- drag-and-drop behavior itself

---

## Suggested Tasks

- [x] validate the selector placement inside real pipeline columns
- [x] adopt the shared hardened submenu behavior
- [x] confirm no overlap regression with card hover actions
- [x] test on populated boards with horizontal scroll

---

## QA Notes

- Open the assignee selector on cards in left, middle, and right columns.
- Test with the board scrolled horizontally.
- Verify keyboard close and focus behavior.

---

EOF
