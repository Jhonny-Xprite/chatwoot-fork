# EPIC-001: SPECIFICATION
## Kanban & Chat Platform Refinements - Complete Technical Specification

**Document ID:** EPIC-001-SPEC-v1.0  
**Date:** 2026-05-04  
**Status:** SPECIFICATION_PHASE  
**Owner:** Morgan (PM)  
**Reviewed By:** Aria (Architect), Atlas (Analyst)

---

## 📋 Executive Summary

This specification consolidates requirements, technical complexity assessment, and research findings for EPIC-001 (Kanban & Chat Platform Refinements). The epic addresses 7 critical UX/functionality/data-integrity issues through 4 implementation waves, targeting 17-24 days of effort with 1-2 developers.

**Strategic Impact:**
- Usability improvement: +60%
- WCAG AA compliance: 100%
- Zero duplicate contacts
- 60 FPS drag & drop performance

---

## 🎯 Requirements Summary

### Functional Requirements

| ID | Category | Requirement | Stories |
|----|----|-----------|---------|
| **FR-001** | UX - Visibility | All UI elements meet WCAG AA contrast (4.5:1) | S1.1, S1.2 |
| **FR-002** | UX - Design | Light/dark theme support with proper color schemes | S1.1, S1.2 |
| **FR-003** | Features | Unread badge + pin icons + unread counter | S1.3 |
| **FR-004** | UI Fix | Filter dropdown z-index above all cards | S2.1 |
| **FR-005** | Kanban | Status/stage filtering in real-time | S2.2 |
| **FR-006** | Interaction | Trello-like drag & drop (mouse + touch) | S3.1 |
| **FR-007** | Data Integrity | Contact deduplication (exact + fuzzy match) | S4.1 |

### Non-Functional Requirements

| ID | Requirement | Target | Stories |
|----|-----------|--------|---------|
| **NFR-001** | WCAG AA Accessibility | 100% compliance | S1.1, S1.2, S2.1 |
| **NFR-002** | Browser Compatibility | Chrome, Firefox, Safari | All |
| **NFR-003** | Responsive Design | 320px - 1920px viewports | S1.2, S2.1, S2.2, S3.1 |
| **NFR-004** | Drag Performance | 60 FPS with 100+ cards | S3.1 |
| **NFR-005** | Data Safety | Zero data loss on dedup | S4.1 |
| **NFR-006** | Theme Support | Light + Dark themes | S1.1, S1.2 |

---

## 🔍 Technical Complexity Assessment

### Timeline Adjustment

**Original Estimate:** 17-22 days  
**Adjusted Estimate:** 18-24 days (with contingency)

**Adjustment Rationale:**
- +1 day: S1.2 accessibility testing (complex color validation)
- +1 day: S3.1 performance optimization (100+ cards)
- +2 days: S4.1 data integrity testing (highest risk)

### Effort Breakdown by Story

| Story | Wave | Complexity | Effort | Risk | Notes |
|-------|------|-----------|--------|------|-------|
| **S1.1** | 1 | LOW | 1-2 days | LOW | Quick CSS fix, WCAG validation critical |
| **S1.2** | 1 | LOW | 2-3 days | LOW-MEDIUM | Accessibility testing extensive |
| **S1.3** | 1 | MEDIUM | 3 days | MEDIUM | DB migration + Vuex integration |
| **S2.1** | 2 | LOW | 1 day | LOW | **BLOCKER for S2.2** |
| **S2.2** | 2 | MEDIUM | 2-3 days | MEDIUM | Depends on S2.1 |
| **S3.1** | 3 | HIGH | 5-6 days | HIGH | **Performance critical**, 100+ cards |
| **S4.1** | 4 | HIGH | 7-8 days | CRITICAL | **Data integrity critical**, highest risk |

### Critical Path

