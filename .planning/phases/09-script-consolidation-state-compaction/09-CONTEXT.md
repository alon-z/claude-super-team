# Context for Phase 9: Script Consolidation & State Compaction

## Phase Boundary (from ROADMAP.md)

**Goal:** Centralize duplicated infrastructure scripts and add state compaction, following the phase-utils.sh pattern from Phase 4

**Success Criteria:**
1. A `gather-common.sh` script exists in `scripts/` with shared functions (emit_project_section, emit_phase_completion, emit_sync_check, emit_preferences) and all 11 gather-data.sh scripts source it instead of duplicating logic
2. A `create_phase_dir()` function exists in `phase-utils.sh` that derives phase name from ROADMAP.md, creates the directory, and returns the path -- replacing 4 inline pipelines across discuss-phase, plan-phase, quick-plan, and execute-phase
3. Execute-phase compaction step moves completed-phase decisions in STATE.md to a `### Decision Archive` section, keeping only current/upcoming decisions in the active section

**What's in scope for this phase:**
- Extracting shared gather functions into `scripts/gather-common.sh`
- Adding `create_phase_dir()` to existing `scripts/phase-utils.sh`
- Updating all 11 gather-data.sh scripts to source the shared script
- Updating 4 skills with inline phase directory creation pipelines
- Extending execute-phase compaction to archive STATE.md decisions
- Auditing every skill and agent's `allowed-tools` frontmatter to ensure permissions are correct, complete, and not overly broad

**What's explicitly out of scope:**
- Changing gather-data.sh output format or section structure
- Modifying skill behavior beyond sourcing the shared script
- Removing per-skill gather-data.sh files entirely (they still contain skill-specific sections)
- Refactoring ROADMAP.md compaction logic
- Converting skills to agents or changing skill classification (already done in Phase 3)

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/scripts/phase-utils.sh`: Existing shared script with `normalize_phase()` and `find_phase_dir()` -- the proven pattern to follow
- `plugins/claude-super-team/skills/*/gather-data.sh` (11 files): Each independently implements PROJECT/ROADMAP/STATE loading with SKIP_ flags, phase completion counting, and roadmap parsing
- `plugins/claude-super-team/scripts/progress-gather.sh`: Standalone duplicate of progress/gather-data.sh (partially diverged)
- `plugins/claude-super-team/skills/execute-phase/SKILL.md`: Contains existing ROADMAP.md compaction step to extend

**Established patterns:**
- SKIP_PROJECT/SKIP_ROADMAP/SKIP_STATE flags: Convention for context-aware skipping when files are already loaded by a parent invocation
- phase-utils.sh sourcing: Skills source `"$(dirname "$0")/../../scripts/phase-utils.sh"` at the top of gather-data.sh
- Section-based output: Gather scripts emit `=== SECTION_NAME ===` headers parsed by skills

**Integration points:**
- All 11 gather-data.sh scripts: Must source gather-common.sh and replace duplicated sections
- 4 skills (discuss-phase, plan-phase, quick-plan, execute-phase): Must replace inline phase directory pipelines with create_phase_dir()
- execute-phase compaction step: Must add STATE.md decision archival alongside existing ROADMAP.md compaction

**Constraints from existing code:**
- Gather scripts must maintain backward compatibility: same section names, same output format
- SKIP_ flags must work identically after refactoring
- Skills that source phase-utils.sh already use a relative path pattern -- gather-common.sh should follow the same convention
- `allowed-tools` in SKILL.md and agent .md frontmatter controls what each skill/agent can access at runtime -- missing tools cause silent failures, overly broad tools grant unnecessary access

---

## Cross-Phase Dependencies

**From Phase 4 (Harden Fragile Areas)** [executed]:
- `phase-utils.sh`: Created the shared script pattern with `normalize_phase()` and `find_phase_dir()` that this phase extends
- Build SKILL.md decomposition: Established the pattern of extracting shared logic into reference documents

**Assumptions about prior phases:**
- The 11 gather-data.sh scripts remain structurally similar enough to extract common functions
- The SKIP_ flag convention is stable and won't change during this phase

---

## Implementation Decisions

### Shared Script Architecture

**Decision:** Create `gather-common.sh` as a sourceable library (like phase-utils.sh), not a standalone runner

**Rationale:** Per-skill gather-data.sh files still need skill-specific sections. The shared script provides building blocks; each skill assembles its own output.

**Constraints:** Must not change the output format of any gather-data.sh script -- downstream skills parse section headers and content.

### Tool Permissions Audit

**Decision:** Review every skill and agent's `allowed-tools` frontmatter against what tools they actually use at runtime. Fix any gaps (missing tools) or excess (unnecessary tools).

**Rationale:** Phase 3 applied audit recommendations but the codebase has evolved since (Phases 4-8 added/modified skills). Tool permissions may have drifted -- skills may reference tools not in their allowed list, or agents spawned by skills may lack tools they need.

**Constraints:** Must verify against actual usage in the SKILL.md body and agent .md instructions, not just what seems reasonable.

### STATE.md Compaction Approach

**Decision:** Move completed-phase decisions below a `### Decision Archive` heading. Gather scripts only emit content above the archive delimiter.

**Rationale:** No data is lost (archive preserved in file). Active context stays lean. Same pattern as ROADMAP.md compaction for completed phase details.

**Constraints:** Must reliably associate decisions with phase numbers to determine which to archive. Gather scripts need to know the archive delimiter to stop reading.

---

## Claude's Discretion

- Exact function names and signatures for gather-common.sh (emit_project_section, emit_phase_completion, etc. are suggestions)
- How to handle edge cases where gather-data.sh scripts have subtly different output formats for the same computation
- Whether to also compact the PREFERENCES section of STATE.md or leave it as-is

This CONTEXT.md was auto-generated from a brainstorm session. Run /discuss-phase for deeper exploration of gray areas.

---

## Specific Ideas

- Follow the exact same sourcing pattern used by phase-utils.sh: `source "$(dirname "$0")/../../scripts/gather-common.sh"`
- The PHASE_COMPLETION logic (counting plans vs summaries) appears in at least 3 scripts with slightly different output formats -- centralization should normalize these
- The `create_phase_dir()` function should accept a phase number, grep ROADMAP.md for the phase name, slugify it, and create the directory
- The decision archive delimiter could be `### Decision Archive` -- simple to grep for

---

## Deferred Ideas

- Frontmatter-driven gather-data (declaring needed sections in SKILL.md frontmatter instead of per-skill scripts) -- deferred from brainstorm session as a more ambitious refactor
- Gather-once caching (`.planning/.cache/` for parsed state across skill invocations) -- deferred as medium effort with less clear payoff

---

## Examples

Not available from brainstorm session.
