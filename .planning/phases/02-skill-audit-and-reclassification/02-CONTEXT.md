# Context for Phase 2: Skill Audit & Reclassification

## Phase Boundary (from ROADMAP.md)

**Goal:** Systematically review every skill in the marketplace against the capability reference, producing per-skill recommendations

**Success Criteria:**
1. Every skill across all 3 plugins has been audited with findings documented
2. Each skill has a classification: remain as skill, convert to agent, hybrid, or needs feature additions
3. Specific frontmatter/feature gaps are identified per skill (missing tool restrictions, wrong model, missing context fork, etc.)

**What's in scope for this phase:**
- Reviewing all 17 skills and 1 agent across 3 plugins
- Classifying each as: remain as skill, convert to agent, hybrid, or needs feature additions
- Identifying specific frontmatter gaps (missing `allowed-tools`, wrong `model`, missing `context: fork`, etc.)
- Documenting per-skill findings with actionable recommendations for Phase 3

**What's explicitly out of scope:**
- Implementing any changes to skills (Phase 3)
- Creating new skills or agents (Phase 3)
- Hardening fragile areas like phase numbering (Phase 4)
- Empirical testing of capability features (deferred to Phase 3 implementation)

---

## Codebase Context

**Existing related code:**
- 17 SKILL.md files across 3 plugins with varying frontmatter completeness
- 1 agent definition (`plugins/claude-super-team/agents/phase-researcher.md`) as the exemplary agent pattern
- `ORCHESTRATION-REFERENCE.md` at project root -- existing capability reference (Phase 1 will extend this)
- `.claude-plugin/marketplace.json` -- marketplace manifest registering all 3 plugins

**Established patterns:**
- 16 unique frontmatter fields identified across skills: `name`, `description`, `allowed-tools`, `model`, `context`, `argument-hint`, `disable-model-invocation`, and others
- Two context modes in use: implicit `skill` (14 skills) and explicit `context: fork` (2 skills: map-codebase, progress)
- Model override used for 6 skills: opus (map-codebase, phase-researcher), haiku (progress, cst-help, marketplace-manager), sonnet (github-issue-manager, skill-creator)
- `disable-model-invocation: true` used for 2 pure orchestrators (map-codebase, add-security-findings)
- Bash tool restrictions are ad-hoc: some skills use granular patterns (`Bash(gh issue create *)`), others have blanket `Bash` access
- Asset/reference file pattern: skills with complex behavior use `assets/` for templates and `references/` for guides

**Integration points:**
- Phase 1 capability reference document will be the primary audit checklist
- Phase 3 will consume audit findings to implement changes
- CLAUDE.md documents conventions that the audit should verify compliance with

**Constraints from existing code:**
- No hooks currently implemented in any skill or agent
- Agent teams are experimental (behind env flag)
- Some frontmatter fields (`memory`, `maxTurns`, `user-invocable`) are documented but unused in this codebase
- Skills that spawn subagents embed all context inline (no `@` file references across Task boundaries)

---

## Cross-Phase Dependencies

**From Phase 1 (Claude Code Capability Mapping)** [discussed + researched]:
- Will produce: A companion capability reference document covering all plugin primitives, frontmatter fields, hooks, tools, and orchestration patterns
- Will provide: The audit checklist -- every skill in Phase 2 is compared against this reference
- Key finding from research: Official docs show 10 canonical skill frontmatter fields and 11 agent fields; some fields used in this codebase are agent-only fields inherited via `context: fork`
- Research identified specific gaps: Output Styles, LSP Servers, dynamic context injection (`!`command``), `$N` argument shorthand, `once` hook field, `statusMessage` hook field -- all potential adoption opportunities the audit should flag

**Assumptions about prior phases:**
- Phase 1's capability reference must exist before the audit can systematically compare skills against it. If Phase 1 is not yet complete, the audit can use Phase 1's RESEARCH.md findings as a provisional reference.
- The capability reference must clearly distinguish skill-only vs agent-only vs shared frontmatter fields

---

## Implementation Decisions

### Execution Approach

**Decision:** Manual interactive review -- each skill is presented individually with its frontmatter, behavior summary, and capability comparison. The user makes the final classification decision (remain/convert/hybrid/needs additions) for each skill.

**Rationale:** Manual review ensures the user validates every classification decision rather than accepting automated judgments. Given only 17 skills + 1 agent, interactive review is feasible and produces higher-confidence results.

**Constraints:** Agent presents findings, gaps, and recommendations per skill. User makes the final call. No batch auto-classification.

### Review Grouping

**Decision:** Review skills one at a time with deep focus per skill. No batching by plugin or role.

**Rationale:** Deep-dive per skill prevents shallow analysis. Each skill has unique behavior and context that benefits from focused attention.

**Constraints:** Must complete all 17 skills + 1 agent. Each review should include: current frontmatter, behavior analysis, capability gaps, and classification options.

### Review Order

**Decision:** Follow the pipeline workflow sequence: new-project -> create-roadmap -> discuss-phase -> research-phase -> plan-phase -> execute-phase -> progress -> quick-plan -> phase-feedback -> brainstorm -> add-security-findings -> cst-help -> map-codebase, then marketplace-utils skills (marketplace-manager, skill-creator), then task-management skills (linear-sync, github-issue-manager), and finally the phase-researcher agent.

**Rationale:** Pipeline order matches the user's mental model of the workflow. Reviewing skills in the order they're used reveals cross-skill consistency issues naturally.

**Constraints:** All 17 skills and 1 agent must be reviewed. No skills skipped.

---

## Claude's Discretion

- **Audit depth per skill**: How deep to go beyond frontmatter -- whether to also review prompt quality, logic structure, and behavioral patterns (decided per skill based on complexity)
- **Output format**: How to structure the per-skill audit findings document -- table-based vs narrative, single document vs per-skill files
- **Classification criteria thresholds**: What signals indicate "convert to agent" vs "hybrid" vs "needs feature additions" -- Claude should propose criteria based on the capability reference

---

## Specific Ideas

- Phase 1 RESEARCH.md already identified several concrete gaps per skill (missing `allowed-tools` on marketplace-manager, missing `argument-hint` on 3 skills, inconsistent `disable-model-invocation` on orchestrators) -- the audit should validate and expand on these findings
- The audit should reference the "In use" / "Documented but unused" / "Unverified" adoption heatmap from the Phase 1 capability reference
- Each skill review should explicitly check: (1) frontmatter completeness, (2) correct model selection, (3) appropriate context mode, (4) tool restrictions, (5) skill vs agent classification

---

## Deferred Ideas

- Implementing any frontmatter fixes or reclassifications (Phase 3 scope)
- Creating new agents from skills identified for conversion (Phase 3 scope)
- Hardening phase numbering or STATE.md coordination (Phase 4 scope)
- Testing capabilities empirically by creating scratch skills (Phase 3 scope)

---

*Created: 2026-02-11 via /discuss-phase 2*
