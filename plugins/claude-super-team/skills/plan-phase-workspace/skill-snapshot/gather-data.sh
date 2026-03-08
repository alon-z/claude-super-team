#!/usr/bin/env bash
# gather-data.sh - Pre-compute phase planning status for /plan-phase

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

# Per-phase planning status (critical for --all mode)
echo "=== PHASE_STATUS ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    plans=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " ")
    context=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d " ")
    research=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d " ")
    verification=$(find "$dir" -maxdepth 1 -name "*-VERIFICATION.md" 2>/dev/null | wc -l | tr -d " ")
    echo "${name}|plans=${plans}|context=${context}|research=${research}|verification=${verification}"
  done
fi

# Roadmap phase headings (for detecting unplanned ones)
echo "=== ROADMAP_PHASES ==="
grep -E "^#+.*Phase [0-9]+(\.[0-9]+)?" .planning/ROADMAP.md 2>/dev/null
