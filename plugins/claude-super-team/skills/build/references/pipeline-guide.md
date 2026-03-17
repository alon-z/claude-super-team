# Pipeline Guide

Heuristics and workflows for /build's pipeline orchestration. Referenced by SKILL.md for adaptive decisions during autonomous execution.

## 1. Skill Invocation Order

Complete pipeline sequence:

```
1.  Input detection: parse $ARGUMENTS for file paths vs inline text
2.  Invoke /new-project with idea/PRD content
3.  [If brownfield: CODE_FILES > 0] Invoke /map-codebase
4.  Invoke /brainstorm (autonomous mode)
5.  Invoke /create-roadmap
6.  Parse sprint groupings from ROADMAP.md (Section 9)
7.  For each sprint S:
    a. For each phase N in sprint S (sequential):
       - Evaluate adaptive pipeline depth (Section 2)
       - [If full pipeline] Invoke /discuss-phase N
    a2. Research FULL phases (parallel with dependency awareness):
       - Overlap analysis on CONTEXT.md files for shared domains
       - Independent phases: parallel Skill('research-phase', N) calls
       - Overlapping phases: chained sequentially (earlier feeds later)
    b. Plan all sprint phases in parallel:
       - Invoke /plan-phase N for each phase (parallel Skill calls)
    c. Git: commit planning artifacts and create feature branches for all phases
    d. Execute each phase on its branch (sequential, each on own branch):
       - Invoke /execute-phase N, commit results
    e. For each phase (sequential):
       - Per-phase validation + feedback (if needed)
       - Squash-merge to main, delete branch
    f. Sprint boundary validation: run build + tests on main
    g. Update BUILD-STATE.md sprint + phase progress
8.  Final validation -- always run (Section 7)
9.  [If fails] Auto-fix loop (max 3 attempts)
10. Generate BUILD-REPORT.md
11. Present completion summary to user
```

## 2. Adaptive Pipeline Depth Heuristic

Determines whether a phase runs the full pipeline (discuss -> research -> plan -> execute) or the short pipeline (plan -> execute).

### Complexity Signals (run full pipeline)

Run /discuss-phase and /research-phase when ANY of these are true:

- Phase goal mentions a new technical domain: auth, payments, search, real-time, file uploads, email, notifications, deployment, CI/CD, monitoring, caching, rate limiting, webhooks
- Phase goal mentions integration with external services or APIs
- Success criteria reference security, compliance, or data protection
- The phase has 4 or more success criteria
- Prior phase artifacts (CONTEXT.md, RESEARCH.md from earlier phases) do not cover this domain
- `build-preferences.md` does NOT specify tech decisions for the domain this phase addresses

### Simplicity Signals (skip discuss/research)

Skip directly to /plan-phase when ALL of these are true:

- Phase goal mentions: setup, init, config, scaffold, boilerplate, structure, foundation, update, tweak, adjust, rename, move, refactor, cleanup, docs, documentation
- Phase extends patterns already established in earlier phases (similar file structure, same tech stack, same architecture)
- The phase has 1-2 success criteria
- `build-preferences.md` already specifies the tech decisions relevant to this phase

### Default Behavior

If signals are mixed or unclear: **run the full pipeline**. Discuss and research are cheap relative to building the wrong thing. False negatives (skipping when you should have discussed) are far more expensive than false positives (discussing when you could have skipped).

### Tech Stack Coverage

If `build-preferences.md` specifies a full tech stack (framework, database, auth provider, etc.) AND the current phase's goal and success criteria use only technologies within that stack, bias toward SIMPLE. The rationale: when the user has already made all tech decisions, /discuss-phase adds no value and /research-phase is redundant for well-known frameworks.

Conversely, if the phase introduces a technology NOT covered by build-preferences (e.g., a payment provider when preferences only specify frontend + backend), run FULL.

### Project Complexity Class

After /create-roadmap completes (Step 8), classify the project as `standard` or `complex` based on the roadmap:

- **complex** if ANY: total phase count >= 8, any phase has >= 5 success criteria, >= 3 phases mention external service integration, project involves real-time features or distributed systems
- **standard** otherwise

Log the classification in BUILD-STATE.md under Session as `Complexity class: {standard|complex}`.

Effect on pipeline depth: For `standard` projects, simplicity signals are weighted more heavily -- a phase matching 2+ simplicity signals skips discuss/research even if it also matches 1 complexity signal (keyword match alone is not enough to trigger FULL). For `complex` projects, the existing default-to-FULL behavior applies unchanged.

### Cumulative Knowledge Discount

After phases 1-2 have been executed, later phases that follow the same patterns established in earlier phases lean toward SIMPLE even if they mention domains that sound "new" but are structurally similar (e.g., "new API endpoints" in a phase that follows the same route/controller/model pattern as phase 2).

