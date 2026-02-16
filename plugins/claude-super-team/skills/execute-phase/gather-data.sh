#!/usr/bin/env bash
# gather-data.sh - Pre-compute plan index and preferences for /execute-phase

# Preferences from STATE.md
echo "=== PREFERENCES ==="
grep -E '^execution-model:' .planning/STATE.md 2>/dev/null || echo "execution-model: unset"
grep -E '^simplifier:' .planning/STATE.md 2>/dev/null || echo "simplifier: unset"

# Plan discovery with metadata for all phases
echo "=== PHASE_PLANS ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    phase_name=$(basename "$dir")
    for plan in "${dir}"*-PLAN.md; do
      [ -f "$plan" ] || continue
      plan_name=$(basename "$plan")
      plan_id=${plan_name%-PLAN.md}
      summary="${dir}${plan_id}-SUMMARY.md"
      has_summary="false"
      [ -f "$summary" ] && has_summary="true"
      wave=$(grep -m1 '^wave:' "$plan" 2>/dev/null | awk '{print $2}')
      gap=$(grep -m1 '^gap_closure:' "$plan" 2>/dev/null | awk '{print $2}')
      echo "${phase_name}|${plan_id}|wave=${wave:-1}|gap=${gap:-false}|summary=${has_summary}"
    done
  done
fi

# Git branch for branch guard
echo "=== GIT ==="
echo "BRANCH=$(git branch --show-current 2>/dev/null || echo detached)"
