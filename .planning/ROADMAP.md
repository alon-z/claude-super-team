# Roadmap: Claude Super Team

## Overview

All 13 phases (plus 7 quick phases) are complete. The roadmap is fully delivered.

## Phases

- [x] **Phase 1: Claude Code Capability Mapping** - Research and document all available plugin primitives as an audit reference
- [x] Phase 1.1: Add phase steps tracking to progress skill (QUICK)
- [x] Phase 1.2: Add branch guard and team log to execute-phase (QUICK)
- [x] Phase 1.3: Make brainstorm create context for roadmap phases (QUICK)
- [x] Phase 1.4: Add compaction resilience to execute-phase (QUICK)
- [x] Phase 1.5: Add research detection to phase-feedback skill (QUICK)
- [x] Phase 1.6: Add planning file sync detection to progress skill (QUICK)
- [x] Phase 1.7: Add per-project toggle to disable simplifier agent in execute-phase (QUICK)
- [x] **Phase 2: Skill Audit & Reclassification** - Systematically review every skill and classify as skill, agent, or hybrid
- [x] **Phase 3: Apply Audit Recommendations** - Implement reclassifications, add missing features, fix frontmatter gaps
- [x] **Phase 4: Harden Fragile Areas** - Address tech debt, phase numbering, state coordination, and large file decomposition
- [x] **Phase 5: Workflow Validation & Gap Closure** - Dogfood updated marketplace on a real project, discover and fix remaining gaps
- [x] **Phase 6: Hook-Based Telemetry Capture** - Add passive telemetry to orchestrator skills via shared shell script and skill-scoped hooks
- [x] **Phase 7: Efficiency Regression Detection** - Create /metrics skill for resource reporting and threshold-based violation detection
- [x] Phase 7.1: Build Skill Efficiency (QUICK)
- [x] **Phase 8: Full Auto Mode** - Create /build skill that autonomously chains all pipeline skills to go from idea to fully built and validated application
- [x] **Phase 9: Script Consolidation & State Compaction** - Centralize duplicated gather scripts and add state compaction
- [x] **Phase 10: Skill Capability Enhancements** - Enhance /cst-help with artifact explanation and /build with dynamic completion awareness
- [x] **Phase 11: Drift Detection** - Create /drift skill comparing codebase against planning artifacts
- [x] **Phase 12: New-Project Discussion Mode & Build Auto-Extend** - Add interactive app definition to /new-project and make /build work from any project state
- [x] **Phase 13: JSON Schema Infrastructure for Planning Files** [Sprint 13] [L] - Add structured JSON alongside top-level .planning/ MD files, update gather scripts to use jq, add /cst-help migration

## Phase Details

### Phase 1: Claude Code Capability Mapping
**Goal**: Create a complete reference of Claude Code's plugin primitives -- skills, agents, hooks, frontmatter options, context behavior -- as the standard to audit against
**Depends on**: Nothing (first phase)
**Requirements**: Foundation for systematic audit (Active req 1) and feature usage (Active req 3)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A capability reference document exists covering all skill frontmatter fields, agent definition syntax, hooks, and context behavior options
  2. Each capability is documented with when to use it, examples, and tradeoffs (skill vs agent vs hook)
  3. The reference is accurate against the current Claude Code version (verified by testing at least 3 capabilities)

### Phase 1.5: Add Research Detection to Phase-Feedback Skill (QUICK)
**Goal:** Make phase-feedback detect when feedback requires research (e.g., missing package docs, unfamiliar APIs) and spawn a research agent inline before planning
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. Phase-feedback skill includes an LLM analysis step between feedback collection and planner spawning that determines if research is needed
2. When research is needed, the skill spawns the phase-researcher agent inline and passes RESEARCH.md to the planner

### Phase 1.4: Add Compaction Resilience to Execute-Phase (QUICK)
**Goal:** Make execute-phase survive context compaction during long team-mode executions by adding skill-scoped hooks and EXEC-PROGRESS.md tracking
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. Execute-phase skill has PreCompact and SessionStart(compact) hooks in frontmatter that re-inject critical state after compaction
2. Execute-phase writes EXEC-PROGRESS.md during execution tracking wave/plan completion, team name, and teammate state
3. cst-help is updated with guidance on compaction resilience and CLAUDE_AUTOCOMPACT_PCT_OVERRIDE configuration

### Phase 1.6: Add Planning File Sync Detection to Progress Skill (QUICK)
**Goal:** Make `/progress` detect and report sync issues between planning files -- missing phase directories, sub-phases absent from ROADMAP.md, STATE.md pointing to nonexistent phases, and other desync conditions
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. `/progress` includes a "Sync Issues" section that detects phase directories not listed in ROADMAP.md and ROADMAP.md phases without matching directories
2. `/progress` reports when STATE.md references a phase that doesn't exist in ROADMAP.md or has no directory

