#!/usr/bin/env bash
# gather-data.sh - Pre-compute plan index and preferences for /execute-phase

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
echo "=== PREFERENCES ==="
grep -E '^execution-model:' .planning/STATE.md 2>/dev/null || echo "execution-model: unset"
grep -E '^simplifier:' .planning/STATE.md 2>/dev/null || echo "simplifier: unset"
[ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" = "1" ] && echo "teams-available: true" || echo "teams-available: false"

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
echo "=== PHASE_COMPLETION ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    plans=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " ")
    summaries=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " ")
    if [ "$plans" -gt 0 ] && [ "$summaries" -ge "$plans" ]; then
      echo "${name}|complete|plans=${plans}|summaries=${summaries}"
    elif [ "$summaries" -gt 0 ]; then
      echo "${name}|partial|plans=${plans}|summaries=${summaries}"
    elif [ "$plans" -gt 0 ]; then
      echo "${name}|planned|plans=${plans}|summaries=${summaries}"
    else
      echo "${name}|empty|plans=0|summaries=0"
    fi
  done
fi

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
