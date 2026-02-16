# Changelog

All notable changes to the claude-super-team marketplace are documented in this file.

## [1.0.16] - 2026-02-16

### claude-super-team
- Added `/code` skill for interactive coding sessions with project context
- Two modes: phase-linked (loads phase artifacts, creates REFINEMENT.md) and free-form (project awareness only)
- Session logs tracked in `.planning/.sessions/` (gitignored)
- Moved data gathering to dynamic context injection across 5 skills: `/create-roadmap`, `/discuss-phase`, `/execute-phase`, `/phase-feedback`, `/plan-phase` -- each now uses a `gather-data.sh` script instead of inline Bash checks
- `/execute-phase` now auto-marks phases complete in ROADMAP.md (checks off Phases checklist, updates Progress table)
- `/phase-feedback` now reverts parent phase completion in ROADMAP.md when creating a feedback subphase
- Updated `/progress` Route C to offer `/code` as a phase refinement alternative
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting with `/code` documentation

### marketplace-utils
- Added `/release` skill for automated release ceremony: detects changes, bumps versions, updates docs, syncs marketplace, commits, pushes, and opens PR
- Bumped version to 1.0.2

## [1.0.15] - 2026-02-13

### claude-super-team
- Audited all 18 skills across 3 plugins
- Redesigned `/add-security-findings` with dual-mode support: Interactive (manual invocation) and Autonomous (auto-invoked after security analysis with findings in context)
- Downgraded `/map-codebase` model from opus to sonnet for cost/speed efficiency
- Added `maxTurns: 40` and `memory: project` to `phase-researcher` agent for safety limits and session persistence
- Added `disable-model-invocation: true` to `/new-project` to prevent spurious auto-invocation
- Added `argument-hint` to `/cst-help` and dynamic context injection (`!` commands) to `/cst-help` and `/progress`
- Added `allowed-tools` to `/marketplace-manager` (was missing entirely)
- Added `Skill` tool to `/linear-sync` for invoking Linear CLI
- Downgraded `/github-issue-manager` model from sonnet to haiku
- Added `argument-hint` to `/marketplace-manager` and `/github-issue-manager`

## [1.0.14] - 2026-02-12

### claude-super-team
- Added inline research detection to `/phase-feedback`: LLM analyzes confirmed feedback for unfamiliar packages/APIs/patterns and conditionally spawns the `phase-researcher` agent before planning
- Added planning file sync detection to `/progress`: detects directory-vs-roadmap mismatches, STATE.md drift, and progress table inconsistencies; outputs "Sync Issues" warning block when problems found
- Added per-project simplifier toggle to `/execute-phase`: `simplifier: enabled|disabled` preference in STATE.md gates the code-simplifier step in both task mode and teams mode
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting with sync detection documentation

## [1.0.13] - 2026-02-12

### claude-super-team
- Added compaction resilience to `/execute-phase`: skill-scoped hooks (`PreCompact`, `SessionStart`) preserve and re-inject execution state when context compaction occurs during long team-mode runs
- Added `EXEC-PROGRESS.md` tracking to `/execute-phase`: initializes wave/plan/team state in Phase 4.7, updates at 5 execution points (wave start, teammate spawn, plan completion, wave completion, team cleanup), and cleans up in Phase 8
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting with compaction resilience documentation

## [1.0.12] - 2026-02-12

### claude-super-team
- Added branch guard to `/execute-phase`: warns when running on main/master and offers to switch branch or continue
- Added execution mode logging to `/execute-phase`: prints which mode (team/task) was selected and how to change it
- Added single-plan wave downgrade in `/execute-phase`: waves with only one plan automatically use task mode even in teams mode, since cross-plan parallelism has no benefit
- Updated `/execute-phase` completion summary with Mode column in wave table
- Enhanced `/brainstorm` with Phase 11.5: auto-generates CONTEXT.md files for new roadmap phases created from brainstorm ideas, using the discuss-phase context template
- Enhanced `/progress` phase table with Steps column showing discuss/research/plan status (D/R/P) per phase

## [1.0.11] - 2026-02-11

### claude-super-team
- Reworked `/phase-feedback` to route by scope: quick fixes are applied directly inline (no subphase, no agents), while standard feedback creates a subphase + plan and directs the user to run `/execute-phase` instead of executing immediately
- Updated `/cst-help` workflow-guide, troubleshooting, and skill reference to reflect new routing behavior

## [1.0.10] - 2026-02-10

### claude-super-team
- Added `/brainstorm` skill with two modes: Interactive (collaborative discussion) and Autonomous (parallel agent analysis with bold recommendations)
- Interactive mode: iterative idea exploration with AskUserQuestion, deep-dives, and per-idea decisions
- Autonomous mode: spawns 3 parallel agents (Codebase Explorer, Creative Strategist, Architecture Reviewer) to generate comprehensive ideas ranked by impact-to-effort ratio
- Both modes write to `.planning/IDEAS.md` and optionally invoke `/create-roadmap` to add approved ideas as new phases
- Updated `/cst-help`, workflow-guide, and troubleshooting to document brainstorming workflow

