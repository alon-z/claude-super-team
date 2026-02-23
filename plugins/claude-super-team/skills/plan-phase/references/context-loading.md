# Context Loading Procedure

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
