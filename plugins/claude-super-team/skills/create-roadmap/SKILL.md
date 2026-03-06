---
name: create-roadmap
description: Create or modify project roadmap with phased delivery plan, sprint grouping, and state tracking. MUST use this skill whenever the user mentions roadmap, phases, build order, delivery plan, milestones, sprints, or wants to figure out what to build in what order. Also use when user wants to add/insert/reorder/split/restructure/reprioritize/replace phases, squeeze in urgent work, or redo the roadmap. Reads .planning/PROJECT.md (required). Produces .planning/ROADMAP.md and .planning/STATE.md. Trigger even when user says things like "break this into phases", "figure out the build order", "what should we build first", "organize into milestones", "I need a delivery plan", or "help me plan the project phases". Pass modification intent as arguments.
argument-hint: "[modification description]"
allowed-tools: Read, Write, AskUserQuestion, Glob, Grep, Bash(test *), Bash(bash *gather-data.sh)
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-roadmap/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STRUCTURE, EXISTING_PHASES, HIGHEST_PHASE, DECIMAL_PHASES) before proceeding.

**Context-aware skip:** If PROJECT.md or ROADMAP.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/create-roadmap/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Transform project context into a phased delivery roadmap with goal-backward success criteria.

Derive phases from requirements -- don't impose arbitrary structure. Each phase delivers a coherent, verifiable capability with observable success criteria.

**Reads:** `.planning/PROJECT.md` (required), `.planning/REQUIREMENTS.md` (optional), `.planning/research/SUMMARY.md` (optional), `.planning/codebase/` docs (optional)
**Creates:** `.planning/ROADMAP.md` + `.planning/STATE.md`

## Process

### Phase 1: Setup Checks

Use the pre-loaded **STRUCTURE** data from dynamic context injection. The flags are already computed:

- `HAS_PROJECT` -- if `false`, show "ERROR: No project found. Run /new-project first." and exit
- `HAS_ROADMAP` -- determines whether to create new or modify existing (Phase 2)
- `HAS_REQUIREMENTS`, `HAS_RESEARCH`, `HAS_CODEBASE` -- which optional context to load in Phase 3

PROJECT.md and ROADMAP.md contents are also pre-loaded above. No Bash calls needed for setup.

### Phase 2: Handle Existing Roadmap

**If ROADMAP_EXISTS=false:** Skip to Phase 3 (create new roadmap).

**If ROADMAP_EXISTS=true:** Interpret intent from `$ARGUMENTS` to determine the operation.

**Intent detection rules** (evaluate in order, first match wins):

1. **Insert urgent phase** -- Arguments contain words like: "insert", "urgent", "after phase", "before phase", "critical", "block", "hotfix", "security fix", "immediately". Go to **Phase 2B**.
2. **Reorder phases** -- Arguments contain words like: "reorder", "reprioritize", "move phase", "swap", "change order", "focus on ... first", "prioritize". Go to **Phase 2C**.
3. **Replace entirely** -- Arguments contain words like: "replace", "start over", "redo", "from scratch", "new roadmap". Delete `.planning/ROADMAP.md` and `.planning/STATE.md`, continue to Phase 3.
4. **Add phase (default for modification)** -- Arguments contain any other modification description (e.g., "add a security phase", "include monitoring"). Go to **Phase 2A**.
5. **No arguments** -- If `$ARGUMENTS` is empty, use AskUserQuestion:
   - header: "Roadmap"
   - question: "A roadmap already exists. What would you like to do?"
   - options:
     - "Add a phase" -- Go to Phase 2A
     - "Insert urgent phase" -- Go to Phase 2B
     - "Reorder phases" -- Go to Phase 2C
     - "Replace entirely" -- Delete and continue to Phase 3

Read `${CLAUDE_SKILL_DIR}/references/roadmap-modification.md` for the detailed add, insert, and reorder phase procedures.

### Phase 3: Load Context

Read `.planning/PROJECT.md`. Extract:

- Core Value
- Active requirements (from Requirements section)
- Constraints
- Key Decisions

**If HAS_REQUIREMENTS=true:** Also read `.planning/REQUIREMENTS.md`. Use its formal requirement definitions and categories as the primary source for phase derivation.

**If HAS_RESEARCH=true:** Also read `.planning/research/SUMMARY.md`. Use its "Implications for Roadmap" section as input for phase suggestions.

**If HAS_CODEBASE=true:** Also read `.planning/codebase/ARCHITECTURE.md` and `.planning/codebase/STACK.md` to understand existing system structure.

### Phase 4: Derive Phases

Read `${CLAUDE_SKILL_DIR}/references/phase-derivation.md` for the goal-backward phase derivation methodology.

### Phase 5: Present Draft

Present the proposed roadmap to the user. Show:

1. Sprint overview: which phases run in parallel per sprint, and what's demoable after each sprint
2. Phase overview (name + sprint + T-shirt size + one-liner for each)
3. Per-phase: goal, requirements covered, success criteria
4. Requirement coverage: which requirements map to which phase

**Sprint validation:** Every sprint should produce something the user can try or demo. If a sprint contains only infrastructure/setup phases with nothing demoable, restructure: either bundle a feature slice into that sprint or merge the setup into an adjacent sprint.

**Coverage check:** If a PROJECT.md Active requirement doesn't map to any phase, flag it explicitly.

Use AskUserQuestion:

- header: "Roadmap"
- question: "Here's the proposed roadmap. What do you think?"
- options:
  - "Approve" -- Write the roadmap files
  - "Adjust" -- I have feedback on the phases
  - "Start over" -- Rethink the approach entirely

**If "Adjust":** Use AskUserQuestion to understand what to change. Specific questions based on the draft -- "Which phase needs changes?" with phase names as options, or "What's wrong?" with concrete interpretations. Revise and re-present.

**If "Start over":** Return to Phase 4 with a different approach.

**If "Approve":** Continue to Phase 6.

Loop until approved.

### Phase 6: Write Files

Write `.planning/ROADMAP.md` using the template from `${CLAUDE_SKILL_DIR}/assets/roadmap.md`. Fill in all phase details, goals, requirements, success criteria, and progress table.

Write `.planning/STATE.md` using the template from `${CLAUDE_SKILL_DIR}/assets/state.md`. Initialize with Phase 1 as current position.

**Carry preferences:** If `.planning/PROJECT.md` has a `## Preferences` section with `execution-model`, copy that value into STATE.md's `## Preferences` section. If PROJECT.md has no preference set, default to `sonnet`.

**Do NOT commit.** Tell the user:

```
Created:
- .planning/ROADMAP.md
- .planning/STATE.md

To commit when ready:
  git add .planning/ROADMAP.md .planning/STATE.md && git commit -m "docs: create project roadmap"
```

### Phase 7: Done

```
Roadmap created.

Created:
- .planning/ROADMAP.md ([N] phases)
- .planning/STATE.md

---

## Next Steps

**Review the roadmap:**
- Read .planning/ROADMAP.md for full phase details

**Start building:**
- Begin with Phase 1 using /plan-phase or /discuss-phase

**Edit before continuing:**
- Update ROADMAP.md if anything needs refinement

---
```

## Success Criteria

- [ ] PROJECT.md exists and was read
- [ ] Available context loaded (REQUIREMENTS.md, research, codebase docs)
- [ ] Phases derived from requirements, not imposed
- [ ] Each phase has goal-backward success criteria (2-5 observable behaviors)
- [ ] All Active requirements from PROJECT.md mapped to a phase
- [ ] User approved the roadmap via AskUserQuestion
- [ ] ROADMAP.md written to .planning/
- [ ] STATE.md written to .planning/
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps
