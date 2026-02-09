# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin marketplace containing three plugins that provide a structured project planning and execution workflow. The marketplace distributes skills (slash commands) that guide users through a full software delivery lifecycle.

## Repository Structure

- `.claude-plugin/marketplace.json` -- marketplace manifest registering all plugins
- `plugins/claude-super-team/` -- core planning and execution plugin (11 skills)
- `plugins/marketplace-utils/` -- marketplace management utility plugin (2 skills)
- `plugins/task-management/` -- Linear sync and GitHub issue management plugin (2 skills)

Each plugin has `.claude-plugin/plugin.json` for metadata and `skills/` containing SKILL.md files that define slash commands.

## Core Workflow (claude-super-team plugin)

The skills form a sequential pipeline. Each skill reads/writes files in `.planning/`:

```
/new-project          --> .planning/PROJECT.md
/map-codebase         --> .planning/codebase/ (7 docs: STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS)
/create-roadmap       --> .planning/ROADMAP.md + STATE.md
/discuss-phase [N]    --> .planning/phases/{NN}-{name}/{NN}-CONTEXT.md (user decisions)
/plan-phase [N]       --> .planning/phases/{NN}-{name}/*-PLAN.md
/execute-phase [N]    --> .planning/phases/{NN}-{name}/*-SUMMARY.md + *-VERIFICATION.md
/progress             --> status report + smart routing to next action
/quick-plan           --> lightweight inserted phase with decimal numbering (e.g., 4.1), includes discussion
/phase-feedback       --> feedback-driven subphase: plans + executes modifications with opus agents (e.g., 4.1)
/add-security-findings --> .planning/SECURITY-AUDIT.md + roadmap integration
/cst-help [question]  --> context-aware help, troubleshooting, skill reference
```

## Key Conventions

- **Phase numbering**: Directories use zero-padded format (`01-foundation`, `02-auth`). Inserted phases use decimals (`02.1-security-hardening`).
- **Never auto-commit**: All skills tell the user how to commit but never run `git commit` automatically (exception: `/new-project` commits if it initialized a new git repo).
- **Agent orchestration**: `/plan-phase` and `/execute-phase` spawn subagents via the Task tool. Planners get opus, checkers get sonnet. Context is embedded inline in prompts (no `@` file references across Task boundaries).
- **Wave-based execution**: Plans group into waves. Plans within a wave run in parallel; waves run sequentially.
- **Goal-backward success criteria**: Each phase defines observable, user-verifiable outcomes -- not task lists.
- **State tracking**: `STATE.md` tracks current phase position, decisions, and blockers. `ROADMAP.md` tracks phase completion.
- **Skill YAML frontmatter**: Each SKILL.md declares `allowed-tools`, optional `model`, `context`, and `disable-model-invocation` fields.

## Marketplace Plugin (marketplace-utils)

Manages `.claude-plugin/marketplace.json`:

- Plugin registration, removal, version syncing
- Audit workflow: detects unregistered plugins, name mismatches, version drift, stale entries
- `plugin.json` name is source of truth for version; directory name is source of truth for naming
- Sources can be relative paths, GitHub repos, or generic git URLs

## Commit Convention

Format: `[plugin] (type): Title`

- **plugin**: The plugin name (e.g., `claude-super-team`, `marketplace-utils`)
- **type**: What was added/changed -- skill, agent, asset, reference, config, etc.
- **Title**: Short description of what was done

The commit body should contain a concise summary of what changed.

Examples:

- `[claude-super-team] (skill): Added /quick-plan for lightweight phase insertion`
- `[marketplace-utils] (config): Updated plugin.json version to 1.2.0`
- `[claude-super-team] (agent): Improved execute-phase wave parallelism`

## Editing Skills

When modifying SKILL.md files:

- Preserve YAML frontmatter (`---` block) -- it controls tool access, model selection, and context behavior
- Skills reference `assets/` templates and `references/` guides that get embedded into agent prompts
- Skills use `$ARGUMENTS` for user-provided arguments after the slash command
- AskUserQuestion is the primary user interaction mechanism (not free-form text)

## Maintaining the /cst-help Skill

When adding, removing, or changing skills in the claude-super-team plugin, update the `/cst-help` skill to stay in sync:

- **SKILL.md**: Update the "Skill Reference" output section with the new/changed skill listing
- **references/workflow-guide.md**: Update the pipeline overview, workflow patterns, and file structure reference
- **references/troubleshooting.md**: Add troubleshooting entries for new skills; update "When to Use Each Skill" section

Also update `/cst-help` when changing core conventions (phase numbering, file naming, state tracking) since it explains these concepts to users.

## Changelog

When making changes to any plugin (adding/removing skills, version bumps, bug fixes, refactors), update `CHANGELOG.md` at the project root. Follow the existing format: group entries under `## [version] - date` with `### plugin-name` subheadings.

## Maintaining This File

Always keep this `CLAUDE.md` up to date with changes made to the project. When modifying conventions, changing structure, or making any notable decision, update this file so future sessions have accurate context.
