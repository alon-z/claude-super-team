---
name: quick-plan
description: Quickly plan an ad-hoc feature or fix as a lightweight phase inserted into the roadmap. Uses decimal numbering (e.g., 4.1 if currently on phase 5) so it slots between existing phases. Spawns a planner (1-3 tasks, no research/checker/verifier) and annotates ROADMAP.md without restructuring it. Execution is handled by /execute-phase. Use when the user wants to squeeze in something urgent or small -- bug fixes, small features, refactors -- without full phase ceremony. Requires .planning/PROJECT.md and .planning/ROADMAP.md.
argument-hint: "[task description]"
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(mkdir *)
---

## Objective

Insert a lightweight phase into the roadmap for an ad-hoc task, plan it with 1-3 tasks (no research, no checker, no verifier), and hand off to `/execute-phase` for execution.

Quick phases use decimal numbering (e.g., 4.1) and slot before the current phase. They are real phases -- they live in `.planning/phases/`, appear in ROADMAP.md, and execute via `/execute-phase` -- but skip the heavy planning pipeline.

**Flow:** Validate -> Get description -> Determine phase number -> Create phase directory -> Annotate ROADMAP.md -> Discuss implementation -> Spawn planner -> Done (user runs /execute-phase)

**Reads:** `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/codebase/` (if exists)
**Creates:** `.planning/phases/{NN.X}-{slug}/{NN.X}-CONTEXT.md` + `{NN.X}-01-PLAN.md`, annotates `ROADMAP.md`

## Process

### Step 1: Validate Environment

```bash
[ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
[ ! -f .planning/ROADMAP.md ] && echo "ERROR: No roadmap found. Run /create-roadmap first." && exit 1
```

You MUST run both checks before proceeding. Quick phases require an active roadmap to determine insertion point.

### Step 2: Get Task Description

If `$ARGUMENTS` contains a task description, use it as `$DESCRIPTION`.

If `$ARGUMENTS` is empty, use AskUserQuestion:

- header: "Quick phase"
- question: "What do you want to do?"
- options:
  - "Bug fix" -- "Fix a specific bug or error"
  - "Small feature" -- "Add a focused piece of functionality"
  - "Refactor" -- "Improve existing code without changing behavior"
  - "Other" -- "Documentation, config, dependency update, etc."

Then ask a follow-up to get the specific description. Store as `$DESCRIPTION`.

**Scope check:** If the description suggests >5 files or multiple subsystems, warn:

```
This sounds like it might be too large for a quick phase. Consider:
- /create-roadmap add a phase for {description}
- /plan-phase {N} for full planning
```

Use AskUserQuestion to confirm: "Proceed as quick phase?" or "Use full phase instead?"

### Step 3: Determine Phase Number

Read `.planning/STATE.md` and `.planning/ROADMAP.md` to find the current phase.

**Logic:** Insert the quick phase just before the current phase using decimal numbering.

```bash
# Extract current phase number from STATE.md
CURRENT_PHASE=$(grep -oE "Phase [0-9]+(\.[0-9]+)?" .planning/STATE.md | head -1 | grep -oE "[0-9]+(\.[0-9]+)?")

# The base phase is the integer phase BEFORE current
# e.g., if current is phase 5, base is 4; if current is 3, base is 2
BASE_PHASE=$((${CURRENT_PHASE%%.*} - 1))

# If current phase is 1, insert as 0.1
if [ "$BASE_PHASE" -lt 1 ]; then
  BASE_PHASE=0
fi

# Find existing decimals for the base phase
EXISTING_DECIMALS=$(grep -oE "Phase ${BASE_PHASE}\.[0-9]+" .planning/ROADMAP.md | grep -oE "\.[0-9]+" | tr -d '.' | sort -n | tail -1)

if [ -z "$EXISTING_DECIMALS" ]; then
  DECIMAL=1
else
  DECIMAL=$((EXISTING_DECIMALS + 1))
fi

QUICK_PHASE="${BASE_PHASE}.${DECIMAL}"
QUICK_PHASE_PADDED=$(printf "%02d.%s" "$BASE_PHASE" "$DECIMAL")
```

Report to user: `Inserting as Phase ${QUICK_PHASE}: ${DESCRIPTION}`

### Step 4: Create Phase Directory

```bash
slug=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)

PHASE_DIR=".planning/phases/${QUICK_PHASE_PADDED}-${slug}"
mkdir -p "$PHASE_DIR"
```

### Step 5: Annotate ROADMAP.md

Add a lightweight entry to ROADMAP.md **without restructuring existing phases**. This is an annotation, not a full phase definition.

**5a. Add to the `## Phases` checklist** after the base phase entry:

```markdown
- [ ] Phase {QUICK_PHASE}: {DESCRIPTION} (QUICK)
```

**5b. Add a brief section** in `## Phase Details` after the base phase's detail section:

```markdown
### Phase {QUICK_PHASE}: {DESCRIPTION} (QUICK)

**Goal:** {one-line goal derived from description}
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase {CURRENT_PHASE}

Success Criteria:
1. {1-2 observable criteria derived from the description}
```

Use the Edit tool to insert these at the correct positions. Do NOT renumber or move existing phases.

**5c. Update STATE.md** -- set current phase to the quick phase number so `/execute-phase` picks it up:

Find and update the current phase reference in STATE.md to point to the quick phase. After the quick phase completes and the user runs `/execute-phase` for the original current phase, it will naturally resume.

