#!/usr/bin/env bash
# gather-data.sh - Gather telemetry data for /metrics skill
# Called via dynamic context injection in SKILL.md

P=.planning
source "$(dirname "$0")/../../scripts/gather-common.sh"

# === Standard sections ===

emit_project_section

emit_state_section

# === TELEMETRY_FILES ===
echo "=== TELEMETRY_FILES ==="
TDIR="$P/.telemetry"
if [ -d "$TDIR" ]; then
  FILES=()
  while IFS= read -r f; do
    FILES+=("$f")
  done < <(find "$TDIR" -maxdepth 1 -name "session-*.jsonl" -type f 2>/dev/null | sort)
  if [ ${#FILES[@]} -eq 0 ]; then
    echo "(none)"
  else
    for f in "${FILES[@]}"; do
      echo "$f"
    done
  fi
else
  echo "(none)"
fi

# === THRESHOLDS ===
echo "=== THRESHOLDS ==="
CONFIG="$TDIR/config.json"
if [ -f "$CONFIG" ]; then
  # Check for jq
  if command -v jq >/dev/null 2>&1; then
    jq -r 'to_entries[] | "\(.key)=\(.value)"' "$CONFIG" 2>/dev/null || echo "(error)"
  else
    # Fallback: parse simple JSON key-value pairs with grep/sed
    grep -oE '"[^"]+"\s*:\s*[0-9]+' "$CONFIG" 2>/dev/null | sed 's/"\([^"]*\)"\s*:\s*/\1=/' || echo "(error)"
  fi
else
  echo "max_tool_calls_per_session=500"
  echo "max_agent_spawns_per_session=20"
  echo "max_session_duration_minutes=60"
  echo "max_failure_rate_percent=5"
fi

# === SESSION_METRICS ===
echo "=== SESSION_METRICS ==="
if [ -d "$TDIR" ] && [ ${#FILES[@]-0} -gt 0 ]; then
  HAS_JQ=false
  command -v jq >/dev/null 2>&1 && HAS_JQ=true

  _jval() {
    echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/'
  }

  for f in "${FILES[@]}"; do
    {
      tools=0
      agents=0
      failures=0
      first_ts=""
      last_ts=""
      model="unknown"

      while IFS= read -r line; do
        [ -z "$line" ] && continue

        if [ "$HAS_JQ" = "true" ]; then
          evt=$(echo "$line" | jq -r '.event // ""' 2>/dev/null)
          ts=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
        else
          evt=$(_jval "$line" "event")
          ts=$(_jval "$line" "timestamp")
        fi

        [ -z "$first_ts" ] && first_ts="$ts"
        last_ts="$ts"

        case "$evt" in
          tool_use) tools=$((tools + 1)) ;;
          agent_spawn) agents=$((agents + 1)) ;;
          tool_failure) failures=$((failures + 1)) ;;
          skill_start)
            if [ "$model" = "unknown" ]; then
              if [ "$HAS_JQ" = "true" ]; then
                m=$(echo "$line" | jq -r '.data.model // "unknown"' 2>/dev/null)
              else
                m=$(_jval "$line" "model")
              fi
              [ -n "$m" ] && [ "$m" != "null" ] && model="$m"
            fi
            ;;
        esac
      done < "$f"

      # Calculate duration
      duration=0
      if [ -n "$first_ts" ] && [ -n "$last_ts" ] && [ "$first_ts" != "$last_ts" ]; then
        # Try macOS date parsing
        t1=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_ts" "+%s" 2>/dev/null) || t1=""
        t2=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" "+%s" 2>/dev/null) || t2=""
        if [ -n "$t1" ] && [ -n "$t2" ]; then
          duration=$((t2 - t1))
          [ "$duration" -lt 0 ] && duration=0
        fi
      fi

      echo "${f}|tools=${tools}|agents=${agents}|failures=${failures}|duration_sec=${duration}|model=${model}"
    } 2>/dev/null || echo "${f}|tools=0|agents=0|failures=0|duration_sec=0|model=unknown"
  done
