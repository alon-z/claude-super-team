#!/usr/bin/env bash
# gather-data.sh - Gather planning artifacts and codebase docs for /drift skill
# Called via dynamic context injection in SKILL.md

P=.planning
source "$(dirname "$0")/../../scripts/gather-common.sh"

# === Standard sections (shared functions) ===

emit_project_section

emit_roadmap_section

emit_state_section

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
    verification=0
    vcount=$(find "$dir" -maxdepth 1 -name "*-VERIFICATION.md" 2>/dev/null | wc -l | tr -d " ")
    [ "$vcount" -gt 0 ] && verification=1
    echo "${name}|context=${context}|research=${research}|plans=${plans}|summaries=${summaries}|verification=${verification}"
  done
else
  echo "(no phases directory)"
fi

# === CODEBASE_DOCS ===
echo "=== CODEBASE_DOCS ==="
if [ -d "$P/codebase" ]; then
  for doc in "$P"/codebase/*.md; do
    [ -f "$doc" ] || continue
    docname=$(basename "$doc")
    echo "--- ${docname} ---"
    cat "$doc"
    echo ""
  done
else
  echo "(no codebase map)"
fi
