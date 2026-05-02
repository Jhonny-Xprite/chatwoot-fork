---
epicId: 2
title: "Contact Import Restoration & Advanced Mapping System"
status: "Draft"
createdAt: "2026-05-02"
createdBy: "Morgan (PM)"
priority: "HIGH"
category: "brownfield-enhancement"
estimatedStories: 3
estimatedEffort: "8-13 story points"
---

# Epic 2: Contact Import Restoration & Advanced Mapping System

## Epic Goal

Restore and enhance the contact CSV import functionality by adding robust column mapping capabilities, ensuring data integrity, and providing users with flexible field mapping during import.

**Business Value:** Enable bulk contact management with user-controlled field mapping, reducing manual data entry and improving data quality through validation.

---

## Executive Summary

The contact import system was upgraded with advanced column mapping features on branch `feat/crm-advanced-filters-automation`, but the migration to persist the mapping data was never created. This epic addresses the missing database schema, implements comprehensive testing, and validates the entire import flow.

**Current State:**
- ✅ Frontend: ContactImportMapper component created (291 lines)
- ✅ Backend: ContactManager refactored to use mapping (data transformation logic)
- ❌ Database: Missing `mapping` column in `data_imports` table
- ❌ Tests: No comprehensive tests for mapping functionality

**Target State:**
- ✅ Database: `mapping` column added (JSON type)
- ✅ Backend: Full import flow with mapping validation and persistence
- ✅ Frontend: Seamless mapping UI with auto-mapping suggestions
- ✅ Tests: Unit, integration, and E2E test coverage
- ✅ Validation: Phone formatting, email validation, identifier deduplication

---

## Epic Description

### Existing System Context

**Current Functionality:**
- Contact model with email, phone_number, name, identifier, and custom attributes
- DataImport model for tracking bulk import operations
- DataImportJob for asynchronous CSV processing
- ContactManager service for business logic

**Technology Stack:**
- Backend: Rails 7.0, PostgreSQL
- Frontend: Vue 3, Composition API
- Job Queue: Sidekiq/ActiveJob
- File Storage: ActiveStorage

**Integration Points:**
- API: POST `/api/v1/accounts/contacts/import`
- UI: Contacts module → Import dialog → Mapping mapper
- Database: `contacts`, `data_imports`, `active_storage_attachments`

### Enhancement Details

**What's Being Added:**
1. **Database Migration** — Add `mapping` JSON column to `data_imports`
2. **Import Validation** — Enforce mapping presence and structure validation
3. **CSV Parsing** — Enhanced column normalization and data transformation
4. **Phone Formatting** — WhatsApp-compatible phone number formatting
5. **Error Reporting** — Comprehensive failed records CSV export
6. **Test Coverage** — Unit, integration, and E2E tests

**How It Integrates:**
- Frontend sends CSV file + column mapping to backend
- Backend validates mapping and creates DataImport record with mapping data
- Job processes CSV with mapping to transform columns
- Phone numbers formatted to E.164 format
- Email addresses validated and deduplicated
- Failed records saved to CSV for user review

**Success Criteria:**
- [ ] Migration creates `mapping` column successfully
- [ ] Import accepts CSV with valid mapping
- [ ] All CSV rows are processed (valid + rejected tracked)
- [ ] Phone numbers formatted to E.164
- [ ] Duplicate detection works (email, phone, identifier)
- [ ] Failed records export includes error reasons
- [ ] User notification emails sent on completion
- [ ] All tests pass (unit, integration, E2E)

---

## Stories with Quality Gates

### Story 1: Add `mapping` Column Migration

**Description:**
Create and execute database migration to add JSON column for storing column mappings in `data_imports` table.

**Executor Assignment:** `@data-engineer`  
**Quality Gate:** `@dev`  
**Quality Gate Tools:** `[schema_validation, migration_review, rls_test]`

**Acceptance Criteria:**
- [ ] Migration file created: `20260502_add_mapping_to_data_imports.rb`
- [ ] Column added as JSON type with default `{}`
- [ ] Migration runs without errors on PostgreSQL
- [ ] Schema.rb updated with new column
- [ ] No existing data is affected (backwards compatible)
- [ ] Rollback tested and verified

**Quality Gates:**
- Pre-Commit: Schema validation, migration syntax check
- Pre-PR: Database compatibility check, index verification

