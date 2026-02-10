---
name: discuss-phase
description: Gather implementation decisions through adaptive questioning before planning. Identifies gray areas in a phase, deep-dives each with the user, and creates CONTEXT.md that constrains downstream planning. Use after /create-roadmap and before /plan-phase to lock decisions and clarify ambiguities.
argument-hint: "<phase number>"
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion, Task
---

## Objective

Capture user implementation decisions before planning begins. Creates CONTEXT.md that locks decisions, defines discretion boundaries, and defers scope creep.

**Why this matters:** Planning agents work better with constraints. "Build auth" is ambiguous. "OAuth2 with Google/GitHub providers, JWT tokens in httpOnly cookies" is executable.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, phase `CONTEXT.md` (if exists), earlier phase artifacts (`SUMMARY.md`, `PLAN.md`, `CONTEXT.md`)
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

### Phase 3.5: Load Cross-Phase Context

Before exploring the codebase, understand what earlier phases will create. This phase may depend on infrastructure, APIs, models, or patterns that don't exist yet but are planned.

**Why:** Phase 5 might use an auth system being built in phase 3. Without cross-phase context, the discussion asks questions that were already answered or plans features that ignore what's coming.

**Process:**

1. List all phase directories with a lower phase number than the current one:

```bash
ls -d .planning/phases/*/ 2>/dev/null | sort
```

2. For each earlier phase, load the most informative artifact available (in priority order):
   - **SUMMARY.md** (phase already executed -- shows what was actually built)
   - **PLAN.md files** (phase planned but not executed -- shows what will be built, including specific APIs, models, endpoints, patterns)
   - **CONTEXT.md** (phase discussed but not planned -- shows locked decisions)
   - **ROADMAP.md entry** (fallback -- just the goal and success criteria)

3. Build a concise "Prior Phase Summary" focusing on what each earlier phase provides that this phase might consume:
   - APIs, endpoints, or services being created
   - Data models, schemas, or database tables
   - Shared utilities, middleware, or patterns
   - Auth flows, permissions, or access control mechanisms
   - Configuration, environment variables, or infrastructure

```
PRIOR PHASES FOR PHASE {N}:

Phase 1 ({name}) [executed]:
- Built: {key deliverables}
- Provides: {what this phase can use}

Phase 2 ({name}) [planned]:
- Will build: {key deliverables from PLAN.md}
- Will provide: {what this phase can piggyback on}

Phase 3 ({name}) [discussed]:
- Decided: {key decisions from CONTEXT.md}
- Will provide: {expected deliverables based on decisions}
```

4. Identify **cross-phase dependencies** -- specific things this phase needs that an earlier phase creates. These feed directly into gray area generation (Phase 4) and deep-dive questions (Phase 6).

**Skip this step** if the current phase is Phase 1 (no prior phases).

### Phase 3.7: Gather Codebase Context

Before identifying gray areas, explore the actual codebase to ground the discussion in reality.

**Why:** Generic gray areas ("JWT vs sessions?") waste the user's time. Codebase-aware gray areas ("There's an existing `middleware/auth.ts` using Passport.js -- extend it or replace?") surface real decisions.

**Step 1: Check for codebase mapping**

```bash
ls .planning/codebase/ 2>/dev/null
```

If `.planning/codebase/` exists, read the docs most relevant to this phase's domain:
- Always read: `ARCHITECTURE.md`, `STACK.md`
- Read `CONVENTIONS.md` if the phase involves writing new code patterns
- Read `INTEGRATIONS.md` if the phase involves external services or APIs
- Read `TESTING.md` if the phase has testing-related success criteria

Store key findings (existing patterns, relevant files, tech choices) for use in Phase 4.

**Step 2: Spawn Explore agent for targeted codebase analysis**

Regardless of whether codebase mapping exists, spawn an Explore agent (subagent_type: "Explore") to find code directly relevant to this phase. The agent should:

- Search for files, functions, and patterns related to the phase domain keywords
- Identify existing implementations that the phase will extend, modify, or interact with
- Note conventions, patterns, and tech choices already established in the codebase
- Flag potential conflicts or constraints the user should know about

**Prompt template for the Explore agent:**

```
Explore this codebase to find code relevant to implementing: "{phase_goal}"

Phase success criteria:
{list success criteria from roadmap}

Find and report:
1. Existing files/modules directly related to this phase's domain
2. Patterns and conventions already established (naming, structure, error handling)
3. Dependencies and tech choices relevant to this phase
4. Integration points -- code this phase will need to interact with
5. Potential constraints or conflicts (e.g., existing implementations that overlap)

Be thorough but focused on what matters for planning this specific phase.
Report findings as a structured summary, not raw file contents.
```

Use `subagent_type: "Explore"` and set thoroughness to "medium" in the prompt.

**Step 3: Synthesize findings**

Combine codebase mapping docs (if available) and Explore agent results into a concise "Codebase Context" summary:

```
CODEBASE CONTEXT FOR PHASE {N}:
- Existing related code: {list key files/modules found}
- Established patterns: {relevant conventions, tech choices}
- Integration points: {code this phase will interact with}
- Constraints: {things that limit implementation choices}
```

This summary feeds directly into Phase 4 to produce grounded gray areas.

### Phase 4: Identify Gray Areas

**Domain-aware, codebase-aware, and cross-phase-aware analysis.** Don't use generic categories. Analyze this specific phase -- informed by codebase context (Phase 3.7) and prior phase plans (Phase 3.5) -- to find 3-4 actual ambiguities.

**Process:**

1. Read the phase goal, success criteria, codebase context (Phase 3.7), AND prior phase summary (Phase 3.5)
2. Identify the domain (auth, payments, API design, data modeling, etc.)
3. Derive 3-4 specific gray areas where reasonable people would disagree, grounded in what the codebase already has AND what earlier phases will create

**Cross-phase-aware gray areas** leverage prior phase plans:
- "Phase 3 plans a `PermissionService` with role-based access -- should this phase extend it with resource-level permissions or keep it role-only?" (cross-phase-aware)
- "How should we handle permissions?" (generic, ignores prior phases, bad)

**Codebase-grounded gray areas** reference actual code:
- "The codebase uses Prisma with a `User` model but no role field -- how should we model permissions?" (grounded)
- "How should we handle permissions?" (generic, bad)

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
- [ ] Earlier phase artifacts loaded (SUMMARY/PLAN/CONTEXT.md) for cross-phase awareness
- [ ] Codebase explored via Explore agent for phase-relevant patterns and constraints
- [ ] 3-4 domain-specific gray areas identified, grounded in codebase AND prior phase plans
- [ ] User selected which areas to discuss via AskUserQuestion
- [ ] Each selected area deep-dived with 4+ targeted questions
- [ ] Decisions, discretion, and deferred ideas tracked
- [ ] CONTEXT.md written to phase directory using template
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps (/plan-phase with context)

## Scope Guardrails

**Phase boundary is FIXED.** Discussion clarifies HOW to implement the phase goal, not WHETHER to change the goal.

If user wants to change the phase goal itself, exit this skill and tell them to edit ROADMAP.md first.

**Only Explore agents for codebase context.** The Explore agent in Phase 3.7 is the only subagent this skill spawns. Don't spawn research, planning, or execution agents.

**Progressive refinement OK.** User can run `/discuss-phase {N}` multiple times to refine context before planning.