Specifically: if a phase's success criteria reference file patterns already created in earlier phases (same directory structure, same file naming, same tech stack), and prior CONTEXT.md/RESEARCH.md already cover the relevant domain, treat it as pattern-following and bias SIMPLE.

This discount does NOT apply when the phase introduces genuinely new infrastructure (new database, new external service, new deployment target).

### Constraints

- /brainstorm always runs once before /create-roadmap -- it is NOT per-phase
- /map-codebase always runs for brownfield projects (CODE_FILES > 0 in input detection)
- Only /discuss-phase and /research-phase are skippable on a per-phase basis
- /plan-phase and /execute-phase always run for every phase

## 3. Adaptive Validation Heuristic

Determines whether to run build + test validation after a phase completes.

### Validate (run build + tests)

Run validation when ANY of these are true:

- Phase created or modified source code files: `*.ts`, `*.js`, `*.jsx`, `*.tsx`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.rb`, `*.swift`, `*.kt`
- Phase created or modified package/dependency files: `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `build.gradle`
- Phase created or modified test files: `*.test.*`, `*.spec.*`, `test_*.py`, `*_test.go`, `*_test.rs`
- Phase goal mentions: build, implement, create, code, develop, integrate, migrate
- A build system exists in the project (see detection priority below)
- It is the **final phase** -- always validate regardless of content

### Skip Validation

Skip validation when ALL of these are true:

- Phase only created or modified `.planning/` files
- Phase only created or modified documentation (`*.md` files outside of source directories)
- Phase only created or modified config files with no accompanying source code changes
- No build system exists yet (project is still in scaffolding stages)

### Validation Command Detection

Check in this priority order. Use the first match:

| Priority | Indicator | Build Command | Test Command |
|----------|-----------|---------------|--------------|
| 1 | `bun.lockb` exists | `bun run build` | `bun test` |
| 2 | `package.json` with scripts | `npm run build` (if "build" script exists) | `npm test` (if "test" script exists) |
| 3 | `Makefile` or `makefile` | `make build` (if target exists) | `make test` (if target exists) |
| 4 | `Cargo.toml` | `cargo build` | `cargo test` |
| 5 | `go.mod` | `go build ./...` | `go test ./...` |
| 6 | `pyproject.toml` or `setup.py` or `requirements.txt` | None | `pytest` (if test files exist) |
| 7 | None detected | Skip build | Attempt to find any test runner in PATH |

Note: `bun.lockb` takes priority over `package.json` because its presence indicates the project uses Bun as its runtime, and Bun commands are faster and more appropriate.

## 4. File Path Detection Heuristic

Parse `$ARGUMENTS` to separate file paths from inline idea text.

### Detection Algorithm

```
1. Split $ARGUMENTS on whitespace into tokens
2. For each token, check if it is a potential file path:
   - Starts with `/`, `./`, `~/`, or `../`         -> potential path
   - Ends with `.md`, `.txt`, `.doc`, `.pdf`, `.rtf` -> potential path
   - Contains `/` and does not start with `http`     -> potential path
3. For each potential path, verify existence:
   - Run: test -f "$token" (for absolute/relative paths)
   - Run: test -f "$HOME/${token#\~/}" (for ~ paths)
4. Classify results:
```

### Result Classification

| Scenario | File Paths | Remaining Text | Action |
|----------|-----------|----------------|--------|
| File(s) found, no remaining text | Read file contents | None | Pass file contents as PRD/vision to /new-project |
| File(s) found, plus remaining text | Read file contents | Join remaining tokens | Pass file as PRD, remaining text as supplementary context |
| No files found | None | Entire $ARGUMENTS | Pass full string as project idea to /new-project |
| Empty $ARGUMENTS | None | None | Error: /build requires input. Inform user. |

### Edge Cases

- Multiple file paths: read and concatenate all files, separated by `---` markers with filenames
- File path exists but is not readable: warn in BUILD-STATE.md, treat remaining text as the input
- File is very large (> 50KB): read first 50KB, note truncation in BUILD-STATE.md

## 5. Sprint-Based Execution

### Sprint Grouping

ROADMAP.md annotates each phase with a sprint number (`**Sprint**: N` in Phase Details, `[Sprint N]` in the Phases checklist). Phases in the same sprint are independent and can be planned in parallel.

### Parsing Sprint Groups

After reading ROADMAP.md, build a sprint map:

```
SPRINT_MAP = { sprint_number: [phase_numbers] }
```

Parse from the Phase Details blocks (`**Sprint**: N` field) or from the Phases checklist (`[Sprint N]` annotation).

