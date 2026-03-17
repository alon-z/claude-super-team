# Sprint Execution Guide

Steps 8-E and 9 of the /build pipeline. Covers extend-mode roadmap creation and the full sprint execution loop (discuss/research, parallel planning, sequential execution, per-phase validation/feedback/merge, sprint boundary validation).

### Step 8-E: Invoke /create-roadmap (Extend Mode)

> **Entry paths:** This step is reached from both **Branch 2** (traditional extend with an existing BUILD-STATE.md) and **Branch 2a** (auto-extend, where no BUILD-STATE.md existed before this build run). The behavior is identical in both cases -- /create-roadmap's "add" flow works the same regardless of whether a prior BUILD-STATE.md existed. By the time this step executes, Step 4-E (Initialize BUILD-STATE.md for Extend) has already run, so BUILD-STATE.md is guaranteed to exist.

Update BUILD-STATE.md: set Pipeline Progress "create-roadmap" row to `in_progress`, set Current stage to `create-roadmap`.

Invoke /create-roadmap with the "add" modification intent, passing the user's feature description:

```
Skill('create-roadmap', 'add $ARGUMENTS')
```

This triggers /create-roadmap's "Add Phase" flow, which:
- Reads existing ROADMAP.md
- Finds the highest phase number
- Derives a new phase from $ARGUMENTS
- Appends to the roadmap

Answer any AskUserQuestion calls autonomously per the decision guide (Section 3, "/create-roadmap (Extend Mode)"):
- "Roadmap already exists. What would you like to do?" -> **"Add a phase"**
- "Add this phase to the roadmap?" -> **"Approve"**

Log decisions in BUILD-STATE.md Decisions Log.

**IMPORTANT: /create-roadmap will output a "Next Steps" section telling you to run /plan-phase or /discuss-phase. IGNORE IT -- those directives are for standalone use. You MUST continue with the post-completion steps below. Do NOT stop, do NOT present "Next Steps" to the user.**

After completion, verify:

```bash
test -f .planning/ROADMAP.md
```

Read ROADMAP.md to determine the full list of phases:

```
Read('.planning/ROADMAP.md')
```

Extract all phase numbers, names, goals, and success criteria. Compare against the PHASE_COMPLETION data from gather-data.sh to identify which phases are new (not present in PHASE_COMPLETION or not marked `complete`).

Parse sprint assignments from the updated ROADMAP.md (same sprint grouping logic as Step 8). Build SPRINT_MAP.

Update BUILD-STATE.md:
- Set Pipeline Progress "create-roadmap" row to `complete`.
- Populate the Phase Progress table with one row per phase from ROADMAP.md (include Sprint column from SPRINT_MAP):
  - For phases already completed (found in PHASE_COMPLETION with status `complete`): set all step columns to `skipped`, Status to `complete (prior)`.
  - For new phases: set all step columns to `pending`, `Started` and `Completed` set to `-`.
- Populate the Sprint Progress table from SPRINT_MAP. Sprints where ALL phases are `complete (prior)` get Status `complete (prior)`.
- Set Current stage to `sprint-execution`.

Print: `Roadmap updated. New phase(s) added. Skipping {N} completed phases.`

Continue to Step 9 (the sprint execution loop will skip completed sprints automatically).

For auto-extend builds (Branch 2a), the prior BUILD-STATE.md did not exist. Step 4-E created a fresh one. The PHASE_COMPLETION data from gather-data.sh reflects filesystem state, so completed phases are correctly identified regardless of BUILD-STATE.md history.

---

### Step 9: Sprint Execution Loop

Parse sprint groupings from SPRINT_MAP (built in Step 8). Process sprints in ascending order.

For each sprint S in SPRINT_MAP:

#### 9-pre. Skip Completed Sprints

For each phase N in sprint S, check PHASE_COMPLETION data from gather-data.sh. If the phase has status `complete`:
1. Set the Phase Progress row: all step columns to `skipped`, Status to `complete (prior)`.
2. Remove this phase from the sprint's active list for this iteration.

