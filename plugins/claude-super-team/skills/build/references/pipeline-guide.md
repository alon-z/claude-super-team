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
6.  For each phase N in ROADMAP.md:
    a. Evaluate adaptive pipeline depth (Section 2)
    b. [If full pipeline] Invoke /discuss-phase N
    c. [If full pipeline] Invoke /research-phase N
    d. Invoke /plan-phase N
    e. Git: commit planning artifacts on main
    f. Git: create feature branch build/{NN}-{slug}
    g. Invoke /execute-phase N
    h. Git: commit execution results on feature branch
    i. [If adaptive validation says yes (Section 3)] Run build + tests
    j. [If validation fails] Invoke /phase-feedback N (one attempt only)
    k. [If still fails] Mark phase incomplete, continue to next
    l. Git: squash-merge feature branch to main, delete branch
    m. Update BUILD-STATE.md phase progress
7.  Final validation -- always run (Section 6)
8.  [If fails] Auto-fix loop (max 3 attempts)
9.  Generate BUILD-REPORT.md
10. Present completion summary to user
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

## 5. Git Branch Flow

### Per-Phase Flow

```
PLANNING (on main branch):
  # After discuss/research/plan complete for phase N
  git add .planning/phases/{NN}-{slug}/ .planning/STATE.md
  git commit -m "[build] Plan phase {N}: {phase_name}"

BRANCH CREATION (before execution):
  git checkout -b build/{NN}-{slug}

EXECUTION (on feature branch):
  # /execute-phase runs all plans here
  # After execution completes
  git add -A
  git commit -m "[build] Execute phase {N}: {phase_name}"

  # If validation runs and feedback is needed:
  # /phase-feedback creates subphase, /execute-phase runs it
  git add -A
  git commit -m "[build] Fix phase {N}: {phase_name}"

SQUASH-MERGE (after execution + validation):
  git checkout main
  git merge --squash build/{NN}-{slug}
  git commit -m "[build] Phase {N}: {phase_name}

  {1-2 sentence summary of what was built}

  Validation: {pass|fail|skipped}
  Plans executed: {M}/{total}

  Autonomous build by /build skill."

CLEANUP:
  git branch -d build/{NN}-{slug}
```

### Resume Handling

When /build resumes (compaction recovery or explicit re-invocation):

**Case 1: Active `build/*` branch exists**
1. Check if execution completed: do SUMMARY.md files exist for all plans in the phase?
2. If yes: switch to main, squash-merge, and continue to the next phase.
3. If no: stay on the branch and resume execution from the first incomplete plan.

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

## 6. Final Validation and Auto-Fix

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

## 7. Phase Feedback Flow

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
