---
name: build
description: "Autonomously build an entire application from idea to working code. Chains all claude-super-team skills (/new-project, /brainstorm, /create-roadmap, per-phase discuss/research/plan/execute) with zero user intervention. Maintains BUILD-STATE.md for compaction resilience and auto-resume. Makes autonomous decisions at every checkpoint using LLM reasoning and build preferences. Manages git branches per phase with squash-merge to main. Self-validates with bounded retry loops."
argument-hint: "<project idea OR path to PRD file>"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion, Bash(git *), Bash(mkdir *), Bash(ls *), Bash(test *), Bash(npm *), Bash(npx *), Bash(bun *), Bash(pnpm *), Bash(yarn *), Bash(cargo *), Bash(go *), Bash(make *), Bash(python *), Bash(pytest *), Bash(find *), Bash(grep *), Bash(cat *), Bash(bash *gather-data.sh), Bash(chmod *)
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

Parse the output sections (BUILD_STATE, PREFERENCES, GIT, PROJECT, BROWNFIELD) before proceeding.

## AUTONOMOUS OPERATION -- CRITICAL INSTRUCTION

**YOU ARE RUNNING IN FULLY AUTONOMOUS MODE.**

This skill builds an entire application without user intervention. You MUST follow these rules at ALL times:

1. **NEVER present AskUserQuestion to the user.** When ANY skill (including child skills invoked via Skill tool) triggers AskUserQuestion, YOU answer it autonomously using the decision framework in `references/autonomous-decision-guide.md`. Select the best option, log the decision in BUILD-STATE.md, and continue.

2. **NEVER stop to ask the user for input.** Every decision point has a resolution path: preferences file, project context, prior decisions, or best-guess with low-confidence logging.

3. **NEVER abort the pipeline.** If a phase fails, mark it incomplete and continue to the next phase. If a skill errors, log the error and skip that step. The only valid stop condition is: all phases processed and final report generated.

4. **ALWAYS update BUILD-STATE.md before and after each skill invocation.** This is your recovery mechanism. If context compaction occurs, BUILD-STATE.md is re-injected and you resume from the last recorded position.

5. **After context compaction:** Read BUILD-STATE.md to determine current position. Read `references/autonomous-decision-guide.md` for decision framework. Resume from the `in_progress` stage in Pipeline Progress or Phase Progress.

---

## Objective

Build a complete application from a project idea or PRD to working, validated code -- fully autonomously.

**Pipeline:** Input detection -> /new-project -> [/map-codebase] -> /brainstorm -> /create-roadmap -> For each phase: [/discuss-phase] -> [/research-phase] -> /plan-phase -> /execute-phase -> [validate] -> [/phase-feedback] -> git merge -> Final validation -> [auto-fix] -> BUILD-REPORT.md

**Reads:** $ARGUMENTS (idea or file path), `~/.claude/build-preferences.md`, `.planning/build-preferences.md`, `.planning/BUILD-STATE.md` (for resume)
**Creates:** All `.planning/` artifacts, application source code, `.planning/BUILD-STATE.md`, `.planning/BUILD-REPORT.md`

**Key behaviors:**
- Invokes all skills via the Skill tool (same session, shared context)
- Makes autonomous decisions at every AskUserQuestion checkpoint
- Maintains BUILD-STATE.md for compaction resilience and auto-resume
- Creates feature branch per phase execution, squash-merges to main
- Adaptive pipeline depth: skips discuss/research for simple phases
- Adaptive validation: only validates code-producing phases (always validates final)
- One feedback attempt per failed phase, then skip and continue
- 3-attempt auto-fix loop on final build/test failure

---

## Process

### Step 1: Detect Resume vs Fresh Start

Check the BUILD_STATE section from the gather-data.sh output.

**If BUILD-STATE.md EXISTS and Status is `in_progress`:**

This is a RESUME. Read BUILD-STATE.md fully:

```
Read('.planning/BUILD-STATE.md')
```

