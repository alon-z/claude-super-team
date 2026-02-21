#!/usr/bin/env bash
# gather-data.sh - Pre-compute cross-phase artifact inventory for /discuss-phase

echo "=== PROJECT ==="
if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else
  cat .planning/PROJECT.md 2>/dev/null || echo "(missing)"
fi
echo "=== ROADMAP ==="
if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else
  cat .planning/ROADMAP.md 2>/dev/null || echo "(missing)"
fi

# Per-phase artifact inventory with status
echo "=== PHASE_ARTIFACTS ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    summaries=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " ")
    plans=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " ")
    context=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d " ")
    research=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d " ")

    if [ "$summaries" -gt 0 ]; then
      status="executed"
    elif [ "$plans" -gt 0 ]; then
      status="planned"
    elif [ "$context" -gt 0 ]; then
      status="discussed"
    else
      status="not_started"
    fi
    echo "${name}|status=${status}|summaries=${summaries}|plans=${plans}|context=${context}|research=${research}"
  done
fi

# Codebase docs availability
echo "=== CODEBASE_DOCS ==="
[ -d .planning/codebase ] && ls .planning/codebase/ 2>/dev/null || echo "none"
