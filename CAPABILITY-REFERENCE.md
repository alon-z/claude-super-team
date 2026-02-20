# Claude Code Capability Reference

Companion to [ORCHESTRATION-REFERENCE.md](./ORCHESTRATION-REFERENCE.md). This document inventories all Claude Code ecosystem capabilities with adoption status flags for audit purposes. Where ORCHESTRATION-REFERENCE.md provides detailed coverage, this document cross-references rather than duplicates.

## Adoption Status Legend

- **In use**: Actively used in this marketplace's skills/agents/config
- **Documented but unused**: Confirmed capability not leveraged by this marketplace (Phase 2 adoption opportunity)
- **Unverified**: Found in single source only; needs empirical verification

Generated: 2026-02-11 | Claude Code version: 2.1.49 (updated 2026-02-20)

---

## 1. Skills

### Skill Frontmatter Fields

| Capability                  | Description                                                | Status | ORCH-REF Section | Notes                     |
|-----------------------------|------------------------------------------------------------| ------ |------------------|---------------------------|
| `name`                      | Unique skill identifier (lowercase, hyphens, max 64 chars) | In use | Skills System    | Used in all 17 skills     |
| `description`               | When to use; drives auto-invocation                        | In use | Skills System    | Used in all 17 skills     |
| `argument-hint`             | Hint shown during autocomplete                             | In use | Skills System    | Used in most skills       |
| `disable-model-invocation`  | Prevent Claude from auto-loading the skill                 | In use | Skills System    | Used in several skills    |
| `allowed-tools` / `tools`   | Tool access allowlist                                      | In use | Skills System    | Used in all 17 skills     |
| `disallowedTools`           | Tool denylist                                              | Documented but unused | Skills System    | Alternative to allowlist; useful when most tools needed |
| `model`                     | Override model (sonnet/opus/haiku)                         | In use | Skills System    | Used in 6 skills: cst-help, progress, map-codebase, marketplace-manager, skill-creator, github-issue-manager |
| `context`                   | `skill` (default) or `fork` (spawns subagent)              | In use | Skills System    | Used in 2 skills: progress, map-codebase (context: fork) |
| `agent`                     | Agent type when `context: fork` is used                    | Documented but unused | Skills System    | Pairs with `context: fork` |
| `user-invocable`            | Hide from `/` menu (default: true)                         | Documented but unused | Skills System    | Could hide internal-only skills |
| `permissionMode`            | Override permissions for skill execution                   | Documented but unused | Skills System    | Useful for high-trust automated skills |
| `hooks`                     | Skill-scoped lifecycle hooks                               | Documented but unused | Skills System    | Would enable per-skill validation |
| `skills`                    | Nested skills to preload                                   | Documented but unused | Skills System    | Could compose skills from smaller units |

### Skill Features

| Capability                              | Description                                                   | Status                | ORCH-REF Section | Notes                                              |
|-----------------------------------------|---------------------------------------------------------------|-----------------------|------------------|----------------------------------------------------|
| `$ARGUMENTS`                            | All arguments passed to the skill                             | In use                | Skills System    | Used across skills for phase numbers, flags        |
| `$ARGUMENTS[N]`                         | Indexed argument access                                       | Documented but unused | Skills System    | Skills currently parse `$ARGUMENTS` manually       |
| `$N` shorthand                          | `$0`, `$1` as shorthand for `$ARGUMENTS[0]`, etc.             | Documented but unused | Not covered      | Simpler syntax; equivalent to `$ARGUMENTS[N]`      |
| `${CLAUDE_SESSION_ID}`                  | Current session ID variable                                   | Documented but unused | Skills System    | Useful for session-aware skills                    |
| Skill tool invocation                   | `/skill-name` slash commands                                  | In use                | Skills System    | Primary invocation method for all 17 skills        |
| `Skill` tool programmatic invocation    | Invoke skill from code via the Skill tool                     | In use                | Not covered      | Used within skills to call other skills            |
| Auto-invocation by description          | Claude auto-loads skill when description matches              | In use                | Skills System    | Enabled by `description` field                     |
| Supporting files alongside SKILL.md     | Assets, references, templates in skill directory              | In use                | Skills System    | Used for templates, guides, references             |
| Nested directory discovery              | Skills in subdirectories auto-discovered                      | Documented but unused | Skills System    | All skills currently at top level                  |
| Skill hot-reload                        | Skills reload on file change without restart                  | Documented but unused | Skills System    | Useful during development                          |
| Agent Skills standard                   | Skills follow agentskills.io open standard                    | Documented but unused | Not covered      | Interoperability with other AI tools               |
| Skill precedence                        | Enterprise > personal > project; skill wins over built-in     | Documented but unused | Not covered      | Relevant if name conflicts arise                   |
| Description character budget            | `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var; default 2% context  | Documented but unused | Not covered      | Impacts how many skills Claude can see at once     |

### Expanded Notes

**`$N` shorthand**: `$0`, `$1`, `$2` map to `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, `$ARGUMENTS[2]`. Fewer characters; same behavior. Source: code.claude.com/docs/en/skills#pass-arguments-to-skills.

**Dynamic context injection**: Use `!`command`` syntax in skill body to run a shell command and inject its output into the prompt before Claude processes it. Example: `!`git log --oneline -5`` injects recent commits. Source: code.claude.com/docs/en/skills#inject-dynamic-context. Status: **Documented but unused**.

