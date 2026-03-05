---
name: phase-feedback
description: Collect user feedback on a just-executed phase and either apply a quick fix directly or plan a feedback subphase for execution. For trivial changes (single-file quick fixes), applies the change inline. For anything larger, creates a feedback subphase with a plan and directs the user to run /execute-phase. Use after /execute-phase when the user wants changes to delivered work. Requires .planning/PROJECT.md and .planning/ROADMAP.md.
argument-hint: "[phase number] [feedback description]"
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(mkdir *), Bash(bash *gather-data.sh)
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/phase-feedback/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, EXECUTED_PHASES, CURRENT_PHASE, SUBPHASES) before proceeding.

**Context-aware skip:** If PROJECT.md, ROADMAP.md, or STATE.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/phase-feedback/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Collect feedback on a just-executed phase, then route based on scope:
- **Quick fix** (trivial, single-file change): Apply the fix directly inline -- no subphase, no plan, no agent spawning.
- **Standard feedback** (anything else): Create a feedback-driven subphase with decimal numbering (e.g., 4.1), plan targeted modifications, then tell the user to run `/execute-phase` to execute.

**Flow:** Validate -> Identify parent phase -> Load execution context -> Collect feedback -> Scope check -> Route (quick fix OR standard) -> Research (if needed) -> Done

**Reads:** `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, parent phase `*-SUMMARY.md` and `*-VERIFICATION.md`
**Creates (standard path only):** `.planning/phases/{NN.X}-feedback-{slug}/{NN.X}-01-PLAN.md`, annotates `ROADMAP.md`. Optionally creates `{NN.X}-RESEARCH.md` if inline research is triggered.

## Process

### Step 1: Validate Environment

PROJECT.md, ROADMAP.md, and STATE.md are pre-loaded via dynamic context injection. If their contents are empty/missing from the injection, show the appropriate error and exit:

- No PROJECT.md content: "ERROR: No project found. Run /new-project first."
- No ROADMAP.md content: "ERROR: No roadmap found. Run /create-roadmap first."

### Step 2: Identify Parent Phase

Parse `$ARGUMENTS` for a phase number. If present, use it as `$PARENT_PHASE`.

If no phase number in arguments, auto-detect using pre-loaded data:

1. Use the **CURRENT_PHASE** value from the gather script
2. Use the **EXECUTED_PHASES** list from the gather script (phases with SUMMARY.md files)
3. If ambiguous, ask the user:

```
AskUserQuestion:
  header: "Which phase?"
  question: "Which phase do you want to give feedback on?"
  options: [list discovered phases that have SUMMARY.md files]
```

Resolve the phase directory:

```bash
PARENT_NUM=$(printf "%02d" "$PARENT_PHASE")
PARENT_DIR=$(ls -d .planning/phases/${PARENT_NUM}-* 2>/dev/null | head -1)
```

If no phase directory or no SUMMARY.md files in it, show error: "Phase {N} has no execution results. Run /execute-phase {N} first."

### Step 3: Load Execution Context

Read all execution artifacts from the parent phase:

```bash
# Summaries -- what was built
ls "${PARENT_DIR}"/*-SUMMARY.md

# Verification -- what passed/failed
ls "${PARENT_DIR}"/*-VERIFICATION.md
```

Store the contents as `$EXECUTION_CONTEXT`. This gives the planner full visibility into what exists.

### Step 4: Collect Feedback

Read `${CLAUDE_SKILL_DIR}/references/feedback-collection.md` for the iterative feedback collection procedure.

### Step 5: Scope Check and Route

Analyze the confirmed feedback to determine scope:

**5a. Check for overly broad feedback.** If it implies:
- More than 5 files
- Multiple subsystems or services
- Architectural changes

Warn the user:

```
This feedback seems too broad for a subphase. Consider:
- /plan-phase {N+1} for a dedicated phase
- Breaking this into multiple /phase-feedback calls
```

Use AskUserQuestion to confirm: "Proceed as feedback subphase?" or "Use full phase instead?"

**5b. Classify scope.** Use AskUserQuestion:

```
AskUserQuestion:
  header: "Scope"
  question: "Based on the feedback, this looks like a {quick fix / standard change}. How should we handle it?\n\n{bullet list of feedback items}"
  options:
    - "Quick fix" -- "Apply the change directly right now (best for single-file tweaks, typos, small style/logic fixes)"
    - "Plan it" -- "Create a feedback subphase with a plan, then execute with /execute-phase (best for multi-file or complex changes)"
```

Route based on the user's choice:
- If "Quick fix" -> Go to Step 6 (Quick Fix Path)
- If "Plan it" -> Go to Step 7 (Standard Feedback Path)

---

## Quick Fix Path

### Step 6: Apply Quick Fix

Read `${CLAUDE_SKILL_DIR}/references/quick-fix-guide.md` for the quick fix application flow.

---

## Standard Feedback Path

Read `${CLAUDE_SKILL_DIR}/references/feedback-subphase-guide.md` for the full subphase creation and planning procedure (Steps 7-12).

### Step 13: Done

Present the plan summary and direct the user to execute:

```
Phase ${FEEDBACK_PHASE} planned (feedback on Phase ${PARENT_PHASE}).

Feedback: ${FEEDBACK}
Plan: ${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-PLAN.md
Directory: ${PHASE_DIR}

---

## Next Steps

**Review the plan:**
  Read ${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-PLAN.md

**Execute the feedback changes:**
  /execute-phase ${FEEDBACK_PHASE} --skip-verify

**More feedback?**
  /phase-feedback ${PARENT_PHASE} to create another feedback subphase (${PARENT_PHASE}.${DECIMAL+1})

**Commit planning artifacts if desired:**
  git add ${PHASE_DIR}/ .planning/ROADMAP.md .planning/STATE.md && git commit -m "plan feedback phase ${FEEDBACK_PHASE}: ${FEEDBACK summary}"

---
```

Never auto-commit.

## Success Criteria

**Common (both paths):**
- [ ] `.planning/PROJECT.md` and `.planning/ROADMAP.md` exist
- [ ] Parent phase identified (from args, STATE.md, or user)
- [ ] Parent phase has execution results (SUMMARY.md files)
- [ ] Execution context loaded (summaries + verification)
- [ ] Feedback collected and confirmed through iterative AskUserQuestion
- [ ] Scope validated (not too broad for a subphase)
- [ ] User chose route: quick fix or standard feedback

**Quick fix path:**
- [ ] Change applied directly using Edit/Write tools
- [ ] No subphase, plan, or agent spawning created
- [ ] User told how to commit (never auto-commit)

**Standard feedback path:**
- [ ] Decimal subphase number calculated (e.g., 4.1)
- [ ] Phase directory created at `.planning/phases/{NN.X}-feedback-{slug}/`
- [ ] ROADMAP.md annotated with feedback phase entry (no restructuring)
- [ ] STATE.md updated to point to feedback phase
- [ ] Research need analyzed after feedback confirmed
- [ ] Researcher spawned inline when research needed, RESEARCH.md passed to planner
- [ ] Planner spawned (opus) with execution context + feedback
- [ ] `{NN.X}-01-PLAN.md` created with 1-3 modification-oriented tasks
- [ ] Execution NOT performed -- user directed to `/execute-phase {N.X} --skip-verify`
- [ ] User told how to commit planning artifacts (never auto-commit)
- [ ] User told about `/phase-feedback` for additional feedback rounds
