# Claude Super Team

A Claude Code plugin marketplace that provides a structured project planning and execution workflow. Install the plugins to get slash commands that guide you through a full software delivery lifecycle -- from project definition through phased execution.

## Plugins

### claude-super-team (core)

The main plugin. Provides a sequential pipeline of skills for planning and delivering software projects:

| Command | Description |
|---------|-------------|
| `/new-project` | Define project scope and goals |
| `/map-codebase` | Analyze an existing codebase (stack, architecture, conventions, etc.) |
| `/create-roadmap` | Build a phased roadmap with success criteria |
| `/discuss-phase [N]` | Capture implementation decisions before planning |
| `/plan-phase [N]` | Generate detailed execution plans for a phase |
| `/execute-phase [N]` | Execute plans with parallel agent orchestration |
| `/progress` | Check status and get routed to the next action |
| `/quick-plan` | Insert a lightweight phase with decimal numbering |
| `/phase-feedback` | Feedback-driven subphase with opus agents |
| `/add-security-findings` | Integrate security audit results into the roadmap |
| `/cst-help [question]` | Get help, troubleshooting, and skill reference |

All planning artifacts are stored in `.planning/` within your project.

### marketplace-utils

Utilities for managing Claude Code plugin marketplaces:

| Command | Description |
|---------|-------------|
| `/marketplace-manager` | Audit and manage plugin registrations |
| `/skill-creator` | Scaffold new skills with guided prompts |

### task-management

Integrations for external task trackers:

| Command | Description |
|---------|-------------|
| `/linear-sync` | Sync `.planning/` artifacts to Linear |
| `/github-issue-manager` | Create and manage GitHub issues |

## Installation

Add the marketplace to your Claude Code configuration:

```
claude mcp add-plugin-marketplace /path/to/claude-super-team
```

Or install individual plugins:

```
claude mcp add-plugin /path/to/claude-super-team/plugins/claude-super-team
```

## How It Works

1. **Define** your project with `/new-project`
2. **Map** an existing codebase with `/map-codebase` (optional)
3. **Plan** a phased roadmap with `/create-roadmap`
4. **For each phase**: discuss decisions, plan the work, then execute
5. **Track progress** with `/progress`, which routes you to the next step

Execution uses wave-based parallelism -- plans within a wave run concurrently via subagents, while waves run sequentially. Planners use Claude Opus; checkers use Claude Sonnet.

## Acknowledgments

Heavily inspired by [get-shit-done](https://github.com/glittercowboy/get-shit-done).
