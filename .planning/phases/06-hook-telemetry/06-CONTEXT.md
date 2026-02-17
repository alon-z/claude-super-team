# Context for Phase 6: Hook-Based Telemetry Capture

## Phase Boundary (from ROADMAP.md)

**Goal:** Add passive, zero-token-cost telemetry to orchestrator skills via a shared shell script called by skill-scoped hooks

**Success Criteria:**
1. A `telemetry.sh` script exists in `plugins/claude-super-team/scripts/` that captures timing, agent spawns, tool usage, outcomes, and token usage
2. Orchestrator skills (plan-phase, execute-phase, research-phase, brainstorm) declare hooks in YAML frontmatter that call `telemetry.sh` at skill start/end and key lifecycle points
3. Telemetry data accumulates in `.planning/.telemetry/` in a format validated by research (JSONL, SQLite, or CSV)
4. Hook script gracefully no-ops when `.planning/` or `.planning/.telemetry/` directories don't exist

**What's in scope for this phase:**
- Creating `telemetry.sh` shared script for event capture
- Adding hook declarations to orchestrator skill YAML frontmatter (plan-phase, execute-phase, research-phase, brainstorm)
- Defining the telemetry data format (requires research on available hook events and optimal storage)
- Capturing: timing, agent spawns, tool usage, outcomes, token usage
- Writing to `.planning/.telemetry/` directory

**What's explicitly out of scope:**
- Reporting or visualization of telemetry data (Phase 7)
- Threshold-based regression detection (Phase 7)
- Cross-project telemetry aggregation (rejected in brainstorm)
- Telemetry for non-orchestrator skills (discuss-phase, progress, etc.)

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/execute-phase/SKILL.md`: Primary orchestrator skill, already has hook support (PreCompact, SessionStart) from Phase 1.4 compaction resilience work
- `plugins/claude-super-team/skills/plan-phase/SKILL.md`: Planner orchestrator, spawns agents via Task tool
- `plugins/claude-super-team/skills/research-phase/SKILL.md`: Research orchestrator, spawns phase-researcher agent
- `plugins/claude-super-team/skills/brainstorm/SKILL.md`: Brainstorm orchestrator, spawns analysis agents in autonomous mode
- `.planning/phases/01-capability-mapping/`: Phase 1 produced a CAPABILITY-REFERENCE.md documenting hooks and frontmatter options

**Established patterns:**
- YAML frontmatter in SKILL.md for declaring hooks, allowed-tools, model, context behavior
- Shell scripts called from hooks (pattern established by execute-phase compaction hooks)
- `.planning/` as the root for all generated artifacts
- Skills are Markdown-driven with no compiled code

**Integration points:**
- Skill YAML frontmatter: hooks declared here call `telemetry.sh`
- `.planning/.telemetry/` directory: new artifact location for telemetry data
- Task tool calls: each agent spawn is an event to capture

**Constraints from existing code:**
- Hooks run shell commands -- `telemetry.sh` must be a valid shell script
- No package dependencies allowed (no runtime code constraint)
- Hook events limited to what Claude Code exposes (needs research)
- Context windows: hooks run outside the LLM context, so they cannot access token counts directly unless the hook event provides them

---

## Cross-Phase Dependencies

**From Phase 1 (Claude Code Capability Mapping)** [executed]:
- CAPABILITY-REFERENCE.md: Documents available hook events, frontmatter fields, and context behavior options

**From Phase 1.4 (Compaction Resilience)** [executed]:
- execute-phase hooks: Established the pattern of shell-script hooks in skill frontmatter (PreCompact, SessionStart)

**From Phase 3 (Apply Audit Recommendations)** [executed]:
- All skill frontmatter updated: Each skill now has correct allowed-tools and model selection

**From Phase 5 (Workflow Validation)** [planned]:
- Validated workflow: Telemetry should instrument a stable, validated workflow

**Assumptions about prior phases:**
- Phase 5 has completed, confirming the workflow is stable enough to instrument
- Hook event types are documented in the Phase 1 capability reference

---

## Implementation Decisions

### Telemetry Must Be Zero-Token-Cost

**Decision:** Use shell-script hooks exclusively -- no LLM calls for telemetry capture

**Rationale:** The user explicitly required that monitoring add no friction or token cost. Hooks run outside the LLM context and are deterministic.

**Constraints:** All capture logic must be implementable in shell scripting. No AI-assisted analysis at capture time.

### Single Shared Script Architecture

**Decision:** One `telemetry.sh` script called by all orchestrator skills, rather than per-skill scripts

**Rationale:** Minimizes maintenance burden (user's primary concern). Changes propagate without touching each skill.

**Constraints:** Script must handle different event types via arguments. Must be resilient to missing directories.

### Orchestrators Only

**Decision:** Only instrument plan-phase, execute-phase, research-phase, and brainstorm

**Rationale:** These are the expensive, agent-spawning skills. Lightweight skills (progress, discuss-phase) add noise without value.

**Constraints:** If future skills become orchestrators, they'll need hook declarations added manually.

### Storage Format Requires Research

**Decision:** Storage format (JSONL, SQLite, CSV) to be determined during research phase

**Rationale:** The optimal format depends on what hook events actually provide and how /metrics will consume the data. Premature commitment could force awkward parsing later.

**Constraints:** Must be appendable (not rewrite-on-every-event). Must be readable without dependencies (no SQLite if it requires installing tooling).

---

## Claude's Discretion

- Specific hook event types to use (depends on what Claude Code exposes)
- Exact telemetry event schema (field names, data types)
- Error handling strategy for the shell script (silent failure vs stderr logging)
- Directory creation approach (auto-create `.planning/.telemetry/` or require manual setup)

This CONTEXT.md was auto-generated from a brainstorm session. Run /discuss-phase for deeper exploration of gray areas.

---

## Specific Ideas

- Shell script location: `plugins/claude-super-team/scripts/telemetry.sh`
- Data location: `.planning/.telemetry/`
- Metrics to capture: timing (start/end timestamps), agent spawns (count, type, model), tool usage (counts by type), outcomes (verification pass/fail), token usage (if accessible via hooks)
- Script should accept event type as first argument (e.g., `telemetry.sh skill_start plan-phase`, `telemetry.sh agent_spawn opus`)

---

## Deferred Ideas

- Budget guardrails (real-time warnings when thresholds exceeded during execution) -- could be revisited as an extension to telemetry.sh
- A/B configuration profiles for comparing different execution models -- useful only after telemetry data exists

---

## Examples

Not available from brainstorm session.
