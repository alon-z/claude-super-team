# Brainstorming Session: Monitoring Efficiency of the Claude Super Team Flow

**Date:** 2026-02-17
**Context:** The claude-super-team plugin has 14 skills forming a sequential planning pipeline. The project is through Phase 3 with Phases 4-5 remaining. The user wants to monitor workflow efficiency -- primarily resource usage (tokens, timing, agent spawns, tool usage, outcomes) -- to optimize skills, track trends over time, and compare approaches. Key constraint: monitoring must be deterministic, zero-token-cost, and add no friction.

---

## Ideas Explored

### Idea 1: Hook-Based Telemetry Capture

**Description:**
A shared shell script (`plugins/claude-super-team/scripts/telemetry.sh`) called by hooks declared in each orchestrator skill's YAML frontmatter. Captures timing, agent spawns, tool usage, outcomes, and token usage at key lifecycle points (skill start, tool calls, skill end). Data writes to `.planning/.telemetry/`. Coverage limited to orchestrator skills only (plan-phase, execute-phase, research-phase, brainstorm).

**Motivation:**
Passive, zero-token-cost monitoring. Hooks run outside the LLM context so they add no friction or expense. Single script as source of truth minimizes maintenance burden. No global hook installation needed -- hooks live in the skills themselves.

**Tradeoffs:**
- **Pros:** Zero token overhead; deterministic; no user friction; self-contained in plugin; single script to maintain
- **Cons:** Depends on what hook events Claude Code actually exposes; maintenance burden when skills change (mitigated by shared script); needs research on whether hooks can access token usage data

**Implementation Notes:**
- One `telemetry.sh` script in `plugins/claude-super-team/scripts/`
- Each orchestrator skill declares hooks in YAML frontmatter that call the script with event type + context
- Data accumulates in `.planning/.telemetry/` (storage format to be researched -- JSONL, SQLite, CSV, etc.)
- Script must be resilient to missing `.planning/` directories (graceful no-ops)
- Research needed: available hook events, token usage accessibility, optimal storage format

**Decision:**
APPROVED

---

### Idea 2: Efficiency Regression Detection (via /metrics)

**Description:**
A `/metrics` skill that reads `.planning/.telemetry/` data and compares it against absolute thresholds defined in `.planning/.telemetry/config.json`. Flags when metrics exceed configurable limits (e.g., >100 agent turns per phase, >N minutes wall-clock time). Triggered manually by the user.

**Motivation:**
Makes resource overruns visible without adding overhead to normal flow. Absolute thresholds are simpler and more predictable than statistical baselines, especially with limited historical data per project. Naturally pairs with hook-based telemetry -- hooks write, /metrics reads.

**Tradeoffs:**
- **Pros:** Simple threshold model; no statistical complexity; actionable output; manual trigger means zero cost unless needed
- **Cons:** Depends on telemetry data existing (Idea 1 must come first); absolute thresholds need initial tuning; limited value until enough data accumulates

**Implementation Notes:**
- New `/metrics` skill in claude-super-team plugin
- Reads all `.planning/.telemetry/` events, rolls up per-phase and per-skill
- Thresholds in `.planning/.telemetry/config.json` (e.g., `{"max_agent_turns_per_phase": 100, "max_duration_minutes": 30}`)
- Reports: per-phase summary table, threshold violations, total resource usage
- Depends on Idea 1 (hook-based telemetry) for data

**Decision:**
APPROVED

---

### Idea 3: Cross-Project Telemetry Store

**Description:**
Store telemetry data in `~/.claude/telemetry/{project-name}/` in addition to `.planning/.telemetry/`, enabling trend comparison across different projects using the same workflow.

**Motivation:**
Would enable long-term trend tracking across projects and skill version changes.

**Tradeoffs:**
- **Pros:** Cross-project visibility; persists beyond project cleanup
- **Cons:** Filesystem conventions for global data; data growth; scope creep

**Implementation Notes:**
Second write path in telemetry.sh to a global location.

**Decision:**
REJECTED -- Keeping telemetry scoped to per-project `.planning/` is simpler and sufficient. Cross-project comparison adds complexity without clear immediate value.

---

### Idea 4: SUMMARY.md Metrics Extension (not deep-dived)

**Description:**
Extend execute-phase SUMMARY.md files with structured metrics (agent turns, files modified, verification pass/fail, timing).

**Decision:**
Not explored -- superseded by hook-based telemetry which captures data more comprehensively and without modifying existing artifact formats.

---

### Idea 5: /metrics Reporting Skill (merged into Idea 2)

**Description:**
Originally proposed as a standalone reporting skill. Merged with regression detection into a single /metrics skill concept.

**Decision:**
Merged into Idea 2.

---

### Idea 6: Per-Skill Timing Instrumentation (not deep-dived)

**Description:**
Add timing and token instrumentation directly to each orchestrator skill's logic.

**Decision:**
Not explored -- superseded by hook-based approach which achieves the same result without touching skill logic.

---

### Idea 7: Budget Guardrails via Hooks (not deep-dived)

**Description:**
Use hooks to enforce soft resource limits with configurable warnings.

**Decision:**
Not explored in depth -- conceptually subsumed by Idea 2's threshold-based regression detection. Could be revisited as a real-time extension.

---

### Idea 8: A/B Configuration Profiles (not deep-dived)

**Description:**
Declare execution profiles in STATE.md for comparing different configurations.

**Decision:**
Not explored -- useful only after telemetry infrastructure exists. Could be revisited post-implementation.

---

## Approved Ideas Summary

| Idea | Priority | Next Step |
|------|----------|-----------|
| Hook-Based Telemetry Capture | High | Research hook events, storage format; add as roadmap phase |
| Efficiency Regression Detection (/metrics) | Medium | Implement after telemetry infrastructure; add as roadmap phase |

---

## Deferred Ideas

- None

---

## Rejected Ideas

- **Cross-Project Telemetry Store:** Per-project scoping is simpler and sufficient. No clear immediate value from cross-project aggregation.

---

## Next Actions

1. Research Claude Code hook events available for skill frontmatter (what can be captured)
2. Research optimal storage format for telemetry data (JSONL vs SQLite vs CSV)
3. Add telemetry infrastructure as a roadmap phase (hook-based capture + /metrics skill)

---

_Last updated: 2026-02-17_
