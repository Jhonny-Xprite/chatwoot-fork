---
epicId: 2
title: "Contact Import Restoration and Advanced Mapping System"
status: "Ready"
createdAt: "2026-05-02"
createdBy: "Morgan (PM)"
priority: "HIGH"
category: "brownfield-enhancement"
estimatedStories: 3
estimatedEffort: "8-13 story points"
lastUpdated: "2026-05-04"
---

# Epic 2: Contact Import Restoration and Advanced Mapping System

## Epic Goal

Restore and harden CSV contact import by persisting column mapping, validating transformed records, and making phone normalization trustworthy for production use.

**Business Value:** Users regain reliable bulk contact import with mapping control, lower manual cleanup, and clearer failure handling.

---

## Why This Epic Exists

The contact import flow was partially upgraded with advanced mapping support, but the work stopped in an unsafe middle state:

- frontend mapping UI exists
- backend flow expects mapping data
- the database persistence layer was missing
- test coverage and phone normalization are not yet strong enough for confident rollout

This epic closes that gap and turns the feature into an execution-ready stream.

---

## Execution Readiness

This epic is fully decomposed into execution-ready stories with unique IDs:

1. [EPIC-002-S1](../EPIC-002-S1-contact-import-mapping-migration.story.md) - Mapping column migration
2. [EPIC-002-S2](../EPIC-002-S2-contact-import-flow-restoration.story.md) - Restore and test import flow
3. [EPIC-002-S3](../EPIC-002-S3-phone-formatting-whatsapp-validation.story.md) - Phone formatting and WhatsApp validation

Source of truth rules:

- epic priority, scope, and sequencing live in this document
- execution status lives in the story files
- epic-scoped IDs are mandatory to avoid collision with the legacy CRM numbering

---

## Sequencing

| Order | Story | Owner | Status | Notes |
|------|-------|-------|--------|-------|
| 1 | EPIC-002-S1 | @data-engineer | Ready | Required before mapped import can persist data |
| 2 | EPIC-002-S2 | @dev | Ready | Restores and proves the full import path |
| 3 | EPIC-002-S3 | @dev | Ready | Hardens phone normalization and validation |

---

## Success Criteria

- `mapping` persists safely on `data_imports`
- mapped imports work end to end
- failed rows are observable and exportable
- duplicate detection remains reliable
- phone normalization is consistent with Chatwoot expectations
- the feature can be enabled without relying on undocumented tribal knowledge

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| migration lands without workflow validation | High | enforce S1 before S2 but do not stop at schema |
| import flow regresses existing behavior | High | add request and job-level regression coverage |
| phone formatting diverges from existing behavior | Medium | reuse existing Chatwoot helpers where possible |
| team picks the wrong story file due to numbering drift | High | use only EPIC-002-S* story files |

---

## Files in Scope

- `db/migrate/*_add_mapping_to_data_imports.rb`
- `app/models/data_import.rb`
- `app/controllers/api/v1/accounts/contacts_controller.rb`
- `app/jobs/data_import_job.rb`
- `app/services/data_import/contact_manager.rb`
- import-related request, job, and service specs

---

## Epic Status

**Epic Status:** Ready
**Created:** 2026-05-02
**Last Updated:** 2026-05-04
**Owner:** Morgan (PM)
**Stakeholders:** @dev, @data-engineer, @qa, @architect
