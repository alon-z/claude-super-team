---
name: discuss-phase
description: Gather implementation decisions through adaptive questioning before planning. Identifies gray areas in a phase, deep-dives each with the user, and creates CONTEXT.md that constrains downstream planning. Use after /create-roadmap and before /plan-phase to lock decisions and clarify ambiguities.
argument-hint: "<phase number>"
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
---

## Objective

Capture user implementation decisions before planning begins. Creates CONTEXT.md that locks decisions, defines discretion boundaries, and defers scope creep.

**Why this matters:** Planning agents work better with constraints. "Build auth" is ambiguous. "OAuth2 with Google/GitHub providers, JWT tokens in httpOnly cookies" is executable.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, phase `CONTEXT.md` (if exists)
**Creates:** `.planning/phases/{phase}-{name}/CONTEXT.md`

## Process

### Phase 1: Validate Phase Number

```bash
[ ! -f .planning/ROADMAP.md ] && echo "ERROR: No roadmap found. Run /create-roadmap first." && exit 1
```

You MUST run this check before proceeding.

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

### Phase 4: Identify Gray Areas

**Domain-aware analysis.** Don't use generic categories. Analyze this specific phase to find 3-4 actual ambiguities.

**Process:**

1. Read the phase goal and success criteria
2. Identify the domain (auth, payments, API design, data modeling, etc.)
3. Derive 3-4 specific gray areas where reasonable people would disagree

**Good gray areas** (domain-specific, phase-specific):
- "Should password reset tokens expire after first use or after time limit?"
- "Where should we validate payment amounts: client, API, or both?"
- "Should deleted items be soft-deleted (flagged) or hard-deleted (removed)?"

**Bad gray areas** (generic, could apply to any phase):
- "What technologies should we use?"
- "How should we structure the code?"
- "What about performance?"

**Anti-pattern: Pre-made category lists.** Every phase gets unique gray areas derived from its goal, not recycled from a template.

**Domain examples:**

| Domain | Example Gray Areas |
|--------|-------------------|
| Authentication | Token storage location, session duration, MFA approach, password requirements |
| Payments | Idempotency strategy, refund flow, currency handling, failed payment retries |
| Multi-tenancy | Tenant isolation level, shared vs separate DBs, cross-tenant references |
| Search | Indexing approach, fuzzy match threshold, result ranking algorithm |
| File uploads | Storage location, size limits, virus scanning, CDN strategy |

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

For each selected area from Phase 5, run this loop:

**6.1. Generate 4 targeted questions** for this area. Questions should:
- Progress from high-level to specific
- Be answerable with concrete decisions, not philosophy
- Build on previous answers within the same area

Example for "Token storage location" area:
1. "Where should access tokens be stored?"
2. "Where should refresh tokens be stored?"
3. "What's the acceptable token lifetime?"
4. "How should expired tokens be handled?"

**6.2. Ask each question sequentially** using AskUserQuestion with 2-4 options. Always include:
- Concrete options (e.g., "httpOnly cookies", "localStorage", "sessionStorage")
- "You decide" option (captures areas for Claude's Discretion)

**6.3. After 4 questions, check if more needed** via AskUserQuestion:

- header: "Continue"
- question: "Anything else to clarify about {area name}?"
- multiSelect: false
- options:
  - label: "All set"
    description: "Move to next area"
  - label: "Keep discussing"
    description: "Ask more questions about this area"

**On "Keep discussing":** Generate 2-4 more questions, ask them, then check again. Limit: 3 rounds per area.

**6.4. Track decisions:**

Build a structured record as you go:

```
{
  "area": "{area name}",
  "decisions": [
    {"question": "...", "answer": "...", "rationale": "..." }
  ],
  "discretion": [ "..." ],  // "You decide" answers
  "deferred": [ "..." ]      // Ideas mentioned but out of scope
}
```

**Identifying deferred ideas:** If user mentions something clearly outside phase scope during discussion (e.g., "we should also add 2FA" when phase is just basic auth), acknowledge it and ask:

- header: "Defer"
- question: "'{idea}' sounds valuable but may be outside Phase {N} scope. How should we handle it?"
- options:
  - label: "Defer to later"
    description: "Capture for future phase"
  - label: "Include now"
    description: "Expand this phase scope"

If "Defer to later", add to deferred list. If "Include now", integrate into current area decisions.

### Phase 7: Write CONTEXT.md

Read `assets/context-template.md`. Populate it with:

1. **Phase Boundary section:**
   - Goal from ROADMAP.md
   - Success criteria from ROADMAP.md
   - Brief summary of scope (derived from goal + discussed areas)
   - Out of scope items (from deferred list)

2. **Implementation Decisions section:**
   - One subsection per area discussed
   - Each subsection: Decision, Rationale, Constraints

3. **Claude's Discretion section:**
   - List of areas where user answered "You decide"

4. **Specific Ideas section:**
   - User-provided references, examples, or specific guidance mentioned during discussion

5. **Deferred Ideas section:**
   - Ideas captured but explicitly out of scope

Write to `${PHASE_DIR}/${PHASE}-CONTEXT.md`.

**Do NOT commit.** Tell user how to commit.

### Phase 8: Present Summary

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

## Next Steps

**Plan the phase with locked context:**
- /plan-phase {N}

**Review context first:**
- Read .planning/phases/{phase-dir}/{phase}-CONTEXT.md

**Edit before planning:**
- Update CONTEXT.md if anything needs refinement

---
```

## Success Criteria

- [ ] Phase number validated against ROADMAP.md
- [ ] Existing CONTEXT.md handled (update/view/replace offered)
- [ ] Phase context loaded (goal, success criteria, requirements)
- [ ] 3-4 domain-specific gray areas identified (not generic categories)
- [ ] User selected which areas to discuss via AskUserQuestion
- [ ] Each selected area deep-dived with 4+ targeted questions
- [ ] Decisions, discretion, and deferred ideas tracked
- [ ] CONTEXT.md written to phase directory using template
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps (/plan-phase with context)

## Scope Guardrails

**Phase boundary is FIXED.** Discussion clarifies HOW to implement the phase goal, not WHETHER to change the goal.

If user wants to change the phase goal itself, exit this skill and tell them to edit ROADMAP.md first.

**No research spawning.** This skill is interactive (AskUserQuestion-based), not agent-driven. Don't spawn Task agents.

**Progressive refinement OK.** User can run `/discuss-phase {N}` multiple times to refine context before planning.
