#!/usr/bin/env bash
# gather-data.sh - Pre-compute plan index and preferences for /execute-phase

source "$(dirname "$0")/../../scripts/gather-common.sh"

echo "=== PROJECT ==="
if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else
  cat .planning/PROJECT.md 2>/dev/null || echo "(missing)"
fi
echo "=== ROADMAP ==="
if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else
  cat .planning/ROADMAP.md 2>/dev/null || echo "(missing)"
fi
echo "=== STATE ==="
if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else
  cat .planning/STATE.md 2>/dev/null || echo "(missing)"
fi

# Preferences from STATE.md and environment
emit_preferences

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

# Computed phase completion from filesystem (source of truth)
emit_phase_completion

# Roadmap checkbox status (may be stale -- compare with PHASE_COMPLETION)
echo "=== ROADMAP_CHECKED ==="
echo -n "CHECKED: "
grep -E '^\s*- \[x\]' .planning/ROADMAP.md 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{print $2}' | tr '\n' ' '
echo
echo -n "UNCHECKED: "
grep -E '^\s*- \[ \]' .planning/ROADMAP.md 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{print $2}' | tr '\n' ' '
echo

# Git branch for branch guard
echo "=== GIT ==="
echo "BRANCH=$(git branch --show-current 2>/dev/null || echo detached)"
