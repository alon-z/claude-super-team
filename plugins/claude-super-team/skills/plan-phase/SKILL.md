---
name: plan-phase
description: Create execution plans (PLAN.md files) for a roadmap phase. Spawns a planner agent to decompose phase goals into executable plans with tasks, dependencies, and wave structure. Includes plan verification loop. Use after /create-roadmap to plan a specific phase before execution. Supports --all to plan every unplanned phase sequentially. Supports gap closure mode (--gaps) for fixing verification failures.
argument-hint: "[phase number | --all] [--gaps] [--skip-verify]"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(cat *)
---

## Objective

Create executable PLAN.md files for a roadmap phase by spawning a planner agent, then verifying plans with a checker agent.

**Flow:** Load context -> Spawn planner -> Verify plans -> Revision loop (if needed) -> Done

**Why agents:** Planning burns context fast. The planner gets a fresh context with all project files + methodology. The checker gets fresh context with just the plans. Main context stays lean.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, phase CONTEXT.md and RESEARCH.md (if exist), `.planning/codebase/` docs (if exist)
**Creates:** `.planning/phases/{phase}-{name}/{phase}-{NN}-PLAN.md` files

## Process

### Phase 1: Validate Environment

```bash
[ ! -f .planning/ROADMAP.md ] && echo "ERROR: No roadmap found. Run /create-roadmap first." && exit 1
[ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
```

You MUST run these checks before proceeding.

### Phase 2: Parse Arguments

Extract from $ARGUMENTS:

- Phase number (integer). If not provided, detect next unplanned phase from roadmap.
- `--all` flag: Plan all unplanned phases sequentially
- `--gaps` flag: Gap closure mode (reads VERIFICATION.md, creates fix plans)
- `--skip-verify` flag: Skip the checker verification loop

**Validations:**

- `--all` + phase number: ERROR -- mutually exclusive. Show: "Cannot combine --all with a specific phase number."
- `--all` + `--gaps`: ERROR -- gap closure is phase-specific. Show: "Cannot combine --all with --gaps. Run gap closure on a specific phase."
- `--all` + `--skip-verify`: Valid.

If `--all` is set, skip the phase number normalization below and proceed to Phase 2.5.

Normalize phase to zero-padded format (single-phase mode only):

```bash
# Handle decimal phase numbers (e.g., 2.1 from inserted phases)
if echo "$PHASE_NUM" | grep -q '\.'; then
  INT_PART=$(echo "$PHASE_NUM" | cut -d. -f1)
  DEC_PART=$(echo "$PHASE_NUM" | cut -d. -f2)
  PHASE=$(printf "%02d.%s" "$INT_PART" "$DEC_PART")
else
  PHASE=$(printf "%02d" "$PHASE_NUM")
fi
```

### Phase 2.5: Discover Unplanned Phases (--all mode only)

Skip this phase if `--all` is not set.

Parse all phases from ROADMAP.md:

```bash
grep -E "^#+.*Phase [0-9]+(\.[0-9]+)?" .planning/ROADMAP.md
```

For each phase found, check if PLAN.md files already exist:

```bash
PHASE_DIR=$(ls -d .planning/phases/${PHASE_PADDED}-* 2>/dev/null | head -1)
ls "${PHASE_DIR}"/*-PLAN.md 2>/dev/null
```

Build a `phases_to_plan` list containing only phases that have no existing PLAN.md files.

**If the list is empty:** Show "All phases already planned. Nothing to do." and exit.

**Otherwise:** Show a brief overview before starting:

```
Planning all unplanned phases:

  Will plan:
  - Phase 2: Authentication
  - Phase 3: API Layer
  - Phase 5: Notifications

  Already planned (skipping):
  - Phase 1: Foundation
  - Phase 4: Dashboard
```

Initialize an empty `phase_results` list to collect per-phase outcomes for the combined summary.

Initialize an empty `prior_plans_index` string. After each phase completes, append a one-line-per-plan entry (plan ID + objective) so later phase planners can reference earlier plans for correct `depends_on` values.

Then loop over `phases_to_plan`, running Phases 3-8 for each. See Phase 3 for loop behavior.

### Phase 3: Validate Phase and Create Directory

**--all mode:** Phases 3-8 run inside a loop over `phases_to_plan`. For each iteration, set `PHASE_NUM` and `PHASE` from the current entry. All single-phase logic below applies unchanged per iteration.

```bash
grep -A5 "Phase ${PHASE_NUM}" .planning/ROADMAP.md
```

If phase not found in roadmap, show available phases and exit.

Create phase directory if needed:

```bash
PHASE_DIR=$(ls -d .planning/phases/${PHASE}-* 2>/dev/null | head -1)
if [ -z "$PHASE_DIR" ]; then
  PHASE_NAME=$(grep "Phase ${PHASE_NUM}:" .planning/ROADMAP.md | sed 's/.*Phase [0-9]*: //' | sed 's/ *-.*//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  mkdir -p ".planning/phases/${PHASE}-${PHASE_NAME}"
  PHASE_DIR=".planning/phases/${PHASE}-${PHASE_NAME}"
fi
```

