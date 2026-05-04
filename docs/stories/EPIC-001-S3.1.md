# Story EPIC-001-S3.1

## Status
- [ ] Draft
- [x] Ready for Development
- [ ] In Progress
- [ ] In Review
- [ ] QA Review
- [ ] Done

**Current Phase:** SPECIFICATION COMPLETE  
**Wave:** Wave 3 - Advanced Interaction  
**Epic:** EPIC-001-KANBAN  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Story

**Title:** Implementar Drag & Drop tipo Trello/ClickUp

**Description:**  
Implement Trello-like drag & drop where users drag contact cards between stages. Features include smooth animations (200-300ms), 60 FPS performance with 100+ cards, mobile touch support, and backend persistence via PATCH API.

**Context:**  
- Current State: No drag & drop, manual card repositioning not possible
- Desired State: Cards drag between stages, persist backend, smooth 60 FPS animation
- Business Impact: Intuitive pipeline management, improved UX
- Technical Impact: Drag API, virtual scrolling, performance optimization

**⚠️ PERFORMANCE CRITICAL:** Must maintain 60 FPS with 100+ cards. Virtual scrolling required.

---

## Acceptance Criteria

### Functional Requirements
1. **Card follows cursor during drag**
   - 200ms delay before drag starts (not too sensitive)
   - Card follows mouse smoothly
   - Visual feedback: shadow/elevation during drag
   - Drag animation fluid (no jank)

2. **Destination stage highlights**
   - On drag over stage, stage highlights (border or bg change)
   - On drag away, highlight removed
   - User sees where card will land

3. **Drop position indicator**
   - Visual line shows where card will be inserted
   - Position updates as card moves
   - Clear visual feedback

4. **Card persists in new stage**
   - Drop card → API call to backend
   - Backend updates stage, returns 200 OK
   - Card stays in new stage after drop

5. **Drag handles 100+ cards at 60 FPS**
   - Load 100 cards, start dragging
   - Measure FPS with DevTools
   - Maintain 60 FPS throughout drag
   - No jank, smooth animation

6. **Touch events supported (mobile/tablet)**
   - Works on iOS Safari (tested on device)
   - Works on Android Chrome (tested on device)
   - Touch drag behaves like mouse drag
   - No interference with page scroll

7. **Edge cases handled**
   - Drag to same column: no-op, card returns to original
   - Drag outside valid zone: card returns to original
   - Drag during loading: prevented, loading state shown
   - Network error during drop: reverts to original, shows error

---

## Task Breakdown

### Phase 1: Drag Library Setup
- [ ] **T3.1.1: Check for vuedraggable library**
  - Check `package.json` for vuedraggable
  - If present, use it (battle-tested)
  - If not, evaluate: `vue-draggable-plus` or native Drag API

- [ ] **T3.1.2: Setup virtual scrolling (if 100+ cards)**
  - Evaluate: `vue-virtual-scroller` or `react-window` equivalent
  - If using vuedraggable, ensure compatibility
  - Test with 100+ card list

### Phase 2: Component Structure
- [ ] **T3.1.3: Create KanbanBoard wrapper**
  - Stages are containers (columns)
  - Each stage contains draggable cards
  - State: which card is dragging, over which stage

- [ ] **T3.1.4: Implement drag state management**
  - Track: `draggedCard`, `overStage`, `dragOffset`
  - Calculate drop position
  - Compute counts/positions reactively

### Phase 3: Drag & Drop Implementation
- [ ] **T3.1.5: Implement card drag start**
  - Listener: `@dragstart` on card
  - Capture card data (id, current stage)
  - Create dragging visual (shadow, opacity)
  - Delay: 200ms before drag starts (long-press feel)

- [ ] **T3.1.6: Implement stage drag over**
  - Listener: `@dragover` on stage
  - Debounce: 100ms (prevent re-renders on every pixel)
  - Highlight stage
  - Calculate drop position in stage
  - Show position indicator (visual line)

- [ ] **T3.1.7: Implement card drop**
  - Listener: `@drop` on stage
  - API call: `PATCH /api/v1/contacts/{id}` with new stage
  - Optimistic UI: update local state immediately
  - Handle error: revert to original if API fails

- [ ] **T3.1.8: Implement drag abort**
  - Listener: `@dragleave` (leave valid drop zone)
  - On mouse leave valid zone: card returns to original
  - Animation: smooth 200ms return

### Phase 4: Performance Optimization
- [ ] **T3.1.9: Virtual scrolling for large lists**
  - Implement vue-virtual-scroller (or similar)
  - Only render visible cards (not all 100+)
  - Reduces DOM nodes, improves FPS
  - Test with 100, 500 cards

- [ ] **T3.1.10: Debounce dragover events**
  - Use composable: `useDebouncedDragover.js`
  - Debounce 100ms (reduce handler calls)
  - Calculate drop position efficiently
  - Measure FPS improvement

- [ ] **T3.1.11: CSS transforms (not position changes)**
  - Use `transform: translate()` instead of `top/left`
  - Transforms use GPU acceleration (faster)
  - `will-change: transform` for hints to browser
  - Measure FPS with DevTools