### Step 6: Discuss Implementation

Run a lightweight version of the discuss-phase workflow to capture decisions before planning.

**6a. Identify 2-3 gray areas** specific to `$DESCRIPTION` and the phase goal. Follow the same domain-aware analysis as `/discuss-phase`:
- Derive gray areas from the specific task, not generic categories
- Focus on HOW to implement, not WHETHER

**6b. Present gray areas** via AskUserQuestion:

- header: "Discuss"
- question: "Before planning, which areas should we clarify? (Select all that apply)"
- multiSelect: true
- options: Each gray area as an option (2-3 options)
  - label: "{Brief area name}" (12 chars max)
  - description: "{Why this matters}"
- Plus one option:
  - label: "Skip"
    description: "Plan without discussing -- Claude decides everything"

**If "Skip" selected:** Set `HAS_CONTEXT=false`, continue to Step 7.

**6c. Deep-dive each selected area** with 2-3 questions per area (lighter than full discuss-phase's 4 questions). Use AskUserQuestion with concrete options per question. Always include a "You decide" option.

**6d. Write CONTEXT.md** to `${PHASE_DIR}/${QUICK_PHASE_PADDED}-CONTEXT.md` using the discuss-phase template structure (read from `../discuss-phase/assets/context-template.md`):
- Phase Boundary (from the ROADMAP.md annotation)
- Implementation Decisions (from the discussion)
- Claude's Discretion (from "You decide" answers)
- Deferred Ideas (from any scope creep caught during discussion)

Set `HAS_CONTEXT=true`.

### Step 7: Spawn Planner Agent

Read `references/planner-quick-mode.md` and `assets/quick-plan-template.md`. Load project context.

**Context to load:**
- `.planning/PROJECT.md` (required)
- `.planning/ROADMAP.md` (required -- includes the annotation just added)
- `.planning/STATE.md` (if exists)
- `${PHASE_DIR}/${QUICK_PHASE_PADDED}-CONTEXT.md` (if HAS_CONTEXT=true -- constrains planning)
- `.planning/codebase/ARCHITECTURE.md`, `STACK.md`, `CONVENTIONS.md` (if exist)

Spawn via Task tool:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Quick plan: Phase ${QUICK_PHASE}"
  prompt: """
  You are a planner agent in quick mode. Follow these instructions:

  {planner_quick_mode_content}

  ---

  Plan template to use:

  {quick_plan_template_content}

  ---

  Phase: ${QUICK_PHASE} - ${DESCRIPTION}
  Phase directory: ${PHASE_DIR}
  Phase type: quick (inserted before Phase ${CURRENT_PHASE})

  Project context:
  {project_md_content}

  Roadmap:
  {roadmap_content}

  State:
  {state_content}

  Phase context (user decisions -- MUST honor locked decisions):
  {context_md_content_or_"No CONTEXT.md -- use your best judgment"}

  Codebase docs:
  {codebase_docs_content}

  Write a SINGLE plan to: ${PHASE_DIR}/${QUICK_PHASE_PADDED}-01-PLAN.md
  The plan must have 1-3 tasks maximum. Keep it lean (~30% context budget).
  Use standard PLAN.md format so /execute-phase can consume it.
  Return PLANNING COMPLETE when done.
  """
)
```

After planner returns:
1. Verify plan exists at `${PHASE_DIR}/${QUICK_PHASE_PADDED}-01-PLAN.md`
2. If plan not found, show error and exit

### Step 8: Done

Present completion summary:

```
Phase ${QUICK_PHASE} planned (quick).

Description: ${DESCRIPTION}
Directory: ${PHASE_DIR}
Context: ${PHASE_DIR}/${QUICK_PHASE_PADDED}-CONTEXT.md (if written, else "Skipped")
Plan: ${PHASE_DIR}/${QUICK_PHASE_PADDED}-01-PLAN.md
Roadmap: Updated with Phase ${QUICK_PHASE} annotation

---

## Next Steps

**Execute the quick phase:**
  /execute-phase ${QUICK_PHASE} --skip-verify

**Review the plan first:**
  Read ${PHASE_DIR}/${QUICK_PHASE_PADDED}-01-PLAN.md

**Commit planning artifacts if desired:**
  git add ${PHASE_DIR}/ .planning/ROADMAP.md .planning/STATE.md && git commit -m "docs: plan quick phase ${QUICK_PHASE}"

---
```

Never auto-commit. Suggest `--skip-verify` on execute-phase since quick phases skip the verification pipeline.

## Success Criteria

- [ ] `.planning/PROJECT.md` and `.planning/ROADMAP.md` exist
- [ ] Task description obtained (from args or user)
- [ ] Scope validated (not too large for quick phase)
- [ ] Decimal phase number calculated (e.g., 4.1)
- [ ] Phase directory created at `.planning/phases/{NN.X}-{slug}/`
- [ ] ROADMAP.md annotated with quick phase entry (no restructuring)
- [ ] STATE.md updated to point to quick phase
- [ ] Implementation discussed: 2-3 gray areas identified, user decisions captured (or skipped)
- [ ] CONTEXT.md written to phase directory (unless user chose "Skip")
- [ ] Planner spawned with CONTEXT.md embedded, `{NN.X}-01-PLAN.md` created with 1-3 tasks
- [ ] Standard PLAN.md format used (compatible with /execute-phase)
- [ ] User told to run `/execute-phase {N.X} --skip-verify`
- [ ] User told how to commit (never auto-commit)