**Backward compatibility:** If no sprint annotations exist (legacy roadmaps), treat each phase as its own single-phase sprint (sprint N = phase N). This preserves sequential behavior.

### Execution Strategy

Within each sprint, phases progress through stages together:

```
SPRINT S:
  STAGE 1 - Discuss (sequential per phase)
    For each phase: adaptive depth -> discuss (AskUserQuestion requires sequential)

  STAGE 2 - Research (parallel with dependency awareness)
    Overlap analysis: scan CONTEXT.md files for shared domains
    Independent phases: Skill('research-phase', N) called in parallel
    Overlapping phases: chained sequentially (earlier feeds into later)

  STAGE 3 - Plan (parallel)
    All phases: Skill('plan-phase', N) called in parallel

  STAGE 4 - Branch + Execute (sequential, separate branches)
    Create all branches from main
    For each phase: checkout branch -> execute -> commit -> back to main

  STAGE 5 - Validate + Merge (sequential per phase)
    For each phase: validate on branch -> feedback if failed -> merge to main

  STAGE 6 - Sprint Boundary Validation
    On main: run build + tests after all phases merged
```

### Why This Parallelism Split

- **Discuss is sequential:** Each `/discuss-phase` call involves multiple AskUserQuestion rounds. Even with autonomous answers, interleaving multiple discuss sessions would cause confusion about which phase's question is being answered.
- **Research is parallel with dependency awareness:** Each `/research-phase` spawns an independent `phase-researcher` agent. Before parallelizing, overlap analysis scans CONTEXT.md files for shared technical domains. Independent phases research in parallel; overlapping phases chain sequentially so the later phase's researcher receives the earlier phase's RESEARCH.md as prior context.
- **Planning is parallel:** Each `/plan-phase` operates on an isolated phase directory.
- **Execution must be sequential (or use worktrees):** All Skill() calls share the same working directory -- you cannot checkout two branches simultaneously. Team+worktree mode enables true parallel execution.

The primary efficiency gains from sprint-based execution are:
1. **Smart parallel research** -- independent phases researched simultaneously, overlapping phases chained to preserve cross-pollination
2. **Batch planning** -- all sprint phases planned before any execute (vs interleaved plan-execute-plan-execute)
3. **Integration validation** -- sprint boundary validation catches cross-phase integration issues early
4. **Smarter ordering** -- respects the dependency graph from /create-roadmap

## 6. Git Branch Flow (Sprint-Aware)

### Per-Sprint Flow

```
SPRINT S (phases N1, N2, ... in same sprint):

PLANNING (on main branch):
  # After discuss (sequential) + research (parallel) complete for all sprint phases
  # Plan all sprint phases (parallel Skill calls)
  # Commit planning artifacts for each phase
  For each phase N in sprint:
    git add .planning/phases/{NN}-{slug}/ .planning/STATE.md .planning/ROADMAP.md .planning/BUILD-STATE.md
    git commit -m "[build] Plan sprint {S} phase {N}: {phase_name}"

BRANCH CREATION (all branches from same main commit):
  For each phase N in sprint:
    git checkout -b build/{NN}-{slug}
    git checkout main  # return to main for next branch

EXECUTION (sequential, each on own branch):
  For each phase N in sprint:
    git checkout build/{NN}-{slug}
    # /execute-phase runs all plans here
    git add -A
    git commit -m "[build] Execute phase {N}: {phase_name}"
    git checkout main

VALIDATE + MERGE (sequential per phase):
  For each phase N in sprint:
    git checkout build/{NN}-{slug}
    # Run per-phase validation
    # If fails: /phase-feedback (one attempt)
    git checkout main
    git merge --squash build/{NN}-{slug}
    git commit -m "[build] Sprint {S}, Phase {N}: {phase_name}
    ...
    Autonomous build by /build skill."
    git branch -d build/{NN}-{slug}

SPRINT BOUNDARY VALIDATION (on main, all phases merged):
  # Run build + tests to validate cross-phase integration
```

### Resume Handling

When /build resumes (compaction recovery or explicit re-invocation):

**Case 1: Active `build/*` branch(es) exist**
1. Identify which sprint is in progress from BUILD-STATE.md `Current stage` (format: `sprint-{S}-*`).
2. For each `build/*` branch in the sprint:
   - Check if execution completed: do SUMMARY.md files exist for all plans in the phase?
   - If yes: switch to main, squash-merge, and continue to next phase in sprint.
   - If no: checkout the branch and resume execution.
3. After all sprint phases handled, run sprint boundary validation.

**Case 2: On main, no `build/*` branches**
- Read BUILD-STATE.md `Current stage` field.
- Resume from that stage. If the stage is `in_progress`, re-run it from the beginning.