1. Determine current position from the Pipeline Progress and Phase Progress tables.
2. Find the first row with status `in_progress` -- that is where to resume.
3. Read the `Compaction count` field. Increment it by 1 and write back to BUILD-STATE.md.
4. **Reconcile stale state:** Use the PHASE_COMPLETION section from gather-data.sh to sync ROADMAP.md and STATE.md with filesystem reality. For each phase with status `complete` in PHASE_COMPLETION that isn't marked `[x]` in ROADMAP.md, update ROADMAP.md (checkbox + progress table) and STATE.md (current position). This ensures planning files are accurate before resuming.
5. Check if a `build/*` branch exists (from gather-data.sh GIT section `BUILD_BRANCHES`):
   - If a `build/*` branch exists, handle resume:
     - Check if execution completed on that branch: do SUMMARY.md files exist for all plans in the phase directory?
     - If yes: squash-merge the branch to main (see Step 9j) and continue to the next phase.
     - If no: checkout the branch and resume execution from Step 9g.
6. Re-read `references/autonomous-decision-guide.md` for the decision framework (it may have been lost to compaction).
7. Skip to the appropriate step below based on current position.
8. Print: `Resuming build from {current_stage}. Compaction count: {N}.`

**If BUILD-STATE.md does NOT exist or Status is `complete` or `failed`:**

This is a FRESH START. Continue to Step 2.

If a stale BUILD-STATE.md exists (status `complete` or `failed`), note it in the output and start fresh.

---

### Step 2: Parse Input

