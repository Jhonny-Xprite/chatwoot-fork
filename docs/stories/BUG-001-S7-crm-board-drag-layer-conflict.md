# Story BUG-001-S7

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

**Resolve CRM Board Drag Layer Conflicts With Menus and Overlays**

---

## Problem

The CRM board drag state forces the dragged card into `z-index: 9999 !important`. That is high enough to compete with global overlays, popovers, and dropdowns, which makes menu behavior brittle during or around drag interactions.

### Evidence
- [app/javascript/dashboard/components/crm/PipelineColumn.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/crm/PipelineColumn.vue:207)
- [app/javascript/dashboard/components-next/popover/Popover.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/popover/Popover.vue:102)
- [app/javascript/dashboard/assets/scss/_z-index-tokens.scss](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/assets/scss/_z-index-tokens.scss:79)

---

## Acceptance Criteria

1. Dragging a card does not eclipse unrelated menus or overlay layers.
2. Board drag behavior still feels smooth and preserves visual feedback.
3. Drag layering is aligned with the shared overlay hierarchy or documented as an intentional exception.
4. Popovers and dropdowns remain predictable before, during, and after drag interactions.
5. The solution does not rely on a new arbitrary higher `z-index`.

---

## Scope

### In Scope
- `PipelineColumn.vue`
- drag ghost / chosen element stacking
- overlay interaction during board drag

### Out of Scope
- business logic for moving conversations
- visual redesign of cards

---

## Suggested Tasks

- [x] review whether drag really needs a near-global overlay layer
- [x] reduce or normalize the drag stack level
- [x] verify interaction with popovers, card selectors, and filter overlays
- [x] document any justified exception if a higher layer must remain

---

## QA Notes

- Start dragging a card with popovers or selectors recently opened.
- Verify the drag layer does not permanently break later overlays.
- Re-test card menus after a drag operation completes.

---

EOF
