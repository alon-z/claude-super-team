# Context for Phase 8: Full Auto Mode

## Phase Boundary (from ROADMAP.md)

**Goal:** Create a `/build` skill that autonomously chains the entire planning pipeline -- from idea to fully built and validated application -- using all claude-super-team skills with no user intervention, surviving many context compactions and self-validating its output at each stage

**Success Criteria:**
1. A `/build` skill exists that accepts a project idea (and optional target directory) as input and autonomously orchestrates: `/new-project` -> `/brainstorm` (autonomous mode) -> `/create-roadmap` -> and for each phase: `/discuss-phase` -> `/research-phase` -> `/plan-phase` -> `/execute-phase`
2. The skill makes autonomous decisions at every AskUserQuestion checkpoint, using LLM reasoning to select the best option without user intervention
3. The skill maintains a durable `BUILD-STATE.md` file that tracks the exact pipeline position (which skill, which phase, which step), all decisions made, and all validation results -- enabling full recovery after any context compaction
4. After each phase execution, the skill runs self-validation: builds the project, runs tests (if any exist), checks for errors, and uses `/phase-feedback` autonomously to fix issues before proceeding to the next phase
5. At completion, the user has a working application that builds and passes its own tests, with all `.planning/` artifacts documenting the full journey from idea to delivery

**What's in scope for this phase:**
- Creating the `/build` skill (SKILL.md, assets, references)
- Autonomous pipeline orchestration via Skill tool invocations
- BUILD-STATE.md for durable state and compaction recovery
- build-preferences.md for global and per-project preferences
- LLM-based autonomous decision-making at AskUserQuestion gates
- Local git automation (feature branches per phase, squash-merge to main, never push)
- Adaptive build/test validation and auto-fix loops
- Auto-resume from BUILD-STATE.md on re-invocation

