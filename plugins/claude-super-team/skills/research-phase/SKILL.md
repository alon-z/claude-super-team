---
name: research-phase
description: "Research how to implement a phase before planning. Spawns a phase-researcher agent that uses Context7 for known library docs and Firecrawl for ecosystem discovery. Produces RESEARCH.md consumed by /plan-phase planner."
argument-hint: "<phase number>"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(bash *gather-data.sh)
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/research-phase/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, PREREQUISITES, PHASE_ARTIFACTS, ROADMAP_PHASES, CODEBASE_DOCS) before proceeding.

**Context-aware skip:** If PROJECT.md, ROADMAP.md, or STATE.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/research-phase/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Research ecosystem, libraries, architecture patterns, and pitfalls for a phase before planning. Spawns a custom `phase-researcher` agent that produces RESEARCH.md consumed directly by the planner.

**Flow:** Validate phase -> Check existing -> Load context -> Spawn researcher -> Handle return -> Done

**Why agents:** Research burns context fast with web scraping and doc reading. The researcher gets a fresh context with project files + methodology. Main context stays lean.

**Why custom agent:** The `phase-researcher` agent definition embeds the full research methodology, template, and Firecrawl skill. This SKILL.md only passes dynamic per-invocation context.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, phase CONTEXT.md (if exists), `.planning/codebase/` docs (if exist)
**Creates:** `.planning/phases/{phase}-{name}/{phase}-RESEARCH.md`

## Process

### Phase 1: Validate Environment

PROJECT.md, ROADMAP.md, and STATE.md are pre-loaded via dynamic context injection. If their contents are empty/missing from the injection, show the appropriate error and exit:

- No PROJECT.md content: "ERROR: No project found. Run /new-project first."
- No ROADMAP.md content: "ERROR: No roadmap found. Run /create-roadmap first."

### Phase 1.5: Parse Phase Number

Parse phase number from `$ARGUMENTS`. If not provided or invalid, use **ROADMAP_PHASES** from the gather script to show available phases and exit.

Normalize phase to zero-padded format:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/phase-utils.sh"
PHASE=$(normalize_phase "$PHASE_NUM")
```

Validate phase exists using **ROADMAP_PHASES** from the gather script. If not found, show available phases and exit.

Find or create the phase directory using **PHASE_ARTIFACTS** from the gather script. Each line shows:

```
{dir_name}|context={N}|research={N}|plans={N}|summaries={N}
```

Match on the phase prefix (e.g., `02-` or `02.1-`). If no directory exists, create it:

```bash
mkdir -p ".planning/phases/${PHASE}-${phase_name}"
```

### Phase 2: Check Existing Research

Use **PHASE_ARTIFACTS** from the gather script. The `research` count for the matched phase directory tells you if RESEARCH.md exists (research > 0).

**If research exists:** Use AskUserQuestion:

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

**If no research exists:** Continue to Phase 3.

### Phase 3: Load Phase Context

PROJECT.md, ROADMAP.md, and STATE.md are already available from dynamic context injection. Gather additional files for embedding in the agent prompt:

**Already injected (use directly):**

- `.planning/PROJECT.md` -- project vision, requirements
- `.planning/ROADMAP.md` -- phase goals, success criteria
- `.planning/STATE.md` -- current position, accumulated decisions

**Read if exists (check PHASE_ARTIFACTS and CODEBASE_DOCS from gather script):**

- `${PHASE_DIR}/*-CONTEXT.md` -- user decisions from /discuss-phase (CRITICAL: constrains research scope)
- `.planning/codebase/STACK.md` -- existing technology stack
- `.planning/codebase/ARCHITECTURE.md` -- existing architecture patterns

### Phase 3.5: Collect Relevant Prior Research

Read `${CLAUDE_SKILL_DIR}/references/prior-research-selection.md` for the prior research relevance criteria and selection procedure.

### Phase 4: Spawn Researcher Agent

Spawn the custom `phase-researcher` agent via Task tool. The agent definition already contains the full research methodology, RESEARCH.md template, and preloaded Firecrawl skill. Only pass dynamic per-invocation context:

```
Task(
  subagent_type: "phase-researcher"
  description: "Research Phase {N}"
  prompt: """
  ultrathink

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
  Prior phase research (relevant only):
  {prior_research or "None -- no prior research is relevant to this phase."}
  ---
  Prior research notes: If prior phase research is included above, use it as
  baseline knowledge. Do not re-research topics already covered there unless
  you have reason to believe the findings are outdated. Focus your effort on
  what is NEW for this phase.
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

Read `${CLAUDE_SKILL_DIR}/references/conflict-detection.md` for the decision conflict detection procedure and user routing.

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
- [ ] Prior RESEARCH.md files scanned; only relevant ones included (0-3 max)
- [ ] Custom `phase-researcher` agent spawned with dynamic context
- [ ] RESEARCH.md created in phase directory
- [ ] User sees completion summary with key findings and confidence
- [ ] Research findings compared against CONTEXT.md decisions for conflicts
- [ ] User prompted to re-discuss if conflicts found (deprecated packages, better alternatives, etc.)
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next step (/discuss-phase if conflicts, /plan-phase otherwise)