```
┌─ S1.1 (1-2d) ─┐
├─ S1.2 (2-3d) ─┼─ Wave 1 (5-7d) ─┐
├─ S1.3 (3d)  ─┘                    │
                                      ├─ S2.1 (1d) ─ S2.2 (2-3d) ─ Wave 2 (3-4d) ─┐
                                                                                    ├─ S3.1 (5-6d) ─ Wave 3 (5-6d) ─ S4.1 (7-8d) ─ Wave 4 (7-8d)
                                                                                    │
                                      └─────────────────────────────────────────┘
```

---

## 🔧 Technical Stack & Tools

### Frontend Stack

**Technology:** Vue 3 + Vuex + SCSS  
**Key Libraries:**
- `vuedraggable` (if available) OR native HTML5 Drag API
- `string-similarity` or `fuzzyset.js` (for contact dedup fuzzy matching)

**WCAG Validation Tools:**
- **Development:** axe DevTools (browser extension)
- **Manual:** WebAIM contrast checker + Coblis color blindness simulator
- **CI/CD:** jest-axe for automated testing
- **Performance:** Lighthouse + Chrome DevTools

### Backend Stack

**Technology:** Rails + Sidekiq  
**Changes:**
- New service: `ContactDeduplicationService`
- New job: `DedupContactsJob` (weekly background job)
- Database migrations: +2 (add columns, unique constraint)
- New API endpoints: +3 (move_to_stage, mark_unread, pin, merge)

---

## 📐 Implementation Details

### Story S1.1: Fix Link Colors

**Acceptance Criteria:**
- Links meet 4.5:1 contrast ratio (WCAG AA)
- Links distinguished by color + underline/indicator (not just color)
- Works in light + dark themes
- Tested in Chrome, Firefox, Safari

**Technical Approach:**
1. Use WebAIM contrast checker to select link color
2. Apply color via CSS variables (light: `--link-color-light`, dark: `--link-color-dark`)
3. Add underline or text-decoration to distinguish from text
4. Test with axe DevTools + Coblis

**Files:**
- `app/javascript/dashboard/components/conversation/Message.vue`
- `app/javascript/dashboard/styles/conversation.scss`

**Testing:**
- axe DevTools: 0 violations
- WebAIM: 4.5:1 contrast in both themes
- Manual: Firefox, Safari

---

### Story S1.2: Fix Conversation Detail Colors

**Acceptance Criteria:**
- Messages from client vs agent clearly differentiated
- All text >= 4.5:1 contrast ratio
- Sender info (name, avatar, status) clearly visible
- Works in light + dark themes
- Accessible in color blindness (Coblis test)

**Technical Approach:**
1. Separate CSS classes for `.message-client` vs `.message-agent`
2. Use CSS custom properties for theming
3. Test with Coblis color blindness simulator (deuteranopia, protanopia, tritanopia)
4. Ensure responsive design (mobile 320px)

**Files:**
- `app/javascript/dashboard/components/conversation/ConversationDetails.vue`
- `app/javascript/dashboard/styles/conversation-detail.scss`

**Testing:**
- axe DevTools
- WebAIM (all text + background combinations)
- Coblis (3 color blindness types)
- Lighthouse accessibility audit
- Mobile responsive (Chrome emulation)

**Risk Mitigation:**
Complex color scheme → extensive accessibility testing required

---

### Story S1.3: Unread + Pin Features

**Acceptance Criteria:**
- Buttons appear in ConversationHeader (unread + pin)
- Visual indicators: red badge for unread, pin icon for pinned
- State persists on reload
- Unread counter in sidebar
- Filter "Show unread" integrates with S2.2

**Technical Approach:**
1. Database migration: add `is_unread` + `is_pinned` columns
2. API endpoints: `PATCH /conversations/:id/mark_unread/mark_read/pin/unpin`
3. Vuex mutations: `SET_UNREAD_STATE`, `SET_PINNED_STATE`
4. UI: toggle buttons with visual feedback
5. Add index on `is_unread` for filter performance

**Files:**
- `app/models/conversation.rb` (new scopes)
- `db/migrate/[ts]_add_unread_pinned_to_conversations.rb`
- `app/javascript/dashboard/components/conversation/ConversationHeader.vue`
- `app/javascript/dashboard/components/crm/ContactPipelineCard.vue`
- `app/javascript/dashboard/store/modules/conversations/actions.js`

