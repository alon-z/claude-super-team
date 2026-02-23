# Standard Feedback Subphase Creation and Planning

This guide covers Steps 7 through 12 of the feedback flow: subphase numbering, directory setup, roadmap annotation, research detection, researcher spawning, and planner spawning.

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
