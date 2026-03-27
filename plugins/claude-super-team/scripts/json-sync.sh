#!/usr/bin/env bash
# json-sync.sh - Convert .planning/ MD files to JSON and validate structure
#
# Usage:
#   json-sync.sh [--all|project|roadmap|state|ideas|--validate|--help]
#
# Converts existing .planning/ Markdown files into their JSON counterparts.
# MD remains source of truth; JSON is always derived from MD content.
# Requires jq.

set -euo pipefail

P="${P:-.planning}"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required but not installed"; exit 1; }

# Atomic JSON write: validates then moves into place
write_json() {
  local target="$1"
  local content="$2"
  local tmp="${target}.tmp"
  if echo "$content" | jq -e '.' > "$tmp" 2>/dev/null; then
    mv "$tmp" "$target"
    return 0
  else
    rm -f "$tmp"
    echo "ERROR: Invalid JSON for $target"
    return 1
  fi
}

# ── sync_project ─────────────────────────────────────────────────────────────
# Converts PROJECT.md -> PROJECT.json
sync_project() {
  local src="$P/PROJECT.md"
  [ -f "$src" ] || return 0

  # Extract project name from first # heading
  local project_name
  project_name=$(awk '/^# / { sub(/^# */, ""); print; exit }' "$src")

  # Extract description from ## What This Is section
  local description
  description=$(awk '
    /^## What This Is/ { found=1; next }
    found && /^##/ { exit }
    found && /[^ ]/ { print }
  ' "$src" | head -20 | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')

  # Extract core value
  local core_value
  core_value=$(grep -E '^\*\*Core value:\*\*|^Core value:' "$src" 2>/dev/null | head -1 | sed 's/.*Core value:\*\* *//; s/^Core value: *//')

  # Extract validated requirements (from ### Validated section with [x] or checkmarks)
  local req_validated
  req_validated=$(awk '
    /^### Validated/ { found=1; next }
    found && /^###/ { found=0 }
    found && /^- \[x\]/ { sub(/^- \[x\] */, ""); printf "%s\n", $0 }
    found && /^- / && !/^\- \[/ { sub(/^- */, ""); printf "%s\n", $0 }
  ' "$src" | jq -Rs 'split("\n") | map(select(length > 0)) | map({text: ., complete: true})')

  # Extract active requirements
  local req_active
  req_active=$(awk '
    /^### Active/ { found=1; next }
    found && /^###/ { found=0 }
    found && /^- \[ \]/ { sub(/^- \[ \] */, ""); printf "%s\n", $0 }
  ' "$src" | jq -Rs 'split("\n") | map(select(length > 0)) | map({text: ., complete: false})')

  # Extract out of scope
  local req_oos
  req_oos=$(awk '
    /^### Out of Scope/ { found=1; next }
    found && /^##/ { found=0 }
    found && /^- / { sub(/^- */, ""); printf "%s\n", $0 }
  ' "$src" | jq -Rs 'split("\n") | map(select(length > 0))')

  # Extract constraints
  local constraints
  constraints=$(awk '
    /^## Constraints/ { found=1; next }
    found && /^##/ { found=0 }
    found && /^- / { sub(/^- */, ""); gsub(/\*\*/, ""); printf "%s\n", $0 }
  ' "$src" | jq -Rs 'split("\n") | map(select(length > 0))')

  # Extract decisions table (pipe-delimited, skip header+separator)
  local decisions
  decisions=$(awk '
    /^## Key Decisions/ { found=1; next }
    found && /^##/ { found=0 }
    found && /^\|/ && !/^\| *Decision/ && !/^\|[-|]/ {
      sub(/^\| */, "")
      sub(/ *\| *$/, "")
      printf "%s\n", $0
    }
  ' "$src" | while IFS='|' read -r dec rat out; do
    dec=$(echo "$dec" | sed 's/^ *//;s/ *$//')
    rat=$(echo "$rat" | sed 's/^ *//;s/ *$//')
    out=$(echo "$out" | sed 's/^ *//;s/ *$//')
    printf '%s|%s|%s\n' "$dec" "$rat" "$out"
  done | jq -Rs '
    split("\n") | map(select(length > 0)) | map(
      split("|") | {decision: .[0], rationale: .[1], outcome: .[2]}
    )
  ')

  # Extract execution-model from Preferences section
  local exec_model
  exec_model=$(awk '
    /^## Preferences/ { found=1; next }
    found && /^##/ { found=0 }
    found && /^execution-model:/ { sub(/^execution-model: */, ""); print; exit }
  ' "$src")
  [ -z "$exec_model" ] && exec_model="unset"

  # Extract last updated
  local last_updated
  last_updated=$(grep -E '^\*Last updated:' "$src" 2>/dev/null | head -1 | sed 's/^\*Last updated: *//; s/\*$//' || echo "")

  local json
  json=$(jq -n \
    --arg name "$project_name" \
    --arg desc "$description" \
    --arg core "$core_value" \
    --argjson reqVal "$req_validated" \
    --argjson reqAct "$req_active" \
    --argjson reqOos "$req_oos" \
    --argjson cons "$constraints" \
    --argjson decs "$decisions" \
    --arg model "$exec_model" \
    --arg updated "$last_updated" \
    '{
      projectName: $name,
      description: $desc,
      coreValue: $core,
      requirements: {
        validated: $reqVal,
        active: $reqAct,
        outOfScope: $reqOos
      },
      constraints: $cons,
      decisions: $decs,
      preferences: { executionModel: $model },
      lastUpdated: $updated
    }')

  write_json "$P/PROJECT.json" "$json"
}

# ── sync_roadmap ─────────────────────────────────────────────────────────────
# Converts ROADMAP.md -> ROADMAP.json
sync_roadmap() {
  local src="$P/ROADMAP.md"
  [ -f "$src" ] || return 0

  # Extract overview paragraph
  local overview
  overview=$(awk '
    /^## Overview/ { found=1; next }
    found && /^##/ { exit }
    found && /[^ ]/ { print }
  ' "$src" | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')

  # Extract phases from checkbox list
  local phases
  phases=$(awk '
    /^## Phases/ { found=1; next }
    found && /^## / { exit }
    found && /^\s*- \[.\]/ {
      checked = (index($0, "[x]") > 0) ? "true" : "false"
      line = $0
      # Extract phase id
      if (match(line, /Phase [0-9]+(\.[0-9]+)?/)) {
        id = substr(line, RSTART+6, RLENGTH-6)
      } else {
        next
      }
      # Extract name: everything after "Phase N: " or "Phase N.N: "
      name = line
      sub(/.*Phase [0-9]+(\.[0-9]+)?: */, "", name)
      # Clean up markdown formatting
      gsub(/\*\*/, "", name)
      # Remove trailing annotations like [Sprint N] [S/M/L] (QUICK) etc
      sub(/ *\[Sprint [0-9]+\].*$/, "", name)
      sub(/ *\(QUICK\).*$/, "", name)
      sub(/ *-- .*$/, "", name)
      sub(/ *\[COMPLETE\].*$/, "", name)
      # Trim
      gsub(/^ +| +$/, "", name)
      printf "%s|%s|%s\n", id, checked, name
    }
  ' "$src" | jq -Rs '
    split("\n") | map(select(length > 0)) | map(
      split("|") | {id: .[0], complete: (.[1] == "true"), name: .[2]}
    )
  ')

  # Extract phase details from ### Phase sections
  local details
  details=$(awk '
    /^### Phase [0-9]/ {
      if (id != "") {
        printf "%s|%s|%s|%s|%s|%s\n", id, goal, depends, sprint, size, ptype
      }
      seen = 1
      # Extract id from heading
      line = $0
      if (match(line, /Phase [0-9]+(\.[0-9]+)?/)) {
        id = substr(line, RSTART+6, RLENGTH-6)
      }
      goal = ""; depends = ""; sprint = ""; size = ""; ptype = ""
      in_sc = 0
      next
    }
    seen && /^## / && !/^### / {
      if (id != "") {
        printf "%s|%s|%s|%s|%s|%s\n", id, goal, depends, sprint, size, ptype
      }
      id = ""
      exit
    }
    id != "" && /^\*\*Goal\*\*:/ {
      goal = $0
      sub(/.*\*\*Goal\*\*: */, "", goal)
      sub(/^\*\*Goal:\*\* */, "", goal)
    }
    id != "" && /^\*\*Depends on\*\*:/ {
      depends = $0
      sub(/.*\*\*Depends on\*\*: */, "", depends)
    }
    id != "" && /^\*\*Sprint\*\*:/ {
      sprint = $0
      sub(/.*\*\*Sprint\*\*: */, "", sprint)
    }
    id != "" && /^\*\*Size\*\*:/ {
      size = $0
      sub(/.*\*\*Size\*\*: */, "", size)
    }
    id != "" && /^\*\*Type:\*\*/ {
      ptype = $0
      sub(/.*\*\*Type:\*\* */, "", ptype)
    }
    END {
      if (id != "") {
        printf "%s|%s|%s|%s|%s|%s\n", id, goal, depends, sprint, size, ptype
      }
    }
  ' "$src" | jq -Rs '
    split("\n") | map(select(length > 0)) | map(
      split("|") | {
        id: .[0],
        goal: (if .[1] == "" then null else .[1] end),
        dependsOn: (if .[2] == "" then [] elif .[2] == "Nothing (first phase)" then [] else [.[2]] end),
        sprint: (if .[3] == "" then null else (.[3] | tonumber? // null) end),
        size: (if .[4] == "" then null else .[4] end),
        type: (if .[5] == "" then null else .[5] end)
      }
    )
  ')

  # Extract success criteria per phase
  local criteria
  criteria=$(awk '
    /^### Phase [0-9]/ {
      if (match($0, /Phase [0-9]+(\.[0-9]+)?/)) {
        id = substr($0, RSTART+6, RLENGTH-6)
      }
      in_sc = 0
      next
    }
    /^\*\*Success Criteria\*\*/ || /^Success Criteria:/ { in_sc = 1; next }
    in_sc && /^[^0-9 ]/ && !/^  / { in_sc = 0 }
    in_sc && /^ *[0-9]+\./ {
      line = $0
      sub(/^ *[0-9]+\. */, "", line)
      printf "%s|%s\n", id, line
    }
  ' "$src" | jq -Rs '
    split("\n") | map(select(length > 0)) | map(
      split("|") | {id: .[0], criterion: .[1]}
    ) | group_by(.id) | map({(.[0].id): [.[].criterion]}) | add // {}
  ')

  # Merge phases list with details and criteria
  local merged_phases
  merged_phases=$(jq -n \
    --argjson list "$phases" \
    --argjson details "$details" \
    --argjson criteria "$criteria" \
    '
    $list | map(. as $p |
      ($details | map(select(.id == $p.id)) | .[0] // {}) as $d |
      ($criteria[$p.id] // []) as $sc |
      $p + {
        goal: ($d.goal // null),
        dependsOn: ($d.dependsOn // []),
        successCriteria: $sc,
        sprint: ($d.sprint // null),
        size: ($d.size // null),
        type: ($d.type // null)
      }
    )
  ')

  # Extract sprints table
  local sprints
  sprints=$(awk '
    /^## Sprint Summary/ { found=1; next }
    found && /^##/ { exit }
    found && /^\|/ && !/^\| *Sprint/ && !/^\|[-|]/ {
      sub(/^\| */, "")
      sub(/ *\| *$/, "")
      printf "%s\n", $0
    }
  ' "$src" | while IFS='|' read -r sid sphases sdesc; do
    sid=$(echo "$sid" | sed 's/^ *//;s/ *$//')
    sphases=$(echo "$sphases" | sed 's/^ *//;s/ *$//')
    sdesc=$(echo "$sdesc" | sed 's/^ *//;s/ *$//')
    printf '%s|%s|%s\n' "$sid" "$sphases" "$sdesc"
  done | jq -Rs '
    split("\n") | map(select(length > 0)) | map(
      split("|") | {
        id: (.[0] | tonumber? // 0),
        phases: (.[1] | split(",") | map(gsub("^ +| +$"; "")) | map(select(length > 0))),
        description: .[2]
      }
    )
  ')

  # Extract progress table
  local progress
  progress=$(awk '
    /^## Progress/ { found=1; next }
    found && /^##/ { exit }
    found && /^\|/ && !/^\| *Phase/ && !/^\|[-|]/ {
      sub(/^\| */, "")
      sub(/ *\| *$/, "")
      printf "%s\n", $0
    }
  ' "$src" | while IFS='|' read -r pphase pstatus pcompleted; do
    pphase=$(echo "$pphase" | sed 's/^ *//;s/ *$//')
    pstatus=$(echo "$pstatus" | sed 's/^ *//;s/ *$//')
    pcompleted=$(echo "$pcompleted" | sed 's/^ *//;s/ *$//')
    printf '%s|%s|%s\n' "$pphase" "$pstatus" "$pcompleted"
  done | jq -Rs '
    split("\n") | map(select(length > 0)) | map(
      split("|") | {phase: .[0], status: .[1], completed: .[2]}
    )
  ')

  # Extract last updated
  local last_updated
  last_updated=$(grep -E '^\*Created:' "$src" 2>/dev/null | head -1 | sed 's/^\*Created: *//; s/\*$//' || echo "")

  local json
  json=$(jq -n \
    --arg overview "$overview" \
    --argjson phases "$merged_phases" \
    --argjson sprints "$sprints" \
    --argjson progress "$progress" \
    --arg updated "$last_updated" \
    '{
      overview: $overview,
      phases: $phases,
      sprints: $sprints,
      progress: $progress,
      lastUpdated: $updated
    }')

  write_json "$P/ROADMAP.json" "$json"
}

# ── sync_state ───────────────────────────────────────────────────────────────
# Converts STATE.md -> STATE.json (excludes Decision Archive)
sync_state() {
  local src="$P/STATE.md"
  [ -f "$src" ] || return 0

  # Extract current position
  local phase status last_activity focus
  phase=$(grep -E '^Phase:' "$src" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "")
  status=$(grep -E '^Status:' "$src" 2>/dev/null | head -1 | sed 's/^Status: *//' || echo "")
  last_activity=$(grep -E '^Last activity:' "$src" 2>/dev/null | head -1 | sed 's/^Last activity: *//' || echo "")
  focus=$(grep -E '^\*\*Current focus:\*\*' "$src" 2>/dev/null | head -1 | sed 's/^\*\*Current focus:\*\* *//' || echo "")

  # Extract preferences (kebab-case keys to match emit_preferences output)
  local exec_model simplifier verification
  exec_model=$(grep -E '^execution-model:' "$src" 2>/dev/null | head -1 | sed 's/^execution-model: *//' || echo "unset")
  simplifier=$(grep -E '^simplifier:' "$src" 2>/dev/null | head -1 | sed 's/^simplifier: *//' || echo "unset")
  verification=$(grep -E '^verification:' "$src" 2>/dev/null | head -1 | sed 's/^verification: *//' || echo "unset")

  # Extract active decisions (stop at Decision Archive)
  local decisions
  decisions=$(awk '
    /^### Decisions/ { found=1; next }
    /^### Decision Archive/ { exit }
    found && /^###/ { exit }
    found && /^- / { sub(/^- */, ""); printf "%s\n", $0 }
  ' "$src" | jq -Rs 'split("\n") | map(select(length > 0)) | map({text: .})')

  # Extract blockers
  local blockers
  blockers=$(awk '
    /^### Blockers/ { found=1; next }
    found && /^###/ { exit }
    found && /^---/ { exit }
    found && /^- / { sub(/^- */, ""); printf "%s\n", $0 }
    found && /^None/ { next }
  ' "$src" | jq -Rs 'split("\n") | map(select(length > 0))')

  # Extract last updated
  local last_updated
  last_updated=$(grep -E '^\*Last updated:' "$src" 2>/dev/null | head -1 | sed 's/^\*Last updated: *//; s/\*$//' || echo "")

  local json
  json=$(jq -n \
    --arg phase "$phase" \
    --arg status "$status" \
    --arg activity "$last_activity" \
    --arg focus "$focus" \
    --arg model "$exec_model" \
    --arg simp "$simplifier" \
    --arg verif "$verification" \
    --argjson decs "$decisions" \
    --argjson blockers "$blockers" \
    --arg updated "$last_updated" \
    '{
      currentPosition: {
        phase: ($phase | tonumber? // null),
        status: $status,
        lastActivity: $activity,
        focus: $focus
      },
      preferences: {
        "execution-model": $model,
        "simplifier": $simp,
        "verification": $verif
      },
      decisions: $decs,
      blockers: $blockers,
      lastUpdated: $updated
    }')

  write_json "$P/STATE.json" "$json"
}

# ── sync_ideas ───────────────────────────────────────────────────────────────
# Converts IDEAS.md -> IDEAS.json
sync_ideas() {
  local src="$P/IDEAS.md"
  [ -f "$src" ] || return 0

  # Parse sessions using awk to extract structured tokens
  local tokens
  tokens=$(awk '
    /^# Brainstorming Session:/ {
      if (idx > 0) printf "SESSION_END\n"
      idx++
      t = $0; sub(/^# Brainstorming Session: */, "", t)
      printf "SESSION_START|%s\n", t
      next
    }
    /^\*\*Date:\*\*/ { sub(/^\*\*Date:\*\* */, ""); printf "DATE|%s\n", $0; next }
    /^\*\*Mode:\*\*/ { sub(/^\*\*Mode:\*\* */, ""); printf "MODE|%s\n", $0; next }
    /^### Idea [0-9]+:/ {
      n = $0; sub(/^### Idea [0-9]+: */, "", n)
      printf "IDEA|%s\n", n; next
    }
    /^\*\*Decision:\*\*/ {
      d = $0; sub(/^\*\*Decision:\*\* */, "", d)
      printf "DECISION|%s\n", d; next
    }
    /^## Approved Ideas Summary/ { sec = "A"; next }
    /^## Deferred Ideas/ { sec = "D"; next }
    /^## Rejected Ideas/ { sec = "R"; next }
    /^## / { sec = "" }
    sec == "A" && /^\|/ && !/^\| *Idea/ && !/^\|[-|]/ {
      sub(/^\| */, ""); sub(/ *\| *$/, "")
      printf "APPROVED|%s\n", $0; next
    }
    sec == "D" && /^- \*\*/ {
      l = $0; sub(/^- \*\*/, "", l)
      nm = l; sub(/\*\*.*$/, "", nm)
      rs = l; sub(/^[^:]*: */, "", rs)
      printf "DEFERRED|%s|%s\n", nm, rs; next
    }
    sec == "R" && /^- \*\*/ {
      l = $0; sub(/^- \*\*/, "", l)
      nm = l; sub(/\*\*.*$/, "", nm)
      printf "REJECTED|%s\n", nm; next
    }
    END { if (idx > 0) printf "SESSION_END\n" }
  ' "$src")

  # Build JSON by processing tokens in a bash loop
  local all_sessions="[]"
  local cur_session=""
  local cur_ideas="[]"
  local cur_approved="[]"
  local cur_deferred="[]"
  local cur_rejected="[]"
  local cur_title="" cur_date="" cur_mode=""
  local idea_idx=0

  _close_session() {
    if [ -n "$cur_title" ]; then
      local s
      s=$(jq -n \
        --arg title "$cur_title" \
        --arg date "$cur_date" \
        --arg mode "$cur_mode" \
        --argjson ideas "$cur_ideas" \
        --argjson approved "$cur_approved" \
        --argjson deferred "$cur_deferred" \
        --argjson rejected "$cur_rejected" \
        '{title: $title, date: $date, mode: $mode, ideas: $ideas, approved: $approved, deferred: $deferred, rejected: $rejected}')
      all_sessions=$(echo "$all_sessions" | jq --argjson s "$s" '. + [$s]')
    fi
  }

  while IFS= read -r line; do
    local tag="${line%%|*}"
    local rest="${line#*|}"
    case "$tag" in
      SESSION_START)
        _close_session
        cur_title="$rest"; cur_date=""; cur_mode=""
        cur_ideas="[]"; cur_approved="[]"; cur_deferred="[]"; cur_rejected="[]"
        idea_idx=0
        ;;
      SESSION_END)
        _close_session
        cur_title=""
        ;;
      DATE) cur_date="$rest" ;;
      MODE) cur_mode="$rest" ;;
      IDEA)
        idea_idx=$((idea_idx + 1))
        cur_ideas=$(echo "$cur_ideas" | jq --arg n "$rest" --argjson id "$idea_idx" \
          '. + [{id: $id, name: $n, decision: "", priority: "", description: ""}]')
        ;;
      DECISION)
        cur_ideas=$(echo "$cur_ideas" | jq --arg d "$rest" \
          'if length > 0 then .[-1].decision = $d else . end')
        ;;
      APPROVED)
        local aname apri anext
        aname=$(echo "$rest" | cut -d'|' -f1 | sed 's/^ *//;s/ *$//')
        apri=$(echo "$rest" | cut -d'|' -f2 | sed 's/^ *//;s/ *$//')
        anext=$(echo "$rest" | cut -d'|' -f3 | sed 's/^ *//;s/ *$//')
        cur_approved=$(echo "$cur_approved" | jq --arg n "$aname" --arg p "$apri" --arg ns "$anext" \
          '. + [{name: $n, priority: $p, nextStep: $ns}]')
        ;;
      DEFERRED)
        local dname dreason
        dname=$(echo "$rest" | cut -d'|' -f1)
        dreason=$(echo "$rest" | cut -d'|' -f2)
        cur_deferred=$(echo "$cur_deferred" | jq --arg n "$dname" --arg r "$dreason" \
          '. + [{name: $n, reason: $r}]')
        ;;
      REJECTED)
        cur_rejected=$(echo "$cur_rejected" | jq --arg n "$rest" '. + [$n]')
        ;;
    esac
  done <<< "$tokens"

  # Get last updated
  local last_updated
  last_updated=$(grep -E '^_Last updated:' "$src" 2>/dev/null | tail -1 | sed 's/^_Last updated: *//; s/_$//' || echo "")

  local final_json
  final_json=$(jq -n \
    --argjson sessions "$all_sessions" \
    --arg updated "$last_updated" \
    '{
      sessions: $sessions,
      lastUpdated: $updated
    }')

  write_json "$P/IDEAS.json" "$final_json"
}

# ── validate_json ────────────────────────────────────────────────────────────
validate_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "MISSING: $file"
    return 1
  fi
  if jq -e '.' "$file" >/dev/null 2>&1; then
    echo "VALID: $file ($(wc -c < "$file" | tr -d ' ') bytes)"
    return 0
  else
    echo "INVALID: $file"
    return 1
  fi
}

# ── sync_all ─────────────────────────────────────────────────────────────────
sync_all() {
  if [ ! -d "$P" ]; then
    echo "ERROR: Planning directory $P does not exist"
    exit 1
  fi

  local created=0 skipped=0 errors=0

  for type in project roadmap state ideas; do
    local md_file
    case $type in
      project) md_file="$P/PROJECT.md" ;;
      roadmap) md_file="$P/ROADMAP.md" ;;
      state)   md_file="$P/STATE.md" ;;
      ideas)   md_file="$P/IDEAS.md" ;;
    esac

    if [ ! -f "$md_file" ]; then
      skipped=$((skipped + 1))
      continue
    fi

    local json_file="${md_file%.md}.json"
    if "sync_${type}"; then
      if [ -f "$json_file" ]; then
        echo "  Created: $json_file ($(wc -c < "$json_file" | tr -d ' ') bytes)"
        created=$((created + 1))
      fi
    else
      echo "  Error: $json_file"
      errors=$((errors + 1))
    fi
  done

  echo ""
  echo "Synced: $created files | Skipped: $skipped | Errors: $errors"
}

# ── Main ─────────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --all)
    echo "Syncing all .planning/ files..."
    sync_all
    ;;
  project)  sync_project && echo "Synced PROJECT.md -> PROJECT.json" ;;
  roadmap)  sync_roadmap && echo "Synced ROADMAP.md -> ROADMAP.json" ;;
  state)    sync_state && echo "Synced STATE.md -> STATE.json" ;;
  ideas)    sync_ideas && echo "Synced IDEAS.md -> IDEAS.json" ;;
  --validate)
    echo "Validating .planning/ JSON files..."
    rc=0
    for f in "$P"/PROJECT.json "$P"/ROADMAP.json "$P"/STATE.json "$P"/IDEAS.json; do
      validate_json "$f" || rc=1
    done
    exit $rc
    ;;
  --help|-h)
    echo "Usage: json-sync.sh [--all|project|roadmap|state|ideas|--validate|--help]"
    echo ""
    echo "Convert .planning/ Markdown files to JSON."
    echo ""
    echo "Commands:"
    echo "  --all       Sync all files (default)"
    echo "  project     Sync PROJECT.md -> PROJECT.json"
    echo "  roadmap     Sync ROADMAP.md -> ROADMAP.json"
    echo "  state       Sync STATE.md -> STATE.json"
    echo "  ideas       Sync IDEAS.md -> IDEAS.json"
    echo "  --validate  Validate existing JSON files"
    echo "  --help      Show this help"
    ;;
  *)
    echo "Unknown command: $1"
    echo "Run with --help for usage"
    exit 1
    ;;
esac
