#!/usr/bin/env bash
# gather-data.sh - Gather planning data for /code skill
# Called via dynamic context injection in SKILL.md

P=.planning

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
grep -E '^Phase:' "$P/STATE.md" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1

# === RECENT_SESSIONS ===
echo "=== RECENT_SESSIONS ==="
if [ -d "$P/.sessions" ]; then
  ls -t "$P/.sessions/"*.md 2>/dev/null | head -5 | while IFS= read -r f; do
    name=$(basename "$f")
    title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
    echo "$name|$title"
  done
fi
