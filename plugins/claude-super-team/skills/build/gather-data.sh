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
[ -f .planning/PROJECT.md ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f .planning/STATE.md ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
[ -d .planning/codebase ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"

# === BROWNFIELD ===
echo "=== BROWNFIELD ==="
CODE_FILES=$(find . -maxdepth 3 -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
echo "CODE_FILES=$CODE_FILES"
