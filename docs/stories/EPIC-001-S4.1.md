# Story EPIC-001-S4.1

## Status
- [ ] Draft
- [x] Ready for Development
- [ ] In Progress
- [ ] In Review
- [ ] QA Review
- [ ] Done

**Current Phase:** SPECIFICATION COMPLETE  
**Wave:** Wave 4 - Data Integrity  
**Epic:** EPIC-001-KANBAN  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Story

**Title:** Resolver Duplicação de Cards (Contact Deduplication)

**Description:**  
Resolve duplicate contacts (same person contacted via different channels: WhatsApp, Email, SMS, etc.). Implement exact + fuzzy matching, consolidate conversations, ensure zero data loss via soft deletes and audit trails.

**Context:**  
- Current State: Same person creates multiple contacts (one per channel)
- Desired State: 1 contact per person, consolidated message history
- Business Impact: Clean database, improved CRM usability
- Technical Impact: Complex merging logic, data integrity critical

**⚠️ CRITICAL DATA INTEGRITY:** This story modifies production data. Soft deletes and backup procedures mandatory.

---

## Acceptance Criteria

### Functional Requirements
1. **Exact match detection**
   - Email exact match → suggests merge
   - Phone exact match → suggests merge
   - Combined email+phone exact → high confidence merge

2. **Fuzzy match detection**
   - Name fuzzy match (Levenshtein distance) with 0.95+ threshold
   - Examples: "John Smith" matches "Jon Smith", but not "Jane Smith"
   - No false positives (threshold = 0.95 prevents noise)

3. **User confirms merge**
   - Manual merge: show side-by-side preview of contacts
   - User clicks "Confirm Merge"
   - No automatic merging (prevents accidents)

4. **Zero data loss**
   - All messages preserved (soft delete source contact)
   - Conversation history consolidated
   - Messages appear in chronological order
   - No data deleted permanently

5. **Merge audit trail**
   - contact_merge_logs table records all merges
   - Log includes: source_id, target_id, merged_at, merged_by
   - Enables troubleshooting and rollback

6. **Rollback capability**
   - Source contact can be restored (is_deleted = false)
   - All messages still accessible post-restore
   - Audit trail documents restore

---

## Task Breakdown

### Phase 1: Database Setup
- [ ] **T4.1.1: Create migration for soft deletes**
  - Add columns: `is_deleted:boolean (default: false)`, `deleted_at:timestamp`
  - Add index on `is_deleted` (for filtering)
  - Add index on `deleted_at` (for sorting/debugging)

- [ ] **T4.1.2: Create contact_merge_logs table**
  - Columns:
    - `id:bigint (primary key)`
    - `source_contact_id:bigint (FK → contacts)`
    - `target_contact_id:bigint (FK → contacts)`
    - `merged_at:timestamp (DEFAULT: current_timestamp)`
    - `merged_by:string (user email who initiated merge)`
    - `merge_data:json (metadata about merge)`
  - Add index on `source_contact_id, target_contact_id`
  - Add index on `merged_at` (for sorting)

- [ ] **T4.1.3: Test migrations up and down**
  - Run: `rails db:migrate`
  - Verify columns and tables exist
  - Run: `rails db:rollback`
  - Verify all changes reverted
  - Document rollback procedure

### Phase 2: Deduplication Algorithm
- [ ] **T4.1.4: Implement exact match logic**
  - Function: `find_exact_duplicates(contact)`
  - Match on: email exact, phone exact, email+phone combined
  - Return list of potential merge targets
  - No false positives (exact only)

- [ ] **T4.1.5: Implement fuzzy match logic**
  - Function: `find_fuzzy_duplicates(contact, threshold=0.95)`
  - Match on: name using Levenshtein distance
  - Return list if distance >= threshold
  - Document threshold choice (0.95 = 95% similar)

- [ ] **T4.1.6: Implement merge algorithm**
  - Function: `merge_contacts(source_id, target_id)`
  - Steps:
    1. Get source and target contacts
    2. Move all messages from source → target (UPDATE messages)
    3. Mark source as deleted (is_deleted = true, deleted_at = now)
    4. Create merge log entry
    5. Verify: no data lost (count messages before/after)

- [ ] **T4.1.7: Test deduplication logic**
  - Unit tests for exact match (email, phone)
  - Unit tests for fuzzy match (Levenshtein distance 0.95+)
  - Unit tests for merge (messages consolidated, counts match)
  - Run: `rails test test/models/contact_deduplication_test.rb`

### Phase 3: Backend API
- [ ] **T4.1.8: Implement deduplicate detection endpoint**
  - `POST /api/v1/admin/contacts/deduplicate`
  - Trigger exact + fuzzy duplicate detection
  - Return list of suggested merges
  - Example response: `[{ source: {...}, target: {...}, confidence: "HIGH|MEDIUM|LOW" }]`

