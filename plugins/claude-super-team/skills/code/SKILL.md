---
name: code
description: Interactive coding session with project context. Applies changes through direct conversation and tracks modifications in a session log. Use for ad-hoc coding, phase refinement, or any work you want to do conversationally without pre-planning.
argument-hint: "[phase number] [description of what to work on]"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(test *), Bash(ls *), Bash(npm *), Bash(npx *), Bash(bun *), Bash(pnpm *), Bash(yarn *), Bash(git diff *), Bash(git status), Bash(mkdir *), Bash(bash *gather-data.sh)
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/code/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, EXECUTED_PHASES, CURRENT_PHASE, RECENT_SESSIONS) before proceeding.

**Context-aware skip:** If PROJECT.md, ROADMAP.md, or STATE.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/code/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Run an interactive coding session with full project context. The user describes changes conversationally, you apply them directly, and everything is tracked in a session log for later reference.

**Two modes:**
- **Phase-linked** -- refine a completed phase's deliverables with full phase context loaded
- **Free-form** -- code with project awareness, no specific phase

**Reads:** `.planning/PROJECT.md`, `ROADMAP.md`, `STATE.md`, phase artifacts (if phase-linked)

**Creates:** `.planning/.sessions/{timestamp}-{slug}.md` (session log), optional `{NN}-REFINEMENT.md` (phase-linked only)

## Process

### Phase 1: Validate Environment

PROJECT.md must exist (pre-loaded via injection above). If the injected PROJECT.md content is empty or missing:

```
No project found. Run /new-project first.
```

Exit skill.

ROADMAP.md is optional -- free-form mode works without it.

### Phase 2: Detect Mode

Parse `$ARGUMENTS` to determine session mode.

**If arguments start with a number** (e.g., `3`, `2.1`):
- Phase-linked mode. Extract phase number.
- Verify that phase has been executed (check EXECUTED_PHASES from gather-data.sh output).
- If phase not executed, warn: "Phase {N} hasn't been executed yet. Run `/execute-phase {N}` first, or continue in free-form mode?"
  - Use AskUserQuestion with header "Mode" and options: "Continue anyway" / "Switch to free-form"

**If arguments contain only text** (e.g., `fix the login bug`):
- Free-form mode with that text as the focus description.

**If arguments are empty:**

Use AskUserQuestion:
- header: "Session type"
- question: "What would you like to work on?"
- options:
  - "Refine a phase" -- "Work on a completed phase's deliverables"
  - "Free-form coding" -- "Code with project context, no specific phase"

**If "Refine a phase":**
- Parse EXECUTED_PHASES from gather-data.sh output
- If no executed phases exist: "No executed phases found. Switching to free-form mode."
- If executed phases exist, use AskUserQuestion:
  - header: "Phase"
  - question: "Which phase do you want to refine?"
  - options: list executed phases (up to 4 most recent, with phase name)
- Switch to phase-linked mode with selected phase

**If "Free-form":**
- Proceed without phase context.

### Phase 3: Load Context

**Phase-linked mode:**
- Read all files from the phase directory: PLAN.md, SUMMARY.md, VERIFICATION.md, CONTEXT.md, RESEARCH.md, REFINEMENT.md (if any exist)
- Note key findings: what was built, what verification found, any gaps

**Free-form mode:**
- PROJECT.md, ROADMAP.md, STATE.md already loaded via injection
- If `.planning/codebase/` exists, read ARCHITECTURE.md and STRUCTURE.md for codebase awareness

### Phase 4: Initialize Session

Create session log directory and file:

```bash
mkdir -p .planning/.sessions
```

Create `.planning/.sessions/{timestamp}-{slug}.md` where:
- `{timestamp}` = current date in `YYYY-MM-DD-HHMM` format
- `{slug}` = kebab-case summary of focus (e.g., `phase-3-refinement`, `login-bug-fix`, `free-form`)

**Session log initial content:**

```markdown
# Coding Session: {description}

- **Date:** {YYYY-MM-DD}
- **Mode:** {Phase-linked (Phase N: Name) | Free-form}
- **Focus:** {user's description or phase goal}

## Changes

```

### Phase 5: Present Session Start

Brief context summary based on mode:

**Phase-linked:**
```
Session started: Phase {N} refinement
Loaded {X} plans, {Y} summaries from phase directory.
{One-line summary of phase goal from ROADMAP.md}

Describe what you'd like to change.
```

**Free-form:**
```
Session started: {focus description or "free-form coding"}
Project context loaded.

Describe what you'd like to work on.
```

Do not use AskUserQuestion here. Let the user drive from this point.

### Phase 6: Interactive Loop

This phase is behavioral -- it defines how to handle each user request during the session.

**For each change the user requests:**

1. **Understand** -- Clarify if needed using AskUserQuestion, but default to acting. Bias toward doing, not asking.
2. **Implement** -- Use Read, Edit, Write, Glob, Grep to make changes. Read files before editing.
3. **Verify** -- Run relevant tests or builds when the change warrants it:
   - `Bash(test *)` for test suites
   - `Bash(npm *)`, `Bash(bun *)`, etc. for builds
   - `Bash(git diff *)` to show what changed
4. **Log** -- Append an entry to the session log:
   ```markdown
   ### {HH:MM} - {brief description}
   - **Files:** {list of modified files}
   - **What:** {1-2 sentence summary}
   ```
5. **Report** -- Tell the user what was done. Show key changes, test results. Keep it brief.

**Guidelines:**
- Apply changes directly. Do not ask "should I proceed?" for straightforward requests.
- If a change is ambiguous or has multiple valid approaches, ask once with AskUserQuestion then act.
- Run tests after changes that could break things, not after every edit.
- Keep session log entries concise -- they're for reference, not documentation.

### Phase 7: Session End

When the user says "done", "wrap up", "finish", "that's it", or similar:

1. **Read the session log** to review all changes made.

2. **Phase-linked mode:**
   - Create `{NN}-REFINEMENT.md` in the phase directory (e.g., `.planning/phases/03-api/03-REFINEMENT.md`):
     ```markdown
     # Phase {N} Refinement

     **Date:** {YYYY-MM-DD}
     **Session:** {link to session log path}

     ## Changes Made

     {Summarize each change from session log -- what changed and why}

     ## Files Modified

     {List all unique files modified during session}
     ```

3. **Free-form mode:**
   - Append a summary section to the session log itself:
     ```markdown
     ## Summary

     **Files modified:** {count}
     {List all unique files}

     **Changes:** {brief summary of what was accomplished}
     ```

4. **Suggest commit:**
   ```
   Session complete. {N} changes applied across {M} files.

   To commit:
     git add {list key files}
     git commit -m "{suggested message}"
   ```

   Never auto-commit.

## Edge Cases

### User wants to switch modes mid-session
If user asks to work on a different phase or switch to free-form, load the new context and note the switch in the session log. Continue the same session.

### No changes made
If user ends session with no changes, skip REFINEMENT.md creation and commit suggestion. Just note "No changes made" and clean up the empty session log.

### Multiple sessions on same phase
Each session creates its own log file and REFINEMENT.md is overwritten (latest refinement is what matters). Previous session logs remain in `.planning/.sessions/`.

## Success Criteria

- [ ] Session mode correctly detected
- [ ] Phase context loaded (phase-linked) or project context loaded (free-form)
- [ ] Session log created and maintained throughout
- [ ] Changes applied as requested
- [ ] REFINEMENT.md created (phase-linked) or summary appended (free-form)
- [ ] Commit command suggested with relevant files
- [ ] Never auto-committed
