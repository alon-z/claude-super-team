# Codebase Concerns

**Analysis Date:** 2026-02-11

## Tech Debt

**Large skill files exceed maintainability threshold:**
- Issue: Several SKILL.md files exceed 500 lines, making them harder to maintain and reason about
- Files: `plugins/claude-super-team/skills/execute-phase/SKILL.md` (564 lines), `plugins/claude-super-team/skills/cst-help/SKILL.md` (501 lines)
- Impact: Harder for maintainers to update orchestration logic, higher chance of inconsistencies between documentation and implementation
- Fix approach: Extract complex phase logic into reference documents (similar to how execute-phase already uses `references/task-execution-guide.md` and `references/verifier-guide.md`), keep SKILL.md focused on orchestration steps

**Very large reference documents:**
- Issue: Some reference documents exceed 600 lines and contain multiple concerns
- Files: `ORCHESTRATION-REFERENCE.md` (892 lines), `plugins/marketplace-utils/skills/skill-creator/docs.md` (660 lines), `plugins/claude-super-team/agents/phase-researcher.md` (585 lines), `plugins/claude-super-team/skills/map-codebase/references/templates.md` (546 lines)
- Impact: Difficult to navigate and update, risk of conflicting guidance within single document
- Fix approach: Split large references into focused sub-documents (e.g., split templates.md into one file per template category), extract reusable patterns into separate guides

**External dependency on code-simplifier plugin:**
- Issue: `/execute-phase` hard-depends on `code-simplifier:code-simplifier` subagent but has no version pinning or fallback
- Files: `plugins/claude-super-team/skills/execute-phase/SKILL.md` (lines 344-376, 273), `README.md` (line 74)
- Impact: Execution fails if plugin not installed or API changes break compatibility; no graceful degradation
- Fix approach: Add version check in Phase 1 validation, provide clear error message with installation instructions, consider making simplifier optional with user confirmation

**Incremental-update mode complexity:**
- Issue: `/map-codebase` incremental-update mode requires mapper agents to implement merge logic correctly -- high cognitive load and error-prone
- Files: `plugins/claude-super-team/skills/map-codebase/references/mapper-instructions.md` (lines 141-237)
- Impact: Mappers may accidentally delete unrelated content or fail to detect topic relatedness correctly
- Fix approach: Implement merge logic in orchestrator instead of pushing to agents; provide agents with simpler "extract findings for topic X" task and handle merging centrally

## Known Bugs

Not detected

## Security Considerations

**Secret scanning only at mapping completion:**
- Risk: Mapper agents could leak secrets into codebase documents if they accidentally read `.env` files or credential stores despite forbidden file rules
- Files: `plugins/claude-super-team/skills/map-codebase/SKILL.md` (scan_for_secrets step, lines 319-352), `plugins/claude-super-team/skills/map-codebase/references/mapper-instructions.md` (Forbidden Files section, lines 240-260)
- Current mitigation: Forbidden file rules instruct agents never to read secrets; post-mapping grep scan detects leaked patterns before commit
- Recommendations: Add pre-agent validation that scans working directory for secret files and fails fast if mappers might access them; consider sandboxing mapper exploration to exclude secret patterns upfront

**No version constraints on external tool integrations:**
- Risk: Skills that invoke external CLI tools (`gh`, Linear CLI, Firecrawl) assume tools exist and have stable APIs
- Files: `plugins/task-management/skills/github-issue-manager/SKILL.md`, `plugins/task-management/skills/linear-sync/SKILL.md`, `plugins/claude-super-team/agents/phase-researcher.md` (Firecrawl skill usage)
- Current mitigation: None -- skills fail at runtime if tools missing or incompatible
- Recommendations: Add tool availability checks with version detection; provide clear error messages with installation links; document minimum required versions in plugin.json

**Git operations expose commit author identity:**
- Risk: Auto-commit patterns in documentation examples could expose maintainer identity if run in sensitive contexts
- Files: Multiple SKILL.md files show commit examples with "Co-Authored-By: Claude Opus 4.6" pattern
- Current mitigation: Skills never auto-commit (enforced in CLAUDE.md conventions); only suggest commit commands
- Recommendations: Current approach is safe -- maintain strict never-auto-commit policy