**Description character budget**: Total skill descriptions consume context. Default budget is 2% of context window (~3,200 tokens for 200k context), fallback 16,000 chars. Check with `/context`. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET`. Source: code.claude.com/docs/en/skills#troubleshooting.

---

## 2. Agents

### Agent Frontmatter Fields

| Capability          | Description                                     | Status                | ORCH-REF Section | Notes                                           |
|---------------------|------------------------------------------------ |-----------------------|------------------|-------------------------------------------------|
| `name`              | Unique identifier (lowercase, hyphens)          | In use                | Custom Agents    | Used in `phase-researcher`                      |
| `description`       | When Claude should delegate to this agent       | In use                | Custom Agents    | Drives auto-delegation                          |
| `tools`             | Tool allowlist                                  | In use                | Custom Agents    | `phase-researcher` restricts to 7 tools         |
| `disallowedTools`   | Tool denylist                                   | Documented but unused | Custom Agents    | Alternative to `tools` allowlist                |
| `model`             | sonnet/opus/haiku/inherit                       | In use                | Custom Agents    | `phase-researcher` uses opus                    |
| `permissionMode`    | Override permission mode for agent              | Documented but unused | Custom Agents    | Could enable `acceptEdits` for trusted agents   |
| `maxTurns`          | Maximum agentic turns before stopping           | Documented but unused | Custom Agents    | Safety limit; prevents runaway agents           |
| `skills`            | Skills preloaded at agent startup               | In use                | Custom Agents    | `phase-researcher` preloads firecrawl           |
| `mcpServers`        | MCP servers available to this agent             | Documented but unused | Custom Agents    | Would scope MCP access per agent                |
| `hooks`             | Agent-scoped lifecycle hooks                    | Documented but unused | Custom Agents    | Per-agent validation hooks                      |
| `memory`            | Persistent memory: user/project/local           | Documented but unused | Custom Agents    | Would let agents learn across sessions          |

### Built-in Agent Types

| Capability           | Description                                      | Status                | ORCH-REF Section | Notes                                      |
|----------------------|--------------------------------------------------|---------------------- |------------------|--------------------------------------------|
| `general-purpose`    | Full tool access, complex multi-step tasks       | In use                | Custom Agents    | Default type for Task tool spawns          |
| `Explore`            | Fast read-only codebase exploration (Haiku)      | Documented but unused | Custom Agents    | Lightweight; good for `context: fork`      |
| `Plan`               | Read-only research for plan mode                 | Documented but unused | Custom Agents    | Used with `--permission-mode plan`         |
| `Bash`               | Separate context for terminal commands           | Documented but unused | Custom Agents    | Isolates shell work from main context      |
| `statusline-setup`   | Configure status line UI                         | Documented but unused | Custom Agents    | Specialized setup agent                    |
| Claude Code Guide    | Built-in Haiku agent for feature questions       | Documented but unused | Not covered      | Answers Claude Code usage questions        |

### Agent Invocation Methods

| Capability             | Description                                      | Status                | ORCH-REF Section | Notes                                |
|------------------------|--------------------------------------------------|-----------------------|------------------|--------------------------------------|
| Automatic delegation   | Description match triggers delegation            | In use                | Custom Agents    | How `phase-researcher` is selected   |
| Explicit instruction   | "Use the X subagent to..."                       | In use                | Custom Agents    | Used in orchestration skills         |
| `@agent-name` mention  | Direct mention invocation                        | Documented but unused | Custom Agents    | Quick way to invoke specific agent   |
| `--agent NAME` flag    | Run entire session as specific agent             | Documented but unused | CLI Flags        | Useful for specialized sessions      |
| `--agents JSON` flag   | Define agents inline (session-only)              | Documented but unused | CLI Flags        | Ephemeral agent definitions          |

### Expanded Notes

**Agent memory**: When `memory: project` is set, the agent stores learnings in `.claude/agents/{name}/MEMORY.md`. First 200 lines are included in the agent's system prompt on subsequent invocations. Three scopes: `user` (cross-project), `project` (version-controllable), `local` (gitignored). Source: code.claude.com/docs/en/sub-agents#supported-frontmatter-fields.

---

## 3. Hooks

All hook capabilities are **Documented but unused** in this marketplace. See ORCH-REF "Hooks System" for detailed event tables, matcher syntax, and handler types.

### Hook Events (16 Total)

| Capability             | Description                                              | Status                | ORCH-REF Section | Notes                                        |
|------------------------|----------------------------------------------------------|---------------------- |------------------|----------------------------------------------|
| `SessionStart`         | Fires on startup/resume/clear/compact                    | Documented but unused | Hooks System     | Inject context after compaction              |
| `SessionEnd`           | Fires on clear/logout/exit                               | Documented but unused | Hooks System     | Cleanup, logging                             |
| `UserPromptSubmit`     | Fires before prompt processed; can block                 | Documented but unused | Hooks System     | Input validation, context injection          |
| `PreToolUse`           | Fires before tool execution; can block/modify            | Documented but unused | Hooks System     | Tool gating, input transformation            |
| `PostToolUse`          | Fires after tool completion; can add context             | Documented but unused | Hooks System     | React to tool results                        |
| `PostToolUseFailure`   | Fires on tool error                                      | Documented but unused | Hooks System     | Error handling, retry logic                  |
| `PermissionRequest`    | Fires on permission prompt; can auto-approve             | Documented but unused | Hooks System     | Automation of permission decisions           |
| `Notification`         | Read-only event for idle/permission prompts              | Documented but unused | Hooks System     | External notification integration            |
| `SubagentStart`        | Fires when subagent starts                               | Documented but unused | Hooks System     | Inject context into spawned agents           |
| `SubagentStop`         | Fires when subagent stops; can prevent                   | Documented but unused | Hooks System     | Validate subagent output before accepting    |
| `Stop`                 | Fires when agent execution ends; can force continue      | Documented but unused | Hooks System     | Force continuation on premature stops        |
| `TeammateIdle`         | Fires when teammate goes idle (teams)                    | Documented but unused | Hooks System     | Prevent idle or inject feedback              |
| `TaskCompleted`        | Fires when team task completed (teams)                   | Documented but unused | Hooks System     | Validate before marking done                 |
| `PreCompact`           | Fires before context compaction                          | Documented but unused | Hooks System     | Custom compaction instructions               |
| `ConfigChange`         | Fires when config files change during session            | Documented but unused | Not covered      | Added v2.1.49; security auditing, block settings changes |
| `Setup`                | Fires via `--init`/`--maintenance`                       | Documented but unused | Hooks System     | Project initialization automation            |

### Handler Types & Fields

| Capability               | Description                                   | Status                | ORCH-REF Section | Notes                                    |
|--------------------------|-----------------------------------------------|---------------------- |------------------|------------------------------------------|
| `type: "command"`        | Shell command handler                         | Documented but unused | Hooks System     | Most common handler type                 |
| `type: "prompt"`         | LLM evaluation handler                        | Documented but unused | Hooks System     | Claude evaluates and returns JSON        |
| `type: "agent"`          | Subagent with tools for verification          | Documented but unused | Hooks System     | Most powerful; full agentic handler      |
| `timeout`                | Handler timeout in seconds                    | Documented but unused | Not covered      | Default varies by handler type           |
| `statusMessage`          | Custom spinner text during execution          | Documented but unused | Not covered      | UX improvement for long-running hooks    |
| `once`                   | Run only once per session, then removed       | Documented but unused | Not covered      | Skills-only; good for one-time setup     |
| `async`                  | Non-blocking background execution             | Documented but unused | Hooks System     | For hooks that do not need to block      |
| `model`                  | Model for prompt/agent handlers               | Documented but unused | Not covered      | Override model for hook evaluation       |
| Handler deduplication    | Identical handlers auto-deduplicated          | Documented but unused | Not covered      | Prevents duplicate hook execution        |

### Hook Configuration Locations

| Location                         | Description                          | Status                | ORCH-REF Section |
|----------------------------------|--------------------------------------|-----------------------|------------------|
| `~/.claude/settings.json`        | User-level hooks                     | Documented but unused | Hooks System     |
| `.claude/settings.json`          | Project-level, version-controllable  | Documented but unused | Hooks System     |
| `.claude/settings.local.json`    | Project-level, gitignored            | Documented but unused | Hooks System     |
| Plugin `hooks/hooks.json`        | Plugin-scoped hooks                  | Documented but unused | Hooks System     |
| Skill/agent frontmatter          | Scoped to specific skill or agent    | Documented but unused | Hooks System     |

### Expanded Notes

**Hook input/output specifics**: Command handlers receive JSON on stdin with fields including `hook_event_name`, `tool_use_id`, `agent_transcript_path`. As of v2.1.47, `Stop` and `SubagentStop` hooks also receive `last_assistant_message` containing the final assistant response text. Output JSON can include `updatedInput` (modify tool input), `additionalContext` (inject context), `permissionDecision` (allow/deny). Environment variables `CLAUDE_PROJECT_DIR` and `CLAUDE_ENV_FILE` are available. Source: code.claude.com/docs/en/hooks.

---

## 4. Plugins

### Plugin Manifest Schema (`plugin.json`)

| Capability      | Description                             | Status                | ORCH-REF Section | Notes                                   |
|-----------------|-----------------------------------------|-----------------------|------------------|-----------------------------------------|
| `name`          | Plugin identifier                       | In use                | Plugins System   | All 3 plugins define name               |
| `version`       | Semantic version                        | In use                | Plugins System   | All 3 plugins define version            |
| `description`   | Brief plugin description                | In use                | Plugins System   | All 3 plugins define description        |
| `author`        | Author object (name, email, url)        | Documented but unused | Plugins System   | Marketplace metadata                    |
| `keywords`      | Keyword array for discovery             | In use                | Plugins System   | Used in marketplace.json                |
| `homepage`      | Documentation URL                       | Documented but unused | Not covered      | For public plugin distribution          |
| `repository`    | Source repository URL                   | Documented but unused | Not covered      | For public plugin distribution          |
| `license`       | License identifier                      | Documented but unused | Not covered      | For public plugin distribution          |
| `commands`      | Custom command file paths               | Documented but unused | Not covered      | Plugin-scoped slash commands            |
| `agents`        | Path to agents directory                | Documented but unused | Plugins System   | Implicit via convention (`agents/`)     |
| `skills`        | Path to skills directory                | Documented but unused | Plugins System   | Implicit via convention (`skills/`)     |
| `hooks`         | Path to hooks config file               | Documented but unused | Plugins System   | `hooks.json` format                     |
| `mcpServers`    | Path to MCP config file                 | Documented but unused | Plugins System   | Plugin-bundled MCP servers              |
| `outputStyles`  | Path to output styles directory         | Documented but unused | Not covered      | Custom output style files               |
| `lspServers`    | Path to LSP config file (`.lsp.json`)   | Documented but unused | Not covered      | Language Server Protocol integration    |

### Plugin Component Types

| Capability     | Description                         | Status                | ORCH-REF Section | Notes                        |
|----------------|-------------------------------------|-----------------------|------------------|------------------------------|
| Skills         | Slash command definitions           | In use                | Plugins System   | 17 skills across 3 plugins   |
| Agents         | Custom subagent definitions         | In use                | Plugins System   | 1 agent (phase-researcher)   |
| Hooks          | Lifecycle hook configs              | Documented but unused | Plugins System   | Via `hooks.json`             |
| MCP Servers    | Model Context Protocol servers      | Documented but unused | Plugins System   | Tool extensions              |
| LSP Servers    | Language Server Protocol servers    | Documented but unused | Not covered      | Real-time code intelligence  |
| Output Styles  | System prompt customization         | Documented but unused | Not covered      | See expanded note below      |
| Commands       | Custom built-in commands            | Documented but unused | Not covered      | Plugin-scoped `/` commands   |

### Plugin Distribution & Management

| Capability                 | Description                                    | Status                | ORCH-REF Section | Notes                                        |
|----------------------------|------------------------------------------------|-----------------------|------------------|----------------------------------------------|
| Relative path source       | `"./plugins/name"` in marketplace              | In use                | Plugins System   | Used by all 3 plugins                        |
| GitHub source              | `"github:user/repo"`                           | Documented but unused | Plugins System   | For public distribution                      |
| npm/pip/URL sources        | Package manager and URL sources                | Documented but unused | Plugins System   | Alternative distribution                     |
| `--plugin-dir PATH`        | Load plugin from local directory for dev       | Documented but unused | Not covered      | Development/testing workflow                 |
| `claude plugin install`    | CLI install command with scope flags           | Documented but unused | Not covered      | `--user` or `--project` scope                |
| `claude plugin update`     | CLI update command                             | Documented but unused | Not covered      | Update installed plugins                     |
| Plugin caching             | Copy-to-cache behavior, path resolution        | Documented but unused | Not covered      | Important for `${CLAUDE_PLUGIN_ROOT}` usage  |
| `${CLAUDE_PLUGIN_ROOT}`    | Plugin root env var in hooks/scripts           | Documented but unused | Not covered      | Resolves paths within cached plugins         |
| `FORCE_AUTOUPDATE_PLUGINS` | Force plugin auto-update env var               | Documented but unused | Not covered      | Override update behavior                     |
| Plugin scopes              | User-scope vs project-scope installation       | Documented but unused | Not covered      | Controls plugin visibility                   |
| Plugin pinning             | Pin plugin to specific version                 | Documented but unused | Not covered      | Prevent unintended updates                   |

### Expanded Notes

**Output Styles**: Output styles customize Claude's system prompt to change response format and behavior. Files use markdown with `name`, `description`, `keep-coding-instructions` (boolean) frontmatter. Shipped via plugin `outputStyles` directory, activated via `/output-style` command or `outputStyle` setting. Predefined styles include Explanatory, Learning, and others. Source: code.claude.com/docs/en/output-styles.

**LSP Servers**: Plugins can bundle Language Server Protocol configurations via `.lsp.json`. Provides real-time code intelligence: diagnostics, go-to-definition, find-references, hover info. The LSP tool is the client-side interface. Source: code.claude.com/docs/en/plugins-reference#lsp-servers.

---

## 5. Tools

See ORCH-REF "Task Tool (Spawning & Lifecycle)" and "Agent Teams" for detailed tool parameters. This section lists all 25 tools with permission requirements.

| Tool               | Permission Required | Status                | ORCH-REF Section  | Notes                               |
|--------------------|---------------------|-----------------------|-------------------|-------------------------------------|
| `AskUserQuestion`  | No                  | In use                | Not covered       | Multiple-choice user interaction    |
| `Bash`             | Yes                 | In use                | Not covered       | Shell command execution             |
| `Edit`             | Yes                 | In use                | Not covered       | Targeted file edits                 |
| `ExitPlanMode`     | Yes                 | Documented but unused | Plan Mode         | Prompts user to exit plan mode      |
| `Glob`             | No                  | In use                | Not covered       | File pattern matching               |
| `Grep`             | No                  | In use                | Not covered       | Content search with regex           |
| `KillShell`        | No                  | Documented but unused | Not covered       | Kill background bash shell          |
| `LSP`              | No                  | In use                | Not covered       | Language server operations          |
| `MCPSearch`        | No                  | Documented but unused | Not covered       | Search/load MCP tools dynamically   |
| `NotebookEdit`     | Yes                 | Documented but unused | Not covered       | Jupyter notebook cell editing       |
| `Read`             | No                  | In use                | Not covered       | File content reading                |
| `Skill`            | Yes                 | In use                | Not covered       | Invoke skill programmatically       |
| `Task`             | No                  | In use                | Task Tool         | Subagent spawning                   |
| `TaskCreate`       | No                  | In use                | Task Management   | Create task in list                 |
| `TaskGet`          | No                  | In use                | Task Management   | Fetch task details                  |
| `TaskList`         | No                  | In use                | Task Management   | List all tasks                      |
| `TaskOutput`       | No                  | In use                | Background Tasks  | Retrieve background task output     |
| `TaskStop`         | No                  | In use                | Background Tasks  | Stop background task                |
| `TaskUpdate`       | No                  | In use                | Task Management   | Update task status/deps             |
| `TeamCreate`       | No                  | In use                | Agent Teams       | Create agent team                   |
| `TeamDelete`       | No                  | In use                | Agent Teams       | Remove team resources               |
| `SendMessage`      | No                  | In use                | Agent Teams       | Inter-agent messaging               |
| `WebFetch`         | Yes                 | In use                | Not covered       | Fetch URL content                   |
| `WebSearch`        | Yes                 | In use                | Not covered       | Web search                          |
| `Write`            | Yes                 | In use                | Not covered       | Create/overwrite files              |

### Notes

**MCP tool naming**: MCP tools use `mcp__<server>__<tool>` naming. Hook matchers can use regex patterns like `mcp__.*__write.*`. Wildcard permissions: `mcp__server__*`. See ORCH-REF "MCP Servers" section.

---

## 6. CLI Flags

All CLI flags are **Documented but unused** by this marketplace (plugins do not invoke CLI flags). See ORCH-REF "CLI Flags for Orchestration" for the full table. Summarized here for audit completeness.

### Agent & Model Control

| Flag                 | Description                                | Status                | ORCH-REF Section |
|----------------------|--------------------------------------------|-----------------------|------------------|
| `--agent NAME`           | Run session as specific agent              | Documented but unused | CLI Flags        |
| `--agents JSON`          | Define agents inline (session-only)        | Documented but unused | CLI Flags        |
| `--model ALIAS`          | Model override (sonnet/opus/haiku)         | Documented but unused | CLI Flags        |
| `--fallback-model`       | Automatic fallback when overloaded         | Documented but unused | CLI Flags        |
| `--tools TOOLS`          | Restrict available tools                   | Documented but unused | CLI Flags        |
| `--disallowedTools`      | Deny specific tools                        | Documented but unused | CLI Flags        |

### Session Control

| Flag                | Description                              | Status                | ORCH-REF Section |
|---------------------|------------------------------------------|-----------------------|------------------|
| `--continue` / `-c` | Resume most recent session               | Documented but unused | CLI Flags        |
| `--resume`          | Resume specific session                  | Documented but unused | CLI Flags        |
| `--fork-session`    | Create divergent branch on resume        | Documented but unused | CLI Flags        |
| `--session-id`      | Use specific session ID                  | Documented but unused | CLI Flags        |
| `--from-pr`         | Resume from GitHub PR                    | Documented but unused | CLI Flags        |

### Execution Control

| Flag                            | Description                       | Status                | ORCH-REF Section |
|---------------------------------|-----------------------------------|-----------------------|------------------|
| `-p` / `--print`                | Headless (non-interactive) mode   | Documented but unused | CLI Flags        |
| `--output-format`               | `text`, `json`, `stream-json`     | Documented but unused | CLI Flags        |
| `--max-turns`                   | Turn limit                        | Documented but unused | CLI Flags        |
| `--max-budget-usd`              | Spending cap                      | Documented but unused | CLI Flags        |
| `--permission-mode`             | Permission strategy               | Documented but unused | CLI Flags        |
| `--dangerously-skip-permissions`| Bypass all checks                 | Documented but unused | CLI Flags        |

### System Prompt

| Flag                      | Description              | Status                | ORCH-REF Section |
|---------------------------|--------------------------|-----------------------|------------------|
| `--system-prompt`         | Replace entire prompt    | Documented but unused | CLI Flags        |
| `--system-prompt-file`    | Load from file           | Documented but unused | CLI Flags        |
| `--append-system-prompt`  | Add to default           | Documented but unused | CLI Flags        |

### Configuration

| Flag                    | Description                           | Status                | ORCH-REF Section |
|-------------------------|---------------------------------------|-----------------------|------------------|
| `--mcp-config`          | Load MCP servers                      | Documented but unused | CLI Flags        |
| `--add-dir`             | Additional working directories        | Documented but unused | CLI Flags        |
| `--settings`            | Load settings from file               | Documented but unused | CLI Flags        |
| `--setting-sources`     | Choose sources (user/project/local)   | Documented but unused | CLI Flags        |
| `--init` / `--maintenance` | Trigger Setup hooks                | Documented but unused | CLI Flags        |
| `--teammate-mode`       | Team display mode (auto/in-process/tmux) | Documented but unused | CLI Flags     |
| `--plugin-dir`          | Load plugin from local directory      | Documented but unused | Not covered      |

---

## 7. Settings & Permissions

See ORCH-REF "Settings & Permissions" for precedence order, permission modes, and rule syntax.

### Settings Precedence

| Level          | Location                        | Status                | ORCH-REF Section       |
|----------------|----------------------------------|-----------------------|------------------------|
| CLI flags      | Command line                     | Documented but unused | Settings & Permissions |
| Project local  | `.claude/settings.local.json`    | Documented but unused | Settings & Permissions |
| Project        | `.claude/settings.json`          | In use                | Settings & Permissions |
| User           | `~/.claude/settings.json`        | In use                | Settings & Permissions |
| Managed policy | Enterprise policies              | Documented but unused | Settings & Permissions |

### Key Settings (Selected)

| Setting                  | Description                          | Status                | ORCH-REF Section       |
|--------------------------|--------------------------------------|-----------------------|------------------------|
| `permissions.allow`      | Permission allowlist rules           | In use                | Settings & Permissions |
| `permissions.deny`       | Permission denylist rules            | In use                | Settings & Permissions |
| `model`                  | Default model override               | Documented but unused | Not covered            |
| `outputStyle`            | Active output style                  | Documented but unused | Not covered            |
| `language`               | Response language preference         | Documented but unused | Not covered            |
| `teammateMode`           | Team display mode                    | Documented but unused | Agent Teams            |
| `env`                    | Environment variable overrides       | Documented but unused | Not covered            |
| `hooks`                  | Hook definitions                     | Documented but unused | Hooks System           |
| `enabledPlugins`         | Plugin enable/disable list           | Documented but unused | Not covered            |
| `statusLine`             | Custom status line config            | Documented but unused | Status Line            |
| `sandbox.*`              | Sandbox configuration                | Documented but unused | Settings & Permissions |
| `respectGitignore`       | Honor .gitignore in file ops         | Documented but unused | Not covered            |
| `cleanupPeriodDays`      | Session cleanup period (default 30)  | Documented but unused | Not covered            |
| `disableAllHooks`        | Global hook disable                  | Documented but unused | Not covered            |
| `alwaysThinkingEnabled`  | Force thinking on all requests       | Documented but unused | Not covered            |

### Permission Modes

Fully documented in ORCH-REF "Settings & Permissions": `default`, `acceptEdits`, `plan`, `dontAsk`, `bypassPermissions`, `delegate`.

### Permission Rule Syntax

Fully documented in ORCH-REF "Settings & Permissions": `Tool`, `Tool(pattern)`, `Task(agent-name)`, wildcard `*`, regex patterns. `deny` always wins over `allow`.

---

## 8. Memory & Context

### CLAUDE.md Locations

| Location                   | Description                                  | Status                | ORCH-REF Section  | Notes                                         |
|----------------------------|----------------------------------------------|-----------------------|-------------------|-----------------------------------------------|
| Project root `CLAUDE.md`   | Project instructions, auto-loaded            | In use                | Memory & Context  | Used for project conventions                  |
| `.claude/CLAUDE.md`        | Alternative project location                 | Documented but unused | Memory & Context  | Equivalent to root CLAUDE.md                  |
| `~/.claude/CLAUDE.md`      | User-level global instructions               | In use                | Memory & Context  | Personal preferences                          |
| `CLAUDE.local.md`          | Gitignored per-project preferences           | Documented but unused | Not covered       | Auto-added to .gitignore                      |
| Managed policy CLAUDE.md   | Organization-wide instructions               | Documented but unused | Not covered       | OS-specific paths; enterprise                 |
| Nested CLAUDE.md           | Child directory CLAUDE.md loaded on demand   | Documented but unused | Memory & Context  | Loaded when Claude reads files in directory   |

### Memory Features

| Capability                        | Description                                      | Status                | ORCH-REF Section      | Notes                             |
|-----------------------------------|--------------------------------------------------|-----------------------|-----------------------|-----------------------------------|
| `@import` syntax                  | Import additional files into CLAUDE.md           | Documented but unused | Memory & Context      | Max depth of 5 hops               |
| Import approval dialog            | First-time import shows approval                 | Documented but unused | Not covered           | One-time per project              |
| `.claude/rules/`                  | Modular rules with path frontmatter              | Documented but unused | Memory & Context      | Glob-based conditional context    |
| Auto Memory                       | Automatic learning persistence                   | In use                | Not covered           | See expanded note                 |
| MEMORY.md                         | Auto Memory entrypoint (200-line limit)          | In use                | Not covered           | Used in `~/.claude/projects/`     |
| `/memory` command                 | View and manage auto memory                      | Documented but unused | Not covered           | Interactive memory management     |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | Disable auto memory env var                      | Documented but unused | Not covered           | Set to 1 to disable               |
| Subagent memory                   | Persistent memory per agent (user/project/local) | Documented but unused | Memory & Context      | See Agents section                |
| Context compaction                | Auto-compact at ~80-95% context usage            | Documented but unused | Context & Compaction  | Enabled by default                |
| `/compact`                        | Manual compaction with optional focus            | Documented but unused | Context & Compaction  | `/compact focus on X`             |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Override compact threshold                       | Documented but unused | Context & Compaction  | Value 1-100                       |

### Expanded Notes

**Auto Memory**: Claude automatically saves learnings to `MEMORY.md` in project-scoped directories (`~/.claude/projects/{project}/`). Can also create topic-specific files. First 200 lines of MEMORY.md are loaded into the system prompt. Disable with `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`. Manage with `/memory` command. Source: code.claude.com/docs/en/memory#auto-memory.

**CLAUDE.local.md**: Gitignored personal overrides placed alongside CLAUDE.md. Automatically added to `.gitignore`. Use for personal API keys, local paths, or style preferences that should not be committed. Source: code.claude.com/docs/en/memory#determine-memory-type.

**Modular rules**: Place `.md` files in `.claude/rules/` with optional `paths` frontmatter containing glob patterns. Rules are loaded only when Claude works with matching files. User-level rules go in `~/.claude/rules/`. Source: code.claude.com/docs/en/memory#modular-rules-with-claude-rules.

---

## 9. Session Management

All session capabilities are **Documented but unused** by this marketplace. See ORCH-REF "Session Management" for persistence, resumption, and forking details.

| Capability           | Description                                    | Status                | ORCH-REF Section    | Notes                                |
|----------------------|------------------------------------------------|-----------------------|---------------------|--------------------------------------|
| Auto-save            | Sessions saved to `.claude/projects/{project}/`| Documented but unused | Session Management  | Automatic; always on                 |
| `--resume`           | Resume specific session                        | Documented but unused | Session Management  | Full context restoration             |
| `--continue` / `-c`  | Resume most recent session                     | Documented but unused | Session Management  | Convenience shorthand                |
| Named sessions       | `/rename` to name, `--resume <name>`           | Documented but unused | Session Management  | Human-friendly session IDs           |
| `/resume`            | Session picker UI                              | Documented but unused | Session Management  | Interactive session selection        |
| `--fork-session`     | Divergent branch on resume                     | Documented but unused | Session Management  | New session ID, preserved context    |
| Checkpointing        | Automatic file edit tracking                   | Documented but unused | Not covered         | See expanded note                    |
| `/rewind`            | Restore to previous checkpoint                 | Documented but unused | Not covered         | Undo file changes                    |
| `Esc+Esc`            | Quick access to checkpoint restore             | Documented but unused | Not covered         | Shortcut for /rewind; ESC no longer kills background agents (use ctrl+f) |
| Restore options      | Restore code only, conversation, or both       | Documented but unused | Not covered         | Granular undo control                |
| Summarize-from-here  | Partial context summarization                  | Documented but unused | Not covered         | Selective compaction                 |
| `--remote`           | Create web session                             | Documented but unused | Session Management  | Remote execution                     |
| `--teleport`         | Resume web session locally                     | Documented but unused | Session Management  | Pull remote session local            |
| `--from-pr`          | Resume from GitHub PR                          | Documented but unused | Session Management  | PR-based session                     |
| Background agents    | Agents running in background                   | Documented but unused | Background Tasks    | Via `run_in_background: true`        |

### Expanded Notes

**Checkpointing/Rewind**: Claude Code automatically tracks file edit checkpoints. Use `/rewind` or press `Esc+Esc` to access restore options: restore code only (revert file changes), restore conversation (reset to that point), or restore both. "Summarize from here" option performs partial context summarization from a selected point. Source: code.claude.com/docs/en/checkpointing.

---

## 10. Monitoring & UI

All monitoring capabilities are **Documented but unused** by this marketplace. See ORCH-REF "Status Line & Monitoring" for status line configuration.

### Built-in Commands

| Command          | Description                      | Status                | ORCH-REF Section    |
|------------------|----------------------------------|-----------------------|---------------------|
| `/cost`          | Track usage and costs            | Documented but unused | Status Line         |
| `/context`       | Detailed context breakdown       | Documented but unused | Status Line         |
| `/stats`         | Session statistics               | Documented but unused | Status Line         |
| `/compact`       | Manual context compaction        | Documented but unused | Context & Compaction|
| `/config`        | Settings editor                  | Documented but unused | Not covered         |
| `/plan`          | Enter plan mode                  | Documented but unused | Plan Mode           |
| `/output-style`  | Switch output style              | Documented but unused | Not covered         |
| `/keybindings`   | View/edit keybindings            | Documented but unused | Not covered         |
| `/hooks`         | View hook configuration          | Documented but unused | Not covered         |
| `/agents`        | View/create agents               | Documented but unused | Custom Agents       |
| `/debug`         | Debug mode toggle                | Documented but unused | Not covered         |
| `/memory`        | View auto memory                 | Documented but unused | Not covered         |
| `/init`          | Run project initialization       | Documented but unused | Not covered         |
| `/resume`        | Session picker                   | Documented but unused | Session Management  |
| `/rename`        | Rename current session           | Documented but unused | Session Management  |
| `/rewind`        | Checkpoint restore               | Documented but unused | Not covered         |
| `/fast`          | Toggle fast mode                 | Documented but unused | Not covered         |
| `/vim`           | Toggle vim mode                  | Documented but unused | Not covered         |
| `/doctor`        | Diagnose configuration issues    | Documented but unused | Not covered         |

### Status Line

| Capability              | Description                                 | Status                | ORCH-REF Section |
|-------------------------|---------------------------------------------|-----------------------|------------------|
| `statusLine` setting    | Custom status line with `type: "command"`   | Documented but unused | Status Line      |
| JSON input fields       | Context usage, cost, model, token counts    | Documented but unused | Status Line      |
| `statusline-setup`      | Built-in setup agent                        | Documented but unused | Custom Agents    |

### Other Monitoring

| Capability | Description                              | Status                | ORCH-REF Section |
|------------|------------------------------------------|-----------------------|------------------|
| OTEL       | OpenTelemetry logging                    | Documented but unused | Status Line      |
| Fast mode  | Same model, faster output; toggle `/fast`| Documented but unused | Not covered      |

### Keybindings

| Capability                   | Description                          | Status                | ORCH-REF Section |
|------------------------------|--------------------------------------|-----------------------|------------------|
| `~/.claude/keybindings.json` | Custom keyboard shortcuts            | Documented but unused | Not covered      |
| `/keybindings` command       | View and edit keybindings            | Documented but unused | Not covered      |
| 17 contexts                  | Context-specific keybinding scopes   | Documented but unused | Not covered      |
| Chord support                | Multi-key combinations               | Documented but unused | Not covered      |
| Hot-reload                   | Keybindings reload on file change    | Documented but unused | Not covered      |
| Vim mode                     | Vi-style editing; toggle `/vim`      | Documented but unused | Not covered      |

---

## 11. Agent Teams

See ORCH-REF "Agent Teams (Experimental)" for detailed tool parameters, coordination mechanics, and display modes. This marketplace uses teams in `/execute-phase` with `--team` flag.

| Capability                             | Description                              | Status                | ORCH-REF Section | Notes                           |
|----------------------------------------|------------------------------------------|-----------------------|------------------|---------------------------------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable teams env var                     | In use                | Agent Teams      | Referenced in execute-phase     |
| `TeamCreate`                           | Create team with shared task list        | In use                | Agent Teams      | Used in execute-phase           |
| `TeamDelete`                           | Remove team resources                    | In use                | Agent Teams      | Cleanup after execution         |
| `SendMessage`                          | Inter-agent DMs and broadcasts           | In use                | Agent Teams      | Teammate coordination           |
| Shared task list                       | Cross-agent task visibility              | Documented but unused | Agent Teams      | Beyond current usage pattern    |
| Task dependencies                      | Cross-agent blocking/unblocking          | Documented but unused | Agent Teams      | `addBlocks`/`addBlockedBy`      |
| `--teammate-mode`                      | Display mode (auto/in-process/tmux)      | Documented but unused | Agent Teams      | Visual preference               |
| Graceful shutdown                      | Negotiated via shutdown_request/response | Documented but unused | Agent Teams      | Clean team teardown             |
| Plan approval workflow                 | Lead approves/rejects teammate plans     | Documented but unused | Agent Teams      | Via `plan_approval_response`    |

---

## 12. Environment Variables

| Variable                                         | Description                             | Status                | ORCH-REF Section      | Notes |
|--------------------------------------------------|-----------------------------------------|-----------------------|-----------------------|-------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`         | Enable agent teams (set to `1`)                | In use                | Agent Teams           |       |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`              | Override auto-compact threshold (1-100)        | Documented but unused | Context & Compaction  |       |
| `BASH_DEFAULT_TIMEOUT_MS`                      | Default bash command timeout                   | Documented but unused | Background Tasks      |       |
| `SLASH_COMMAND_TOOL_CHAR_BUDGET`               | Skill description character budget             | Documented but unused | Not covered           | Default 2% of context |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY`              | Disable auto memory (set to 1)                 | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`         | Disable background tasks                       | Documented but unused | Not covered           |       |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR`     | Reset cwd after each Bash (set to `1`)         | Documented but unused | Not covered           |       |
| `CLAUDE_ENV_FILE`                              | Env file path for hooks                        | Documented but unused | Not covered           | Persists vars across hooks |
| `CLAUDE_PROJECT_DIR`                           | Project root (available in hooks)              | Documented but unused | Not covered           |       |
| `CLAUDE_PLUGIN_ROOT`                           | Plugin root (available in plugin hooks)        | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_REMOTE`                           | Remote web environment flag (set to `"true"`)  | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_TMPDIR`                           | Override temp directory                        | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_EXIT_AFTER_STOP_DELAY`            | Delay before exit after stop                   | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_SHELL`                            | Override shell executable                      | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_SHELL_PREFIX`                     | Shell prefix command                           | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS`      | Max tokens for file reads                      | Documented but unused | Not covered           |       |
| `CLAUDE_BASH_NO_LOGIN`                         | Skip login shell initialization                | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_ENABLE_TASKS`                     | Enable task management tools                   | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`     | Minimize network traffic                       | Documented but unused | Not covered           |       |
| `ANTHROPIC_DEFAULT_SONNET_MODEL`               | Override sonnet model alias                    | Documented but unused | Not covered           |       |
| `ANTHROPIC_DEFAULT_OPUS_MODEL`                 | Override opus model alias                      | Documented but unused | Not covered           |       |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL`                | Override haiku model alias                     | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`       | Disable experimental features                  | Documented but unused | Not covered           |       |
| `DISABLE_INTERLEAVED_THINKING`                 | Disable interleaved thinking                   | Documented but unused | Not covered           |       |
| `USE_BUILTIN_RIPGREP`                          | Use built-in ripgrep binary                    | Documented but unused | Not covered           |       |
| `MCP_TIMEOUT`                                  | MCP server connection timeout                  | Documented but unused | Not covered           |       |
| `MCP_TOOL_TIMEOUT`                             | MCP tool execution timeout                     | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | Load CLAUDE.md from --add-dir dirs (set to `1`)| Documented but unused | Not covered           |       |
| `FORCE_AUTOUPDATE_PLUGINS`                     | Force plugin auto-update                       | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_EFFORT_LEVEL`                     | Override effort level                          | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS`                | Max output tokens                              | Documented but unused | Not covered           |       |
| `MAX_THINKING_TOKENS`                          | Max thinking budget tokens                     | Documented but unused | Not covered           |       |
| `ENABLE_TOOL_SEARCH`                           | Enable MCPSearch tool                          | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_SUBAGENT_MODEL`                   | Override model for subagents                   | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_TASK_LIST_ID`                     | Specify task list ID                           | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_PROXY_RESOLVES_HOSTS`             | Proxy DNS resolution                           | Documented but unused | Not covered           |       |
| `CLAUDE_CODE_AUTO_CONNECT_IDE`                 | Auto-connect IDE integration                   | Documented but unused | Not covered           |       |
| `IS_DEMO`                                      | Demo mode flag                                 | Documented but unused | Not covered           |       |

---

## Unverified Items

Items found in a single source only. Empirical testing would confirm or deny.

| Item                            | Single Source                  | What Would Confirm                                                                |
|---------------------------------|--------------------------------|-----------------------------------------------------------------------------------|
| Task tool `mode` parameter      | ORCHESTRATION-REFERENCE.md     | Spawn a Task with `mode: "plan"` and verify agent runs in plan mode              |
| Claude Agent SDK full API       | ORCH-REF + training data       | Install `@anthropic-ai/claude-agent-sdk`, verify `query()`, `canUseTool`, etc.   |

---

## Changelog Watch

Capability areas to re-check when Claude Code updates. These are fast-moving or recently-added areas where new capabilities are most likely to appear.

| Area               | What to Check                                                      | Last Verified |
|--------------------|--------------------------------------------------------------------|---------------|
| Agent Teams        | New team tools, teammate modes, team-scoped hooks                  | 2026-02-20    |
| Hooks              | New hook events, handler types, input/output fields                | 2026-02-20    |
| Plugin system      | New component types, manifest fields, distribution methods         | 2026-02-20    |
| Skills frontmatter | New fields, variable substitution enhancements                     | 2026-02-20    |
| CLI flags          | New flags, especially `--from-pr`, `--remote` evolution            | 2026-02-20    |
| Output Styles      | New predefined styles, frontmatter fields                          | 2026-02-11    |
| MCP                | New MCP features, auto:N syntax, MCPSearch evolution               | 2026-02-11    |
| Session management | Checkpointing improvements, remote session features                | 2026-02-20    |
| Agent SDK          | New SDK features, Python SDK maturity                              | 2026-02-11    |
| Memory             | Auto Memory improvements, modular rules enhancements               | 2026-02-11    |

---

## Sources

| Source                     | URL                                                               |
|----------------------------|-------------------------------------------------------------------|
| Skills Documentation       | https://code.claude.com/docs/en/skills                            |
| Subagents Documentation    | https://code.claude.com/docs/en/sub-agents                        |
| Agent Teams Documentation  | https://code.claude.com/docs/en/agent-teams                       |
| Hooks Reference            | https://code.claude.com/docs/en/hooks                             |
| Hooks Guide                | https://code.claude.com/docs/en/hooks-guide                       |
| Plugins Reference          | https://code.claude.com/docs/en/plugins-reference                 |
| Create Plugins Guide       | https://code.claude.com/docs/en/plugins                           |
| Output Styles              | https://code.claude.com/docs/en/output-styles                     |
| Memory Documentation       | https://code.claude.com/docs/en/memory                            |
| Settings Documentation     | https://code.claude.com/docs/en/settings                          |
| Permissions                | https://code.claude.com/docs/en/permissions                       |
| Checkpointing              | https://code.claude.com/docs/en/checkpointing                     |
| CLI Reference              | https://code.claude.com/docs/en/cli-reference                     |
| Keybindings                | https://code.claude.com/docs/en/keybindings                       |
| Fast Mode                  | https://code.claude.com/docs/en/fast-mode                         |
| Status Line                | https://code.claude.com/docs/en/statusline                        |
| ORCHESTRATION-REFERENCE.md | Project root (companion document)                                 |
| Phase 1 Research           | `.planning/phases/01-claude-code-capability-mapping/01-RESEARCH.md` |
