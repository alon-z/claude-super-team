---
name: plan-phase
description: Create execution plans (PLAN.md files) for a roadmap phase. MUST use this skill whenever the user wants to plan a phase, break down a phase into tasks, create PLAN.md files, decompose phase goals, or turn a roadmap phase into executable work. Also trigger when user mentions planning tasks for a phase, creating task dependencies, updating/refining existing plans, fixing verification gaps, or planning all remaining phases. Spawns a planner agent for parallel plans with wave structure. Trigger even when user says things like "break down phase N", "plan the next phase", "decompose into tasks", "create plans for phase", "update the plans", or "fix the gaps". Supports --all, --gaps, and --verify flags.
argument-hint: "[phase number | --all] [--gaps] [--verify]"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(cat *), Bash(bash *gather-data.sh)
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/plan-phase/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, PHASE_STATUS, ROADMAP_PHASES) before proceeding. The pre-assembled sections (ROADMAP_TRIMMED, STATE_TRIMMED, etc.) will be empty at this stage since PHASE_NUM/PHASE_DIR aren't known yet -- they are loaded in Phase 3.5.

**Context-aware skip:** If PROJECT.md, ROADMAP.md, or STATE.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/plan-phase/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Create executable PLAN.md files for a roadmap phase by spawning a planner agent, then verifying plans with a checker agent.

**Flow:** Load context -> Spawn planner (with built-in pre-flight checklist) -> Done
**Flow (with --verify):** Load context -> Spawn planner -> Verify plans -> Revision loop (if needed) -> Done

**Why agents:** Planning burns context fast. The planner gets a fresh context with all project files + methodology. The checker gets fresh context with just the plans. Main context stays lean.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, phase CONTEXT.md and RESEARCH.md (if exist), `.planning/codebase/` docs (if exist)
**Creates:** `.planning/phases/{phase}-{name}/{phase}-{NN}-PLAN.md` files

## Process

### Phase 1: Validate Environment

PROJECT.md, ROADMAP.md, and STATE.md are pre-loaded via dynamic context injection. If their contents are empty/missing from the injection, show the appropriate error and exit:

- No ROADMAP.md content: "ERROR: No roadmap found. Run /create-roadmap first."
- No PROJECT.md content: "ERROR: No project found. Run /new-project first."

### Phase 2: Parse Arguments

Extract from $ARGUMENTS:

- Phase number (integer). If not provided, detect next unplanned phase from roadmap.
- `--all` flag: Plan all unplanned phases sequentially
- `--gaps` flag: Gap closure mode (reads VERIFICATION.md, creates fix plans)
- `--verify` flag: Run the checker verification loop (skipped by default)

**Validations:**

- `--all` + phase number: ERROR -- mutually exclusive. Show: "Cannot combine --all with a specific phase number."
- `--all` + `--gaps`: ERROR -- gap closure is phase-specific. Show: "Cannot combine --all with --gaps. Run gap closure on a specific phase."
- `--all` + `--verify`: Valid.

If `--all` is set, skip the phase number normalization below and proceed to Phase 2.5.

