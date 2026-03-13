# Context Loading Procedure

Context for the planner agent is pre-assembled by `gather-data.sh` into trimmed, ready-to-embed sections. The skill LLM does not need to read and trim individual files -- just use the pre-assembled sections from the Phase 3.5 gather-data.sh output.

## Pre-Assembled Sections (from gather-data.sh)

These sections are available when `PHASE_NUM` and `PHASE_DIR` are passed to gather-data.sh:

| Section | Source | What it contains |
|---------|--------|-----------------|
| ROADMAP_TRIMMED | ROADMAP.md | Phases overview list + target phase detail block only |
| STATE_TRIMMED | STATE.md | Current Position + Preferences + Accumulated Context (Key Decisions) |
| CODEBASE_DOCS | .planning/codebase/ | Aggregated ARCHITECTURE.md, STACK.md, CONVENTIONS.md, STRUCTURE.md |
| PHASE_CONTEXT | {PHASE_DIR}/*-CONTEXT.md | User decisions from /discuss-phase |
| PHASE_RESEARCH | {PHASE_DIR}/*-RESEARCH.md | Research findings |
| PHASE_REQUIREMENTS | .planning/REQUIREMENTS.md | Formal requirements |

Sections output "(none)" when the source file doesn't exist, or "(in context)" when skipped via SKIP flags.

## Required vs Optional Context

**Required (always embed in planner prompt):**

- PROJECT.md -- project vision, requirements (from Step 0 gather-data.sh PROJECT section)
- ROADMAP_TRIMMED -- phase detail + phases overview for dependency context

**Optional (embed if not "(none)"):**

- STATE_TRIMMED -- current position and key decisions
- PHASE_CONTEXT -- user decisions from /discuss-phase (CRITICAL: constrains planning)
- PHASE_RESEARCH -- research findings
- PHASE_REQUIREMENTS -- formal requirements
- CODEBASE_DOCS -- codebase context (skip for greenfield phases via SKIP_CODEBASE=1)

## Missing-Context Handling

**If PHASE_CONTEXT is "(none)"**, show informational note (not a blocker):

```
Note: No CONTEXT.md found. Run /discuss-phase {N} first to capture implementation
decisions, or continue planning without it.
```

**If PHASE_RESEARCH is "(none)"**, use AskUserQuestion:

- header: "Research"
- question: "No RESEARCH.md found for this phase. Research helps the planner choose the right libraries, patterns, and avoid common pitfalls. Would you like to research first?"
- options:
  - label: "Research first (Recommended)"
    description: "Run /research-phase {N} to investigate ecosystem, then return to planning"
  - label: "Plan without research"
    description: "Continue planning with existing knowledge only"

**On "Research first":** Exit with message: "Run `/research-phase {N}` first, then come back to `/plan-phase {N}`."

**On "Plan without research":** Continue to Phase 5.

## Gap Closure Context (--gaps only)

These are NOT pre-assembled (gap-closure specific, loaded separately):

- `${PHASE_DIR}/*-VERIFICATION.md` -- verification failures to fix
- `${PHASE_DIR}/*-UAT.md` -- UAT failures to fix

## Existing Plans Detection

Check for existing plans:

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
