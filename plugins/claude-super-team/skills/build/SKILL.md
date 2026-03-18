---
name: build
description: "Autonomously build an entire application from idea to working code. Chains all claude-super-team skills (/new-project, /brainstorm, /create-roadmap, per-phase discuss/research/plan/execute) with zero user intervention. Maintains BUILD-STATE.md for compaction resilience and auto-resume. Makes autonomous decisions at every checkpoint using LLM reasoning and build preferences. Multi-phase sprints execute in parallel via team+worktrees (one teammate per phase in isolated worktrees), with sequential fallback. Self-validates with bounded retry loops."
argument-hint: "<project idea OR path to PRD file>"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion, Agent, TeamCreate, TeamDelete, SendMessage, TaskCreate, TaskUpdate, TaskList, TaskGet, TaskOutput, TaskStop, Bash(git *), Bash(mkdir *), Bash(ls *), Bash(test *), Bash(npm *), Bash(npx *), Bash(bun *), Bash(pnpm *), Bash(yarn *), Bash(cargo *), Bash(go *), Bash(make *), Bash(python *), Bash(pytest *), Bash(find *), Bash(grep *), Bash(cat *), Bash(bash *gather-data.sh), Bash(chmod *)
hooks:
  PreCompact:
    - matcher: "auto"
      hooks:
        - type: command
          command: 'echo "BUILD STATE TO PRESERVE:"; cat .planning/BUILD-STATE.md 2>/dev/null || echo "No build state found"'
  SessionStart:
    - matcher: "compact"
      hooks:
        - type: command
          command: 'echo "=== BUILD STATE (resume from here) ==="; cat .planning/BUILD-STATE.md 2>/dev/null || echo "No build state found"; echo "=== RUN Step 0 to reload full context ==="'
---

## Step 0: Load Context

