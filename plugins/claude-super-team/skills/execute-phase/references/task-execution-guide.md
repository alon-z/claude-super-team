# Task Execution Guide

You are executing a single task from a phase plan. Follow these instructions exactly.

## Input

You receive:
- **Task details:** `<name>`, `<files>`, `<action>`, `<verify>`, `<done>`
- **Plan context:** Objective, must_haves, prior task summaries (if sequential)
- **Project context:** PROJECT.md, relevant codebase docs

## Execution Process

1. **Read existing files** listed in `<files>` before modifying. Understand current state.
2. **Execute `<action>`** precisely. Follow the specific instructions -- do not reinterpret.
3. **Run `<verify>`** commands. Fix issues until verification passes.
4. **Check `<done>`** criteria. Every acceptance criterion must be met.
5. **Commit** atomically (see Commit Protocol below).
6. **Report** results in structured format.

## Deviation Rules

You will encounter situations not covered by the plan. Handle them:

**Auto-fix (do it, report it):**
- Logic errors, type errors, broken imports
- Missing error handling, input validation
- SQL injection, XSS, race conditions
- Missing dependencies blocking the task
- Broken imports from prior tasks

**STOP and report (do NOT proceed):**
- New database tables or major schema changes
- New service layers or infrastructure
- Library/framework switches
- API breaking changes
- Auth approach changes

When auto-fixing, record what you fixed and why in your report.

## Commit Protocol

After completing the task, stage and commit:

```
{type}({phase}-{plan}): {task-name}

- {key change 1}
- {key change 2}
```

Types: `feat`, `fix`, `test`, `refactor`, `perf`, `docs`, `style`, `chore`

Rules:
- Stage specific files (never `git add .` or `git add -A`)
- One commit per task
- Commit message must reference phase-plan scope

## TDD Execution

If the plan type is `tdd`, follow RED-GREEN-REFACTOR:

1. **RED:** Write failing test. Commit: `test({phase}-{plan}): {task-name}`
2. **GREEN:** Implement minimal code to pass. Commit: `feat({phase}-{plan}): {task-name}`
3. **REFACTOR:** Clean up if needed. Commit: `refactor({phase}-{plan}): {task-name}`

## Strategic CLAUDE.md Files

After completing your task, evaluate whether any directory you created or heavily modified warrants a CLAUDE.md file. These files help the next developer who enters the directory understand critical, non-obvious context.

**When to create one:** Only when the directory contains something a developer MUST know that is not obvious from reading the code -- e.g., a non-standard auth flow, a critical ordering constraint, an unusual data format, a gotcha that would cause bugs if missed.

**When NOT to create one:** Do not create CLAUDE.md files for straightforward code, standard patterns, or directories where the code is self-explanatory. Most directories do NOT need one.

**Rules:**
- Maximum 3-5 lines. One-liners are preferred.
- No boilerplate, no headers, no formatting fluff. Just the critical facts.
- If a CLAUDE.md already exists in the directory, append your line(s) to it rather than overwriting.
- Do not duplicate what the code already says. Only capture what you CANNOT see from reading the code.

**Examples:**

```
# src/auth/CLAUDE.md
Refresh tokens use rotating scheme -- old token invalidated on use. See /api/auth/refresh.
Session cookie is httpOnly + secure + sameSite=strict. Never expose token to client JS.
```

```
# src/db/migrations/CLAUDE.md
Migrations run in alphabetical order. Prefix with timestamp, not sequence number.
```

```
# src/payments/CLAUDE.md
Stripe webhook signature verification is mandatory. Raw body must be preserved (no JSON parsing middleware).
```

## Self-Check

Before reporting completion, verify:
- All files in `<files>` exist
- Commit exists: `git log --oneline -1 --grep="{phase}-{plan}"`
- `<verify>` commands pass
- `<done>` criteria met

If ANY check fails, report `SELF_CHECK: FAILED` with details.

## Report Format

```markdown
## TASK COMPLETE

**Task:** {task-name}
**Status:** complete | failed | blocked
**Commit:** {hash} {message}

### Files
- Created: {list}
- Modified: {list}

### Deviations
{any auto-fixes applied, or "None"}

### Self-Check
{PASSED | FAILED with details}

### Notes
{anything the next task or orchestrator needs to know}
```

If blocked or failed:

```markdown
## TASK BLOCKED

**Task:** {task-name}
**Reason:** {what went wrong}
**Attempted:** {what you tried}
**Needs:** {what would unblock this}
```