If ALL phases in sprint S are already complete:
1. Print: `Sprint {S} already complete, skipping.`
2. Set Sprint Progress row: Status to `complete (prior)`.
3. Continue to the next sprint.

#### 9a. Sprint Setup

Set `Current stage` to `sprint-{S}-discuss-research`.

For each active phase N in sprint S:
- Set the Phase Progress row's `Started` column to the current time (HH:MM).

Update Sprint Progress row: set Status to `in_progress`, Started to current time (HH:MM).

Write BUILD-STATE.md.

Print: `Starting sprint {S}: {active_phase_count} phase(s) -- {phase_names}`

#### 9b. Adaptive Pipeline Depth (All Sprint Phases)

Read `${CLAUDE_SKILL_DIR}/references/pipeline-guide.md` Section 2 "Adaptive Pipeline Depth Heuristic":

```
Read('${CLAUDE_SKILL_DIR}/references/pipeline-guide.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/references/pipeline-guide.md`)

For each active phase N in sprint S, analyze the phase goal and success criteria from ROADMAP.md. Apply the heuristic:

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

**Default:** If signals are mixed or unclear, run the FULL pipeline.

Record each phase's pipeline depth decision (FULL or SIMPLE) for use in subsequent steps.

Log decisions in BUILD-STATE.md Decisions Log: Phase N, Skill "build", Question "Pipeline depth", Answer "full|simple", Confidence level.

Print: `Sprint {S} pipeline depths: {Phase N: FULL, Phase M: SIMPLE, ...}`

#### 9c. Discuss + Research (Sequential Per Phase)

For each active phase N in sprint S:

**If pipeline depth = FULL:**

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

6. Update Phase Progress: set Research to `in_progress`.
7. Invoke:
   ```
   Skill('research-phase', '{N}')
   ```
8. Answer any AskUserQuestion calls autonomously per the decision guide:
   - "Continue research / Done" -> **"Done"**
   - "RESEARCH.md already exists" -> **"Replace entirely"**
   - "Research was blocked / failed" -> **"Plan without research"**
   - "Research conflicts with decisions" -> **"Keep decisions"**
9. Log decisions in BUILD-STATE.md Decisions Log.
10. Update Phase Progress: set Research to `complete`.

**If pipeline depth = SIMPLE:**

Update Phase Progress: set Discuss to `skipped`, Research to `skipped`.

#### 9d. Plan All Sprint Phases (Parallel)

Update `Current stage` to `sprint-{S}-plan`.

Update Phase Progress: set Plan to `in_progress` for all active phases in this sprint.

**If sprint has multiple active phases**, invoke all plan-phase calls simultaneously as parallel Skill calls:

```
Skill('plan-phase', '{N1}')
Skill('plan-phase', '{N2}')
... (one per active phase in the sprint)
```

**If sprint has only one active phase**, invoke a single Skill call:

```
Skill('plan-phase', '{N}')
```

Answer any AskUserQuestion calls autonomously per the decision guide. Plan checker is skipped by default (planner has built-in pre-flight checklist). If the skill asks about existing plans or research, prefer continuing without delay.

Log decisions in BUILD-STATE.md Decisions Log.

Update Phase Progress: set Plan to `complete` for all active phases.

#### 9e. Git: Commit Planning Artifacts and Create Feature Branches

Update `Current stage` to `sprint-{S}-branch`.

For each active phase N in sprint S:

1. Determine the phase directory name (zero-padded, e.g., `01-foundation`):
   ```bash
   ls -d .planning/phases/${PADDED_PHASE}-* 2>/dev/null | head -1
   ```

2. Commit planning artifacts on main branch:
   ```bash
   git add .planning/phases/${PHASE_DIR}/ .planning/STATE.md .planning/ROADMAP.md .planning/BUILD-STATE.md
   git commit -m "[build] Plan sprint ${S} phase ${N}: ${PHASE_NAME}"
   ```

