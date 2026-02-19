#!/usr/bin/env bash
# gather-data.sh - Pre-compute planning structure for /create-roadmap

echo "=== PROJECT ==="
cat .planning/PROJECT.md 2>/dev/null || echo "(missing)"
echo "=== ROADMAP ==="
cat .planning/ROADMAP.md 2>/dev/null || echo "(missing)"

echo "=== STRUCTURE ==="
[ -f .planning/PROJECT.md ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f .planning/REQUIREMENTS.md ] && echo "HAS_REQUIREMENTS=true" || echo "HAS_REQUIREMENTS=false"
[ -f .planning/research/SUMMARY.md ] && echo "HAS_RESEARCH=true" || echo "HAS_RESEARCH=false"
[ -d .planning/codebase ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"

if [ -f .planning/ROADMAP.md ]; then
  echo "=== EXISTING_PHASES ==="
  grep -E "^\s*- \[.\] Phase" .planning/ROADMAP.md 2>/dev/null
  echo "=== HIGHEST_PHASE ==="
  grep -oE 'Phase [0-9]+' .planning/ROADMAP.md 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1
  echo "=== DECIMAL_PHASES ==="
  grep -oE 'Phase [0-9]+\.[0-9]+' .planning/ROADMAP.md 2>/dev/null
fi
