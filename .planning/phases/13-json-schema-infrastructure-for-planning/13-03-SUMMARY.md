---
phase: 13
plan: 03
completed: 2026-03-27
key_files:
  created: []
  modified:
    - plugins/claude-super-team/skills/new-project/SKILL.md
    - plugins/claude-super-team/skills/new-project/references/project-writing-guide.md
    - plugins/claude-super-team/skills/create-roadmap/SKILL.md
    - plugins/claude-super-team/skills/create-roadmap/assets/roadmap.md
    - plugins/claude-super-team/skills/create-roadmap/assets/state.md
    - plugins/claude-super-team/skills/brainstorm/SKILL.md
    - plugins/claude-super-team/skills/cst-help/SKILL.md
    - plugins/claude-super-team/skills/cst-help/references/workflow-guide.md
    - plugins/claude-super-team/skills/cst-help/references/troubleshooting.md
decisions:
  - JSON schemas use kebab-case keys matching existing MD conventions
  - Skills construct JSON inline (no json-sync.sh calls from skills)
  - Migrate action uses AskUserQuestion for confirmation before running json-sync.sh
deviations: []
---

# Phase 13 Plan 03: Skill Dual-Write + cst-help Migrate Summary

Updated 3 core skills (new-project, create-roadmap, brainstorm) to dual-write MD+JSON companions and added a migrate action to /cst-help for bulk JSON regeneration from MD sources.

## Tasks Completed
| # | Task | Commit | Files | Status |
|---|------|--------|-------|--------|
| 1 | Update /new-project, /create-roadmap, /brainstorm SKILL.md for dual MD+JSON output | 1a1094d | 6 | Done |
| 2 | Add /cst-help migrate action and update references | 8e2eafa | 3 | Done |

## What Was Built
- **new-project Phase 4.5**: Inline PROJECT.json construction after PROJECT.md write, with schema template
- **create-roadmap Phase 6.5**: Inline ROADMAP.json + STATE.json construction after Phase 6 writes, with schema templates
- **brainstorm Phase 10.5**: Inline IDEAS.json construction after Phase 10 write, with schema template and append support
- **Template assets**: JSON companion comments added to roadmap.md and state.md templates
- **project-writing-guide.md**: Updated commit instructions and completion messages for PROJECT.json
- **/cst-help migrate action**: Full migrate workflow with prerequisites check, state display, confirmation, json-sync.sh execution, and commit instructions
- **cst-help Phase 1**: New routing case for "migrate" argument
- **cst-help Phase 2**: JSON file existence checks (PROJECT.json, ROADMAP.json, STATE.json, IDEAS.json)
- **workflow-guide.md**: JSON Data Layer section, file structure with JSON files, pipeline notes, maintenance best practice
- **troubleshooting.md**: JSON Layer section (4 issues: sync, script missing, corruption, commit), diagnostic commands, "When to Use" update

## Deviations From Plan
None

## Decisions Made
- Used kebab-case keys in all JSON schemas consistently
- Skills build JSON inline -- never call json-sync.sh (as per must_haves)
- Migrate confirmation uses AskUserQuestion before executing
- Added JSON existence checks to Phase 2 state detection for project-specific guidance

## Issues / Blockers
None
