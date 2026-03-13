---
phase: 04
plan: 01
completed: 2026-03-12
key_files:
  created:
    - plugins/claude-super-team/scripts/phase-utils.sh
  modified:
    - plugins/claude-super-team/skills/discuss-phase/SKILL.md
    - plugins/claude-super-team/skills/execute-phase/SKILL.md
    - plugins/claude-super-team/skills/plan-phase/SKILL.md
    - plugins/claude-super-team/skills/research-phase/SKILL.md
    - plugins/claude-super-team/skills/phase-feedback/SKILL.md
    - plugins/claude-super-team/skills/plan-phase-workspace/skill-snapshot/SKILL.md
decisions: []
deviations: []
---

# Phase 04 Plan 01: Centralize Phase Number Normalization

Shared `phase-utils.sh` script with `normalize_phase()` and `find_phase_dir()` functions, replacing duplicated inline normalization code across 6 skills.

## Tasks Completed

| # | Task | Commit | Files | Status |
|---|------|--------|-------|--------|
| 1 | Create phase-utils.sh | 50af348 | scripts/phase-utils.sh | complete |
| 2 | Replace inline normalization in 6 skills | cbf3e71 | 6 SKILL.md files | complete |

## What Was Built

- `plugins/claude-super-team/scripts/phase-utils.sh`: Shared bash utility with two functions:
  - `normalize_phase()`: Zero-pads phase numbers (2->02, 2.1->02.1, 10->10, 2.10->02.10)
  - `find_phase_dir()`: Resolves phase number to `.planning/phases/{NN}-{name}/` directory
- 6 skills now source phase-utils.sh instead of inline normalization: discuss-phase, execute-phase, plan-phase, research-phase, phase-feedback, plan-phase-workspace/skill-snapshot
- Net: 14 insertions, 38 deletions (24 lines of duplicated code eliminated)

## Deviations From Plan

None

## Decisions Made

None

## Issues / Blockers

None
