# Brainstorming Session: Usability and Day-to-Day Operations

**Date:** 2026-03-16
**Mode:** Autonomous
**Context:** The claude-super-team plugin has 16 skills, completed Phases 1-4, 6, 7.1, and 8. Remaining: Phase 5 (workflow validation) and Phase 7 (metrics). Three parallel analysis agents (Codebase Explorer, Creative Strategist, Architecture Reviewer) analyzed usability friction, daily workflow pain points, and architectural improvements.

---

## Ideas Explored

### Idea 1: Centralize Gather Scripts

**Description:**
Extract shared functions into `scripts/gather-common.sh` -- functions like `emit_project_section()`, `emit_phase_completion()`, `emit_sync_check()`, `emit_preferences()`. All 11 `gather-data.sh` scripts source the common script instead of copy-pasting identical logic. Follows the same pattern as the successful `phase-utils.sh` centralization from Phase 4.

**Motivation:**
11 gather-data.sh scripts duplicate identical logic for reading PROJECT.md, ROADMAP.md, STATE.md, and computing phase completion. When a convention changes (new artifact type, naming scheme shift), all 11 files must be updated in lockstep. The `progress/gather-data.sh` and `scripts/progress-gather.sh` have already partially diverged. This is the highest-leverage maintenance improvement.

**Tradeoffs:**
- **Pros:** Single source of truth for state parsing; bug fixes propagate everywhere; same proven pattern as phase-utils.sh; reduces per-skill gather scripts to just skill-specific sections
- **Cons:** Medium effort to extract and test; need to handle the SKIP_ flag pattern across shared functions; some skills have subtly different output formats for the same computation

**Implementation Notes:**
- Create `scripts/gather-common.sh` alongside existing `scripts/phase-utils.sh`
- Extract: project loading, roadmap loading, state loading, phase completion counting, preferences extraction, sync checks
- Each skill's gather-data.sh sources the common script and appends skill-specific sections
- Preserve the SKIP_PROJECT/SKIP_ROADMAP/SKIP_STATE pattern in the shared functions

**Decision:**
APPROVED

---

### Idea 2: Unified Phase Resolution

**Description:**
Add a `create_phase_dir` function to the existing `phase-utils.sh` that takes a phase number, looks up the name from ROADMAP.md, creates the directory if needed, and returns the path. Replaces 4 different inline pipelines across skills that each implement this differently.

**Motivation:**
Four skills (discuss-phase, plan-phase, quick-plan, execute-phase) have different inline Bash pipelines for deriving phase name from ROADMAP.md and creating the directory. They use different combinations of `ls -d`, `grep`, `sed`, and `tr`. Identical today but fragile to divergence on any future format change.

**Tradeoffs:**
- **Pros:** Single function for phase directory creation; eliminates 4 different code paths; low effort since phase-utils.sh already exists and is sourced by these skills
- **Cons:** Minimal -- straightforward extraction of existing logic

**Implementation Notes:**
- Add `create_phase_dir()` to `scripts/phase-utils.sh`
- Function accepts phase number, reads ROADMAP.md for phase name, creates directory, returns path
- Update discuss-phase, plan-phase, quick-plan, execute-phase to call the shared function

**Decision:**
APPROVED

---

### Idea 3: Compact STATE.md Decisions

**Description:**
When `execute-phase` runs its existing ROADMAP.md compaction step for completed phases, also process STATE.md: move decisions from completed phases into a `### Decision Archive` section at the bottom. The active `### Decisions` section keeps only decisions from the current and upcoming phases. Gather-data scripts only emit the active section.

**Motivation:**
Every gather-data.sh dumps the full STATE.md into context. As projects grow, stale decisions from completed phases waste tokens without adding value to planners or executors. For a 15-phase project, the decisions section could be 40+ lines of irrelevant context per skill invocation.

**Tradeoffs:**
- **Pros:** Keeps active context lean; no data lost (archive preserved in file); reduces token waste per invocation; same concept as existing ROADMAP.md compaction
- **Cons:** Need to reliably associate decisions with phase numbers; gather scripts must know to stop at the archive section