**Risks & Mitigation:**
- Risk: Migration fails on existing databases
- Mitigation: Test on staging environment, provide rollback procedure

**Focus Areas:**
- Column type: JSON (native PostgreSQL support)
- Default value: `{}` (empty hash for backwards compatibility)
- Idempotent: Handle if column already exists

---

### Story 2: Restore & Test Contact Import Flow

**Description:**
Implement comprehensive testing and validation of the complete CSV import flow with column mapping, including validation, error handling, and notification system.

**Executor Assignment:** `@dev`  
**Quality Gate:** `@qa`  
**Quality Gate Tools:** `[code_review, test_coverage, integration_test, security_scan]`

**Acceptance Criteria:**
- [ ] Unit tests for `ContactManager` with mapping scenarios
- [ ] Unit tests for `DataImportJob` with CSV parsing
- [ ] Integration test: Full import flow (upload → process → create contacts)
- [ ] Integration test: Failed records export
- [ ] Integration test: Duplicate detection (email, phone, identifier)
- [ ] Integration test: Phone number formatting
- [ ] E2E test: UI → API → Database flow
- [ ] All tests pass with coverage > 80%
- [ ] No regressions in existing import functionality

**Quality Gates:**
- Pre-Commit: CodeRabbit review (code patterns, security)
- Pre-PR: Test coverage check, integration test results
- Pre-Deployment: E2E test results

**Test Scenarios:**
1. Valid CSV with all columns mapped
2. CSV with missing required fields (email/phone)
3. CSV with invalid phone numbers (should handle gracefully)
4. CSV with duplicate emails (merge logic)
5. CSV with invalid email format (reject with error)
6. Large file (1000+ rows) performance test
7. Mapping with empty columns (should skip)
8. Phone number variations (with/without +, different formats)

**Risks & Mitigation:**
- Risk: Tests expose other bugs in import logic
- Mitigation: Log all issues, prioritize CRITICAL/HIGH for immediate fix
- Risk: Performance issues with large files
- Mitigation: Batch processing, monitor job queue

---

### Story 3: Enhanced Phone Formatting & WhatsApp Validation

**Description:**
Implement robust phone number formatting to E.164 standard and WhatsApp-compatible validation, including support for Brazilian numbers and international formats.

**Executor Assignment:** `@dev`  
**Quality Gate:** `@architect`  
**Quality Gate Tools:** `[code_review, pattern_validation, security_scan]`

**Acceptance Criteria:**
- [ ] Phone formatter handles multiple formats (with/without country code)
- [ ] Support for Brazilian phone numbers (Chatwoot standard)
- [ ] E.164 format output: `+[country code][number]`
- [ ] Invalid phones rejected with clear error message
- [ ] Phone field is optional (contacts can be created with email only)
- [ ] Duplicate detection by phone works across accounts
- [ ] Handles edge cases (spaces, parentheses, dashes)
- [ ] Error messages include the invalid phone value for debugging

**Quality Gates:**
- Pre-Commit: Security scan (no hardcoded test numbers)
- Pre-PR: Pattern validation (alignment with existing formatter)

**Phone Format Examples:**
- Input: `11987654321` (Brazilian) → Output: `+5511987654321`
- Input: `+55 11 9 8765-4321` → Output: `+5511987654321`
- Input: `+1 (555) 123-4567` → Output: `+15551234567`
- Input: `invalid123` → Rejected with error message

**Risks & Mitigation:**
- Risk: Breaking change in phone formatting
- Mitigation: Comprehensive test coverage, feature flag for rollout
- Risk: International formats not fully supported
- Mitigation: Log unsupported formats, allow override in mapping

**Focus Areas:**
- Reuse existing Chatwoot formatters if available
- Support Brazilian WhatsApp numbers (primary use case)
- Clear error messages for invalid formats
- Performance (no external API calls for validation)

---

## Compatibility Requirements

- [ ] Existing import API remains unchanged
- [ ] Backwards compatible: imports without mapping still work (with limitations)
- [ ] Database schema changes are backward compatible (no data loss)
- [ ] UI changes follow existing Chatwoot patterns
- [ ] Performance: Import job processes 1000 rows in < 5 minutes
- [ ] Memory usage: Job doesn't consume > 500MB for large files

---

## Risk Mitigation