### Phase 1.7: Add Per-Project Toggle to Disable Simplifier Agent in Execute-Phase (QUICK)
**Goal:** Allow users to disable the code-simplifier agent step in execute-phase on a per-project basis via a persistent setting
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. A `simplifier` preference in STATE.md (or equivalent per-project config) controls whether the code-simplifier step runs during execution
2. Execute-phase respects the setting in both task mode and teams mode, skipping simplification when disabled

### Phase 2: Skill Audit & Reclassification
**Goal**: Systematically review every skill in the marketplace against the capability reference, producing per-skill recommendations
**Depends on**: Phase 1
**Requirements**: Systematic audit (Active req 1), evaluate skill vs agent (Active req 2)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Every skill across all 3 plugins has been audited with findings documented
  2. Each skill has a classification: remain as skill, convert to agent, hybrid, or needs feature additions
  3. Specific frontmatter/feature gaps are identified per skill (missing tool restrictions, wrong model, missing context fork, etc.)

### Phase 3: Apply Audit Recommendations
**Goal**: Implement all reclassification decisions and feature fixes from the audit
**Depends on**: Phase 2
**Requirements**: Convert skills to agents (Active req 2), use available features (Active req 3)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Skills classified for conversion are converted to agents (or hybrid) with working implementations
  2. All frontmatter gaps are fixed -- every skill uses correct tool restrictions, model selection, context behavior, and argument hints
  3. No regression -- every skill/agent functions correctly after changes (verified by manual execution of key workflows)

### Phase 4: Harden Fragile Areas [COMPLETE]
Centralized phase number normalization into shared `phase-utils.sh` (6 skills updated), decomposed build/SKILL.md from 1084 to 498 lines via two extracted reference documents. STATE/ROADMAP sync detection already covered by Phase 1.6.

### Phase 5: Workflow Validation & Gap Closure [COMPLETE]
Validated 10/16 skills post-audit via tevel project dogfooding, catalogued 6 gaps with proposed solutions. Fixed highest-impact gap: plan-phase startup speed reduced by moving context assembly into gather-data.sh (0 LLM Read calls, down from 6+).

### Phase 6: Hook-Based Telemetry Capture
**Goal**: Add passive, zero-token-cost telemetry to orchestrator skills via a shared shell script called by skill-scoped hooks
**Depends on**: Phase 5
**Requirements**: Add missing capabilities (Active req 4)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A `telemetry.sh` script exists in `plugins/claude-super-team/scripts/` that captures timing, agent spawns, tool usage, outcomes, and token usage
  2. Orchestrator skills (plan-phase, execute-phase, research-phase, brainstorm) declare hooks in YAML frontmatter that call `telemetry.sh` at skill start/end and key lifecycle points
  3. Telemetry data accumulates in `.planning/.telemetry/` in a format validated by research (JSONL, SQLite, or CSV)
  4. Hook script gracefully no-ops when `.planning/` or `.planning/.telemetry/` directories don't exist

### Phase 7: Efficiency Regression Detection [COMPLETE]
Created /metrics skill with gather-data.sh (telemetry JSONL aggregation, 8 structured sections, jq with grep/sed fallback), SKILL.md (haiku model, context: fork, threshold violation detection), and report-template.md. Registered in plugin manifests (v1.0.50) and documented in /cst-help (skill reference, workflow guide, troubleshooting).

### Phase 7.1: Build Skill Efficiency (QUICK)
**Goal:** Make /build significantly faster for well-understood projects by fixing teams detection, adding smarter pipeline depth, skipping verification when validation passes clean, and enabling parallel phase execution
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 8

Success Criteria:
1. Execute-phase reads teams-available from gather script PREFERENCES section instead of checking inaccessible env var (bug fix)
2. /build's adaptive pipeline depth heuristic accounts for project complexity class and tech stack coverage, not just keyword matching
3. Verification is skippable via a `verification` preference in STATE.md (always|on-failure|disabled), defaulting to on-failure (skip deep verification when build+tests pass clean)
4. Plan-phase planner instructions produce more aggressive wave batching -- plans that can safely run in parallel are assigned to the same wave

