#!/usr/bin/env bash
# gather-data.sh - Pre-load BUILD-STATE.md, preferences, and git status for /build skill
# Called via dynamic context injection in SKILL.md

# === BUILD_STATE ===
echo "=== BUILD_STATE ==="
if [ -f .planning/BUILD-STATE.md ]; then
  echo "EXISTS=true"
  cat .planning/BUILD-STATE.md
else
  echo "EXISTS=false"
fi

# === PREFERENCES ===
echo "=== PREFERENCES ==="
if [ -f "$HOME/.claude/build-preferences.md" ]; then
  echo "GLOBAL_PREFS=true"
  cat "$HOME/.claude/build-preferences.md"
else
  echo "GLOBAL_PREFS=false"
fi
if [ -f .planning/build-preferences.md ]; then
  echo "PROJECT_PREFS=true"
  cat .planning/build-preferences.md
else
  echo "PROJECT_PREFS=false"
fi

# === GIT ===
echo "=== GIT ==="
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "GIT_AVAILABLE=true"
  echo "BRANCH=$(git branch --show-current 2>/dev/null || echo detached)"
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "HAS_UNCOMMITTED=1"
  else
    echo "HAS_UNCOMMITTED=0"
  fi
  echo "BUILD_BRANCHES:"
  git branch --list 'build/*' 2>/dev/null | sed 's/^[* ]*/  /'
else
  echo "GIT_AVAILABLE=false"
  echo "BRANCH=none"
fi

# === PROJECT ===
echo "=== PROJECT ==="
[ -f .planning/PROJECT.md ] && HAS_PROJECT=true || HAS_PROJECT=false
[ -f .planning/ROADMAP.md ] && HAS_ROADMAP=true || HAS_ROADMAP=false
echo "HAS_PROJECT=$HAS_PROJECT"
if [ "$HAS_PROJECT" = "true" ]; then
  if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else cat .planning/PROJECT.md; fi
fi
echo "HAS_ROADMAP=$HAS_ROADMAP"
if [ "$HAS_ROADMAP" = "true" ]; then
  if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else cat .planning/ROADMAP.md; fi
fi
if [ -f .planning/STATE.md ]; then
  echo "HAS_STATE=true"
  if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else cat .planning/STATE.md; fi
else
  echo "HAS_STATE=false"
fi
[ -d .planning/codebase ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"

# === PHASE_COMPLETION === (filesystem source of truth for phase status)
echo "=== PHASE_COMPLETION ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
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

# === EXTEND ===
echo "=== EXTEND ==="
if [ -f .planning/BUILD-STATE.md ]; then
  STATUS=$(grep -m1 "^\- \*\*Status:\*\*" .planning/BUILD-STATE.md | sed 's/.*\*\* //')
  if [ "$STATUS" = "complete" ] && [ "$HAS_PROJECT" = "true" ] && [ "$HAS_ROADMAP" = "true" ]; then
    echo "EXTEND_CANDIDATE=true"
  else
    echo "EXTEND_CANDIDATE=false"
  fi
else
  echo "EXTEND_CANDIDATE=false"
fi

# === BROWNFIELD ===
echo "=== BROWNFIELD ==="
CODE_FILES=$(find . -maxdepth 3 -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
echo "CODE_FILES=$CODE_FILES"
