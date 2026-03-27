# Research for Phase 13: JSON Schema Infrastructure for Planning Files

## User Constraints

### Locked Decisions

- **JSON Schema Design:** Normalized jq-optimized structures, not 1:1 MD mirror. camelCase keys, max 3 levels nesting, arrays of objects with id/name fields.
- **Sync Direction:** MD remains source of truth. JSON always derived from MD. Skills write both.
- **Gather Migration:** Add JSON-first path to existing emit_* functions in gather-common.sh. jq if JSON exists, fall back to grep/sed on MD.
- **/cst-help Migration:** Single "migrate" command processes all top-level files. Idempotent. Shows summary.
- **File naming:** PROJECT.json, ROADMAP.json, STATE.json, IDEAS.json (same base name as MD)
- **Script location:** json-sync.sh in `plugins/claude-super-team/scripts/` alongside gather-common.sh and phase-utils.sh
- **Out of scope:** Phase-level files (CONTEXT/RESEARCH/PLAN/SUMMARY), codebase mapping files, BUILD-STATE.md, SECURITY-AUDIT.md, JSON->MD reverse generation

### Claude's Discretion

- Exact JSON field names and nesting for each schema
- jq query patterns in emit_* functions
- Error handling in json-sync.sh for MD parsing edge cases
- Whether to modify existing emit_* functions inline or create parallel functions

### Deferred Ideas (OUT OF SCOPE)

