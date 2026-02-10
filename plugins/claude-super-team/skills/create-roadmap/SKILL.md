---
name: create-roadmap
description: Create or modify project roadmap with phased delivery plan and state tracking. Reads .planning/PROJECT.md (required) and optionally .planning/REQUIREMENTS.md. Produces .planning/ROADMAP.md and .planning/STATE.md. Use after /new-project to define phases, success criteria, and delivery order. Also use to add phases, insert urgent phases with decimal numbering, reorder phases, or replace an existing roadmap. Pass modification intent as arguments (e.g., "add a security phase", "insert urgent auth fix after phase 2", "reorder to prioritize payments").
argument-hint: "[modification description]"
allowed-tools: Read, Bash, Write, AskUserQuestion, Glob, Grep
disable-model-invocation: false
---

## Objective

Transform project context into a phased delivery roadmap with goal-backward success criteria.

Derive phases from requirements -- don't impose arbitrary structure. Each phase delivers a coherent, verifiable capability with observable success criteria.

**Reads:** `.planning/PROJECT.md` (required), `.planning/REQUIREMENTS.md` (optional), `.planning/research/SUMMARY.md` (optional), `.planning/codebase/` docs (optional)
**Creates:** `.planning/ROADMAP.md` + `.planning/STATE.md`

## Process

### Phase 1: Setup Checks

**Execute before any interaction:**

1. **Require PROJECT.md:**

   ```bash
   [ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
   ```

2. **Check for existing roadmap:**

   ```bash
   [ -f .planning/ROADMAP.md ] && echo "ROADMAP_EXISTS=true" || echo "ROADMAP_EXISTS=false"
   ```

3. **Detect available context:**

   ```bash
   [ -f .planning/REQUIREMENTS.md ] && echo "HAS_REQUIREMENTS=true" || echo "HAS_REQUIREMENTS=false"
   [ -f .planning/research/SUMMARY.md ] && echo "HAS_RESEARCH=true" || echo "HAS_RESEARCH=false"
   [ -d .planning/codebase ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"
   ```

**You MUST run all bash commands above before proceeding.**

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

### Phase 2A: Add Phase

1. Read ROADMAP.md, find the highest integer phase number. Set `NEXT_PHASE = highest + 1`.
2. Derive the new phase name, goal, requirements covered, and 2-5 success criteria from `$ARGUMENTS` and existing project context (PROJECT.md, REQUIREMENTS.md if available).
3. Present the proposed phase to the user:

   ```
   Proposed Phase {NEXT_PHASE}: {Name}
   Goal: {goal}
   Requirements: {requirements}
   Success Criteria:
     1. {criterion}
     2. {criterion}
   ```

   Use AskUserQuestion:
   - header: "New phase"
   - question: "Add this phase to the roadmap?"
   - options:
     - "Approve" -- Write the phase
     - "Adjust" -- Refine details
     - "Cancel" -- Exit without changes

4. On approve: append to `## Phases` checklist, append `### Phase N` section to `## Phase Details`, append row to `## Progress` table.
5. Skip to Phase 7 (Done) with modified completion message: "Phase {N} added to roadmap."

### Phase 2B: Insert Urgent Phase

Uses decimal numbering -- inserting after Phase N creates Phase N.1, N.2, etc. Never renumbers existing phases.

1. Read ROADMAP.md, display current phases.
2. Determine the target phase from `$ARGUMENTS` (e.g., "after phase 2" means target = 2). If ambiguous, use AskUserQuestion:
   - header: "Position"
   - question: "Insert after which phase?"
   - options: list of current phases
