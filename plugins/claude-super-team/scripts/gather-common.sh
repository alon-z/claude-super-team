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

# emit_project_section: Emit === PROJECT === section.
# Honors SKIP_PROJECT env var. Emits HAS_PROJECT flag.
emit_project_section() {
  echo "=== PROJECT ==="
  if [ -f "$P/PROJECT.md" ]; then
    echo "HAS_PROJECT=true"
    if [ "${SKIP_PROJECT:-}" = "1" ]; then
      echo "(in context)"
    else
      cat "$P/PROJECT.md"
    fi
  else
    echo "HAS_PROJECT=false"
    echo "(missing)"
  fi
}

# emit_roadmap_section: Emit === ROADMAP === section.
# Honors SKIP_ROADMAP env var. Emits HAS_ROADMAP flag.
emit_roadmap_section() {
  echo "=== ROADMAP ==="
  if [ -f "$P/ROADMAP.md" ]; then
    echo "HAS_ROADMAP=true"
    if [ "${SKIP_ROADMAP:-}" = "1" ]; then
      echo "(in context)"
    else
      cat "$P/ROADMAP.md"
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
# Extracts phase numbers from directories, ROADMAP.md, STATE.md,
# and CHECKED/UNCHECKED phase lists from ROADMAP.md checkboxes.
emit_sync_check() {
  echo "=== SYNC_CHECK ==="
  echo -n "DIR_PHASES: "
  if [ -d "$P/phases" ]; then
    for dir in "$P"/phases/*/; do
      [ -d "$dir" ] || continue
      basename "$dir" | sed 's/^\([0-9.]*\)-.*/\1/' | sed 's/^0*//'
    done 2>/dev/null | sort -V | tr '\n' ' '
  fi
  echo

  echo -n "ROADMAP_PHASES: "
  grep -oE 'Phase [0-9]+(\.[0-9]+)?' "$P/ROADMAP.md" 2>/dev/null | awk '{print $2}' | sort -V | uniq | tr '\n' ' '
  echo

  echo -n "STATE_PHASE: "
  grep -E '^Phase:' "$P/STATE.md" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1
  echo

  grep -E '^\s*- \[x\] Phase' "$P/ROADMAP.md" 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "CHECKED: %s\n", $2}'
  grep -E '^\s*- \[ \] Phase' "$P/ROADMAP.md" 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "UNCHECKED: %s\n", $2}'
}

# emit_preferences: Emit === PREFERENCES === section.
# Extracts execution-model, simplifier, verification, and teams-available
# from STATE.md and environment, with fallback defaults.
emit_preferences() {
  echo "=== PREFERENCES ==="
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
}