else
  echo "(none)"
fi

# === TOOL_BREAKDOWN ===
echo "=== TOOL_BREAKDOWN ==="
if [ -d "$TDIR" ] && [ ${#FILES[@]-0} -gt 0 ]; then
  {
    if command -v jq >/dev/null 2>&1; then
      for f in "${FILES[@]}"; do
        grep '"tool_use"' "$f" 2>/dev/null | jq -r '.data.tool_name // empty' 2>/dev/null
      done
    else
      for f in "${FILES[@]}"; do
        grep '"tool_use"' "$f" 2>/dev/null | grep -oE '"tool_name"\s*:\s*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/'
      done
    fi
  } | sort | uniq -c | sort -rn | awk '{print $2"="$1}' 2>/dev/null || echo "(error)"
else
  echo "(none)"
fi

# === AGENT_BREAKDOWN ===
echo "=== AGENT_BREAKDOWN ==="
if [ -d "$TDIR" ] && [ ${#FILES[@]-0} -gt 0 ]; then
  {
    if command -v jq >/dev/null 2>&1; then
      for f in "${FILES[@]}"; do
        grep '"agent_spawn"' "$f" 2>/dev/null | jq -r '.data.agent_type // empty' 2>/dev/null
      done
    else
      for f in "${FILES[@]}"; do
        grep '"agent_spawn"' "$f" 2>/dev/null | grep -oE '"agent_type"\s*:\s*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/'
      done
    fi
  } | sort | uniq -c | sort -rn | awk '{print $2"="$1}' 2>/dev/null || echo "(error)"
else
  echo "(none)"
fi

# === TOTALS ===
echo "=== TOTALS ==="
if [ -d "$TDIR" ] && [ ${#FILES[@]-0} -gt 0 ]; then
  total_tools=0
  total_agents=0
  total_failures=0
  total_duration=0
  session_count=0

  for f in "${FILES[@]}"; do
    session_count=$((session_count + 1))
    t=$(grep -c '"tool_use"' "$f" 2>/dev/null) || t=0
    a=$(grep -c '"agent_spawn"' "$f" 2>/dev/null) || a=0
    fl=$(grep -c '"tool_failure"' "$f" 2>/dev/null) || fl=0
    total_tools=$((total_tools + t))
    total_agents=$((total_agents + a))
    total_failures=$((total_failures + fl))
  done

  # Sum durations from SESSION_METRICS (re-read is simpler than caching)
  # Use grep counts for totals; duration needs timestamp parsing which was done above
  # For total_duration, parse first/last timestamps across ALL sessions
  all_first=""
  all_last=""
  for f in "${FILES[@]}"; do
    if command -v jq >/dev/null 2>&1; then
      fts=$(head -1 "$f" 2>/dev/null | jq -r '.timestamp // ""' 2>/dev/null)
      lts=$(tail -1 "$f" 2>/dev/null | jq -r '.timestamp // ""' 2>/dev/null)
    else
      fts=$(head -1 "$f" 2>/dev/null | grep -oE '"timestamp"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
      lts=$(tail -1 "$f" 2>/dev/null | grep -oE '"timestamp"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    fi
    if [ -n "$fts" ] && [ -n "$lts" ]; then
      t1=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$fts" "+%s" 2>/dev/null) || t1=""
      t2=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$lts" "+%s" 2>/dev/null) || t2=""
      if [ -n "$t1" ] && [ -n "$t2" ]; then
        d=$((t2 - t1))
        [ "$d" -lt 0 ] && d=0
        total_duration=$((total_duration + d))
      fi
    fi
  done

  echo "sessions=${session_count}"
  echo "total_tools=${total_tools}"
  echo "total_agents=${total_agents}"
  echo "total_failures=${total_failures}"
  echo "total_duration_sec=${total_duration}"
else
  echo "sessions=0"
  echo "total_tools=0"
  echo "total_agents=0"
  echo "total_failures=0"
  echo "total_duration_sec=0"
fi
