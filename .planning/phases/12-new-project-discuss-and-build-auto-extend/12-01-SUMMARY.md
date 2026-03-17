---
phase: 12
plan: 01
completed: 2026-03-17
key_files:
  created: []
  modified:
    - plugins/claude-super-team/skills/new-project/SKILL.md
    - plugins/claude-super-team/skills/new-project/references/questioning-methodology.md
    - plugins/claude-super-team/skills/build/gather-data.sh
    - plugins/claude-super-team/skills/build/SKILL.md
    - plugins/claude-super-team/skills/build/references/sprint-execution-guide.md
decisions: []
deviations: []
---

# Phase 12 Plan 01: Add /new-project --discuss mode and /build auto-extend detection Summary

Added interactive discussion mode to /new-project via --discuss flag (Path C with progressive domain/problem/users narrowing) and 5-way branching to /build for auto-detecting existing project state (auto-extend for PROJECT.md+ROADMAP.md, partial-project for PROJECT.md only).

## Tasks Completed

| # | Task | Commit | Files | Status |
|---|------|--------|-------|--------|
| 1 | Add --discuss mode to /new-project SKILL.md and questioning-methodology.md | 89b6435 | new-project/SKILL.md, questioning-methodology.md | complete |
| 2 | Update /build gather-data.sh and SKILL.md branching for auto-extend | 9079111 | build/gather-data.sh, build/SKILL.md | complete |
| 3 | Update sprint-execution-guide.md Step 8-E for auto-extend context | b81cb00 | sprint-execution-guide.md | complete |

## What Was Built

- **/new-project --discuss mode (Path C):** New flag detection before empty-arguments exit. Path C starts with a domain selection AskUserQuestion, then progressively narrows via problem/users/success/constraints questions using existing methodology techniques. Flows into the same Phase 3.5/Phase 4 as Paths A and B.
- **questioning-methodology.md Path C section:** Documents the progressive narrowing pattern (domain -> problem -> users -> solution shape -> success criteria) with example AskUserQuestion sequences.
- **/build auto-extend detection:** gather-data.sh now emits AUTO_EXTEND (PROJECT.md + ROADMAP.md present, no BUILD-STATE.md) and PARTIAL_PROJECT (PROJECT.md only, no ROADMAP.md or BUILD-STATE.md) signals. SKILL.md Step 1 has 5-way branching: Resume, Extend, Auto-Extend, Partial Project, Fresh Start.
- **sprint-execution-guide.md:** Step 8-E now documents that it serves both Branch 2 (traditional extend) and Branch 2a (auto-extend), noting PHASE_COMPLETION is filesystem-derived.

## Deviations From Plan

None

## Decisions Made

None

## Issues / Blockers

None