- Phase-level JSON schemas (CONTEXT.md, RESEARCH.md, PLAN.md, SUMMARY.md)
- JSON->MD reverse generation
- Formal JSON Schema (draft-07) validation files
- Codebase mapping JSON (.planning/codebase/*.md)

---

## Summary

This phase adds a JSON data layer alongside existing Markdown planning files. The core technical challenge is twofold: (1) reliably parsing structured Markdown into normalized JSON using only bash/awk/jq, and (2) updating 7+ gather-common.sh functions with transparent JSON-first extraction that preserves identical output format. Research confirms jq 1.7+ is broadly available (pre-installed on macOS Sequoia, standard package on all major Linux distros), and the `--arg`/`--argjson` flags provide safe string escaping for bash-to-JSON construction. The awk-pipe-to-jq pattern (awk extracts pipe-delimited records, `jq -Rs` builds arrays) is the robust approach for converting MD list/table structures. Overall confidence is HIGH -- all patterns were verified against the actual codebase files.

---

## Standard Stack

### Core Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| jq | 1.7+ (1.7 on current system, 1.8.1 latest stable) | JSON construction, extraction, validation in bash | HIGH |
| awk (gawk/mawk) | System default | Markdown section extraction, structured data parsing | HIGH |
| bash | 4.0+ | Script execution, pipe orchestration | HIGH |

### Supporting Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| grep/sed | System default | MD fallback parsing (existing patterns) | HIGH |

### Alternatives Considered

| Alternative | Why Not |
|-------------|---------|
| Python/Node JSON generation | Project constraint: no runtime dependencies, bash-only |
| yq (YAML processor) | Not needed -- data is markdown, not YAML. Extra dependency. |
| JSON Schema draft-07 validation | Deferred per CONTEXT.md -- structural validation via jq sufficient |
| jo (JSON output tool) | Extra dependency. jq -n with --arg achieves the same thing. |

---

## Architecture Patterns

### Project Structure

New files created by this phase:

```
plugins/claude-super-team/scripts/
  json-sync.sh              # MD->JSON conversion + validation (NEW)
  gather-common.sh          # Updated: JSON-first emit_* functions
  phase-utils.sh            # Unchanged (reads ROADMAP.md for phase names -- could use JSON later)

.planning/
  PROJECT.md                # Existing (unchanged)
  PROJECT.json              # NEW: structured project data
  ROADMAP.md                # Existing (unchanged)
  ROADMAP.json              # NEW: structured roadmap data
  STATE.md                  # Existing (unchanged)
  STATE.json                # NEW: structured state data
  IDEAS.md                  # Existing (unchanged)
  IDEAS.json                # NEW: structured ideas data
```

### Design Patterns

- **JSON-first with silent fallback:** Every emit_* function checks (1) jq available, (2) JSON file exists. If both true, extract from JSON. Otherwise, fall back to existing grep/sed/awk on MD. No warnings, no errors -- the caller never knows which path ran.

- **Awk-pipe-to-jq construction:** For building JSON from MD, use awk to extract pipe-delimited records from markdown structures (lists, tables, sections), then pipe through `jq -Rs 'split("\n") | map(...)'` to build properly escaped JSON arrays. This avoids manual string escaping and handles special characters safely.

- **jq --arg for safe string injection:** Never interpolate bash variables directly into jq filters. Always use `jq -n --arg key "$value"` to prevent injection and handle special characters (dashes, quotes, newlines) correctly.

- **Atomic JSON writes:** Use `jq ... > "$file.tmp" && mv "$file.tmp" "$file"` pattern to prevent partial writes on error. If jq fails mid-construction, the original JSON file remains intact.

- **Dual-write in skills:** Skills that create/update MD files add a parallel JSON write step. The skill generates both formats simultaneously -- it does NOT run json-sync.sh. The sync script is only for migration of existing projects.

### Anti-Patterns

- **Shell variable interpolation in jq filters:** Never use `jq ".key = \"$value\""`. Use `jq --arg v "$value" '.key = $v'` instead. Shell interpolation is vulnerable to injection and breaks on special characters.

- **Parsing JSON with grep/sed:** Never parse JSON output with grep. If jq produced it, jq should consume it. The only grep/sed parsing should be on MD files in fallback paths.

- **Mirroring MD structure in JSON:** The JSON structure should be normalized for queries, not a literal translation of markdown headings. For example, ROADMAP.md has nested "## Phase Details" sections with multi-line content -- the JSON should flatten this into a phases array with fields, not nest markdown text.

- **Modifying emit_* output format:** The output format of emit_* functions is a contract with downstream SKILL.md parsers. The JSON path must produce byte-identical output to the MD path for any given state.

---

## Don't Hand-Roll

| Problem | Solution | Why Not Custom |
|---------|----------|----------------|
| String escaping in JSON construction | `jq --arg` / `jq --argjson` | Manual escaping will break on quotes, newlines, backslashes, unicode |
| JSON validation | `jq -e '.' "$file" >/dev/null 2>&1` | Writing a custom JSON parser/validator in bash is futile |
| Pipe-delimited to JSON array conversion | `awk '...' \| jq -Rs 'split("\n") \| map(...)'` | Building JSON arrays with string concatenation will break on special chars |
| Merging JSON objects | `jq -s '.[0] * .[1]'` or `jq --slurpfile` | Manual merge logic is fragile |
| Conditional JSON field inclusion | `jq 'if .field then ... else ... end'` | Bash if/else around jq calls is verbose and error-prone |

---

## Common Pitfalls

| Pitfall | Impact | How to Avoid |
|---------|--------|--------------|
| jq not installed on target system | All JSON extraction fails, gather scripts broken | Always check `command -v jq` before JSON path; silent fallback to MD parsing |
| MD file format changes break awk parsers | json-sync.sh produces wrong/empty JSON | Design awk patterns to be resilient: match section headers, not line counts; always validate output |
| emit_* output format changes | SKILL.md parsers that depend on exact output break | Test that JSON path produces identical output to MD path for each function |
| Special characters in project descriptions | JSON construction fails or produces invalid JSON | Always use `jq --arg` for string values, never shell interpolation |
| Partial JSON file from interrupted write | Subsequent jq reads fail with parse error | Use atomic write pattern: write to .tmp, then mv |
| Stale JSON after manual MD edit | JSON and MD diverge; gather scripts return old data | Document: after manual MD edits, run `/cst-help migrate` to regenerate JSON. Skills auto-maintain both. |
| IDEAS.md has multiple brainstorming sessions | Naive parsing grabs wrong session's data | Parse by session boundary (`# Brainstorming Session:` heading), aggregate across all sessions |
| ROADMAP.md phase names contain markdown bold/brackets | awk extraction includes unwanted `**` or `[COMPLETE]` | Strip markdown formatting in awk before passing to jq (existing phase-utils.sh pattern) |
| STATE.md Decision Archive section | Gather scripts should NOT include archived decisions | Existing `awk '/^### Decision Archive/ { exit }'` pattern must be preserved in JSON path too |
| jq version differences | Features like try-catch, `limit`, `ascii_downcase` may not exist on jq 1.5 | Target jq 1.6+ minimum (Ubuntu 20.04+). All required features (`--arg`, `-Rs`, `//`, `-e`, `to_entries`) exist since 1.5. |

---

## Key Patterns

### JSON-first emit function pattern

The core pattern for updating gather-common.sh functions. Each function gains a JSON path that produces identical output to the existing MD path.

```bash
emit_preferences() {
  echo "=== PREFERENCES ==="
  if command -v jq >/dev/null 2>&1 && [ -f "$P/STATE.json" ]; then
    jq -r '.preferences | to_entries[] | "\(.key): \(.value)"' "$P/STATE.json" 2>/dev/null && {
      [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" = "1" ] && echo "teams-available: true" || echo "teams-available: false"
      return 0
    }
  fi
  # MD fallback (existing logic unchanged)
  grep -E '^execution-model:' "$P/STATE.md" 2>/dev/null || echo "execution-model: unset"
  grep -E '^simplifier:' "$P/STATE.md" 2>/dev/null || echo "simplifier: unset"
  grep -E '^verification:' "$P/STATE.md" 2>/dev/null || echo "verification: unset"
  [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" = "1" ] && echo "teams-available: true" || echo "teams-available: false"
}
```

The `&& { ...; return 0; }` pattern ensures fallback only triggers if jq extraction actually fails (exit non-zero or file missing).

### Awk-pipe-to-jq for markdown list/table extraction

Convert markdown checkbox lists (ROADMAP phases) into JSON arrays safely.

```bash
awk '/^\s*- \[.\].*Phase [0-9]/ {
  checked = (index($0, "[x]") > 0) ? "true" : "false"
  match($0, /Phase [0-9]+(\.[0-9]+)?/)
  id = substr($0, RSTART+6, RLENGTH-6)
  name = $0; sub(/.*Phase [0-9]+(\.[0-9]+)?: */, "", name)
  gsub(/\*\*/, "", name)
  printf "%s|%s|%s\n", id, checked, name
}' "$P/ROADMAP.md" | jq -Rs '
  split("\n") | map(select(length > 0)) | map(
    split("|") | {id: .[0], complete: (.[1] == "true"), name: .[2]}
  )