**Implementation Notes:**
- Extend execute-phase compaction step to also process STATE.md
- Move decisions tagged with completed phase numbers below a `### Decision Archive` heading
- Update gather-data scripts (or gather-common.sh after Idea 1) to only emit up to the archive delimiter

**Decision:**
APPROVED

---

### Idea 4: Drift Detector

**Description:**
A `/drift` skill that compares the actual codebase state against what planning artifacts say should exist. Reads SUMMARY.md files (which describe what was built), inspects the actual code to find divergence: files that summaries say exist but don't, architectural patterns that drifted from CONTEXT.md decisions, dependencies added that weren't in RESEARCH.md, tests that were planned but never written.

**Motivation:**
Planning artifacts become stale the moment any work happens outside the pipeline -- a quick manual commit, a fix during a `/code` session, a refactor that changes the architecture. Over time, `.planning/` state becomes fiction. Drift detection turns planning from a one-time documentation activity into a living contract with the codebase. This is the difference between a project management tool and a project integrity tool.

**Tradeoffs:**
- **Pros:** Transforms planning artifacts from documentation into living contracts; surfaces hidden divergence; uniquely possible because the entire lifecycle is instrumented; builds trust in planning artifacts
- **Cons:** High effort -- requires deep codebase analysis and semantic comparison against plans; may produce false positives for intentional changes; needs clear definition of what constitutes "drift" vs "evolution"

**Implementation Notes:**
- New `/drift` skill in claude-super-team plugin
- Reads all SUMMARY.md files for descriptions of what was built
- Uses Explore agent to inspect actual codebase state
- Compares against CONTEXT.md decisions, RESEARCH.md recommendations, PLAN.md task specifications
- Reports: confirmed drift (clear divergence), potential drift (unclear), aligned (matches plan)
- Could integrate into `/progress` as an optional drift check section

**Decision:**
APPROVED

---

### Idea 5: Enhance /cst-help with Artifact Explanation

**Description:**
Extend the `/cst-help` skill to handle "explain [path]" queries -- when given a `.planning/` file path, it reads the artifact and its surrounding context (CONTEXT.md, RESEARCH.md, ROADMAP.md phase details) and reconstructs the reasoning chain: why the artifact exists, what constraints shaped it, how it connects to decisions and research.

**Motivation:**
Planning artifacts are structured data optimized for machine consumption (planners, executors, verifiers). When reviewing them, users want the story: why is this task in wave 2? Why 5 success criteria? The answers are scattered across multiple files. Rather than a standalone skill, this fits naturally into `/cst-help` which already serves as the project's help and context system.

**Tradeoffs:**
- **Pros:** Natural extension of cst-help's existing purpose; no new skill to maintain; provides on-demand transparency for any artifact
- **Cons:** Adds complexity to cst-help's routing logic; needs to read multiple files for context synthesis

**Implementation Notes:**
- Add a routing case in cst-help for "explain" queries
- When triggered, read the target file plus its phase's CONTEXT.md, RESEARCH.md, and ROADMAP.md phase detail
- Synthesize a narrative explaining the artifact's purpose, constraints, and connections
- Keep the explanation concise -- 5-10 sentences, not a full essay

**Decision:**
APPROVED

---

### Idea 6: Enhance /build Dynamic Awareness

**Description:**
Make `/build` more dynamic -- able to detect when there is more work to do beyond its initial pipeline run. Currently `/build` runs a fixed pipeline and stops. Enhancement would allow it to recognize incomplete work, detect new requirements that emerged during execution, and continue working until the project is truly done.

**Motivation:**
User feedback: the concept of `/next` (auto-advancing through the manual workflow) should be absorbed into `/build` rather than existing as a separate skill. `/build` should be the single entry point for autonomous work and should be smart enough to know when it is not done yet.

**Tradeoffs:**
- **Pros:** Single entry point for all autonomous work; no new skill to learn; builds on existing /build infrastructure
- **Cons:** Increases /build complexity; needs clear termination criteria to avoid infinite loops; must distinguish between "more work to do" and "done"

**Implementation Notes:**
- After the main pipeline completes, add a "completion audit" step that checks for gaps
- Detect: phases with failed verification, phases marked incomplete, new requirements surfaced during execution
- If gaps found, present a summary and continue working (in autonomous mode) or report and stop
- Needs a bounded retry mechanism to prevent infinite loops

