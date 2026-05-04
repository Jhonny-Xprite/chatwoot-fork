# Story BUG-001-S2

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

**Stabilize Shared Dropdown Accessibility and Positioning**

---

## Problem

The shared dropdown foundation is missing behavior that multiple filters now need:

- `Escape` close
- focus restoration
- safe placement near viewport edges
- reuse of the existing shared positioning composable

### Evidence
- [app/javascript/dashboard/components-next/dropdown-menu/base/DropdownContainer.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/dropdown-menu/base/DropdownContainer.vue:24)
- [app/javascript/dashboard/components-next/filter/inputs/FilterSelect.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/inputs/FilterSelect.vue:57)
- [app/javascript/dashboard/composables/useDropdownPosition.js](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/composables/useDropdownPosition.js:19)

---

## Acceptance Criteria

1. Shared dropdowns close on `Escape`.
2. Focus returns to the trigger when a dropdown closes through keyboard or outside click.
3. Shared filter selects can reposition safely near bottom and right viewport edges.
4. Horizontal clipping is prevented for standard filter dropdowns.
5. New behavior is implemented in the shared layer, not duplicated per screen.

---

## Scope

### In Scope
- `DropdownContainer.vue`
- `FilterSelect.vue`
- `useDropdownPosition.js`
- shared dropdown keyboard and positioning contract

### Out of Scope
- screen-specific CRM styling polish
- broad modal refactors unrelated to dropdowns

---

## Suggested Tasks

- [x] add `Escape` close handling in the shared dropdown container
- [x] preserve and restore trigger focus on close
- [x] migrate `FilterSelect` to use shared positioning logic
- [x] validate vertical and horizontal placement in LTR and RTL contexts

---

## QA Notes

- Verify `Escape` closes without trapping focus.
- Verify right-edge placement on narrow screens.
- Verify dropdowns stay usable when the page is scrolled.

---

EOF
