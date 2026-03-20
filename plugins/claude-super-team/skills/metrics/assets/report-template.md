# Telemetry Metrics Report

**Sessions:** {total_sessions} | **Tool calls:** {total_tools} | **Agents:** {total_agents} | **Failures:** {total_failures} ({failure_rate}%)

## Threshold Violations

{If any violations: table with columns: Metric | Threshold | Actual | Session}
{If no violations: "No threshold violations detected."}

## Per-Session Summary

| Session | Tools | Agents | Failures | Duration | Model |
|---------|-------|--------|----------|----------|-------|
{One row per session, sorted by duration descending}

## Tool Usage

| Tool | Count | % of Total |
|------|-------|------------|
{One row per tool, sorted by count descending}

## Agent Types

| Agent Type | Count |
|------------|-------|
{One row per agent type, sorted by count descending}

## Configuration

Thresholds loaded from: {config.json path or "defaults"}
{Table of threshold key-value pairs}

To customize thresholds, create or edit:
  .planning/.telemetry/config.json