'
```

This pattern was verified against the actual ROADMAP.md and correctly extracts all 20+ phases with proper boolean completion status.

### Atomic JSON file write

Prevent corruption from interrupted writes.

```bash
write_json() {
  local target="$1"
  local content="$2"
  local tmp="${target}.tmp"
  if echo "$content" | jq -e '.' > "$tmp" 2>/dev/null; then
    mv "$tmp" "$target"
    return 0
  else
    rm -f "$tmp"
    return 1
  fi
}
```

### jq availability check (one-time, cached)

Cache the check result to avoid repeated `command -v` calls in loops.

```bash
# At top of gather-common.sh, after P= assignment
_JQ_AVAILABLE=false
command -v jq >/dev/null 2>&1 && _JQ_AVAILABLE=true
```

Then in each function: `if [ "$_JQ_AVAILABLE" = "true" ] && [ -f "$P/STATE.json" ]; then ...`

### JSON construction from bash variables using jq -n

Build complete JSON objects safely from shell variables.

```bash
jq -n \
  --arg name "$project_name" \
  --arg desc "$description" \
  --arg core "$core_value" \
  --arg model "$exec_model" \
  --argjson reqs "$requirements_json_array" \
  '{
    projectName: $name,
    description: $desc,
    coreValue: $core,
    preferences: { executionModel: $model },
    requirements: $reqs
  }'
