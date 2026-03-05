# Context Loading Procedure

Load context efficiently -- the planner's quality degrades with context pressure, so send only what's relevant to the phase being planned.

**Required:**

- `.planning/PROJECT.md` -- project vision, requirements
- `.planning/ROADMAP.md` -- **only the specific phase section** being planned, plus the Phases overview list (for dependency context). Do NOT send all phase details for all phases.

**Optional (use if exists):**

- `.planning/STATE.md` -- only the Current Position and Key Decisions sections (skip history/log)
- `${PHASE_DIR}/*-CONTEXT.md` -- user decisions from /discuss-phase (CRITICAL: constrains planning)
- `${PHASE_DIR}/*-RESEARCH.md` -- research findings
- `.planning/REQUIREMENTS.md` -- formal requirements
- `.planning/codebase/ARCHITECTURE.md`, `STACK.md`, `CONVENTIONS.md` -- codebase context

**Context trimming rules:**

1. **ROADMAP.md**: Extract the `## Phases` list (one-liners) and only the `### Phase N` detail section for the target phase. Skip all other phase detail sections -- the planner doesn't need Phase 12's success criteria to plan Phase 3.
2. **STATE.md**: Extract `## Current Position` and `## Key Decisions` only. Skip execution history.
3. **Codebase docs**: Only include if the phase touches existing code. For greenfield phases (new subsystems), skip codebase docs entirely.

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
  - label: "Refine existing plans (Recommended)"
    description: "Update plans based on new context (RESEARCH.md, CONTEXT.md, etc.) -- surgical changes only"
  - label: "Replan from scratch"
    description: "Delete existing plans and create entirely new ones"
  - label: "Keep existing"
    description: "Exit without changes"

**On "Refine existing plans":** Set `PLAN_MODE=refinement`. Read all existing `*-PLAN.md` files in the phase directory and store their contents. Detect what context changed since plans were created by comparing file modification times or noting which optional context files (CONTEXT.md, RESEARCH.md) are present but not reflected in existing plans. Continue to Phase 5 with refinement mode.

**On "Replan from scratch":** Set `PLAN_MODE=standard`. Delete existing plans. Continue to Phase 5.

**On "Keep existing":** Exit without changes.
