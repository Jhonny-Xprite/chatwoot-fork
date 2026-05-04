---
storyId: EPIC-002-S3
epicId: 2
title: "Phone Formatting and WhatsApp Validation"
status: "Ready"
priority: "HIGH"
complexity: "MEDIUM"
estimatedPoints: 3
createdAt: "2026-05-04"
createdBy: "River (SM)"
assignedTo: "@dev"
qualityGate: "@architect"
qualityGateTools: [code_review, pattern_validation, security_scan]
---

# Story EPIC-002-S3: Phone Formatting and WhatsApp Validation

## Story Goal

Normalize imported phone values into a Chatwoot-compatible format and reject invalid values with clear feedback.

**Why:** Imported contacts are only reliable if phone data is normalized consistently and duplicate detection can compare stable values.

---

## Story Description

### Problem Statement

Imported phone values arrive in inconsistent formats:

- local Brazilian numbers without country code
- international numbers with punctuation
- malformed free-form strings

Without normalization and validation, duplicate detection and downstream channel usage become unreliable.

### Dependencies

- This story follows EPIC-002-S2 because it hardens the import path after the workflow is restored.

---

## Acceptance Criteria

- [ ] Supported phone inputs normalize to E.164 where appropriate
- [ ] Brazilian numbers are handled as the primary use case
- [ ] Punctuation and spacing are normalized
- [ ] Invalid values are rejected with a clear reason
- [ ] Email-only imports still work when phone is absent
- [ ] Duplicate detection can rely on normalized phone values
- [ ] Automated tests cover valid and invalid examples

---

## Quality Gates

**Executor:** `@dev`
**Quality Gate:** `@architect`

- [ ] code review
- [ ] alignment with existing Chatwoot formatting patterns
- [ ] security scan

---

## File List

| File | Change Type | Status |
|------|------------|--------|
| `app/services/data_import/contact_manager.rb` | Modify | Planned |
| `spec/services/data_import/contact_manager_spec.rb` | Create or Update | Planned |
| `spec/requests/api/v1/accounts/contacts/import_spec.rb` | Update | Planned |

---

## Related Stories

- **EPIC-002-S1:** Mapping column migration
- **EPIC-002-S2:** Restore and test contact import flow

---

## Completion Checklist

- [ ] Formatting behavior implemented
- [ ] Validation behavior implemented
- [ ] Tests added for common and edge cases
- [ ] Story status updated for architecture review

---

**Story Status:** Ready
**Created:** 2026-05-04
**Last Updated:** 2026-05-04
**Owner:** River (SM)
**Executor:** @dev
**Quality Gate:** @architect