**Decision:**
APPROVED (modified from original "Autopilot /next" proposal)

---

### Idea 7: Smart Defaults for AskUserQuestion

**Description:**
Expand STATE.md preferences to remember repeated AskUserQuestion answers. Auto-apply after consistent answers with an --ask override.

**Decision:**
REJECTED -- User prefers explicit control over automated assumptions.

---

### Idea 8: Quiet Mode

**Description:**
Global preference to suppress verbose output (Next Steps blocks, success criteria, explanatory text).

**Decision:**
REJECTED -- Output verbosity is acceptable as-is.

---

### Idea 9: Compact Progress (--compact flag)

**Description:**
A `--compact` flag on `/progress` outputting a single line suitable for shell prompts or quick checks.

**Decision:**
DEFERRED -- Nice to have but not a priority.

---

### Idea 10: Skip Discussion for Known Phases (--fast flag on plan-phase)

**Description:**
Add --fast flag to /plan-phase that plans without requiring CONTEXT.md or RESEARCH.md.

**Decision:**
REJECTED -- Already works this way. Plan-phase proceeds without these files when they don't exist.

---

### Idea 11: Clean Dead Code

**Description:**
Remove scripts/progress-gather.sh (duplicate), .DS_Store files tracked in git, move *-workspace/ eval directories.

**Decision:**
REJECTED

---

### Idea 12: Warmup (Context Preloader)

**Description:**
/warmup generates a narrative reconstruction for resuming after time away from a project.

**Decision:**
REJECTED

---

### Idea 13: Rewind (Phase Rollback)

**Description:**
/rewind [N] rolls back a phase execution -- removes artifacts, unchecks roadmap, resets state.

**Decision:**
REJECTED

---

### Idea 14: Fast Restart (Session Resume)

**Description:**
Lightweight session state tracking with /resume for interrupted multi-step skills.

**Decision:**
REJECTED

---

### Idea 15: Postmortem (Automated Retrospective)

**Description:**
/postmortem analyzes full .planning/ history to generate data-driven retrospectives using telemetry, decisions, and outcomes.

**Decision:**
DEFERRED -- Interesting concept, revisit after Phase 7 (metrics) is complete and telemetry data is consumable.

---

### Idea 16: Checkpoint (Save/Restore Planning Snapshots)

**Description:**
/checkpoint save/restore/list for versioning .planning/ state independent of git.

**Decision:**
REJECTED

---

### Idea 17: Fix Progress Model/Data Mismatch

**Description:**
/progress uses haiku with the heaviest gather script. Proposal to reduce data or bump model.

**Decision:**
REJECTED

---

### Idea 18: Error Recovery (Try-Catch for Task Failures)

**Description:**
Wrap critical operations in try-catch, save state on failure, offer retry/skip/abort.

**Decision:**
REJECTED

---

### Idea 19: Validate Planner Output

**Description:**
Glob for PLAN.md files after planner returns to verify they were actually written.

**Decision:**
REJECTED

---

### Idea 20: Preserve Branches on Merge Failure

**Description:**
In /build, keep branches as "merge-pending" instead of force-deleting on squash-merge failure.

**Decision:**
REJECTED

---

### Idea 21: Template Extraction

**Description:**
/extract-template distills completed .planning/ into reusable blueprints for new projects.

**Decision:**
REJECTED

---

### Idea 22: Parallel Sprint Execution

**Description:**
Execute independent /build sprint phases in parallel via Task tool.

**Decision:**
REJECTED

---

### Idea 23: Bidirectional Plan-Code Sync

**Description:**
Hooks detect code changes outside the pipeline and propose updates to planning artifacts. Updated CONTEXT decisions flag violating code.

**Decision:**
DEFERRED -- Ambitious and valuable but depends on drift detection infrastructure (Idea 4) being built first.

---

## Approved Ideas Summary

| Idea | Priority | Next Step |
|------|----------|-----------|
| Centralize Gather Scripts | High | Add as roadmap phase; extract shared functions into gather-common.sh |
| Unified Phase Resolution | High | Add create_phase_dir to phase-utils.sh; update 4 skills |
| Compact STATE.md Decisions | Medium | Extend execute-phase compaction step |
| Drift Detector | Medium | Add as roadmap phase; design drift comparison methodology |
| Enhance /cst-help with Artifact Explanation | Medium | Add explain routing case to cst-help |
| Enhance /build Dynamic Awareness | Medium | Add completion audit step to /build pipeline |

