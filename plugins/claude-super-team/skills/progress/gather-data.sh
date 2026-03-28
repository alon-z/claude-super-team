#!/usr/bin/env bash
# gather-data.sh - Gather planning structure data for /progress skill
# Called via dynamic context injection in SKILL.md
#
# Optimized for token efficiency: emits compact structured data, not full prose.
# Uses JSON companions when available, MD fallback otherwise.

P=.planning
source "$(dirname "$0")/../../scripts/gather-common.sh"

# Progress-optimized: only emit what this skill actually uses
# - Project: only need the name for the header
# - Roadmap: phases list is sufficient, overview prose goes stale
# - State: position + preferences, not dev-note blockers/decisions
SLIM_NAME_ONLY=1 emit_project_slim
SLIM_SKIP_OVERVIEW=1 emit_roadmap_slim
SLIM_SKIP_DECISIONS=1 SLIM_SKIP_BLOCKERS=1 emit_state_slim

echo "=== SECURITY_AUDIT ==="
if [ -f "$P/SECURITY-AUDIT.md" ]; then
  echo "HAS_SECURITY=true"
  # Only severity counts, not full content
  echo "CRITICAL=$(grep -ci 'critical' "$P/SECURITY-AUDIT.md" 2>/dev/null || echo 0)"
  echo "HIGH=$(grep -ci 'high' "$P/SECURITY-AUDIT.md" 2>/dev/null || echo 0)"
  echo "MEDIUM=$(grep -ci 'medium' "$P/SECURITY-AUDIT.md" 2>/dev/null || echo 0)"
  echo "LOW=$(grep -ci 'low' "$P/SECURITY-AUDIT.md" 2>/dev/null || echo 0)"
else
  echo "HAS_SECURITY=false"
fi

# === DEPENDENCIES ===
# Only emit phases that have real dependencies (skip {phase}|none noise)
echo "=== DEPENDENCIES ==="
if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/ROADMAP.json" ]; then
  jq -r '.phases[] | select(.dependsOn | length > 0) | "\(.id)|\(.dependsOn | join(","))"' "$P/ROADMAP.json" 2>/dev/null
elif [ -f "$P/ROADMAP.md" ]; then
  awk '
    /^### Phase [0-9]/ {
      phase = $0
      sub(/.*Phase /, "", phase)
      sub(/[^0-9.].*/, "", phase)
    }
    /^\*\*Depends on\*\*:/ {
      dep = $0
      sub(/.*\*\*Depends on\*\*: */, "", dep)
      if (dep ~ /[Nn]othing/ || dep ~ /^-$/ || dep == "") { next }
      result = ""
      n = split(dep, parts, /[,;]/)
      for (i = 1; i <= n; i++) {
        if (match(parts[i], /[0-9]+(\.[0-9]+)?/)) {
          num = substr(parts[i], RSTART, RLENGTH)
          result = (result == "" ? num : result "," num)
        }
      }
      if (result != "" && result != "none") print phase "|" result
    }
  ' "$P/ROADMAP.md"
fi

# === STRUCTURE ===
emit_structure

# === PHASE_MAP ===
echo "=== PHASE_MAP ==="
if [ -d ".planning/phases" ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    n=$(basename "$dir")
    p=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " ")
    s=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " ")
    g=$(grep -l "status: gaps_found" "${dir}"*-VERIFICATION.md 2>/dev/null | wc -l | tr -d " ")
    c=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d " ")
    r=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d " ")
    echo "$n|plans=$p|summaries=$s|gaps=$g|context=$c|research=$r"
  done
fi

# === RECENT_SUMMARIES ===
echo "=== RECENT_SUMMARIES ==="
if [ -d ".planning/phases" ]; then
  find .planning/phases -name "*-SUMMARY.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -3 | while IFS= read -r f; do
    rel=${f#.planning/phases/}
    exc=$(grep -m1 -vE "^(#|---|[[:space:]]*$)" "$f" 2>/dev/null | head -c 120)
    echo "$rel|$exc"
  done
fi

# === SYNC_CHECK ===
emit_sync_check

# === BUILD ===
echo "=== BUILD ==="
if [ -f "$P/BUILD-STATE.md" ]; then
  echo "HAS_BUILD_STATE=true"
  status=$(grep -E '^- \*\*Status:\*\*' "$P/BUILD-STATE.md" 2>/dev/null | head -1 | sed 's/.*\*\* //')
  echo "BUILD_STATUS=$status"
  stage=$(grep -E '^- \*\*Current stage:\*\*' "$P/BUILD-STATE.md" 2>/dev/null | head -1 | sed 's/.*\*\* //')
  echo "BUILD_STAGE=$stage"
  phase=$(grep -E '^- \*\*Current phase:\*\*' "$P/BUILD-STATE.md" 2>/dev/null | head -1 | sed 's/.*\*\* //')
  echo "BUILD_PHASE=$phase"
  compactions=$(grep -E '^- \*\*Compaction count:\*\*' "$P/BUILD-STATE.md" 2>/dev/null | head -1 | sed 's/.*\*\* //')
  echo "BUILD_COMPACTIONS=$compactions"
  started=$(grep -E '^- \*\*Started:\*\*' "$P/BUILD-STATE.md" 2>/dev/null | head -1 | sed 's/.*\*\* //')
  echo "BUILD_STARTED=$started"
  input=$(grep -E '^- \*\*Input:\*\*' "$P/BUILD-STATE.md" 2>/dev/null | head -1 | sed 's/.*\*\* //' | head -c 100)
  echo "BUILD_INPUT=$input"
  echo "BUILD_PIPELINE:"
  awk '/## Pipeline Progress/,/^## [^P]/' "$P/BUILD-STATE.md" 2>/dev/null | grep '^|' | grep -v '^\| Stage' | grep -v '^|---' | sed 's/| */|/g; s/ *|/|/g'
  echo "BUILD_INCOMPLETE:"
  awk '/## Incomplete Phases/,/^## /' "$P/BUILD-STATE.md" 2>/dev/null | grep -v '^#' | grep -v '^$' | head -5
else
  echo "HAS_BUILD_STATE=false"
fi

# === GIT ===
echo "=== GIT ==="
git log --oneline -5 2>/dev/null || echo "(no git)"
echo "---"
echo "BRANCH=$(git branch --show-current 2>/dev/null || echo detached)"
echo "DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
