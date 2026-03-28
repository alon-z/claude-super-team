#!/usr/bin/env bash
# gather-data.sh - Gather planning data for /code skill
# Called via dynamic context injection in SKILL.md
#
# Optimized: slim project/roadmap. Keeps full STATE (accumulated context
# is valuable for interactive coding sessions).

P=.planning
source "$(dirname "$0")/../../scripts/gather-common.sh"

emit_project_slim
emit_roadmap_slim

echo "=== STATE ==="
if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else
  if [ -f "$P/STATE.md" ]; then
    # Full state but stop at Decision Archive
    awk '/^### Decision Archive/ { exit } { print }' "$P/STATE.md"
  else
    echo "(missing)"
  fi
fi

# === EXECUTED_PHASES ===
echo "=== EXECUTED_PHASES ==="
if [ -d "$P/phases" ]; then
  for dir in "$P"/phases/*/; do
    [ -d "$dir" ] || continue
    s=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " ")
    if [ "$s" -gt 0 ]; then
      basename "$dir"
    fi
  done
fi

# === CURRENT_PHASE ===
echo "=== CURRENT_PHASE ==="
if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/STATE.json" ]; then
  jq -r '.currentPosition.phase // empty' "$P/STATE.json" 2>/dev/null
else
  grep -E '^Phase:' "$P/STATE.md" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1
fi

# === RECENT_SESSIONS ===
echo "=== RECENT_SESSIONS ==="
if [ -d "$P/.sessions" ]; then
  ls -t "$P/.sessions/"*.md 2>/dev/null | head -5 | while IFS= read -r f; do
    name=$(basename "$f")
    title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
    echo "$name|$title"
  done
fi
