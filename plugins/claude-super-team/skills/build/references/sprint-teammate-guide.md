# Sprint Teammate Guide

Instructions for a sprint teammate executing a single phase in an isolated worktree during parallel sprint execution. This guide is embedded in the teammate's prompt by the build lead.

---

## Overview

You are a sprint teammate responsible for executing one phase of a multi-phase sprint. You work in an isolated git worktree so your changes don't conflict with other teammates executing other phases concurrently. After execution, the build lead merges your worktree branch to main.

## Step 1: Enter Worktree

Create an isolated working copy:

```
EnterWorktree(name: "{worktree_name}")
```

Record the worktree branch name immediately:

```bash
git branch --show-current
```

Save this branch name -- you must report it when done.

## Step 2: Execute Phase

Invoke execute-phase in task mode (avoids nested teams):

```
Skill('claude-super-team:execute-phase', '{phase_number} --no-team')
```

### Autonomous Decision Protocol

When execute-phase presents AskUserQuestion, answer autonomously:

| Question | Answer | Confidence |
|----------|--------|------------|
| Branch warning ("on main") | "Continue anyway" -- you are in a worktree, not on main | high |
| Exec model | Use **{exec_model}** | high |
| Task blocked / needs human input | "Skip task" -- cannot get human guidance | low |
| Checkpoint: human-verify | AUTO-APPROVE | low |
| Checkpoint: decision | Use LLM reasoning based on project context | medium |
| Verification gaps / gap closure | "Accept as-is" -- lead handles final validation | medium |

**IGNORE "Next Steps" output** from execute-phase. It is for standalone use. Continue with Step 3.

## Step 3: Commit Execution Results

After execute-phase completes, commit all changes:

```bash
git add -A
git commit -m "[build] Execute phase {N}: {phase_name}"
```

## Step 4: Validate

Detect and run build/test commands using the first matching indicator:

| Priority | Indicator | Build Command | Test Command |
|----------|-----------|---------------|--------------|
| 1 | `bun.lockb` exists | `bun run build` | `bun test` |
| 2 | `package.json` with scripts | `npm run build` (if "build" script) | `npm test` (if "test" script) |
| 3 | `Makefile` or `makefile` | `make build` (if target exists) | `make test` (if target exists) |
| 4 | `Cargo.toml` | `cargo build` | `cargo test` |
| 5 | `go.mod` | `go build ./...` | `go test ./...` |
| 6 | `pyproject.toml` / `setup.py` | None | `pytest` |
| 7 | None detected | Skip build | Skip tests |

**Skip validation entirely** if phase only created/modified `.planning/` files or documentation (no source code, no dependencies, no test files).

Record the validation result: `pass`, `fail`, or `skipped`.

## Step 5: Feedback (On Validation Failure Only)

If validation failed, make ONE feedback attempt:

1. Synthesize the error: `"Build failed: {error_summary}"` or `"Tests failed: {failing_test_names}"`
2. Invoke phase-feedback:
   ```
   Skill('claude-super-team:phase-feedback', '{N} {synthesized_error_description}')
   ```
3. Answer any AskUserQuestion calls autonomously (same protocol as Step 2).
4. If phase-feedback creates a subphase (e.g., N.1), execute it:
   ```
   Skill('claude-super-team:execute-phase', '{N.1} --no-team')
   ```
5. Commit fix results:
   ```bash
   git add -A
   git commit -m "[build] Fix phase {N}: {phase_name}"
   ```
6. Re-run the same validation commands from Step 4.
7. Record result:
   - **If pass:** `feedback_result = "pass"`
   - **If still fails:** `feedback_result = "fail"`. Log as incomplete, continue to Step 6.

If validation passed or was skipped: `feedback_result = "N/A"`.

## Step 6: Exit Worktree

Exit the worktree, keeping all changes and commits:

```
ExitWorktree(action: "keep")
```

## Step 7: Report and Complete

Mark your task as completed:

```
TaskUpdate(taskId: "{task_id}", status: "completed")
```

Send your completion report to the lead. Use this exact format so the lead can parse it:

```
## PHASE {N} COMPLETE

- **Branch:** {branch name from Step 1}
- **Validation:** {pass | fail | skipped}
- **Feedback:** {pass | fail | N/A}
- **Plans completed:** {M}/{total}
- **Summary:** {1-2 sentence summary of what was built}
```

## Error Handling

- **EnterWorktree fails:** Report the error immediately. Do not attempt execute-phase.
- **Execute-phase crashes:** Still commit whatever was done (`git add -A && git commit`), run validation, then exit worktree and report with details.
- **Validation command not found:** Report `skipped` with a note about missing build system.
- **ExitWorktree fails:** Report the error. The lead can clean up manually.

In ALL error cases: always exit the worktree (or attempt to) and always report results. Never leave silently.
