# Story BUG-001-S3

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

**Fix CRM Pipeline Filter Dropdown Visibility and Clipping**

---

## Problem

The CRM pipeline view uses a different filter implementation from the dashboard conversation filter. It needs its own overlay fix after the shared dropdown foundation is corrected.

### Evidence
- [app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue:596)
- [app/javascript/dashboard/components/crm/FilterBar.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/crm/FilterBar.vue:116)
- [app/javascript/dashboard/components-next/filter/inputs/FilterSelect.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components-next/filter/inputs/FilterSelect.vue:88)
- [app/javascript/dashboard/components/crm/PipelineBoard.vue](D:/MINI-PROJETOS-AIOX/chatwoot-fork/app/javascript/dashboard/components/crm/PipelineBoard.vue:70)

---

## Acceptance Criteria

1. CRM filter dropdowns remain visible above pipeline cards.
2. Dropdowns are not clipped at the right edge of the viewport.
3. Dropdowns remain usable while the board is horizontally scrolled.
4. Assignee, labels, score, and status filters behave consistently.
5. The fix uses the shared dropdown behavior from `BUG-001-S2`.

---

## Scope

### In Scope
- `Pipelines.vue`
- `FilterBar.vue`
- CRM filter dropdown QA
- horizontal scroll verification

### Out of Scope
- conversation dashboard filter
- unrelated CRM card popovers

---

## Suggested Tasks

- [x] validate the stacking context around `FilterBar` and `PipelineBoard`
- [x] remove any CRM-only workaround that duplicates shared behavior
- [x] test all filter dropdowns on a board with many columns
- [x] confirm no regressions after `BUG-001-S2`

---

## QA Notes

- Test with enough columns to force horizontal scroll.
- Test near the far-right viewport edge.
- Test on both empty and populated filters.

---

EOF