### Primary Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Migration fails on existing databases | HIGH | Test on staging first, provide rollback |
| Import breaks for existing users | HIGH | Feature flag for new mapping validation |
| Performance degradation with large files | MEDIUM | Batch processing, job monitoring |
| Phone formatting breaks existing numbers | MEDIUM | Comprehensive test coverage, gradual rollout |
| Data loss during mapping transformation | HIGH | Transaction protection, backup before processing |

### Quality Assurance Strategy

**CodeRabbit Validation:**
- All stories include pre-commit reviews
- Database story: Schema validation, migration safety
- Workflow story: Code patterns, test coverage
- Phone formatting: Security scan, regex validation

**Specialized Expertise:**
- @data-engineer reviews database migration
- @architect reviews phone formatting patterns
- @dev implements comprehensive tests
- @qa validates full import flow

**Quality Gates:**
- LOW RISK (migration): Pre-Commit only
- MEDIUM RISK (restore flow): Pre-Commit + Pre-PR
- HIGH RISK (phone formatting): Pre-Commit + Pre-PR + @architect review

**Regression Prevention:**
- Each story includes tasks to verify existing functionality
- Integration tests validate import compatibility
- Performance tests prevent degradation
- Feature flags enable safe rollout

### Rollback Plan

**If issues detected after deployment:**

1. **Immediate Actions:**
   - Disable import feature flag
   - Roll back database migration (if needed)
   - Verify existing contacts unaffected

2. **Communication:**
   - Notify admins of import service unavailability
   - Provide ETA for fix

3. **Recovery:**
   - Address identified issues
   - Re-deploy with feature flag enabled
   - Validate on staging first

---

## Implementation Approach

### Wave 1: Foundation (Week 1)
- Story 1: Database migration
- Setup test environment
- Establish baseline for Phone formatting

### Wave 2: Core Functionality (Week 2)
- Story 2: Import flow restoration & tests
- Story 3: Phone formatting & validation
- Integration testing

### Wave 3: Validation & Deployment (Week 3)
- E2E testing
- Performance testing
- Staging deployment
- Production deployment with monitoring

---

## Success Metrics

**Technical:**
- All tests passing (unit, integration, E2E)
- Code coverage > 80%
- No CRITICAL/HIGH CodeRabbit issues
- Import job completes in < 5 minutes for 1000 rows

**Business:**
- Users can import 100+ contacts via CSV
- 95%+ successful import rate for valid data
- Clear error messages for invalid data
- Admin notifications on completion

**User Experience:**
- Mapping UI is intuitive
- Error reporting is comprehensive
- Failed records export is usable
- Import process is fast and reliable

---

## Dependencies & Prerequisites

**Existing Artifacts:**
- ContactImportDialog.vue (created)
- ContactImportMapper.vue (created)
- ContactManager service (modified)
- DataImportJob (modified)

**Missing (To Be Created):**
- Database migration file
- Comprehensive test suite
- Phone formatting utilities

**External Dependencies:**
- PostgreSQL (JSON support)
- ActiveStorage (file handling)
- Sidekiq (job processing)

---

## Notes

- This epic assumes the advanced mapping feature was intentionally added and the migration was forgotten
- Phone formatting follows Chatwoot's Brazil-first approach
- All dates/times are in user's timezone for clarity
- Feature will be behind feature flag during initial rollout

---

## File List

| File | Status | Comments |
|------|--------|----------|
| `db/migrate/20260502_add_mapping_to_data_imports.rb` | To Create | Migration file |
| `app/controllers/api/v1/accounts/contacts_controller.rb` | Modify | Import action already updated |
| `app/models/data_import.rb` | Verify | `serialize :mapping, JSON` already in place |
| `app/jobs/data_import_job.rb` | Verify | Job logic already updated |
| `app/services/data_import/contact_manager.rb` | Verify | Service already refactored |
| `spec/services/data_import/contact_manager_spec.rb` | To Create | Unit tests |
| `spec/jobs/data_import_job_spec.rb` | To Create | Job tests |
| `spec/requests/api/v1/accounts/contacts/import_spec.rb` | To Create | Integration tests |

---

**Epic Status:** Draft  
**Created:** 2026-05-02  
**Last Updated:** 2026-05-02  
**Owner:** Morgan (PM)  
**Stakeholders:** @dev, @data-engineer, @qa, @architect
