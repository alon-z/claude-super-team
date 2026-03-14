# Context for Phase 05: Workflow Validation & Gap Closure

## Phase Boundary (from ROADMAP.md)

**Goal:** Dogfood the updated marketplace on a real project to validate changes and discover remaining gaps

**Success Criteria:**
1. Full pipeline (`/new-project` through `/execute-phase`) runs successfully on a test project using the updated skills/agents
2. Any newly discovered gaps are documented with proposed solutions
3. At least one gap is addressed and the fix is integrated

**What's in scope for this phase:**
- Validation checklist documenting which skills were exercised post-audit on the tevel project
- Gap identification from real-world usage analysis and codebase exploration
- Fix for the highest-impact gap: plan-phase startup speed (time to first agent spawn)

**What's explicitly out of scope:**
- Running a fresh test project (tevel provides sufficient validation evidence)
- Fixing all identified gaps (only the highest-impact one is required)
- Execute-phase speed optimization (apply learnings from plan-phase fix later)

---

## Codebase Context

**Existing related code:**
- `plugins/claude-super-team/skills/plan-phase/SKILL.md`: The primary fix target -- orchestrates planner agent spawning with heavy upfront context loading
- `plugins/claude-super-team/skills/plan-phase/gather-data.sh`: Pre-computes PROJECT, ROADMAP, STATE, PHASE_STATUS, ROADMAP_PHASES sections
- `plugins/claude-super-team/skills/execute-phase/SKILL.md`: Secondary target -- same startup speed issue, fix learnings should transfer
- `plugins/claude-super-team/skills/execute-phase/gather-data.sh`: Pre-computes PROJECT, ROADMAP, STATE, PREFERENCES, PHASE_PLANS, PHASE_COMPLETION, GIT sections
- `plugins/claude-super-team/scripts/phase-utils.sh`: Shared normalization (centralized in Phase 4)

**Established patterns:**
- gather-data.sh scripts run upfront to pre-compute context sections
- Skills read full PROJECT.md, ROADMAP.md, STATE.md regardless of phase complexity
- All prior phase artifacts (SUMMARY, PLAN, CONTEXT) loaded for cross-phase context
- Codebase docs (ARCHITECTURE.md, STACK.md, etc.) loaded when relevant

**Integration points:**
- Plan-phase spawns planner agents via Task tool with embedded context
- Planner agents receive the full context dump as part of their prompt
- CONTEXT.md and RESEARCH.md are loaded and forwarded to planners

**Constraints from existing code:**
- Skills are Markdown-driven -- no programmatic logic beyond bash scripts
- gather-data.sh output is consumed as a single block by the skill
- Context loading happens in the skill body (LLM processing time), not in bash

---

## Cross-Phase Dependencies

**From Phase 1 (Capability Mapping)** [executed]:
- Created reference of all Claude Code plugin primitives
- Documented when to use skills vs agents vs hooks
- Provides: audit standard that Phase 5 validates against

**From Phase 2 (Skill Audit)** [executed]:
- Audited all skills with per-skill recommendations
- Classified each as skill/agent/hybrid
- Provides: gap identification framework

**From Phase 3 (Apply Audit)** [executed]:
- Fixed frontmatter across all skills (Bash restrictions, tool access)
- Provides: the updated skills that tevel validated

**From Phase 4 (Harden Fragile Areas)** [executed]:
- Centralized phase-utils.sh, decomposed build SKILL.md
- Provides: the hardened foundation to validate (thin validation coverage)

**Assumptions about prior phases:**
- All frontmatter fixes from Phase 3 are functioning correctly (tevel evidence supports this)
- Phase-utils.sh centralization works for all phase numbering patterns (partial coverage)

---

## Implementation Decisions

### Validation Scope

**Decision:** Use tevel project as validation evidence with a per-skill checklist. No fresh test project needed.

**Rationale:** Tevel ran 13+ phases (25, 35, 39-44, 42.1-42.5) after phases 2-3 completed (2026-02-25). This exercised the full pipeline with post-audit skills. Phase 4's centralization (2026-03-12) has thinner coverage but overlaps with tevel's last feedback phases.

**Constraints:** Validation checklist must map each skill to specific tevel phases that exercised it post-audit. Skills not exercised post-audit must be noted.

### Gap Priority

**Decision:** Focus on the highest-impact gap from real usage: plan-phase startup speed (time to first agent spawn). Other gaps are documented but not fixed.

**Rationale:** User's primary friction point during 48-phase tevel build. Simple phases (single-screen UI change) take the same startup time as complex multi-service features. The bottleneck is between gather-data.sh completing and the first planner agent being spawned -- likely LLM processing time through loaded context.

**Constraints:** Must investigate where time is actually spent (context loading vs LLM reasoning) before implementing a fix. Fix should target plan-phase first; learnings transfer to execute-phase later.

### Fix Approach

**Decision:** Phase 5 investigates the plan-phase startup bottleneck and implements a fix. Execute-phase optimization is deferred.