**Testing:**
- Unit: Conversation model scopes (`:unread`, `:pinned`)
- API: All 4 endpoints
- UI: Toggle buttons + persistence on reload
- Regression: Ensure other features unaffected

---

### Story S2.1: Fix Filter Z-Index

**Acceptance Criteria:**
- Dropdown z-index >= 50 (above all cards)
- Doesn't get clipped at viewport edges
- Works with page scrolling
- Keyboard accessible (Tab, Escape)

**Technical Approach:**
1. Update `.filter-dropdown` CSS: `z-index: 50; position: absolute;`
2. Ensure parent `.filter-bar` has `position: relative`
3. Test at viewport edges (left, right, bottom)
4. Test with scroll active

**Files:**
- `app/javascript/dashboard/components/crm/FilterBar.vue`
- `app/javascript/dashboard/styles/filter.scss`

**Testing:**
- Visual: Dropdown always visible
- Edge cases: Bottom of viewport
- Scroll: Dropdown visible while scrolling
- Keyboard: Tab + Escape work

**Critical Note:** This is a BLOCKER for S2.2 - must be completed first.

---

### Story S2.2: Status Filter

**Acceptance Criteria:**
- Dropdown lists all pipeline stages
- Default: "All stages" (no filter)
- Filters in real-time (no reload)
- Persists in URL: `?status=stage-id`
- Combines with other filters (assignee, labels, etc)
- Shows count per status: "Novo (15)"

**Technical Approach:**
1. Vuex: add `stageFilter` to state
2. Mutation: `SET_STAGE_FILTER(stageId)`
3. Getter: `getAppliedFilters` (include stageFilter)
4. Watch: on stageFilter change → refresh contacts
5. URL: add query param handling
6. API: include `?stage_id=X` in requests

**Files:**
- `app/javascript/dashboard/components/crm/FilterBar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue`
- `app/javascript/dashboard/store/crm/pipeline.js`
- `app/javascript/dashboard/store/mutation-types.js`

**Dependencies:** S2.1 must be complete (z-index fix)

**Testing:**
- Dropdown filters contacts
- URL persists filter
- Reload maintains filter
- Works with other filters
- Counts accurate

---

### Story S3.1: Drag & Drop (Trello-like)

**Acceptance Criteria:**
- Card levanta on click+hold (200ms delay)
- Follows cursor while dragging
- Visual feedback: shadow, column highlight, insert line
- Smooth animation on drop (200-300ms)
- Works with 100+ cards (60 FPS)
- Mobile/touch support
- Backend persists (POST to API)

**Technical Approach:**

**Option A: Vuedraggable (RECOMMENDED if available)**
```
1. Check package.json for vuedraggable
2. If yes: Use <draggable> component wrapper
3. Handles state, animations, mobile - minimal code
```

**Option B: Native HTML5 Drag API (FALLBACK)**
```
1. Add event listeners: mousedown, mousemove, mouseup
2. Create drag overlay (ghost image)
3. Check drop targets, provide visual feedback
4. Post to backend on drop
5. Animate card reallocation
```

**Performance Optimization:**
1. Debounce dragover events (100ms max)
2. Use virtual scrolling if 100+ cards (`vue-virtual-scroller`)
3. Use CSS transforms (will-change) not position changes
4. Memoize drop target calculations

**Files:**
- `app/javascript/dashboard/components/crm/PipelineBoard.vue`
- `app/javascript/dashboard/components/crm/PipelineColumn.vue`
- `app/javascript/dashboard/components/crm/ContactPipelineCard.vue`
- `app/javascript/dashboard/api/crm/pipeline.js` (new: moveConversation)
- `app/controllers/api/v1/accounts/crm/conversations_controller.rb` (new: move_to_stage action)
- `app/javascript/dashboard/styles/kanban-drag-drop.scss`

**Testing:**
- Drag card between columns → persists on reload
- 100+ cards + Lighthouse FPS check
- Mobile: long-press drag on real device
- Firefox: explicit testing (different behavior)
- Edge cases: drag outside viewport (abort)

