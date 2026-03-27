# Context for Phase 13: JSON Schema Infrastructure for Planning Files

## Phase Boundary (from ROADMAP.md)

**Goal:** Add structured JSON representations alongside top-level `.planning/` MD files (PROJECT, ROADMAP, STATE, IDEAS) so gather scripts can use `jq` for reliable data extraction, while preserving MD files as human-readable versions. Give `/cst-help` the ability to migrate existing MD-only projects to dual MD+JSON format.

**Success Criteria:**
1. JSON schema definitions exist for PROJECT, ROADMAP, STATE, and IDEAS -- each `.planning/*.md` file has a corresponding `.planning/*.json` with structured, queryable data
2. A shared script (`json-sync.sh` or similar in `plugins/claude-super-team/scripts/`) can generate JSON from existing MD content and validate JSON structure
3. All `gather-data.sh` scripts that read top-level planning files use `jq` on JSON files for data extraction, with fallback to MD parsing when JSON files don't exist (backward compatibility)
4. All skills that create or modify top-level planning files (`/new-project`, `/create-roadmap`, `/brainstorm`) produce both MD and JSON output on every write
5. `/cst-help` includes a "migrate" action that generates JSON files from existing MD-only `.planning/` projects, making them queryable without re-running the full pipeline

**What's in scope for this phase:**
- JSON schema definitions for 4 top-level files (PROJECT, ROADMAP, STATE, IDEAS)
- Shared json-sync.sh script for MD→JSON conversion
- Updating gather-data.sh scripts to use jq with MD fallback
- Updating writer skills (new-project, create-roadmap, brainstorm) for dual output
- Adding /cst-help "migrate" action
- Updating /cst-help references (workflow-guide, troubleshooting, skill reference)

**What's explicitly out of scope:**
- Phase-level files (CONTEXT.md, RESEARCH.md, PLAN.md, SUMMARY.md) -- only top-level .planning/ files
- Codebase mapping files (.planning/codebase/*.md) -- not included in JSON schema
- BUILD-STATE.md -- already structured enough and is /build-internal
- SECURITY-AUDIT.md -- low-frequency file, not worth the JSON overhead
- Removing MD files -- they remain as human-readable format
- JSON→MD reverse generation -- MD remains the human-editable format

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/scripts/gather-common.sh`: Shared library with 7 emit_* functions (`emit_project_section`, `emit_roadmap_section`, `emit_state_section`, `emit_phase_completion`, `emit_sync_check`, `emit_preferences`, `emit_structure`). Currently uses grep/sed/awk to parse MD files.
- `plugins/claude-super-team/scripts/phase-utils.sh`: Shared utilities with `normalize_phase()`, `find_phase_dir()`, `create_phase_dir()`. Uses grep on ROADMAP.md for phase name extraction.
- Individual `gather-data.sh` scripts: 9+ scripts across skills. High-overlap scripts (build, execute-phase, progress) source gather-common.sh. Lower-overlap scripts have their own sections but also source gather-common.sh.

**Established patterns:**
- `source "$(dirname "$0")/../../scripts/gather-common.sh"` -- standard sourcing pattern for shared scripts
- `SKIP_PROJECT=1 SKIP_ROADMAP=1` env var pattern for context-aware skipping
- `HAS_*=true/false` flags emitted by gather functions for downstream conditional logic
- `emit_*_section` functions output structured sections with `=== SECTION_NAME ===` delimiters
- Bash variables use UPPERCASE_WITH_UNDERSCORES

**Integration points:**
- Every skill with a `gather-data.sh` script will need updates
- Skills that write .planning/ files: `/new-project` (PROJECT.md), `/create-roadmap` (ROADMAP.md, STATE.md), `/brainstorm` (IDEAS.md), `/execute-phase` (STATE.md updates), `/progress` (STATE.md reads), `/build` (BUILD-STATE.md)
- `/cst-help` SKILL.md routes actions and outputs -- new "migrate" route needed

**Constraints from existing code:**
- No runtime dependencies (bash-only, no Node/Python)
- jq must be available on the system (standard on most Unix systems)
- gather-common.sh functions are sourced by 9+ scripts -- changes must be backward-compatible
- SKIP_* env vars must continue to work for context-aware gathering
- Skills write MD files via Write() tool calls embedded in SKILL.md instructions -- dual-write means adding JSON write calls alongside existing Write() calls

---

## Cross-Phase Dependencies

**From Phase 9 (Script Consolidation & State Compaction)** [executed]:
- Built: `gather-common.sh` with 7 shared emit_* functions, `create_phase_dir()` in phase-utils.sh
- Provides: The exact functions that need JSON-aware alternatives. The shared script architecture that json-sync.sh will follow.
- Key: `emit_project_section`, `emit_roadmap_section`, `emit_state_section` are the primary functions to update

**From Phase 4 (Harden Fragile Areas)** [executed]:
- Built: `phase-utils.sh` with `normalize_phase()`, `find_phase_dir()`
- Provides: Pattern for shared script location and sourcing conventions

**From Phase 5 (Workflow Validation)** [executed]:
- Built: gather-data.sh pre-assembled sections pattern (ROADMAP_TRIMMED, STATE_TRIMMED, etc.)
- Provides: The two-invocation pattern (Step 0 for validation, Phase 3.5 for phase-specific) that must be preserved

**Assumptions about prior phases:**
- gather-common.sh emit_* functions are stable and sourced by 9+ scripts
- The `=== SECTION_NAME ===` delimiter format is stable across all gather scripts
- Skills that write .planning/ files do so via Write() or Edit() tool calls in SKILL.md

---

## Implementation Decisions

### JSON Schema Design

**Decision:** Use normalized, jq-optimized JSON structures. Not a 1:1 mirror of MD layout. Each JSON file has a flat, queryable structure with arrays of objects for collections (phases, decisions, requirements) and key-value pairs for scalar data.

**Rationale:** The whole purpose of JSON is efficient programmatic access via jq. A literal MD-to-JSON translation (e.g., preserving markdown headings as nested keys) would just move the parsing problem from MD to JSON. Instead, data should be structured for the most common jq queries: extracting phase status, getting current position, listing requirements, reading preferences.

**Constraints:**
- JSON keys use camelCase (standard JSON convention)
- Arrays use objects with `id` or `name` fields for filtering
- Avoid deeply nested structures (max 3 levels) to keep jq queries simple
- Every field in JSON must correspond to something in the MD file (no invented data)

### Sync Direction & Source of Truth

**Decision:** MD files remain the primary human-editable format. JSON is always derived FROM MD content, never the reverse. Skills write both MD and JSON when creating/updating files. The json-sync.sh script converts MD→JSON for migration scenarios.

**Rationale:** This project is markdown-driven. All existing workflows, skills, and user habits revolve around editing and reading MD files. Making JSON the source of truth would break the existing human workflow and require rewriting how users interact with .planning/ files. JSON is a machine-readable layer on top, not a replacement.

**Constraints:**
- No JSON→MD generation needed (MD is always written directly by skills)
- If MD and JSON ever diverge, MD is authoritative -- re-run migration to regenerate JSON
- Skills that update only a section of an MD file must also update the corresponding JSON field(s)

### Gather Script Migration Pattern

**Decision:** Add jq-based extraction functions to `gather-common.sh` alongside existing emit_* functions. Each emit_* function gains a JSON-first path: if the corresponding .json file exists, use `jq` to extract data; otherwise fall back to existing MD grep/sed parsing. The function signature and output format remain identical.

**Rationale:** Centralizing JSON/MD fallback logic in gather-common.sh follows the Phase 9 consolidation pattern. Individual gather-data.sh scripts should not need to know whether they're reading JSON or MD -- the shared functions abstract this. This also makes the migration incremental: scripts that source gather-common.sh automatically get JSON support.

**Constraints:**
- Output format of emit_* functions must NOT change (downstream SKILL.md parsers depend on the current format)
- `jq` must be checked for availability at function entry (not all environments may have it)
- SKIP_* env vars must continue to work (skip the entire section, regardless of JSON/MD source)
- Fallback must be silent (no warnings if JSON doesn't exist -- many existing projects won't have it)

### /cst-help Migration UX

**Decision:** Add a "migrate" routing case in /cst-help. When user runs `/cst-help migrate`, the skill runs json-sync.sh to generate JSON files for all top-level .planning/ MD files that don't already have JSON counterparts. Shows a summary of what was created. If JSON already exists, offers to regenerate (overwrite).

**Rationale:** Migration should be a single command that handles all files at once. Per-file migration adds unnecessary friction. The script handles idempotency -- running it multiple times is safe.

**Constraints:**
- Migration requires .planning/ directory to exist (otherwise error: "No planning files found")
- Only processes files that match known schemas (PROJECT, ROADMAP, STATE, IDEAS)
- Shows diff summary of what was generated (file list + size)
- Does NOT auto-commit -- tells user how to commit (consistent with all CST skills)

---

## Claude's Discretion

- **Exact JSON field names and nesting:** Claude decides the specific key names, nesting structure, and array formats for each JSON schema, optimizing for the most common jq query patterns used in gather scripts
- **jq query patterns:** Claude decides the exact jq filters used in emit_* functions, choosing the most robust and readable patterns
- **Error handling in json-sync.sh:** Claude decides how to handle MD parsing edge cases (malformed sections, missing fields, unexpected formatting)
- **gather-common.sh refactoring approach:** Claude decides whether to modify existing emit_* functions inline or create parallel emit_*_json functions

---

## Specific Ideas

- JSON files should be named with the same base name: `PROJECT.json`, `ROADMAP.json`, `STATE.json`, `IDEAS.json`
- The json-sync.sh script should be in `plugins/claude-super-team/scripts/` alongside gather-common.sh and phase-utils.sh
- Consider using `jq -e` for existence checks and `jq -r` for raw string output in gather functions
- The `emit_phase_completion` function in gather-common.sh is a prime candidate for JSON optimization since it currently uses complex grep/ls/wc pipelines

---

## Deferred Ideas

- **Phase-level JSON schemas:** JSON for CONTEXT.md, RESEARCH.md, PLAN.md, SUMMARY.md would be valuable but is out of scope. Could be a future phase if top-level JSON proves useful.
- **JSON→MD reverse generation:** Making JSON the sole source of truth and generating MD from it. Deferred because it would break existing human workflows.
- **JSON validation via schema files:** Formal JSON Schema (draft-07) validation files. Nice-to-have but not needed for initial implementation -- structural validation in json-sync.sh is sufficient.
- **Codebase mapping JSON:** .planning/codebase/*.md could also benefit from JSON but is lower priority since those files are rarely read by gather scripts.
