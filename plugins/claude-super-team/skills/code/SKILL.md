---
name: code
description: Interactive coding session with project context. Applies changes through direct conversation and tracks modifications in a session log. Pre-loads relevant skills from the catalog for each new user request. Use for ad-hoc coding, phase refinement, or any work you want to do conversationally without pre-planning.
argument-hint: "[phase number] [description of what to work on]"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Skill, Bash(test *), Bash(ls *), Bash(npm *), Bash(npx *), Bash(bun *), Bash(pnpm *), Bash(yarn *), Bash(git diff *), Bash(git status), Bash(mkdir *), Bash(date *), Bash(bash *gather-data.sh)
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

**Timestamp convention:** You do not have a clock. NEVER guess or fabricate timestamps. Always get the real time by running `date "+%Y-%m-%d %H:%M"`. Use the full output for `YYYY-MM-DD HH:MM` fields and the `%H:%M` portion for `HH:MM` fields. Run this command every time you need a timestamp -- do not reuse a previously fetched value if more than a few seconds have passed.

Create session log directory and file:

```bash
mkdir -p .planning/.sessions
```

Run `date "+%Y-%m-%d-%H%M"` to get the timestamp for the filename.

Create `.planning/.sessions/{timestamp}-{slug}.md` where:
- `{timestamp}` = output of `date "+%Y-%m-%d-%H%M"`
- `{slug}` = kebab-case summary of focus (e.g., `phase-3-refinement`, `login-bug-fix`, `free-form`)

**Session log initial content** (run `date "+%Y-%m-%d"` for the date field):

```markdown
# Coding Session: {description}

- **Date:** {date output}
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

**Session skill tracking:** Maintain an in-memory list of skills you have already loaded during this session (call it `loaded_skills`). It starts empty at Phase 5 and grows as you pre-load skills in step 2 below. Never re-invoke a skill that is already in `loaded_skills` -- the Skill tool's description warns that invoking an already-running skill is a no-op and wastes context.

**For each change the user requests:**

1. **Understand** -- Clarify if needed using AskUserQuestion, but default to acting. Bias toward doing, not asking.
2. **Select & pre-load skills** -- Before touching files, decide which skills from the live catalog are relevant to THIS request:
   - Look at the "skills are available for use with the Skill tool" system reminder. That list is your source of truth -- do not invent or guess skill names.
   - Pick 0-3 skills that directly match the request's domain (iOS + `swiftui-expert:swiftui-expert-skill`, Expo + `expo-app-design:building-native-ui`, Neon + `neon-postgres`, Fly + `fly`, etc.), or the tool/CLI the task will actually invoke (`xcodebuildmcp-cli`, `vercel-cli`, `firecrawl-scrape`, `playwright-cli`).
   - Exclude: skills already in `loaded_skills`; `claude-super-team:*` meta/workflow skills; skills from unrelated domains; pure research/image/notebook skills unless the task explicitly needs them.
   - For each chosen skill, invoke it: `Skill(skill: "{fully-qualified-name}")` -- use the exact name from the catalog. Then append it to `loaded_skills`.
   - If the request is trivial (rename a variable, fix a typo, tweak copy) and no skill is a clear match, skip this step entirely. Over-loading skills is worse than loading none.
   - If a skill invocation fails (unknown name, plugin missing), note it in the session log's change entry under a `- **Skill miss:**` line and continue with your own judgment.
3. **Implement** -- Use Read, Edit, Write, Glob, Grep to make changes, following any patterns loaded in step 2. Read files before editing.
4. **Verify** -- Run relevant tests or builds when the change warrants it:
   - `Bash(test *)` for test suites
   - `Bash(npm *)`, `Bash(bun *)`, etc. for builds
   - `Bash(git diff *)` to show what changed
5. **Log** -- Run `date "+%H:%M"` then append an entry to the session log:
   ```markdown
   ### {HH:MM from date command} - {brief description}
   - **Files:** {list of modified files}
   - **Skills loaded:** {new skills loaded this turn, or "none"}
   - **What:** {1-2 sentence summary}
   ```
6. **Report** -- Tell the user what was done. Show key changes, test results. Keep it brief. If you loaded skills, mention them in one short clause so the user can see your reasoning.

**Guidelines:**
- Apply changes directly. Do not ask "should I proceed?" for straightforward requests.
- If a change is ambiguous or has multiple valid approaches, ask once with AskUserQuestion then act.
- Run tests after changes that could break things, not after every edit.
- Keep session log entries concise -- they're for reference, not documentation.
- Skills persist across turns within this session. Load once, reuse.
- When the user's focus shifts to a new domain mid-session (e.g., switches from backend to SwiftUI views), re-run step 2 against the new request -- do not assume earlier-loaded skills still cover the new work.

### Phase 7: Session End

When the user says "done", "wrap up", "finish", "that's it", or similar:

1. **Read the session log** to review all changes made.

2. **Phase-linked mode:**
   - Run `date "+%Y-%m-%d"` for the date. Create `{NN}-REFINEMENT.md` in the phase directory (e.g., `.planning/phases/03-api/03-REFINEMENT.md`):
     ```markdown
     # Phase {N} Refinement

     **Date:** {date output}
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
- [ ] For every non-trivial user request, relevant skills were selected from the live catalog and pre-loaded before making changes (or deliberately skipped for trivial edits)
- [ ] No skill was re-loaded within the same session (`loaded_skills` dedup respected)
- [ ] Changes applied as requested
- [ ] REFINEMENT.md created (phase-linked) or summary appended (free-form)
- [ ] Commit command suggested with relevant files
- [ ] Never auto-committed