**What's explicitly out of scope:**
- Remote git operations (push, pull, PR creation)
- Task tool-based skill invocation (starting with Skill tool, may iterate to hybrid later)
- Target directory selection (always current directory)
- Parallelizing across phases (phases execute sequentially)

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/execute-phase/SKILL.md` (712 lines): Most complex orchestrator, compaction resilience via PreCompact/SessionStart hooks and EXEC-PROGRESS.md. Pattern for wave-based execution, task routing, verification loops
- `plugins/claude-super-team/skills/brainstorm/SKILL.md` (457 lines): Autonomous mode implementation with 3 parallel analysis agents. Pattern for non-interactive skill execution
- `plugins/claude-super-team/skills/phase-feedback/SKILL.md` (445 lines): Feedback loop with quick-fix vs standard path routing. Pattern for autonomous issue detection and remediation
- `plugins/claude-super-team/skills/progress/SKILL.md` (332 lines): State validation, sync detection, smart routing. Pattern for determining next action
- `plugins/claude-super-team/skills/new-project/SKILL.md`: Project initialization, brownfield detection, exec model preference capture
- `plugins/claude-super-team/skills/code/SKILL.md`: Session logging pattern in .planning/.sessions/
- `plugins/claude-super-team/scripts/telemetry.sh`: Telemetry capture engine for hook-based event logging

**Established patterns:**
- Skills use YAML frontmatter for tool restrictions, model selection, hooks
- PreCompact hooks emit state to stdout; SessionStart(compact) hooks re-inject state
- Dynamic context injection via `gather-data.sh` scripts that pre-load planning files
- AskUserQuestion is the primary user interaction mechanism (2-4 options, header, multiSelect)
- Skills read/write to `.planning/` directory tree with zero-padded phase numbering
- Wave-based execution: tasks within a plan sequential, plans within a wave parallel, waves sequential

**Integration points:**
- All 14 claude-super-team skills: /build chains them in sequence
- `.planning/STATE.md`: Tracks current position, preferences (exec model, simplifier)
- `.planning/ROADMAP.md`: Tracks phase completion and progress
- `.planning/BUILD-STATE.md` (new): Durable build execution state for recovery
- `~/.claude/build-preferences.md` and `.planning/build-preferences.md` (new): Global and per-project preferences
- `.planning/.telemetry/`: Telemetry data from hook-based capture

**Constraints from existing code:**
- Skills invoked via Skill tool share the conversation context -- context window fills across the full pipeline
- AskUserQuestion blocks until user responds; /build must make these decisions autonomously via LLM reasoning
- No `@` file references work across Task tool boundaries (relevant if hybrid approach adopted later)
- Compaction is automatic and can happen mid-skill; all state must be recoverable from files on disk

---

## Cross-Phase Dependencies

**From Phase 1 (Claude Code Capability Mapping)** [executed]:
- CAPABILITY-REFERENCE.md: Documents all frontmatter fields, hooks, context behavior
- ORCHESTRATION-REFERENCE.md: Complete hooks system documentation, teams mode, Task tool patterns

**From Phase 1.4 (Compaction Resilience)** [executed]:
- PreCompact/SessionStart hook pattern in execute-phase: /build must replicate this for BUILD-STATE.md
- EXEC-PROGRESS.md tracking pattern: /build adapts this for build-level progress tracking

**From Phase 3 (Apply Audit Recommendations)** [executed]:
- Established frontmatter conventions for all skills: tool restrictions, model selection, context behavior
- All skills now properly declare allowed-tools and use correct model settings

**From Phase 6 (Hook-Based Telemetry)** [executed]:
- telemetry.sh script and hook declarations: /build should declare telemetry hooks for its own execution
- Event types: skill_start, skill_end, agent_spawn, agent_complete, tool_use, tool_failure

**From Phase 7 (Metrics)** [discussed]:
- /metrics skill will read telemetry data: /build's execution generates telemetry if hooks are declared
- Threshold configuration in .planning/.telemetry/config.json

**Assumptions about prior phases:**
- All 14 existing skills are stable and functioning correctly
- Compaction resilience works reliably in execute-phase (Phase 1.4)
- Telemetry hooks capture events without interfering with execution (Phase 6)

---

## Implementation Decisions

### Skill Chain: Adaptive Pipeline Depth

**Decision:** LLM decides per-phase whether to run the full pipeline (discuss -> research -> plan -> execute) or skip discuss/research and go straight to plan -> execute. Simple phases (UI tweaks, config changes) skip; complex phases (auth, payments, data modeling) get the full treatment.

**Rationale:** Full pipeline for every phase is wasteful for simple phases but necessary for complex ones. LLM reasoning based on phase goal and domain complexity is the right granularity.

**Constraints:** /brainstorm always runs (before /create-roadmap). /map-codebase always runs for brownfield projects. Only discuss and research are skippable.

### Skill Chain: Always Brainstorm

**Decision:** Always run /brainstorm in autonomous mode after /new-project and before /create-roadmap.

**Rationale:** Brainstorming expands the idea with creative, architectural, and codebase-aware perspectives. The roadmap benefits from this richer context even for seemingly simple projects.

**Constraints:** Must use autonomous mode (not interactive). Must auto-approve all ideas.

### Skill Chain: Always Map Codebase

**Decision:** Always run /map-codebase when the target directory has existing code (brownfield detection).

**Rationale:** Codebase mapping produces ARCHITECTURE.md, STACK.md, etc. that all downstream skills consume for grounded decisions.

**Constraints:** Only for brownfield projects. Greenfield projects skip mapping.

### Skill Chain: Skill Tool Invocation

**Decision:** Invoke all chained skills via the Skill tool (same session, shared context). Context compaction handles window pressure.

**Rationale:** Single conversation thread is simpler to reason about and debug. Compaction resilience (BUILD-STATE.md + hooks) handles the primary risk of context loss.

**Constraints:** May iterate to hybrid (Skill tool + Task tool) in the future if context pressure becomes problematic. This is a v1 decision.

### Decision Logic: LLM Reasoning

**Decision:** Before each skill invocation, /build uses LLM reasoning to determine the best autonomous answer for each AskUserQuestion checkpoint, based on project context and build preferences.

**Rationale:** Hard-coded decision maps are brittle and break when skills add new questions. LLM reasoning is flexible and adapts to any question format.

**Constraints:** Uses tokens for reasoning. Must be guided by project context (PROJECT.md, ROADMAP.md) and build preferences.

### Decision Logic: Log and Continue on Ambiguity

**Decision:** When a decision is truly ambiguous (no clearly better option), /build picks the best guess via LLM reasoning and logs the decision in BUILD-STATE.md as "low confidence." User can review and override later via /phase-feedback.

**Rationale:** Full autonomy means never stopping for user input during the build. Logging low-confidence decisions provides transparency without blocking.

**Constraints:** Low-confidence decisions must be clearly marked in BUILD-STATE.md for post-build review.

### Decision Logic: Dynamic Input

**Decision:** /build accepts flexible input via $ARGUMENTS: inline idea string, file path to a PRD/vision document, a brief description document, or any combination. Auto-detect whether input is a file path (read and use as PRD) or a string (use as idea).

**Rationale:** Different projects start with different levels of preparation. A fitness app idea needs just a sentence; an enterprise SaaS may have a full PRD.

**Constraints:** File paths must exist and be readable. If both inline text and file path provided, both are passed to /new-project.

### Decision Logic: Build Preferences File

**Decision:** Build preferences stored in `build-preferences.md` at two locations: `~/.claude/build-preferences.md` (global defaults) and `.planning/build-preferences.md` (per-project overrides). Same filename at both locations. Project-level takes precedence where specified.

**Rationale:** Global preferences cover common choices (preferred stack, exec model). Per-project overrides allow deviation for specific projects.

**Constraints:** Structured markdown file with sections: tech stack, execution model, architecture style, coding style, etc. Both files optional -- /build works without either.

### Failure Modes: One Feedback Attempt

**Decision:** After a phase fails verification (gaps_found), /build runs one /phase-feedback cycle. If it still fails after the fix, mark the phase as incomplete and continue.

**Rationale:** One attempt catches most fixable issues. Multiple retries risk infinite loops on fundamentally broken phases.

**Constraints:** The single feedback attempt uses the standard path (plan + execute), not quick-fix.

### Failure Modes: Skip and Continue

**Decision:** When a phase fails after the feedback attempt, /build logs the failure in BUILD-STATE.md, marks the phase as "incomplete" in ROADMAP.md progress, and proceeds to the next phase.

**Rationale:** Downstream phases may or may not depend on the failed one. Stopping entirely wastes completed work. Skipping allows maximum progress; the user can fix failures post-build.

**Constraints:** BUILD-STATE.md must clearly indicate which phases are incomplete and why. Final build report must highlight skipped phases.

### Failure Modes: Adaptive Validation

**Decision:** LLM judges which phases warrant build/test validation after execution. Code-producing phases get validated; planning-only or documentation phases do not.

**Rationale:** Running build/tests after every phase adds overhead and may fail early when the project isn't buildable until later phases (e.g., no package.json until phase 2).

**Constraints:** Validation always runs after the final phase regardless. Early-phase validation only when the project has a buildable state.

### Failure Modes: Auto-Fix on Final Failure

**Decision:** If the final build/test validation fails after all phases complete, /build spawns a fix agent that reads errors, proposes fixes, applies them, and re-runs build/tests. Limited to 3 attempts.

**Rationale:** Getting to the finish line with a broken build defeats the purpose. An auto-fix loop is the last line of defense before reporting to the user.

**Constraints:** 3 attempt limit prevents infinite loops. After 3 failures, report the errors and let the user handle it.

### Scope: Git Autonomy

**Decision:** /build is fully git-autonomous with local-only operations. It creates a feature branch per phase execution, auto-commits during execution, squash-merges the feature branch to main on phase completion, and never pushes to origin.

**Rationale:** Feature branches isolate phase work. Squash-merge keeps main clean with one commit per phase. Local-only avoids any risk of pushing incomplete/broken code.

**Constraints:**
- Planning work (discuss, research, plan) happens on main and is committed before execution starts
- Each phase execution creates `build/{phase-name}` branch
- On phase completion: squash-merge to main, delete feature branch
- Never run `git push`

### Scope: Auto-Resume

**Decision:** /build auto-resumes from BUILD-STATE.md on re-invocation. If BUILD-STATE.md exists and shows incomplete phases, resume from where it left off with no duplicate work.

**Rationale:** Long builds across many phases will inevitably hit context limits or session interruptions. Auto-resume makes /build resilient to interruptions.

**Constraints:** BUILD-STATE.md must be accurate and up-to-date. Must detect completed vs in-progress vs not-started phases. Must not re-execute completed phases.

### Scope: Current Directory Only

**Decision:** /build always operates in the current working directory.

**Rationale:** Simplicity. User controls the target by cd-ing to it before running /build.

**Constraints:** Directory must exist and be writable. /build does not create directories.

---

## Claude's Discretion

- BUILD-STATE.md format and structure (what fields to track, how to organize sections)
- build-preferences.md structure and sections (tech stack, exec model, architecture style, coding style -- exact field names and format)
- How to detect whether $ARGUMENTS contains a file path vs inline text (heuristic design)
- Adaptive pipeline depth heuristic: what makes a phase "complex enough" for discuss/research vs "simple enough" to skip
- Adaptive validation heuristic: when a phase produces enough code to warrant build/test validation
- Feature branch naming convention (e.g., `build/01-foundation` vs `build/phase-1`)
- Squash-merge commit message format
- How /build interacts with skills that have their own AskUserQuestion calls -- whether to pre-answer or handle inline
- Hook structure for /build's own compaction resilience
- Whether to generate a final BUILD-REPORT.md summarizing the entire build journey

---

## Specific Ideas

- Input handling: if `$ARGUMENTS` starts with `/` or `./` or `~`, check if it's a file. If readable, use as PRD. Otherwise treat entire string as idea.
- Git flow: `main` -> commit planning artifacts -> `git checkout -b build/01-foundation` -> execute -> squash-merge -> `git checkout -b build/02-auth` -> execute -> squash-merge -> ...
- BUILD-STATE.md should track: session start time, current pipeline stage, phases completed (with timestamps), phases skipped (with reasons), low-confidence decisions, current git branch, total feedback loops used
- build-preferences.md sections: `## Tech Stack`, `## Execution Model`, `## Architecture Style`, `## Coding Style`, `## Testing Strategy`, `## Git Preferences`
- The adaptive pipeline depth decision could check: does the phase goal mention a new domain (auth, payments, search)? If yes, run full pipeline. Does it mention "add", "update", "fix" existing patterns? If yes, skip discuss/research.

---

## Deferred Ideas

- Hybrid invocation (Skill tool + Task tool): May be needed if context pressure becomes unmanageable in v1. Revisit after initial implementation and testing.
- Parallel phase execution: Some phases may be independent and could run in parallel. Not in v1 -- sequential is simpler and sufficient.
- Remote git operations: /build could optionally push to origin and create PRs. Deferred as local-only is safer for autonomous execution.
- Target directory argument: /build could accept `--dir` to create and work in a specified directory. Deferred for simplicity.
- Build profiles: Pre-defined configurations for common project types (Next.js SaaS, CLI tool, API server). Deferred until build-preferences.md patterns stabilize.

---