### Phase 8: Full Auto Mode
**Goal**: Create a `/build` skill that autonomously chains the entire planning pipeline -- from idea to fully built and validated application -- using all claude-super-team skills with no user intervention, surviving many context compactions and self-validating its output at each stage
**Depends on**: Phase 7
**Requirements**: Add missing capabilities (Active req 4)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A `/build` skill exists that accepts a project idea as input and autonomously orchestrates: `/new-project` -> `/brainstorm` (autonomous mode) -> `/create-roadmap` -> and for each phase: `/discuss-phase` -> `/research-phase` -> `/plan-phase` -> `/execute-phase`
  2. The skill makes autonomous decisions at every AskUserQuestion checkpoint, using LLM reasoning to select the best option without user intervention
  3. The skill maintains a durable `BUILD-STATE.md` file that tracks the exact pipeline position (which skill, which phase, which step), all decisions made, and all validation results -- enabling full recovery after any context compaction
  4. After each phase execution, the skill runs self-validation: builds the project, runs tests (if any exist), checks for errors, and uses `/phase-feedback` autonomously to fix issues before proceeding to the next phase
  5. At completion, the user has a working application that builds and passes its own tests, with all `.planning/` artifacts documenting the full journey from idea to delivery

### Phase 9: Script Consolidation & State Compaction [COMPLETE]
Created gather-common.sh with 7 shared emit_* functions sourced by all 9 active gather-data.sh scripts. Added create_phase_dir() to phase-utils.sh replacing inline pipelines in 3 SKILL.md files. Extended execute-phase Phase 8 with STATE.md decision archival (### Decision Archive delimiter). Audited 24 skills/agents for tool permissions, fixing 4 missing declarations.

### Phase 10: Skill Capability Enhancements [COMPLETE]
Added /cst-help explain capability (reads .planning/ artifacts + phase context, produces 5-10 sentence narrative) and /build completion audit (Step 12.5 with 4-category gap detection, bounded 2-cycle remediation via /phase-feedback).

### Phase 11: Drift Detection [COMPLETE]
Created /drift skill with SKILL.md orchestrator (sonnet, spawns opus agents), gather-data.sh with PHASE_ARTIFACTS and CODEBASE_DOCS sections, drift-analysis-guide.md for claim extraction/verification methodology, drift-report-template.md for structured output. Updated cst-help with /drift in skill reference, workflow guide, and troubleshooting.

### Phase 12: New-Project Discussion Mode & Build Auto-Extend [COMPLETE]
/new-project --discuss mode (Path C) with progressive domain/problem/users narrowing via AskUserQuestion. /build 5-way branching: auto-extend (PROJECT.md + ROADMAP.md, no BUILD-STATE.md) and partial-project (PROJECT.md only) detection via new gather-data.sh signals.

### Phase 13: JSON Schema Infrastructure for Planning Files [COMPLETE]
json-sync.sh (676 lines) converts PROJECT/ROADMAP/STATE/IDEAS MD files to structured JSON. gather-common.sh emit_* functions use JSON-first extraction with silent MD fallback. 6 gather-data.sh scripts updated with inline JSON-first paths. /new-project, /create-roadmap, /brainstorm produce dual MD+JSON output. /cst-help migrate action generates JSON from existing MD-only projects.

## Sprint Summary

| Sprint | Phases | What's Demoable After |
|--------|--------|-----------------------|
| 13 | Phase 13 | Planning files have dual MD+JSON format; gather scripts use jq; existing projects can migrate via /cst-help |

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Claude Code Capability Mapping | Complete | 2026-02-11 |
| 1.1 Progress Phase Steps (QUICK) | Complete | 2026-02-11 |
| 1.2 Execute Branch Guard Team Log (QUICK) | Complete | 2026-02-12 |
| 1.3 Brainstorm Creates Context (QUICK) | Complete | 2026-02-12 |
| 1.4 Execute Compaction Resilience (QUICK) | Complete | 2026-02-11 |
| 1.5 Feedback Research Detection (QUICK) | Complete | 2026-02-25 |
| 1.6 Progress Sync Detection (QUICK) | Complete | 2026-02-25 |
| 1.7 Simplifier Toggle (QUICK) | Complete | 2026-02-25 |
| 2. Skill Audit & Reclassification | Complete | 2026-02-25 |
| 3. Apply Audit Recommendations | Complete | 2026-02-25 |
| 4. Harden Fragile Areas | Complete | 2026-03-12 |
| 5. Workflow Validation & Gap Closure | Complete | 2026-03-13 |
| 6. Hook-Based Telemetry Capture | Complete | 2026-02-17 |
| 7. Efficiency Regression Detection | Complete | 2026-03-20 |
| 7.1 Build Skill Efficiency (QUICK) | Complete | 2026-02-25 |
| 8. Full Auto Mode | Complete | 2026-02-18 |
| 9. Script Consolidation & State Compaction | Complete | 2026-03-16 |
| 10. Skill Capability Enhancements | Complete | 2026-03-16 |
| 11. Drift Detection | Complete | 2026-03-16 |
| 12. New-Project Discuss + Build Auto-Extend | Complete | 2026-03-17 |
| 13. JSON Schema Infrastructure | Complete | 2026-03-27 |

---
*Created: 2026-02-11*
