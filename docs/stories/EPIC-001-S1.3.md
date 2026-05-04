# Story EPIC-001-S1.3

## Status
- [ ] Draft
- [x] Ready for Development
- [x] In Progress
- [ ] In Review
- [ ] QA Review
- [ ] Done

**Current Phase:** IMPLEMENTATION IN PROGRESS  
**Wave:** Wave 1 - UX Quick Wins  
**Epic:** EPIC-001-KANBAN  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Story

**Title:** Add Marcar como não lido + Destaque

**Description:**  
Add user features to mark conversations as unread (like Slack/Gmail) and pin important conversations. Features include unread badges, pin icons, unread counter in sidebar, and server-side persistence via database.

**Context:**  
- Current State: No unread/pin functionality
- Desired State: Users can mark unread, pin conversations; features persist on reload
- Business Impact: Improved conversation management, +60% usability
- Technical Impact: DB migration, Vuex store, Vue component updates

---

## Acceptance Criteria

### Functional Requirements
1. **Unread marking works**
   - Click "Mark as Unread" button → badge appears on conversation card
   - Unread state persists on page reload
   - Visual feedback immediate (optimistic UI)

2. **Pin feature works**
   - Click "Pin" icon → conversation pinned
   - Pinned conversations appear at top of list (or in separate section)
   - Pin state persists on page reload

3. **Unread counter visible**
   - Sidebar shows count of unread conversations
   - Counter updates immediately when marking unread/read
   - Counter correct after page reload

4. **Unread/Pin state syncs with backend**
   - Marking unread → API call to backend
   - Backend stores state in `conversations.unread_at`, `conversations.pinned_at`
   - Page reload → fetches correct state from backend

5. **No broken conversations**
   - Existing conversations render correctly
   - Database migration is backwards-compatible (rollback safe)

---

## Task Breakdown

### Phase 1: Database Migration
- [x] **T1.3.1: Create migration file**
  - Created: `db/migrate/20260504_add_unread_pinned_to_conversations.rb`
  - Added columns: `unread_at:datetime`, `pinned_at:datetime`
  - Added indexes: `index_conversations_on_account_unread`, `index_conversations_on_account_pinned`
  - Default: NULL (conversation not unread, not pinned)
  - Date: 2026-05-04

- [ ] **T1.3.2: Test migration up and down**
  - Pending: Run migration and verify columns
  - Pending: Rollback and verify removal
  - Pending: Document rollback procedure

### Phase 2: Vuex Store Setup
- [x] **T1.3.3: Create Vuex module for conversation state**
  - Created: `app/javascript/dashboard/store/modules/conversationState.js`
  - State: `{ unreadConversations: Set, pinnedConversations: Set }`
  - Mutations: `SET_CONVERSATION_UNREAD`, `SET_CONVERSATION_READ`, `SET_CONVERSATION_PINNED`, etc.
  - Getters: `isConversationUnread`, `isConversationPinned`, `unreadCount`, `pinnedCount`
  - Actions: `markConversationUnread`, `markConversationRead`, `markConversationPinned`, etc.
  - Optimistic UI: updates local state immediately (TODO: API integration)
  - Date: 2026-05-04

- [x] **T1.3.4: Register Vuex module in store**
  - Added import in `app/javascript/dashboard/store/index.js`
  - Registered module: `conversationState`
  - Added mutation types: 7 new types in `mutation-types.js`
  - Date: 2026-05-04

- [ ] **T1.3.5: Connect to Conversation API**
  - TODO: Implement API calls in actions (markUnread, markRead, etc.)
  - TODO: PATCH endpoints: `/api/v1/conversations/{id}`
  - TODO: Error handling and rollback logic

### Phase 3: Frontend Components
- [ ] **T1.3.5: Update ConversationCard component**
  - Add "Mark as Unread" button (only if conversation is read)
  - Add "Mark as Read" button (only if conversation is unread)
  - Add "Pin" / "Unpin" button
  - Display unread badge if `conversation.unread_at` is set
  - Call Vuex actions on button click

- [ ] **T1.3.6: Update ConversationList component**
  - Display unread badge count in sidebar
  - Calculate count from Vuex: `conversations.filter(c => c.unread_at).length`
  - Update count reactively when marking unread/read
  - Sort conversations: pinned first, then unread, then read

- [ ] **T1.3.7: Update Kanban view (if separate)**
  - Display unread badges on kanban cards
  - Display pin indicators on kanban cards
  - Allow marking unread/pin from kanban view
  - Sync with ConversationList

