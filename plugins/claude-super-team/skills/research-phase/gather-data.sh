#!/usr/bin/env bash
# gather-data.sh - Pre-compute phase and context data for /research-phase

P=.planning
source "$(dirname "$0")/../../scripts/gather-common.sh"

echo "=== PROJECT ==="
if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else
  cat "$P/PROJECT.md" 2>/dev/null || echo "(missing)"
fi
echo "=== ROADMAP ==="
if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else
  cat "$P/ROADMAP.md" 2>/dev/null || echo "(missing)"
fi
echo "=== STATE ==="
if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else
  cat "$P/STATE.md" 2>/dev/null || echo "(missing)"
fi

# === PREREQUISITES ===
echo "=== PREREQUISITES ==="
[ -f "$P/PROJECT.md" ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f "$P/ROADMAP.md" ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f "$P/STATE.md" ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
[ -f "$P/PROJECT.json" ] && echo "HAS_PROJECT_JSON=true" || echo "HAS_PROJECT_JSON=false"
[ -f "$P/ROADMAP.json" ] && echo "HAS_ROADMAP_JSON=true" || echo "HAS_ROADMAP_JSON=false"
[ -f "$P/STATE.json" ] && echo "HAS_STATE_JSON=true" || echo "HAS_STATE_JSON=false"

# === PHASE_ARTIFACTS ===
echo "=== PHASE_ARTIFACTS ==="
if [ -d "$P/phases" ]; then
  for dir in "$P"/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    context=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d " ")
    research=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d " ")
    plans=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " ")
    summaries=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " ")
    echo "${name}|context=${context}|research=${research}|plans=${plans}|summaries=${summaries}"
  done
fi

# === ROADMAP_PHASES ===
echo "=== ROADMAP_PHASES ==="
if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/ROADMAP.json" ]; then
  jq -r '.phases[] | "### Phase \(.id): \(.name)"' "$P/ROADMAP.json" 2>/dev/null
else
  grep -E "^#+.*Phase [0-9]+(\.[0-9]+)?" "$P/ROADMAP.md" 2>/dev/null
fi

# === CODEBASE_DOCS ===
echo "=== CODEBASE_DOCS ==="
[ -d "$P/codebase" ] && ls "$P/codebase/" 2>/dev/null || echo "none"
