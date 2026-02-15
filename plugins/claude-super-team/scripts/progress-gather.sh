#!/usr/bin/env bash
# progress-gather.sh - Collect all planning data for the /progress skill
# Run from the project root (where .planning/ lives).
# Output is structured with === SECTION === markers for easy parsing.
#
# Sections:
#   STRUCTURE        - Which core planning files exist
#   PHASE_MAP        - Per-phase metrics (plans, summaries, gaps, context, research)
#   SYNC_CHECK       - Pre-computed phase number lists for sync issue detection
#   RECENT_SUMMARIES - 3 most recently modified summary files with excerpts
#   GIT              - Recent commits, current branch, dirty file count

set -uo pipefail

P=".planning"
PH="$P/phases"

# --- STRUCTURE ---
echo "=== STRUCTURE ==="
if [ ! -d "$P" ]; then
  echo "PLANNING_DIR=missing"
  exit 0
fi
echo "PLANNING_DIR=exists"
[ -f "$P/PROJECT.md" ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f "$P/ROADMAP.md" ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f "$P/STATE.md" ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
[ -f "$P/SECURITY-AUDIT.md" ] && echo "HAS_SECURITY=true" || echo "HAS_SECURITY=false"

# --- PHASE MAP ---
echo ""
echo "=== PHASE_MAP ==="
for dir in "$PH"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  plans=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d ' ')
  summaries=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d ' ')
  gaps=$(grep -l "status: gaps_found" "$dir"*-VERIFICATION.md 2>/dev/null | wc -l | tr -d ' ')
  context=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d ' ')
  research=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "$name|plans=$plans|summaries=$summaries|gaps=$gaps|context=$context|research=$research"
done 2>/dev/null

# --- SYNC CHECK ---
echo ""
echo "=== SYNC_CHECK ==="
# Phase numbers from directories (strip leading zeros)
echo -n "DIR_PHASES: "
for dir in "$PH"/*/; do
  [ -d "$dir" ] || continue
  basename "$dir" | sed 's/^\([0-9.]*\)-.*/\1/' | sed 's/^0*//'
done 2>/dev/null | sort -V | tr '\n' ' '
echo

# Phase numbers from ROADMAP.md
echo -n "ROADMAP_PHASES: "
grep -oE 'Phase [0-9]+(\.[0-9]+)?' "$P/ROADMAP.md" 2>/dev/null | awk '{print $2}' | sort -V | uniq | tr '\n' ' '
echo

# Current phase from STATE.md (matches "Phase: N of M" or "Phase: N")
echo -n "STATE_PHASE: "
grep -E '^Phase:' "$P/STATE.md" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1

# Checked/unchecked phases from ROADMAP.md checklist
grep -E '^\s*- \[x\] Phase' "$P/ROADMAP.md" 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "CHECKED: %s\n", $2}'
grep -E '^\s*- \[ \] Phase' "$P/ROADMAP.md" 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "UNCHECKED: %s\n", $2}'

# --- RECENT SUMMARIES ---
echo ""
echo "=== RECENT_SUMMARIES ==="
if [ -d "$PH" ]; then
  find "$PH" -name "*-SUMMARY.md" -type f 2>/dev/null \
    | xargs ls -t 2>/dev/null \
    | head -3 \
    | while IFS= read -r f; do
        rel="${f#"$PH"/}"
        excerpt=$(grep -m1 -vE '^(#|---|[[:space:]]*$)' "$f" 2>/dev/null | head -c 120)
        echo "$rel|$excerpt"
      done
fi

# --- GIT ---
echo ""
echo "=== GIT ==="
git log --oneline -5 2>/dev/null || echo "(no git history)"
echo "---"
echo "BRANCH=$(git branch --show-current 2>/dev/null || echo 'detached')"
echo "DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
