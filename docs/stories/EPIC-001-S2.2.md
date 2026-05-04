# Story EPIC-001-S2.2

## Status
- [ ] Draft
- [x] Ready for Development
- [x] In Progress
- [ ] In Review
- [ ] QA Review
- [ ] Done

**Current Phase:** SPECIFICATION COMPLETE  
**Wave:** Wave 2 - Kanban Functionality  
**Epic:** EPIC-001-KANBAN  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Story

**Title:** Add Filtro por Status no Kanban

**Description:**  
Add status/stage filtering to KanbanFilterBar. Users can filter contacts by stage, select "All Stages" (default), and filter updates in real-time without page reload. Filter state persists in URL (?status=stage-id).

**Context:**  
- Current State: No status filtering in Kanban view
- Desired State: Status dropdown with real-time filtering, URL persistence
- Business Impact: Better contact management, easier pipeline visualization
- Technical Impact: Frontend filtering, Vuex state, URL params

**⚠️ DEPENDENCY:** This story depends on S2.1 (Z-INDEX fix). Cannot start until S2.1 is complete.

---

## Acceptance Criteria

### Functional Requirements
1. **Status filter dropdown visible**
   - Dropdown shows all stages/statuses
   - Option "Todos os estágios" is default
   - Dropdown accessible (keyboard + mouse)

2. **Real-time filtering works**
   - Select status → contacts filtered immediately (< 500ms)
   - No page reload required
   - Unselected status contacts hidden

3. **Filter combines with other filters**
   - Status filter + search filter work together
   - All filters applied simultaneously
   - Count shows filtered results

4. **Filter state persists in URL**
   - Select status → URL becomes `?status=stage-id`
   - Reload page → filter still applied
   - URL can be bookmarked/shared

5. **Contact count per status displayed**
   - Show "5 contacts" next to stage name
   - Count updates when filtering
   - Shows total, not filtered count

---

## Task Breakdown

### Phase 1: Store Setup (if needed)
- [x] **T2.2.1: Extend Vuex for filter state**
  - Status filter stored in existing `crmPipeline/appliedFilters`
  - No new module needed - reused existing pattern (scoreBand)
  - Existing mutations: `setFilter`, action: dispatched via setFilter

- [x] **T2.2.2: Initialize from URL params**
  - Status filter initialized from `appliedFilters.status`
  - Already supported by existing extractFiltersFromView logic
  - Can be bookmarked/shared via URL query param

### Phase 2: Component Updates
- [x] **T2.2.3: Add status dropdown to KanbanFilterBar**
  - Added to `app/javascript/dashboard/components/crm/FilterBar.vue`
  - Uses existing FilterSelect component
  - Lists all stages via `crmPipeline/getStages` getter
  - "CRM.ALL_STAGES" default option
  - Triggers `crmPipeline/setFilter` action on selection

- [x] **T2.2.4: Update Kanban view filtering**
  - Updated `filteredBoardContacts` in Pipelines.vue
  - Filters contacts by `stage_id` when status filter set
  - Combines with scoreBand filter
  - Also updated `buildContactFilterPayload` for API filtering

- [x] **T2.2.5: Display stage contact counts**
  - Contact counts displayed via stage objects from `crmPipeline/getStages`
  - Counts are total counts per stage (not filtered)
  - Display handled by FilterSelect component dropdown
  - Counts update reactively when data changes

### Phase 3: URL State Management
- [ ] **T2.2.6: Update URL when filter changes**
  - Select status → update URL query param `?status=stage-id`
  - Use router: `this.$router.push({ query: { status: stageId } })`
  - No page reload, just URL update

- [ ] **T2.2.7: Restore filter from URL on load**
  - On app mount, read URL query param
  - Set Vuex state from URL
  - Example: URL `/kanban?status=sales` → load with sales filter applied

### Phase 4: Testing
- [ ] **T2.2.8: Unit tests - Vuex filter state**
  - Test mutation: `setStatusFilter` updates state
  - Test action: `selectStatus` updates state
  - Run: `npm test store/kanban-filters.spec.js`

- [ ] **T2.2.9: Integration tests - URL params**
  - Navigate to `/kanban?status=sales` → filter applied
  - Change filter → URL updates
  - Reload page → filter persists
  - Run: `npm test integration/kanban-filtering.spec.js`

