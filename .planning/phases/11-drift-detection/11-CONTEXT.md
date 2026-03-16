# Context for Phase 11: Drift Detection

## Phase Boundary (from ROADMAP.md)

**Goal:** Create a /drift skill that compares actual codebase state against planning artifacts to surface divergence

**Success Criteria:**
1. A `/drift` skill exists that reads SUMMARY.md files, CONTEXT.md decisions, RESEARCH.md recommendations, and PLAN.md task specifications
2. The skill uses an Explore agent to inspect the actual codebase and compare against what planning artifacts describe
3. The skill produces a structured report categorizing findings as: confirmed drift (clear divergence), potential drift (unclear), or aligned (matches plan)

**What's in scope for this phase:**
- New `/drift` skill in claude-super-team plugin
- Reading planning artifacts to extract "what should exist" claims
- Using an Explore agent to verify claims against actual codebase
- Structured drift report with categorized findings
- SKILL.md with appropriate frontmatter (allowed-tools, model, context)

**What's explicitly out of scope:**
- Automatic correction of drift (this skill detects, not fixes)
- Integration into /progress or other skills (standalone first)
- Bidirectional plan-code sync (deferred from brainstorm)
- Historical drift tracking or trend analysis
- Hook-based automatic drift detection on code changes

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/progress/SKILL.md`: Already does some state validation (sync checks between ROADMAP.md and phase directories). Drift detection goes deeper -- comparing artifact claims against actual code.
- `plugins/claude-super-team/agents/phase-researcher.md`: Example of an agent definition with Explore-style capabilities. Drift detection will use a similar exploration pattern.
- `plugins/claude-super-team/skills/execute-phase/SKILL.md`: Produces SUMMARY.md files that describe what was built -- the primary source of "what should exist" claims.
- `plugins/claude-super-team/scripts/gather-common.sh` (planned Phase 9): Would provide shared context loading for the drift skill.

**Established patterns:**
- SUMMARY.md files describe what was built in each plan (files created/modified, patterns implemented, tests added)
- CONTEXT.md files contain implementation decisions (technology choices, architectural approaches)
- PLAN.md files contain task specifications with `<files>` tags listing expected file targets
- VERIFICATION.md files contain pass/fail status of phase verification

**Integration points:**
- Reading .planning/phases/*/: All SUMMARY.md, CONTEXT.md, RESEARCH.md, PLAN.md, VERIFICATION.md files
- Codebase exploration: Using Explore agent subagent_type to inspect actual code
- Report output: Writing a DRIFT-REPORT.md or similar artifact

**Constraints from existing code:**
- SUMMARY.md format varies by plan -- some describe files created, others describe patterns implemented. The drift skill must handle both.
- The Explore agent needs sufficient context about what to look for, embedded inline (no @ references across Task boundaries)
- Planning artifacts may reference files that were later renamed or moved -- this is drift, not an error

---

## Cross-Phase Dependencies

**From Phase 9 (Script Consolidation)** [planned]:
- `gather-common.sh`: Would provide shared context loading functions for the drift skill's gather-data.sh
- `create_phase_dir()`: Not directly needed but establishes consistent phase directory conventions

**Assumptions about prior phases:**
- Planning artifacts (SUMMARY.md, CONTEXT.md, etc.) exist for at least some completed phases to compare against
- The project has a codebase to inspect (not just planning files)

---

## Implementation Decisions

### Drift Detection Methodology

**Decision:** Extract claims from planning artifacts, then verify each claim against actual codebase state using an Explore agent

**Rationale:** Planning artifacts contain implicit and explicit claims about what should exist in the codebase. By extracting and systematically verifying these claims, we can surface drift without relying on git history or manual comparison.

**Constraints:** Claims must be concrete enough to verify (e.g., "file X exists" or "pattern Y is used in module Z"). Vague claims ("good error handling") should be flagged as unverifiable.

### Report Categorization

**Decision:** Three categories: confirmed drift (clear divergence), potential drift (unclear), aligned (matches plan)

**Rationale:** Binary pass/fail is too rigid for code-to-plan comparison. Some drift is intentional (improvements beyond the plan), some is concerning (missing deliverables), and some is ambiguous. Three categories let the user prioritize.

**Constraints:** Each finding must include the specific artifact claim, the actual codebase state, and why it was categorized as it was.

---

## Claude's Discretion

- Exact claim extraction methodology (regex on SUMMARY.md? LLM parsing? Structured extraction?)
- How to handle phases with no SUMMARY.md (not yet executed) -- skip or flag as "unverifiable"
- Report format: standalone DRIFT-REPORT.md in `.planning/` or printed inline
- Whether to use a single Explore agent or multiple agents (one per phase, one per claim category)
- How deep to explore: surface-level (file existence) vs deep (code content, patterns, architecture)

This CONTEXT.md was auto-generated from a brainstorm session. Run /discuss-phase for deeper exploration of gray areas.

---

## Specific Ideas

- Extract "what was built" claims from SUMMARY.md: file paths, patterns, dependencies, test coverage
- Extract "what was decided" claims from CONTEXT.md: technology choices, architectural patterns, integration approaches
- Extract "what was planned" claims from PLAN.md `<files>` tags: expected file targets and modifications
- Use Explore agent with "very thorough" mode to verify claims against actual codebase
- Consider integrating drift findings into /progress as an optional section (post-MVP)

---

## Deferred Ideas

- Bidirectional plan-code sync ("Mirror") -- deferred from brainstorm. Depends on drift detection being built first as the foundation.
- Automatic drift correction -- detect first, fix later. Could be addressed via /phase-feedback if drift is found.
- Historical drift tracking -- trend analysis over time, requires multiple drift reports.

---

## Examples

Not available from brainstorm session.