---

## Deferred Ideas

- **Compact Progress:** Single-line output flag for /progress. Low priority, revisit when shell prompt integration becomes useful.
- **Postmortem:** Automated retrospective from planning data. Depends on Phase 7 (metrics/telemetry consumption) being complete.
- **Bidirectional Plan-Code Sync:** Reactive planning layer. Depends on Drift Detector being built first as foundation.

---

## Rejected Ideas

- **Smart Defaults:** User prefers explicit control over automated assumptions
- **Quiet Mode:** Output verbosity is acceptable
- **Skip Discussion:** Already works -- plan-phase proceeds without CONTEXT.md/RESEARCH.md
- **Clean Dead Code:** Not a priority
- **Warmup:** Not needed
- **Rewind:** Not needed
- **Fast Restart:** Not needed
- **Checkpoint:** Not needed
- **Fix Progress Model:** Not needed
- **Error Recovery:** Not needed
- **Validate Planner Output:** Not needed
- **Preserve Branches:** Not needed
- **Template Extraction:** Not needed
- **Parallel Sprint Execution:** Not needed

---

## Next Actions

1. Update ROADMAP.md with new phases for approved ideas (via /create-roadmap)
2. Centralize gather scripts as the first implementation target (highest maintenance leverage)
3. Add create_phase_dir to phase-utils.sh alongside gather centralization

---

_Last updated: 2026-03-16_

---

# Brainstorming Session: Monitoring Efficiency of the Claude Super Team Flow

**Date:** 2026-02-17
**Context:** The claude-super-team plugin has 14 skills forming a sequential planning pipeline. The project is through Phase 3 with Phases 4-5 remaining. The user wants to monitor workflow efficiency -- primarily resource usage (tokens, timing, agent spawns, tool usage, outcomes) -- to optimize skills, track trends over time, and compare approaches. Key constraint: monitoring must be deterministic, zero-token-cost, and add no friction.

---

## Ideas Explored

### Idea 1: Hook-Based Telemetry Capture

**Description:**
A shared shell script (`plugins/claude-super-team/scripts/telemetry.sh`) called by hooks declared in each orchestrator skill's YAML frontmatter. Captures timing, agent spawns, tool usage, outcomes, and token usage at key lifecycle points (skill start, tool calls, skill end). Data writes to `.planning/.telemetry/`. Coverage limited to orchestrator skills only (plan-phase, execute-phase, research-phase, brainstorm).

**Motivation:**
Passive, zero-token-cost monitoring. Hooks run outside the LLM context so they add no friction or expense. Single script as source of truth minimizes maintenance burden. No global hook installation needed -- hooks live in the skills themselves.

**Tradeoffs:**
- **Pros:** Zero token overhead; deterministic; no user friction; self-contained in plugin; single script to maintain
- **Cons:** Depends on what hook events Claude Code actually exposes; maintenance burden when skills change (mitigated by shared script); needs research on whether hooks can access token usage data

**Implementation Notes:**
- One `telemetry.sh` script in `plugins/claude-super-team/scripts/`
- Each orchestrator skill declares hooks in YAML frontmatter that call the script with event type + context
- Data accumulates in `.planning/.telemetry/` (storage format to be researched -- JSONL, SQLite, CSV, etc.)
- Script must be resilient to missing `.planning/` directories (graceful no-ops)
- Research needed: available hook events, token usage accessibility, optimal storage format

**Decision:**
APPROVED

---

### Idea 2: Efficiency Regression Detection (via /metrics)

**Description:**
A `/metrics` skill that reads `.planning/.telemetry/` data and compares it against absolute thresholds defined in `.planning/.telemetry/config.json`. Flags when metrics exceed configurable limits (e.g., >100 agent turns per phase, >N minutes wall-clock time). Triggered manually by the user.

**Motivation:**
Makes resource overruns visible without adding overhead to normal flow. Absolute thresholds are simpler and more predictable than statistical baselines, especially with limited historical data per project. Naturally pairs with hook-based telemetry -- hooks write, /metrics reads.

