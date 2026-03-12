#!/usr/bin/env bash
# phase-utils.sh - Shared phase number normalization and directory resolution
#
# Sourced by skills via:
#   source "${CLAUDE_PLUGIN_ROOT}/scripts/phase-utils.sh"
#
# Provides two functions:
#   normalize_phase <raw_phase_number>  - Zero-pad phase number (stdout)
#   find_phase_dir  <normalized_phase>  - Resolve phase directory path (stdout)

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
