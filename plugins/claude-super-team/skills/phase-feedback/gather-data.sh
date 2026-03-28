#!/usr/bin/env bash
# gather-data.sh - Pre-compute executed phases and subphase numbers for /phase-feedback
#
# Optimized: slim project/roadmap/state. This skill needs phase lists and
# current position, not full prose.

source "$(dirname "$0")/../../scripts/gather-common.sh"

emit_project_slim
emit_roadmap_slim
emit_state_slim

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

# Current phase from STATE
echo "=== CURRENT_PHASE ==="
if [ "$_JQ_AVAILABLE" = "true" ] && [ -f .planning/STATE.json ]; then
  jq -r '"Phase: \(.currentPosition.phase)"' .planning/STATE.json 2>/dev/null || grep -E '^Phase:' .planning/STATE.md 2>/dev/null | head -1
else
  grep -E '^Phase:' .planning/STATE.md 2>/dev/null | head -1
fi

# Existing subphases (for decimal numbering)
echo "=== SUBPHASES ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    echo "$name" | grep -q '\.' && echo "$name"
  done
fi