- [ ] **T2.2.10: Component tests**
  - Test dropdown: select status → contacts filtered
  - Test counts: counts update after filtering
  - Test "All Stages": clears filter, shows all contacts
  - Run: `npm test components/KanbanFilterBar.spec.js`

- [ ] **T2.2.11: Manual E2E testing**
  - Open Kanban view
  - Select status "Sales"
  - Verify: only Sales contacts visible, count correct
  - Select "Negotiation"
  - Verify: only Negotiation visible
  - Select "Todos os estágios"
  - Verify: all contacts visible
  - Reload page
  - Verify: filter persists (URL shows `?status=...`)

- [ ] **T2.2.12: Combined filter testing**
  - Select status "Sales" + search "John"
  - Verify: only Sales contacts matching "John" shown
  - Both filters applied
  - Clear search
  - Verify: all Sales contacts shown
  - Clear status filter
  - Verify: all contacts shown

### Phase 5: Performance Testing
- [ ] **T2.2.13: Load test with 100+ contacts**
  - Load Kanban with 100 contacts
  - Select status filter
  - Verify: filters instantly (< 500ms)
  - Measure performance with DevTools
  - If slower, implement virtual scrolling

### Phase 6: Regression Testing
- [ ] **T2.2.14: Full regression test**
  - Run: `npm test && npm run lint && npm run typecheck`
  - Ensure no new failures
  - Kanban view loads
  - Other filters still work (search, etc.)
  - Drag & drop still works

---

## Testing Strategy

### Automated Testing
| Test Type | Tool | Command | Success Criteria |
|-----------|------|---------|------------------|
| Vuex Store | Jest | `npm test store/kanban-filters.spec.js` | All pass |
| Integration | Jest | `npm test integration/kanban-filtering.spec.js` | All pass |
| Components | Jest | `npm test components/KanbanFilterBar.spec.js` | All pass |
| Full Test | Jest | `npm test` | All pass |

### Manual Testing
| Test Case | Steps | Expected Result | Evidence |
|-----------|-------|-----------------|----------|
| **Select Status** | Click dropdown, select "Sales" | Only Sales contacts visible | Screenshot |
| **Count Display** | Look at dropdown | Stage shows "(5 contacts)" or similar | Screenshot |
| **Real-time Update** | Select status, watch contacts | Immediate filter (< 500ms) | Video or timestamp |
| **URL Persistence** | Select status, reload page | Filter persists, URL shows `?status=sales` | Screenshot |
| **Combined Filters** | Select status "Sales" + search "John" | Only Sales + matching John shown | Screenshot |
| **All Stages** | Select "Todos os estágios" | All contacts shown again | Screenshot |
| **Bookmark Share** | Copy URL `?status=sales`, open in new tab | Filter applied in new tab | Screenshot |

---

## Development Notes

### Architectural Decisions
1. **Frontend Filtering (not backend)**
   - Filter on frontend: simpler, no API changes
   - Good for < 1000 contacts
   - If > 1000, implement backend pagination in future story

2. **URL Query Params**
   - Use `?status=stage-id` for filter state
   - Enables bookmarking and sharing
   - No server changes needed

3. **Vuex Store for Shared State**
   - Centralize filter state
   - Enable multi-component access
   - Persist to URL on change

### Implementation Approach
1. Extend Vuex store with `statusFilter` state
2. Add status dropdown to KanbanFilterBar
3. Update Kanban view to apply filter
4. Update URL when filter changes
5. Restore filter from URL on load
6. Test manually with 50+ contacts

### Files Affected
- `src/store/modules/kanban-filters.js` (MODIFY or CREATE)
- `src/components/KanbanFilterBar.vue` (MODIFY)
- `src/views/KanbanView.vue` (MODIFY)
- `tests/unit/store/kanban-filters.spec.js` (MODIFY or CREATE)
- `tests/unit/components/KanbanFilterBar.spec.js` (MODIFY)

### No Database Changes
This is pure frontend filtering.

---

## Risk Mitigation