## Performance Bottlenecks

**Parallel agent context duplication:**
- Problem: When spawning multiple agents in parallel (e.g., 4 mappers, wave execution), each agent receives full embedded context including templates and guides
- Files: `plugins/claude-super-team/skills/map-codebase/SKILL.md` (spawn_agents step embeds full mapper-instructions.md and templates.md for each of 4 agents), `plugins/claude-super-team/skills/execute-phase/SKILL.md` (embeds task-execution-guide for each task)
- Cause: No shared context mechanism -- orchestrators paste full reference docs into every agent prompt
- Improvement path: Use custom agents (like `phase-researcher.md`) that embed context once at agent definition level; reference agent by name instead of pasting instructions per-spawn

**Sequential task execution within plans:**
- Problem: Tasks within a single plan must run sequentially even when not dependent, because orchestrator can't determine independence
- Files: `plugins/claude-super-team/skills/execute-phase/SKILL.md` (Phase 5c notes "Within a plan: Tasks execute sequentially")
- Cause: Task dependencies not explicitly declared in plan frontmatter -- conservative assumption that task N depends on task N-1
- Improvement path: Add optional `depends_on: [task_ids]` field to task definitions; allow parallel execution of independent tasks within same plan

## Fragile Areas

**Phase number formatting inconsistencies:**
- Files: `plugins/claude-super-team/skills/execute-phase/SKILL.md` (Phase 2 argument parsing), `plugins/claude-super-team/skills/phase-feedback/SKILL.md` (Step 7 subphase numbering), `CLAUDE.md` (Phase numbering conventions, line 41)
- Why fragile: Zero-padding logic differs between skills; decimal phase detection uses string operations that break with edge cases (e.g., "2.10" gets parsed incorrectly); mix of printf and bash string manipulation
- Safe modification: Centralize phase number normalization logic into a shared reference or helper skill; document exact format rules (NN for integer, NN.X for decimal) and enforce in validation steps
- Test coverage: No automated tests -- edge cases only discovered in production usage

**STATE.md and ROADMAP.md coordination:**
- Files: `plugins/claude-super-team/skills/progress/SKILL.md`, `plugins/claude-super-team/skills/phase-feedback/SKILL.md` (Step 9c updates STATE.md), `plugins/claude-super-team/skills/execute-phase/SKILL.md` (Phase 8 updates STATE.md)
- Why fragile: Multiple skills update STATE.md independently; no locking mechanism; manual edits can desync; troubleshooting guide documents sync issues as common problem (see `plugins/claude-super-team/skills/cst-help/references/troubleshooting.md`, lines 40-49)
- Safe modification: Always read both STATE.md and ROADMAP.md before updating either; validate phase references exist in ROADMAP before writing to STATE; add consistency check to `/progress` skill
- Test coverage: Manual verification only -- troubleshooting docs capture user-reported issues

**Roadmap annotation in feedback/quick-plan:**
- Files: `plugins/claude-super-team/skills/phase-feedback/SKILL.md` (Step 9 annotates ROADMAP.md), `plugins/claude-super-team/skills/quick-plan/SKILL.md` (similar roadmap annotation)
- Why fragile: Edit tool used to insert entries "without restructuring existing phases" -- relies on finding correct insertion point, fragile to roadmap format changes, no validation that insertion succeeded at correct position
- Safe modification: Read ROADMAP.md fully, parse phase structure, rebuild with new entry at correct numeric position, write atomically; verify phase order after write
- Test coverage: Gaps -- decimal phase ordering edge cases untested

## Scaling Limits

**Single-repository marketplace model:**
- Current capacity: 3 plugins (claude-super-team with 17 skills, marketplace-utils with 3 skills, task-management with 2 skills)
- Limit: `.claude-plugin/marketplace.json` lists all plugins; directory structure scales poorly beyond ~10 plugins (flat namespace collision risk)
- Scaling path: Support multi-marketplace federation -- allow marketplace.json to reference other marketplace.json files; add namespacing to plugin names

