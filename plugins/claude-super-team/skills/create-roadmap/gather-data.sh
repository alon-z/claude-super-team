#!/usr/bin/env bash
# gather-data.sh - Pre-compute planning structure for /create-roadmap

source "$(dirname "$0")/../../scripts/gather-common.sh"

echo "=== PROJECT ==="
if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else
  cat_project .planning/PROJECT.md
fi
echo "=== ROADMAP ==="
if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else
  cat_roadmap .planning/ROADMAP.md
fi

echo "=== STRUCTURE ==="
[ -f .planning/PROJECT.md ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f .planning/REQUIREMENTS.md ] && echo "HAS_REQUIREMENTS=true" || echo "HAS_REQUIREMENTS=false"
[ -f .planning/research/SUMMARY.md ] && echo "HAS_RESEARCH=true" || echo "HAS_RESEARCH=false"
[ -d .planning/codebase ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"
[ -f .planning/PROJECT.json ] && echo "HAS_PROJECT_JSON=true" || echo "HAS_PROJECT_JSON=false"
[ -f .planning/ROADMAP.json ] && echo "HAS_ROADMAP_JSON=true" || echo "HAS_ROADMAP_JSON=false"

# EXISTING_PHASES, HIGHEST_PHASE, DECIMAL_PHASES removed:
# All derivable from the full ROADMAP content already emitted above.
# roadmap-modification.md instructs the agent to parse ROADMAP.md directly.
