# Story BUG-001-S5

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

**Harden Dashboard Quick Conversation Menu Submenus**

---

## Problem

The compact conversation menu in the dashboard header opens nested `SelectMenu` submenus for status and sort order. Those submenus are positioned with static left/right classes and do not use viewport-aware placement, so they can clip or render off-screen near the right edge or in tighter layouts.

### Evidence
- [app/javascript/dashboard/components/widgets/conversation/ConversationBasicFilter.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/widgets/conversation/ConversationBasicFilter.vue:138)
- [app/javascript/dashboard/components-next/selectmenu/SelectMenu.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/selectmenu/SelectMenu.vue:60)

---

## Acceptance Criteria

1. Status and sort submenus stay fully visible near the viewport edge.
2. Submenus remain usable in both condensed and expanded conversation layouts.
3. `Escape` closes the open submenu predictably.
4. Focus returns to the trigger that opened the submenu.
5. The quick menu still works without regressions for mouse users.

---

## Scope

### In Scope
- `ConversationBasicFilter.vue`
- `SelectMenu.vue`
- submenu placement and keyboard close behavior

### Out of Scope
- advanced conversation filter modal
- CRM filter bar

---

## Suggested Tasks

- [x] replace static submenu positioning with viewport-safe logic
- [x] add keyboard close and focus restoration for nested menu usage
- [x] verify submenu behavior in both `left` and `right` placement modes
- [x] validate the compact conversation header on narrower desktop widths

---

## QA Notes

- Open the dashboard quick filter menu near the right edge.
- Open both status and sort submenus.
- Verify submenu visibility, `Escape`, and focus return.

---

EOF