- [ ] **T4.1.9: Implement merge execution endpoint**
  - `POST /api/v1/admin/contacts/merge`
  - Payload: `{ source_contact_id, target_contact_id }`
  - Validate: both contacts exist
  - Execute merge (call algorithm)
  - Return: `{ merged: true, contact: { ... } }`
  - Error: 422 if validation fails (e.g., self-merge)

- [ ] **T4.1.10: Implement merge log query endpoint**
  - `GET /api/v1/admin/contacts/merge-logs`
  - Return all merge history (paginated)
  - Include: source, target, merged_at, merged_by
  - Sort: recent first

### Phase 4: Frontend UI
- [ ] **T4.1.11: Create duplicate detection modal**
  - Modal: "Duplicate Contacts Detected"
  - Show list of suggested merges
  - For each: side-by-side preview (source vs target)
  - User selects which contacts to merge

- [ ] **T4.1.12: Create merge confirmation dialog**
  - Show: source and target side-by-side
  - Highlight differences
  - Show: "X messages will be consolidated"
  - Buttons: "Cancel" and "Confirm Merge"
  - After confirm: API call to merge

- [ ] **T4.1.13: Create merge progress indicator**
  - While merging: show progress (messages consolidated, audit trail created)
  - Prevent user action during merge (disable buttons)
  - After success: "Contacts merged" toast
  - After error: "Merge failed" error toast with rollback option

### Phase 5: Data Safety & Backup
- [ ] **T4.1.14: Create backup procedure**
  - Script: `bin/backup_before_merge.sh`
  - Command: `pg_dump chatwoot_prod > backup_contacts_$(date +%Y%m%d_%H%M%S).sql`
  - Verify backup is valid (can restore)
  - Document procedure in runbook

- [ ] **T4.1.15: Create rollback procedure**
  - Script: `bin/rollback_merge.sh`
  - Command: `UPDATE contacts SET is_deleted = false WHERE id IN (...)`
  - Restore messages (already in DB, not deleted)
  - Document procedure in runbook

- [ ] **T4.1.16: Test backup and restore**
  - Create test DB
  - Run backup
  - Restore from backup
  - Verify all data intact
  - Document test results

### Phase 6: Edge Cases & Validation
- [ ] **T4.1.17: Implement self-merge prevention**
  - Validation: prevent merging contact with itself
  - Error: 422 "Cannot merge contact with itself"
  - Test: attempt self-merge, verify error

- [ ] **T4.1.18: Implement duplicate merge prevention**
  - Validation: prevent merging same pair twice
  - Check merge_logs: has this pair already merged?
  - Error: 422 "Contacts already merged"
  - Test: attempt merge twice, verify error on second

- [ ] **T4.1.19: Implement cascade validation**
  - If source was previously merged (is in merge_logs as target), validate chain
  - Prevent circular merges
  - Test: A→B, B→C, attempt C→A, verify error

### Phase 7: Testing
- [ ] **T4.1.20: Unit tests - deduplication**
  - Exact match: email match → detected ✓
  - Exact match: phone match → detected ✓
  - Exact match: no match → not detected ✓
  - Fuzzy match (0.95): "John Smith" vs "Jon Smith" → match ✓
  - Fuzzy match (0.95): "John Smith" vs "Jane Smith" → no match ✓
  - Run: `rails test test/models/contact_deduplication_test.rb`

- [ ] **T4.1.21: Integration tests - merge operation**
  - Merge source→target → all source messages move to target ✓
  - Verify: message count before/after matches
  - Verify: source is_deleted = true
  - Verify: merge_log entry created
  - Verify: rollback restores is_deleted = false
  - Run: `rails test test/integration/contacts_merge_test.rb`

- [ ] **T4.1.22: API contract tests**
  - Test: `POST /api/v1/admin/contacts/deduplicate` returns suggestions
  - Test: `POST /api/v1/admin/contacts/merge` executes merge
  - Test: `GET /api/v1/admin/contacts/merge-logs` returns history
  - Run: `rails test test/controllers/api/contacts_controller_test.rb`

- [ ] **T4.1.23: Manual E2E testing**
  - Create 2 test contacts with same email
  - Run deduplication endpoint
  - Verify: merge suggestion appears
  - Open merge UI
  - Confirm merge
  - Verify: source contact deleted (is_deleted = true)
  - Verify: messages consolidated
  - Verify: merge log entry created
  - Rollback test: restore source, verify data intact

- [ ] **T4.1.24: Data integrity test**
  - Before merge: count messages for each contact
  - Execute merge
  - After merge: count messages in target
  - Verify: target message count = source + target
  - Verify: source is_deleted = true
  - Query source messages: should still return (is_deleted ignored in JOIN)