3. Find existing decimals for that phase (grep `Phase {N}\.[0-9]+`), calculate next decimal: if none exist, use `N.1`; if `N.1` exists, use `N.2`, etc.
4. Derive phase details from `$ARGUMENTS` and project context. Auto-set `depends_on` to the target phase.
5. Present with `(INSERTED)` tag:

   ```
   Proposed Phase {N.X}: {Name} (INSERTED)
   Goal: {goal}
   Depends on: Phase {N}
   Success Criteria:
     1. {criterion}
   ```

   Use AskUserQuestion:
   - header: "Insert phase"
   - question: "Insert this urgent phase?"
   - options:
     - "Approve" -- Write the phase
     - "Adjust" -- Refine details
     - "Cancel" -- Exit without changes

6. On approve: insert into `## Phases` checklist after target phase, insert `### Phase N.X: Name (INSERTED)` section at correct position in `## Phase Details`, insert row in `## Progress` table.
7. Skip to Phase 7 (Done) with message: "Phase {N.X} inserted after Phase {N}."

Directory convention for downstream skills: `{NN.X}-{slug}/` (e.g., `02.1-security-hardening/`).

### Phase 2C: Reorder Phases

1. Read ROADMAP.md. Display phases with their `depends_on` relationships.
2. Determine the reorder intent from `$ARGUMENTS` (e.g., "focus on multi-tenant first" means move multi-tenant phase earlier). If ambiguous, use AskUserQuestion:
   - header: "Reorder"
   - question: "Which phase to move?"
   - options: list of current phases
3. Use AskUserQuestion for new position if not clear from arguments:
   - header: "Position"
   - question: "Move to which position?"
   - options: "Before Phase {X}" / "After Phase {Y}" etc.
4. Validate no circular dependencies are created.
5. Present new order:

   ```
   Proposed phase order:
   1. Phase 1: {Name} (unchanged)
   2. Phase 4: {Name} (moved up)
   3. Phase 2: {Name} (moved down)
   ...
   ```

   Use AskUserQuestion:
   - header: "Reorder"
   - question: "Apply this new ordering?"
   - options:
     - "Approve" -- Apply changes
     - "Adjust" -- Different ordering
     - "Cancel" -- Exit without changes

6. On approve: reorder the `## Phases` checklist, `## Phase Details` sections, and `## Progress` rows. Update `depends_on` fields to reflect new ordering. Phase numbers stay the same -- only ordering and dependencies change.
7. Skip to Phase 7 (Done) with message: "Phases reordered."

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

**Philosophy: requirements drive structure, not templates.**

Analyze the requirements and derive natural delivery boundaries:

1. **Group by capability** -- Which requirements cluster into coherent deliverables?
2. **Identify dependencies** -- Which capabilities depend on others?
3. **Create phases** -- Each phase delivers one complete, verifiable capability.

**Goal-backward thinking for each phase:**

Don't ask "what should we build?" -- ask "what must be TRUE for users when this phase completes?"

For each phase, derive 2-5 success criteria that are:

- Observable from the user's perspective
- Verifiable by a human using the application
- Stated as outcomes, not tasks

Good: "User can log in with email/password and stay logged in across browser sessions"
Bad: "Build authentication system"

**Phase count guidance:**

- Let the work determine the count. Don't pad small projects or compress complex ones.
- 3-5 phases for focused projects, 5-8 for medium, 8-12 for large
- Each phase should feel inevitable given the requirements, not arbitrary

**Anti-patterns:**

- Horizontal layers (all models, then all APIs, then all UI)
- Arbitrary splits to hit a number
- Enterprise PM artifacts (time estimates, Gantt charts, risk matrices)
- Phases for team coordination, documentation, or ceremonies

### Phase 5: Present Draft

Present the proposed roadmap to the user. Show:

1. Phase overview (name + one-liner for each)
2. Per-phase: goal, requirements covered, success criteria
3. Requirement coverage: which requirements map to which phase

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

Write `.planning/ROADMAP.md` using the template from `assets/roadmap.md`. Fill in all phase details, goals, requirements, success criteria, and progress table.

Write `.planning/STATE.md` using the template from `assets/state.md`. Initialize with Phase 1 as current position.

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