**Rationale:** Plan-phase is invoked more frequently (every phase needs planning). Fixing it first provides immediate value and establishes patterns for execute-phase optimization.

**Constraints:** The fix must not break existing plan-phase functionality. Validation via running plan-phase on at least one phase before and after the fix.

### Evidence Format

**Decision:** All validation evidence and gap documentation lives in CONTEXT.md (this file), consumed by the planner.

**Rationale:** Single artifact keeps planning context consolidated. No need for separate VERIFICATION.md or GAPS.md.

**Constraints:** Tevel's STATE.md concerns are domain-specific (API quirks, library gotchas) and not mined for skill gaps.

---

## Claude's Discretion

- **Startup speed investigation methodology**: Claude determines how to profile the plan-phase startup bottleneck (e.g., timing gather-data.sh vs context reads vs LLM processing, analyzing what context is loaded vs what's actually used by planners)
- **Specific fix implementation**: Claude determines the best approach to reduce time-to-first-agent-spawn (adaptive context loading, lazy loading, parallel reads, context pruning, or other techniques)
- **Validation checklist granularity**: Claude determines appropriate detail level for per-skill validation entries

---

## Specific Ideas

- The gather-data.sh scripts are instant (user confirmed). The bottleneck is likely the LLM reading and reasoning through the large context block before deciding to spawn agents.
- Plan-phase loads PROJECT.md + ROADMAP.md + STATE.md + all codebase docs + all prior phase artifacts + CONTEXT.md + RESEARCH.md -- some of this may be unnecessary for simple phases.
- Consider whether the planner agent prompt can be pre-assembled in gather-data.sh (bash) rather than having the skill LLM process and re-format it.

---

## Deferred Ideas

- **Execute-phase startup optimization**: Same issue as plan-phase but deferred -- apply learnings from plan-phase fix
- **Compaction resilience in brainstorm/research-phase/code**: Only execute-phase has PreCompact/SessionStart hooks. Other long-running skills lack them. Low urgency given current usage patterns.
- **Gather-data.sh SKIP flag inconsistency**: Not all skills use the same pattern for context-aware skipping. Polish issue, not blocking.
- **Argument-hint validation**: No static check that actual parameter parsing matches declared hints. Polish issue.
- **Skill nesting documentation**: Which skills can safely call others via Skill tool is undocumented. Low urgency.

---

## Validation Checklist (Tevel Evidence)

Skills exercised post-audit (after 2026-02-25) on tevel project:

| Skill | Post-Audit Usage | Tevel Phases |
|-------|-----------------|--------------|
| /new-project | Pre-audit (2026-03-01) | Phase 1 init |
| /map-codebase | Post-audit (2026-03-08 refresh) | Codebase refresh |
| /create-roadmap | Post-audit (multiple modifications) | Phases 35-38, 39-45, 47-48 additions |
| /brainstorm | Unknown | Not confirmed |
| /discuss-phase | Post-audit | Phases 25, 33, 39, 41-42 |
| /research-phase | Post-audit | Phases 25, 33, 34 |
| /plan-phase | Post-audit | Phases 25, 35, 39, 41-44, 42.1 |
| /execute-phase | Post-audit | Phases 25, 35, 39, 41-44, 42.1-42.5 |
| /progress | Post-audit | Used throughout |
| /phase-feedback | Post-audit | Phases 42.1, 42.2, 42.3, 42.4, 42.5 |
| /quick-plan | Unknown | Not confirmed |
| /code | Unknown | Not confirmed |
| /build | Post-audit (extended mode) | Phase 34 autonomous build |
| /add-security-findings | Not used | N/A |
| /cst-help | Unknown | Not confirmed |
| /optimize-artifacts | Unknown | Not confirmed |

**Gaps in validation coverage:**
- `/new-project` was used pre-audit (but the skill is simple -- low risk)
- `/brainstorm`, `/quick-plan`, `/code`, `/cst-help`, `/optimize-artifacts` -- unconfirmed post-audit usage
- `/add-security-findings` -- never used on tevel

---

## Identified Gaps (From Codebase Exploration)

| # | Gap | Category | Impact | Status |
|---|-----|----------|--------|--------|
| 1 | Plan-phase/execute-phase startup speed | Robustness | HIGH -- user's primary friction point | **Fix in Phase 5** |
| 2 | Compaction resilience incomplete | Robustness | Medium -- only execute-phase has hooks | Documented, deferred |
| 3 | gather-data.sh SKIP flag inconsistency | Consistency | Low -- works but inconsistent | Documented, deferred |
| 4 | No skill nesting documentation | Documentation | Low -- which skills can call others | Documented, deferred |
| 5 | Missing argument-hint in cst-help | Polish | Low -- minor frontmatter gap | Documented, deferred |
| 6 | No argument-hint/parsing validation | Polish | Low -- hints may not match actual parsing | Documented, deferred |

---

*Created: 2026-03-13 via /discuss-phase 5*
