---
name: research-phase
description: Research how to implement a phase before planning. Spawns a custom phase-researcher agent that investigates ecosystem, architecture patterns, libraries, and pitfalls. Firecrawl is preloaded via the agent definition. Produces RESEARCH.md consumed by /plan-phase planner. Use after /discuss-phase and before /plan-phase.
argument-hint: "<phase number>"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *)
---

## Objective

Research ecosystem, libraries, architecture patterns, and pitfalls for a phase before planning. Spawns a custom `phase-researcher` agent that produces RESEARCH.md consumed directly by the planner.

**Flow:** Validate phase -> Check existing -> Load context -> Spawn researcher -> Handle return -> Done

**Why agents:** Research burns context fast with web scraping and doc reading. The researcher gets a fresh context with project files + methodology. Main context stays lean.

**Why custom agent:** The `phase-researcher` agent definition embeds the full research methodology, template, and Firecrawl skill. This SKILL.md only passes dynamic per-invocation context.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, phase CONTEXT.md (if exists), `.planning/codebase/` docs (if exist)
**Creates:** `.planning/phases/{phase}-{name}/{phase}-RESEARCH.md`

## Process

### Phase 1: Validate Phase Number

```bash
[ ! -f .planning/ROADMAP.md ] && echo "ERROR: No roadmap found. Run /create-roadmap first." && exit 1
[ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
```

You MUST run these checks before proceeding.

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

### Phase 2: Check Existing Research

Check if RESEARCH.md already exists:

```bash
RESEARCH_FILE=$(ls "${PHASE_DIR}"/*-RESEARCH.md 2>/dev/null | head -1)
[ -n "$RESEARCH_FILE" ] && echo "RESEARCH_EXISTS=true" || echo "RESEARCH_EXISTS=false"
```

**If RESEARCH_EXISTS=true:** Use AskUserQuestion:

- header: "Research"
- question: "RESEARCH.md already exists for this phase. What do you want to do?"
- multiSelect: false
- options:
  - label: "Update research"
    description: "Re-run research, keeping existing as reference"
  - label: "View existing"
    description: "Show current research and exit"
  - label: "Replace entirely"
    description: "Start fresh, discard existing research"

**On "View existing":** Read and display the RESEARCH.md file, then exit with message:

```
Current research for Phase {N}:

{display RESEARCH.md contents}

---

To update: /research-phase {N}
To plan with current research: /plan-phase {N}
```

**On "Replace entirely":** Continue to Phase 3 (will overwrite later).

**On "Update research":** Load existing RESEARCH.md content to pass as context to the researcher agent. Continue to Phase 3.

**If RESEARCH_EXISTS=false:** Continue to Phase 3.

### Phase 3: Load Phase Context

Read and store these files for embedding in the agent prompt:

**Required:**

- `.planning/ROADMAP.md` -- phase goals, success criteria
- `.planning/PROJECT.md` -- project vision, requirements

**Optional (use if exists):**

- `.planning/STATE.md` -- current position, accumulated decisions
- `${PHASE_DIR}/*-CONTEXT.md` -- user decisions from /discuss-phase (CRITICAL: constrains research scope)
- `.planning/codebase/STACK.md` -- existing technology stack
- `.planning/codebase/ARCHITECTURE.md` -- existing architecture patterns

### Phase 4: Spawn Researcher Agent

Spawn the custom `phase-researcher` agent via Task tool. The agent definition already contains the full research methodology, RESEARCH.md template, and preloaded Firecrawl skill. Only pass dynamic per-invocation context:

```
Task(
  subagent_type: "phase-researcher"
  description: "Research Phase {N}"
  prompt: """
  Research Phase {phase_number}: {phase_name}
  Phase goal: {from roadmap}
  Phase success criteria: {from roadmap}
  ---
  Project context: {project_md_content}
  Roadmap: {roadmap_content}
  State: {state_content}
  Phase context: {context_md_content}
  Existing stack: {stack_content}
  Existing architecture: {architecture_content}
  Existing research (if updating): {existing_research_content}
  ---
  Write RESEARCH.md to: {path}
  Return RESEARCH COMPLETE or RESEARCH BLOCKED when done.
  """
)
```

### Phase 5: Handle Researcher Return

Parse the researcher's output:

**`## RESEARCH COMPLETE`:** Research created. Continue to Phase 6.

**`## RESEARCH BLOCKED`:** Show what was attempted and what's needed. Use AskUserQuestion:

- header: "Blocked"
- question: "Research was blocked. How do you want to proceed?"
- options:
  - label: "Retry"
    description: "Re-spawn researcher with same context"
  - label: "Provide more context"
    description: "Add information, then re-spawn"
  - label: "Plan without research"
    description: "Skip research, proceed to /plan-phase"

**On "Retry":** Re-spawn researcher (back to Phase 4).

**On "Provide more context":** Use AskUserQuestion to gather additional context, then re-spawn.

**On "Plan without research":** Exit with message suggesting `/plan-phase {N}`.

### Phase 6: Check for Decision Conflicts

Before presenting the summary, compare research findings against CONTEXT.md decisions (if CONTEXT.md exists). Look for conflicts where research invalidates or challenges prior decisions:

**Conflict types to detect:**
- **Deprecated/abandoned packages:** A library chosen in CONTEXT.md is deprecated, unmaintained, or has known security issues
- **Better alternatives discovered:** Research found a well-maintained package or built-in solution that replaces something the user planned to do manually
- **API/compatibility issues:** A chosen approach won't work with the existing stack or has breaking changes in current versions
- **Pattern mismatches:** Research reveals that a decided architecture pattern is anti-pattern for the chosen framework or ecosystem

**Process:**

1. Read the RESEARCH.md that was just created
2. Read the phase CONTEXT.md (if it exists)
3. Cross-reference: for each decision in CONTEXT.md, check if research findings contradict, deprecate, or offer a significantly better alternative
4. Build a list of conflicts (if any)

**If conflicts found**, present them and ask the user:

Use AskUserQuestion:

- header: "Conflicts"
- question: "Research found findings that may affect decisions made during discussion:"
- multiSelect: false
- options:
  - label: "Re-discuss (Recommended)"
    description: "{Brief summary of conflicts, e.g., 'chosen package X is deprecated; found library Y that automates manual step Z'}"
  - label: "Keep decisions"
    description: "Proceed to planning with current context as-is"
  - label: "Review first"
    description: "Read both files before deciding"

**On "Re-discuss":** Set next step to `/discuss-phase {N}` in the summary.

**On "Keep decisions":** Set next step to `/plan-phase {N}` in the summary.

**On "Review first":** Show paths to both RESEARCH.md and CONTEXT.md, set next step to `/discuss-phase {N}` (since they'll likely want to update after reviewing).

**If no CONTEXT.md exists or no conflicts found**, set next step to `/plan-phase {N}`.

### Phase 7: Done

Present completion summary:

```
Research complete for Phase {N}: {Name}

Key findings:
{brief summary from researcher's return}

Confidence: {N} HIGH, {N} MEDIUM, {N} LOW

{If conflicts were found:}
Decision conflicts detected:
- {conflict 1: e.g., "CONTEXT.md chose `moment.js` but research found it is in maintenance mode -- `date-fns` or `dayjs` recommended"}
- {conflict 2: e.g., "CONTEXT.md plans manual JWT validation but `next-auth` handles this out of the box"}

{End if}

Created:
- {path to RESEARCH.md}

To commit when ready:
  git add {path to RESEARCH.md} && git commit -m "docs: research phase {N}"

---

## Next Step

{If conflicts found and user chose "Re-discuss" or "Review first":}

**Update decisions with research insights:**
- /discuss-phase {N}

{If no conflicts or user chose "Keep decisions":}

**Plan the phase with research context:**
- /plan-phase {N}

---
```

## Scope Guardrails

**Research is scoped to the phase goal.** Don't research technologies unrelated to the phase's success criteria.

**Honor CONTEXT.md constraints.** If a decision is locked, don't research alternatives to that decision.

**Don't execute.** This skill produces RESEARCH.md only. No code changes, no file creation outside `.planning/`.

**No auto-commit.** Tell the user how to commit but never run `git commit` automatically.

## Success Criteria

- [ ] .planning/ROADMAP.md and PROJECT.md exist
- [ ] Phase validated against roadmap
- [ ] Phase directory created
- [ ] Existing research handled (update/view/replace offered)
- [ ] All available context loaded and embedded in agent prompt
- [ ] Custom `phase-researcher` agent spawned with dynamic context
- [ ] RESEARCH.md created in phase directory
- [ ] User sees completion summary with key findings and confidence
- [ ] Research findings compared against CONTEXT.md decisions for conflicts
- [ ] User prompted to re-discuss if conflicts found (deprecated packages, better alternatives, etc.)
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next step (/discuss-phase if conflicts, /plan-phase otherwise)