**Subagent orchestration depth:**
- Current capacity: 2-3 levels (orchestrator -> planner -> execution agent)
- Limit: Task tool spawn depth unclear; teams mode adds coordination overhead at scale
- Scaling path: Document max recommended depth; add depth tracking to prevent infinite recursion; consider flattening deeply nested orchestrations

**Planning artifact size:**
- Current capacity: `.planning/` directory with ~50 markdown files for medium project
- Limit: Skills read entire documents into context (PROJECT.md, ROADMAP.md, STATE.md, all codebase docs); large projects could exceed context windows
- Scaling path: Implement selective context loading -- only load relevant phase docs instead of everything; add size checks and warnings in validation steps

## Dependencies at Risk

**code-simplifier plugin availability:**
- Risk: Hard dependency on external plugin from `claude-plugins-official` namespace
- Impact: `/execute-phase` fails if plugin unavailable, renamed, or API changes
- Migration plan: Vendor a copy of simplifier logic into claude-super-team as optional built-in subagent; maintain external dependency as default but support degraded mode without it

**Claude Code Task tool API:**
- Risk: All orchestration depends on Task tool behavior (subagent spawning, background execution, team coordination)
- Impact: API changes to Task tool could break all planning/execution skills
- Migration plan: Document exact Task tool usage patterns; add version detection if SDK provides it; maintain compatibility layer if breaking changes occur

## Missing Critical Features

**No skill versioning or compatibility checks:**
- Problem: Skills reference each other by name (e.g., `/execute-phase` calls `/phase-feedback`) but have no version constraints
- Blocks: Safe plugin updates -- can't guarantee cross-skill compatibility after changes

**No rollback or undo mechanism:**
- Problem: Failed phase execution leaves partial state; no way to cleanly revert to pre-execution state
- Blocks: Safe experimentation, recovering from execution failures without manual git operations

**No validation of plan-execution contract:**
- Problem: Planner agents create PLAN.md; executor agents consume it -- but no schema validation between planning and execution
- Blocks: Early detection of malformed plans; could cause cryptic execution failures

**No progress persistence across sessions:**
- Problem: Agent spawning via Task tool has no built-in resume capability; interrupting `/execute-phase` loses partial progress within current task
- Blocks: Long-running executions (multi-hour phases), graceful interrupt handling

## Test Coverage Gaps

**Untested area: Decimal phase insertion edge cases**
- What's not tested: Phase 2.10 vs 2.1 comparison, concurrent decimal insertions, decimal phases at boundaries (0.1, N.999)
- Files: `plugins/claude-super-team/skills/quick-plan/SKILL.md`, `plugins/claude-super-team/skills/phase-feedback/SKILL.md`
- Risk: Phase ordering bugs, duplicate phase numbers, sorting inconsistencies
- Priority: Medium

**Untested area: Incremental codebase mapping merge logic**
- What's not tested: Mapper agents correctly preserving unrelated content while updating target sections
- Files: `plugins/claude-super-team/skills/map-codebase/references/mapper-instructions.md` (Update Mode section)
- Risk: Data loss -- mapper could accidentally remove valid documentation when updating specific topics
- Priority: High

**Untested area: Agent team coordination**
- What's not tested: Teams mode with >5 parallel plans, teammate reuse across waves, message delivery reliability
- Files: `plugins/claude-super-team/skills/execute-phase/SKILL.md` (Teams Mode section)
- Risk: Deadlocks, lost messages, orphaned teammates, resource exhaustion
- Priority: Medium

**Untested area: Cross-skill state consistency**
- What's not tested: Multiple skills updating STATE.md concurrently, ROADMAP.md/STATE.md sync after manual edits
- Files: All skills that update STATE.md or ROADMAP.md
- Risk: Inconsistent project state leading to skill execution failures
- Priority: High

**Untested area: Secret scanning patterns**
- What's not tested: All secret patterns in scan regex, false positive rate, handling of multi-line secrets
- Files: `plugins/claude-super-team/skills/map-codebase/SKILL.md` (scan_for_secrets step)
- Risk: Secrets leak to git despite scanning
- Priority: High

---

*Concerns audit: 2026-02-11*
