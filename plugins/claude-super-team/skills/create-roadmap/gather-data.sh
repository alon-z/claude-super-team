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

if [ -f .planning/ROADMAP.md ] || { [ "$_JQ_AVAILABLE" = "true" ] && [ -f .planning/ROADMAP.json ]; }; then
  echo "=== EXISTING_PHASES ==="
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f .planning/ROADMAP.json ]; then
    jq -r '.phases[] | "- [\(if .complete then "x" else " " end)] Phase \(.id): \(.name)"' .planning/ROADMAP.json 2>/dev/null
  else
    grep -E "^\s*- \[.\] Phase" .planning/ROADMAP.md 2>/dev/null
  fi
  echo "=== HIGHEST_PHASE ==="
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f .planning/ROADMAP.json ]; then
    jq -r '[.phases[].id | tonumber? // .] | max' .planning/ROADMAP.json 2>/dev/null
  else
    grep -oE 'Phase [0-9]+' .planning/ROADMAP.md 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1
  fi
  echo "=== DECIMAL_PHASES ==="
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f .planning/ROADMAP.json ]; then
    jq -r '.phases[].id | select(contains("."))' .planning/ROADMAP.json 2>/dev/null | while read -r id; do
      echo "Phase $id"
    done
  else
    grep -oE 'Phase [0-9]+\.[0-9]+' .planning/ROADMAP.md 2>/dev/null
  fi
fi
