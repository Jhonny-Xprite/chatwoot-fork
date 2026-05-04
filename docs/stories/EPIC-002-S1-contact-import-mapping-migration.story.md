---
storyId: EPIC-002-S1
epicId: 2
title: "Add Mapping Column Migration - Contact Import Database Schema"
status: "Ready"
priority: "HIGH"
complexity: "LOW"
estimatedPoints: 2
createdAt: "2026-05-04"
createdBy: "River (SM)"
assignedTo: "@data-engineer"
qualityGate: "@dev"
qualityGateTools: [schema_validation, migration_review, rls_test]
---

# Story EPIC-002-S1: Add `mapping` Column Migration

## Story Goal

Add a JSON column to `data_imports` so user-defined mapping data is persisted during CSV contact import.

**Why:** The import flow already expects mapping data. Without schema support, the feature cannot reliably persist or consume the mapping payload.

---

## Story Description

### Problem Statement

The import flow currently has a schema gap:

1. frontend sends mapping data
2. backend attempts to save mapping data
3. `data_imports` does not yet persist that mapping field
4. the downstream job cannot trust the payload it receives

### Scope

- create the migration
- validate rollback safety
- confirm schema compatibility
- do not expand into workflow testing beyond what is needed to prove the migration is safe

---

## Acceptance Criteria

- [ ] Migration file created for adding `mapping` to `data_imports`
- [ ] Column uses JSON with default `{}`
- [ ] Migration is reversible
- [ ] Schema update is backward compatible
- [ ] No existing `data_imports` records are corrupted or blocked
- [ ] Story is ready to hand off to EPIC-002-S2 after schema validation

---

## Quality Gates

**Executor:** `@data-engineer`
**Quality Gate:** `@dev`

- [ ] schema validation
- [ ] migration review
- [ ] rollback verification

---

## File List

| File | Change Type | Status |
|------|------------|--------|
| `db/migrate/*_add_mapping_to_data_imports.rb` | Create | Planned |
| `db/schema.rb` | Auto-update | Planned |
| `app/models/data_import.rb` | Verify | Planned |

---

## Related Stories

- **EPIC-002-S2:** Restore and test contact import flow
- **EPIC-002-S3:** Phone formatting and WhatsApp validation

---

## Completion Checklist

- [ ] Migration created
- [ ] Migration runs locally
- [ ] Rollback runs locally
- [ ] Schema reviewed
- [ ] Story status updated for handoff

---

**Story Status:** Ready
**Created:** 2026-05-04
**Last Updated:** 2026-05-04
**Owner:** River (SM)
**Executor:** @data-engineer
**Quality Gate:** @dev
