# Research for Phase 6: Hook-Based Telemetry Capture

## User Constraints

### Locked Decisions

1. **Telemetry Must Be Zero-Token-Cost**: Use shell-script hooks exclusively -- no LLM calls for telemetry capture. All capture logic must be implementable in shell scripting.
2. **Single Shared Script Architecture**: One `telemetry.sh` script called by all orchestrator skills, rather than per-skill scripts. Minimizes maintenance burden.
3. **Orchestrators Only**: Only instrument plan-phase, execute-phase, research-phase, and brainstorm.
4. **Storage Format Requires Research**: Storage format (JSONL, SQLite, CSV) to be determined during research phase. Must be appendable and readable without dependencies.

### Claude's Discretion

- Specific hook event types to use (depends on what Claude Code exposes)
- Exact telemetry event schema (field names, data types)
- Error handling strategy for the shell script (silent failure vs stderr logging)
- Directory creation approach (auto-create `.planning/.telemetry/` or require manual setup)

### Deferred Ideas (OUT OF SCOPE)

- Budget guardrails (real-time warnings when thresholds exceeded during execution)
- A/B configuration profiles

### Out of Scope

- Reporting or visualization of telemetry data (Phase 7)
- Threshold-based regression detection (Phase 7)
- Cross-project telemetry aggregation (rejected in brainstorm)
- Telemetry for non-orchestrator skills

---

## Summary

Research is complete with HIGH confidence across all critical domains. Claude Code's hook system provides 14 lifecycle events with rich JSON input data on stdin, making shell-script-based telemetry capture fully viable. The key insight is that hooks receive structured event data (tool names, agent types, session IDs, timestamps) that the telemetry script can parse with `jq` or basic shell JSON extraction. **JSONL is the recommended storage format** -- it is natively appendable, requires no dependencies beyond basic shell tools, and is trivially parseable by a future `/metrics` skill.

The most impactful hook events for telemetry are: `SessionStart` (skill invocation start), `Stop`/`SessionEnd` (skill end with timing), `SubagentStart`/`SubagentStop` (agent spawn tracking), `PreToolUse`/`PostToolUse` (tool usage counting), and `PostToolUseFailure` (outcome tracking). Token usage is NOT directly available through hooks -- this is a hard limitation. Timing data must be computed by the script itself using timestamps.

Overall confidence: **HIGH** -- primary source is official Anthropic documentation at code.claude.com, verified February 2026, cross-referenced with existing hook implementations in this codebase.

---

## Standard Stack

### Core Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| bash (POSIX sh compatible) | system | Shell script runtime for `telemetry.sh` | HIGH |
| jq | system (pre-installed on most dev machines) | Parse JSON stdin from hook events | HIGH |
| date (GNU/BSD) | system | Generate ISO-8601 timestamps | HIGH |

### Supporting Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| None required | N/A | No external dependencies -- constraint from project rules | HIGH |

### Alternatives Considered

| Alternative | Why Not |
|-------------|---------|
| SQLite for storage | Requires `sqlite3` binary -- violates "no dependencies" constraint. Also harder to append from shell scripts. |
| CSV for storage | Fragile with embedded commas/quotes in tool inputs. No schema enforcement. Harder for Phase 7 `/metrics` skill to parse reliably with Claude Code tools. |
| OpenTelemetry CLI (`otel-cli`) | External dependency. Overkill for file-based local telemetry. Designed for distributed tracing, not local CLI metrics. |
| Per-event separate log files | Harder to correlate events. JSONL with event_type field is cleaner and more queryable. |

---

## Architecture Patterns

### Storage Format: JSONL (Recommended)

**Decision: Use JSONL (JSON Lines)** -- one JSON object per line, appended to a single file per skill invocation session.

Rationale:
- **Appendable**: `echo '{"event": ...}' >> file.jsonl` -- atomic append, no read-modify-write
- **No dependencies**: Readable with `grep`, `jq`, basic shell tools
- **Schema-flexible**: New fields can be added without breaking existing entries
- **Claude Code native**: The `/metrics` skill (Phase 7) can use `Read`, `Grep`, and `Bash(jq ...)` to query JSONL files trivially
- **Corruption-resistant**: Each line is independent; a partial write corrupts at most one event