```

The `--arg` flag handles string escaping; `--argjson` passes pre-built JSON values (arrays, objects, numbers, booleans).

---

## State of the Art

| Aspect | Old Approach (Current) | New Approach (This Phase) | What Changed |
|--------|------------------------|---------------------------|--------------|
| Data extraction in gather scripts | grep/sed/awk on MD files, fragile regex patterns | jq on JSON files with MD fallback | Structured queries replace pattern matching |
| Planning file format | MD only, human-readable | Dual MD+JSON: MD for humans, JSON for scripts | Machine-readable layer added |
| Phase completion check | `find \| wc -l` pipelines, string manipulation | `jq '.phases[] \| select(.status == "complete")'` | Type-safe filtering replaces string counting |
| Preference extraction | `grep -E '^key:'` with manual parsing | `jq '.preferences.key'` | Direct field access replaces regex |
| Cross-file queries (sync check) | Multiple grep commands across files | Single jq query across JSON files | Consolidated queries replace scattered greps |
| Migration for existing projects | Re-run pipeline skills | `/cst-help migrate` runs json-sync.sh | One command generates all JSON files |

---

## JSON Schema Designs

Recommended JSON structures for each planning file. These are optimized for the actual jq queries needed by gather-data.sh scripts across all 13 skills.

### PROJECT.json

```json
{
  "projectName": "string",
  "description": "string",
  "coreValue": "string",
  "requirements": {
    "validated": [{"text": "string", "complete": true}],
    "active": [{"text": "string", "complete": false}],
    "outOfScope": ["string"]
  },
  "constraints": ["string"],
  "decisions": [{"decision": "string", "rationale": "string", "outcome": "string"}],
  "preferences": {
    "executionModel": "string"
  },
  "lastUpdated": "string"
}
```

**Query examples used by gather scripts:**
- `jq -r '.projectName'` (emit_project_section -- header)
- `jq -r '.preferences.executionModel'` (emit_preferences)
- `jq -e '.requirements.active | length > 0'` (structure checks)

### ROADMAP.json

```json
{
  "overview": "string",
  "phases": [
    {
      "id": "string",
      "name": "string",
      "complete": true,
      "goal": "string",
      "dependsOn": ["string"],
      "successCriteria": ["string"],
      "sprint": null,
      "size": null,
      "type": null
    }
  ],
  "sprints": [
    {"id": "number", "phases": ["string"], "description": "string"}
  ],
  "progress": [
    {"phase": "string", "status": "string", "completed": "string"}
  ],
  "lastUpdated": "string"
}
```

**Query examples used by gather scripts:**
- `jq -r '.phases[] | select(.complete == false) | .id'` (unchecked phases for sync_check)
- `jq -r '.phases[] | select(.id == "13") | .name'` (phase name lookup in create_phase_dir)
- `jq '[.phases[] | select(.complete)] | length'` (completion counting)
- `jq -r '.phases[] | "\(.id)|\(.dependsOn | join(","))"'` (dependency extraction for progress)

### STATE.json

```json
{
  "currentPosition": {
    "phase": 13,
    "status": "string",
    "lastActivity": "string",
    "focus": "string"
  },
  "preferences": {
    "executionModel": "string",
    "simplifier": "string",
    "verification": "string"
  },
  "decisions": [{"text": "string"}],
  "blockers": ["string"],
  "lastUpdated": "string"
}
```

**Query examples:**
- `jq -r '.currentPosition.phase'` (emit_state_section, code/gather-data.sh CURRENT_PHASE)
- `jq -r '.preferences | to_entries[] | "\(.key): \(.value)"'` (emit_preferences)
- `jq -r '.currentPosition.status'` (state detection in cst-help)

Note: The Decision Archive from STATE.md is intentionally excluded from JSON. The JSON `decisions` array contains only active decisions. This matches the existing `awk '/^### Decision Archive/ { exit }'` behavior.

### IDEAS.json

```json
{
  "sessions": [
    {
      "title": "string",
      "date": "string",
      "mode": "string",
      "ideas": [
        {
          "id": 1,
          "name": "string",
          "decision": "string",
          "priority": "string",
          "description": "string"
        }
      ],
      "approved": [{"name": "string", "priority": "string", "nextStep": "string"}],
      "deferred": [{"name": "string", "reason": "string"}],
      "rejected": ["string"]
    }
  ],
  "lastUpdated": "string"
}
```

**Note:** No gather-data.sh scripts currently read IDEAS.md. This schema is designed for potential future gather use and for /cst-help explain queries. The schema focuses on queryable decision status rather than full idea descriptions.

---

## Gather Script Impact Analysis

Analysis of which gather-data.sh scripts need changes and what specifically changes in each.

### Scripts that use gather-common.sh emit_* functions (automatic benefit)

These scripts source gather-common.sh and call shared functions. When emit_* functions gain JSON paths, these scripts benefit automatically with no code changes:

| Script | Functions Used | Changes Needed |
|--------|---------------|----------------|
| metrics/gather-data.sh | emit_project_section, emit_state_section | None (automatic) |
| drift/gather-data.sh | emit_project_section, emit_roadmap_section, emit_state_section | None (automatic) |
| build/gather-data.sh | emit_preferences, emit_phase_completion | None (automatic) |
| execute-phase/gather-data.sh | emit_preferences, emit_phase_completion | None (automatic) |

### Scripts with inline PROJECT/ROADMAP/STATE reading (need updates)

These scripts read planning files directly with `cat`/`grep`/`awk` instead of using emit_* functions. They need JSON-first paths added:

| Script | What It Reads Inline | Complexity |
|--------|---------------------|------------|
| progress/gather-data.sh | PROJECT, ROADMAP, STATE (full cat), DEPENDENCIES (awk on ROADMAP), SYNC_CHECK (partial), BUILD (grep on BUILD-STATE) | High -- most inline reads |
| plan-phase/gather-data.sh | PROJECT, ROADMAP, STATE (full cat), ROADMAP_TRIMMED (awk), STATE_TRIMMED (awk), ROADMAP_PHASES | High -- two-invocation pattern |
| discuss-phase/gather-data.sh | PROJECT, ROADMAP (full cat) | Low |
| research-phase/gather-data.sh | PROJECT, ROADMAP, STATE (full cat) | Low |
| phase-feedback/gather-data.sh | PROJECT, ROADMAP, STATE (full cat) | Low |
| code/gather-data.sh | PROJECT, ROADMAP, STATE (full cat), CURRENT_PHASE | Low |
| create-roadmap/gather-data.sh | PROJECT, ROADMAP (full cat), EXISTING_PHASES, HIGHEST_PHASE | Medium |

### Recommended migration approach

**Phase A (gather-common.sh):** Update all 7 emit_* functions with JSON-first paths. This gives automatic benefit to 4 scripts.

**Phase B (inline readers):** For scripts that `cat` full MD files into context, the JSON path is NOT about replacing `cat` -- those scripts dump the entire file for LLM consumption, and that must remain MD (LLMs read markdown, not JSON). The JSON benefit for these scripts is in their _structured extraction_ sections: DEPENDENCIES, SYNC_CHECK, PHASE_STATUS, CURRENT_PHASE, HIGHEST_PHASE, etc.

**Key insight:** Many gather scripts dump full MD files (`cat "$P/PROJECT.md"`) for LLM context. These `cat` calls should NOT be replaced with JSON reads -- LLMs consume markdown better than JSON. Only the structured data extraction sections (grep/awk pipelines that produce key=value output) benefit from JSON.

---

## Open Questions

- **camelCase key mapping for preferences:** STATE.md uses kebab-case keys (`execution-model`, `simplifier`). JSON uses camelCase (`executionModel`). The emit_preferences output uses kebab-case (`execution-model: opus`). The JSON path needs to convert camelCase back to kebab-case for output compatibility. The `jq 'to_entries[] | (.key | gsub("(?<a>[A-Z])"; "-" + (.a | ascii_downcase)))'` pattern works but is verbose. Alternative: store preferences in JSON with kebab-case keys to avoid conversion. **Recommendation:** Store preferences in JSON with the same kebab-case keys as MD (`"execution-model": "opus"`) to avoid conversion complexity. This violates the camelCase convention but is pragmatic.

- **phase-utils.sh create_phase_dir:** This function greps ROADMAP.md for phase names. Should it also gain a JSON path? The function is called infrequently (only during phase directory creation) and the grep is simple enough. **Recommendation:** Defer to future phase. The function works fine on MD and is called rarely.

- **ROADMAP.md Phase Details sections:** The detailed `### Phase N:` sections contain multi-line goal descriptions, success criteria, and dependency information. The JSON `phases` array captures this in structured form. But plan-phase/gather-data.sh extracts the raw markdown for these sections (`ROADMAP_TRIMMED`) to pass to the planner LLM. The JSON path should NOT replace this -- the planner needs human-readable markdown. Only the structured extraction (phase listing, completion status, dependency graph) should use JSON.

