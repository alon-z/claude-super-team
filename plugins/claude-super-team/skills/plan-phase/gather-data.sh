#!/usr/bin/env bash
# gather-data.sh - Pre-compute phase planning status for /plan-phase
# Outputs structured sections that the skill LLM parses.
# Env vars: SKIP_PROJECT, SKIP_ROADMAP, SKIP_STATE, SKIP_CODEBASE (set to "1" to skip)
#           PHASE_NUM (e.g. "5" or "2.1") - target phase for trimmed sections
#           PHASE_DIR (e.g. ".planning/phases/05-workflow-validation") - for phase-specific files

source "$(dirname "$0")/../../scripts/gather-common.sh"

ROADMAP_FILE=".planning/ROADMAP.md"
STATE_FILE=".planning/STATE.md"

# --- Existing sections (backward compatible) ---

echo "=== PROJECT ==="
if [ "${SKIP_PROJECT:-}" = "1" ]; then echo "(in context)"; else
  cat .planning/PROJECT.md 2>/dev/null || echo "(missing)"
fi
echo "=== ROADMAP ==="
if [ "${SKIP_ROADMAP:-}" = "1" ]; then echo "(in context)"; else
  cat "$ROADMAP_FILE" 2>/dev/null || echo "(missing)"
fi
echo "=== STATE ==="
if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else
  cat "$STATE_FILE" 2>/dev/null || echo "(missing)"
fi

# Per-phase planning status (critical for --all mode)
echo "=== PHASE_STATUS ==="
if [ -d .planning/phases ]; then
  for dir in .planning/phases/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    plans=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " ")
    context=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d " ")
    research=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d " ")
    verification=$(find "$dir" -maxdepth 1 -name "*-VERIFICATION.md" 2>/dev/null | wc -l | tr -d " ")
    echo "${name}|plans=${plans}|context=${context}|research=${research}|verification=${verification}"
  done
fi

# Roadmap phase headings (for detecting unplanned ones)
echo "=== ROADMAP_PHASES ==="
grep -E "^#+.*Phase [0-9]+(\.[0-9]+)?" "$ROADMAP_FILE" 2>/dev/null

# --- New pre-assembled context sections ---

# ROADMAP_TRIMMED: Only the phases list + target phase detail block
echo "=== ROADMAP_TRIMMED ==="
if [ -z "${PHASE_NUM:-}" ]; then
  echo "(no phase specified -- use full roadmap)"
elif [ ! -f "$ROADMAP_FILE" ]; then
  echo "(missing)"
else
  # Extract ## Phases list (from "## Phases" to next "##" heading)
  echo "--- Phases Overview ---"
  awk '
    /^## Phases/ { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$ROADMAP_FILE" 2>/dev/null

  # Extract ### Phase N detail block (from "### Phase {PHASE_NUM}:" to next "###" or EOF)
  echo ""
  echo "--- Phase ${PHASE_NUM} Detail ---"
  awk -v pnum="$PHASE_NUM" '
    /^### Phase / {
      line = $0
      sub(/^### Phase /, "", line)
      sub(/:.*/, "", line)
      gsub(/ .*/, "", line)
      if (line == pnum) { found=1; print; next }
      else if (found) { exit }
    }
    found { print }
  ' "$ROADMAP_FILE" 2>/dev/null
fi

# STATE_TRIMMED: Only Current Position, Preferences, and Accumulated Context
echo "=== STATE_TRIMMED ==="
if [ "${SKIP_STATE:-}" = "1" ]; then echo "(in context)"; else
  if [ ! -f "$STATE_FILE" ]; then
    echo "(missing)"
  else
    # Extract Current Position, Preferences, and Accumulated Context using state-based awk
    awk '
      /^## Current Position/ { section=1; print; next }
      /^## Preferences/ { section=1; print; next }
      /^## Accumulated Context/ { section=1; print; next }
      section && /^## / { section=0; next }
      section && /^---$/ { section=0; next }
      section { print }
    ' "$STATE_FILE" 2>/dev/null
  fi
fi

# CODEBASE_DOCS: Aggregated planning-relevant codebase docs
echo "=== CODEBASE_DOCS ==="
if [ "${SKIP_CODEBASE:-}" = "1" ]; then echo "(in context)"; else
  if [ ! -d .planning/codebase ]; then
    echo "(no codebase docs)"
  else
    for doc in ARCHITECTURE.md STACK.md CONVENTIONS.md STRUCTURE.md; do
      if [ -f ".planning/codebase/$doc" ]; then
        echo "--- $doc ---"
        cat ".planning/codebase/$doc"
        echo ""
      fi
    done
  fi
fi

# PHASE_CONTEXT: Phase-specific CONTEXT.md content
echo "=== PHASE_CONTEXT ==="
if [ -n "${PHASE_DIR:-}" ]; then
  ctx_file=$(ls "${PHASE_DIR}"/*-CONTEXT.md 2>/dev/null | head -1)
  if [ -n "$ctx_file" ]; then
    cat "$ctx_file"
  else
    echo "(none)"
  fi
else
  echo "(none)"
fi

# PHASE_RESEARCH: Phase-specific RESEARCH.md content
echo "=== PHASE_RESEARCH ==="
if [ -n "${PHASE_DIR:-}" ]; then
  res_file=$(ls "${PHASE_DIR}"/*-RESEARCH.md 2>/dev/null | head -1)
  if [ -n "$res_file" ]; then
    cat "$res_file"
  else
    echo "(none)"
  fi
else
  echo "(none)"
fi

# PHASE_REQUIREMENTS: Project-level requirements
echo "=== PHASE_REQUIREMENTS ==="
if [ -f .planning/REQUIREMENTS.md ]; then
  cat .planning/REQUIREMENTS.md
else
  echo "(none)"
fi
