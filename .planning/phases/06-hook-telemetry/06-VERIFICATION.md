# Phase 06: Hook-Based Telemetry Capture -- Verification

**status: passed**

**Date:** 2026-02-17
**Phase goal:** Add passive, zero-token-cost telemetry to orchestrator skills via a shared shell script called by skill-scoped hooks

---

## Plan 01: Shared Telemetry Script + Gitignore

### Must-Have Truths

#### 1. "telemetry.sh captures skill_start, skill_end, agent_spawn, agent_complete, tool_use, and tool_failure events as JSONL lines"

**VERIFIED**

- **Existence:** `plugins/claude-super-team/scripts/telemetry.sh` exists (129 lines).
- **Substantive:** Script contains a `case` statement (lines 65-124) handling all 6 event types: `skill_start`, `skill_end`, `agent_spawn`, `agent_complete`, `tool_use`, `tool_failure`. Each branch extracts event-specific data fields. The JSONL write on line 127 assembles a complete JSON object with event, skill, session_id, timestamp, and data fields, appended via `>>` to the output file.
- **Wired:** The output line format is valid JSONL (`echo "{...}" >> "${OUTFILE}"`). Each event type produces different `data` payloads (source/model for skill_start, reason for skill_end, agent_type/agent_id for agent_spawn/agent_complete, tool_name for tool_use, tool_name/error for tool_failure).

#### 2. "telemetry.sh silently exits 0 when .planning/ directory does not exist"

**VERIFIED**

- Line 25: `[ -d "${PROJECT_DIR}/.planning" ] || exit 0` -- guard check that exits 0 if `.planning/` is absent.
- Tested: `echo '{}' | bash plugins/claude-super-team/scripts/telemetry.sh skill_start test-skill 2>/dev/null | wc -c` outputs `0` (no stdout).
- The script uses `set -uo pipefail` (line 16) but all guard exits are explicit `exit 0`, so the script never returns non-zero in the no-op path.

#### 3. "telemetry.sh auto-creates .planning/.telemetry/ if .planning/ exists"

**VERIFIED**

- Line 26: `mkdir -p "${TELEMETRY_DIR}" 2>/dev/null || exit 0` -- creates `.planning/.telemetry/` with `mkdir -p` (idempotent), silently exits 0 if creation fails.
- `TELEMETRY_DIR` is computed on line 23 as `"${PROJECT_DIR}/.planning/.telemetry"`.

#### 4. "telemetry.sh uses TELEMETRY_FILE env var when available, otherwise generates a deterministic fallback path"

**VERIFIED**

- Lines 51-56: If `TELEMETRY_FILE` is set and non-empty, `OUTFILE="${TELEMETRY_FILE}"`. Otherwise, generates `OUTFILE="${TELEMETRY_DIR}/${SKILL_NAME}-${DATE_SLUG}.jsonl"` using a UTC timestamp slug.

#### 5. "On skill_start events, telemetry.sh persists TELEMETRY_FILE to CLAUDE_ENV_FILE so subsequent hooks in the same session write to the same JSONL file"

**VERIFIED**

- Lines 58-61: Conditional block checks `EVENT_TYPE = skill_start`, `CLAUDE_ENV_FILE` is set, and `TELEMETRY_FILE` is not yet set. If all true, writes `export TELEMETRY_FILE="${OUTFILE}"` to `$CLAUDE_ENV_FILE`. This ensures subsequent hooks (Stop, SubagentStart, etc.) in the same session inherit the file path.

#### 6. ".planning/.telemetry/ is gitignored"

**VERIFIED**

- `.gitignore` contains `.planning/.telemetry/` (line 5 of 5 total lines).
- Existing entries are preserved: `__pycache__/`, `.DS_Store`, `.firecrawl/`, `.planning/.sessions/`.

### Artifacts

| Artifact | Existence | Substantive | Wired |
|----------|-----------|-------------|-------|
| `plugins/claude-super-team/scripts/telemetry.sh` | YES (129 lines) | YES (full implementation, all 6 event types, jq fallback, env persistence) | YES (writes JSONL to `.planning/.telemetry/*.jsonl`, called by SKILL.md hooks) |
| `.gitignore` | YES (5 lines) | YES (contains `.planning/.telemetry/` entry) | YES (Git will ignore telemetry output files) |

### Key Links

| From | To | Via | Status |
|------|----|-----|--------|
| `plugins/claude-super-team/scripts/telemetry.sh` | `.planning/.telemetry/*.jsonl` | File append (`>>`) writes JSONL to telemetry directory | VERIFIED -- line 127 appends to `${OUTFILE}` which resolves to `.planning/.telemetry/{skill}-{timestamp}.jsonl` |

---

## Plan 02: Hook Declarations in Orchestrator Skills

### Must-Have Truths

#### 1. "All 4 orchestrator skills declare telemetry hooks in YAML frontmatter"

**VERIFIED**

- All 4 SKILL.md files contain `hooks:` sections in their YAML frontmatter with telemetry hook declarations.
- Confirmed 6 `telemetry.sh` references in each file (24 total across 4 files).

#### 2. "SessionStart hooks call telemetry.sh with skill_start and the correct skill name"

**VERIFIED**

- `execute-phase/SKILL.md`: `telemetry.sh skill_start execute-phase` with `once: true`
- `plan-phase/SKILL.md`: `telemetry.sh skill_start plan-phase` with `once: true`
- `research-phase/SKILL.md`: `telemetry.sh skill_start research-phase` with `once: true`
- `brainstorm/SKILL.md`: `telemetry.sh skill_start brainstorm` with `once: true`
- Each uses empty matcher `""` to fire on all session start types.

#### 3. "Stop hooks call telemetry.sh with skill_end and the correct skill name"

**VERIFIED**

- All 4 files declare `Stop:` hooks calling `telemetry.sh skill_end {skill-name}` with the correct skill name.
- Stop hooks do NOT use `async: true` (correct -- fires once at session end).

#### 4. "SubagentStart/SubagentStop hooks capture agent lifecycle events asynchronously"

**VERIFIED**

- All 4 files declare `SubagentStart:` hooks calling `telemetry.sh agent_spawn {skill-name}` with `async: true`.
- All 4 files declare `SubagentStop:` hooks calling `telemetry.sh agent_complete {skill-name}` with `async: true`.

#### 5. "PostToolUse/PostToolUseFailure hooks capture tool usage asynchronously"

**VERIFIED**

- All 4 files declare `PostToolUse:` hooks calling `telemetry.sh tool_use {skill-name}` with `async: true`.
- All 4 files declare `PostToolUseFailure:` hooks calling `telemetry.sh tool_failure {skill-name}` with `async: true`.

#### 6. "Existing hooks in execute-phase (PreCompact, SessionStart compact matcher) are preserved unchanged"

**VERIFIED**

- `PreCompact:` hook with `matcher: "auto"` and `"EXECUTION STATE TO PRESERVE"` command is present and unchanged (line 8-11).
- `SessionStart:` has two list items: the original `matcher: "compact"` entry (line 13-16) and the new telemetry `matcher: ""` entry (line 17-21).
- The compact matcher command referencing `EXEC-PROGRESS.md`, `STATE.md`, `PROJECT.md`, and `PLAN.md` files is intact.

### Artifacts

| Artifact | Existence | Substantive | Wired |
|----------|-----------|-------------|-------|
| `plugins/claude-super-team/skills/execute-phase/SKILL.md` | YES | YES (6 telemetry hooks + 2 preserved existing hooks) | YES (hooks reference `${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh`) |
| `plugins/claude-super-team/skills/plan-phase/SKILL.md` | YES | YES (6 telemetry hooks in frontmatter) | YES (hooks reference `${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh`) |
| `plugins/claude-super-team/skills/research-phase/SKILL.md` | YES | YES (6 telemetry hooks in frontmatter) | YES (hooks reference `${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh`) |
| `plugins/claude-super-team/skills/brainstorm/SKILL.md` | YES | YES (6 telemetry hooks in frontmatter) | YES (hooks reference `${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh`) |

### Key Links

| From | To | Via | Status |
|------|----|-----|--------|
| `plugins/claude-super-team/skills/*/SKILL.md` | `plugins/claude-super-team/scripts/telemetry.sh` | Hook commands reference `${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh` | VERIFIED -- 24 total hook commands across 4 files, all using `${CLAUDE_PLUGIN_ROOT}/scripts/telemetry.sh` which resolves to the script at runtime |

### Hook Count Summary

| Skill | SessionStart | Stop | SubagentStart | SubagentStop | PostToolUse | PostToolUseFailure | Total |
|-------|-------------|------|---------------|--------------|-------------|-------------------|-------|
| execute-phase | 1 (+ compact) | 1 | 1 | 1 | 1 | 1 | 6 |
| plan-phase | 1 | 1 | 1 | 1 | 1 | 1 | 6 |
| research-phase | 1 | 1 | 1 | 1 | 1 | 1 | 6 |
| brainstorm | 1 | 1 | 1 | 1 | 1 | 1 | 6 |
| **Total** | **4** | **4** | **4** | **4** | **4** | **4** | **24** |

---

## Anti-Pattern Scan

| Pattern | Result |
|---------|--------|
| TODO/FIXME/HACK/XXX/PLACEHOLDER in telemetry.sh | NONE FOUND |
| Empty implementations in telemetry.sh | NONE -- all 6 case branches have substantive extraction logic |
| Stdout leaks in telemetry.sh | NONE -- all `echo` calls are within `$()` subshells or pipe to `>>` file append; tested: 0 bytes stdout output |
| Non-zero exit paths in telemetry.sh | NONE -- all exits are explicit `exit 0` or guarded `|| exit 0` |
| Stub hooks in SKILL.md files | NONE -- all 24 hook declarations have complete command strings |

---

## Verification Summary

| Truth | Plan | Status |
|-------|------|--------|
| telemetry.sh captures all 6 event types as JSONL | 01 | VERIFIED |
| telemetry.sh silently exits 0 when .planning/ missing | 01 | VERIFIED |
| telemetry.sh auto-creates .planning/.telemetry/ | 01 | VERIFIED |
| telemetry.sh uses TELEMETRY_FILE env var with fallback | 01 | VERIFIED |
| telemetry.sh persists TELEMETRY_FILE via CLAUDE_ENV_FILE on skill_start | 01 | VERIFIED |
| .planning/.telemetry/ is gitignored | 01 | VERIFIED |
| All 4 orchestrator skills declare telemetry hooks | 02 | VERIFIED |
| SessionStart hooks call skill_start with correct name | 02 | VERIFIED |
| Stop hooks call skill_end with correct name | 02 | VERIFIED |
| SubagentStart/SubagentStop hooks capture agent lifecycle async | 02 | VERIFIED |
| PostToolUse/PostToolUseFailure hooks capture tool usage async | 02 | VERIFIED |
| Existing execute-phase hooks preserved unchanged | 02 | VERIFIED |

**All 12 observable truths VERIFIED. No anti-patterns found. No blockers.**
