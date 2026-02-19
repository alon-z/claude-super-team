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
| `/brainstorm [topic]` | Brainstorm features and changes -- interactive or autonomous mode |
| `/discuss-phase [N]` | Capture implementation decisions before planning |
| `/research-phase [N]` | Research ecosystem, libraries, and patterns for a phase |
| `/plan-phase [N]` | Generate detailed execution plans for a phase |
| `/execute-phase [N]` | Execute plans with parallel agent orchestration |
| `/progress` | Check status and get routed to the next action |
| `/quick-plan` | Insert a lightweight phase with decimal numbering |
| `/phase-feedback` | Feedback-driven subphase with opus agents |
| `/code [N]` | Interactive coding session with project context |
| `/build [idea or PRD]` | Autonomously build entire application from idea to working code |
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

**Full automation:** Run `/build` with a project idea or PRD path and the entire pipeline runs autonomously -- from project definition through brainstorming, roadmap creation, and phased execution. Zero user intervention required. Creates BUILD-STATE.md for compaction resilience and BUILD-REPORT.md with a complete decisions log.

**Step-by-step control:**

1. **Define** your project with `/new-project`
2. **Map** an existing codebase with `/map-codebase` (optional)
3. **Plan** a phased roadmap with `/create-roadmap`
4. **Brainstorm** features and changes with `/brainstorm` -- interactively or let Claude go autonomous with parallel analysis agents (optional, feeds into roadmap)
5. **For each phase**: discuss decisions, research the ecosystem (may loop back to update decisions if conflicts found), plan the work, then execute
6. **Track progress** with `/progress`, which routes you to the next step

Execution uses wave-based parallelism -- plans within a wave run concurrently via subagents, while waves run sequentially. After each plan's tasks complete, a code-simplifier pass refines the output for clarity and consistency (can be disabled per-project via `simplifier: disabled` in STATE.md preferences). Planners use Claude Opus; checkers use Claude Sonnet. Execution agents default to Sonnet with Opus for TDD/security tasks, but you can set `execution-model: opus` in your project preferences to use Opus for all execution tasks (asked during `/new-project` or on first `/execute-phase` run).

`/phase-feedback` automatically detects when feedback involves unfamiliar packages or APIs and spawns a research agent before planning. `/progress` detects sync issues between phase directories and planning files, warning you early when drift occurs. `/add-security-findings` supports dual-mode invocation: run it manually for interactive finding entry, or let it auto-invoke after a security scan to capture findings from the conversation context.

All skills use scoped Bash access (e.g., `Bash(git *)`, `Bash(test *)`) rather than blanket shell access, following least-privilege principles.

## Dependencies

The `/execute-phase` skill uses the `code-simplifier` plugin for post-execution code refinement. Install it from the official marketplace:

```
/plugin install code-simplifier@claude-plugins-official
```

## Acknowledgments

Heavily inspired by [get-shit-done](https://github.com/glittercowboy/get-shit-done).