### Phase 5: Mobile/Touch Support
- [ ] **T3.1.12: Implement pointer events (not Touch API)**
  - Listener: `@pointerdown`, `@pointermove`, `@pointerup`
  - Pointer events work on mouse, touch, pen (unified API)
  - Prevent scroll during drag: `pointer-events: none`
  - Test on real device

- [ ] **T3.1.13: Test iOS Safari touch**
  - Open Kanban on iPad or iPhone
  - Long-press card (200ms delay trigger)
  - Drag across stages
  - Verify smooth animation
  - Document any iOS quirks

- [ ] **T3.1.14: Test Android Chrome touch**
  - Open Kanban on Android phone
  - Long-press card
  - Drag across stages
  - Verify smooth animation
  - No interference with vertical scroll

### Phase 6: API Integration
- [ ] **T3.1.15: Implement optimistic UI + API sync**
  - Drop → update local state immediately (optimistic)
  - PATCH request async: `PATCH /api/v1/contacts/{id} with { stage: newStageId, position: positionInStage }`
  - If 200 OK: confirm update (no-op, already updated)
  - If error: emit event to revert position, show error toast

- [ ] **T3.1.16: Test API contract**
  - Verify endpoint exists: `PATCH /api/v1/contacts/{id}`
  - Verify response: `{ contact: { stage: "...", position: ... } }`
  - Test with curl: `curl -X PATCH http://localhost:3000/api/v1/contacts/1 -H "Content-Type: application/json" -d '{"stage": "sales"}'`

### Phase 7: Testing
- [ ] **T3.1.17: Unit tests - drag state**
  - Test: drag start, calculate position, drag end
  - Mock API, verify call made with correct data
  - Run: `npm test components/KanbanBoard.spec.js`

- [ ] **T3.1.18: Performance test - 60 FPS**
  - Load 100 cards, start dragging
  - Open Chrome DevTools Performance tab
  - Record drag session
  - Measure FPS: target >= 60
  - Document frame time (should be < 16.67ms)

- [ ] **T3.1.19: Performance test - Firefox**
  - Open Kanban in Firefox
  - Open Firefox DevTools Performance tab
  - Drag with 100 cards
  - Measure FPS: target >= 60
  - Check for long-running JavaScript

- [ ] **T3.1.20: Manual E2E testing**
  - Drag card to different stage → persists backend
  - Drag to same stage → no-op, returns
  - Drag outside valid zone → returns to original
  - 100 cards loaded → no lag during drag
  - Network error → reverts, shows error toast
  - Touch on mobile → drag works

- [ ] **T3.1.21: Regression testing**
  - Run: `npm test && npm run lint && npm run typecheck`
  - Other filters still work (status, search)
  - Kanban view renders correctly
  - Cards not stuck in loading state

---

## Testing Strategy

### Automated Testing
| Test Type | Tool | Command | Success Criteria |
|-----------|------|---------|------------------|
| Components | Jest | `npm test components/KanbanBoard.spec.js` | All pass |
| Performance | Lighthouse | Run audit with 100 cards | 60+ FPS |
| Full Test | Jest | `npm test` | All pass |

### Manual Testing
| Test Case | Steps | Expected Result | Evidence |
|-----------|-------|-----------------|----------|
| **Drag Card** | Click card, drag to stage | Card follows cursor smoothly | Video |
| **Drop Persists** | Drag card, drop → reload | Card stays in new stage | Screenshot |
| **60 FPS (100 cards)** | DevTools, drag with 100 cards | Frame rate >= 60 FPS | DevTools screenshot |
| **Destination Highlights** | Drag over stage | Stage highlights (border/bg) | Video |
| **Position Indicator** | Drag between cards | Visual line shows position | Video |
| **Same Stage Drop** | Drag to same stage | Card returns to original | Video |
| **Outside Zone Drop** | Drag outside stages | Card returns to original | Video |
| **Network Error** | Mock API error, drag | Revert, show error toast | Video |
| **Touch iOS** | iPad, drag card | Smooth drag, stage changes | Video (on device) |
| **Touch Android** | Android phone, drag card | Smooth drag, no scroll conflict | Video (on device) |
| **Firefox Compat** | Firefox, drag 100 cards | 60 FPS, smooth animation | DevTools screenshot |

---

## Development Notes

### Architectural Decisions
1. **vuedraggable or native Drag API**
   - vuedraggable: easier, but adds dependency
   - Native HTML5 Drag API: lighter, no dependency
   - Decision: use vuedraggable if available, native if not

2. **Virtual Scrolling**
   - Render only visible cards in viewport
   - Reduces DOM nodes: 100 → ~10 visible
   - Improves FPS dramatically
   - Must work with drag library

3. **Optimistic UI**
   - Update local state on drop immediately
   - API sync async in background
   - If API fails: revert state, show error
   - User sees instant feedback

4. **Debounced dragover**
   - Drag generates ~100 dragover events/sec
   - Debounce 100ms: ~10 handler calls/sec
   - Prevents re-render thrashing
   - Maintains smooth animation

