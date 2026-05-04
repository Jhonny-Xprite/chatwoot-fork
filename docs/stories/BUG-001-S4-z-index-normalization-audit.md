# Story BUG-001-S4

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

**Normalize Dashboard Z-Index Hierarchy for Overlays**

---

## Problem

The dashboard has accumulated several arbitrary high `z-index` values. This makes overlay behavior fragile and encourages local hotfixes instead of a reliable layering contract.

### Known Hotspots
- [app/javascript/dashboard/components-next/filter/ConversationFilter.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/ConversationFilter.vue:108)
- [app/javascript/dashboard/assets/scss/plugins/_date-picker.scss](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/assets/scss/plugins/_date-picker.scss:88)
- [app/javascript/dashboard/components-next/year-in-review/ShareModal.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/year-in-review/ShareModal.vue:179)
- [app/javascript/dashboard/components/ui/ContextMenu.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/ui/ContextMenu.vue:89)
- [app/javascript/dashboard/assets/scss/_z-index-tokens.scss](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/assets/scss/_z-index-tokens.scss:34)

---

## Acceptance Criteria

1. Overlay layers are mapped back to the documented token hierarchy wherever feasible.
2. Arbitrary high values are reduced or justified explicitly.
3. Filter-related overlays no longer require one-off `z-[1000]+` workarounds.
4. The final hierarchy documents which components intentionally stay above modal or dropdown layers.
5. No regressions are introduced in modals, date pickers, context menus, or share flows.

---

## Scope

### In Scope
- overlay layering audit
- token alignment for filter and dropdown-related components
- documented exceptions that must remain above normal overlay layers

### Out of Scope
- visual redesign of overlay components
- unrelated layout bugs

---

## Suggested Tasks

- [x] inventory components using `z-[1000]` and above
- [x] classify each usage as token-aligned, justified exception, or debt
- [x] reduce filter-related hotfixes to token-based layers
- [x] document any remaining exceptions in code comments or follow-up backlog

---

## QA Notes

- Test modal over dropdown.
- Test date picker over form controls.
- Test context menus, popovers, and filter overlays together on the same screens.

---

EOF