**Risk Mitigation:**
- Performance critical → extensive testing required
- Firefox compatibility → dedicated browser testing
- Mobile touch → real device testing, not emulation

---

### Story S4.1: Contact Deduplication

**Acceptance Criteria:**
- Detect duplicates: exact match (email+phone) + fuzzy (name similarity 0.95+)
- Consolidate contacts: 1 card per contact, multiple conversations
- Zero data loss: soft deletes, audit trail
- Backend prevents future duplication: unique constraint
- UI shows "X conversations" for multi-channel contacts

**Technical Approach:**

**Phase 1: Service Layer**
```ruby
class ContactDeduplicationService
  def self.merge(primary_contact, duplicate_contact, reason)
    transaction do
      # Move conversations from duplicate to primary
      duplicate_contact.conversations.update_all(contact_id: primary_contact.id)
      
      # Mark duplicate as merged (soft delete)
      duplicate_contact.update!(merged_to_id: primary_contact.id, is_merged: true)
      
      # Audit log
      log_merge(primary_contact, duplicate_contact, reason)
    end
  end
end
```

**Phase 2: Background Job**
```ruby
class DedupContactsJob < ApplicationJob
  def perform
    # Weekly job: find and merge exact matches
    Contact.unmerged.find_each do |contact|
      duplicates = find_duplicates(contact)  # email+phone exact match
      duplicates.each { |dup| merge(contact, dup) }
    end
  end
end
```

**Phase 3: API Endpoint**
```
POST /api/v1/accounts/:account_id/contacts/:id/merge_with/:duplicate_id
Body: { reason: "manual" }
Response: { success: true, primary_contact: {...} }
```

**Phase 4: Unique Constraint**
```sql
ALTER TABLE contacts
  ADD CONSTRAINT unique_contact_per_channel
  UNIQUE (account_id, phone_number, identifier)
  WHERE is_merged = false;
```

**Data Safety:**
1. Soft deletes: keep merged record, mark `is_merged = true`
2. Audit trail: log every merge (who, when, reason, before/after snapshot)
3. Merge chain: follow `merged_to_id` chain (A→B, B→C requires following)
4. Backup: require backup before batch merge operations

**Files:**
- `app/models/contact.rb`
- `app/services/contact_deduplication_service.rb` (NEW)
- `app/jobs/dedup_contacts_job.rb` (NEW)
- `db/migrate/[ts]_add_merge_tracking_to_contacts.rb` (NEW)
- `db/migrate/[ts]_add_unique_constraint_by_channel.rb` (NEW)
- `app/javascript/dashboard/components/crm/ContactPipelineCard.vue`

**Testing (CRITICAL):**
- Unit: Exact match detection (email+phone)
- Unit: Fuzzy match with threshold 0.95+
- Integration: Merge contacts, verify all conversations move
- Integration: Merge chains (A→B→C)
- Data: No data loss - all messages visible
- Audit: Log complete for every merge
- Staging dry-run: Test with production data snapshot
- Monitoring: Post-deploy, check merge logs daily

**Risk Mitigation:**
- CRITICAL RISK: Data loss if merge gone wrong
- Mitigation: Soft deletes, comprehensive testing, audit trail, backup before production
- Recommendation: Start with exact match, add fuzzy after validation
- Rollback: If merge detected as bad, unmerge capability

---

## 🧪 Testing Strategy

### Wave 1 Testing (S1.1, S1.2, S1.3)

**Accessibility:**
- axe DevTools: Run on every component, 0 violations
- WebAIM contrast checker: Manual verification of all text colors
- Coblis: Test S1.2 in all 3 color blindness types
- Keyboard: Tab, Shift+Tab, Enter, Escape all work

**Regression:**
- Existing conversation display unchanged
- Other pages unaffected
- Database migration reversible (test rollback)

### Wave 2 Testing (S2.1, S2.2)

**UI:**
- Filter dropdown visible at all viewport edges
- Filters update without page reload
- URL persists filter state
- Multiple filters combine correctly

