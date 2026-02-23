# Context File Generation for New Roadmap Phases

### Phase 11.5: Generate Context Files for New Phases

**Skip this phase entirely if:**
- Phase 11 was skipped (no approved ideas)
- User chose "Manual later" in Phase 11
- `/create-roadmap` was not invoked or failed

**This phase only runs when Phase 11 resulted in new phases being added to the roadmap** (user chose "Add to roadmap" and `/create-roadmap` completed successfully).

#### 11.5.1: Detect New Phase Directories

Read the updated `.planning/ROADMAP.md` to identify which new phases were added by `/create-roadmap`. For each approved brainstorm idea that became a roadmap phase, note:
- The phase number (zero-padded, e.g., `05`)
- The phase directory slug (e.g., `05-feature-name`)
- The goal and success criteria from the ROADMAP.md entry

Verify each phase directory exists under `.planning/phases/`.

#### 11.5.2: Read Context Template

Read the discuss-phase context template at runtime:

```bash
cat plugins/claude-super-team/skills/discuss-phase/assets/context-template.md
```

Use this template as the structural reference for every CONTEXT.md file generated below. Do NOT hardcode the template structure -- always read it fresh so downstream template changes are picked up automatically.

#### 11.5.3: Write CONTEXT.md for Each New Phase

For each newly created phase directory, write a `{NN}-CONTEXT.md` file (e.g., `05-CONTEXT.md`) mapping brainstorm session data into the template sections:

**Phase Boundary:**
- **Goal:** From the ROADMAP.md entry for this phase.
- **Success Criteria:** From the ROADMAP.md entry for this phase.
- **In scope:** Derived from the brainstorm scope discussion -- for interactive mode, use Phase 4 step 4.3 question 1 answers ("What should this include vs exclude?"). For autonomous mode, derive from the idea description and implementation notes.
- **Out of scope:** Inverse of in-scope from the same source. If no explicit exclusions were discussed, note: "Not explicitly discussed during brainstorm session -- refine via /discuss-phase."

**Codebase Context:**
- If `.planning/codebase/` exists: Summarize relevant findings from the brainstorm's loaded context (ARCHITECTURE.md, STACK.md, CONVENTIONS.md) that pertain to this specific idea.
  - **Existing related code:** Files/modules relevant to the idea, from codebase exploration.
  - **Established patterns:** Patterns from CONVENTIONS.md that apply.
  - **Integration points:** From Phase 4 step 4.3 question 3 (interactive) or from architecture analysis (autonomous).
  - **Constraints from existing code:** Any constraints surfaced during brainstorm discussion.
- If `.planning/codebase/` does NOT exist: Fill entire section with: "Not available from brainstorm session -- run /map-codebase and /discuss-phase to populate."

**Cross-Phase Dependencies:**
- Derive from the ROADMAP.md `depends_on` field if present for this phase.
- If no dependency information is available: "Not available from brainstorm session."

**Implementation Decisions:**
- Map each brainstorm discussion answer as a decision entry using the Decision / Rationale / Constraints format:
  - **Interactive mode:** Map answers from Phase 4 step 4.3 questions:
    - Scope answer (question 1) --> Decision about scope boundaries
    - Tradeoffs answer (question 2) --> Decision about tradeoff resolution
    - Integration answer (question 3) --> Decision about integration approach
    - Risk answer (question 4) --> Decision about risk mitigation
  - **Autonomous mode:** Map the idea's implementation notes and tradeoffs as decisions. Each distinct tradeoff or implementation note becomes a separate decision entry.
- If no discussion data exists for a question, omit that decision entry (do not create empty ones).

**Claude's Discretion:**
- Areas where the user chose "You decide" during brainstorm discussion (Phase 4 step 4.3).
- Areas not covered by the brainstorm session.
- Always include this note at the end of the section: "This CONTEXT.md was auto-generated from a brainstorm session. Run /discuss-phase for deeper exploration of gray areas."

**Specific Ideas:**
- The idea's implementation notes from the brainstorm discussion.
- For autonomous mode: specific recommendations from the synthesis (Phase 8).

**Deferred Ideas:**
- Any related ideas from the brainstorm session that were deferred and pertain to this phase's domain.
- If none: "No deferred ideas related to this phase from the brainstorm session."

**Examples:**
- "Not available from brainstorm session."

Do NOT omit any template section. Every section must appear in the generated CONTEXT.md, even if filled with a "Not available" note.

#### 11.5.4: Report Created Files

After writing all CONTEXT.md files, print a summary list:

```
Context files created for new roadmap phases:
- .planning/phases/{NN}-{slug}/{NN}-CONTEXT.md
- .planning/phases/{NN}-{slug}/{NN}-CONTEXT.md
...
```

Store this list so Phase 12 can include it in the final summary.