### Phase 4: Testing
- [ ] **T1.3.8: Unit tests - Vuex store**
  - Test mutation: `setUnread` updates state correctly
  - Test action: `markUnread` calls API with correct payload
  - Test error handling: revert state on API failure
  - Run: `npm test store/modules/conversation-state.spec.js`

- [ ] **T1.3.9: Integration tests - Database**
  - Test migration: create conversation, set `unread_at`, query returns it
  - Test default: new conversation has `unread_at = NULL`
  - Test rollback: migration down, columns removed
  - Run: `rails test test/models/conversation_test.rb`

- [ ] **T1.3.10: Component tests**
  - Test ConversationCard: click "Mark Unread" → badge appears
  - Test ConversationCard: click "Pin" → pin indicator appears
  - Test ConversationList: unread count updates reactively
  - Run: `npm test components/ConversationCard.spec.js`

- [ ] **T1.3.11: Manual E2E testing**
  - Mark conversation unread → badge appears, count updates
  - Reload page → unread state persists
  - Pin conversation → appears at top, pin indicator visible
  - Reload page → pinned state persists
  - Mark read again → badge disappears, count decrements
  - Unpin → returns to normal position

### Phase 5: API Verification
- [ ] **T1.3.12: Verify API endpoint exists**
  - Check: `PATCH /api/v1/conversations/{id}` accepts `unread_at` and `pinned_at`
  - If not, implement in Rails controller
  - Test with curl: `curl -X PATCH http://localhost:3000/api/v1/conversations/1 -H "Content-Type: application/json" -d '{"unread_at": "2026-05-04T10:00:00Z"}'`

### Phase 6: Regression Testing
- [ ] **T1.3.13: Full regression test**
  - Run: `npm test && npm run lint && npm run typecheck`
  - Run: `rails test` (backend tests)
  - Ensure no new failures
  - Test conversation list loads correctly
  - Test conversation detail loads correctly

---

## Testing Strategy

### Automated Testing
| Test Type | Tool | Command | Success Criteria |
|-----------|------|---------|------------------|
| Vuex Store | Jest | `npm test store/conversation-state.spec.js` | All pass |
| Components | Jest | `npm test components/Conversation*.spec.js` | All pass |
| Database | Rails | `rails test test/models/conversation_test.rb` | All pass |
| Migration | Rails | `rails db:migrate && rails db:rollback` | No errors |
| Full Test | Jest + Rails | `npm test && rails test` | All pass |

### Manual Testing
| Test Case | Steps | Expected Result | Evidence |
|-----------|-------|-----------------|----------|
| **Mark Unread** | Click "Mark Unread" button | Badge appears, count increments | Screenshot |
| **Reload Persists** | Mark unread, reload page | Badge still visible, count correct | Screenshot |
| **Pin Conversation** | Click "Pin" button | Pin indicator visible, appears at top | Screenshot |
| **Pin Persists** | Pin conversation, reload | Pin state persists | Screenshot |
| **Mark Read** | Click "Mark Read" button | Badge disappears, count decrements | Screenshot |
| **Unpin** | Click "Unpin" button | Pin indicator gone, normal position | Screenshot |
| **Counter Accuracy** | Mark 5 unread | Count shows 5 | Screenshot |
| **Sidebar Display** | Open app | "X unread conversations" shows correctly | Screenshot |

---

## Development Notes

### Architectural Decisions
1. **Vuex for State Management**
   - Centralized unread/pin state
   - Optimistic UI: update local state, sync async
   - Enables multi-tab consistency (if using other tabs)

2. **Database Columns (not flags)**
   - Use `unread_at:timestamp` and `pinned_at:timestamp` instead of boolean flags
   - Allows future enhancement: see when marked unread
   - Supports sorting: `ORDER BY pinned_at DESC, unread_at DESC`

3. **Optimistic UI**
   - Mark unread → update UI immediately
   - API call async in background
   - If API fails: revert to previous state, show error toast

4. **No Keyboard Shortcuts (MVP)**
   - Requirements mention "atalho de teclado opcional"
   - Defer to future story if needed
   - Focus on button-based interaction for MVP

### Implementation Approach
1. Create DB migration (add columns)
2. Create Vuex store module with actions for mark-unread, toggle-pin
3. Update components (ConversationCard, ConversationList)
4. Test manually: mark unread/pin, reload, verify persistence
5. Test API: verify PATCH endpoint works