### Phase 4: Load All Context

Read and store these files for embedding in agent prompts:

**Required:**

- `.planning/ROADMAP.md` -- phase goals, success criteria
- `.planning/PROJECT.md` -- project vision, requirements

**Optional (use if exists):**

- `.planning/STATE.md` -- current position, accumulated decisions
- `${PHASE_DIR}/*-CONTEXT.md` -- user decisions from /discuss-phase (CRITICAL: constrains planning)
- `${PHASE_DIR}/*-RESEARCH.md` -- research findings
- `.planning/REQUIREMENTS.md` -- formal requirements
- `.planning/codebase/ARCHITECTURE.md`, `STACK.md`, `CONVENTIONS.md` -- codebase context

**If CONTEXT.md does not exist,** show a brief informational note (not a blocker):

```
Note: No CONTEXT.md found. Run /discuss-phase {N} first to capture implementation
decisions, or continue planning without it.
```

This is informational only -- plan-phase works fine without CONTEXT.md.

**If RESEARCH.md does not exist,** show a brief informational note with offer:

Use AskUserQuestion:

- header: "Research"
- question: "No RESEARCH.md found for this phase. Research helps the planner choose the right libraries, patterns, and avoid common pitfalls. Would you like to research first?"
- options:
  - label: "Research first (Recommended)"
    description: "Run /research-phase {N} to investigate ecosystem, then return to planning"
  - label: "Plan without research"
    description: "Continue planning with existing knowledge only"

**On "Research first":** Exit with message: "Run `/research-phase {N}` first, then come back to `/plan-phase {N}`."

**On "Plan without research":** Continue to Phase 5.

**For gap closure (--gaps only):**

- `${PHASE_DIR}/*-VERIFICATION.md` -- verification failures to fix
- `${PHASE_DIR}/*-UAT.md` -- UAT failures to fix

Also check for existing plans:

```bash
ls "${PHASE_DIR}"/*-PLAN.md 2>/dev/null
```

If plans exist and NOT --gaps mode, use AskUserQuestion:

- header: "Plans"
- question: "Plans already exist for this phase. What do you want to do?"
- options:
  - "Replan from scratch" -- Delete existing and create new plans
  - "Keep existing" -- Exit without changes

### Phase 5: Spawn Planner Agent

Read `references/planner-guide.md` and `assets/plan-template.md`. Build the planner prompt by embedding:

1. The full planner guide content
2. The plan template
3. All context files loaded in Phase 4 (inline their contents -- `@` syntax does not work across Task boundaries)
4. The phase number, name, and goal from roadmap
5. Mode: `standard` or `gap_closure` (if --gaps)

Spawn via Task tool:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Plan Phase {N}"
  prompt: """
  You are a planner agent. Follow these instructions:

  {planner_guide_content}

  ---

  PLAN.md template to use:

  {plan_template_content}

  ---

  Phase: {phase_number} - {phase_name}
  Mode: {standard | gap_closure}

  Project context:
  {project_md_content}

  Roadmap:
  {roadmap_content}

  State:
  {state_content}

  Phase context (user decisions -- MUST honor locked decisions):
  {context_md_content}

  Research:
  {research_content}

  Requirements:
  {requirements_content}

  Codebase docs:
  {codebase_docs_content}

  Gap closure context (if --gaps):
  {verification_content}
  {uat_content}

  Prior phase plans index (--all mode only, empty for first phase or single-phase mode):
  {prior_plans_index}
  Use this index for setting correct depends_on references to plans from earlier phases.

  Write PLAN.md files to: {phase_dir}/
  Return PLANNING COMPLETE or REVISION COMPLETE when done.
  """
)
```

### Phase 6: Handle Planner Return

Parse the planner's output:

**`## PLANNING COMPLETE`:** Plans created. Continue to Phase 7 (unless --skip-verify).

**`## REVISION COMPLETE`:** Plans revised. Continue to Phase 7 for re-verification.

**Anything else / failure:** Show what happened. Use AskUserQuestion:

- "Retry" -- Re-spawn planner
- "Provide more context" -- User adds info, re-spawn
- "Abort" -- Exit skill

### Phase 7: Spawn Plan Checker

Skip if `--skip-verify` flag was set.

Read `references/plan-checker-guide.md`. Read all PLAN.md files just created:

```bash
PLANS_CONTENT=$(cat "${PHASE_DIR}"/*-PLAN.md 2>/dev/null)
```

Spawn via Task tool:

```
Task(
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Verify Phase {N} plans"
  prompt: """
  You are a plan checker. Follow these instructions:

  {plan_checker_guide_content}

  ---

  Phase: {phase_number}
  Phase goal (from roadmap): {phase_goal}

  Plans to verify:
  {plans_content}

  Requirements (if exists):
  {requirements_content}

  Phase context (user decisions -- plans must honor these):
  {context_md_content}

  Verify these plans against all dimensions. Return VERIFICATION PASSED or ISSUES FOUND.
  """
)
```

### Phase 8: Handle Checker Return and Revision Loop

**`## VERIFICATION PASSED`:** Plans verified. Continue to Phase 9.

**`## ISSUES FOUND`:** Parse issues. Track iteration count (starts at 1).

**If iteration_count < 3:**

Show issues to user, then re-spawn planner in revision mode:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Revise Phase {N} plans"
  prompt: """
  You are a planner agent in REVISION mode. Follow these instructions:

  {planner_guide_content}

  ---

  Phase: {phase_number}
  Mode: revision

  Existing plans:
  {current_plans_content}

  Checker issues to fix:
  {structured_issues}

  Phase context (user decisions):
  {context_md_content}

  Make targeted updates to address issues. Do NOT rewrite from scratch.
  Return REVISION COMPLETE when done.
  """
)
```

After revision, re-spawn checker (back to Phase 7). Increment iteration_count.

**If iteration_count >= 3:**

Show remaining issues. Use AskUserQuestion:

- header: "Issues"
- question: "Max revision iterations reached. {N} issues remain."
- options:
  - "Proceed anyway" -- Accept plans with known issues
  - "Provide guidance" -- Give direction for another attempt
  - "Abort" -- Exit (in --all mode, this stops the entire loop)

#### --all mode: End-of-Phase Bookkeeping

After Phases 3-8 complete for one phase (whether verification passed, was skipped, or user overrode):

**1. Update prior plans index.** Read all PLAN.md files just created for this phase and append one line per plan to `prior_plans_index`:

```
Phase {N} / {plan_id}: {objective from plan frontmatter}
```

This lightweight index is passed to subsequent phase planners so they can set correct cross-phase `depends_on` references.

**2. Record result.** Append to `phase_results`:

```
{ phase_num, phase_name, plan_count, wave_count, verification: "Passed" | "Skipped" | "Passed with override" | "Failed" }
```

**3. Show progress:**

```
Phase {N} ({name}) planned. [{completed}/{total}]
```

**4. Error handling.** If the planner agent fails or the checker hits max iterations and the user chose "Abort" in the single-phase flow, use AskUserQuestion in --all mode instead:

- header: "Phase failed"
- question: "Phase {N} ({name}) failed. How do you want to proceed?"
- options:
  - "Skip and continue" -- Record as failed, move to next phase
  - "Retry" -- Re-attempt this phase from Phase 3
  - "Stop here" -- End loop, show partial summary with phases completed so far

After the loop ends (all phases done or user chose "Stop here"), proceed to Phase 9.

### Phase 9: Done

#### Single-phase mode (no --all)

Present completion summary:

```
Phase {N} planned.

Created:
- {list each PLAN.md file with brief objective}

Wave structure:
| Wave | Plans | What it builds |
|------|-------|----------------|
| 1 | 01, 02 | [objectives] |
| 2 | 03 | [objective] |

Verification: {Passed | Passed with override | Skipped}

---

## Next Steps

**Execute the plans:**
- Run /execute-phase {N}

**Review plans first:**
- Read .planning/phases/{phase-dir}/*-PLAN.md

**Commit if desired:**
  git add .planning/phases/{phase-dir}/*-PLAN.md && git commit -m "docs: plan phase {N}"

---
```

#### --all mode: Combined Summary

Use `phase_results` collected during the loop to build a summary table:

```
All phases planned.

| Phase | Name | Plans | Waves | Verification |
|-------|------|-------|-------|--------------|
| 1 | Foundation | 3 | 2 | Passed |
| 2 | Auth | 2 | 1 | Passed |
| 3 | API Layer | 4 | 3 | Skipped |

Total: {N} plans across {M} phases

---

## Next Steps

**Execute the plans:**
- Run /execute-phase 1

**Review all plans:**
- Read .planning/phases/*-PLAN.md

**Commit if desired:**
  git add .planning/phases/ && git commit -m "docs: plan all phases"

---
```

If some phases failed or were skipped (user chose "Skip and continue" or "Stop here"), note them:

```
Incomplete:
- Phase 4 (Dashboard): Failed -- skipped
- Phases 5-6: Not attempted (stopped early)
```

## Success Criteria

- [ ] .planning/ROADMAP.md and PROJECT.md exist
- [ ] Phase validated against roadmap
- [ ] Phase directory created
- [ ] All available context loaded and embedded in agent prompts
- [ ] Planner agent spawned with full context + planner guide + plan template
- [ ] PLAN.md files created in phase directory
- [ ] Plan checker spawned (unless --skip-verify)
- [ ] Verification passed OR user override OR max iterations with user decision
- [ ] User sees clear completion summary with wave structure
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps
