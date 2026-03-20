---
name: metrics
description: "Analyze telemetry data to report resource usage per session, tool/agent breakdowns, and threshold violations. Reads .planning/.telemetry/ session files and config.json thresholds."
allowed-tools: Read, Glob, Bash(bash *gather-data.sh)
model: haiku
context: fork
---

## Step 0: Gather Telemetry Data

Run the gather script to collect all telemetry data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/metrics/gather-data.sh"
```

Parse all output sections:
- **PROJECT** and **STATE**: Project context (informational only)
- **TELEMETRY_FILES**: List of session JSONL files found
- **THRESHOLDS**: Configured or default threshold values
- **SESSION_METRICS**: Per-session summary lines in pipe-delimited format: `{file}|tools={N}|agents={N}|failures={N}|duration_sec={N}|model={name}`
- **TOOL_BREAKDOWN**: Tool usage counts as `{tool_name}={count}` lines sorted by count descending
- **AGENT_BREAKDOWN**: Agent type counts as `{agent_type}={count}` lines sorted by count descending
- **TOTALS**: Aggregate counts as key=value lines (sessions, total_tools, total_agents, total_failures, total_duration_sec)

## Step 1: Validate Environment

If the TELEMETRY_FILES section shows `(none)`, display this message and exit:

```
No telemetry data found. Telemetry is captured automatically when using skills from the claude-super-team plugin. Run some skills first, then try /metrics again.
```

## Step 2: Parse Session Metrics

For each line in the SESSION_METRICS section, extract the pipe-delimited fields. For each session compute:

- **Duration display**: Convert `duration_sec` to human-readable format (e.g., `12m 30s`, or `1h 5m` for longer durations, or `0s` for zero)
- **Session name**: Extract the filename from the path (e.g., `session-abc123.jsonl` from `.planning/.telemetry/session-abc123.jsonl`)
- **Failure rate**: `failures / (tools + failures) * 100`, rounded to 1 decimal. If tools + failures = 0, failure rate is 0%.

## Step 3: Threshold Violation Detection

Read the THRESHOLDS section values. For each session, check:

1. **max_tool_calls_per_session**: Flag if the session's `tools` count exceeds this threshold
2. **max_agent_spawns_per_session**: Flag if the session's `agents` count exceeds this threshold
3. **max_session_duration_minutes**: Flag if `duration_sec / 60` exceeds this threshold
4. **max_failure_rate_percent**: Flag if the session's computed failure rate exceeds this threshold

Collect all violations into a list with: metric name, threshold value, actual value, and session name.

## Step 4: Generate Report

Read the report template for structure reference:

```
${CLAUDE_SKILL_DIR}/assets/report-template.md
```

Build the report following the template structure:

**Header**: Fill in total_sessions, total_tools, total_agents, total_failures from the TOTALS section. Compute overall failure rate as `total_failures / (total_tools + total_failures) * 100`.

**Threshold Violations**: If violations were found in Step 3, render a table:

| Metric | Threshold | Actual | Session |
|--------|-----------|--------|---------|

If no violations, display: "No threshold violations detected."

**Per-Session Summary**: Render a table with one row per session, sorted by duration descending:

| Session | Tools | Agents | Failures | Duration | Model |
|---------|-------|--------|----------|----------|-------|

Only include sessions that have at least 1 tool call or agent spawn (skip empty/trivial sessions with all zeros).

**Tool Usage**: Render a table from TOOL_BREAKDOWN data. Calculate percentage as `count / total_tools * 100`, rounded to 1 decimal:

| Tool | Count | % of Total |
|------|-------|------------|

**Agent Types**: Render a table from AGENT_BREAKDOWN data:

| Agent Type | Count |
|------------|-------|

**Configuration**: Show which thresholds are active and their source (config.json path or "defaults"). List each threshold key-value pair.

## Step 5: Display Report

Present the complete report directly in the conversation output. Do NOT write the report to a file.