### Phase 8: Regression Testing
- [ ] **T4.1.25: Full regression test**
  - Run: `rails test && npm test`
  - Ensure no new failures
  - Contacts list loads correctly
  - Conversation detail loads correctly
  - Drag & drop still works

---

## Testing Strategy

### Automated Testing
| Test Type | Tool | Command | Success Criteria |
|-----------|------|---------|------------------|
| Unit Tests | Rails | `rails test test/models/contact_deduplication_test.rb` | All pass |
| Integration | Rails | `rails test test/integration/contacts_merge_test.rb` | All pass |
| API Tests | Rails | `rails test test/controllers/api/contacts_controller_test.rb` | All pass |
| Full Tests | Rails + Jest | `rails test && npm test` | All pass |

### Manual Testing
| Test Case | Steps | Expected Result | Evidence |
|-----------|-------|-----------------|----------|
| **Exact Match Detection** | Create 2 contacts, same email | Merge suggestion appears | Screenshot |
| **Fuzzy Match Detection** | Create "John Smith" + "Jon Smith" | Merge suggestion appears | Screenshot |
| **Merge Confirmation** | Confirm merge in UI | Merge executes, source deleted | Screenshot |
| **Message Consolidation** | Merge, check messages | All messages in target | Query result |
| **Merge Log** | Query merge_logs table | Entry exists with source, target, timestamp | Query result |
| **Rollback Test** | Restore source contact | Data intact, accessible | Query result |
| **Self-Merge Prevent** | Attempt self-merge | Error 422 | API response |
| **Duplicate Merge Prevent** | Merge same pair twice | Error 422 on second | API response |
| **Data Count Verify** | Before/after message count | Counts match, no data lost | Query result |

---

## Development Notes

### Architectural Decisions
1. **Soft Deletes (not hard deletes)**
   - Mark is_deleted = true instead of DELETE
   - Preserves data integrity, enables rollback
   - Queries must include `WHERE is_deleted = false` (or handle in ORM)

2. **Exact + Fuzzy Two-Pass Approach**
   - Exact match first (0 false positives, high precision)
   - Fuzzy match second (catches edge cases)
   - Threshold 0.95 prevents noise (very high precision)

3. **Manual Merge Confirmation**
   - User reviews before merge (prevents accidents)
   - Show side-by-side preview
   - Clear "Confirm" button prevents mis-clicks

4. **Audit Trail for Compliance**
   - contact_merge_logs records WHO merged WHEN
   - Enables rollback investigation
   - Supports compliance/audit requirements

### Implementation Approach
1. Create DB migrations (is_deleted, contact_merge_logs)
2. Implement deduplication algorithms (exact + fuzzy)
3. Implement merge execution (move messages, soft delete)
4. Implement API endpoints (detect, merge, logs)
5. Implement frontend UI (duplicate detection, merge confirmation)
6. Test thoroughly (data integrity critical)
7. Create backup/rollback runbooks

### Files Affected
- `db/migrate/20260504_add_soft_delete_to_contacts.rb` (NEW)
- `db/migrate/20260504_create_contact_merge_logs.rb` (NEW)
- `app/models/Contact.rb` (MODIFY - add scope, methods)
- `app/models/ContactMergeLog.rb` (NEW)
- `app/services/ContactDeduplication.rb` (NEW)
- `app/controllers/api/contacts_controller.rb` (MODIFY - add dedup endpoints)
- `src/components/ContactDeduplicateDialog.vue` (NEW)
- `src/views/ContactsAdmin.vue` (MODIFY - add dedup trigger)
- `tests/models/contact_deduplication_test.rb` (NEW)
- `tests/integration/contacts_merge_test.rb` (NEW)

### Database Changes
```sql
ALTER TABLE contacts ADD COLUMN is_deleted BOOLEAN DEFAULT false;
ALTER TABLE contacts ADD COLUMN deleted_at TIMESTAMP NULL;
CREATE INDEX index_contacts_on_is_deleted ON contacts(is_deleted);
CREATE INDEX index_contacts_on_deleted_at ON contacts(deleted_at);

CREATE TABLE contact_merge_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  source_contact_id BIGINT NOT NULL REFERENCES contacts(id),
  target_contact_id BIGINT NOT NULL REFERENCES contacts(id),
  merged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  merged_by VARCHAR(255),
  merge_data JSON,
  INDEX index_merge_logs_on_source_id (source_contact_id),
  INDEX index_merge_logs_on_target_id (target_contact_id),
  INDEX index_merge_logs_on_merged_at (merged_at)
);
```