### Risk: Filter Performance Issues with Large Lists
- **Likelihood:** MEDIUM (if 1000+ contacts)
- **Impact:** Filter slow (> 500ms), poor UX
- **Mitigation:** Frontend filtering good for < 1000; use virtual scrolling if needed
- **Testing:** Load test with 100, 500, 1000 contacts (T2.2.13)

### Risk: URL Param Not Restored on Page Load
- **Likelihood:** LOW
- **Impact:** Bookmark doesn't restore filter
- **Mitigation:** Test URL restore on mount
- **Testing:** Manual test (T2.2.11)

### Risk: Filter Breaks Other Filters (Search, etc.)
- **Likelihood:** MEDIUM
- **Impact:** Status filter + search don't work together
- **Mitigation:** Ensure all filters combined in filtering logic
- **Testing:** Combined filter test (T2.2.12)

---

## Story Points & Effort

| Estimate | Days | Notes |
|----------|------|-------|
| **Story Points** | 5 | Medium complexity: store, components, URL |
| **Developer Days** | 2-3 | Frontend filtering, store setup |
| **QA Days** | 1 | Testing + URL verification |
| **Total Calendar Days** | 2-3 | Blocked by S2.1 |

---

## File List

### Files Modified

- `app/javascript/dashboard/components/crm/FilterBar.vue` (MODIFIED: added status filter dropdown)
- `app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue` (MODIFIED: added stage filtering logic)

### Files Not Yet Modified (Phase 3-6)

- URL state management (T2.2.6, T2.2.7)
- Test files (T2.2.8-T2.2.14)

---

## Development Agent Record

**Assigned to:** @dev (Dex)  
**Status:** Phase 1 & 2 Implementation Complete - Ready for Testing

### Implementation Summary

- ✅ Phase 1: Store setup - used existing `crmPipeline/appliedFilters.status`
- ✅ Phase 2: Component updates:
  - Added status dropdown to `FilterBar.vue` with stages from `crmPipeline/getStages`
  - Updated `filteredBoardContacts` in `Pipelines.vue` to filter by `stage_id`
  - Updated `buildContactFilterPayload` to include stage_id in API filters
- 🔄 Phase 3-6: Testing & URL state management (pending)
- Commit: 418eaca81

### Next Steps

- Phase 3: URL state management (T2.2.6, T2.2.7)
- Phase 4-6: Testing (unit, integration, E2E, regression)

---

## QA Results

**QA Gate:** PENDING  
**QA Assigned to:** @qa (Quinn)  

### QA Checklist
- [ ] Status dropdown shows all stages
- [ ] "Todos os estágios" is default
- [ ] Select status → contacts filter immediately (< 500ms)
- [ ] URL updates when filter changes (`?status=stage-id`)
- [ ] Reload page → filter persists
- [ ] Status filter + search filter work together
- [ ] Contact counts per stage display correctly
- [ ] "Todos os estágios" shows all contacts again
- [ ] Load test with 100+ contacts (< 500ms response)
- [ ] No regressions in other filters

**QA Verdict:** PENDING (awaiting @dev implementation)

---

## Change Log

| Date       | Author | Change                                                                    | Status      |
|------------|--------|---------------------------------------------------------------------------|-------------|
| 2026-05-04 | Dex    | Phase 1-2: Implemented status filter in FilterBar & Pipelines (418eaca81) | IN_PROGRESS |
| 2026-05-04 | Aria   | Story created from EPIC-001-IMPLEMENTATION-PLAN                           | CREATED     |

---

## Related Stories

- **Depends on:** [S2.1 - Z-INDEX Fix](./EPIC-001-S2.1.md) ⛔ **BLOCKER**
- **Enables:** [S3.1 - Drag & Drop](./EPIC-001-S3.1.md)
- **Wave 2:** [S2.1 - Z-INDEX Fix](./EPIC-001-S2.1.md)
- **Epic:** [EPIC-001-KANBAN](./EPIC-001-KANBAN.md)

---

## Dependencies

- **Blocked by:** S2.1 (Z-INDEX fix) — cannot start until S2.1 is QA approved
- **Blocks:** S3.1 (S3.1 can only start after Wave 2 complete)

---

## Critical Path Impact

**S2.1 → S2.2 → S3.1**

This story is on critical path. S2.1 delay = S2.2 delay = S3.1 delay.

---

EOF
