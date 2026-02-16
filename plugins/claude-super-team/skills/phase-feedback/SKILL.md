---
name: phase-feedback
description: Collect user feedback on a just-executed phase and either apply a quick fix directly or plan a feedback subphase for execution. For trivial changes (single-file quick fixes), applies the change inline. For anything larger, creates a feedback subphase with a plan and directs the user to run /execute-phase. Use after /execute-phase when the user wants changes to delivered work. Requires .planning/PROJECT.md and .planning/ROADMAP.md.
argument-hint: "[phase number] [feedback description]"
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(mkdir *), Bash(bash *gather-data.sh)
---

<!-- Dynamic context injection: pre-load core planning files -->
!`cat .planning/PROJECT.md 2>/dev/null`
!`cat .planning/ROADMAP.md 2>/dev/null`
!`cat .planning/STATE.md 2>/dev/null`

<!-- Structured data: executed phases, current phase, subphase numbers -->
!`bash "${CLAUDE_PLUGIN_ROOT}/skills/phase-feedback/gather-data.sh"`

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

**The goal of this step is to fully understand what the user wants changed before planning anything.** Vague feedback leads to wrong plans. Use AskUserQuestion iteratively until you have concrete, actionable feedback.

**4a. Initial feedback collection:**

If `$ARGUMENTS` contains feedback text (beyond the phase number), use it as the starting point -- but still proceed to 4b to clarify.

If no feedback in arguments, use AskUserQuestion:

```
AskUserQuestion:
  header: "Feedback"
  question: "What would you like to change about Phase {N}'s output?"
  options:
    - "Visual/Design" -- "Change how something looks (layout, styling, colors)"
    - "Behavior" -- "Change how something works (interactions, logic, flow)"
    - "Missing feature" -- "Add something that was left out"
    - "Quality" -- "Fix bugs, improve performance, or harden"
```

**4b. Drill down into specifics:**

After receiving the initial feedback (from args or the question above), ask targeted follow-ups to remove ambiguity. Use AskUserQuestion for each area that needs clarification. Examples:

- If "visual/design": "Which part of the UI needs to change?" with options listing specific components/pages from the parent phase summaries
- If "behavior": "What should happen differently?" with options describing current vs desired behavior
- If "missing feature": "What specifically is missing?" with options based on what was NOT built in the parent phase
- If feedback mentions a specific page/component: "How should {component} look/work instead?" with concrete alternatives

**4c. Confirm understanding:**

Summarize the collected feedback back to the user and confirm with AskUserQuestion:

```
AskUserQuestion:
  header: "Confirm"
  question: "Here's what I understand you want changed:\n\n{bullet list of specific changes}\n\nIs this accurate?"
  options:
    - "Yes, proceed" -- "This captures my feedback correctly"
    - "Not quite" -- "I want to clarify or add something"
```

If "Not quite," loop back to 4b and ask what needs adjusting.

**4d. Store final feedback:**

Only after confirmation, store as `$FEEDBACK`. This should be a concrete, specific description -- not a vague wish. Good: "Change the marketplace grid from 2 columns to 3 columns, add plugin icons to each card, and make the search bar full-width." Bad: "Make the marketplace look better."

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

This path is for trivial changes: single-file tweaks, typos, small style or logic fixes. No subphase, no plan, no agent spawning.

**6a. Locate target files.** Read the target file(s) mentioned in the feedback. Use the execution context from Step 3 to locate exact file paths.

**6b. Apply changes.** Apply the change directly using Edit/Write tools. Keep the change minimal and focused on exactly what the feedback requested.

**6c. Verify changes.** Verify the change works (run relevant commands if applicable).

**6d. Present completion summary:**

```
Quick fix applied for Phase ${PARENT_PHASE}.

Feedback: ${FEEDBACK}
Files changed: {list of files modified}

---

## Next Steps

**More feedback?**
  /phase-feedback ${PARENT_PHASE}

**Continue to next phase:**
  /progress to see what's next

**Commit if desired:**
  git add {changed files} && git commit -m "fix: {short description of fix}"

---
```

Never auto-commit. **STOP here -- do not continue to Step 7.**

---

## Standard Feedback Path

### Step 7: Determine Subphase Number

Use the pre-loaded **SUBPHASES** list from the gather script to find existing subphases of the parent. Each line is a directory name containing `.` (e.g., `02.1-feedback-fix-layout`).

Filter to subphases matching `${PARENT_NUM}.*`. Find the highest decimal. Set `DECIMAL` to `highest + 1` (or `1` if none exist).

```
FEEDBACK_PHASE="${PARENT_PHASE}.${DECIMAL}"
FEEDBACK_PHASE_PADDED=$(printf "%02d.%s" "$PARENT_PHASE" "$DECIMAL")
```

### Step 8: Create Phase Directory

```bash
slug=$(echo "$FEEDBACK" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-30)

PHASE_DIR=".planning/phases/${FEEDBACK_PHASE_PADDED}-feedback-${slug}"
mkdir -p "$PHASE_DIR"
```

Report: `Creating Phase ${FEEDBACK_PHASE}: Feedback on Phase ${PARENT_PHASE}`

### Step 9: Annotate ROADMAP.md

Add entry **without restructuring existing phases**.

**9a. Add to the `## Phases` checklist** after the parent phase entry:

```markdown
- [ ] Phase {FEEDBACK_PHASE}: {FEEDBACK summary} (FEEDBACK on Phase {PARENT_PHASE})
```

**9b. Add a brief section** in `## Phase Details` after the parent phase's detail section:

```markdown
### Phase {FEEDBACK_PHASE}: Feedback -- {FEEDBACK summary} (FEEDBACK on Phase {PARENT_PHASE})

**Goal:** Address user feedback on Phase {PARENT_PHASE} deliverables
**Type:** Feedback subphase -- modifies existing work, no research/verification
**Parent:** Phase {PARENT_PHASE}

Success Criteria:
1. {1-2 observable criteria derived from the feedback}
```

Use Edit tool to insert at correct positions. Do NOT renumber or move existing phases.

**9c. Revert parent phase completion** -- In the `## Phases` checklist, change the parent phase entry from `- [x]` back to `- [ ]`. In the `## Progress` table, update the parent phase row: set Status back to "In Progress" and clear the Completed date. The parent phase is not truly complete until its feedback subphase is also done.

**9d. Update STATE.md** -- set current phase to the feedback subphase so `/execute-phase` picks it up.

### Step 10: Detect Research Need

After the subphase directory is created and ROADMAP.md is annotated, analyze the confirmed feedback (`$FEEDBACK`) together with the execution context (`$EXECUTION_CONTEXT`) to determine if research is needed before planning.

**Analysis criteria:**

1. Does the feedback reference packages, libraries, or APIs not present in the parent phase's stack?
2. Does it require integration with external services or protocols the project hasn't used before?
3. Does it involve architectural patterns or techniques not evident in existing code?

Set two variables based on analysis:
- `$RESEARCH_NEEDED`: yes or no
- `$RESEARCH_TOPICS`: brief description of what needs researching (empty if no)

Inform the user of the decision:
- If yes: "Research needed: feedback references {topic} -- spawning researcher before planning."
- If no: "No research needed -- proceeding to planning."

This is an autonomous LLM decision. Do NOT ask the user for confirmation. The goal is to keep the flow frictionless while ensuring unfamiliar territory gets researched.

### Step 11: Spawn Researcher (conditional)

This step only runs if `$RESEARCH_NEEDED` is yes. Skip to Step 12 otherwise.

Spawn the `phase-researcher` custom agent via Task tool, using the same pattern as `/research-phase`:

```
Task(
  subagent_type: "phase-researcher"
  description: "Inline research: Phase ${FEEDBACK_PHASE}"
  prompt: """
  Research Phase ${FEEDBACK_PHASE}: Feedback on Phase ${PARENT_PHASE}
  Phase goal: ${FEEDBACK}
  Research focus: ${RESEARCH_TOPICS}
  ---
  Project context: {project_md_content}
  Roadmap: {roadmap_content}
  State: {state_content}
  Existing stack: {stack_content}
  Existing architecture: {architecture_content}
  ---
  Write RESEARCH.md to: ${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-RESEARCH.md
  Return RESEARCH COMPLETE or RESEARCH BLOCKED when done.
  """
)
```

**Context to pass:**
- `.planning/PROJECT.md` (required)
- `.planning/ROADMAP.md` (required)
- `.planning/STATE.md` (if exists)
- `.planning/codebase/STACK.md`, `ARCHITECTURE.md` (if exist)
- `$FEEDBACK` as the phase goal (the feedback IS the goal for a feedback subphase)
- `$RESEARCH_TOPICS` as the research focus

**After the researcher returns:**

1. Read and store the RESEARCH.md content as `$RESEARCH_CONTENT`
2. If the researcher returned `RESEARCH BLOCKED`, inform the user and proceed to planning without research (do not block the feedback flow):
   "Research was blocked: {reason}. Proceeding to planning without research findings."

### Step 12: Spawn Planner Agent

Read `references/planner-feedback-mode.md` and `assets/feedback-plan-template.md`. Load project context.

**Context to load:**
- `.planning/PROJECT.md` (required)
- `.planning/ROADMAP.md` (required, includes the annotation just added)
- `.planning/STATE.md` (if exists)
- `.planning/codebase/ARCHITECTURE.md`, `STACK.md`, `CONVENTIONS.md` (if exist)
- Parent phase execution context (`$EXECUTION_CONTEXT`)

Spawn via Task tool:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Feedback plan: Phase ${FEEDBACK_PHASE}"
  prompt: """
  You are a planner agent in feedback mode. Follow these instructions:

  {planner_feedback_mode_content}

  ---

  Plan template to use:

  {feedback_plan_template_content}

  ---

  Phase: ${FEEDBACK_PHASE} - Feedback on Phase ${PARENT_PHASE}
  Phase directory: ${PHASE_DIR}
  Parent phase: ${PARENT_PHASE}

  User feedback:
  ${FEEDBACK}

  Parent phase execution context (what was built):
  ${EXECUTION_CONTEXT}

  Research findings (from inline research):
  ${RESEARCH_CONTENT}
  (Include this section only if $RESEARCH_CONTENT is non-empty)

  Project context:
  {project_md_content}

  Roadmap:
  {roadmap_content}

  State:
  {state_content}

  Codebase docs:
  {codebase_docs_content}

  Write a SINGLE plan to: ${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-PLAN.md
  The plan must have 1-3 tasks maximum. Tasks should MODIFY existing files from Phase ${PARENT_PHASE}, not build from scratch.
  Set feedback_on: ${PARENT_PHASE} in frontmatter.
  Use standard PLAN.md format so /execute-phase can consume it.
  Return PLANNING COMPLETE when done.
  """
)
```

After planner returns:
1. Verify plan exists at `${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-PLAN.md`
2. If plan not found, show error and exit

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