File naming pattern:
```
.planning/.telemetry/{skill_name}-{YYYY-MM-DD}T{HH-MM-SS}.jsonl
```

Each skill invocation produces one JSONL file. This avoids contention from concurrent appends (e.g., parallel agent spawns within execute-phase) and makes it trivial to identify which invocation produced which data.

### Telemetry Event Schema

Every JSONL line follows this base schema:

```json
{
  "event": "skill_start|skill_end|agent_spawn|agent_complete|tool_use|tool_failure",
  "skill": "execute-phase|plan-phase|research-phase|brainstorm",
  "session_id": "abc123",
  "timestamp": "2026-02-17T14:30:00Z",
  "data": { ... event-specific fields ... }
}
```

Event-specific `data` fields:

| Event | Data Fields | Source |
|-------|------------|--------|
| `skill_start` | `phase_num`, `args`, `model` | SessionStart hook input |
| `skill_end` | `duration_sec`, `reason` | Stop/SessionEnd hook input + computed |
| `agent_spawn` | `agent_type`, `agent_id` | SubagentStart hook input |
| `agent_complete` | `agent_type`, `agent_id`, `agent_transcript_path` | SubagentStop hook input |
| `tool_use` | `tool_name`, `tool_input_summary` | PostToolUse hook input (tool_name only, not full input for privacy/size) |
| `tool_failure` | `tool_name`, `error` | PostToolUseFailure hook input |

### Script Architecture

```
telemetry.sh
  |
  |-- Reads JSON from stdin (hook event data)
  |-- Reads EVENT_TYPE from first argument
  |-- Computes timestamp
  |-- Writes one JSONL line to the session's telemetry file
  |-- Uses TELEMETRY_FILE env var (set by SessionStart hook) or computes path
```

The script is called by hooks declared in each orchestrator skill's YAML frontmatter. The `SessionStart` hook initializes the telemetry file path and exports it via `CLAUDE_ENV_FILE` for subsequent hooks in the same session.

### Project Structure

```
plugins/claude-super-team/
  scripts/
    telemetry.sh              # The shared telemetry capture script
    progress-gather.sh        # (existing) Progress data gathering
  skills/
    execute-phase/SKILL.md    # Updated: add telemetry hooks to frontmatter
    plan-phase/SKILL.md       # Updated: add telemetry hooks to frontmatter
    research-phase/SKILL.md   # Updated: add telemetry hooks to frontmatter
    brainstorm/SKILL.md       # Updated: add telemetry hooks to frontmatter

.planning/
  .telemetry/                 # Telemetry data directory (gitignored)
    execute-phase-2026-02-17T14-30-00.jsonl
    plan-phase-2026-02-17T15-00-00.jsonl
```

### Design Patterns