**Regression:**
- Existing filters unaffected
- Kanban display unchanged

### Wave 3 Testing (S3.1)

**Performance:**
- Lighthouse: 60+ FPS during drag
- Chrome DevTools: Profile drag → check for reflows
- 100+ cards: No lag, smooth animations

**Compatibility:**
- Chrome: Primary browser
- Firefox: Explicit testing (different drag behavior)
- Safari: Touch support
- Mobile: Real device (not emulation)

**Functionality:**
- Drag card between columns
- Drop persists to backend
- Reload maintains new position
- Drag abort (mouse leaves) → card returns to original

### Wave 4 Testing (S4.1)

**Critical Tests:**
- Exact match detection (no false positives)
- Fuzzy match with threshold (manual review)
- Merge chain following (A→B→C)
- Zero data loss: all messages visible post-merge
- Audit trail: complete log of all merges
- Unmerge capability: reverse merge if needed
- Production dry-run: staging with prod data snapshot

**Safety Checks:**
- Backup before batch merge
- Monitor merge logs post-deploy
- Pause if data anomaly detected
- Rollback plan ready

---

## 📊 Success Metrics

| Metric | Target | Measurement | Wave |
|--------|--------|-------------|------|
| **WCAG AA Compliance** | 100% | axe DevTools + manual audit | 1,2,3 |
| **Drag Performance** | 60 FPS | Lighthouse + profiler | 3 |
| **Filter Accuracy** | 100% | Data audit | 2 |
| **Duplicate Contacts** | 0% | Monthly contact audit | 4 |
| **Usability** | +60% | User survey + session recording | All |

---

## 🚀 Rollout Strategy

### Phase 1: Deploy Waves 1-2 (8-11 days)
1. S1.1 + S1.2: Color fixes (parallel)
2. S1.3: Unread + pin (serial, after 1.1/1.2)
3. S2.1: Z-index fix (first in wave 2)
4. S2.2: Status filter (after S2.1)

### Phase 2: Deploy Wave 3 (5-6 days)
1. S3.1: Drag & drop (after Wave 1+2 complete)

### Phase 3: Deploy Wave 4 (7-8 days)
1. S4.1: Deduplication (LAST, for stability)

**Per-Wave Deployment:**
- 1 story per PR (never combine stories)
- QA gate before each deployment
- Monitor metrics post-deployment
- Rollback plan ready for each wave

---

## ⚠️ Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|-----------|
| WCAG non-compliance | Legal, accessibility reduced | MEDIUM | Automated + manual testing, Coblis |
| Drag performance lag | UX poor on large pipelines | MEDIUM | Virtual scrolling, debounce, profiling |
| Data loss in dedup | DATA LOSS - CRITICAL | LOW | Soft deletes, audit trail, backup, dry-run |
| S2.1 delay blocks S2.2 | Wave 2 extends | LOW | Prioritize S2.1 first |
| Firefox compatibility | ~15% user base affected | MEDIUM | Explicit Firefox testing |

---

## 📋 Approval & Sign-off

- [ ] Product Owner approved
- [ ] Technical Lead (Architect) approved
- [ ] QA Lead approved
- [ ] Timeline and risks accepted by stakeholders

---

## 🔗 Related Artifacts

- Requirements: `docs/specs/EPIC-001-requirements.json`
- Complexity Assessment: `docs/specs/EPIC-001-complexity.json`
- Research Findings: `docs/specs/EPIC-001-research.json`
- Epic Overview: `docs/epics/EPIC-001-KANBAN.md`
- Individual Stories: `docs/stories/EPIC-001-S*.md`

---

## 📝 Document History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-05-04 | Morgan (PM) | Initial specification from Spec Pipeline |
| | | Aria (Architect) | Technical complexity assessment |
| | | Atlas (Analyst) | Research & tool recommendations |

---

**Status:** AWAITING QA CRITIQUE  
**Next Phase:** CRITIQUE (@qa) → PLAN (@architect) → READY FOR DEVELOPMENT

