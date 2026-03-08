# Roadmap Modification Procedures

## Compacted Phase Format

Completed phases use a compact format to reduce token usage. When reading a roadmap, recognize the `[COMPLETE]` tag:

```markdown
### Phase 3: Authentication [COMPLETE]
better-auth with Apple/Google social sign-in, session management, user profile CRUD.
```

When modifying a roadmap with compacted phases:
- **Never expand** compacted phases back to full detail
- **Overview paragraph** should focus on remaining work, not rehash completed phases. Use a count (e.g., "Phases 1-8 complete") rather than describing each completed phase's dependencies or deliverables.
- New phases added after compacted ones reference them by number only in `Depends on` -- no need to repeat what they built.

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
