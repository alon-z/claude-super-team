#!/usr/bin/env bash
# gather-data.sh - Pre-compute executed phases and subphase numbers for /phase-feedback

# Executed phases (those with SUMMARY.md files)
echo "=== EXECUTED_PHASES ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    summaries=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " ")
    [ "$summaries" -gt 0 ] && echo "${name}|summaries=${summaries}"
  done
fi

# Current phase from STATE.md
echo "=== CURRENT_PHASE ==="
grep -E '^Phase:' .planning/STATE.md 2>/dev/null | head -1

# Existing subphases (for decimal numbering)
echo "=== SUBPHASES ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    echo "$name" | grep -q '\.' && echo "$name"
  done
fi
