#!/usr/bin/env bash
# telemetry.sh - Capture skill/agent/tool telemetry as JSONL
# Usage: telemetry.sh <event_type> <skill_name>
#
# Event types:
#   skill_start     - Skill session started (SessionStart hook)
#   skill_end       - Skill session ended (Stop hook)
#   agent_spawn     - Subagent spawned (SubagentStart hook)
#   agent_complete  - Subagent finished (SubagentComplete hook)
#   tool_use        - Tool invoked (PostToolUse hook)
#   tool_failure    - Tool failed (PostToolUse hook with error)
#
# Reads hook JSON from stdin, appends a JSONL line to a session-scoped file.
# Completely fail-safe -- never disrupts skill execution.

set -uo pipefail

EVENT_TYPE="${1:-unknown}"
SKILL_NAME="${2:-unknown}"

# --- Directory resolution and no-op guard ---
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TELEMETRY_DIR="${PROJECT_DIR}/.planning/.telemetry"

[ -d "${PROJECT_DIR}/.planning" ] || exit 0
mkdir -p "${TELEMETRY_DIR}" 2>/dev/null || exit 0

# --- jq availability check ---
HAS_JQ=false
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=true
fi

_json_val() {
  echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# --- Read stdin ---
INPUT=$(cat)

# --- Extract common fields ---
if [ "${HAS_JQ}" = "true" ]; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
else
  SESSION_ID=$(_json_val "$INPUT" "session_id")
  SESSION_ID="${SESSION_ID:-unknown}"
fi
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Determine output file path ---
if [ -n "${TELEMETRY_FILE:-}" ]; then
  OUTFILE="${TELEMETRY_FILE}"
else
  DATE_SLUG=$(date -u +"%Y-%m-%dT%H-%M-%S")
  OUTFILE="${TELEMETRY_DIR}/${SKILL_NAME}-${DATE_SLUG}.jsonl"
fi

# --- Persist TELEMETRY_FILE for session (skill_start only) ---
if [ "${EVENT_TYPE}" = "skill_start" ] && [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -z "${TELEMETRY_FILE:-}" ]; then
  echo "export TELEMETRY_FILE=\"${OUTFILE}\"" >> "${CLAUDE_ENV_FILE}" 2>/dev/null
fi

# --- Build event-specific data ---
DATA='{}'
case "${EVENT_TYPE}" in
  skill_start)
    if [ "${HAS_JQ}" = "true" ]; then
      DATA=$(echo "$INPUT" | jq -c '{source: .source, model: .model}' 2>/dev/null || echo '{}')
    else
      _src=$(_json_val "$INPUT" "source")
      _mdl=$(_json_val "$INPUT" "model")
      DATA="{\"source\":\"${_src}\",\"model\":\"${_mdl}\"}"
    fi
    ;;
  skill_end)
    if [ "${HAS_JQ}" = "true" ]; then
      DATA=$(echo "$INPUT" | jq -c '{reason: .reason}' 2>/dev/null || echo '{}')
    else
      _rsn=$(_json_val "$INPUT" "reason")
      DATA="{\"reason\":\"${_rsn}\"}"
    fi
    ;;
  agent_spawn)
    if [ "${HAS_JQ}" = "true" ]; then
      DATA=$(echo "$INPUT" | jq -c '{agent_type: .agent_type, agent_id: .agent_id}' 2>/dev/null || echo '{}')
    else
      _at=$(_json_val "$INPUT" "agent_type")
      _ai=$(_json_val "$INPUT" "agent_id")
      DATA="{\"agent_type\":\"${_at}\",\"agent_id\":\"${_ai}\"}"
    fi
    ;;
  agent_complete)
    if [ "${HAS_JQ}" = "true" ]; then
      DATA=$(echo "$INPUT" | jq -c '{agent_type: .agent_type, agent_id: .agent_id, transcript_path: .agent_transcript_path}' 2>/dev/null || echo '{}')
    else
      _at=$(_json_val "$INPUT" "agent_type")
      _ai=$(_json_val "$INPUT" "agent_id")
      _tp=$(_json_val "$INPUT" "agent_transcript_path")
      DATA="{\"agent_type\":\"${_at}\",\"agent_id\":\"${_ai}\",\"transcript_path\":\"${_tp}\"}"
    fi
    ;;
  tool_use)
    if [ "${HAS_JQ}" = "true" ]; then
      DATA=$(echo "$INPUT" | jq -c '{tool_name: .tool_name}' 2>/dev/null || echo '{}')
    else
      _tn=$(_json_val "$INPUT" "tool_name")
      DATA="{\"tool_name\":\"${_tn}\"}"
    fi
    ;;
  tool_failure)
    if [ "${HAS_JQ}" = "true" ]; then
      DATA=$(echo "$INPUT" | jq -c '{tool_name: .tool_name, error: ((.error // "unknown") | .[0:200])}' 2>/dev/null || echo '{}')
    else
      _tn=$(_json_val "$INPUT" "tool_name")
      _err=$(_json_val "$INPUT" "error")
      _err="${_err:-unknown}"
      _err="${_err:0:200}"
      DATA="{\"tool_name\":\"${_tn}\",\"error\":\"${_err}\"}"
    fi
    ;;
  *)
    DATA='{}'
    ;;
esac

# --- Write JSONL line ---
echo "{\"event\":\"${EVENT_TYPE}\",\"skill\":\"${SKILL_NAME}\",\"session_id\":\"${SESSION_ID}\",\"timestamp\":\"${TIMESTAMP}\",\"data\":${DATA}}" >> "${OUTFILE}" 2>/dev/null

exit 0
