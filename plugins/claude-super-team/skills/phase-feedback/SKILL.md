---
name: phase-feedback
description: Collect user feedback on a just-executed phase, plan a targeted subphase, and execute the changes immediately. Reads execution summaries and verification results from the parent phase, gathers specific feedback through iterative clarification, spawns a feedback-aware planner, then executes all tasks with opus agents. Use after /execute-phase when the user wants changes to delivered work. Requires .planning/PROJECT.md and .planning/ROADMAP.md.
argument-hint: "[phase number] [feedback description]"
allowed-tools: Read, Bash, Write, Edit, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
---

## Objective

Collect feedback on a just-executed phase, create a feedback-driven subphase with decimal numbering (e.g., 4.1), plan targeted modifications, and execute them immediately with opus agents.

**Flow:** Validate -> Identify parent phase -> Load execution context -> Collect feedback -> Scope check -> Create subphase -> Annotate roadmap -> Spawn planner -> Execute tasks (opus) -> Write summary -> Done

**Reads:** `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, parent phase `*-SUMMARY.md` and `*-VERIFICATION.md`
**Creates:** `.planning/phases/{NN.X}-feedback-{slug}/{NN.X}-01-PLAN.md`, `*-SUMMARY.md`, annotates `ROADMAP.md`

## Process

### Step 1: Validate Environment

```bash
[ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
[ ! -f .planning/ROADMAP.md ] && echo "ERROR: No roadmap found. Run /create-roadmap first." && exit 1
```

You MUST run both checks before proceeding.

### Step 2: Identify Parent Phase

Parse `$ARGUMENTS` for a phase number. If present, use it as `$PARENT_PHASE`.

If no phase number in arguments, auto-detect:

1. Read `.planning/STATE.md` for the most recently executed phase
2. Look for the most recent SUMMARY.md across `.planning/phases/*/`
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

### Step 5: Scope Check

Analyze the feedback. If it implies:
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

### Step 6: Determine Subphase Number

```bash
# Find existing subphases of the parent
EXISTING=$(ls -d .planning/phases/${PARENT_NUM}.*-* 2>/dev/null | grep -oE "${PARENT_NUM}\.[0-9]+" | grep -oE "\.[0-9]+" | tr -d '.' | sort -n | tail -1)

if [ -z "$EXISTING" ]; then
  DECIMAL=1
else
  DECIMAL=$((EXISTING + 1))
fi

FEEDBACK_PHASE="${PARENT_PHASE}.${DECIMAL}"
FEEDBACK_PHASE_PADDED=$(printf "%02d.%s" "$PARENT_PHASE" "$DECIMAL")
```

### Step 7: Create Phase Directory

```bash
slug=$(echo "$FEEDBACK" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-30)

PHASE_DIR=".planning/phases/${FEEDBACK_PHASE_PADDED}-feedback-${slug}"
mkdir -p "$PHASE_DIR"
```

Report: `Creating Phase ${FEEDBACK_PHASE}: Feedback on Phase ${PARENT_PHASE}`

### Step 8: Annotate ROADMAP.md

Add entry **without restructuring existing phases**.

**8a. Add to the `## Phases` checklist** after the parent phase entry:

```markdown
- [ ] Phase {FEEDBACK_PHASE}: {FEEDBACK summary} (FEEDBACK on Phase {PARENT_PHASE})
```

**8b. Add a brief section** in `## Phase Details` after the parent phase's detail section:

```markdown
### Phase {FEEDBACK_PHASE}: Feedback -- {FEEDBACK summary} (FEEDBACK on Phase {PARENT_PHASE})

**Goal:** Address user feedback on Phase {PARENT_PHASE} deliverables
**Type:** Feedback subphase -- modifies existing work, no research/verification
**Parent:** Phase {PARENT_PHASE}

Success Criteria:
1. {1-2 observable criteria derived from the feedback}
```

Use Edit tool to insert at correct positions. Do NOT renumber or move existing phases.

**8c. Update STATE.md** -- set current phase to the feedback subphase so `/execute-phase` picks it up.

### Step 9: Spawn Planner Agent

Read `references/planner-feedback-mode.md` and `assets/feedback-plan-template.md`. Load project context.

**Context to load:**
- `.planning/PROJECT.md` (required)
- `.planning/ROADMAP.md` (required -- includes the annotation just added)
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

### Step 10: Execute Tasks

Read the plan created in Step 9. Parse the `<tasks>` section and extract each task's `<name>`, `<files>`, `<action>`, `<verify>`, `<done>`.

Read the task execution guide from the execute-phase skill: `plugins/claude-super-team/skills/execute-phase/references/task-execution-guide.md`. This guide gives agents their execution protocol (deviation rules, commit protocol, self-check, report format).

**All tasks execute sequentially via opus agents.** For each task, spawn:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Feedback ${FEEDBACK_PHASE} Task {N}: {task_name}"
  prompt: """
  You are executing a feedback task -- modifying existing code to address user feedback on Phase ${PARENT_PHASE}.

  {task_execution_guide_content}

  ---

  Plan: ${FEEDBACK_PHASE}-01
  Plan objective: {objective from plan}
  Plan must_haves: {must_haves from plan}

  Your task:

  <task type="{type}">
    <name>{name}</name>
    <files>{files}</files>
    <action>{action}</action>
    <verify>{verify}</verify>
    <done>{done}</done>
  </task>

  Prior tasks in this plan:
  {prior_task_reports or "This is the first task."}

  User feedback being addressed:
  ${FEEDBACK}

  What parent Phase ${PARENT_PHASE} built (from execution summaries):
  ${EXECUTION_CONTEXT}

  Project context:
  {project_md_content}

  Codebase context:
  {codebase_docs_content}

  IMPORTANT: You are MODIFYING existing files, not building from scratch.
  Read the files listed in <files> first to understand current state before changing anything.
  """
)
```

**Handling task results:**

- **`## TASK COMPLETE`:** Record result. Feed report to next task as prior context. Continue.
- **`## TASK BLOCKED`:** Show blocker to user via AskUserQuestion:
  - header: "Blocked"
  - question: "Task '{name}' is blocked: {reason}. What do you want to do?"
  - options:
    - "Provide guidance" -- User gives direction, re-spawn task with guidance
    - "Skip task" -- Mark as skipped, continue
    - "Abort" -- Stop execution

### Step 11: Write Summary

After all tasks complete, read the summary template from `plugins/claude-super-team/skills/execute-phase/assets/summary-template.md` and create:

```
${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-SUMMARY.md
```

Populate with:
- Task results (commits, files changed, deviations)
- Aggregate from all task reports
- Note this is a feedback subphase on Phase ${PARENT_PHASE}

### Step 12: Done

Present completion summary:

```
Phase ${FEEDBACK_PHASE} complete (feedback on Phase ${PARENT_PHASE}).

Feedback: ${FEEDBACK}
Tasks executed: {N} (all opus)
Directory: ${PHASE_DIR}
Summary: ${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-SUMMARY.md

---

## Next Steps

**Review what changed:**
  Read ${PHASE_DIR}/${FEEDBACK_PHASE_PADDED}-01-SUMMARY.md

**More feedback?**
  /phase-feedback ${PARENT_PHASE} to create another feedback subphase (${PARENT_PHASE}.${DECIMAL+1})

**Continue to next phase:**
  /progress to see what's next

**Commit planning artifacts if desired:**
  git add ${PHASE_DIR}/ .planning/ROADMAP.md .planning/STATE.md && git commit -m "feedback phase ${FEEDBACK_PHASE}: ${FEEDBACK summary}"

---
```

Never auto-commit.

## Success Criteria

- [ ] `.planning/PROJECT.md` and `.planning/ROADMAP.md` exist
- [ ] Parent phase identified (from args, STATE.md, or user)
- [ ] Parent phase has execution results (SUMMARY.md files)
- [ ] Execution context loaded (summaries + verification)
- [ ] Feedback collected and confirmed through iterative AskUserQuestion
- [ ] Scope validated (not too broad for a subphase)
- [ ] Decimal subphase number calculated (e.g., 4.1)
- [ ] Phase directory created at `.planning/phases/{NN.X}-feedback-{slug}/`
- [ ] ROADMAP.md annotated with feedback phase entry (no restructuring)
- [ ] STATE.md updated to point to feedback phase
- [ ] Planner spawned (opus) with execution context + feedback
- [ ] `{NN.X}-01-PLAN.md` created with 1-3 modification-oriented tasks
- [ ] Each task executed by an opus agent with full context
- [ ] Task agents received task-execution-guide, execution summaries, and feedback
- [ ] SUMMARY.md written after all tasks complete
- [ ] User told how to commit (never auto-commit)
- [ ] User told about `/phase-feedback` for additional feedback rounds
