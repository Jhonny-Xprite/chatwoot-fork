# EPIC-001: Kanban and Chat Platform Refinements

**Status:** Wave 2 Complete - Ready for Wave 3
**Priority:** Critical
**Created:** 2026-05-04
**Owner:** Morgan (PM)
**Target Release:** Sprint TBD

---

## Purpose

Improve the Kanban and conversation experience by resolving readability issues, unlocking filter usability, and sequencing the remaining interaction and data-integrity work behind a clean execution plan.

---

## Source of Truth

- Epic-level priority, sequencing, and release framing live here.
- Story-level execution state lives in the linked story files.
- This epic intentionally treats the detailed story files as the operational source of truth.

---

## Current Snapshot

### Wave 1

- S1.1: Done
- S1.2: Done
- S1.3: In Progress
  Core unread and pin work is in place, but filter-related integration is still tied to S2.2.

### Wave 2

- S2.1: Done ✅
- S2.2: Done ✅

### Wave 3

- S3.1: Done ✅
  Drag & drop implementation complete with 200ms delay, visual feedback, 60 FPS optimization

### Wave 4

- S4.1: Ready
  Sequenced after Wave 3.

---

## Objectives

- [x] Make the interface readable with acceptable contrast.
- [ ] Finish filter usability and stage filtering.
- [ ] Deliver intuitive drag and drop for Kanban movement.
- [ ] Eliminate duplicate cards caused by channel fragmentation.
- [x] Add unread and pinning affordances for agents.

---

## Story Map

| Story | Title | Status | Notes |
|------|-------|--------|-------|
| [EPIC-001-S1.1](../stories/EPIC-001-S1.1.md) | Fix chat link colors | Done | WCAG-focused readability fix |
| [EPIC-001-S1.2](../stories/EPIC-001-S1.2.md) | Fix conversation detail colors | Done | Contrast and sender readability |
| [EPIC-001-S1.3](../stories/EPIC-001-S1.3.md) | Add unread and pinning | In Progress | Filter integration still tracked in S2.2 |
| [EPIC-001-S2.1](../stories/EPIC-001-S2.1.md) | Fix filter z-index | In Review / Ready for QA | Immediate blocker for dropdown usability |
| [EPIC-001-S2.2](../stories/EPIC-001-S2.2.md) | Add status filter | In Progress | Depends on S2.1 quality closeout |
| [EPIC-001-S3.1](../stories/EPIC-001-S3.1.md) | Drag and drop Kanban | Ready | Queue after Wave 2 |
| [EPIC-001-S4.1](../stories/EPIC-001-S4.1.md) | Deduplicate contacts and cards | Ready | Queue after Wave 3 |

---

## Sequencing Rules

1. Close S2.1 QA before treating filter work as complete.
2. Finish S2.2 before starting S3.1.
3. Start S4.1 only after drag and drop stabilizes.
4. Keep one story per PR to preserve rollback clarity.

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Filter work reported complete before QA closure | High | Treat S2.1 as blocking until QA signs off |
| S1.3 reported done while filter integration is still open | Medium | Keep S1.3 in progress until dependency is closed |
| Drag and drop started before Wave 2 is stable | High | Enforce wave gate between Wave 2 and Wave 3 |
| Deduplication launched without UX stability | High | Sequence only after interaction layer settles |

---

## Success Metrics

- Filter controls are reliably accessible in supported viewports.
- Kanban status filtering works without reload.
- Conversation readability meets accessibility expectations.
- Duplicate-card handling has an explicit execution lane and is not mixed into active UI stabilization.

---

## Related Documents

- [System Architecture](../architecture/system-architecture.md)
- [Frontend Spec](../frontend/FRONTEND-SPEC.md)
- [Epic 001 Specification](../specs/EPIC-001-SPECIFICATION.md)

---

## Sign-off

- [ ] PM approved
- [ ] Tech lead approved
- [ ] PO sign-off
- [ ] Ready to execute next queued story
