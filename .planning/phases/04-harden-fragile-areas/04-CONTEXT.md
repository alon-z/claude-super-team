# Context for Phase 4: Harden Fragile Areas

## Phase Boundary (from ROADMAP.md)

**Goal:** Address technical debt and fragile areas identified in the codebase concerns audit

**Success Criteria:**
1. Phase numbering logic is consistent across all skills that handle phase numbers (no formatting discrepancies)
2. ~~STATE.md/ROADMAP.md coordination includes validation~~ -- **Already satisfied by Phase 1.6** (progress skill detects and reports sync issues)
3. Large skill files (>500 lines) are decomposed into skill + reference documents without behavior changes

**What's in scope for this phase:**
- Centralize phase numbering logic into a shared bash script (`phase-utils.sh`)
- Decompose `build/SKILL.md` (1084 lines) into skill + reference documents, target under 500 lines

**What's explicitly out of scope:**
- STATE/ROADMAP sync hardening (already done in Phase 1.6)
- Roadmap annotation fragility in quick-plan/phase-feedback
- Simplifier plugin dependency hardening
- Incremental codebase mapping merge logic
- Parallel agent context duplication
- Plan-execution schema validation
- Rollback/undo mechanism
- Decomposition of any file other than build/SKILL.md (progress, cst-help, agents, references, ORCHESTRATION-REFERENCE.md all stay as-is)

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/discuss-phase/SKILL.md` (lines 40-46): Phase number normalization with decimal handling
- `plugins/claude-super-team/skills/execute-phase/SKILL.md` (lines 103-109): Identical normalization logic
- `plugins/claude-super-team/skills/plan-phase/SKILL.md` (lines 61-67): Identical normalization logic
- `plugins/claude-super-team/skills/plan-phase-workspace/skill-snapshot/SKILL.md` (lines 61-67): Identical normalization logic
- `plugins/claude-super-team/skills/quick-plan/SKILL.md` (lines 63-85): Divergent phase extraction from STATE.md + decimal computation
- `plugins/claude-super-team/skills/phase-feedback/SKILL.md` (line 60): Simpler padding with `printf "%02d"`
- `plugins/claude-super-team/skills/research-phase/SKILL.md` (line 49+): Normalization inline
- `plugins/claude-super-team/skills/build/SKILL.md` (1084 lines): Largest skill, orchestrates entire pipeline

**Established patterns:**
- Skills use bash code blocks inline for phase number parsing
- `gather-data.sh` scripts handle pre-loading of planning files
- Reference documents in `references/` are read inline by skills
- `$CLAUDE_SKILL_DIR` provides the skill's base directory path at runtime

**Integration points:**
- `phase-utils.sh` must be sourceable from any skill via `$CLAUDE_SKILL_DIR` relative path
- Build skill references must be loadable via the existing Read tool pattern skills already use

**Constraints from existing code:**
- Skills can only run bash via allowed `Bash(pattern)` declarations in frontmatter
- No shared import mechanism exists yet; this will be the first shared script
- Agent definitions (phase-researcher.md) embed all context inline; they don't source bash scripts

---

## Cross-Phase Dependencies

**From Phase 1 (Claude Code Capability Mapping)** [executed]:
- Built: ORCHESTRATION-REFERENCE.md documenting all plugin primitives
- Provides: Understanding of skill frontmatter, agent definitions, hooks, context behavior

**From Phase 2 (Skill Audit & Reclassification)** [executed]:
- Built: Per-skill audit with 33 identified gaps
- Provides: Classification of all skills (all remain as skills, none converted to agents)

**From Phase 3 (Apply Audit Recommendations)** [executed]:
- Built: All 33 frontmatter gaps fixed, specific Bash patterns on all skills
- Provides: Clean frontmatter baseline; every skill has specific `Bash(pattern *)` entries

**Assumptions about prior phases:**
- All skills have correct `allowed-tools` declarations (Phase 3 verified this)
- Any new `Bash(source *)` or similar pattern needed for phase-utils.sh must be added to skill frontmatter

---

## Implementation Decisions

### Phase Number Centralization

**Decision:** Create a shared bash script at `plugins/claude-super-team/scripts/phase-utils.sh` containing:
1. `normalize_phase()` -- zero-pad and format phase numbers (integer and decimal)
2. `find_phase_dir()` -- resolve a phase number to its `.planning/phases/{NN}-{name}/` directory path

**Rationale:** 4 skills have identical copy-pasted normalization code, and directory resolution is also duplicated. A shared script eliminates drift and provides a single place to fix edge cases (e.g., `2.10` vs `2.1`).

**Constraints:**
- Skills must `source` the script, which may require adding `Bash(source *)` or `Bash(. *)` to frontmatter allowed-tools
- Quick-plan's STATE.md extraction and decimal computation logic: Claude's discretion on whether to centralize or keep inline (see below)

### Build Skill Decomposition

**Decision:** Extract procedural blocks from `build/SKILL.md` (1084 lines) into `references/` files. Target: SKILL.md under 500 lines.

**Rationale:** build/SKILL.md is the largest file in the codebase at over 2x the 500-line threshold. Extracting self-contained procedural blocks into references maintains behavior while improving maintainability.

**Constraints:**
- Must not change any behavior -- pure structural refactor
- Extracted references are read inline by the skill using the existing Read tool pattern
- Natural split points: sprint execution loop, compaction recovery, phase validation logic

---

## Claude's Discretion

- **Quick-plan centralization scope**: Whether quick-plan's divergent logic (STATE.md phase extraction, next decimal computation) should move into phase-utils.sh or remain inline. Decide based on whether other skills could reuse that logic.
- **Build decomposition split points**: Which specific blocks to extract from build/SKILL.md into references. Identify natural boundaries that create cohesive, self-contained reference documents.

---

## Specific Ideas

- Script location: `plugins/claude-super-team/scripts/phase-utils.sh`
- Skills source it via: `source "$CLAUDE_SKILL_DIR/../../scripts/phase-utils.sh"` (or similar relative path)
- Build references location: `plugins/claude-super-team/skills/build/references/`

---

## Deferred Ideas

- Decompose other large files (progress 564, cst-help 523, phase-researcher 680, ORCHESTRATION-REFERENCE 892, troubleshooting.md 597, templates.md 546, researcher-guide.md 525) -- deferred, user chose build only
- Roadmap annotation hardening in quick-plan/phase-feedback -- deferred to future phase
- Simplifier plugin availability check/fallback -- deferred
- Incremental mapping merge centralization -- deferred
- Plan-execution schema validation -- deferred
- Auto-repair for STATE/ROADMAP desync -- deferred (detection is sufficient per Phase 1.6)

---

*Created: 2026-03-12 via /discuss-phase 4*
