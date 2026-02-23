---
name: discuss-phase
description: Gather implementation decisions through adaptive questioning before planning. Identifies gray areas in a phase, deep-dives each with the user, and creates CONTEXT.md that constrains downstream planning. Use after /create-roadmap and before /plan-phase to lock decisions and clarify ambiguities.
argument-hint: "<phase number>"
allowed-tools: Read, Write, Glob, Grep, AskUserQuestion, Task, Bash(test *), Bash(ls *), Bash(grep *), Bash(mkdir *), Bash(bash *gather-data.sh)
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/discuss-phase/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, PHASE_ARTIFACTS, CODEBASE_DOCS) before proceeding.

**Context-aware skip:** If PROJECT.md or ROADMAP.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/discuss-phase/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Capture user implementation decisions before planning begins. Creates CONTEXT.md that locks decisions, defines discretion boundaries, and defers scope creep.

**Why this matters:** Planning agents work better with constraints. "Build auth" is ambiguous. "OAuth2 with Google/GitHub providers, JWT tokens in httpOnly cookies" is executable.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, phase `CONTEXT.md` (if exists), earlier phase artifacts (`SUMMARY.md`, `PLAN.md`, `CONTEXT.md`)
**Creates:** `.planning/phases/{phase}-{name}/CONTEXT.md`

## Process

### Phase 1: Validate Phase Number

PROJECT.md and ROADMAP.md are pre-loaded via dynamic context injection. If ROADMAP.md content is empty/missing, show "ERROR: No roadmap found. Run /create-roadmap first." and exit.

Parse phase number from `$ARGUMENTS`. If not provided or invalid, show available phases from ROADMAP.md and exit.

Normalize phase to zero-padded format:

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

Validate phase exists in ROADMAP.md:

```bash
grep -A5 "Phase ${PHASE_NUM}" .planning/ROADMAP.md
```

If not found, show available phases and exit.

Create phase directory if needed:

```bash
PHASE_DIR=$(ls -d .planning/phases/${PHASE}-* 2>/dev/null | head -1)
if [ -z "$PHASE_DIR" ]; then
  PHASE_NAME=$(grep "Phase ${PHASE_NUM}:" .planning/ROADMAP.md | sed 's/.*Phase [0-9]*: //' | sed 's/ *-.*//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  mkdir -p ".planning/phases/${PHASE}-${PHASE_NAME}"
  PHASE_DIR=".planning/phases/${PHASE}-${PHASE_NAME}"
fi
```

### Phase 2: Check Existing Context

Check if CONTEXT.md already exists:

```bash
CONTEXT_FILE=$(ls "${PHASE_DIR}"/*-CONTEXT.md 2>/dev/null | head -1)
[ -n "$CONTEXT_FILE" ] && echo "CONTEXT_EXISTS=true" || echo "CONTEXT_EXISTS=false"
```

**If CONTEXT_EXISTS=true:** Use AskUserQuestion:

- header: "Context"
- question: "CONTEXT.md already exists for this phase. What do you want to do?"
- multiSelect: false
- options:
  - label: "Update existing"
    description: "Review and modify existing decisions"
  - label: "View only"
    description: "Show current context and exit"
  - label: "Replace entirely"
    description: "Start fresh, discard existing"

**On "View only":** Read and display the CONTEXT.md file, then exit with message:

```
Current context for Phase {N}:

{display CONTEXT.md contents}

---

To modify: /discuss-phase {N}
To plan with current context: /plan-phase {N}
```

**On "Replace entirely":** Continue to Phase 3 (will overwrite later).

**On "Update existing":** Load existing CONTEXT.md and present current decisions as context when generating gray areas. Continue to Phase 3.

**If CONTEXT_EXISTS=false:** Continue to Phase 3.

### Phase 3: Load Phase Context

Read and extract:

**From ROADMAP.md:**
- Phase {N} goal
- Success criteria (list)
- Requirements covered by this phase

**From PROJECT.md:**
- Core Value
- Constraints
- Key Decisions

Extract the phase name for use in templates.

### Phase 3.5: Load Cross-Phase Context

Read `references/cross-phase-context.md` for the cross-phase artifact loading procedure.

### Phase 3.7: Gather Codebase Context

Read `references/codebase-exploration.md` for the Explore agent spawning and codebase analysis procedure.

### Phase 4: Identify Gray Areas

Read `references/gray-area-methodology.md` for the domain-aware gray area identification methodology.

### Phase 5: Present Gray Areas and Gather Selection

Present the identified gray areas to the user via AskUserQuestion:

- header: "Areas"
- question: "Which implementation areas would you like to clarify before planning? (Select all that apply)"
- multiSelect: true
- options: Each gray area as an option
  - label: "{Brief area name}" (12 chars max)
  - description: "{Why this matters / what's ambiguous}"