## [1.0.9] - 2026-02-10

### claude-super-team
- Added execution model preference (`execution-model: sonnet|opus`) to `## Preferences` section in STATE.md and PROJECT.md
- `/new-project` now asks user for preferred execution model during project initialization (Phase 3.5)
- `/create-roadmap` carries execution model preference from PROJECT.md to STATE.md when creating state
- `/execute-phase` reads preference from STATE.md and asks on first run if not set (Phase 3.5); opus preference overrides routing table to use opus for all execution tasks
- Updated STATE.md and PROJECT.md templates with `## Preferences` section

## [1.0.8] - 2026-02-10

### claude-super-team
- Added code-simplifier step to `/execute-phase`: after all tasks in a plan complete, spawns `code-simplifier:code-simplifier` agent to refine written code for clarity, consistency, and maintainability before summary creation
- Updated teams mode to embed simplifier call in teammate prompt (runs after task execution, before SUMMARY.md)
- Requires `code-simplifier` plugin: install via `/plugin install code-simplifier@claude-plugins-official`
- Updated `/cst-help`, workflow-guide, and troubleshooting to document the simplification step

## [1.0.7] - 2026-02-10

### claude-super-team
- Added discuss-research feedback loop: `/discuss-phase` now recommends `/research-phase` when no RESEARCH.md exists, and `/research-phase` cross-references findings against CONTEXT.md decisions to detect conflicts (deprecated packages, better alternatives) and recommend re-discussion
- Updated `/discuss-phase` Phase 8 to check for RESEARCH.md and prompt user to research before planning
- Updated `/research-phase` with new Phase 6 (decision conflict detection) that compares research against CONTEXT.md and routes user back to `/discuss-phase` if conflicts found
- Updated README, `/cst-help`, workflow-guide, and troubleshooting to document the discuss-research-discuss flow

## [1.0.6] - 2026-02-10

### claude-super-team
- Enhanced `/discuss-phase` with cross-phase context loading (Phase 3.5) -- reads earlier phase SUMMARY/PLAN/CONTEXT.md to understand what prior phases will create, enabling dependency-aware gray areas
- Enhanced `/discuss-phase` with codebase exploration (Phase 3.7) -- spawns Explore agent to find phase-relevant code patterns and constraints before generating gray areas
- Added `Task` to discuss-phase allowed-tools for agent spawning
- Updated context-template.md with new "Codebase Context" and "Cross-Phase Dependencies" sections for downstream planners
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting to reflect codebase-aware discuss-phase

## [1.0.5] - 2026-02-10

### claude-super-team
- Added `/research-phase` skill for ecosystem research before planning
- Added custom `phase-researcher` agent (`agents/phase-researcher.md`) with embedded research methodology, template, and preloaded Firecrawl skill
- Updated `/plan-phase` to offer research when RESEARCH.md missing
- Updated `/progress` routing to suggest research after discussion
- Added RESEARCH.md interpretation guidance to planner-guide.md
- Updated `/cst-help` with research-phase documentation

## [1.0.4] - 2026-02-09

### claude-super-team
- Added `/cst-help` skill for interactive workflow help, concept explanations, and troubleshooting
- Updated README with `/discuss-phase` and `/cst-help` documentation, renumbered all commands

## [1.0.3] - 2026-02-09

### claude-super-team
- Added `/discuss-phase` skill for capturing user implementation decisions before planning
- Integrated lightweight discussion step into `/quick-plan`
- Updated `/progress` routing to suggest discussion when no context exists
- Added informational note to `/plan-phase` when CONTEXT.md is missing

## [1.0.2] - 2026-02-09

### task-management (new plugin)
- Added `/linear-sync` skill for syncing `.planning/` artifacts to Linear
- Added `/github-issue-manager` skill for creating and managing GitHub issues

### marketplace-utils
- Added `/skill-creator` skill for guided skill scaffolding

## [1.0.1] - 2026-02-09

### claude-super-team
- Added `/phase-feedback` skill for feedback-driven subphases with opus agents
- Added teams mode to `/execute-phase` for multi-agent parallel execution
- Added `/quick-plan` skill for lightweight phase insertion with decimal numbering

### marketplace-utils (new plugin)
- Added `/marketplace-manager` skill for auditing and managing plugin marketplaces

## [1.0.0] - 2026-02-08

### claude-super-team (new plugin)
- Initial release with core planning and execution pipeline
- Skills: `/new-project`, `/create-roadmap`, `/plan-phase`, `/execute-phase`, `/progress`
