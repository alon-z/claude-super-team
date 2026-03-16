#!/usr/bin/env bash
# phase-utils.sh - Shared phase number normalization and directory resolution
#
# Sourced by skills via:
#   source "${CLAUDE_PLUGIN_ROOT}/scripts/phase-utils.sh"
#
# Provides three functions:
#   normalize_phase <raw_phase_number>  - Zero-pad phase number (stdout)
#   find_phase_dir  <normalized_phase>  - Resolve phase directory path (stdout)
#   create_phase_dir <raw_phase_number> - Create phase directory from ROADMAP.md name (stdout)
#
# create_phase_dir examples:
#   create_phase_dir 9      -> .planning/phases/09-script-consolidation-state-compaction
#   create_phase_dir 2.1    -> .planning/phases/02.1-security-hardening
#   create_phase_dir 02     -> .planning/phases/02-skill-audit-and-reclassification  (existing)
#
# Slugification handles:
#   "Build Skill Efficiency (QUICK)" -> "build-skill-efficiency-quick"
#   "Phase Name [COMPLETE]"          -> "phase-name"
#   Trailing dashes, multiple consecutive hyphens, special chars

# normalize_phase: Accept a raw phase number and print the zero-padded form.
#
# Examples:
#   normalize_phase 2     -> 02
#   normalize_phase 2.1   -> 02.1
#   normalize_phase 2.10  -> 02.10
#   normalize_phase 10    -> 10
#   normalize_phase 10.3  -> 10.3
#   normalize_phase 02    -> 02
#   normalize_phase 02.1  -> 02.1
normalize_phase() {
  local input="$1"
  if echo "$input" | grep -q '\.'; then
    local int_part dec_part
    int_part=$(echo "$input" | cut -d. -f1)
    dec_part=$(echo "$input" | cut -d. -f2-)
    printf "%02d.%s" "$int_part" "$dec_part"
  else
    printf "%02d" "$input"
  fi
}

# find_phase_dir: Accept a normalized phase string and print the matching
# directory path under .planning/phases/. Prints nothing if no match found.
#
# Examples:
#   find_phase_dir 02    -> .planning/phases/02-auth  (if exists)
#   find_phase_dir 02.1  -> .planning/phases/02.1-security-hardening  (if exists)
find_phase_dir() {
  local phase="$1"
  ls -d .planning/phases/${phase}-* 2>/dev/null | head -1
}

# create_phase_dir: Accept a raw phase number, derive the phase name from
# ROADMAP.md, create the directory under .planning/phases/, and print the path.
#
# If the directory already exists, prints the existing path and returns 0.
# Returns 1 if the phase is not found in ROADMAP.md.
create_phase_dir() {
  local raw="$1"
  local padded
  padded=$(normalize_phase "$raw")

  # Check if directory already exists
  local existing
  existing=$(find_phase_dir "$padded")
  if [ -n "$existing" ]; then
    echo "$existing"
    return 0
  fi

  # Extract phase name from ROADMAP.md
  # Try both raw and padded forms: "Phase 9:" and "Phase 09:"
  local phase_line
  phase_line=$(grep -E "Phase ${raw}:" .planning/ROADMAP.md 2>/dev/null | head -1)
  if [ -z "$phase_line" ]; then
    phase_line=$(grep -E "Phase ${padded}:" .planning/ROADMAP.md 2>/dev/null | head -1)
  fi

  if [ -z "$phase_line" ]; then
    return 1
  fi

  # Extract the text after "Phase N:" -- the phase name
  local phase_name
  phase_name=$(echo "$phase_line" | sed 's/.*Phase [0-9.]*: *//')

  # Slugify: strip [COMPLETE] tag, strip markdown bold markers, strip special chars,
  # lowercase, spaces to hyphens, collapse multiple hyphens, strip trailing hyphens
  local slug
  slug=$(echo "$phase_name" \
    | sed 's/\[COMPLETE\]//g' \
    | sed 's/\*\*//g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 -]/ /g' \
    | sed 's/  */ /g' \
    | sed 's/ /-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//' \
    | sed 's/-$//' \
    | cut -c1-40 \
    | sed 's/-$//')

  local dir_path=".planning/phases/${padded}-${slug}"
  mkdir -p "$dir_path"
  echo "$dir_path"
  return 0
}