Read $ARGUMENTS. Use the file path detection heuristic from `references/pipeline-guide.md` Section 4:

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
```

Stop execution.

---

### Step 3: Load Preferences

Read build preferences from both locations (if they exist). These are in the PREFERENCES section of the gather-data.sh output.

1. **Global preferences:** `~/.claude/build-preferences.md` (from `GLOBAL_PREFS` in gather-data.sh output)
2. **Project preferences:** `.planning/build-preferences.md` (from `PROJECT_PREFS` in gather-data.sh output)

If project-level exists, it takes precedence for any overlapping fields. Merge into a unified preference context:

- `$PREF_EXEC_MODEL` -- execution model preference (opus or sonnet). Default: opus.
- `$PREF_TECH_STACK` -- tech stack preferences (if specified).
- `$PREF_ARCH_STYLE` -- architecture style (if specified).
- `$PREF_TESTING` -- testing strategy (if specified).

If neither file exists, proceed with no preferences. LLM reasoning handles all decisions using project context alone.

Print: `Build preferences: {source summary or "None found -- using LLM reasoning for all decisions"}`

---

### Step 4: Initialize BUILD-STATE.md

Read the template:

```
Read('assets/build-state-template.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/assets/build-state-template.md`)

Populate the Session section:
- **Started:** current timestamp (YYYY-MM-DD HH:MM)
- **Input:** $IDEA_TEXT (or first line of $PRD_CONTENT if file-only input)
- **Input source:** inline | file | both
- **Status:** in_progress
- **Current stage:** input-detection
- **Current phase:** N/A
- **Git main branch:** current branch from gather-data.sh `BRANCH` value (or "main" if not available)
- **Compaction count:** 0

Populate the Build Preferences section from Step 3 resolved values.

Set Pipeline Progress "input-detection" row to `complete`, with `Started` and `Completed` set to the current timestamp (HH:MM).

**Timestamp convention:** Throughout the entire build, whenever you update a Pipeline Progress or Phase Progress row to `in_progress`, record the current time in the `Started` column (HH:MM format). When you update a row to `complete`, `skipped`, or `failed`, record the current time in the `Completed` column. This applies to all steps below.

Write to `.planning/BUILD-STATE.md`:

```
Write('.planning/BUILD-STATE.md', populated_template)
```

Print: `BUILD-STATE.md initialized. Starting autonomous build pipeline.`

---

### Step 5: Invoke /new-project

Read the autonomous decision guide for the decision framework that governs all AskUserQuestion handling:

```
Read('references/autonomous-decision-guide.md')
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

Extract phase numbers, names, goals, and success criteria from the roadmap.

Update BUILD-STATE.md:
- Set Pipeline Progress "create-roadmap" row to `complete`.
- Populate the Phase Progress table with one row per phase from ROADMAP.md. All step columns set to `pending`, `Started` and `Completed` set to `-`.
- Set Current stage to `phase-execution`.

---

### Step 9: Phase Execution Loop

For each phase N in ROADMAP.md (sequential, in order):

#### 9a. Update BUILD-STATE.md

Set `Current phase` to N. Set `Current stage` to `phase-{N}-pipeline`.

Set the Phase Progress row's `Started` column to the current time (HH:MM).

Write BUILD-STATE.md.

Print: `Starting phase {N}: {phase_name}`

#### 9b. Adaptive Pipeline Depth Decision

Read `references/pipeline-guide.md` Section 2 "Adaptive Pipeline Depth Heuristic":

```
Read('references/pipeline-guide.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/references/pipeline-guide.md`)

Analyze the phase goal and success criteria from ROADMAP.md. Apply the heuristic:

**Complexity signals (run FULL pipeline: discuss + research + plan + execute):**
- Phase goal mentions a new technical domain: auth, payments, search, real-time, file uploads, email, notifications, deployment, CI/CD, monitoring, caching, rate limiting, webhooks
- Phase goal mentions integration with external services or APIs
- Success criteria reference security, compliance, or data protection
- The phase has 4 or more success criteria
- Prior phase artifacts (CONTEXT.md, RESEARCH.md from earlier phases) do not cover this domain
- Build preferences do NOT specify tech decisions for the domain this phase addresses

**Simplicity signals (SIMPLE pipeline: plan + execute only):**
- Phase goal mentions: setup, init, config, scaffold, boilerplate, structure, foundation, update, tweak, adjust, rename, move, refactor, cleanup, docs, documentation
- Phase extends patterns already established in earlier phases
- The phase has 1-2 success criteria
- Build preferences already specify the tech decisions relevant to this phase

**Default:** If signals are mixed or unclear, run the FULL pipeline. False negatives (skipping when you should have discussed) are more expensive than false positives.

Log the decision in BUILD-STATE.md Decisions Log: Phase N, Skill "build", Question "Pipeline depth", Answer "full|simple", Confidence level.

Print: `Phase {N} pipeline depth: {FULL|SIMPLE}`

#### 9c. Invoke /discuss-phase N (Full Pipeline Only)

**If FULL pipeline:**

1. Update Phase Progress: set Discuss to `in_progress`.
2. Invoke:
   ```
   Skill('discuss-phase', '{N}')
   ```
3. Answer all gray area questions autonomously per the decision guide:
   - Tech choices, patterns, tradeoffs: answer based on project context, build preferences tech stack, and common patterns for the domain.
   - Log each decision as **medium** confidence for domain-specific decisions.
   - After answering all presented gray areas, select **"All set"** to move forward.
4. Log decisions in BUILD-STATE.md Decisions Log.
5. Update Phase Progress: set Discuss to `complete`.

**If SIMPLE pipeline:**

Update Phase Progress: set Discuss to `skipped`.

#### 9d. Invoke /research-phase N (Full Pipeline Only)

**If FULL pipeline:**

1. Update Phase Progress: set Research to `in_progress`.
2. Invoke:
   ```
   Skill('research-phase', '{N}')
   ```
3. Answer any AskUserQuestion calls autonomously per the decision guide:
   - "Continue research / Done" -> **"Done"**
   - "RESEARCH.md already exists" -> **"Replace entirely"**
   - "Research was blocked / failed" -> **"Plan without research"**
   - "Research conflicts with decisions" -> **"Keep decisions"**
4. Log decisions in BUILD-STATE.md Decisions Log.
5. Update Phase Progress: set Research to `complete`.

**If SIMPLE pipeline:**

Update Phase Progress: set Research to `skipped`.

#### 9e. Invoke /plan-phase N

Update Phase Progress: set Plan to `in_progress`.

Invoke:

```
Skill('plan-phase', '{N}')
```

Answer any AskUserQuestion calls autonomously per the decision guide. Plan checker is skipped by default (planner has built-in pre-flight checklist). If the skill asks about existing plans or research, prefer continuing without delay.

Log decisions in BUILD-STATE.md Decisions Log.

Update Phase Progress: set Plan to `complete`.

#### 9f. Git: Commit Planning Artifacts and Create Feature Branch

Determine the phase directory name (zero-padded, e.g., `01-foundation`):

```bash
ls -d .planning/phases/${PADDED_PHASE}-* 2>/dev/null | head -1
```

Commit planning artifacts on main branch:

```bash
git add .planning/phases/${PHASE_DIR}/ .planning/STATE.md .planning/ROADMAP.md .planning/BUILD-STATE.md
git commit -m "[build] Plan phase ${N}: ${PHASE_NAME}"
```

Derive the branch slug from the phase directory name (e.g., `01-foundation`):

```bash
git checkout -b build/${PHASE_DIR_BASENAME}
```

Example: `git checkout -b build/01-foundation`

Update Phase Progress: set Git Merge to `branched`.

Write BUILD-STATE.md with updated progress.

#### 9g. Invoke /execute-phase N

Update Phase Progress: set Execute to `in_progress`.

Invoke:

```
Skill('execute-phase', '{N}')
```

Answer all AskUserQuestion calls autonomously per the decision guide:

- **Branch warning ("on main"):** Select **"Continue anyway"** -- /build manages its own branch flow and we are on a `build/` branch.
- **Exec model:** Use $PREF_EXEC_MODEL from resolved preferences.
- **Task blocked / needs human input:** Select **"Skip task"** -- cannot provide human guidance autonomously. Log the skipped task.
- **Checkpoint: human-verify:** **AUTO-APPROVE.** Log as **low** confidence.
- **Checkpoint: decision:** Use LLM reasoning based on project context. Log with appropriate confidence.
- **Verification gaps / gap closure:** Select **"Accept as-is"** -- rely on the external build/test validation in the pipeline and /phase-feedback for the single permitted feedback attempt.

Log each decision in BUILD-STATE.md Decisions Log.

After completion, commit execution results:

```bash
git add -A
git commit -m "[build] Execute phase ${N}: ${PHASE_NAME}"
```

Update Phase Progress: set Execute to `complete`.

#### 9h. Adaptive Validation

Read `references/pipeline-guide.md` Section 3 "Adaptive Validation Heuristic".

Determine if validation should run for this phase.

**Validate when ANY of these are true:**
- Phase created or modified source code files (*.ts, *.js, *.jsx, *.tsx, *.py, *.go, *.rs, *.java, *.rb, *.swift, *.kt)
- Phase created or modified package/dependency files (package.json, requirements.txt, Cargo.toml, go.mod, Gemfile, build.gradle)
- Phase created or modified test files (*.test.*, *.spec.*, test_*.py, *_test.go, *_test.rs)
- Phase goal mentions: build, implement, create, code, develop, integrate, migrate
- A build system exists in the project
- It is the **final phase** -- always validate regardless of content

**Skip validation when ALL of these are true:**
- Phase only created or modified `.planning/` files
- Phase only created or modified documentation (*.md outside source directories)
- Phase only created config files with no accompanying source code
- No build system exists yet

**If VALIDATE:**

1. Update Phase Progress: set Validate to `in_progress`.
2. Detect build/test commands using the priority order from `references/pipeline-guide.md` Section 3:

   | Priority | Indicator | Build Command | Test Command |
   |----------|-----------|---------------|--------------|
   | 1 | `bun.lockb` exists | `bun run build` | `bun test` |
   | 2 | `package.json` with scripts | `npm run build` (if "build" script exists) | `npm test` (if "test" script exists) |
   | 3 | `Makefile` or `makefile` | `make build` (if target exists) | `make test` (if target exists) |
   | 4 | `Cargo.toml` | `cargo build` | `cargo test` |
   | 5 | `go.mod` | `go build ./...` | `go test ./...` |
   | 6 | `pyproject.toml` or `setup.py` or `requirements.txt` | None | `pytest` (if test files exist) |
   | 7 | None detected | Skip build | Skip tests |

3. Run build command via Bash. Capture output (stdout + stderr).
4. Run test command via Bash. Capture output (stdout + stderr).
5. Record results in BUILD-STATE.md Validation Results table: Phase, Build (pass/fail/skipped), Tests (pass/fail/skipped/none), Feedback Attempt (N/A), Final Status.
6. If both pass: set Phase Progress Validate to `complete`.
7. If either fails: proceed to Step 9i.

**If SKIP:**

Update Phase Progress: set Validate to `skipped`.

#### 9i. Phase Feedback (One Attempt, On Validation Failure)

If validation failed in Step 9h:

1. Synthesize feedback from build/test error output:
   - "Build failed: {error_summary}" or "Tests failed: {failing_test_names}"
   - Include file paths and error messages (truncate to 500 chars if very long)

2. Update Phase Progress: set Feedback to `in_progress`.

3. Invoke:
   ```
   Skill('phase-feedback', '{N} {synthesized_error_description}')
   ```

4. Answer any AskUserQuestion calls autonomously per the decision guide.

5. If /phase-feedback creates a subphase (e.g., N.1), invoke execution for it:
   ```
   Skill('execute-phase', '{N.1}')
   ```
   Answer all AskUserQuestion calls autonomously. Commit results:
   ```bash
   git add -A
   git commit -m "[build] Fix phase ${N}: ${PHASE_NAME}"
   ```

6. Re-run the same validation commands from Step 9h (build + tests).

7. **If pass:** Set Phase Progress Feedback to `complete`, Validate to `complete`. Update Validation Results table: set Feedback Attempt to "pass", Final Status to "pass".

8. **If still fail:** Set Phase Progress Feedback to `failed`.
   - Log in BUILD-STATE.md Incomplete Phases section: phase number, name, error summary.
   - Update Validation Results table: set Feedback Attempt to "fail", Final Status to "incomplete".
   - Print: `Phase {N} validation failed after feedback attempt. Marking incomplete, continuing.`
   - Continue to next phase.

**If validation passed or was skipped in Step 9h:**

Update Phase Progress: set Feedback to `N/A`.

#### 9j. Git: Squash-Merge to Main

Determine the branch name from the phase directory:

```bash
git checkout main
git merge --squash build/${PHASE_DIR_BASENAME}
git commit -m "[build] Phase ${N}: ${PHASE_NAME}

$(head -5 .planning/phases/${PHASE_DIR}/??-??-SUMMARY.md 2>/dev/null | tail -2)

Validation: ${VALIDATION_RESULT}
Plans executed: ${PLANS_COMPLETED}/${PLANS_TOTAL}

Autonomous build by /build skill."
```

Replace `main` with the actual main branch name from BUILD-STATE.md `Git main branch` field.

Clean up the feature branch:

```bash
git branch -d build/${PHASE_DIR_BASENAME}
```

**If merge fails:** Log the error in BUILD-STATE.md Errors section. Attempt to resolve:

```bash
git merge --abort 2>/dev/null
git checkout main
git branch -D build/${PHASE_DIR_BASENAME}
```

Log: `Merge conflict for phase {N}. Branch deleted, changes lost. Phase marked incomplete.`

Update Phase Progress: set Git Merge to `complete` (or `failed` if merge failed), Status to `complete` (or `incomplete`).

#### 9k. Sync Planning State Files

After each phase completes (whether via successful merge or failure), explicitly sync ROADMAP.md and STATE.md to reflect reality. Do NOT rely on execute-phase having done this -- it may not have.

**ROADMAP.md sync:**
1. In the **Phases** checklist: change `- [ ]` to `- [x]` for the completed phase entry
2. In the **Progress** table: set Status to "Complete" and Completed to today's date (YYYY-MM-DD format)

**STATE.md sync:**
1. Set "Phase:" in Current Position to {N+1} (the next phase number)
2. Set "Status:" to the appropriate value for the next phase (e.g., "Ready to plan" or "Ready to execute")
3. Update "Last activity:" to today's date with a brief note

These updates happen on the main branch (after the squash-merge in Step 9j).

#### 9l. Update BUILD-STATE.md

Set the Phase Progress row's `Completed` column to the current time (HH:MM).

Write the full updated BUILD-STATE.md with all progress changes from this phase iteration.

Print: `Phase {N} complete. Moving to next phase.`

---

### Step 10: Final Validation

After ALL phases have been processed:

1. Ensure on the main branch:
   ```bash
   git checkout main
   ```
   (Use the actual main branch name from BUILD-STATE.md.)

2. Update BUILD-STATE.md: set Current stage to `final-validation`.

3. ALWAYS run build + test validation regardless of per-phase results.

4. Detect validation commands using the same priority order from Step 9h.

5. Run build command. Capture full output.

6. Run test command. Capture full output.

7. Record results in BUILD-STATE.md Validation Results table as "Final" row.

**If both pass:** Print `Final validation passed.` Proceed to Step 12.

**If either fails:** Print `Final validation failed. Entering auto-fix loop.` Proceed to Step 11.

**If no build system detected:** Print `No build system detected -- skipping final validation.` Proceed to Step 12.

---

### Step 11: Auto-Fix Loop (Max 3 Attempts)

Update BUILD-STATE.md: set Current stage to `auto-fix`.

For attempt 1 to 3:

1. **Capture** the full build/test error output (stdout + stderr) from the previous run.

2. **Analyze** errors:
   - Parse error messages for file paths and line numbers.
   - Categorize: build error, type error, test failure, missing dependency.
   - Identify the most likely root cause for each error.

3. **Apply targeted fixes** using Edit/Write tools directly (no skill invocation):
   - Import errors: add missing imports.
   - Type errors: fix type mismatches.
   - Test failures: fix failing assertions or broken logic.
   - Missing dependencies: install via the project's package manager.

4. **Commit** the fixes:
   ```bash
   git add -A
   git commit -m "[build] Auto-fix attempt ${ATTEMPT}: ${FIX_SUMMARY}"
   ```

5. **Re-run** build + test commands.

6. **If pass:** Log success in BUILD-STATE.md. Print `Auto-fix attempt {N} succeeded.` Break out of loop. Proceed to Step 12.

7. **If fail:** Log the attempt in BUILD-STATE.md Errors section: attempt number, error summary, fix applied, result. Continue to next attempt.

**After 3 failures:**

- Log final errors in BUILD-STATE.md Errors section.
- Set BUILD-STATE.md Status to `partial`.
- Print: `Auto-fix failed after 3 attempts. Build status: partial.`
- Proceed to Step 12.

**Constraints:**
- Each attempt is logged in BUILD-STATE.md Errors section.
- Auto-fix must NOT make architectural changes -- only targeted fixes for build/test failures.
- The 3-attempt limit is hard -- do not extend it.

---

### Step 12: Generate BUILD-REPORT.md

Read the report template:

```
Read('assets/build-report-template.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/assets/build-report-template.md`)

Populate all sections from BUILD-STATE.md:

- **Overview:** project name (from PROJECT.md), input ($IDEA_TEXT or PRD summary), start/end timestamps, final status.
- **Pipeline Summary:** phases planned, phases completed, phases incomplete, total plans executed, feedback loops used, compactions survived.
- **Phase Results:** from Phase Progress table -- one row per phase with name, status, validation result, notes.
- **Key Decisions:** from Decisions Log -- all decisions made during the build.
- **Low-Confidence Decisions:** filtered subset of Decisions Log where confidence = low. These are flagged for user review.
- **Validation Summary:** from Validation Results table -- per-phase build/test results.
- **Final Validation:** build/test results from Step 10, auto-fix attempts from Step 11 (if any).
- **Incomplete Items:** from Incomplete Phases section -- phases that failed validation after feedback.
- **Known Issues:** from Errors section -- all logged errors and unresolved problems.
- **Files Created:** summary from SUMMARY.md files across all phases.
- **Next Steps:** recommendations based on outcome:
  - If `complete`: "Application is built and validated. Review low-confidence decisions. Run manually. Deploy."
  - If `partial`: "Build/tests have failures after auto-fix. Review Known Issues. Run /phase-feedback on incomplete phases. Fix manually if needed."
  - If `failed`: "Critical failure prevented completion. Review Errors section. Address blockers and re-run /build to resume."

Write to `.planning/BUILD-REPORT.md`:

```
Write('.planning/BUILD-REPORT.md', populated_report)
```

Update BUILD-STATE.md:
- Set Status to `complete` (or `partial` or `failed` based on outcome).
- Set Current stage to `done`.
- Write final BUILD-STATE.md.

Commit the final report:

```bash
git add .planning/BUILD-REPORT.md .planning/BUILD-STATE.md
git commit -m "[build] Build report: ${STATUS}"
```

---

### Step 13: Present Completion Summary

Print the final summary:

```
=== BUILD COMPLETE ===

Project: {project_name}
Status: {complete | partial | failed}
Duration: {start_time} to {end_time}

Phases: {completed}/{total} completed
  {list each phase: "  Phase N: {name} -- {status}"}

Validation:
  Per-phase: {N} passed, {M} failed, {K} skipped
  Final: {pass | fail | skipped}
  Auto-fix attempts: {0-3}

Decisions: {total} made autonomously
  High confidence: {count}
  Medium confidence: {count}
  Low confidence: {count} (review recommended)

{If incomplete phases exist:}
Incomplete Phases:
  {list each: "  Phase N: {name} -- {reason}"}

Git: {total_commits} commits on main branch. No remote pushes.

Report: .planning/BUILD-REPORT.md
State:  .planning/BUILD-STATE.md

--- Next Steps ---

{If complete:}
  - Review BUILD-REPORT.md, especially low-confidence decisions
  - Test the application manually
  - Run /phase-feedback on any phase to adjust behavior or style
  - Push to remote when ready: git push

{If partial:}
  - Review Known Issues in BUILD-REPORT.md
  - Run /phase-feedback on incomplete phases
  - Or fix manually and re-run: /build (auto-resumes)

{If failed:}
  - Review Errors section in BUILD-REPORT.md
  - Address the blocking issue
  - Re-run: /build (auto-resumes from last position)
```

**END OF PROCESS.**

---

## Compaction Recovery Protocol

When context compaction occurs mid-build, the hooks system handles recovery:

1. **PreCompact hook** emits BUILD-STATE.md contents to stdout, ensuring it is captured in the compacted context.
2. **SessionStart(compact) hook** re-injects BUILD-STATE.md, PROJECT.md, ROADMAP.md, STATE.md, and build preferences.
3. On resume, Step 1 detects the `in_progress` status and enters the resume path.
4. The `Compaction count` field is incremented to track how many compactions occurred.
5. `references/autonomous-decision-guide.md` is re-read to restore the decision framework.

The critical invariant: **BUILD-STATE.md on disk is always up-to-date.** Every step writes BUILD-STATE.md before and after skill invocations. This ensures that even if compaction occurs mid-skill, the state file reflects the last known position.

---

## Autonomous Decision Summary

All AskUserQuestion calls from child skills are answered autonomously. The full decision framework is in `references/autonomous-decision-guide.md`. Key rules:

1. Check build-preferences.md for a directly relevant preference.
2. If no preference: reason from project context, prior decisions, and best practices.
3. Always move the pipeline forward -- never select "Abort", "Cancel", or "Stop".
4. Log every decision with confidence level (high / medium / low).
5. Low-confidence decisions are flagged for review in BUILD-REPORT.md.

---

## Git Flow Summary

All git operations are local-only. Never push to remote.

**Per-phase flow:**
1. Planning artifacts (discuss, research, plan) committed on main.
2. Feature branch created: `build/{NN}-{slug}` (e.g., `build/01-foundation`).
3. Execution happens on feature branch.
4. Squash-merge back to main on phase completion.
5. Feature branch deleted.

**Branch naming:** `build/{NN}-{slug}` where NN is zero-padded phase number and slug is the kebab-case phase name from the directory.

**Merge conflict handling:** If squash-merge fails, abort merge, delete branch, log error, mark phase incomplete, continue.

---

## Adaptive Heuristics Summary

**Pipeline depth** (per-phase):
- FULL (discuss + research + plan + execute): new domains, external integrations, security concerns, 4+ success criteria.
- SIMPLE (plan + execute): scaffolding, config, extending established patterns, 1-2 success criteria.
- Default: FULL when signals are mixed.

**Validation** (per-phase):
- VALIDATE: source code changes, dependency changes, test changes, code-producing goals, final phase.
- SKIP: planning-only changes, documentation, config without code.

**Feedback** (per-phase, on validation failure):
- ONE attempt via /phase-feedback. If still fails, mark incomplete and continue.
- Feedback subphase inherits the same feature branch.

---

## Success Criteria

- [ ] Application code exists and was generated from the provided idea/PRD
- [ ] All phases in ROADMAP.md were processed (completed or marked incomplete)
- [ ] BUILD-STATE.md tracks the full execution journey
- [ ] BUILD-REPORT.md summarizes results with all decisions logged
- [ ] Low-confidence decisions are flagged for user review
- [ ] Git history shows one squash-merge commit per completed phase
- [ ] No user interaction occurred during the entire build
- [ ] Final validation ran (build + tests) with auto-fix if needed
- [ ] Incomplete phases are documented with reasons
- [ ] User sees a clear completion summary with next steps
