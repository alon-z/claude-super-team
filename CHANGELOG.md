# Changelog

All notable changes to the claude-super-team marketplace are documented in this file.

## [1.0.4] - 2026-02-09

### claude-super-team
- Added `/cst-help` skill for interactive workflow help, concept explanations, and troubleshooting
- Updated README with `/discuss-phase` and `/cst-help` documentation, renumbered all commands

## [1.0.3] - 2026-02-09

### claude-super-team
- Added `/discuss-phase` skill for capturing user implementation decisions before planning
- Integrated lightweight discussion step into `/quick-plan`
- Updated `/progress` routing to suggest discussion when no context exists
- Added informational note to `/plan-phase` when CONTEXT.md is missing

## [1.0.2] - 2026-02-09

### task-management (new plugin)
- Added `/linear-sync` skill for syncing `.planning/` artifacts to Linear
- Added `/github-issue-manager` skill for creating and managing GitHub issues

### marketplace-utils
- Added `/skill-creator` skill for guided skill scaffolding

## [1.0.1] - 2026-02-09

### claude-super-team
- Added `/phase-feedback` skill for feedback-driven subphases with opus agents
- Added teams mode to `/execute-phase` for multi-agent parallel execution
- Added `/quick-plan` skill for lightweight phase insertion with decimal numbering

### marketplace-utils (new plugin)
- Added `/marketplace-manager` skill for auditing and managing plugin marketplaces

## [1.0.0] - 2026-02-08

### claude-super-team (new plugin)
- Initial release with core planning and execution pipeline
- Skills: `/new-project`, `/create-roadmap`, `/plan-phase`, `/execute-phase`, `/progress`