3. Create feature branch and return to main:
   ```bash
   git checkout -b build/${PHASE_DIR_BASENAME}
   git checkout ${MAIN_BRANCH}
   ```
   **Important:** Return to main immediately so the next branch also forks from the same main commit. All sprint branches must share the same base.

4. Update Phase Progress: set Git Merge to `branched`.

Write BUILD-STATE.md with updated progress.

#### 9f. Execute All Sprint Phases (Sequential, Separate Branches)

Update `Current stage` to `sprint-{S}-execute`.

For each active phase N in sprint S:

1. Checkout the phase's feature branch:
   ```bash
   git checkout build/${PHASE_DIR_BASENAME}
   ```

2. Update Phase Progress: set Execute to `in_progress`.

3. Invoke:
   ```
   Skill('execute-phase', '{N}')
   ```

   The verification preference (`$PREF_VERIFICATION`) is already persisted in STATE.md from Step 3 preference resolution. Execute-phase reads it from its gather script PREFERENCES section automatically.

   Answer all AskUserQuestion calls autonomously per the decision guide:
   - **Branch warning ("on main"):** Select **"Continue anyway"** -- /build manages its own branch flow and we are on a `build/` branch.
   - **Exec model:** Use $PREF_EXEC_MODEL from resolved preferences.
   - **Task blocked / needs human input:** Select **"Skip task"** -- cannot provide human guidance autonomously. Log the skipped task.
   - **Checkpoint: human-verify:** **AUTO-APPROVE.** Log as **low** confidence.
   - **Checkpoint: decision:** Use LLM reasoning based on project context. Log with appropriate confidence.
   - **Verification gaps / gap closure:** Select **"Accept as-is"** -- rely on the external build/test validation in the pipeline and /phase-feedback for the single permitted feedback attempt.

4. Log each decision in BUILD-STATE.md Decisions Log.

5. After completion, commit execution results:
   ```bash
   git add -A
   git commit -m "[build] Execute phase ${N}: ${PHASE_NAME}"
   ```

6. Update Phase Progress: set Execute to `complete`.

7. Return to main:
   ```bash
   git checkout ${MAIN_BRANCH}
   ```

#### 9g. Per-Phase Validation, Feedback, and Merge

Update `Current stage` to `sprint-{S}-merge`.

For each active phase N in sprint S (sequential):

##### 9g-i. Adaptive Validation

Checkout the phase branch:
```bash
git checkout build/${PHASE_DIR_BASENAME}
```

Read `${CLAUDE_SKILL_DIR}/references/pipeline-guide.md` Section 3 "Adaptive Validation Heuristic".

Determine if validation should run for this phase.

**Validate when ANY of these are true:**
- Phase created or modified source code files (*.ts, *.js, *.jsx, *.tsx, *.py, *.go, *.rs, *.java, *.rb, *.swift, *.kt)
- Phase created or modified package/dependency files (package.json, requirements.txt, Cargo.toml, go.mod, Gemfile, build.gradle)
- Phase created or modified test files (*.test.*, *.spec.*, test_*.py, *_test.go, *_test.rs)
- Phase goal mentions: build, implement, create, code, develop, integrate, migrate
- A build system exists in the project
- It is the **last phase in the last sprint** -- always validate regardless of content

**Skip validation when ALL of these are true:**
- Phase only created or modified `.planning/` files
- Phase only created or modified documentation (*.md outside source directories)
- Phase only created config files with no accompanying source code
- No build system exists yet

**If VALIDATE:**

1. Update Phase Progress: set Validate to `in_progress`.
2. Detect build/test commands using the priority order from `${CLAUDE_SKILL_DIR}/references/pipeline-guide.md` Section 3:

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
7. If either fails: proceed to feedback below.

**If SKIP:**

Update Phase Progress: set Validate to `skipped`.

##### 9g-ii. Phase Feedback (One Attempt, On Validation Failure)

If validation failed:

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

6. Re-run the same validation commands (build + tests).

