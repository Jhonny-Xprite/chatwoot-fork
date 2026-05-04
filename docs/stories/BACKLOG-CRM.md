# Product Backlog Overview

> Last updated: 2026-05-04
> Purpose: portfolio index only. Detailed status lives in the linked epic and story files.

---

## Working Agreement

- This file is a summary, not the source of truth for execution status.
- One story ID maps to one story file only.
- Epic-level priority and sequence live in the epic document.
- Story-level execution status lives in the story document.

---

## Active Epics

| Epic | Status | Priority | Next action | Source of truth |
|------|--------|----------|-------------|-----------------|
| EPIC-001 | In Progress | Critical | QA S2.1 and finish S2.2 | [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md) |
| EPIC-002 | Ready for Execution | High | Start S1 migration work | [EPIC-2.contact-import-restoration](epics/EPIC-2.contact-import-restoration.md) |

---

## Active Bug Stream

| Bug | Status | Priority | Next action | Source of truth |
|-----|--------|----------|-------------|-----------------|
| BUG-001 | Draft / Triage complete | Critical | Refine S1-S4 and execute dashboard filter fix first | [BUG-001-filter-overlay-regressions](BUG-001-filter-overlay-regressions.md) |

Bug story source of truth:
- [BUG-001-S1](BUG-001-S1-dashboard-conversation-filter-focus-layering.md)
- [BUG-001-S2](BUG-001-S2-shared-dropdown-accessibility-positioning.md)
- [BUG-001-S3](BUG-001-S3-crm-pipeline-filter-overlay-fix.md)
- [BUG-001-S4](BUG-001-S4-z-index-normalization-audit.md)
- [BUG-001-S5](BUG-001-S5-dashboard-quick-menu-submenu-hardening.md)
- [BUG-001-S6](BUG-001-S6-crm-inline-selector-menu-hardening.md)
- [BUG-001-S7](BUG-001-S7-crm-board-drag-layer-conflict.md)

---

## EPIC-001 Snapshot

- Wave 1: S1.1 and S1.2 done, S1.3 partially complete with filter integration still tracked in S2.2.
- Wave 2: S2.1 ready for QA, S2.2 in progress.
- Wave 3: S3.1 ready for development after Wave 2 closes.
- Wave 4: S4.1 ready for development after Wave 3 closes.

Story source of truth:
- [EPIC-001-S1.1](EPIC-001-S1.1.md)
- [EPIC-001-S1.2](EPIC-001-S1.2.md)
- [EPIC-001-S1.3](EPIC-001-S1.3.md)
- [EPIC-001-S2.1](EPIC-001-S2.1.md)
- [EPIC-001-S2.2](EPIC-001-S2.2.md)
- [EPIC-001-S3.1](EPIC-001-S3.1.md)
- [EPIC-001-S4.1](EPIC-001-S4.1.md)

---

## EPIC-002 Snapshot

- Epic decomposed into 3 execution-ready stories.
- All stories now use epic-scoped IDs with no collision against the legacy CRM track.
- Epic can move into execution starting with the migration story.

Story source of truth:
- [EPIC-002-S1](EPIC-002-S1-contact-import-mapping-migration.story.md)
- [EPIC-002-S2](EPIC-002-S2-contact-import-flow-restoration.story.md)
- [EPIC-002-S3](EPIC-002-S3-phone-formatting-whatsapp-validation.story.md)

---

## Completed Foundation Stories

- [1.1 - CRM Database Infrastructure](1.1-db-infrastructure.story.md)
- [1.2 - CRM Models and API Endpoints](1.2-crm-models-api.story.md)
- [2.1 - Kanban Board and Frontend Foundation](2.1-kanban-board.story.md)
- [2.2 - Advanced Filters and Automation](2.2-advanced-filters-automation.story.md)

---

## Naming Convention

- Legacy CRM stories keep their existing delivery filenames for traceability.
- New epic-managed stories use epic-scoped IDs in both file name and document body.
- Avoid reusing numeric IDs like `2.1` across unrelated epics.
