#!/usr/bin/env bash
# gather-data.sh - Gather planning structure data for /progress skill
# Called via dynamic context injection in SKILL.md

P=.planning
source "$(dirname "$0")/../../scripts/gather-common.sh"

echo "=== PROJECT ==="
if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else
  cat_project "$P/PROJECT.md"
fi
echo "=== ROADMAP ==="
if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else
  cat_roadmap_compact "$P/ROADMAP.md"
fi
echo "=== STATE ==="
if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else
  cat "$P/STATE.md" 2>/dev/null || echo "(missing)"
fi
echo "=== SECURITY_AUDIT ==="
head -20 "$P/SECURITY-AUDIT.md" 2>/dev/null || echo "(missing)"
echo "=== BUILD_STATE_FILE ==="
cat "$P/BUILD-STATE.md" 2>/dev/null || echo "(missing)"

# === DEPENDENCIES ===
echo "=== DEPENDENCIES ==="
if [ -f "$P/ROADMAP.md" ]; then
  # Extract phase number and "Depends on" value for each phase
  awk '
    /^### Phase [0-9]/ {
      # Extract phase number: strip everything before "Phase " and after the number
      phase = $0
      sub(/.*Phase /, "", phase)
      sub(/[^0-9.].*/, "", phase)
    }
    /^\*\*Depends on\*\*:/ {
      dep = $0
      sub(/.*\*\*Depends on\*\*: */, "", dep)
      # Extract phase numbers from dependency string
      if (dep ~ /[Nn]othing/ || dep ~ /^-$/ || dep == "") {
        print phase "|none"
      } else {
        # Pull all phase numbers from the dependency string
        result = ""
        n = split(dep, parts, /[,;]/)
        for (i = 1; i <= n; i++) {
          if (match(parts[i], /[0-9]+(\.[0-9]+)?/)) {
            num = substr(parts[i], RSTART, RLENGTH)
            result = (result == "" ? num : result "," num)
          }
        }
        if (result == "") result = "none"
        print phase "|" result
      }
    }
  ' "$P/ROADMAP.md"
fi

# === STRUCTURE ===
echo "=== STRUCTURE ==="
[ -d "$P" ] && echo "PLANNING_DIR=exists" || echo "PLANNING_DIR=missing"
[ -f "$P/PROJECT.md" ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f "$P/ROADMAP.md" ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f "$P/STATE.md" ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
[ -f "$P/SECURITY-AUDIT.md" ] && echo "HAS_SECURITY=true" || echo "HAS_SECURITY=false"

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
  # Extract pipeline progress rows (stage|status format)
  echo "BUILD_PIPELINE:"
  awk '/## Pipeline Progress/,/^## [^P]/' "$P/BUILD-STATE.md" 2>/dev/null | grep '^|' | grep -v '^\| Stage' | grep -v '^|---' | sed 's/| */|/g; s/ *|/|/g'
  # Count incomplete phases
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
