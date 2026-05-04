---
storyId: EPIC-002-S2
epicId: 2
title: "Restore and Test Contact Import Flow"
status: "Ready"
priority: "HIGH"
complexity: "MEDIUM"
estimatedPoints: 5
createdAt: "2026-05-04"
createdBy: "River (SM)"
assignedTo: "@dev"
qualityGate: "@qa"
qualityGateTools: [code_review, test_coverage, integration_test, security_scan]
---

# Story EPIC-002-S2: Restore and Test Contact Import Flow

## Story Goal

Restore the full CSV import workflow with mapping, validation, failed-row handling, and regression coverage so the feature is safe to execute in production.

**Why:** The feature is partially implemented but not yet proven end to end. Without automated coverage and workflow validation, the team cannot trust the import path.

---

## Story Description

### Problem Statement

The import feature currently has workflow risk:

- mapping UI exists
- backend transformation exists
- schema support must land first
- there is no reliable automated proof that upload, processing, persistence, and failure handling work together

### Dependencies

- EPIC-002-S1 must land before this story starts execution.

---

## Acceptance Criteria

- [ ] Valid CSV plus valid mapping imports successfully
- [ ] Mapping is available to the job processor
- [ ] Invalid rows fail without aborting the whole import
- [ ] Failed rows can be exported with clear reasons
- [ ] Duplicate handling is covered for email, phone, and identifier
- [ ] Legacy import behavior is not regressed
- [ ] Request, job, and service coverage exists for the critical path

---

## Quality Gates

**Executor:** `@dev`
**Quality Gate:** `@qa`

- [ ] code review
- [ ] integration test coverage
- [ ] regression validation
- [ ] security scan of the import flow

---

## File List

| File | Change Type | Status |
|------|------------|--------|
| `spec/services/data_import/contact_manager_spec.rb` | Create or Update | Planned |
| `spec/jobs/data_import_job_spec.rb` | Create or Update | Planned |
| `spec/requests/api/v1/accounts/contacts/import_spec.rb` | Create or Update | Planned |
| `app/jobs/data_import_job.rb` | Verify or Modify | Planned |
| `app/services/data_import/contact_manager.rb` | Verify or Modify | Planned |
| `app/controllers/api/v1/accounts/contacts_controller.rb` | Verify or Modify | Planned |

---

## Related Stories

- **EPIC-002-S1:** Mapping column migration
- **EPIC-002-S3:** Phone formatting and WhatsApp validation

---

## Completion Checklist

- [ ] Full import happy path verified
- [ ] Failure export verified
- [ ] Regression suite updated
- [ ] Story status updated for QA handoff

---

**Story Status:** Ready
**Created:** 2026-05-04
**Last Updated:** 2026-05-04
**Owner:** River (SM)
**Executor:** @dev
**Quality Gate:** @qa