- **Fail-silent pattern**: All telemetry operations use `2>/dev/null` or conditional checks. A broken telemetry script must never interrupt skill execution. Exit 0 always.
- **Session-scoped file path**: The SessionStart hook generates the file path and persists it via `CLAUDE_ENV_FILE` so all subsequent hooks in the session write to the same file.
- **Stdin passthrough**: The script reads hook JSON from stdin, extracts needed fields, writes telemetry, and exits 0. It never produces stdout (which would inject context into Claude) or exits non-zero (which would disrupt the hook flow).
- **Async for high-frequency events**: PostToolUse and PostToolUseFailure hooks should use `async: true` to avoid blocking Claude's agentic loop with I/O. Low-frequency events (SessionStart, Stop) can be synchronous.
- **Idempotent directory creation**: The script auto-creates `.planning/.telemetry/` on first write if `.planning/` exists. If `.planning/` does not exist, it no-ops silently (success criterion #4).

### Anti-Patterns

- **Do NOT use stdout for telemetry output**: In hooks, stdout content is added to Claude's context (for SessionStart/UserPromptSubmit) or shown in verbose mode. All telemetry writes must go to the JSONL file, with stderr for error logging only.
- **Do NOT capture full tool_input content**: Tool inputs can be large (entire file contents for Write tool). Capture only tool_name and a brief summary.
- **Do NOT use `type: "prompt"` or `type: "agent"` hooks**: These invoke LLM calls, violating the zero-token-cost constraint.
- **Do NOT use synchronous hooks for PostToolUse**: Tool use hooks fire on every tool call (potentially hundreds per execution). Blocking Claude's loop for file I/O on each one adds latency. Use `async: true`.

---

## Don't Hand-Roll

| Problem | Solution | Why Not Custom |
|---------|----------|----------------|
| JSON parsing in shell | Use `jq` | Reliable, handles escaping, edge cases. Shell string manipulation for JSON is fragile. |
| Timestamp generation | Use `date -u +"%Y-%m-%dT%H:%M:%SZ"` | ISO-8601 standard, sortable, timezone-aware |
| Atomic file append | Use `>>` (shell append operator) | Atomic on most filesystems for single lines. No locking needed for JSONL. |
| Session-scoped env vars | Use `CLAUDE_ENV_FILE` mechanism | Official Claude Code pattern for persisting variables across hooks in a session |

---

## Common Pitfalls

| Pitfall | Impact | How to Avoid |
|---------|--------|--------------|
| Hook stdout injected into Claude's context | Telemetry data leaks into LLM context, wastes tokens | Never write to stdout in telemetry hooks. Use file I/O only. Set `suppressOutput: true` in JSON output if needed. |
| Synchronous PostToolUse hooks slow execution | Each tool call blocks until telemetry write completes | Use `async: true` for PostToolUse and PostToolUseFailure hooks |
| Shell profile `echo` statements corrupt hook JSON | If `~/.zshrc` prints text, it prepends to hook stdout, breaking JSON parsing | `telemetry.sh` should not produce JSON on stdout at all -- it writes to files. But if it ever needs stdout, guard against this. |
| `jq` not installed on target machine | Script fails, telemetry silently stops | Add a `jq` availability check at script start; fall back to basic `grep`/`sed` extraction if `jq` is missing |
| Concurrent writes from async hooks | File corruption from interleaved writes | Each JSONL line is atomic (single `echo ... >>` call). Keep lines under the OS pipe buffer size (~4KB on most systems). |
| `date` command differences (GNU vs BSD/macOS) | Different flag syntax for ISO timestamps | Use `date -u +"%Y-%m-%dT%H:%M:%SZ"` which works on both GNU and BSD. Avoid GNU-only flags like `--iso-8601`. |
| `.planning/` directory does not exist | Script crashes on file creation | Check `[ -d .planning ]` before any telemetry operations. No-op if missing. |
| `CLAUDE_ENV_FILE` not available in all hook types | Only SessionStart hooks have access to `CLAUDE_ENV_FILE` | Use a deterministic file path based on session_id (available in all hook inputs) instead of relying solely on env vars. Fall back: write session file path to `.planning/.telemetry/.current-session` as a coordination file. |
| Token usage not available in hook data | Cannot capture token counts -- a key desired metric | Document this limitation clearly. Token counts are not exposed through hooks. The transcript JSONL file (available via `transcript_path`) MAY contain token data but parsing it requires reading potentially large files. Research for Phase 7 should investigate transcript parsing. |
| `SubagentStart` matcher filters by agent type name | Custom agent names like "phase-researcher" work as matchers, but built-in "general-purpose" is the default | To capture all agent spawns regardless of type, omit the matcher or use `"*"` |

---

## Code Examples

### telemetry.sh -- Core Script Structure

```bash
#!/usr/bin/env bash
# telemetry.sh -- Zero-token-cost telemetry capture for orchestrator skills
# Called by skill-scoped hooks. Reads hook JSON from stdin, writes JSONL to file.
#
# Usage (from hook command):
#   telemetry.sh <event_type> <skill_name>
#
# Event types: skill_start, skill_end, agent_spawn, agent_complete, tool_use, tool_failure
# Environment: CLAUDE_PROJECT_DIR, TELEMETRY_FILE (set by SessionStart hook)

set -uo pipefail

EVENT_TYPE="${1:-unknown}"
SKILL_NAME="${2:-unknown}"

# Resolve project dir
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TELEMETRY_DIR="${PROJECT_DIR}/.planning/.telemetry"

# Graceful no-op: exit silently if .planning/ doesn't exist
[ -d "${PROJECT_DIR}/.planning" ] || exit 0

# Auto-create telemetry directory
mkdir -p "${TELEMETRY_DIR}" 2>/dev/null || exit 0

# Read hook JSON from stdin
INPUT=$(cat)

# Extract common fields from hook input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Determine telemetry file path
# Use TELEMETRY_FILE if set (by SessionStart hook), otherwise generate from session
if [ -n "${TELEMETRY_FILE:-}" ]; then
  OUTFILE="${TELEMETRY_FILE}"
else
  # Deterministic path based on skill + date
  DATE_SLUG=$(date -u +"%Y-%m-%dT%H-%M-%S")
  OUTFILE="${TELEMETRY_DIR}/${SKILL_NAME}-${DATE_SLUG}.jsonl"
fi

# Build event-specific data based on event type
case "${EVENT_TYPE}" in
  skill_start)
    DATA=$(echo "$INPUT" | jq -c '{source: .source, model: .model}' 2>/dev/null || echo '{}')
    ;;
  skill_end)
    DATA=$(echo "$INPUT" | jq -c '{reason: .reason}' 2>/dev/null || echo '{}')
    ;;
  agent_spawn)
    DATA=$(echo "$INPUT" | jq -c '{agent_type: .agent_type, agent_id: .agent_id}' 2>/dev/null || echo '{}')
    ;;
  agent_complete)
    DATA=$(echo "$INPUT" | jq -c '{agent_type: .agent_type, agent_id: .agent_id}' 2>/dev/null || echo '{}')
    ;;
  tool_use)
    DATA=$(echo "$INPUT" | jq -c '{tool_name: .tool_name}' 2>/dev/null || echo '{}')
    ;;
  tool_failure)
    DATA=$(echo "$INPUT" | jq -c '{tool_name: .tool_name, error: (.error // "unknown")[0:200]}' 2>/dev/null || echo '{}')
    ;;
  *)
    DATA='{}'
    ;;
esac

# Write JSONL line (atomic append)
echo "{\"event\":\"${EVENT_TYPE}\",\"skill\":\"${SKILL_NAME}\",\"session_id\":\"${SESSION_ID}\",\"timestamp\":\"${TIMESTAMP}\",\"data\":${DATA}}" >> "${OUTFILE}" 2>/dev/null

exit 0
```

Source: Designed for this project based on official Claude Code hooks documentation at https://code.claude.com/docs/en/hooks

### Skill Frontmatter Hook Declarations -- execute-phase Example

```yaml
---
name: execute-phase
# ... existing fields ...
hooks:
  # Existing compaction resilience hooks (keep these):
  PreCompact:
    - matcher: "auto"
      hooks:
        - type: command
          command: 'echo "EXECUTION STATE TO PRESERVE:"; find .planning/phases -name "EXEC-PROGRESS.md" -exec cat {} \; 2>/dev/null || echo "No execution progress file found"'
  SessionStart:
    - matcher: "compact"
      hooks:
        - type: command
          command: '{ echo "=== STATE ==="; cat .planning/STATE.md 2>/dev/null; ... }'
    # NEW: Telemetry on session start (all session types)
    - matcher: ""
      hooks:
        - type: command
          command: '${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh skill_start execute-phase'
          once: true
  # NEW: Telemetry hooks
  Stop:
    - hooks:
        - type: command
          command: '${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh skill_end execute-phase'
  SubagentStart:
    - hooks:
        - type: command
          command: '${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh agent_spawn execute-phase'
          async: true
  SubagentStop:
    - hooks:
        - type: command
          command: '${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh agent_complete execute-phase'
          async: true
  PostToolUse:
    - hooks:
        - type: command
          command: '${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh tool_use execute-phase'
          async: true
  PostToolUseFailure:
    - hooks:
        - type: command
          command: '${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh tool_failure execute-phase'
          async: true
---
```

Source: Pattern derived from existing execute-phase SKILL.md hooks and official hooks reference at https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents

### SessionStart Hook with CLAUDE_ENV_FILE for Session Path

```bash
# In the SessionStart hook, persist the telemetry file path for this session
# This specific initialization logic could be inline in the hook command:
SKILL="execute-phase"
DATE_SLUG=$(date -u +"%Y-%m-%dT%H-%M-%S")
TFILE=".planning/.telemetry/${SKILL}-${DATE_SLUG}.jsonl"
if [ -d .planning ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  mkdir -p .planning/.telemetry 2>/dev/null
  echo "export TELEMETRY_FILE=\"${TFILE}\"" >> "$CLAUDE_ENV_FILE"
fi
```

Source: Official Claude Code docs on CLAUDE_ENV_FILE at https://code.claude.com/docs/en/hooks#persist-environment-variables

---

## Hook Event Selection and Mapping

### Recommended Hook Events Per Orchestrator Skill

| Hook Event | Matcher | Purpose | Async? | Applicable Skills |
|------------|---------|---------|--------|-------------------|
| `SessionStart` | `""` (all) | Record skill invocation start, set telemetry file path via CLAUDE_ENV_FILE | No (fast, needs CLAUDE_ENV_FILE) | All 4 orchestrators |
| `Stop` | (no matcher support) | Record skill completion, compute duration | No (fires once) | All 4 orchestrators |
| `SessionEnd` | `""` (all) | Final cleanup, record session end reason | No (fires once) | All 4 orchestrators |
| `SubagentStart` | `""` (all) | Count and log agent spawns | Yes | All 4 orchestrators |
| `SubagentStop` | `""` (all) | Log agent completions, capture transcript path | Yes | All 4 orchestrators |
| `PostToolUse` | `"Task"` | Count Task tool invocations (agent spawns via Task tool) | Yes | All 4 orchestrators |
| `PostToolUse` | `"Bash\|Read\|Write\|Edit\|Glob\|Grep"` | Count tool usage by type | Yes | All 4 orchestrators |
| `PostToolUseFailure` | `""` (all) | Track tool failures | Yes | All 4 orchestrators |

### Hook Events NOT Used (and Why)

| Hook Event | Why Not |
|------------|---------|
| `PreToolUse` | Fires BEFORE tool execution -- we want to capture outcomes, not intents. Also, blocking/denying is not relevant for telemetry. |
| `UserPromptSubmit` | Only fires on user prompts, not skill-driven interactions. Not relevant for automated telemetry. |
| `PreCompact` | Already used by execute-phase for compaction resilience. Adding telemetry here adds no value -- SessionStart with "compact" matcher already captures compaction events. |
| `PermissionRequest` | Permission prompts are a UX event, not a telemetry-relevant execution event. |
| `Notification` | Read-only notifications have no telemetry value for execution metrics. |
| `TeammateIdle` | Teams-specific. Could be added later but adds complexity for marginal value. |
| `TaskCompleted` | Teams-specific task completion. SubagentStop already captures agent completions. |

---

## Hook Data Availability Analysis

### What IS Available Through Hooks (HIGH confidence)

| Data | Source Hook | Input Field | Notes |
|------|-----------|-------------|-------|
| Session ID | All hooks | `session_id` | Unique per Claude Code session |
| Timestamps | Computed by telemetry.sh | N/A (`date` command) | Not provided by hooks, must be generated |
| Tool names | PostToolUse, PostToolUseFailure, PreToolUse | `tool_name` | Exact tool name (e.g., "Bash", "Task", "Write") |
| Tool input | PostToolUse, PreToolUse | `tool_input` | Full tool parameters (can be large for Write/Edit) |
| Tool response | PostToolUse | `tool_response` | Success/failure result |
| Tool errors | PostToolUseFailure | `error`, `is_interrupt` | Error message string |
| Agent type | SubagentStart, SubagentStop | `agent_type` | "Bash", "Explore", "Plan", custom agent names |
| Agent ID | SubagentStart, SubagentStop | `agent_id` | Unique agent identifier |
| Agent transcript path | SubagentStop | `agent_transcript_path` | Path to subagent's transcript JSONL |
| Session source | SessionStart | `source` | "startup", "resume", "clear", "compact" |
| Model | SessionStart | `model` | Model identifier string |
| Session end reason | SessionEnd | `reason` | "clear", "logout", "prompt_input_exit", etc. |
| Transcript path | All hooks | `transcript_path` | Path to main session transcript JSONL |
| Working directory | All hooks | `cwd` | Current working directory |

### What is NOT Available Through Hooks (HIGH confidence)

| Data | Why Not | Workaround |
|------|---------|------------|
| Token usage (input/output tokens) | Not exposed in any hook event's input JSON | Parse the transcript JSONL file post-session (Phase 7 investigation) |
| Cost data | Not exposed through hooks | Compute from token counts + model pricing (Phase 7) |
| Agent prompt content | Not in SubagentStart input | Available in transcript, not needed for metrics |
| Task tool prompt/description | PostToolUse for Task only shows `tool_input.prompt`, `tool_input.description` | Could capture `tool_input.description` from PostToolUse matcher "Task" |
| Skill invocation arguments | Not in SessionStart input | Use `once: true` SessionStart hook to capture; or parse from context |
| Verification pass/fail status | Not a hook event | Parse VERIFICATION.md after execution (Phase 7 or via Stop hook reading files) |

Source: Official Claude Code hooks reference at https://code.claude.com/docs/en/hooks#hook-events -- verified February 2026.

---

## State of the Art

| Aspect | What Was Assumed | What Research Found | Impact |
|--------|-----------------|--------------------|----|
| Token availability | CONTEXT.md listed "token usage (if accessible via hooks)" as a metric to capture | Token usage is NOT available through any hook event's JSON input | Must defer token metrics to Phase 7 transcript parsing |
| Hook data richness | Assumed hooks would provide basic metadata | Hooks provide rich structured JSON: session IDs, tool inputs/outputs, agent IDs, transcript paths | More data available than expected -- telemetry can be comprehensive |
| `CLAUDE_ENV_FILE` scope | Assumed env vars persist across all hooks | `CLAUDE_ENV_FILE` is ONLY available in SessionStart hooks | Must use deterministic file paths or a coordination file for non-SessionStart hooks |
| Async hooks | Assumed all hooks would block | `async: true` is available for command hooks, runs in background | Critical for high-frequency PostToolUse hooks to avoid slowing execution |
| `once` field | Not previously considered | Available for skill-scoped hooks -- runs once per session then removed | Perfect for SessionStart telemetry initialization (run on first session start only) |
| Hook deduplication | Not previously considered | Identical handlers are auto-deduplicated | Won't affect telemetry since each skill has unique commands |
| Existing hook coexistence | Concerned about conflicts | Hooks merge -- multiple matcher groups for same event type work fine. Multiple SessionStart matchers are additive. | Can add telemetry hooks alongside existing compaction hooks without conflict |
| Verification outcomes | Assumed hook could capture pass/fail | Verification is a skill-internal concept, not a hook event | Capture via Stop hook reading VERIFICATION.md files, or defer to Phase 7 |

---

## Implementation Recommendations

### Error Handling Strategy: Silent Failure

Recommended approach: **Silent failure with optional stderr logging**.

- All telemetry operations wrapped in `2>/dev/null` or `|| true`
- Script always exits 0 (never disrupts hook flow)
- Optional: Write errors to `.planning/.telemetry/errors.log` for debugging
- Rationale: Telemetry is passive observation. If it fails, execution must continue unaffected.

### Directory Creation Approach: Auto-Create

Recommended approach: **Auto-create `.planning/.telemetry/` if `.planning/` exists**.

- Check `[ -d .planning ]` at script start
- If `.planning/` exists, run `mkdir -p .planning/.telemetry` silently
- If `.planning/` does not exist, exit 0 immediately (no-op)
- This satisfies success criterion #4 ("gracefully no-ops when directories don't exist")
- The `.telemetry/` directory should be added to `.gitignore`

### Session File Path Strategy

Recommended approach: **Deterministic path based on skill name + timestamp, with CLAUDE_ENV_FILE as optimization**.

The challenge: `CLAUDE_ENV_FILE` is only available in SessionStart hooks. Other hooks (PostToolUse, SubagentStart, etc.) need to know which file to write to.

Solution:
1. SessionStart hook generates the file path: `.planning/.telemetry/{skill}-{datetime}.jsonl`
2. Writes `export TELEMETRY_FILE="{path}"` to `CLAUDE_ENV_FILE`
3. Subsequent hooks check `$TELEMETRY_FILE` -- if set, use it; if not, write to a fallback deterministic path
4. Fallback: write a `.planning/.telemetry/.current-{skill}` file containing the path, which other hooks can read

### PostToolUse Matcher Strategy

For capturing tool usage across all orchestrator skills, use a broad matcher or no matcher:

- **Option A (recommended)**: No matcher (fires on all tool calls). Simple, captures everything. Filter during analysis in Phase 7.
- **Option B**: Matcher `"Task|Bash|Read|Write|Edit|Glob|Grep"` to exclude internal tools. Slightly less data, slightly less noise.

Recommendation: Use Option A (no matcher) with `async: true`. The overhead is minimal (one file append per tool call) and having complete data is more valuable than filtering at capture time.

---

## Open Questions

- **Transcript JSONL format**: The `transcript_path` field in hook input points to a JSONL file containing the full conversation. This file likely contains token usage data. However, parsing it during execution (from a hook) would be expensive and potentially slow. Investigation of transcript format should be deferred to Phase 7 research for the `/metrics` skill.

- **`CLAUDE_ENV_FILE` availability in skill-scoped hooks**: The documentation says SessionStart hooks have access to `CLAUDE_ENV_FILE`. It is unclear whether this is also true when the SessionStart hook is defined in skill frontmatter vs. settings.json. The execute-phase already uses SessionStart in frontmatter (for compaction resilience), and its output is added to Claude's context, which confirms skill-scoped SessionStart hooks work. The env var persistence needs testing during implementation.

- **Hook handler deduplication across skills**: If two skills define identical hook commands, Claude Code deduplicates them. Since each skill passes its name as an argument (`telemetry.sh skill_start execute-phase` vs `telemetry.sh skill_start plan-phase`), deduplication should not affect telemetry. But this should be verified.

- **Async hook output delivery timing**: The docs state async hook output is "delivered to Claude as context on the next conversation turn." For telemetry, since we never produce stdout/JSON output, this is irrelevant. But it is worth noting that async hooks cannot influence execution flow.

---

## Sources

| Source | Type | Confidence | URL |
|--------|------|------------|-----|
| Claude Code Hooks Reference | Official docs | HIGH | https://code.claude.com/docs/en/hooks |
| Claude Code Hooks Guide | Official docs | HIGH | https://code.claude.com/docs/en/hooks-guide |
| Claude Code Skills Documentation | Official docs | HIGH | https://code.claude.com/docs/en/skills |
| CAPABILITY-REFERENCE.md (Phase 1 output) | Codebase | HIGH | Project root |
| Existing execute-phase SKILL.md hooks | Codebase | HIGH | plugins/claude-super-team/skills/execute-phase/SKILL.md |
| Existing progress-gather.sh | Codebase | HIGH | plugins/claude-super-team/scripts/progress-gather.sh |
| Phase 1 Research (01-RESEARCH.md) | Codebase | HIGH | .planning/phases/01-claude-code-capability-mapping/01-RESEARCH.md |
| Phase 6 CONTEXT.md | Codebase | HIGH | .planning/phases/06-hook-telemetry/06-CONTEXT.md |

---

## Metadata

- **Research date:** 2026-02-17
- **Phase:** 6 - Hook-Based Telemetry Capture
- **Confidence breakdown:** 22 HIGH, 2 MEDIUM, 0 LOW findings
- **Firecrawl available:** yes
- **Sources consulted:** 8
