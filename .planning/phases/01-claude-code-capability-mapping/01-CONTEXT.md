# Context for Phase 1: Claude Code Capability Mapping

## Phase Boundary (from ROADMAP.md)

**Goal:** Create a complete reference of Claude Code's plugin primitives -- skills, agents, hooks, frontmatter options, context behavior -- as the standard to audit against

**Success Criteria:**
1. A capability reference document exists covering all skill frontmatter fields, agent definition syntax, hooks, and context behavior options
2. Each capability is documented with when to use it, examples, and tradeoffs (skill vs agent vs hook)
3. The reference is accurate against the current Claude Code version (verified by cross-referencing all documented capabilities against multiple sources)

**What's in scope for this phase:**
- Full Claude Code ecosystem reference: plugin primitives (skills, agents, hooks), tools, CLI flags, MCP servers, settings, memory, session management
- Companion document to ORCHESTRATION-REFERENCE.md -- extends it with audit-focused structure and gap flagging
- Capabilities not currently used by this marketplace are documented and flagged as adoption opportunities
- Unverified capabilities (found in docs but not confirmed in code) included with explicit markers

**What's explicitly out of scope:**
- Applying capabilities to existing skills (Phase 2/3)
- Hands-on testing of capabilities by creating scratch skills (deferred -- verification is doc accuracy via multi-source cross-referencing)
- Modifying any existing skills or agents

---

## Codebase Context

**Existing related code:**
- `ORCHESTRATION-REFERENCE.md` (project root): Comprehensive 160+ line guide covering thinking control, context compaction, custom agents, Task tool, agent teams, skills system, hooks, plan mode, MCP servers, settings, session management, memory, plugins system -- the baseline to extend
- 17 skill definitions across 3 plugins demonstrating various frontmatter patterns
- 1 custom agent definition (`plugins/claude-super-team/agents/phase-researcher.md`) showing agent YAML syntax
- `.claude-plugin/marketplace.json` demonstrating plugin distribution schema

**Established patterns:**
- 16 unique frontmatter fields identified across skills: `name`, `description`, `allowed-tools`, `model`, `context`, `argument-hint`, `disable-model-invocation`, `disallowedTools`, `permissionMode`, `tools`, `skills`, `mcpServers`, `hooks`, `agent`, `user-invocable`, `memory`, `maxTurns`
- Two context modes in use: implicit `skill` (14 skills) and explicit `context: fork` (2 skills: map-codebase, progress)
- Model override used for 4 skills: opus (map-codebase), haiku (progress, cst-help, marketplace-manager), sonnet (github-issue-manager)
- `disable-model-invocation: true` used for pure orchestrators (map-codebase, add-security-findings)

**Integration points:**
- ORCHESTRATION-REFERENCE.md is the existing capability source -- new reference must complement, not duplicate
- Phase 2 audit will directly consume the capability reference to evaluate each skill

**Constraints from existing code:**
- No hooks currently implemented in any skill or agent -- documentation relies on ORCHESTRATION-REFERENCE.md and web sources
- Agent teams are experimental (behind env flag) -- limited firsthand usage data
- Some frontmatter fields (memory, maxTurns, user-invocable) are documented but not used in this codebase

---

## Implementation Decisions

### Reference Scope

**Decision:** Full ecosystem coverage -- plugin primitives, tools, CLI flags, MCP servers, settings, memory, session management. All capabilities documented, including those not currently used by this marketplace, with unused ones explicitly flagged as adoption opportunities.

**Rationale:** The Phase 2 audit needs a complete picture to identify gaps. Limiting scope to only what's currently used would miss the most valuable part -- capabilities we should be leveraging but aren't.

**Constraints:** Unverified capabilities (found in docs but unconfirmed in code) must be included with an explicit "unverified" marker so Phase 2 knows to investigate them.

### Document Structure

**Decision:** Create a companion reference document at the project root alongside ORCHESTRATION-REFERENCE.md. The new document extends it with audit-focused structure and capability gap flagging rather than replacing it.

**Rationale:** ORCHESTRATION-REFERENCE.md is a working reference that skills already point to. A companion document adds the audit lens (tradeoffs, when-to-use, adoption status) without disrupting existing references.

**Constraints:** Must not duplicate content from ORCHESTRATION-REFERENCE.md where possible -- reference it instead.

### Research Method

**Decision:** Primary source is web research via Firecrawl to find official Claude Code documentation, plus Claude's own knowledge of its capabilities. The user will provide the Claude Code changelog as additional context when prompted during execution.

**Rationale:** Web research provides the most up-to-date and authoritative source. The changelog captures recent additions that may not appear in static docs. Claude's built-in knowledge fills structural gaps.

**Constraints:** No live testing of capabilities in Phase 1. Research is documentation-only. Capabilities discovered must be cross-referenced against at least one additional source.

### Verification Approach

**Decision:** Doc accuracy verification via multi-source cross-referencing. Every capability in the reference must be verified against at least one additional source (codebase usage, web docs, changelog, or Claude's knowledge). No empirical testing.

**Rationale:** Hands-on testing of capabilities across skills is Phase 2/3 work. Phase 1 focuses on building an accurate reference document. Cross-referencing catches documentation errors without scope creep into implementation.

**Constraints:** Capabilities that can only be confirmed from a single source get the "unverified" marker.

---

## Claude's Discretion

- **Document organization**: How to structure sections within the companion reference (by category, by primitive type, alphabetical, etc.)
- **Level of detail**: How much to document per capability -- brief summary vs exhaustive specification
- **Cross-referencing format**: How to link between the new reference and ORCHESTRATION-REFERENCE.md

---

## Specific Ideas

- User will provide Claude Code changelog via paste when prompted during execution (not via web research)
- Reference should flag capabilities as: "In use", "Documented but unused", or "Unverified" to create a clear adoption heatmap for Phase 2
- ORCHESTRATION-REFERENCE.md content should be referenced (not duplicated) where the companion document covers overlapping topics

---

## Deferred Ideas

- Applying `context: fork` across all skills to test which ones benefit (Phase 2/3 scope)
- Creating scratch skills/agents for empirical capability testing (Phase 2/3 scope)
- Modifying existing skills based on capability findings (Phase 3 scope)

---

*Created: 2026-02-11 via /discuss-phase 1*