**Tradeoffs:**
- **Pros:** Simple threshold model; no statistical complexity; actionable output; manual trigger means zero cost unless needed
- **Cons:** Depends on telemetry data existing (Idea 1 must come first); absolute thresholds need initial tuning; limited value until enough data accumulates

**Implementation Notes:**
- New `/metrics` skill in claude-super-team plugin
- Reads all `.planning/.telemetry/` events, rolls up per-phase and per-skill
- Thresholds in `.planning/.telemetry/config.json` (e.g., `{"max_agent_turns_per_phase": 100, "max_duration_minutes": 30}`)
- Reports: per-phase summary table, threshold violations, total resource usage
- Depends on Idea 1 (hook-based telemetry) for data

**Decision:**
APPROVED

---

### Idea 3: Cross-Project Telemetry Store

**Description:**
Store telemetry data in `~/.claude/telemetry/{project-name}/` in addition to `.planning/.telemetry/`, enabling trend comparison across different projects using the same workflow.

**Motivation:**
Would enable long-term trend tracking across projects and skill version changes.

**Tradeoffs:**
- **Pros:** Cross-project visibility; persists beyond project cleanup
- **Cons:** Filesystem conventions for global data; data growth; scope creep

**Implementation Notes:**
Second write path in telemetry.sh to a global location.

**Decision:**
REJECTED -- Keeping telemetry scoped to per-project `.planning/` is simpler and sufficient. Cross-project comparison adds complexity without clear immediate value.

---

### Idea 4: SUMMARY.md Metrics Extension (not deep-dived)

**Description:**
Extend execute-phase SUMMARY.md files with structured metrics (agent turns, files modified, verification pass/fail, timing).

**Decision:**
Not explored -- superseded by hook-based telemetry which captures data more comprehensively and without modifying existing artifact formats.

---

### Idea 5: /metrics Reporting Skill (merged into Idea 2)

**Description:**
Originally proposed as a standalone reporting skill. Merged with regression detection into a single /metrics skill concept.

**Decision:**
Merged into Idea 2.

---

### Idea 6: Per-Skill Timing Instrumentation (not deep-dived)

**Description:**
Add timing and token instrumentation directly to each orchestrator skill's logic.

**Decision:**
Not explored -- superseded by hook-based approach which achieves the same result without touching skill logic.

---

### Idea 7: Budget Guardrails via Hooks (not deep-dived)

**Description:**
Use hooks to enforce soft resource limits with configurable warnings.

**Decision:**
Not explored in depth -- conceptually subsumed by Idea 2's threshold-based regression detection. Could be revisited as a real-time extension.

---

### Idea 8: A/B Configuration Profiles (not deep-dived)

**Description:**
Declare execution profiles in STATE.md for comparing different configurations.

**Decision:**
Not explored -- useful only after telemetry infrastructure exists. Could be revisited post-implementation.

---

## Approved Ideas Summary

| Idea | Priority | Next Step |
|------|----------|-----------|
| Hook-Based Telemetry Capture | High | Research hook events, storage format; add as roadmap phase |
| Efficiency Regression Detection (/metrics) | Medium | Implement after telemetry infrastructure; add as roadmap phase |

---

## Deferred Ideas

- **Cross-Phase Parallel DAG Execution:** /build analyzes "Depends on" fields in ROADMAP.md phase details to build a dependency DAG. Independent phases (no dependency relationship) execute in parallel using teams mode -- each phase gets its own branch from main, parallel agents work simultaneously, then merge sequentially when all complete. Failed phases mark dependents as skipped. Requires teams mode. Would significantly speed up builds where phases like "Auth" and "Frontend scaffold" are independent after a shared foundation phase.

---

## Rejected Ideas

- **Cross-Project Telemetry Store:** Per-project scoping is simpler and sufficient. No clear immediate value from cross-project aggregation.

---

## Next Actions

1. Research Claude Code hook events available for skill frontmatter (what can be captured)
2. Research optimal storage format for telemetry data (JSONL vs SQLite vs CSV)
3. Add telemetry infrastructure as a roadmap phase (hook-based capture + /metrics skill)

---

_Last updated: 2026-02-17_
