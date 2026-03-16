# Context for Phase 10: Skill Capability Enhancements

## Phase Boundary (from ROADMAP.md)

**Goal:** Enhance /cst-help with artifact explanation and /build with dynamic completion awareness

**Success Criteria:**
1. /cst-help handles "explain [path]" queries by reading the target `.planning/` artifact plus surrounding context (CONTEXT.md, RESEARCH.md, ROADMAP.md) and producing a concise narrative explaining its purpose, constraints, and connections
2. /build includes a completion audit step after the main pipeline that checks for gaps (failed verifications, incomplete phases, new requirements surfaced during execution) and continues working autonomously or reports findings

**What's in scope for this phase:**
- Adding an "explain" routing case to /cst-help that reads and synthesizes .planning/ artifacts
- Adding a completion audit step to /build that detects remaining work after the main pipeline
- /build's audit step should check for: failed verifications, incomplete phases, new requirements

**What's explicitly out of scope:**
- Changing /cst-help's existing help, troubleshooting, or skill reference functionality
- Changing /build's core pipeline flow (discuss -> research -> plan -> execute)
- Creating new skills -- both changes modify existing skills
- Adding new frontmatter fields or hook declarations

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/cst-help/SKILL.md`: Current help skill with routing for questions, troubleshooting, and "what's next" queries
- `plugins/claude-super-team/skills/cst-help/references/workflow-guide.md`: Workflow reference embedded in cst-help responses
- `plugins/claude-super-team/skills/cst-help/references/troubleshooting.md`: Troubleshooting guide with "When to Use Each Skill" section
- `plugins/claude-super-team/skills/build/SKILL.md`: Current /build skill (498 lines) with 13-step process
- `plugins/claude-super-team/skills/build/references/sprint-execution-guide.md`: Steps 8-E/9 for sprint execution
- `plugins/claude-super-team/skills/build/references/finalization-guide.md`: Steps 10-13 for finalization and reporting

**Established patterns:**
- /cst-help routes queries based on intent detection (question type -> appropriate response section)
- /build uses reference documents for complex steps (sprint-execution-guide.md, finalization-guide.md)
- /build tracks state in BUILD-STATE.md with compaction-resilient hooks

**Integration points:**
- /cst-help's routing logic: Must add "explain" intent detection alongside existing "question", "troubleshoot", "what's next" intents
- /build's finalization step: The completion audit should run after Step 12 (finalization) but before Step 13 (final report)
- /build's BUILD-STATE.md: Audit results should be recorded for compaction resilience

**Constraints from existing code:**
- /cst-help uses `model: haiku` -- artifact explanation may need more reasoning power, consider whether haiku is sufficient for synthesis or if this specific routing case should use a higher model
- /build at 498 lines is already the longest SKILL.md -- the audit step should be in a reference document, not inline

---

## Cross-Phase Dependencies

No direct dependencies on other new phases. Both skills are standalone modifications.

**Assumptions about prior phases:**
- /cst-help and /build are stable and functional (Phase 3 applied audit recommendations, Phase 4 hardened build)
- The `.planning/` artifact structure (CONTEXT.md, RESEARCH.md, SUMMARY.md, PLAN.md, VERIFICATION.md) is stable

---

## Implementation Decisions

### /cst-help Explain Scope

**Decision:** Explain capability reads the target file plus its phase's CONTEXT.md, RESEARCH.md, and ROADMAP.md phase detail section to reconstruct reasoning

**Rationale:** The reasoning chain for any artifact lives across these specific files. CONTEXT.md has the decisions, RESEARCH.md has the constraints, ROADMAP.md has the goal. Together they explain "why."

**Constraints:** Keep explanations concise (5-10 sentences). This is a quick clarification tool, not a deep analysis.

### /build Completion Audit

**Decision:** After main pipeline, add an audit step that checks for gaps and either continues working or reports findings

**Rationale:** User feedback: /build should be dynamic and know when there is more to do, rather than stopping at a fixed pipeline endpoint. This makes /build the single entry point for autonomous work.

**Constraints:** Must have bounded retry/continuation to prevent infinite loops. Clear termination criteria needed.

---

## Claude's Discretion

- Whether /cst-help's explain feature needs a model override for the synthesis step (haiku may be insufficient)
- The specific gap categories the /build audit should check for
- Whether the audit step belongs in finalization-guide.md or a new reference document
- How many retry/continuation cycles /build should attempt before stopping

This CONTEXT.md was auto-generated from a brainstorm session. Run /discuss-phase for deeper exploration of gray areas.

---

## Specific Ideas

- /cst-help explain: detect "explain" keyword + a file path in the arguments, then Read the file and its phase context, synthesize a narrative
- /build audit: after finalization, scan for VERIFICATION.md files with failures, ROADMAP.md phases still unchecked, SUMMARY.md files mentioning unresolved issues
- /build audit could re-invoke /phase-feedback autonomously for each detected gap (bounded to 2 cycles)

---

## Deferred Ideas

- Warmup skill (narrative reconstruction for returning to projects) -- rejected in brainstorm but the "explain" capability in /cst-help addresses a subset of the same need
- Error recovery (try-catch for Task failures) -- rejected but could complement the /build audit step in a future phase

---

## Examples

Not available from brainstorm session.