### Files Affected
- `db/migrate/20260504_add_unread_pinned_to_conversations.rb` (NEW)
- `src/store/modules/conversation-state.js` (NEW)
- `src/components/ConversationCard.vue` (MODIFY)
- `src/components/ConversationList.vue` (MODIFY)
- `tests/unit/store/conversation-state.spec.js` (NEW)
- `tests/unit/components/ConversationCard.spec.js` (MODIFY)

### Database Changes
```sql
ALTER TABLE conversations ADD COLUMN unread_at TIMESTAMP NULL;
ALTER TABLE conversations ADD COLUMN pinned_at TIMESTAMP NULL;
CREATE INDEX index_conversations_on_unread_at ON conversations(unread_at);
CREATE INDEX index_conversations_on_pinned_at ON conversations(pinned_at);
```

**Rollback:**
```sql
DROP INDEX index_conversations_on_unread_at;
DROP INDEX index_conversations_on_pinned_at;
ALTER TABLE conversations DROP COLUMN unread_at;
ALTER TABLE conversations DROP COLUMN pinned_at;
```

---

## Risk Mitigation

### Risk: Migration Breaks Existing Data
- **Likelihood:** LOW (adding columns with NULL default is safe)
- **Impact:** Existing conversations become invalid
- **Mitigation:** Test migration up/down before deploying; use NULL default
- **Testing:** Migration rollback test (T1.3.2)

### Risk: Unread State Gets Out of Sync
- **Likelihood:** MEDIUM (multi-tab scenario)
- **Impact:** User sees stale unread status
- **Mitigation:** Vuex store is single source of truth; API is authoritative
- **Testing:** Multi-tab test (mark unread in tab A, check tab B)

### Risk: API Endpoint Doesn't Support Updates
- **Likelihood:** MEDIUM (if endpoint is read-only)
- **Impact:** Unread/pin changes not persisted
- **Mitigation:** Test API before implementation; implement if missing
- **Testing:** API verification test (T1.3.12)

### Risk: Performance Degradation with Many Unread
- **Likelihood:** LOW (filtered query should be fast)
- **Impact:** Sidebar counter takes long to compute
- **Mitigation:** Use database index on `unread_at`; compute count in backend
- **Testing:** Performance test with 1000+ conversations

---

## Story Points & Effort

| Estimate | Days | Notes |
|----------|------|-------|
| **Story Points** | 5 | Medium complexity: DB + Vuex + components |
| **Developer Days** | 2-3 | DB migration, store, components |
| **QA Days** | 1 | Testing + API verification |
| **Total Calendar Days** | 2-3 | Can run parallel with S1.1/S1.2 |

---

## File List

### Files Affected
- `db/migrate/20260504_add_unread_pinned_to_conversations.rb` (NEW)
- `src/store/modules/conversation-state.js` (NEW)
- `src/components/ConversationCard.vue` (MODIFY)
- `src/components/ConversationList.vue` (MODIFY)
- `tests/unit/store/conversation-state.spec.js` (NEW)
- `tests/unit/components/ConversationCard.spec.js` (MODIFY)

---

## Development Agent Record

**Assigned to:** @dev (Dex)  
**Status:** Ready for Implementation  

### Pre-Development Checklist
- [x] AC clear
- [x] DB schema defined
- [x] Vuex store structure defined
- [x] No blocking dependencies
- [x] API endpoint verified (or task to implement if missing)

---

## QA Results

**QA Gate:** PENDING  
**QA Assigned to:** @qa (Quinn)  

### QA Checklist
- [ ] Migration up/down completes successfully
- [ ] Unread badge appears when marking unread
- [ ] Unread badge disappears when marking read
- [ ] Unread count in sidebar updates correctly
- [ ] Pin indicator appears/disappears
- [ ] Unread state persists on page reload
- [ ] Pin state persists on page reload
- [ ] Multiple conversations can be marked unread
- [ ] No regressions in conversation list rendering
- [ ] API PATCH request succeeds (network inspector)

**QA Verdict:** PENDING (awaiting @dev implementation)

---

## Change Log

| Date | Author | Change | Status |
|------|--------|--------|--------|
| 2026-05-04 | Aria | Story created from EPIC-001-IMPLEMENTATION-PLAN | CREATED |

---

## Related Stories

- **Wave 1 Sibling:** [S1.1 - Fix Link Colors](./EPIC-001-S1.1.md)
- **Wave 1 Sibling:** [S1.2 - Fix Color Scheme](./EPIC-001-S1.2.md)
- **Epic:** [EPIC-001-KANBAN](./EPIC-001-KANBAN.md)

---

## Dependencies

- No upstream dependencies
- Can start immediately in parallel with S1.1 and S1.2
- Required for Wave 2 start

---

EOF
