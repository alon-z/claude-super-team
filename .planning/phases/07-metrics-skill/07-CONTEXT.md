# Context for Phase 7: Efficiency Regression Detection

## Phase Boundary (from ROADMAP.md)

**Goal:** Create a `/metrics` skill that reads telemetry data, compares against configurable absolute thresholds, and reports resource usage and violations

**Success Criteria:**
1. A `/metrics` skill exists that reads `.planning/.telemetry/` data and generates per-phase and per-skill resource summaries
2. Absolute thresholds are configurable via `.planning/.telemetry/config.json`
3. The skill flags threshold violations and presents them alongside the summary report

**What's in scope for this phase:**
- Creating the `/metrics` skill (SKILL.md, assets, references as needed)
- Reading and aggregating telemetry data from `.planning/.telemetry/`
- Threshold configuration via `.planning/.telemetry/config.json`
- Per-phase and per-skill resource summary reporting
- Threshold violation detection and flagging

**What's explicitly out of scope:**
- Telemetry capture (Phase 6)
- Statistical/percentage-based regression detection (brainstorm chose absolute thresholds only)
- Cross-project comparison (rejected in brainstorm)
- Automated remediation based on violations
- Real-time budget guardrails during execution

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/progress/SKILL.md`: Closest existing skill in purpose -- reads .planning/ files and generates a status report. /metrics follows a similar pattern.
- `plugins/claude-super-team/scripts/telemetry.sh`: Will be created by Phase 6 -- the data source for this skill
- `.planning/.telemetry/`: Data directory created by Phase 6's hooks

**Established patterns:**
- Skills use Bash guards at start to validate required files exist
- Skills use AskUserQuestion for user interaction
- Skills output structured reports with clear sections
- Skills declare allowed-tools in YAML frontmatter
- Reporting skills (like /progress) read multiple .planning/ files and synthesize

**Integration points:**
- `.planning/.telemetry/` directory: reads telemetry event data (format determined by Phase 6)
- `.planning/.telemetry/config.json`: reads threshold configuration
- Plugin registration: must be added to `plugins/claude-super-team/.claude-plugin/plugin.json`
- Marketplace: must be registered in `.claude-plugin/marketplace.json`
- `/cst-help`: must be updated with /metrics documentation

**Constraints from existing code:**
- No runtime dependencies -- telemetry data must be parseable with shell commands or Claude's built-in tools (Read, Grep)
- Skill frontmatter must declare appropriate allowed-tools
- Storage format from Phase 6 dictates how /metrics reads the data

---

## Cross-Phase Dependencies

**From Phase 6 (Hook-Based Telemetry Capture)** [planned]:
- `telemetry.sh`: Creates the data that /metrics reads
- `.planning/.telemetry/`: Directory structure and data format
- Event schema: Field names and types that /metrics must parse

**From Phase 1 (Claude Code Capability Mapping)** [executed]:
- CAPABILITY-REFERENCE.md: Skill frontmatter options for configuring the new skill

**From Phase 3 (Apply Audit Recommendations)** [executed]:
- Frontmatter conventions: Established patterns for allowed-tools, model selection, context behavior

**Assumptions about prior phases:**
- Phase 6 has completed and telemetry data exists in `.planning/.telemetry/`
- The data format is documented and stable
- At least one project run with telemetry hooks active has produced data to analyze

---

## Implementation Decisions

### Manual Trigger Only

**Decision:** /metrics is invoked manually by the user, not triggered automatically

**Rationale:** Avoids adding overhead to the normal workflow. The user runs it when they want insight, not on every phase completion.

**Constraints:** Must be self-contained -- reads data and produces output in a single invocation.

### Absolute Thresholds

**Decision:** Use absolute threshold values (e.g., max 100 agent turns per phase), not percentage-based deviation from averages

**Rationale:** Simpler, more predictable, works with limited historical data. No statistical complexity needed for a personal tool.

**Constraints:** Thresholds need sensible defaults. Users must be able to tune them via config.json.

### Dedicated Config File

**Decision:** Thresholds stored in `.planning/.telemetry/config.json`, not in STATE.md

**Rationale:** Keeps telemetry configuration separate from project state. Config is specific to the telemetry system.

**Constraints:** Must handle missing config.json gracefully (use defaults).

---

## Claude's Discretion

- Report format and layout (table vs sections vs mixed)
- Default threshold values (what counts as "too many" agent turns, "too long" duration)
- Whether to write a METRICS.md file or only display in terminal
- Skill model selection (likely sonnet -- this is a reader/reporter, not a planner)
- Whether to include trend data (e.g., "this phase used more tokens than the previous one") alongside absolute threshold checks

This CONTEXT.md was auto-generated from a brainstorm session. Run /discuss-phase for deeper exploration of gray areas.

---

## Specific Ideas

- Config structure: `{"max_agent_turns_per_phase": 100, "max_duration_minutes": 30, "max_tool_calls_per_skill": 500}`
- Report sections: per-phase summary table, per-skill breakdown, threshold violations (highlighted), total resource usage
- Skill should work even with partial data (some phases may not have telemetry if hooks were added mid-project)

---

## Deferred Ideas

- Statistical regression detection (percentage-based deviation from running averages) -- revisit if absolute thresholds prove insufficient
- A/B configuration profiles for comparing execution approaches -- useful once multiple runs exist
- Budget guardrails (real-time warnings during execution) -- extension of telemetry infrastructure

---

## Examples

Not available from brainstorm session.