**Rollback:**
```sql
DROP TABLE contact_merge_logs;
ALTER TABLE contacts DROP COLUMN is_deleted;
ALTER TABLE contacts DROP COLUMN deleted_at;
DROP INDEX index_contacts_on_is_deleted;
DROP INDEX index_contacts_on_deleted_at;
```

---

## Risk Mitigation

### Risk: Data Loss During Merge
- **Likelihood:** LOW (soft deletes protect)
- **Impact:** CRITICAL - Messages disappear permanently
- **Mitigation:** Soft deletes only, backup before production, test rollback
- **Testing:** Backup/restore test (T4.1.16), data count verification (T4.1.24)

### Risk: Fuzzy Match False Positives
- **Likelihood:** MEDIUM (without threshold validation)
- **Impact:** Wrong contacts merged
- **Mitigation:** Threshold 0.95 (very strict), manual confirmation before merge
- **Testing:** Fuzzy match test with intentionally different names (T4.1.20)

### Risk: Merge Gets Out of Sync with Code
- **Likelihood:** LOW
- **Impact:** Merge logic inconsistent with queries
- **Mitigation:** Centralize merge logic in service, document algorithm
- **Testing:** Algorithm unit tests (T4.1.20)

### Risk: Rollback Doesn't Fully Restore
- **Likelihood:** MEDIUM
- **Impact:** Data partially restored after rollback
- **Mitigation:** Test rollback thoroughly, document procedure
- **Testing:** Rollback test (T4.1.16, manual T4.1.23)

---

## Story Points & Effort

| Estimate | Days | Notes |
|----------|------|-------|
| **Story Points** | 21 | Critical complexity: data integrity paramount |
| **Developer Days** | 7-8 | Algorithm, migrations, API, UI, testing |
| **QA Days** | 2-3 | Data integrity validation critical |
| **Total Calendar Days** | 7-8 | Longest story, last in critical path |

---

## File List

### Files Affected
- `db/migrate/20260504_add_soft_delete_to_contacts.rb` (NEW)
- `db/migrate/20260504_create_contact_merge_logs.rb` (NEW)
- `app/models/Contact.rb` (MODIFY)
- `app/models/ContactMergeLog.rb` (NEW)
- `app/services/ContactDeduplication.rb` (NEW)
- `app/controllers/api/contacts_controller.rb` (MODIFY)
- `src/components/ContactDeduplicateDialog.vue` (NEW)
- `src/views/ContactsAdmin.vue` (MODIFY)
- `tests/models/contact_deduplication_test.rb` (NEW)
- `tests/integration/contacts_merge_test.rb` (NEW)

---

## Development Agent Record

**Assigned to:** @dev (Dex)  
**Status:** Ready for Development (blocked by Waves 1-3)  

### Pre-Development Checklist
- [x] Algorithm documented (exact + fuzzy match)
- [x] Database schema designed
- [x] Backup/rollback procedures defined
- [x] Data integrity testing strategy clear
- [x] **BLOCKED by Waves 1-3** — wait for all prior waves complete

### ⚠️ CRITICAL REQUIREMENTS
- **Soft deletes MANDATORY** (never hard delete)
- **Backup MANDATORY** before first production merge
- **Rollback test MANDATORY** before deployment
- **Data count verification MANDATORY** (before/after message counts match)

---

## QA Results

**QA Gate:** PENDING  
**QA Assigned to:** @qa (Quinn)  

### QA Checklist
- [ ] Exact match detection works (email, phone)
- [ ] Fuzzy match detection works (0.95+ threshold)
- [ ] No false positives (wrong contacts not merged)
- [ ] User must confirm merge (no auto-merge)
- [ ] All messages consolidated (message count matches)
- [ ] Source contact marked is_deleted = true
- [ ] Merge log entry created with timestamp
- [ ] Self-merge prevented (error 422)
- [ ] Duplicate merge prevented (error 422)
- [ ] Rollback restores source (is_deleted = false)
- [ ] Data count verification (before/after match)
- [ ] Backup/restore tested and documented
- [ ] No regressions in other features

**QA Verdict:** PENDING (awaiting @dev implementation)

---

## Change Log

| Date | Author | Change | Status |
|------|--------|--------|--------|
| 2026-05-04 | Aria | Story created from EPIC-001-IMPLEMENTATION-PLAN | CREATED |

---

## Related Stories

- **Depends on:** All Waves 1-3 (S1.1-S3.1)
- **Wave 4:** S4.1 only story
- **Epic:** [EPIC-001-KANBAN](./EPIC-001-KANBAN.md)

---

## Dependencies

- **Blocked by:** Waves 1-3 complete (S1.1, S1.2, S1.3, S2.1, S2.2, S3.1)
- **Blocks:** None (last story)

---

## Critical Path Impact

**S2.1 → S2.2 → S3.1 → S4.1**

This story is last on critical path. Prior delays cascade here.

---

EOF