**Case 3: On main, BUILD-STATE.md missing or corrupt**
- Start the entire pipeline from scratch. The existing `.planning/` files from completed stages will be detected and reused where possible (e.g., /new-project detects PROJECT.md exists).

### Branch Naming Convention

Format: `build/{NN}-{slug}` where:
- `{NN}` is the zero-padded phase number (e.g., `01`, `02`, `03`)
- `{slug}` is the kebab-case phase name from ROADMAP.md (e.g., `foundation`, `auth-system`, `api-layer`)
- Example: `build/02-auth-system`

## 7. Final Validation and Auto-Fix

Runs after ALL phases complete, regardless of per-phase validation results.

### Flow

```
1. Detect validation commands (Section 3 priority order)
2. Run build command (if detected)
3. Run test command (if detected)
4. If both pass: proceed to BUILD-REPORT.md generation
5. If either fails: enter auto-fix loop
```

### Auto-Fix Loop

```
attempt = 0
max_attempts = 3

while attempt < max_attempts:
    attempt += 1

    a. Capture full error output (stdout + stderr)
    b. Analyze errors:
       - Parse error messages for file paths and line numbers
       - Categorize: build error, type error, test failure, missing dep
    c. Apply targeted fixes using Edit/Write tools:
       - Import errors: add missing imports
       - Type errors: fix type mismatches
       - Test failures: fix failing assertions or broken logic
       - Missing deps: install via package manager
    d. Re-run build + tests
    e. If pass: break (done)
    f. If fail: continue loop

if attempt >= max_attempts and still failing:
    Log all errors in BUILD-STATE.md Errors section
    Mark build status as "partial" in BUILD-STATE.md
    Proceed to BUILD-REPORT.md (include error summary)
```

### Constraints

- Each auto-fix attempt is logged in BUILD-STATE.md Errors section with: attempt number, error summary, fix applied, result
- Auto-fix must not make architectural changes -- only targeted fixes for build/test failures
- If an auto-fix would require a new dependency not in the project, log it rather than installing blindly
- The 3-attempt limit is hard -- do not extend it

## 8. Extend Mode

When /build detects a completed prior build and new feature arguments, it enters extend mode.

### Detection

All of these must be true:

- BUILD-STATE.md exists with Status: complete
- HAS_PROJECT=true (PROJECT.md exists)
- HAS_ROADMAP=true (ROADMAP.md exists)
- $ARGUMENTS is non-empty (the new feature description)

### Skipped Stages

- /new-project -- PROJECT.md already exists
- /map-codebase -- codebase already mapped
- /brainstorm -- user has a specific feature, not ideating

### Pipeline

```
1. Initialize BUILD-STATE.md with extend metadata (Build mode: extend)
2. Invoke /create-roadmap "add {feature}" -- adds new phase(s) to existing roadmap
3. Phase execution loop -- skip completed phases, execute new ones only
4. Final validation -- always runs on full codebase
5. BUILD-REPORT.md -- notes extend mode, references prior build
```

### Phase Execution in Extend Mode

Already-completed phases (detected via PHASE_COMPLETION from gather-data.sh) are skipped in the execution loop. Only newly added phases run the full discuss/research/plan/execute pipeline. Pipeline Progress marks skipped stages as `skipped (extend)`.

## 9. Phase Feedback Flow

How /build invokes /phase-feedback after a per-phase validation failure.

### Trigger Condition

Phase validation (Section 3) ran and failed: build errors, test failures, or both.

### Flow

```
1. Capture validation error output
2. Synthesize a feedback description from the errors:
   - "Build failed: {error_summary}" or "Tests failed: {failing_test_names}"
   - Include file paths and error messages (truncate to 500 chars if very long)
3. Invoke: /phase-feedback {N} {synthesized_feedback_description}
4. /phase-feedback creates a subphase (e.g., 2.1-feedback-fix) with a plan
5. Invoke: /execute-phase {N.1} to execute the feedback fix plan
6. After feedback execution, re-run the same validation commands
7. Record result in BUILD-STATE.md:
   - Validation Results table: update Feedback Attempt column
   - Phase Progress table: update Feedback column
```

### Constraints

- Only ONE feedback attempt per phase. This is a locked decision -- never retry feedback.
- If validation still fails after feedback: mark the phase as **incomplete** in BUILD-STATE.md Incomplete Phases section, record the error, and continue to the next phase.
- The feedback subphase inherits the same `build/{NN}-{slug}` feature branch -- no additional branch creation.
- /phase-feedback receives the synthesized error description as its argument, not the raw error output.
- The feedback fix plan should target only the specific failures, not re-implement the phase.
