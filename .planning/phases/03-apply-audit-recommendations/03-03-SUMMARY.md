---
phase: 03
plan: 03
completed: 2026-02-12
key_files:
  created: []
  modified:
    - plugins/marketplace-utils/skills/marketplace-manager/SKILL.md
    - plugins/task-management/skills/linear-sync/SKILL.md
    - plugins/task-management/skills/github-issue-manager/SKILL.md
    - plugins/claude-super-team/agents/phase-researcher.md
decisions: []
deviations: []
---

# Phase 03 Plan 03: Cross-Plugin and Agent Fixes Summary

Fix cross-plugin skills (marketplace-manager, linear-sync, github-issue-manager) and add safety limits to the phase-researcher agent.

## Tasks Completed

| # | Task | Commit | Files | Status |
|---|------|--------|-------|--------|
| 1 | Fix marketplace-manager, linear-sync, and github-issue-manager | 9cd4925 | marketplace-manager/SKILL.md, linear-sync/SKILL.md, github-issue-manager/SKILL.md | complete |
| 2 | Update phase-researcher agent with safety limits and memory | 96c00d8 | phase-researcher.md | complete |

## What Was Built

Closed the two most critical audit gaps and applied model/argument-hint fixes:

- **marketplace-manager**: Added `allowed-tools` with 8 specific tool entries (was completely unrestricted -- the highest priority fix in the audit). Added `argument-hint` for subcommand routing.
- **linear-sync**: Added `Skill` to `allowed-tools`, fixing a functional bug where the skill could not delegate to `linear-cli`.
- **github-issue-manager**: Downgraded model from `sonnet` to `haiku` (appropriate for the task complexity). Added `argument-hint` for subcommand routing.
- **phase-researcher agent**: Added `maxTurns: 40` safety limit to prevent runaway research spirals. Added `memory: project` for cross-session learning of research patterns and reliable sources.

## Deviations From Plan

None.

## Decisions Made

None -- all changes were prescribed by the plan.

## Issues / Blockers

None.
