# Claude Code Orchestration & Multi-Agent Reference

A comprehensive guide to all Claude Code features, tools, and mechanisms for building orchestration layers and controlling multiple agents.

---

## Table of Contents

- [Thinking Control](#thinking-control)
- [Context & Compaction](#context--compaction)
- [Custom Agents (Subagents)](#custom-agents-subagents)
- [Task Tool (Spawning & Lifecycle)](#task-tool-spawning--lifecycle)
- [Agent Teams (Experimental)](#agent-teams-experimental)
- [Skills System](#skills-system)
- [Hooks System](#hooks-system)
- [Plan Mode](#plan-mode)
- [Claude Agent SDK](#claude-agent-sdk)
- [Task Management System](#task-management-system)
- [Background Tasks & Async Execution](#background-tasks--async-execution)
- [MCP Servers](#mcp-servers)
- [Settings & Permissions](#settings--permissions)
- [CLI Flags for Orchestration](#cli-flags-for-orchestration)
- [Session Management](#session-management)
- [Memory & Context](#memory--context)
- [Plugins System](#plugins-system)
- [Status Line & Monitoring](#status-line--monitoring)
- [Manager Pattern Without Teams](#manager-pattern-without-teams)
- [Orchestration Patterns Summary](#orchestration-patterns-summary)

---

## Thinking Control

### Per-Skill Thinking

There is **no dedicated frontmatter field** to set thinking effort per skill. The available workaround is to include thinking keywords directly in the skill's markdown body:

- `think` -- basic thinking
- `think harder` -- deeper analysis
- `ultrathink` -- maximum thinking effort

Example:

```markdown
---
name: deep-analysis
description: Deeply analyze code architecture
allowed-tools: Read, Grep, Glob
---

ultrathink

Analyze the following codebase for architectural issues...
```

**Limitations:**

- Binary toggle per keyword -- pick one level and bake it into the skill
- No `thinking-level` or `thinking-budget` frontmatter field exists
- Global toggle via `/config` or `Alt+T` affects all interactions

**Workarounds for varying effort:**

- Create separate skill variants (e.g., `quick-review` vs `deep-review` with `ultrathink`)
- Use the `model` frontmatter field to pair thinking with a specific model (e.g., `model: opus`)
- Toggle thinking globally via `/config` or `Alt+T` and invoke skills manually

---

## Context & Compaction

### Auto-Compact

- Triggers when conversation approaches ~80-95% of context window
- Enabled by default, toggle in `/config`
- Made instant as of version 2.0.64
- Custom threshold override: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` environment variable

### Manual Compact

- `/compact` command at any time
- Optional instruction: `/compact focus on the auth refactor`
- "Summarize from here" option in message selector for partial summarization

### Context Monitoring

- `context_window.used_percentage` and `context_window.remaining_percentage` in status line
- `/context` command for detailed breakdown

### Re-injection After Compaction

- `SessionStart` hook with `compact` matcher re-injects critical context
- `PreCompact` hook fires before compaction with custom instructions

---

## Custom Agents (Subagents)

### Creation & Location

- **Interactive**: `/agents` command
- **Project-level**: `.claude/agents/AGENT.md`
- **User-level**: `~/.claude/agents/AGENT.md`
- **CLI-defined**: `--agents` flag with JSON (session-only)
- **Plugin agents**: bundled in plugin `agents/` directory

### Frontmatter Fields (Complete)

| Field             | Purpose                                                                      |
| ----------------- | ---------------------------------------------------------------------------- |
| `name`            | Unique identifier (lowercase, hyphens)                                       |
| `description`     | When Claude should delegate to this agent                                    |
| `tools`           | Allowed tools (allowlist)                                                    |
| `disallowedTools` | Denied tools (denylist)                                                      |
| `model`           | `sonnet`, `opus`, `haiku`, or `inherit`                                      |
| `permissionMode`  | `default`, `acceptEdits`, `delegate`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns`        | Maximum agentic turns before stopping                                        |
| `skills`          | Array of skill names to preload                                              |
| `mcpServers`      | MCP servers available to this agent                                          |
| `hooks`           | Lifecycle hooks scoped to this agent                                         |
| `memory`          | Persistent memory scope: `user`, `project`, or `local`                       |

### Tool Restriction Syntax

- `tools: Read, Glob, Grep` -- allowlist
- `disallowedTools: Write, Edit` -- denylist
- `Task(worker, researcher)` -- restrict which child agents can be spawned
- `Task` without parentheses -- allow any subagent

### Built-in Agent Types

- **Explore**: fast read-only codebase exploration (Haiku)
- **Plan**: read-only research for plan mode
- **general-purpose**: full tool access, complex multi-step tasks
- **Bash**: separate context for terminal commands
- **statusline-setup**: configure status line UI

### Invocation Methods

- Automatic delegation by description match
- Explicit: "Use the X subagent to..."
- `@agent-name` mention
- Via the `Task` tool directly

---

## Task Tool (Spawning & Lifecycle)

### Parameters

| Parameter           | Purpose                                             |
| ------------------- | --------------------------------------------------- |
| `prompt`            | Task description for the agent                      |
| `description`       | Short 3-5 word summary                              |
| `subagent_type`     | Agent type to use                                   |
| `model`             | Optional model override (`sonnet`, `opus`, `haiku`) |
| `run_in_background` | Run concurrently (boolean)                          |
| `resume`            | Agent ID to continue from prior transcript          |
| `team_name`         | Spawn as teammate in a team                         |
| `name`              | Human-readable name for the teammate                |
| `mode`              | Permission mode override                            |
| `max_turns`         | Turn limit                                          |

### Execution Modes

- **Foreground**: blocks main conversation until complete
- **Background**: runs concurrently, check with `TaskOutput`
- **Resume**: continue from previous transcript with full context
- **Parallel**: multiple Task calls in one message for concurrent work

### Key Constraints

- Subagents cannot spawn their own subagents (flat hierarchy)
- Background agents cannot use MCP tools
- Each subagent has an independent context window
- Main conversation history is NOT passed to workers

---

## Agent Teams (Experimental)

### Enabling

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Can also be set in `settings.json` under the `env` key.

### Architecture

- **Team lead**: main session that creates and coordinates
- **Teammates**: separate Claude Code instances with independent contexts
- **Shared task list**: work items with dependency tracking
- **Mailbox**: messaging system for inter-agent communication

### Complete Tool List (9 Tools)

#### 1. TeamCreate

Creates a new team to coordinate multiple agents.

| Parameter     | Required | Purpose                       |
| ------------- | -------- | ----------------------------- |
| `team_name`   | Yes      | Name for the team             |
| `description` | No       | Team description/purpose      |
| `agent_type`  | No       | Type/role of the team lead    |

Creates:
- Team config at `~/.claude/teams/{team-name}/config.json`
- Task directory at `~/.claude/tasks/{team-name}/`

#### 2. TeamDelete

Removes team and task directories when work is complete. Takes no parameters (uses current session's team context). **Fails if teammates are still active** -- send `shutdown_request` to all teammates first.

#### 3. SendMessage

Inter-agent communication tool with 5 message types:

**`type: "message"` -- Direct Message**
| Parameter   | Required | Purpose                              |
| ----------- | -------- | ------------------------------------ |
| `type`      | Yes      | `"message"`                          |
| `recipient` | Yes      | Teammate name (not UUID)             |
| `content`   | Yes      | Message text                         |
| `summary`   | Yes      | 5-10 word preview shown in UI        |

**`type: "broadcast"` -- Message All Teammates**
| Parameter | Required | Purpose                                 |
| --------- | -------- | --------------------------------------- |
| `type`    | Yes      | `"broadcast"`                           |
| `content` | Yes      | Message to send to everyone             |
| `summary` | Yes      | 5-10 word preview shown in UI           |

Use sparingly -- each broadcast sends N separate messages (one per teammate).

**`type: "shutdown_request"` -- Request Graceful Exit**
| Parameter   | Required | Purpose                         |
| ----------- | -------- | ------------------------------- |
| `type`      | Yes      | `"shutdown_request"`            |
| `recipient` | Yes      | Teammate name                   |
| `content`   | No       | Reason for shutdown             |

**`type: "shutdown_response"` -- Respond to Shutdown**
| Parameter    | Required | Purpose                         |
| ------------ | -------- | ------------------------------- |
| `type`       | Yes      | `"shutdown_response"`           |
| `request_id` | Yes      | ID from the shutdown request    |
| `approve`    | Yes      | `true` to exit, `false` to stay |
| `content`    | No       | Reason (if rejecting)           |

**`type: "plan_approval_response"` -- Approve/Reject Plan**
| Parameter    | Required | Purpose                               |
| ------------ | -------- | ------------------------------------- |
| `type`       | Yes      | `"plan_approval_response"`            |
| `request_id` | Yes      | ID from the plan approval request     |
| `recipient`  | Yes      | Teammate name                         |
| `approve`    | Yes      | `true` to approve, `false` to reject  |
| `content`    | No       | Feedback (if rejecting)               |

#### 4. TaskCreate

Create a task in the shared team task list.

| Parameter     | Required | Purpose                                                              |
| ------------- | -------- | -------------------------------------------------------------------- |
| `subject`     | Yes      | Brief imperative title (e.g., "Fix auth bug in login flow")         |
| `description` | Yes      | Detailed requirements and acceptance criteria                        |
| `activeForm`  | No       | Present continuous form for spinner (e.g., "Fixing auth bug")       |
| `metadata`    | No       | Arbitrary key-value metadata to attach                               |

All tasks are created with status `pending` and no owner.

#### 5. TaskUpdate

Update any task's status, ownership, dependencies, or details.

| Parameter      | Required | Purpose                                                   |
| -------------- | -------- | --------------------------------------------------------- |
| `taskId`       | Yes      | Task ID to update                                         |
| `status`       | No       | `pending`, `in_progress`, `completed`, or `deleted`       |
| `subject`      | No       | New task title                                            |
| `description`  | No       | New task description                                      |
| `activeForm`   | No       | New spinner text                                          |
| `owner`        | No       | Assign to a teammate by name                              |
| `addBlocks`    | No       | Array of task IDs that this task blocks                   |
| `addBlockedBy` | No       | Array of task IDs that must complete before this one      |
| `metadata`     | No       | Merge metadata keys (set key to `null` to delete)         |

Key behaviors:
- `addBlocks` / `addBlockedBy` create dependency chains
- Blocked tasks auto-unblock when dependencies complete
- Setting `status: "deleted"` permanently removes the task

#### 6. TaskGet

Retrieve full details of a specific task.

| Parameter | Required | Purpose         |
| --------- | -------- | --------------- |
| `taskId`  | Yes      | Task ID to fetch |

Returns: subject, description, status, owner, blocks, blockedBy.

#### 7. TaskList

List all tasks in the team's shared task list. Takes no parameters.

Returns per task: id, subject, status, owner, blockedBy. Use to find available (pending, unowned, unblocked) tasks.

#### 8. TaskOutput

Retrieve output from a running or completed background task/agent.

| Parameter | Required | Default | Purpose                                      |
| --------- | -------- | ------- | -------------------------------------------- |
| `task_id` | Yes      | --      | ID of the background task                    |
| `block`   | Yes      | `true`  | `true` to wait for completion, `false` to poll |
| `timeout` | No       | 30000   | Max wait time in ms (max 600000)             |

Use `block: false` for non-blocking progress checks. Use `block: true` to wait for a specific agent to finish.

#### 9. TaskStop

Stop a running background task.

| Parameter | Required | Purpose                          |
| --------- | -------- | -------------------------------- |
| `task_id` | Yes      | ID of the background task to stop |

Note: TaskCreate/Update/Get/List/Output/Stop exist without teams too, but with teams enabled they operate on a **shared task list** visible to all teammates rather than being session-local.

### Display Modes

- **In-process**: all teammates in main terminal (Shift+Up/Down to select)
- **Split panes**: each teammate in own tmux/iTerm2 pane
- Configure: `--teammate-mode` flag or `teammateMode` in settings.json
- Values: `auto` (default), `in-process`, `tmux`

### Capabilities Comparison

| Capability            | Without Teams            | With Teams                               |
| --------------------- | ------------------------ | ---------------------------------------- |
| Inter-agent messaging | Not possible             | DMs and broadcasts via SendMessage       |
| Shared task list      | Per-session only         | Shared across all teammates              |
| Task dependencies     | Single-agent             | Cross-agent blocking/unblocking          |
| Live coordination     | Wait for completion only | Message idle teammates to wake them      |
| Graceful shutdown     | Kill or wait             | Negotiated via shutdown_request/response |
| Plan review           | User only                | Lead can approve/reject teammate plans   |
| Teammate discovery    | N/A                      | Read team config to find all members     |

### Team Coordination Mechanics

- Shared task list stored in `~/.claude/teams/{team-name}/`
- Automatic task unblocking when dependencies complete
- Auto-messaging when teammates finish and go idle
- File locking for race-condition prevention on task claiming
- Teammates go idle between turns (normal behavior, not an error)

### Current Limitations

- No session resumption for in-process teammates
- One team per session
- No nested teams (teammates can't spawn teammates)
- Lead is fixed (no promotion)
- Task status can lag
- Shutdown can be slow

---

## Skills System

### Creation & Location

- **Project-level**: `.claude/skills/SKILL.md`
- **User-level**: `~/.claude/skills/SKILL.md`
- Nested directories supported with automatic discovery
- Hot-reload on changes (no restart needed)

### Frontmatter Fields

| Field                      | Purpose                                       |
| -------------------------- | --------------------------------------------- |
| `name`                     | Unique skill identifier                       |
| `description`              | When to use (auto-invocation trigger)         |
| `argument-hint`            | Hint for expected arguments                   |
| `disable-model-invocation` | Prevent Claude from auto-loading              |
| `user-invocable`           | Hide from `/` menu (default: true)            |
| `tools` / `allowed-tools`  | Restrict tool access                          |
| `disallowedTools`          | Deny specific tools                           |
| `model`                    | Override model for this skill                 |
| `context`                  | `skill` (default) or `fork` (spawns subagent) |
| `agent`                    | Agent type when using `context: fork`         |
| `permissionMode`           | Override default permissions                  |
| `hooks`                    | Skill-scoped hooks                            |
| `skills`                   | Nested skills to load                         |

### Variable Substitution

- `$ARGUMENTS` -- all arguments passed to the skill
- `$ARGUMENTS[0]`, `$ARGUMENTS[1]` -- indexed arguments
- `${CLAUDE_SESSION_ID}` -- current session ID

### Invocation

- `/skill-name` slash commands in interactive mode
- Automatic invocation when description matches
- Preloaded into subagents via `skills:` field in agent frontmatter

---

## Hooks System

### All Hook Events (15 Total)

#### Session Lifecycle

| Event              | Matcher                                      | Can Block | Purpose                         |
| ------------------ | -------------------------------------------- | --------- | ------------------------------- |
| `SessionStart`     | `startup`, `resume`, `clear`, `compact`      | No        | Inject context on session start |
| `SessionEnd`       | `clear`, `logout`, `prompt_input_exit`, etc. | No        | Cleanup and logging             |
| `UserPromptSubmit` | N/A                                          | Yes       | Block prompts or add context    |

#### Tool Execution

| Event                | Matcher                            | Can Block            | Purpose                           |
| -------------------- | ---------------------------------- | -------------------- | --------------------------------- |
| `PreToolUse`         | Tool name (Bash, Read, Edit, etc.) | Yes                  | Allow, deny, ask, or modify input |
| `PostToolUse`        | Tool name                          | No (can add context) | React to tool completion          |
| `PostToolUseFailure` | Tool name                          | No                   | Handle tool errors                |

#### Permissions

| Event               | Matcher   | Can Block | Purpose                          |
| ------------------- | --------- | --------- | -------------------------------- |
| `PermissionRequest` | Tool name | Yes       | Auto-approve or deny permissions |

#### Notifications

| Event          | Matcher                                  | Can Block | Purpose             |
| -------------- | ---------------------------------------- | --------- | ------------------- |
| `Notification` | `permission_prompt`, `idle_prompt`, etc. | No        | Read-only awareness |

#### Subagent Lifecycle

| Event           | Matcher         | Can Block | Purpose                      |
| --------------- | --------------- | --------- | ---------------------------- |
| `SubagentStart` | Agent type name | No        | Inject context into subagent |
| `SubagentStop`  | Agent type name | Yes       | Can prevent stopping         |

#### Agent Execution

| Event  | Matcher | Can Block | Purpose            |
| ------ | ------- | --------- | ------------------ |
| `Stop` | N/A     | Yes       | Force continuation |

#### Agent Teams

| Event           | Matcher | Can Block         | Purpose                    |
| --------------- | ------- | ----------------- | -------------------------- |
| `TeammateIdle`  | N/A     | Yes (exit code 2) | Block idling with feedback |
| `TaskCompleted` | N/A     | Yes (exit code 2) | Block task completion      |

#### Context Management

| Event        | Matcher          | Can Block | Purpose                        |
| ------------ | ---------------- | --------- | ------------------------------ |
| `PreCompact` | `manual`, `auto` | No        | Inject compaction instructions |

#### Setup

| Event   | Matcher | Can Block | Purpose                                 |
| ------- | ------- | --------- | --------------------------------------- |
| `Setup` | N/A     | No        | Triggered via `--init`, `--maintenance` |

### Handler Types

1. **Command** (`type: "command"`): shell commands
2. **Prompt** (`type: "prompt"`): LLM evaluation
3. **Agent** (`type: "agent"`): subagent with tools for verification

### Hook Input/Output

- **Input**: JSON via stdin
- **Output**: exit codes + optional JSON on stdout
- Exit 0: success/allow
- Exit 2: blocking error
- `"async": true` for non-blocking background execution

### Hook Configuration Locations

- `~/.claude/settings.json` (user-level)
- `.claude/settings.json` (project-level, version-controllable)
- `.claude/settings.local.json` (project-level, gitignored)
- Plugin `hooks/hooks.json`
- Skill/agent frontmatter

---

## Plan Mode

- `/plan` command or `--permission-mode plan`
- Read-only exploration, no file modifications
- Spawns Plan subagent for codebase research
- User approves plan before any changes
- `opusplan` model alias: Opus for planning, Sonnet for execution

---

## Claude Agent SDK

### Language Support

- **TypeScript**: `@anthropic-ai/claude-agent-sdk` (npm)
- **Python**: `claude-agent-sdk` (pip)

### Key Options

| Option                                | Purpose                                   |
| ------------------------------------- | ----------------------------------------- |
| `allowedTools`                        | Array of allowed tools                    |
| `disallowedTools`                     | Array of denied tools                     |
| `permissionMode`                      | Override permission mode                  |
| `agents`                              | Dictionary of custom agent definitions    |
| `hooks`                               | Programmatic hook definitions (callbacks) |
| `mcpServers`                          | MCP server configuration                  |
| `skillSources`                        | Specify skill locations                   |
| `settingSources`                      | Load from `['project', 'user', 'local']`  |
| `modelOverride`                       | Specify model                             |
| `maxTurns`                            | Turn limit                                |
| `resume` / `forkSession`              | Session management                        |
| `systemPrompt` / `appendSystemPrompt` | Prompt control                            |

### Programmatic Features

- `query()` with streaming message iteration
- `canUseTool` callback for permission decisions
- `--json-schema` for structured output validation
- `--max-budget-usd` for spending caps
- Headless mode: `-p` with `--output-format stream-json`
- Session ID capture for resume workflows

---

## Task Management System

### Tools

| Tool         | Purpose                                                     |
| ------------ | ----------------------------------------------------------- |
| `TaskCreate` | Create task with subject, description, activeForm, metadata |
| `TaskUpdate` | Set status, owner, dependencies, or delete                  |
| `TaskGet`    | Fetch full task details                                     |
| `TaskList`   | List all tasks with summary                                 |

### Task States

`pending` -> `in_progress` -> `completed` (or `deleted`)

### Dependencies

- `addBlocks`: tasks that cannot start until this one completes
- `addBlockedBy`: tasks that must complete before this one can start
- Auto-unblocking when dependencies resolve

### In Agent Teams

- Shared across all teammates
- Teammates self-claim unassigned, unblocked tasks
- Owner assignment via `TaskUpdate`
- `TaskCompleted` hook can validate before marking done

---

## Background Tasks & Async Execution

- **Ctrl+B**: background any running bash command or agent
- **`run_in_background`** on Task tool: agent runs concurrently
- **`TaskOutput`**: check on background tasks (`block: true` to wait, `block: false` to poll)
- **Async hooks**: `"async": true` for non-blocking hook execution
- **Auto-backgrounding**: long-running bash commands auto-background (configurable via `BASH_DEFAULT_TIMEOUT_MS`)
- **Completion notification**: background agents notify main thread when done

---

## MCP Servers

### Tool Naming

- Format: `mcp__<server>__<tool>`
- Hook matching: regex patterns like `mcp__.*__write.*`
- Wildcard permissions: `mcp__server__*`

### Agent-Scoped MCP

- `mcpServers` in agent frontmatter restricts server access per agent
- Background agents cannot use MCP tools

---

## Settings & Permissions

### Settings Precedence

1. CLI flags (highest)
2. `.claude/settings.local.json` (project, gitignored)
3. `.claude/settings.json` (project, version-controlled)
4. `~/.claude/settings.json` (user)
5. Managed/enterprise policies (lowest)

### Permission Rule Syntax

- `Tool` -- all uses of a tool
- `Tool(pattern)` -- specific usage (e.g., `Bash(git *)`)
- `Task(agent-name)` -- restrict subagent types
- Wildcard matching with `*` at any position
- Regex patterns supported
- `deny` always wins over `allow`

### Permission Modes

| Mode                | Behavior                                 |
| ------------------- | ---------------------------------------- |
| `default`           | Standard prompting                       |
| `acceptEdits`       | Auto-accept file edits                   |
| `plan`              | Read-only plan mode                      |
| `dontAsk`           | Auto-deny non-approved                   |
| `bypassPermissions` | Skip all checks                          |
| `delegate`          | Agent team lead mode (coordination-only) |

### Sandbox

- Filesystem and network isolation
- OS-level enforcement
- `sandbox.excludedCommands` for exceptions

---

## CLI Flags for Orchestration

### Agent & Model Control

| Flag                      | Purpose                             |
| ------------------------- | ----------------------------------- |
| `--agent NAME`            | Run session as specific agent       |
| `--agents JSON`           | Define agents inline (session-only) |
| `--model ALIAS`           | Model override (sonnet/opus/haiku)  |
| `--fallback-model`        | Automatic fallback when overloaded  |
| `--tools TOOLS`           | Restrict available tools            |
| `--disallowedTools TOOLS` | Deny specific tools                 |

### Session Control

| Flag                  | Purpose                         |
| --------------------- | ------------------------------- |
| `--continue` / `-c`   | Resume most recent session      |
| `--resume SESSION_ID` | Resume specific session         |
| `--fork-session`      | Create new session ID on resume |
| `--session-id UUID`   | Use specific session ID         |
| `--from-pr NUMBER`    | Resume from GitHub PR           |

### Execution Control

| Flag                             | Purpose                         |
| -------------------------------- | ------------------------------- |
| `-p` / `--print`                 | Headless (non-interactive) mode |
| `--output-format`                | `text`, `json`, `stream-json`   |
| `--max-turns N`                  | Turn limit                      |
| `--max-budget-usd`               | Spending cap                    |
| `--permission-mode`              | Permission strategy             |
| `--dangerously-skip-permissions` | Bypass all checks               |

### System Prompt

| Flag                          | Purpose               |
| ----------------------------- | --------------------- |
| `--system-prompt TEXT`        | Replace entire prompt |
| `--system-prompt-file PATH`   | Load from file        |
| `--append-system-prompt TEXT` | Add to default        |

### Configuration

| Flag                       | Purpose                                  |
| -------------------------- | ---------------------------------------- |
| `--mcp-config FILE`        | Load MCP servers                         |
| `--add-dir PATH`           | Additional working directories           |
| `--settings FILE`          | Load settings from file                  |
| `--setting-sources`        | Choose sources (user, project, local)    |
| `--init` / `--maintenance` | Trigger Setup hooks                      |
| `--teammate-mode`          | Team display mode (auto/in-process/tmux) |

---

## Session Management

### Persistence

- Auto-saved to `.claude/projects/{project}/{sessionId}/`
- Transcript: `{sessionId}.jsonl`
- Subagent transcripts: `subagents/agent-{agentId}.jsonl`
- 30-day cleanup default (configurable with `cleanupPeriodDays`)

### Resumption

- `--resume SESSION_ID` or `--continue`
- Named sessions: `/rename` to name, `--resume <name>` to resume
- Session picker UI via `/resume`
- Subagents resumable individually by agent ID

### Forking

- `--fork-session` on resume creates divergent branch
- New session ID, preserves prior context

### Remote Sessions

- `--remote PROMPT` -- create web session
- `--teleport` -- resume web session locally
- Auto-linking to GitHub PRs when created via `gh pr create`

---

## Memory & Context

### CLAUDE.md (Project Memory)

- Located at project root or `.claude/CLAUDE.md`
- Persistent instructions, auto-loaded every session
- Version-controllable
- Import additional files: `@path/to/file.md`

### Modular Rules

- `.claude/rules/` directory
- Path-specific rules with glob patterns
- User-level (`~/.claude/rules/`) and project-level

### Subagent Persistent Memory

- `memory: user` -- across all projects
- `memory: project` -- project-specific (version-controllable)
- `memory: local` -- project-specific (gitignored)
- First 200 lines of MEMORY.md included in agent's system prompt

### Context Re-injection

- `SessionStart` hook with `compact` matcher
- `PreCompact` hook for custom compaction instructions
- Skills preloaded via agent `skills:` field

---

## Plugins System

### Components

- Skills, agents, hooks, MCP servers, LSP servers

### Distribution

- Git repos (GitHub, GitLab, etc.)
- Marketplaces (official or custom)
- Local directories

### Management

- `/plugin install|uninstall|enable|disable|update`
- User or project scope
- Auto-update configurable per marketplace
- Manifest: `claude.manifest.json`

---

## Status Line & Monitoring

### Custom Status Line

- `statusLine` in settings.json with `type: "command"`
- JSON input includes: context window usage, session cost, model, token counts

### Available Fields

- `context_window.used_percentage`
- `context_window.remaining_percentage`
- `current_usage`
- `exceeds_200k_tokens`
- Session cost info

### Other Monitoring

- `/cost` -- track usage
- `/context` -- detailed context breakdown
- `/stats` -- session statistics
- OTEL -- OpenTelemetry logging

---

## Manager Pattern Without Teams

### What Works

**Spawning multiple agents in parallel:**
The Task tool supports multiple calls in a single message for concurrent execution.

**Background execution + checking results:**

- `run_in_background: true` launches agents concurrently
- `TaskOutput` with `block: false` polls without blocking
- `TaskOutput` with `block: true` waits for completion
- Background agents notify main thread on completion

**File-based coordination:**
Subagents share the filesystem. Establish conventions:

```
.planning/agent-reports/agent-1-findings.md
.planning/agent-reports/agent-2-progress.md
```

**Wave-based execution pattern:**

1. Manager spawns Wave 1 agents (parallel)
2. Waits for all to complete
3. Reads all results
4. Adjusts plan, spawns Wave 2 based on findings
5. Repeat

**Resuming agents:**
Pass agent ID to Task tool with `resume` for follow-up instructions.

**Task management as shared state:**
`TaskCreate`, `TaskUpdate`, `TaskList` track work items between waves.

**Hooks for automation:**

- `SubagentStop` fires on each subagent completion
- `Stop` hooks can force the manager to continue
- `PostToolUse` on Task results injects coordination logic

### What Does NOT Work

| Limitation                      | Why                                                      |
| ------------------------------- | -------------------------------------------------------- |
| No mid-execution steering       | Cannot send messages to a running subagent               |
| No real-time progress streaming | Only see final output or partial via output file         |
| No inter-agent messaging        | Only manager can relay information between agents        |
| No deep nesting                 | Subagents cannot spawn their own subagents               |
| Background agents can't use MCP | Must run foreground (blocking) if MCP needed             |
| Context isolation               | Each subagent starts fresh with only the prompt provided |

### Realistic Architecture

```
Manager (main agent or skill with context: fork)
  |
  |-- [Wave 1] Spawn parallel background agents
  |     |-- Research Agent A  -->  writes findings to file
  |     |-- Research Agent B  -->  writes findings to file
  |
  |-- Wait (TaskOutput block:true) + Read result files
  |-- Analyze, update task list, adjust plan
  |
  |-- [Wave 2] Spawn based on Wave 1 results
  |     |-- Implementation Agent C (resume or new)
  |     |-- Implementation Agent D
  |
  |-- Wait + Read + Validate
  |-- [Wave 3] Fix issues found in Wave 2
  ...
```

### Bottom Line

You get **batch orchestration** (spawn, wait, react, repeat) but not **real-time coordination** (steer agents while they run, receive progress mid-task). For live inter-agent communication, use the agent teams feature.

---

## Orchestration Patterns Summary

| Pattern                 | Mechanism                                                    |
| ----------------------- | ------------------------------------------------------------ |
| Sequential pipeline     | Main agent chains subagents via Task tool                    |
| Parallel execution      | Multiple Task calls in one message, or agent teams           |
| Hierarchical delegation | Lead agent + teammates with shared task list                 |
| Conditional gates       | PreToolUse / Stop / TaskCompleted hooks                      |
| Context preservation    | Session resume, subagent memory, CLAUDE.md                   |
| Validation loops        | Hook handlers (prompt/agent type) verify before proceeding   |
| Programmatic control    | Agent SDK with streaming, callbacks, structured output       |
| CI/CD integration       | Headless `-p` mode with JSON output and budget caps          |
| Wave coordination       | Manager spawns waves, waits, adjusts, repeats                |
| File-based IPC          | Subagents write to shared filesystem for the manager to read |