Normalize phase to zero-padded format (single-phase mode only):

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/phase-utils.sh"
PHASE=$(normalize_phase "$PHASE_NUM")
```

### Phase 2.5: Discover Unplanned Phases (--all mode only)

Read `${CLAUDE_SKILL_DIR}/references/all-phases-mode.md` for the --all mode discovery, end-of-phase bookkeeping, and combined summary procedures.

### Phase 3: Validate Phase and Create Directory

**--all mode:** Phases 3-8 run inside a loop over `phases_to_plan`. For each iteration, set `PHASE_NUM` and `PHASE` from the current entry. All single-phase logic below applies unchanged per iteration.

```bash
grep -A5 "Phase ${PHASE_NUM}" .planning/ROADMAP.md
```

If phase not found in roadmap, show available phases and exit.

Create phase directory if needed:

```bash
PHASE_DIR=$(create_phase_dir "$PHASE_NUM")
```

### Phase 3.5: Load Pre-Assembled Context

Now that PHASE_NUM and PHASE_DIR are known, run gather-data.sh again with phase-specific variables to get pre-assembled context sections. Skip the files already loaded in Step 0:

```bash
SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 PHASE_NUM="${PHASE_NUM}" PHASE_DIR="${PHASE_DIR}" bash "${CLAUDE_PLUGIN_ROOT}/skills/plan-phase/gather-data.sh"
```

Parse the new output sections: ROADMAP_TRIMMED, STATE_TRIMMED, CODEBASE_DOCS, PHASE_CONTEXT, PHASE_RESEARCH, PHASE_REQUIREMENTS. These contain pre-trimmed, ready-to-embed content for the planner agent.

If codebase docs are already in conversation context (e.g., from a parent `/build` invocation), add `SKIP_CODEBASE=1` to the command.

### Phase 4: Load All Context

Context is now pre-assembled from gather-data.sh. Use the pre-assembled sections directly instead of reading individual files:

1. **ROADMAP_TRIMMED** -- contains the phases overview list and target phase detail block (replaces reading ROADMAP.md and manually extracting)
2. **STATE_TRIMMED** -- contains Current Position, Preferences, and Key Decisions (replaces reading STATE.md and manually trimming)
3. **CODEBASE_DOCS** -- contains aggregated ARCHITECTURE.md, STACK.md, CONVENTIONS.md, STRUCTURE.md (replaces reading 4 individual files)
4. **PHASE_CONTEXT** -- contains the phase's CONTEXT.md content or "(none)"
5. **PHASE_RESEARCH** -- contains the phase's RESEARCH.md content or "(none)"
6. **PHASE_REQUIREMENTS** -- contains REQUIREMENTS.md content or "(none)"

**Missing-context handling (check pre-assembled sections for "(none)"):**

If PHASE_CONTEXT is "(none)", show informational note (not a blocker): "Note: No CONTEXT.md found. Run /discuss-phase {N} first to capture implementation decisions, or continue planning without it."

If PHASE_RESEARCH is "(none)", use AskUserQuestion:
- header: "Research"
- question: "No RESEARCH.md found for this phase. Research helps the planner choose the right libraries, patterns, and avoid common pitfalls. Would you like to research first?"
- options:
  - label: "Research first (Recommended)" / description: "Run /research-phase {N} to investigate ecosystem, then return to planning"
  - label: "Plan without research" / description: "Continue planning with existing knowledge only"

On "Research first": Exit with message: "Run `/research-phase {N}` first, then come back to `/plan-phase {N}`."
On "Plan without research": Continue to Phase 5.

**For gap closure (--gaps only):** Read VERIFICATION.md and UAT.md separately -- these are NOT pre-assembled since they're gap-closure specific:
- `${PHASE_DIR}/*-VERIFICATION.md` -- verification failures to fix
- `${PHASE_DIR}/*-UAT.md` -- UAT failures to fix

**Existing plans check:** See `${CLAUDE_SKILL_DIR}/references/context-loading.md` for the existing plans detection and refinement mode handling (AskUserQuestion for refine/replan/keep).

### Phase 5: Spawn Planner Agent

Read `${CLAUDE_SKILL_DIR}/references/planner-guide.md` and `${CLAUDE_SKILL_DIR}/assets/plan-template.md`. Build the planner prompt by embedding:

1. The full planner guide content
2. The plan template
3. Pre-assembled context from gather-data.sh (ROADMAP_TRIMMED, STATE_TRIMMED, CODEBASE_DOCS, PHASE_CONTEXT, PHASE_RESEARCH, PHASE_REQUIREMENTS) -- already trimmed and ready to embed
4. PROJECT.md content from Step 0
5. The phase number, name, and goal from ROADMAP_TRIMMED's phase detail
6. Mode: `standard`, `gap_closure` (if --gaps), or `refinement` (if refining existing plans)

Spawn via Task tool:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Plan Phase {N}"
  prompt: """
  ultrathink

  You are a planner agent. Follow these instructions:

  {planner_guide_content}

  ---

  PLAN.md template to use:

  {plan_template_content}

  ---

  Phase: {phase_number} - {phase_name}
  Mode: {standard | gap_closure | refinement}

  Project context:
  {project_md_content}

  Roadmap phases overview (one-liners only):
  {roadmap_phases_list}

  This phase's roadmap detail:
  {roadmap_phase_detail}

  State (current position + key decisions only):
  {state_trimmed}

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

  Existing plans (refinement mode only):
  {existing_plan_contents}

  Prior phase plans index (--all mode only, empty for first phase or single-phase mode):
  {prior_plans_index}
  Use this index for setting correct depends_on references to plans from earlier phases.

  Write PLAN.md files to: {phase_dir}/
  Return PLANNING COMPLETE or REVISION COMPLETE or REFINEMENT COMPLETE when done.
  """
)
```

**Refinement mode:** When `PLAN_MODE=refinement`, set Mode to `refinement` and include the full contents of all existing `*-PLAN.md` files under "Existing plans". The planner will surgically update existing plans based on new context rather than creating plans from scratch. See "Refinement Mode" in planner-guide.md.

### Phase 6: Handle Planner Return

Parse the planner's output:

**`## PLANNING COMPLETE`:** Plans created. Continue to Phase 7 (if --verify), otherwise skip to Phase 9.

**`## REFINEMENT COMPLETE`:** Existing plans updated. Continue to Phase 7 (if --verify), otherwise skip to Phase 9.

**`## REVISION COMPLETE`:** Plans revised. Continue to Phase 7 for re-verification.

**Anything else / failure:** Show what happened. Use AskUserQuestion:

- "Retry" -- Re-spawn planner
- "Provide more context" -- User adds info, re-spawn
- "Abort" -- Exit skill

### Phase 7-8: Plan Checker and Revision Loop

Read `${CLAUDE_SKILL_DIR}/references/checker-loop.md` for the plan checker verification and revision loop procedure (Phase 7-8). Skip unless --verify flag was set.

In --all mode, read `${CLAUDE_SKILL_DIR}/references/all-phases-mode.md` for end-of-phase bookkeeping after Phases 3-8 complete for each phase.

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

Read `${CLAUDE_SKILL_DIR}/references/all-phases-mode.md` for the combined summary table format and incomplete-phase notes.

## Success Criteria

- [ ] .planning/ROADMAP.md and PROJECT.md exist
- [ ] Phase validated against roadmap
- [ ] Phase directory created
- [ ] All available context loaded and embedded in agent prompts
- [ ] Planner agent spawned with full context + planner guide + plan template
- [ ] PLAN.md files created in phase directory
- [ ] Plan checker spawned (if --verify)
- [ ] Verification passed OR user override OR max iterations with user decision
- [ ] User sees clear completion summary with wave structure
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps
