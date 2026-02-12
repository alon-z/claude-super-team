# Roadmap: Claude Super Team

## Overview

Evolve the Claude Super Team plugin marketplace from a working but unoptimized state to one where every skill and agent leverages the right Claude Code primitive for its purpose. The journey starts with understanding what Claude Code offers, auditing existing skills against those capabilities, applying fixes and reclassifications, hardening fragile areas, and validating the whole workflow end-to-end.

## Phases

- [ ] **Phase 1: Claude Code Capability Mapping** - Research and document all available plugin primitives as an audit reference
- [ ] Phase 1.5: Add research detection to phase-feedback skill (QUICK)
- [ ] Phase 1.4: Add compaction resilience to execute-phase (QUICK)
- [ ] Phase 1.6: Add planning file sync detection to progress skill (QUICK)
- [ ] Phase 1.7: Add per-project toggle to disable simplifier agent in execute-phase (QUICK)
- [ ] **Phase 2: Skill Audit & Reclassification** - Systematically review every skill and classify as skill, agent, or hybrid
- [ ] **Phase 3: Apply Audit Recommendations** - Implement reclassifications, add missing features, fix frontmatter gaps
- [ ] **Phase 4: Harden Fragile Areas** - Address tech debt, phase numbering, state coordination, and large file decomposition
- [ ] **Phase 5: Workflow Validation & Gap Closure** - Dogfood updated marketplace on a real project, discover and fix remaining gaps

## Phase Details

### Phase 1: Claude Code Capability Mapping
**Goal**: Create a complete reference of Claude Code's plugin primitives -- skills, agents, hooks, frontmatter options, context behavior -- as the standard to audit against
**Depends on**: Nothing (first phase)
**Requirements**: Foundation for systematic audit (Active req 1) and feature usage (Active req 3)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A capability reference document exists covering all skill frontmatter fields, agent definition syntax, hooks, and context behavior options
  2. Each capability is documented with when to use it, examples, and tradeoffs (skill vs agent vs hook)
  3. The reference is accurate against the current Claude Code version (verified by testing at least 3 capabilities)

### Phase 1.5: Add Research Detection to Phase-Feedback Skill (QUICK)
**Goal:** Make phase-feedback detect when feedback requires research (e.g., missing package docs, unfamiliar APIs) and spawn a research agent inline before planning
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. Phase-feedback skill includes an LLM analysis step between feedback collection and planner spawning that determines if research is needed
2. When research is needed, the skill spawns the phase-researcher agent inline and passes RESEARCH.md to the planner

### Phase 1.4: Add Compaction Resilience to Execute-Phase (QUICK)
**Goal:** Make execute-phase survive context compaction during long team-mode executions by adding skill-scoped hooks and EXEC-PROGRESS.md tracking
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. Execute-phase skill has PreCompact and SessionStart(compact) hooks in frontmatter that re-inject critical state after compaction
2. Execute-phase writes EXEC-PROGRESS.md during execution tracking wave/plan completion, team name, and teammate state
3. cst-help is updated with guidance on compaction resilience and CLAUDE_AUTOCOMPACT_PCT_OVERRIDE configuration

### Phase 1.6: Add Planning File Sync Detection to Progress Skill (QUICK)
**Goal:** Make `/progress` detect and report sync issues between planning files -- missing phase directories, sub-phases absent from ROADMAP.md, STATE.md pointing to nonexistent phases, and other desync conditions
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. `/progress` includes a "Sync Issues" section that detects phase directories not listed in ROADMAP.md and ROADMAP.md phases without matching directories
2. `/progress` reports when STATE.md references a phase that doesn't exist in ROADMAP.md or has no directory

### Phase 1.7: Add Per-Project Toggle to Disable Simplifier Agent in Execute-Phase (QUICK)
**Goal:** Allow users to disable the code-simplifier agent step in execute-phase on a per-project basis via a persistent setting
**Type:** Quick phase -- lightweight planning, no research/verification
**Inserted before:** Phase 2

Success Criteria:
1. A `simplifier` preference in STATE.md (or equivalent per-project config) controls whether the code-simplifier step runs during execution
2. Execute-phase respects the setting in both task mode and teams mode, skipping simplification when disabled

### Phase 2: Skill Audit & Reclassification
**Goal**: Systematically review every skill in the marketplace against the capability reference, producing per-skill recommendations
**Depends on**: Phase 1
**Requirements**: Systematic audit (Active req 1), evaluate skill vs agent (Active req 2)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Every skill across all 3 plugins has been audited with findings documented
  2. Each skill has a classification: remain as skill, convert to agent, hybrid, or needs feature additions
  3. Specific frontmatter/feature gaps are identified per skill (missing tool restrictions, wrong model, missing context fork, etc.)

### Phase 3: Apply Audit Recommendations
**Goal**: Implement all reclassification decisions and feature fixes from the audit
**Depends on**: Phase 2
**Requirements**: Convert skills to agents (Active req 2), use available features (Active req 3)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Skills classified for conversion are converted to agents (or hybrid) with working implementations
  2. All frontmatter gaps are fixed -- every skill uses correct tool restrictions, model selection, context behavior, and argument hints
  3. No regression -- every skill/agent functions correctly after changes (verified by manual execution of key workflows)

### Phase 4: Harden Fragile Areas
**Goal**: Address technical debt and fragile areas identified in the codebase concerns audit
**Depends on**: Phase 3
**Requirements**: Stability improvements supporting ongoing usage (Active req 4)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Phase numbering logic is consistent across all skills that handle phase numbers (no formatting discrepancies)
  2. STATE.md/ROADMAP.md coordination includes validation -- `/progress` detects and reports desync
  3. Large skill files (>500 lines) are decomposed into skill + reference documents without behavior changes

### Phase 5: Workflow Validation & Gap Closure
**Goal**: Dogfood the updated marketplace on a real project to validate changes and discover remaining gaps
**Depends on**: Phase 4
**Requirements**: Add missing capabilities (Active req 4)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Full pipeline (`/new-project` through `/execute-phase`) runs successfully on a test project using the updated skills/agents
  2. Any newly discovered gaps are documented with proposed solutions
  3. At least one gap is addressed and the fix is integrated

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Claude Code Capability Mapping | Complete | 2026-02-11 |
| 1.1 Progress Phase Steps (QUICK) | Complete | 2026-02-11 |
| 1.2 Execute Branch Guard Team Log (QUICK) | Complete | 2026-02-12 |
| 1.3 Brainstorm Creates Context (QUICK) | Complete | 2026-02-12 |
| 1.4 Execute Compaction Resilience (QUICK) | Complete | 2026-02-11 |
| 1.5 Feedback Research Detection (QUICK) | Not started | - |
| 1.6 Progress Sync Detection (QUICK) | Not started | - |
| 1.7 Simplifier Toggle (QUICK) | Not started | - |
| 2. Skill Audit & Reclassification | Planned | - |
| 3. Apply Audit Recommendations | Not started | - |
| 4. Harden Fragile Areas | Not started | - |
| 5. Workflow Validation & Gap Closure | Not started | - |

---
*Created: 2026-02-11*