5. **CSS Transforms (not top/left)**
   - Transforms use GPU (faster)
   - `top/left` forces layout recalculation (slower)
   - Use `will-change: transform` hint to browser

### Implementation Approach
1. Setup drag library (vuedraggable or native)
2. Implement card drag listeners (start, over, drop)
3. Add virtual scrolling
4. Implement debounced dragover
5. API integration with optimistic UI
6. Performance testing (60 FPS with 100+ cards)
7. Mobile/touch testing

### Files Affected
- `src/components/KanbanBoard.vue` (MODIFY or CREATE)
- `src/components/KanbanCard.vue` (MODIFY)
- `src/composables/useDebouncedDragover.js` (NEW)
- `src/composables/useDragAndDrop.js` (NEW)
- `src/assets/styles/kanban-drag.scss` (NEW)
- `tests/unit/components/KanbanBoard.spec.js` (NEW or MODIFY)

### No Database Changes
This is pure frontend with API calls to existing endpoint.

---

## Risk Mitigation

### Risk: Performance Below 60 FPS with 100+ Cards
- **Likelihood:** HIGH (common with drag & drop at scale)
- **Impact:** Janky drag, poor UX
- **Mitigation:** Virtual scrolling, debounce dragover, CSS transforms
- **Testing:** DevTools Performance test (T3.1.18, T3.1.19)

### Risk: Mobile Touch Not Working
- **Likelihood:** MEDIUM (pointer events need careful setup)
- **Impact:** Drag broken on mobile
- **Mitigation:** Use Pointer Events API (unified), test on real devices
- **Testing:** iOS and Android device tests (T3.1.13, T3.1.14)

### Risk: Firefox Compatibility Issues
- **Likelihood:** MEDIUM (Firefox drag behavior differs)
- **Impact:** Drag buggy on Firefox
- **Mitigation:** Explicit Firefox testing, use standard APIs
- **Testing:** Firefox performance test (T3.1.19)

### Risk: Network Error Doesn't Revert Card
- **Likelihood:** LOW
- **Impact:** Card stays in wrong stage after API fails
- **Mitigation:** Emit revert event, catch API errors
- **Testing:** Error handling test (T3.1.20)

---

## Story Points & Effort

| Estimate | Days | Notes |
|----------|------|-------|
| **Story Points** | 13 | High complexity: drag, performance, mobile |
| **Developer Days** | 5-6 | Performance optimization critical |
| **QA Days** | 1-2 | DevTools testing, device testing |
| **Total Calendar Days** | 5-6 | Longest Wave 3 task |

---

## File List

### Files Affected
- `src/components/KanbanBoard.vue` (MODIFY or CREATE)
- `src/components/KanbanCard.vue` (MODIFY)
- `src/composables/useDebouncedDragover.js` (NEW)
- `src/composables/useDragAndDrop.js` (NEW)
- `src/assets/styles/kanban-drag.scss` (NEW)
- `tests/unit/components/KanbanBoard.spec.js` (NEW or MODIFY)

---

## Development Agent Record

**Assigned to:** @dev (Dex)  
**Status:** Ready for Development (blocked by Wave 2)  

### Pre-Development Checklist
- [x] AC clear and performance targets defined
- [x] Drag library decision made
- [x] Virtual scrolling requirement identified
- [x] Performance testing methodology defined
- [x] **BLOCKED by Wave 2** — wait for S2.1 and S2.2 complete

---

## QA Results

**QA Gate:** PENDING  
**QA Assigned to:** @qa (Quinn)  

### QA Checklist
- [ ] Card follows cursor during drag (smooth)
- [ ] Destination stage highlights on drag over
- [ ] Position indicator shows drop position
- [ ] Card persists in new stage after drop
- [ ] Drag to same stage: no-op, returns original
- [ ] Drag outside valid zone: returns original
- [ ] 100 cards loaded: drag maintains 60 FPS
- [ ] Firefox drag: 60 FPS, no lag
- [ ] iOS touch drag: works, smooth
- [ ] Android touch drag: works, smooth
- [ ] Network error: reverts card, shows error
- [ ] No regressions in other features

**QA Verdict:** PENDING (awaiting @dev implementation)

---

## Change Log

| Date | Author | Change | Status |
|------|--------|--------|--------|
| 2026-05-04 | Aria | Story created from EPIC-001-IMPLEMENTATION-PLAN | CREATED |

---

## Related Stories

- **Depends on:** [S2.1 - Z-INDEX Fix](./EPIC-001-S2.1.md) + [S2.2 - Status Filter](./EPIC-001-S2.2.md)
- **Enables:** [S4.1 - Deduplication](./EPIC-001-S4.1.md)
- **Wave 3:** S3.1 only story
- **Epic:** [EPIC-001-KANBAN](./EPIC-001-KANBAN.md)

---

## Dependencies

- **Blocked by:** Wave 1 (S1.1, S1.2, S1.3) + Wave 2 (S2.1, S2.2)
- **Blocks:** S4.1 (S4.1 cannot start until Wave 3 complete)

---

## Critical Path Impact

**S2.1 → S2.2 → S3.1 → S4.1**

This story is on critical path. Delays impact Wave 4.

---

EOF