Run the gather script to load build state, preferences, git status, and planning files:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/build/gather-data.sh"
```

Parse the output sections (BUILD_STATE, PREFERENCES, BUILD_PREFERENCES, GIT, PROJECT, BROWNFIELD) before proceeding.

### Context-Aware Gathering

After Step 0 completes, PROJECT.md, ROADMAP.md, and STATE.md are in your conversation context. When child skills (invoked via `Skill()`) run their own `gather-data.sh` in their Step 0, these files would be re-dumped redundantly, wasting context tokens.

**Rule:** When a child skill's Step 0 runs `bash "${CLAUDE_PLUGIN_ROOT}/skills/.../gather-data.sh"`, prefix it with skip flags for files already in context:

```bash
SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/.../gather-data.sh"
```

This applies to all child skill invocations throughout the build pipeline (Steps 5-9). It also applies after compaction resume: once you've re-read the core files in Step 0, use skip flags for all subsequent `gather-data.sh` calls.

Only skip files that are genuinely in your current context. If ROADMAP.md was just modified by a child skill (e.g., `/create-roadmap`), do NOT skip it on the next invocation -- you need the updated version.

## AUTONOMOUS OPERATION -- CRITICAL INSTRUCTION

**YOU ARE RUNNING IN FULLY AUTONOMOUS MODE.**

This skill builds an entire application without user intervention. You MUST follow these rules at ALL times:

1. **NEVER present AskUserQuestion to the user.** When ANY skill (including child skills invoked via Skill tool) triggers AskUserQuestion, YOU answer it autonomously using the decision framework in `${CLAUDE_SKILL_DIR}/references/autonomous-decision-guide.md`. Select the best option, log the decision in BUILD-STATE.md, and continue.

2. **NEVER stop to ask the user for input.** Every decision point has a resolution path: preferences file, project context, prior decisions, or best-guess with low-confidence logging.

3. **NEVER abort the pipeline.** If a phase fails, mark it incomplete and continue to the next phase. If a skill errors, log the error and skip that step. The only valid stop condition is: all phases processed and final report generated.

4. **ALWAYS update BUILD-STATE.md before and after each skill invocation.** This is your recovery mechanism. If context compaction occurs, BUILD-STATE.md is re-injected and you resume from the last recorded position.

5. **After context compaction:** Read BUILD-STATE.md to determine current position. Read `${CLAUDE_SKILL_DIR}/references/autonomous-decision-guide.md` for decision framework. Resume from the `in_progress` stage in Pipeline Progress or Phase Progress.

6. **IGNORE child skill "Next Steps" output.** When a child skill completes, it may output a "Next Steps" section with user-facing directives (e.g., "Run /plan-phase", "Begin with Phase 1", "Run /execute-phase"). These directives are for standalone interactive use. In /build, ALWAYS ignore them and continue to the next step in THIS pipeline. The child skill's completion is informational only -- it does NOT alter your control flow.

---

## Objective

Build a complete application from a project idea or PRD to working, validated code -- fully autonomously.

**Pipeline:** Input detection -> /new-project -> [/map-codebase] -> /brainstorm -> /create-roadmap -> For each sprint: { discuss all phases (sequential) -> research phases (parallel, dependency-aware) -> plan all phases (parallel) -> execute all phases (parallel via team+worktrees, or sequential fallback) -> merge each -> sprint boundary validation } -> Final validation -> [auto-fix] -> BUILD-REPORT.md -> [completion audit] -> Summary

**Reads:** $ARGUMENTS (idea or file path), `~/.claude/build-preferences.md`, `.planning/build-preferences.md`, `.planning/BUILD-STATE.md` (for resume)
**Creates:** All `.planning/` artifacts, application source code, `.planning/BUILD-STATE.md`, `.planning/BUILD-REPORT.md`

**Key behaviors:**
- Invokes all skills via the Skill tool (same session, shared context)
- Makes autonomous decisions at every AskUserQuestion checkpoint
- Maintains BUILD-STATE.md for compaction resilience and auto-resume
- Sprint-based execution: groups phases by sprint, plans in parallel, executes in parallel (team+worktrees) or sequentially (fallback)
- Multi-phase sprints: one teammate per phase in isolated worktrees, parallel execution, squash-merge to main
- Single-phase sprints: direct Skill invocation (no team overhead)
- Adaptive pipeline depth: skips discuss/research for simple phases
- Adaptive validation: per-phase + sprint boundary + final validation
- One feedback attempt per failed phase, then skip and continue
- 3-attempt auto-fix loop on final build/test failure
- Completion audit: scans for gaps after report generation, bounded remediation (max 2 cycles)

---

## Process

### Step 1: Detect Resume, Extend, or Fresh Start

Check the BUILD_STATE and EXTEND sections from the gather-data.sh output.

**Branch 1 -- RESUME: BUILD-STATE.md EXISTS and Status is `in_progress`:**

This is a RESUME. Read BUILD-STATE.md fully:

```
Read('.planning/BUILD-STATE.md')
```

1. Determine current position from the Pipeline Progress, Sprint Progress, and Phase Progress tables.
2. Find the first row with status `in_progress` -- that is where to resume. For sprint-based execution, the `Current stage` field indicates which sprint and substage to resume from (e.g., `sprint-2-execute`).
3. Read the `Compaction count` field. Increment it by 1 and write back to BUILD-STATE.md.
4. **Reconcile stale state:** Use the PHASE_COMPLETION section from gather-data.sh to sync ROADMAP.md and STATE.md with filesystem reality. For each phase with status `complete` in PHASE_COMPLETION that isn't marked `[x]` in ROADMAP.md, update ROADMAP.md (checkbox + progress table) and STATE.md (current position). This ensures planning files are accurate before resuming.
5. **Rebuild SPRINT_MAP:** Re-parse sprint groupings from ROADMAP.md (same logic as Step 8). This is needed after compaction since the in-memory sprint map is lost.
6. Check if `build/*` branch(es) or worktree branches exist (from gather-data.sh GIT section `BUILD_BRANCHES` and `git worktree list`):
   - If `build/*` branches exist (sequential mode): identify which sprint they belong to from the Sprint Progress table.
     - For each branch, check if execution completed: do SUMMARY.md files exist for all plans in the phase directory?
       - If yes: squash-merge the branch to main (see Step 9g-sequential-iii) and continue.
       - If no: checkout the branch and resume execution from Step 9f-sequential.
   - If worktree branches exist under `.claude/worktrees/sprint-*` (parallel mode was interrupted):
     - For each worktree, check if SUMMARY.md files exist for the phase.
       - If yes: squash-merge the worktree branch to main (see Step 9g-parallel-ii) and continue.
       - If no: log as incomplete. The worktree teammate context is lost on resume, so re-executing in the worktree is not possible. Merge whatever was committed, mark phase as incomplete.
     - Clean up stale worktrees: `git worktree remove <path> 2>/dev/null`
   - After handling all branches for the current sprint, proceed to sprint boundary validation (Step 9h) if all phases are merged.
7. Re-read `${CLAUDE_SKILL_DIR}/references/autonomous-decision-guide.md` for the decision framework (it may have been lost to compaction).
8. Apply context-aware gathering: since Step 0 re-loaded core files, use `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1` when child skills run their `gather-data.sh`.
9. Skip to the appropriate step below based on current position.
10. Print: `Resuming build from {current_stage}. Compaction count: {N}.`

**Branch 2 -- EXTEND: `EXTEND_CANDIDATE=true` AND $ARGUMENTS is non-empty:**

This is an EXTEND. A prior build completed successfully and the user is adding a new feature. Skip to Step 1-E.

**Branch 2a -- AUTO-EXTEND: `AUTO_EXTEND=true` from gather-data.sh AND $ARGUMENTS is non-empty:**

This is an AUTO-EXTEND. PROJECT.md and ROADMAP.md exist but there is no BUILD-STATE.md -- the project was set up outside of /build (e.g., manually or via individual skills). Print: `Auto-extend mode: existing project detected, adding feature.` Then skip to Step 1-E (same extend entry point as Branch 2). The extend flow will create a fresh BUILD-STATE.md and invoke /create-roadmap in extend mode to append new phases.

**Branch 2b -- PARTIAL PROJECT: `PARTIAL_PROJECT=true` from gather-data.sh AND $ARGUMENTS is non-empty:**

This is a PARTIAL PROJECT. PROJECT.md exists but there is no ROADMAP.md or BUILD-STATE.md -- the user started project definition but did not complete the full pipeline. Print: `Partial project detected: skipping /new-project, starting from brainstorm.` Then continue to Step 3 (Load Preferences). In Step 4 (Initialize BUILD-STATE.md), set the `new-project` pipeline row to `skipped` with Notes "Pre-existing PROJECT.md". In Step 5, check: since `HAS_PROJECT=true` from gather-data.sh, skip the /new-project invocation entirely -- set the pipeline row to `skipped` (if not already) and continue directly to Step 6. The pipeline proceeds normally from Step 7 (/brainstorm) onward.

**Branch 3 -- FRESH START: Everything else (BUILD-STATE.md does not exist, or Status is `complete`/`failed` without extend conditions):**

This is a FRESH START. Continue to Step 2.

If a stale BUILD-STATE.md exists (status `complete` or `failed`), note it in the output and start fresh.

---

### Step 1-E: Extend Mode Entry

Print: `Extend mode: adding feature to existing project.`

1. Read the previous BUILD-STATE.md to capture prior phase count and decisions:
   ```
   Read('.planning/BUILD-STATE.md')
   ```
2. Record the set of already-completed phases from the PHASE_COMPLETION section of gather-data.sh output. These phases will be skipped in the execution loop.
3. Read the autonomous decision guide for the decision framework:
   ```
   Read('${CLAUDE_SKILL_DIR}/references/autonomous-decision-guide.md')
   ```
   (Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/references/autonomous-decision-guide.md`)
4. Skip to Step 4-E.

---

### Step 2: Parse Input

Read $ARGUMENTS. Use the file path detection heuristic from `${CLAUDE_SKILL_DIR}/references/pipeline-guide.md` Section 4:

1. Split $ARGUMENTS on whitespace into tokens.
2. For each token, check if it is a potential file path:
   - Starts with `/`, `./`, `~/`, or `../` -> potential path
   - Ends with `.md`, `.txt`, `.doc`, `.pdf`, `.rtf` -> potential path
   - Contains `/` and does not start with `http` -> potential path
3. For each potential path, verify existence:
   ```bash
   test -f "$token"
   ```
   For `~` paths:
   ```bash
   test -f "$HOME/${token#\~/}"
   ```
4. Classify results:
   - **File(s) found, no remaining text:** Read file contents. Use as PRD/vision.
   - **File(s) found, plus remaining text:** Read file contents as PRD. Join remaining tokens as supplementary context.
   - **No files found:** Entire $ARGUMENTS is the project idea string.
   - **Empty $ARGUMENTS:** Error.

Set variables:
- `$IDEA_TEXT` -- the inline text portion (may be empty if only a file path)
- `$PRD_PATH` -- the file path (if any)
- `$PRD_CONTENT` -- the file contents (if path found)

If multiple file paths: read and concatenate all files, separated by `---` markers with filenames.
If a file is very large (> 50KB): read first 50KB, note truncation in BUILD-STATE.md.

**If $ARGUMENTS is empty or not provided:**

```
ERROR: /build requires a project idea or path to a PRD file.
Usage: /build <project idea> or /build ./path/to/prd.md
If you have an existing project, provide the feature you want to add.
```

Stop execution.

---

### Step 3: Load Preferences

Read build preferences from both locations (if they exist). These are in the BUILD_PREFERENCES section of the gather-data.sh output.

1. **Global preferences:** `~/.claude/build-preferences.md` (from `GLOBAL_PREFS` in BUILD_PREFERENCES section)
2. **Project preferences:** `.planning/build-preferences.md` (from `PROJECT_PREFS` in BUILD_PREFERENCES section)

If project-level exists, it takes precedence for any overlapping fields. Merge into a unified preference context:

- `$PREF_EXEC_MODEL` -- execution model preference (opus or sonnet). Default: opus.
- `$PREF_TECH_STACK` -- tech stack preferences (if specified).
- `$PREF_ARCH_STYLE` -- architecture style (if specified).
- `$PREF_TESTING` -- testing strategy (if specified).
- `$PREF_VERIFICATION` -- verification preference (always, on-failure, or disabled). Default: on-failure.

If neither file exists, proceed with no preferences. LLM reasoning handles all decisions using project context alone.

Print: `Build preferences: {source summary or "None found -- using LLM reasoning for all decisions"}`

---

### Step 4: Initialize BUILD-STATE.md

Read the template:

```
Read('${CLAUDE_SKILL_DIR}/assets/build-state-template.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/assets/build-state-template.md`)

Populate the Session section:
- **Started:** run `date "+%Y-%m-%d %H:%M"` to get the real timestamp
- **Input:** $IDEA_TEXT (or first line of $PRD_CONTENT if file-only input)
- **Input source:** inline | file | both
- **Status:** in_progress
- **Current stage:** input-detection
- **Current phase:** N/A
- **Git main branch:** current branch from gather-data.sh `BRANCH` value (or "main" if not available)
- **Compaction count:** 0

Populate the Build Preferences section from Step 3 resolved values.

Set Pipeline Progress "input-detection" row to `complete`, with `Started` and `Completed` set to the current timestamp (HH:MM).

**Timestamp convention:** Throughout the entire build, whenever you update a Pipeline Progress or Phase Progress row to `in_progress`, record the current time in the `Started` column (HH:MM format). When you update a row to `complete`, `skipped`, or `failed`, record the current time in the `Completed` column. This applies to all steps below. **You do not have a clock. NEVER guess or fabricate timestamps.** Always get the real time by running:

```bash
date "+%Y-%m-%d %H:%M"
```

Use the full output for `YYYY-MM-DD HH:MM` fields and the `%H:%M` portion for `HH:MM` fields. Run this command every time you need a timestamp -- do not reuse a previously fetched value if more than a few seconds have passed.

Write to `.planning/BUILD-STATE.md`:

```
Write('.planning/BUILD-STATE.md', populated_template)
```

If `$PREF_VERIFICATION` was resolved from preferences, persist it to STATE.md under `## Preferences`:
```markdown
verification: {$PREF_VERIFICATION}
```
Use Edit tool to update STATE.md. If the preference line already exists, update it. If not, add it below the existing preferences.

Print: `BUILD-STATE.md initialized. Starting autonomous build pipeline.`

---

### Step 4-E: Initialize BUILD-STATE.md for Extend

Read the template:

```
Read('${CLAUDE_SKILL_DIR}/assets/build-state-template.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/assets/build-state-template.md`)

Populate the Session section:
- **Started:** run `date "+%Y-%m-%d %H:%M"` to get the real timestamp
- **Input:** $ARGUMENTS (the new feature description)
- **Input source:** extend
- **Build mode:** extend
- **Status:** in_progress
- **Current stage:** create-roadmap
- **Current phase:** N/A
- **Git main branch:** current branch from gather-data.sh `BRANCH` value (or "main" if not available)
- **Compaction count:** 0

Populate the Build Preferences section from Step 3 resolved values.

Set Pipeline Progress rows:
- `input-detection`: `skipped`, Notes: "Extend mode"
- `new-project`: `skipped`, Notes: "Extend mode"
- `map-codebase`: `skipped`, Notes: "Extend mode"
- `brainstorm`: `skipped`, Notes: "Extend mode"
- `create-roadmap`: `pending`

Write to `.planning/BUILD-STATE.md`:

```
Write('.planning/BUILD-STATE.md', populated_template)
```

Print: `BUILD-STATE.md initialized (extend mode). Skipping to roadmap update.`

Skip to Step 8-E.

---

### Step 5: Invoke /new-project

Read the autonomous decision guide for the decision framework that governs all AskUserQuestion handling:

```
Read('${CLAUDE_SKILL_DIR}/references/autonomous-decision-guide.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/references/autonomous-decision-guide.md`)

Update BUILD-STATE.md: set Pipeline Progress "new-project" row to `in_progress`, set Current stage to `new-project`.

Compose the input for /new-project. If $PRD_CONTENT exists, pass it. Otherwise pass $IDEA_TEXT:

```
Skill('new-project', '{$IDEA_TEXT or $PRD_CONTENT}')
```

The /new-project skill will ask several AskUserQuestion questions. Answer ALL of them autonomously per the decision guide:

- **Brownfield detection ("Map codebase first?"):** Always answer **"Skip mapping"** -- /build handles /map-codebase independently in Step 6.
- **Exploration questions ("Keep exploring" vs "Create PROJECT.md"):** Answer 2-3 rounds of exploration, then select **"Create PROJECT.md"** / **"All set"** to move forward.
- **Exec model preference:** Use $PREF_EXEC_MODEL from build preferences. If unset, default to **opus**.

Log each autonomous decision in BUILD-STATE.md Decisions Log table.

After /new-project completes, verify:

```bash
test -f .planning/PROJECT.md
```

If `.planning/PROJECT.md` does not exist, log the error in BUILD-STATE.md Errors section and stop:

```
FATAL: /new-project did not create PROJECT.md. Cannot continue.
```

Update BUILD-STATE.md: set Pipeline Progress "new-project" row to `complete`.

---

### Step 6: Invoke /map-codebase (Brownfield Only)

Check brownfield status from gather-data.sh output: the `CODE_FILES` value in the BROWNFIELD section.

**If CODE_FILES > 0 (brownfield):**

1. Update BUILD-STATE.md: set Pipeline Progress "map-codebase" row to `in_progress`, set Current stage to `map-codebase`.
2. Invoke:
   ```
   Skill('map-codebase')
   ```
3. Answer any AskUserQuestion calls autonomously per the decision guide:
   - **Mode question:** Select **"Full map"** on first run. Select **"Refresh"** if `.planning/codebase/` already has docs.
4. Log decisions in BUILD-STATE.md Decisions Log.
5. Update BUILD-STATE.md: set Pipeline Progress "map-codebase" row to `complete`.

**If CODE_FILES = 0 (greenfield):**

Update BUILD-STATE.md: set Pipeline Progress "map-codebase" row to `skipped`, Notes: "Greenfield project".

Continue to Step 7.

---

### Step 7: Invoke /brainstorm (Autonomous Mode)

Update BUILD-STATE.md: set Pipeline Progress "brainstorm" row to `in_progress`, set Current stage to `brainstorm`.

Invoke:

```
Skill('brainstorm')
```

Answer AskUserQuestion calls autonomously per the decision guide:

- **Mode question:** Select **"Autonomous"** (locked decision -- brainstorm always runs in autonomous mode during /build).
- **Review ideas / Approve all:** Select **"Approve all"**. Move forward. Ideas are captured in IDEAS.md for reference.
- **Update roadmap?:** Select **"Add to roadmap"** / **"Yes"**.

Log each decision in BUILD-STATE.md Decisions Log.

After completion, update BUILD-STATE.md: set Pipeline Progress "brainstorm" row to `complete`.

---

### Step 8: Invoke /create-roadmap

Update BUILD-STATE.md: set Pipeline Progress "create-roadmap" row to `in_progress`, set Current stage to `create-roadmap`.

Invoke:

```
Skill('create-roadmap')
```

Answer any AskUserQuestion calls autonomously per the decision guide:

- **Phase count / structure:** Accept the LLM's recommended roadmap structure.
- **Confirm roadmap:** Accept / Approve.

Log decisions in BUILD-STATE.md Decisions Log.

**IMPORTANT: /create-roadmap will output a "Next Steps" section telling you to run /plan-phase or /discuss-phase. IGNORE IT -- those directives are for standalone use. You MUST continue with the post-completion steps below. Do NOT stop, do NOT present "Next Steps" to the user.**

After completion, verify:

```bash
test -f .planning/ROADMAP.md
```

If ROADMAP.md does not exist, log error and stop:

```
FATAL: /create-roadmap did not create ROADMAP.md. Cannot continue.
```

Read ROADMAP.md to determine the list of phases:

```
Read('.planning/ROADMAP.md')
```

Extract phase numbers, names, goals, success criteria, and **sprint assignments** from the roadmap.

### Sprint Grouping

Parse sprint assignments from ROADMAP.md. Each phase has a `**Sprint**: N` field in its Phase Details block and a `[Sprint N]` annotation in the Phases checklist. Build the sprint map:

```
SPRINT_MAP = { sprint_number: [phase_numbers] }
```

**Backward compatibility:** If no sprint annotations are found in ROADMAP.md (legacy roadmaps without sprints), treat each phase as its own single-phase sprint: `SPRINT_MAP = { 1: [1], 2: [2], 3: [3], ... }`. This preserves sequential behavior.

Print sprint overview:
```
Sprint plan:
  Sprint 1: Phase 1, Phase 2 (2 phases)
  Sprint 2: Phase 3, Phase 4, Phase 5 (3 phases)
  Sprint 3: Phase 6 (1 phase)
```

Classify the project complexity. Read the phase list from ROADMAP.md:
- Count total phases
- For each phase, count success criteria
- Count phases mentioning external service integration
- Check for real-time features or distributed systems

If ANY: total phases >= 8, any phase has >= 5 success criteria, >= 3 phases mention external integrations, or project involves real-time/distributed: `COMPLEXITY_CLASS = complex`. Otherwise: `COMPLEXITY_CLASS = standard`.

Log in BUILD-STATE.md under Session: `Complexity class: {standard|complex}`.

Update BUILD-STATE.md:
- Set Pipeline Progress "create-roadmap" row to `complete`.
- Populate the Phase Progress table with one row per phase from ROADMAP.md. Include the Sprint column from SPRINT_MAP. All step columns set to `pending`, `Started` and `Completed` set to `-`.
- Populate the Sprint Progress table with one row per sprint from SPRINT_MAP: Phases lists the phase numbers, Status set to `pending`, Boundary Validation set to `-`, Started and Completed set to `-`.
- Set Current stage to `sprint-execution`.

---

### Step 8-E: Invoke /create-roadmap (Extend Mode)

### Step 9: Sprint Execution Loop

Read the sprint execution guide for Step 8-E (extend-mode roadmap creation) and the complete sprint execution loop:

```
Read('${CLAUDE_SKILL_DIR}/references/sprint-execution-guide.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/references/sprint-execution-guide.md`)

**Step 8-E** covers extend-mode /create-roadmap invocation, sprint map rebuild, and phase progress initialization for extend builds. After completion, continue to Step 9.

**Step 9** is the core execution loop. Follow it for each sprint in SPRINT_MAP. It covers:
- 9-pre: Skip completed sprints
- 9a-9c: Sprint setup, adaptive pipeline depth, discuss (sequential) + research (parallel)
- 9d: Plan all sprint phases (parallel)
- 9e: Commit planning artifacts and prepare for execution
- 9f: Execute sprint phases (parallel via team+worktrees for multi-phase, sequential fallback)
- 9g: Per-phase merge, validation (parallel: teammate-side), feedback, state sync (9g-i through 9g-v)
- 9h: Sprint boundary validation
- 9i: Complete sprint

After the sprint execution loop completes (all sprints processed), continue to Steps 10-13 below.

---

### Steps 10-13: Finalization

Read the finalization guide for the complete end-of-pipeline procedure:

```
Read('${CLAUDE_SKILL_DIR}/references/finalization-guide.md')
```

Follow the finalization guide. It covers:
- Step 10: Final validation (always run build + tests after all phases)
- Step 11: Auto-fix loop (max 3 attempts on failure)
- Step 12: Generate BUILD-REPORT.md from BUILD-STATE.md data
- Step 12.5: Completion audit (scan for gaps, bounded remediation -- max 2 cycles)
- Step 13: Present completion summary to user
- Success criteria checklist

**END OF PROCESS.**
