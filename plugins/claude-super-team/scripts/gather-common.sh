#!/usr/bin/env bash
# gather-common.sh - Shared functions for skill gather-data.sh scripts
#
# Sourced by per-skill gather-data.sh via:
#   source "$(dirname "$0")/../../scripts/gather-common.sh"
#
# All functions assume the working directory is the project root.
# All functions emit their own === SECTION === header.
# Callers can override the planning directory by setting P before sourcing.

P="${P:-.planning}"

# Cache jq availability to avoid repeated command -v calls
_JQ_AVAILABLE=false
command -v jq >/dev/null 2>&1 && _JQ_AVAILABLE=true

# cat_project: Output PROJECT.md with validated requirements trimmed.
# Strips "- [x]" items from ### Validated section, emits count instead.
# Usage: cat_project [file]  (defaults to $P/PROJECT.md)
cat_project() {
  local f="${1:-$P/PROJECT.md}"
  if [ ! -f "$f" ]; then echo "(missing)"; return 1; fi
  awk '
    /^### Validated/ { in_val=1; count=0; print; next }
    in_val && /^- \[x\]/ { count++; next }
    in_val && /^(### |## )/ {
      if (count > 0) printf "\n*(%d validated requirements omitted -- see PROJECT.md)*\n\n", count
      in_val=0; print; next
    }
    in_val && /^[[:space:]]*$/ { next }
    { print }
    END { if (in_val && count > 0) printf "\n*(%d validated requirements omitted -- see PROJECT.md)*\n\n", count }
  ' "$f"
}

# cat_roadmap: Output ROADMAP.md with completed phase details trimmed.
# Strips ### Phase ... [COMPLETE] blocks from ## Phase Details, keeps incomplete/deferred.
# Usage: cat_roadmap [file]  (defaults to $P/ROADMAP.md)
cat_roadmap() {
  local f="${1:-$P/ROADMAP.md}"
  if [ ! -f "$f" ]; then echo "(missing)"; return 1; fi
  awk '
    /^## Phase Details/ { in_details=1; print; next }
    in_details && /^### Phase .* \[COMPLETE\]/ { in_complete=1; skipped++; next }
    in_details && /^### Phase / { in_complete=0; print; next }
    in_details && /^## / {
      if (skipped > 0) printf "\n*(%d completed phase details omitted)*\n\n", skipped
      in_details=0; in_complete=0; print; next
    }
    in_complete { next }
    { print }
    END { if (in_details && skipped > 0) printf "\n*(%d completed phase details omitted)*\n\n", skipped }
  ' "$f"
}

# cat_roadmap_compact: Output ROADMAP.md with ONLY Overview + Phases checklist.
# Strips the entire ## Phase Details section. Use for skills that get phase info
# from structured gather data (execute-phase, progress, build, plan-phase, research-phase).
# Usage: cat_roadmap_compact [file]  (defaults to $P/ROADMAP.md)
cat_roadmap_compact() {
  local f="${1:-$P/ROADMAP.md}"
  if [ ! -f "$f" ]; then echo "(missing)"; return 1; fi
  awk '
    /^## Phase Details/ { exit }
    { print }
  ' "$f"
}

# emit_project_section: Emit === PROJECT === section (trimmed).
# Honors SKIP_PROJECT env var. Emits HAS_PROJECT flag.
emit_project_section() {
  echo "=== PROJECT ==="
  if [ -f "$P/PROJECT.md" ]; then
    echo "HAS_PROJECT=true"
    if [ "${SKIP_PROJECT:-}" = "1" ]; then
      echo "(in context)"
    else
      cat_project "$P/PROJECT.md"
    fi
  else
    echo "HAS_PROJECT=false"
    echo "(missing)"
  fi
}

# emit_roadmap_section: Emit === ROADMAP === section (trimmed).
# Honors SKIP_ROADMAP env var. Emits HAS_ROADMAP flag.
emit_roadmap_section() {
  echo "=== ROADMAP ==="
  if [ -f "$P/ROADMAP.md" ]; then
    echo "HAS_ROADMAP=true"
    if [ "${SKIP_ROADMAP:-}" = "1" ]; then
      echo "(in context)"
    else
      cat_roadmap "$P/ROADMAP.md"
    fi
  else
    echo "HAS_ROADMAP=false"
    echo "(missing)"
  fi
}

# emit_state_section: Emit === STATE === section.
# Honors SKIP_STATE env var. Emits HAS_STATE flag.
# CRITICAL: Stops reading at ### Decision Archive delimiter to keep
# archived decisions out of context.
emit_state_section() {
  echo "=== STATE ==="
  if [ -f "$P/STATE.md" ]; then
    echo "HAS_STATE=true"
    if [ "${SKIP_STATE:-}" = "1" ]; then
      echo "(in context)"
    else
      awk '/^### Decision Archive/ { exit } { print }' "$P/STATE.md"
    fi
  else
    echo "HAS_STATE=false"
    echo "(missing)"
  fi
}