**No "Skip all" option.** At least one area must be selected. If the user doesn't want to discuss anything, they can exit the skill and run `/plan-phase` directly.

Store the selected areas for the next phase.

### Phase 6: Deep-Dive Each Selected Area

Read `references/deep-dive-methodology.md` for the deep-dive questioning loop procedure.

### Phase 7: Write CONTEXT.md

Read `assets/context-template.md`. Populate it with:

1. **Phase Boundary section:**
   - Goal from ROADMAP.md
   - Success criteria from ROADMAP.md
   - Brief summary of scope (derived from goal + discussed areas)
   - Out of scope items (from deferred list)

2. **Codebase Context section:**
   - Existing related code (key files/modules found by Explore agent)
   - Established patterns (conventions, tech choices)
   - Integration points (code this phase interacts with)
   - Constraints from existing code

3. **Cross-Phase Dependencies section** (omit for Phase 1):
   - What each relevant prior phase provides (from SUMMARY/PLAN/CONTEXT.md)
   - Specific deliverables this phase will consume or extend
   - Assumptions about prior phases that must hold

4. **Implementation Decisions section:**
   - One subsection per area discussed
   - Each subsection: Decision, Rationale, Constraints

5. **Claude's Discretion section:**
   - List of areas where user answered "You decide"

6. **Specific Ideas section:**
   - User-provided references, examples, or specific guidance mentioned during discussion

7. **Deferred Ideas section:**
   - Ideas captured but explicitly out of scope

Write to `${PHASE_DIR}/${PHASE}-CONTEXT.md`.

**Do NOT commit.** Tell user how to commit.

### Phase 8: Present Summary

Check if RESEARCH.md exists for this phase:

```bash
RESEARCH_FILE=$(ls "${PHASE_DIR}"/*-RESEARCH.md 2>/dev/null | head -1)
[ -n "$RESEARCH_FILE" ] && echo "RESEARCH_EXISTS=true" || echo "RESEARCH_EXISTS=false"
```

**If RESEARCH_EXISTS=false**, use AskUserQuestion to recommend research:

- header: "Research"
- question: "No research exists for this phase yet. Would you like to research ecosystem options, libraries, and patterns before planning? (Recommended)"
- multiSelect: false
- options:
  - label: "Research first (Recommended)"
    description: "Run /research-phase to investigate libraries, patterns, and pitfalls before planning"
  - label: "Skip to planning"
    description: "Go straight to /plan-phase with current context"

Then display the summary with the appropriate next step based on their choice:

```
Context captured for Phase {N}: {Name}

Decisions locked:
- {Area 1}: {brief decision summary}
- {Area 2}: {brief decision summary}

Claude's discretion:
- {Area}: {brief description}

Deferred ideas: {count}

---

Created:
- .planning/phases/{phase-dir}/{phase}-CONTEXT.md

To commit when ready:
  git add .planning/phases/{phase-dir}/{phase}-CONTEXT.md && git commit -m "docs: capture phase {N} implementation context"

---

## Next Step

{If user chose "Research first" OR RESEARCH_EXISTS=false and user was not asked (shouldn't happen, but fallback):}

**Research the ecosystem before planning:**
- /research-phase {N}

{If user chose "Skip to planning" OR RESEARCH_EXISTS=true:}

**Plan the phase with locked context:**
- /plan-phase {N}

---
```

## Success Criteria

- [ ] Phase number validated against ROADMAP.md
- [ ] Existing CONTEXT.md handled (update/view/replace offered)
- [ ] Phase context loaded (goal, success criteria, requirements)
- [ ] Earlier phase artifacts loaded (SUMMARY/PLAN/CONTEXT.md) for cross-phase awareness
- [ ] Codebase explored via Explore agent for phase-relevant patterns and constraints
- [ ] 3-4 domain-specific gray areas identified, grounded in codebase AND prior phase plans
- [ ] User selected which areas to discuss via AskUserQuestion
- [ ] Each selected area deep-dived with 4+ targeted questions
- [ ] Decisions, discretion, and deferred ideas tracked
- [ ] CONTEXT.md written to phase directory using template
- [ ] User told how to commit (never auto-commit)
- [ ] User prompted to research if no RESEARCH.md exists (recommended before planning)
- [ ] User knows next step (/research-phase or /plan-phase based on choice)

## Scope Guardrails

**Phase boundary is FIXED.** Discussion clarifies HOW to implement the phase goal, not WHETHER to change the goal.

If user wants to change the phase goal itself, exit this skill and tell them to edit ROADMAP.md first.

**Only Explore agents for codebase context.** The Explore agent in Phase 3.7 is the only subagent this skill spawns. Don't spawn research, planning, or execution agents.

**Progressive refinement OK.** User can run `/discuss-phase {N}` multiple times to refine context before planning.