7. **If pass:** Set Phase Progress Feedback to `complete`, Validate to `complete`. Update Validation Results table: set Feedback Attempt to "pass", Final Status to "pass".

8. **If still fail:** Set Phase Progress Feedback to `failed`.
   - Log in BUILD-STATE.md Incomplete Phases section: phase number, name, error summary.
   - Update Validation Results table: set Feedback Attempt to "fail", Final Status to "incomplete".
   - Print: `Phase {N} validation failed after feedback attempt. Marking incomplete, continuing.`

**If validation passed or was skipped:** Update Phase Progress: set Feedback to `N/A`.

##### 9g-iii. Squash-Merge to Main

```bash
git checkout ${MAIN_BRANCH}
git merge --squash build/${PHASE_DIR_BASENAME}
git commit -m "[build] Sprint ${S}, Phase ${N}: ${PHASE_NAME}

$(head -5 .planning/phases/${PHASE_DIR}/??-??-SUMMARY.md 2>/dev/null | tail -2)

Validation: ${VALIDATION_RESULT}
Plans executed: ${PLANS_COMPLETED}/${PLANS_TOTAL}

Autonomous build by /build skill."
```

Replace `${MAIN_BRANCH}` with the actual main branch name from BUILD-STATE.md `Git main branch` field.

Clean up the feature branch:

```bash
git branch -d build/${PHASE_DIR_BASENAME}
```

**If merge fails:** Log the error in BUILD-STATE.md Errors section. Attempt to resolve:

```bash
git merge --abort 2>/dev/null
git checkout ${MAIN_BRANCH}
git branch -D build/${PHASE_DIR_BASENAME}
```

Log: `Merge conflict for phase {N}. Branch deleted, changes lost. Phase marked incomplete.`

Update Phase Progress: set Git Merge to `complete` (or `failed` if merge failed), Status to `complete` (or `incomplete`).

##### 9g-iv. Sync Planning State Files

After each phase merges, sync ROADMAP.md and STATE.md to reflect reality. Do NOT rely on execute-phase having done this.

**ROADMAP.md sync:**
1. In the **Phases** checklist: change `- [ ]` to `- [x]` for the completed phase entry
2. In the **Progress** table: set Status to "Complete" and Completed to today's date (YYYY-MM-DD format)

**STATE.md sync:**
1. Set "Phase:" in Current Position to the next phase number
2. Set "Status:" to the appropriate value
3. Update "Last activity:" to today's date with a brief note

##### 9g-v. Update Phase Progress

Set the Phase Progress row's `Completed` column to the current time (HH:MM).

Write BUILD-STATE.md.

Print: `Phase {N} complete.`

#### 9h. Sprint Boundary Validation

After ALL active phases in sprint S are merged to main:

Update `Current stage` to `sprint-{S}-boundary-validation`.

1. Ensure on main branch:
   ```bash
   git checkout ${MAIN_BRANCH}
   ```

2. Determine if any phase in this sprint produced source code (check the per-phase validation decisions from 9g-i). If no phase in the sprint warranted validation, skip sprint boundary validation.

3. **If validation warranted:** Run build + test commands using the same detection logic from the Adaptive Validation Heuristic (Section 3 of pipeline-guide.md).

4. Record result in Sprint Progress table: set Boundary Validation to `pass`, `fail`, or `skipped`.

5. **If pass:** Print `Sprint {S} boundary validation passed. {phase_count} phases integrated successfully.`

6. **If fail:** Print `Sprint {S} boundary validation failed.` Log the error in BUILD-STATE.md Errors section. This is informational -- per-phase feedback already attempted. The final validation (Step 10) and auto-fix loop (Step 11) will address remaining issues.

7. **If skipped (no build system or no code phases):** Print `Sprint {S} boundary validation skipped.`

#### 9i. Complete Sprint

Update Sprint Progress row: set Status to `complete`, Completed to current time (HH:MM).

Write BUILD-STATE.md.

Print: `Sprint {S} complete. Moving to next sprint.`

