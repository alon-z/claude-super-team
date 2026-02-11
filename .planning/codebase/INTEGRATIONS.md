# External Integrations

**Analysis Date:** 2026-02-11

## APIs & External Services

**Web Research:**
- Firecrawl - Web scraping and documentation crawling
  - SDK/Client: External skill (`firecrawl`)
  - Auth: Configured externally via Firecrawl skill setup
  - Used by: `plugins/claude-super-team/agents/phase-researcher.md` (preloaded in agent definition)
  - Purpose: Research phase ecosystem and library investigation

**Web Search:**
- WebSearch tool - Built-in Claude Code tool for web search
  - Integration: Native Claude Code tool
  - Auth: Handled by Claude Code
  - Used by: `plugins/marketplace-utils/skills/skill-creator/SKILL.md`, researcher agents

**Web Fetch:**
- WebFetch tool - Built-in Claude Code tool for fetching web content
  - Integration: Native Claude Code tool
  - Auth: Handled by Claude Code
  - Used by: `plugins/marketplace-utils/skills/skill-creator/SKILL.md`, researcher agents

## Data Storage

**Databases:**
- Local filesystem only
  - Connection: Direct file I/O via Read/Write tools
  - Client: Claude Code file system tools (Read, Write, Edit, Glob, Grep)

**File Storage:**
- Local filesystem - All state stored in `.planning/` directory structure
  - `plugins/claude-super-team/` stores 13 skills with assets, references, and custom agents
  - `plugins/marketplace-utils/` stores 2 skills for marketplace management
  - `plugins/task-management/` stores 2 skills for Linear/GitHub integration

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- Not applicable - Skills execute in user's authenticated Claude Code session
  - Implementation: All authentication delegated to external tools (gh CLI, Linear CLI)

**External Service Auth:**
- GitHub - Via `gh` CLI (requires `gh auth login`)
  - Used by: `plugins/task-management/skills/github-issue-manager/SKILL.md`
  - Operations: Issue creation, editing, listing, labeling via restricted `gh` commands
- Linear - Via `linear-cli` skill (requires external skill with Linear API authentication)
  - Used by: `plugins/task-management/skills/linear-sync/SKILL.md`
  - Operations: Initiative, project, milestone, document, and issue synchronization

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Claude Code conversation history serves as execution log
- Skills output structured markdown reports for user visibility

## CI/CD & Deployment

**Hosting:**
- Git repository - Distributed as clonable repository or via marketplace.json source paths

**CI Pipeline:**
- None

**Distribution:**
- Marketplace manifest (`.claude-plugin/marketplace.json`) references plugins via relative paths
- Plugins can be sourced from local paths, GitHub repos, or generic git URLs
- Version management via `plugin.json` version field per plugin

## Environment Configuration

**Required env vars:**
- None for marketplace functionality
- External integrations (GitHub, Linear, Firecrawl) require their respective CLI tools/skills to be configured with authentication separately

**Secrets location:**
- Not managed by this repository - All secrets handled by external tools (gh CLI keychain, Linear CLI config, Firecrawl skill config)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Tool Integration Patterns

**Claude Code Tool Restrictions:**
Skills use `allowed-tools` YAML frontmatter to restrict tool access following least-privilege principle:

- `plugins/claude-super-team/skills/map-codebase/SKILL.md` - Read, Bash, Glob, Grep, Write, Task
- `plugins/claude-super-team/skills/research-phase/SKILL.md` - Read, Write, Bash, Glob, Grep, Task, AskUserQuestion
- `plugins/claude-super-team/skills/execute-phase/SKILL.md` - Read, Bash, Write, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskGet, TaskList, TaskOutput, TaskStop, TeamCreate, TeamDelete, SendMessage
- `plugins/task-management/skills/github-issue-manager/SKILL.md` - Read, Grep, Glob, restricted `gh` commands only
- `plugins/task-management/skills/linear-sync/SKILL.md` - Read, Write, Edit, Bash(shasum *), Glob, Grep, AskUserQuestion

**Subagent Orchestration:**
Skills spawn subagents via Task tool with different agent types:
- `subagent_type: "general-purpose"` - Most planning/execution tasks
- `subagent_type: "Explore"` - Codebase exploration in discuss-phase
- `subagent_type: "phase-researcher"` - Custom agent in `plugins/claude-super-team/agents/phase-researcher.md`
- `subagent_type: "code-simplifier:code-simplifier"` - External skill for code simplification
- `subagent_type: "everything-claude-code:architect"` - External architecture review agent

**Model Routing:**
Skills specify model preferences in YAML frontmatter or Task calls:
- `model: "opus"` - Used for planning, research, and complex reasoning (`plugins/claude-super-team/skills/map-codebase/SKILL.md`)
- `model: "sonnet"` - Used for verification, checking, and execution tasks
- `model: "haiku"` - Used for lightweight status and help commands (`plugins/claude-super-team/skills/cst-help/SKILL.md`)

---

*Integration audit: 2026-02-11*
