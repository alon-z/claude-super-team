# Roadmap: Claude Super Team

## Overview

Evolve the Claude Super Team plugin marketplace from a working but unoptimized state to one where every skill and agent leverages the right Claude Code primitive for its purpose. The journey starts with understanding what Claude Code offers, auditing existing skills against those capabilities, applying fixes and reclassifications, hardening fragile areas, and validating the whole workflow end-to-end.

## Phases

- [ ] **Phase 1: Claude Code Capability Mapping** - Research and document all available plugin primitives as an audit reference
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
| 1. Claude Code Capability Mapping | Not started | - |
| 2. Skill Audit & Reclassification | Not started | - |
| 3. Apply Audit Recommendations | Not started | - |
| 4. Harden Fragile Areas | Not started | - |
| 5. Workflow Validation & Gap Closure | Not started | - |

---
*Created: 2026-02-11*