# emit_phase_completion: Emit === PHASE_COMPLETION === section.
# Loops through .planning/phases/*/, counts *-PLAN.md and *-SUMMARY.md
# per directory, and emits status lines.
# Format: {dir_name}|{status}|plans={N}|summaries={N}
# Status: complete (summaries >= plans > 0), partial (summaries > 0 but < plans),
#         planned (plans > 0, summaries == 0), empty (no plans or summaries)
emit_phase_completion() {
  echo "=== PHASE_COMPLETION ==="
  if [ -d "$P/phases" ]; then
    for dir in "$P"/phases/*/; do
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
}

# emit_sync_check: Emit === SYNC_CHECK === section.
# Extracts phase numbers from directories, ROADMAP.json/md, STATE.json/md,
# and CHECKED/UNCHECKED phase lists from ROADMAP checkboxes.
emit_sync_check() {
  echo "=== SYNC_CHECK ==="

  # DIR_PHASES: always from filesystem (source of truth)
  echo -n "DIR_PHASES: "
  if [ -d "$P/phases" ]; then
    for dir in "$P"/phases/*/; do
      [ -d "$dir" ] || continue
      basename "$dir" | sed 's/^\([0-9.]*\)-.*/\1/' | sed 's/^0*//'
    done 2>/dev/null | sort -V | tr '\n' ' '
  fi
  echo

  # ROADMAP_PHASES: try JSON first
  echo -n "ROADMAP_PHASES: "
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/ROADMAP.json" ]; then
    jq -r '[.phases[].id] | sort_by(tonumber? // .) | .[]' "$P/ROADMAP.json" 2>/dev/null | tr '\n' ' '
    echo
  else
    grep -oE 'Phase [0-9]+(\.[0-9]+)?' "$P/ROADMAP.md" 2>/dev/null | awk '{print $2}' | sort -V | uniq | tr '\n' ' '
    echo
  fi

  # STATE_PHASE: try JSON first
  echo -n "STATE_PHASE: "
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/STATE.json" ]; then
    jq -r '.currentPosition.phase // empty' "$P/STATE.json" 2>/dev/null
  else
    grep -E '^Phase:' "$P/STATE.md" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1
  fi
  echo

  # CHECKED/UNCHECKED: try JSON first
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/ROADMAP.json" ]; then
    jq -r '.phases[] | select(.complete == true) | "CHECKED: \(.id)"' "$P/ROADMAP.json" 2>/dev/null
    jq -r '.phases[] | select(.complete == false) | "UNCHECKED: \(.id)"' "$P/ROADMAP.json" 2>/dev/null
  else
    grep -E '^\s*- \[x\] Phase' "$P/ROADMAP.md" 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "CHECKED: %s\n", $2}'
    grep -E '^\s*- \[ \] Phase' "$P/ROADMAP.md" 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "UNCHECKED: %s\n", $2}'
  fi
}

# emit_preferences: Emit === PREFERENCES === section.
# Extracts execution-model, simplifier, verification, and teams-available
# from STATE.json (JSON-first) or STATE.md (fallback), with defaults.
emit_preferences() {
  echo "=== PREFERENCES ==="
  if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/STATE.json" ]; then
    # JSON path: extract preferences with kebab-case keys
    jq -r '.preferences // {} | to_entries[] | "\(.key): \(.value)"' "$P/STATE.json" 2>/dev/null && {
      [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" = "1" ] && echo "teams-available: true" || echo "teams-available: false"
      return 0
    }
  fi
  # MD fallback (existing logic)
  grep -E '^execution-model:' "$P/STATE.md" 2>/dev/null || echo "execution-model: unset"
  grep -E '^simplifier:' "$P/STATE.md" 2>/dev/null || echo "simplifier: unset"
  grep -E '^verification:' "$P/STATE.md" 2>/dev/null || echo "verification: unset"
  [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" = "1" ] && echo "teams-available: true" || echo "teams-available: false"
}

# emit_structure: Emit === STRUCTURE === section.
# Checks existence of core planning files and emits HAS_* flags.
emit_structure() {
  echo "=== STRUCTURE ==="
  [ -d "$P" ] && echo "PLANNING_DIR=exists" || echo "PLANNING_DIR=missing"
  [ -f "$P/PROJECT.md" ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
  [ -f "$P/ROADMAP.md" ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
  [ -f "$P/STATE.md" ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
  [ -f "$P/SECURITY-AUDIT.md" ] && echo "HAS_SECURITY=true" || echo "HAS_SECURITY=false"
  [ -d "$P/codebase" ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"
  # JSON layer indicators
  [ -f "$P/PROJECT.json" ] && echo "HAS_PROJECT_JSON=true" || echo "HAS_PROJECT_JSON=false"
  [ -f "$P/ROADMAP.json" ] && echo "HAS_ROADMAP_JSON=true" || echo "HAS_ROADMAP_JSON=false"
  [ -f "$P/STATE.json" ] && echo "HAS_STATE_JSON=true" || echo "HAS_STATE_JSON=false"
  [ -f "$P/IDEAS.json" ] && echo "HAS_IDEAS_JSON=true" || echo "HAS_IDEAS_JSON=false"
}
