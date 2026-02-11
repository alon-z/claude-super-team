# Claude Super Team

## What This Is

A Claude Code plugin marketplace containing three plugins that provide a structured project planning and execution workflow through slash commands (skills) and custom agents. Built primarily for personal use, it covers the full software delivery lifecycle -- from project initialization through phased execution and verification.

## Core Value

Every skill and agent must leverage the right Claude Code primitive for its purpose, and the end-to-end workflow must have no gaps -- if a user needs a capability during project delivery, it exists and works smoothly.

## Requirements

### Validated

- Completed sequential planning pipeline: `/new-project` -> `/create-roadmap` -> `/discuss-phase` -> `/research-phase` -> `/plan-phase` -> `/execute-phase` -> `/progress` -- existing
- Multi-agent orchestration via Task tool with wave-based parallel execution -- existing
- Codebase mapping with 4 parallel mapper agents (`/map-codebase`) -- existing
- Marketplace management utilities (`/marketplace-manager`, `/skill-creator`) -- existing
- Task management integrations: Linear sync (`/linear-sync`) and GitHub issues (`/github-issue-manager`) -- existing
- Interactive and autonomous brainstorming (`/brainstorm`) -- existing
- Phase feedback loop for iterating on delivered work (`/phase-feedback`) -- existing
- Quick-plan for inserting urgent phases with decimal numbering (`/quick-plan`) -- existing
- Context-aware help system (`/cst-help`) -- existing
- Research phase with custom `phase-researcher` agent and Firecrawl integration -- existing

### Active

- [ ] Systematic audit of all skills against Claude Code ecosystem capabilities (skills vs agents vs hooks, frontmatter features, context behavior, `disable-model-invocation`, etc.)
- [ ] Evaluate and convert skills that would work better as agents or hybrid skill+agent patterns
- [ ] Ensure all skills properly use available Claude Code features (tool restrictions, model selection, context forking, argument hints)
- [ ] Add missing capabilities as discovered through ongoing usage of the planning workflow

### Out of Scope

- Community contribution workflows -- this is a personal tool, not optimizing for external contributors
- Automated test suites -- skills are Markdown-based and validated through execution, not unit tests
- Web UI or dashboard -- this is a CLI-only toolset, no visual interfaces
- Backward compatibility guarantees -- as the sole user, breaking changes are acceptable when they improve the tool

## Context

- The Claude Code plugin ecosystem continues to evolve with new features (agent definitions, hooks, context forking, `disable-model-invocation`). Some skills predate these features and may not leverage them optimally.
- The repository dogfoods its own tools -- this project itself is managed using the claude-super-team planning pipeline.
- Skills and agents serve different purposes in Claude Code: skills are user-invoked slash commands with declared tool access; agents are spawned subprocesses with their own tool sets and model selection. Some current skills may be better suited as agents.
- New capabilities are discovered organically -- as the planning workflow is used on real projects, gaps surface and become new skills (recent examples: `/brainstorm`, `/phase-feedback`).
- The marketplace distributes three plugins but only `claude-super-team` is actively evolving; `marketplace-utils` and `task-management` are stable utilities.

## Constraints

- **Platform**: Claude Code CLI only -- all skills execute within the Claude Code runtime environment
- **No runtime code**: Entirely Markdown-driven with JSON manifests; no build system, no compiled code, no package dependencies
- **Ecosystem dependency**: All capabilities constrained by what Claude Code's plugin API, Task tool, and frontmatter system support
- **Context windows**: Skills that spawn subagents must embed all necessary context inline (no `@` file references across Task boundaries)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Systematic skill audit before new features | Existing skills may not use available Claude Code capabilities; fixing foundations first prevents compounding issues | -- Pending |
| Execution model: opus | Higher reasoning quality preferred for all execution tasks; cost/speed tradeoff acceptable for personal use | -- Pending |
| Evaluate skills vs agents for each capability | Claude Code agents offer different primitives than skills; some orchestration-heavy skills may be better as agents | -- Pending |

## Preferences

execution-model: opus

---

*Last updated: 2026-02-11 after initialization*