---

## Sources

| Source | Type | Confidence | URL |
|--------|------|------------|-----|
| jq official manual | Official docs | HIGH | https://jqlang.github.io/jq/manual/ |
| jq download/installation page | Official docs | HIGH | https://jqlang.org/download/ |
| jq GitHub wiki - Installation | Official repo | HIGH | https://github.com/jqlang/jq/wiki/Installation |
| Codebase: gather-common.sh | Project code | HIGH | plugins/claude-super-team/scripts/gather-common.sh |
| Codebase: phase-utils.sh | Project code | HIGH | plugins/claude-super-team/scripts/phase-utils.sh |
| Codebase: 13 gather-data.sh scripts | Project code | HIGH | plugins/claude-super-team/skills/*/gather-data.sh |
| Codebase: PROJECT.md, ROADMAP.md, STATE.md, IDEAS.md | Project data | HIGH | .planning/*.md |
| Codebase: cst-help/SKILL.md | Project code | HIGH | plugins/claude-super-team/skills/cst-help/SKILL.md |
| jq version testing on target system | Direct verification | HIGH | jq-1.7 confirmed via `jq --version` |
| All jq patterns tested | Direct verification | HIGH | Tested --arg, -Rs, -e, //, to_entries, try-catch on system |

---

## Metadata

- **Research date:** 2026-03-27
- **Phase:** 13 - JSON Schema Infrastructure for Planning Files
- **Confidence breakdown:** 14 HIGH, 1 MEDIUM, 0 LOW findings
- **Context7 available:** yes (not needed -- no external library docs required)
- **Context7 libraries queried:** 0
- **Firecrawl available:** no
- **Sources consulted:** 10+
