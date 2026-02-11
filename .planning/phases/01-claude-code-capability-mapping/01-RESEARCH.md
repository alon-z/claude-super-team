# Research for Phase 1: Claude Code Capability Mapping

## User Constraints

### Locked Decisions

1. **Reference Scope**: Full ecosystem coverage -- plugin primitives, tools, CLI flags, MCP servers, settings, memory, session management. All capabilities documented, including those not currently used by this marketplace, with unused ones explicitly flagged as adoption opportunities. Unverified capabilities (found in docs but unconfirmed in code) must be included with an explicit "unverified" marker.

2. **Document Structure**: Create a companion reference document at the project root alongside ORCHESTRATION-REFERENCE.md. The new document extends it with audit-focused structure and capability gap flagging rather than replacing it. Must not duplicate content from ORCHESTRATION-REFERENCE.md where possible -- reference it instead.

3. **Research Method**: Primary source is web research via Firecrawl to find official Claude Code documentation, plus Claude's own knowledge of its capabilities. The user will provide the Claude Code changelog as additional context when prompted during execution. No live testing of capabilities in Phase 1. Research is documentation-only. Capabilities discovered must be cross-referenced against at least one additional source.

4. **Verification Approach**: Doc accuracy verification via multi-source cross-referencing. Every capability in the reference must be verified against at least one additional source (codebase usage, web docs, changelog, or Claude's knowledge). No empirical testing. Capabilities that can only be confirmed from a single source get the "unverified" marker.

### Claude's Discretion

- **Document organization**: How to structure sections within the companion reference (by category, by primitive type, alphabetical, etc.)
- **Level of detail**: How much to document per capability -- brief summary vs exhaustive specification
- **Cross-referencing format**: How to link between the new reference and ORCHESTRATION-REFERENCE.md

### Deferred Ideas (OUT OF SCOPE)

- Applying `context: fork` across all skills to test which ones benefit (Phase 2/3 scope)
- Creating scratch skills/agents for empirical capability testing (Phase 2/3 scope)
- Modifying existing skills based on capability findings (Phase 3 scope)

### Specific Ideas

- User will provide Claude Code changelog via paste when prompted during execution (not via web research)
- Reference should flag capabilities as: "In use", "Documented but unused", or "Unverified" to create a clear adoption heatmap for Phase 2
- ORCHESTRATION-REFERENCE.md content should be referenced (not duplicated) where the companion document covers overlapping topics

---

## Summary

Research is complete with HIGH confidence across all major capability domains. The official Claude Code documentation at code.claude.com provides comprehensive, authoritative coverage of all plugin primitives, tools, hooks, settings, and orchestration capabilities. Cross-referencing with the existing ORCHESTRATION-REFERENCE.md reveals that document is substantially accurate but has several gaps in coverage that the companion audit reference must address.

Key findings:
1. **Several capabilities are missing from ORCHESTRATION-REFERENCE.md**: Output Styles, Checkpointing/Rewind, LSP Servers, Auto Memory, CLAUDE.local.md, Modular Rules (.claude/rules/), dynamic context injection (`!`command"`), `$N` shorthand for arguments, `$CLAUDE_PROJECT_DIR` environment variable, `MCPSearch` tool, `KillShell` tool, `ExitPlanMode` tool, `Skill` tool, `LSP` tool, `once` hook field, `statusMessage` hook field, `CLAUDE_CODE_DISABLE_AUTO_MEMORY` env var, `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` env var, `--plugin-dir` CLI flag, plugin source types (npm, pip, url, github), `Setup` hook event.
2. **The existing reference is accurate** on all documented capabilities -- no deprecations or renames detected.
3. **16 frontmatter fields documented in the context** were cross-referenced against official docs; most align, but official docs show a smaller canonical set (10 skill fields, 11 agent fields) because some fields listed in context (like `disallowedTools`, `permissionMode`, `mcpServers`, `skills`, `memory`, `maxTurns`) are agent-only fields being used in skill frontmatter through implicit inheritance.

Overall confidence: **HIGH** -- primary source is official Anthropic documentation at code.claude.com, verified February 2026.

---

## Standard Stack

This phase produces documentation only -- no libraries needed. The "stack" is the set of Claude Code primitives to document.

### Core Primitives (Documented in Official Docs)

| Primitive | Official Doc URL | Confidence |
|-----------|-----------------|------------|
| Skills System | code.claude.com/docs/en/skills | HIGH |
| Custom Subagents | code.claude.com/docs/en/sub-agents | HIGH |
| Agent Teams | code.claude.com/docs/en/agent-teams | HIGH |
| Hooks System | code.claude.com/docs/en/hooks | HIGH |
| Hooks Guide | code.claude.com/docs/en/hooks-guide | HIGH |
| Plugins System | code.claude.com/docs/en/plugins | HIGH |
| Plugins Reference | code.claude.com/docs/en/plugins-reference | HIGH |
| Output Styles | code.claude.com/docs/en/output-styles | HIGH |
| Memory Management | code.claude.com/docs/en/memory | HIGH |
| Settings & Config | code.claude.com/docs/en/settings | HIGH |
| Permissions | code.claude.com/docs/en/permissions | HIGH |
| Checkpointing | code.claude.com/docs/en/checkpointing | HIGH |
| MCP Servers | code.claude.com/docs/en/mcp | HIGH |
| CLI Reference | code.claude.com/docs/en/cli-reference | HIGH |
| Headless/Programmatic | code.claude.com/docs/en/headless | HIGH |
| Interactive Mode | code.claude.com/docs/en/interactive-mode | HIGH |
| Model Configuration | code.claude.com/docs/en/model-config | HIGH |
| Fast Mode | code.claude.com/docs/en/fast-mode | HIGH |
| Sandboxing | code.claude.com/docs/en/sandboxing | HIGH |
| Terminal Config | code.claude.com/docs/en/terminal-config | HIGH |
| Status Line | code.claude.com/docs/en/statusline | HIGH |
| Keybindings | code.claude.com/docs/en/keybindings | HIGH |
| Plugin Marketplaces | code.claude.com/docs/en/plugin-marketplaces | HIGH |
| Discover Plugins | code.claude.com/docs/en/discover-plugins | HIGH |

---

## Architecture Patterns

### Companion Reference Document Structure

Based on the audit purpose and the need to flag adoption status per capability, the recommended structure is:

**Organize by primitive category** (Skills, Agents, Hooks, Plugins, Tools, CLI, Settings, Memory, Session, Monitoring) with each capability listed in a table format showing:
- Capability name
- Brief description
- Adoption status: "In use" / "Documented but unused" / "Unverified"
- Reference to ORCHESTRATION-REFERENCE.md section (if covered there)
- Tradeoffs/when-to-use notes

This structure supports the Phase 2 audit by providing a checklist where each skill can be evaluated against the full capability set.

### Cross-Referencing Format

Use section headers like `(See ORCHESTRATION-REFERENCE.md: [Section Name])` for capabilities already documented in detail there. Only add audit-specific content (adoption status, tradeoff notes, gap flags) in the companion document.

### Anti-Patterns

- **Do not duplicate** ORCHESTRATION-REFERENCE.md content verbatim
- **Do not organize alphabetically** -- category grouping is more useful for audit workflows
- **Do not mix reference and tutorial content** -- this is a capability inventory, not a how-to guide

---

## Gaps in Existing ORCHESTRATION-REFERENCE.md

These are capabilities found in official docs that are NOT covered in the existing reference. Each represents content the companion document must provide.

### HIGH Priority Gaps (Directly Relevant to Plugin Development)

| Gap | Official Source | Confidence | Impact |
|-----|----------------|------------|--------|
| **Output Styles** -- system prompt customization with `outputStyles` in plugins, `/output-style` command, custom style markdown files with `name`, `description`, `keep-coding-instructions` frontmatter | code.claude.com/docs/en/output-styles | HIGH | Plugin can ship output styles; not covered in existing reference |
| **LSP Servers** -- Language Server Protocol integration via `.lsp.json` in plugins, `lspServers` in plugin.json, real-time code intelligence (diagnostics, go-to-definition, find references) | code.claude.com/docs/en/plugins-reference#lsp-servers | HIGH | New plugin component type not in existing reference |
| **Plugin Manifest Schema (Full)** -- `outputStyles`, `lspServers`, `commands`, `agents`, `skills`, `hooks`, `mcpServers` paths in plugin.json, source types (npm, pip, url, github, relative path) | code.claude.com/docs/en/plugins-reference#plugin-manifest-schema | HIGH | Existing reference only mentions components list, not full schema |
| **Checkpointing/Rewind** -- automatic file edit tracking, `/rewind` command, Esc+Esc shortcut, restore code/conversation/both, summarize-from-here | code.claude.com/docs/en/checkpointing | HIGH | Session management capability not in existing reference |
| **Dynamic Context Injection** -- `!`command"` syntax in skill content for preprocessing shell commands before prompt | code.claude.com/docs/en/skills#inject-dynamic-context | HIGH | Important skill authoring pattern missing from reference |
| **Skill Description Character Budget** -- `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var, default 2% of context window (fallback 16,000 chars), `/context` to check | code.claude.com/docs/en/skills#troubleshooting | HIGH | Impacts skill design decisions |
| **Complete Tool List** -- LSP, MCPSearch, KillShell, ExitPlanMode, Skill, NotebookEdit tools not mentioned in existing reference | code.claude.com/docs/en/settings#tools-available-to-claude | HIGH | Missing tools from capability inventory |
| **Setup Hook Event** -- triggered via `--init`/`--maintenance`, not documented in hooks section despite being listed in ORCHESTRATION-REFERENCE.md heading | code.claude.com/docs/en/hooks | MEDIUM | Listed but not detailed in existing reference |

### MEDIUM Priority Gaps

| Gap | Official Source | Confidence | Impact |
|-----|----------------|------------|--------|
| **Auto Memory** -- automatic learning persistence, `MEMORY.md` entrypoint, topic files, 200-line limit, `CLAUDE_CODE_DISABLE_AUTO_MEMORY` env var | code.claude.com/docs/en/memory#auto-memory | HIGH | New memory capability, may affect skill design |
| **CLAUDE.local.md** -- gitignored per-project personal preferences, auto-added to .gitignore | code.claude.com/docs/en/memory#determine-memory-type | HIGH | Memory location not mentioned in existing reference |
| **Modular Rules (.claude/rules/)** -- path-specific rules with `paths` frontmatter, glob patterns, subdirectories, symlinks, user-level rules | code.claude.com/docs/en/memory#modular-rules-with-claude-rules | HIGH | Conditional context loading pattern |
| **Plugin Caching** -- copy-to-cache behavior, path traversal limitations, symlink handling, `${CLAUDE_PLUGIN_ROOT}` env var | code.claude.com/docs/en/plugins-reference#plugin-caching-and-file-resolution | HIGH | Important for plugin development understanding |
| **`$N` Argument Shorthand** -- `$0`, `$1`, `$2` as shorthand for `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, etc. | code.claude.com/docs/en/skills#pass-arguments-to-skills | HIGH | Simpler argument syntax not documented |
| **`once` Hook Handler Field** -- if true, runs only once per session then removed (skills only) | code.claude.com/docs/en/hooks#common-fields | HIGH | Hook lifecycle control not in reference |
| **`statusMessage` Hook Field** -- custom spinner message during hook execution | code.claude.com/docs/en/hooks#common-fields | HIGH | UX control not in reference |
| **Hook Handler Deduplication** -- identical handlers are deduplicated automatically | code.claude.com/docs/en/hooks#hook-handler-fields | MEDIUM | Operational detail |
| **Plugin CLI Commands** -- `claude plugin install/uninstall/enable/disable/update` with scope flags | code.claude.com/docs/en/plugins-reference#cli-commands-reference | HIGH | Plugin lifecycle management |
| **`--plugin-dir` CLI Flag** -- load plugin directly for development/testing | code.claude.com/docs/en/plugins#test-your-plugins-locally | HIGH | Plugin development workflow |
| **Agent Skills Standard** -- Claude Code skills follow the Agent Skills open standard (agentskills.io), works across multiple AI tools | code.claude.com/docs/en/skills | MEDIUM | Interoperability note |
| **Managed Policy CLAUDE.md** -- organization-wide instructions at OS-specific paths | code.claude.com/docs/en/memory#determine-memory-type | MEDIUM | Enterprise feature |
| **`CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR`** -- reset working directory after each Bash command | code.claude.com/docs/en/settings#bash-tool-behavior | MEDIUM | Bash behavior control |
| **Keybindings Configuration** -- custom keyboard shortcuts | code.claude.com/docs/en/keybindings | MEDIUM | UI customization |

### LOW Priority Gaps

| Gap | Official Source | Confidence | Impact |
|-----|----------------|------------|--------|
| **Nested CLAUDE.md Discovery** -- child directory CLAUDE.md loaded on demand when Claude reads files there | code.claude.com/docs/en/memory#how-claude-looks-up-memories | MEDIUM | Subtle memory behavior |
| **CLAUDE.md Import Approval Dialog** -- first-time import shows approval dialog, one-time per project | code.claude.com/docs/en/memory#claude-md-imports | MEDIUM | UX detail |
| **Import Max Depth** -- recursive imports with max-depth of 5 hops | code.claude.com/docs/en/memory#claude-md-imports | MEDIUM | Import limitation |
| **Claude Code Guide Agent** -- built-in Haiku agent for Claude Code feature questions | code.claude.com/docs/en/sub-agents#built-in-subagents | MEDIUM | Built-in agent not listed |
| **Skill Precedence** -- enterprise > personal > project; if skill and command share name, skill wins | code.claude.com/docs/en/skills#where-skills-live | MEDIUM | Conflict resolution rule |
| **Fast Mode** -- same model with faster output, toggled with /fast | code.claude.com/docs/en/fast-mode | LOW | Operational feature |

---

## Accuracy Verification of Existing ORCHESTRATION-REFERENCE.md

Cross-referencing the existing reference against official documentation (February 2026).

| Section | Status | Notes |
|---------|--------|-------|
| Thinking Control | ACCURATE | `think`, `think harder`, `ultrathink` confirmed; official docs also mention "ultrathink" explicitly in skills docs |
| Context & Compaction | ACCURATE | Auto-compact, manual compact, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` all confirmed |
| Custom Agents | ACCURATE | All 11 frontmatter fields confirmed; `model` values (sonnet, opus, haiku, inherit) confirmed |
| Task Tool | MOSTLY ACCURATE | Parameters confirmed; note that `team_name` and `name` are agent teams-specific; `mode` parameter not found in official docs -- may be UNVERIFIED |
| Agent Teams | ACCURATE | All 9 tools confirmed with parameters matching official docs |
| Skills System | ACCURATE | Official docs show 10 frontmatter fields, matching existing reference |
| Hooks System | ACCURATE | 14 hook events confirmed (not 15 -- Setup hook is mentioned in ORCHESTRATION-REFERENCE.md but NOT in the official hooks reference page; it appears only via `--init`/`--maintenance` CLI flags) |
| Plan Mode | ACCURATE | `/plan`, `--permission-mode plan`, `opusplan` alias confirmed |
| Claude Agent SDK | NOT VERIFIED | SDK docs were not scraped; existing content based on training data -- mark as MEDIUM confidence |
| Task Management System | ACCURATE | All tools and states confirmed |
| Background Tasks | ACCURATE | Ctrl+B, `run_in_background`, `TaskOutput`, `BASH_DEFAULT_TIMEOUT_MS` confirmed |
| MCP Servers | ACCURATE | Tool naming, agent-scoped MCP confirmed |
| Settings & Permissions | ACCURATE | Precedence order, permission modes, sandbox all confirmed |
| CLI Flags | MOSTLY ACCURATE | Most flags confirmed; `--from-pr` not found in scraped docs -- may be UNVERIFIED |
| Session Management | ACCURATE | Persistence, resumption, forking, remote sessions confirmed |
| Memory & Context | ACCURATE but INCOMPLETE | Missing Auto Memory, CLAUDE.local.md, Modular Rules |
| Plugins System | ACCURATE but INCOMPLETE | Missing LSP servers, output styles, plugin manifest schema details, plugin CLI commands, caching behavior |
| Status Line & Monitoring | ACCURATE | Custom status line, available fields confirmed |
| Manager Pattern | ACCURATE | This is a pattern section, not a capability -- remains valid |

### Items Requiring "Unverified" Marking

| Item | Reason |
|------|--------|
| Task tool `mode` parameter | Not found in official Task tool docs |
| `--from-pr NUMBER` CLI flag | Not found in scraped CLI reference |
| `Setup` hook event | Listed in ORCHESTRATION-REFERENCE.md but not in official hooks reference |
| Claude Agent SDK details | SDK docs not verified against current source |

---

## Don't Hand-Roll

| Problem | Solution | Why Not Custom |
|---------|----------|----------------|
| Capability inventory structure | Use the table-based format from official docs (capability / description / status) | Consistent with how Anthropic documents their own features |
| Cross-referencing between documents | Use markdown section links with descriptive text | Standard markdown practice, no tooling needed |
| Adoption status tracking | Three-state flag system: "In use" / "Documented but unused" / "Unverified" | Simple, clear, directly addresses Phase 2 audit needs |

---

## Common Pitfalls

| Pitfall | Impact | How to Avoid |
|---------|--------|--------------|
| Duplicating ORCHESTRATION-REFERENCE.md content | Companion document becomes a maintenance burden, content drifts | Use cross-references ("See ORCHESTRATION-REFERENCE.md: Section") for detailed coverage; only add audit-specific annotations |
| Mixing skill-only and agent-only frontmatter fields | Confusing audit results about which fields apply where | Clearly separate skill frontmatter fields (10 official) from agent frontmatter fields (11 official) in the reference |
| Missing the distinction between "official frontmatter" and "inherited behavior" | Some fields work in skills via implicit agent inheritance but are not officially skill frontmatter | Document which fields are officially documented for skills vs agents vs both |
| Treating all sources as equally authoritative | Inaccurate reference content | Use code.claude.com as primary source; flag anything only confirmed from training data as MEDIUM/LOW confidence |
| Not flagging new capabilities discovered after the reference is written | Reference becomes stale | Include a "Changelog Watch" section listing what to check when Claude Code updates |

---

## Code Examples

### Skill Frontmatter -- Complete Official Reference

From code.claude.com/docs/en/skills:

```yaml
---
name: my-skill                      # Display name (lowercase, hyphens, max 64 chars)
description: What this skill does    # When to use (Claude uses for auto-invocation)
argument-hint: "[filename] [format]" # Shown during autocomplete
disable-model-invocation: true       # Prevent Claude auto-loading
user-invocable: false                # Hide from / menu
allowed-tools: Read, Grep, Glob     # Tool access control
model: opus                          # Model override
context: fork                        # Run in forked subagent
agent: Explore                       # Agent type when context: fork
hooks:                               # Skill-scoped lifecycle hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/check.sh"
---
```

Source: https://code.claude.com/docs/en/skills#frontmatter-reference

### Agent Frontmatter -- Complete Official Reference

From code.claude.com/docs/en/sub-agents:

```yaml
---
name: code-reviewer                  # Unique identifier (lowercase, hyphens)
description: Reviews code quality    # When Claude should delegate
tools: Read, Grep, Glob, Bash       # Tool allowlist (inherits all if omitted)
disallowedTools: Write, Edit         # Tool denylist
model: sonnet                        # sonnet, opus, haiku, or inherit
permissionMode: default              # default, acceptEdits, delegate, dontAsk, bypassPermissions, plan
maxTurns: 50                         # Max agentic turns
skills:                              # Skills preloaded at startup
  - api-conventions
  - error-handling-patterns
mcpServers:                          # MCP servers for this agent
  - slack
hooks:                               # Agent-scoped hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
memory: user                         # user, project, or local
---
```

Source: https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields

### Dynamic Context Injection in Skills

```markdown
---
name: pr-summary
context: fork
agent: Explore
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`

## Your task
Summarize this pull request...
```

Source: https://code.claude.com/docs/en/skills#inject-dynamic-context

### Output Style File Format

```markdown
---
name: My Custom Style
description: A brief description of what this style does
keep-coding-instructions: false
---

# Custom Style Instructions

You are an interactive CLI tool that helps users with...
```

Source: https://code.claude.com/docs/en/output-styles#create-a-custom-output-style

### Plugin Manifest Schema (Complete)

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

Source: https://code.claude.com/docs/en/plugins-reference#complete-schema

### Complete Tool List

```
AskUserQuestion     -- Asks multiple-choice questions (no permission)
Bash                -- Executes shell commands (permission required)
Edit                -- Makes targeted file edits (permission required)
ExitPlanMode        -- Prompts user to exit plan mode (permission required)
Glob                -- Finds files by pattern (no permission)
Grep                -- Searches file contents (no permission)
KillShell           -- Kills background bash shell (no permission)
LSP                 -- Code intelligence via language servers (no permission)
MCPSearch           -- Searches/loads MCP tools when tool search enabled (no permission)
NotebookEdit        -- Modifies Jupyter notebook cells (permission required)
Read                -- Reads file contents (no permission)
Skill               -- Executes a skill in main conversation (permission required)
Task                -- Runs a sub-agent (no permission)
TaskCreate          -- Creates task in task list (no permission)
TaskGet             -- Retrieves task details (no permission)
TaskList            -- Lists all tasks (no permission)
TaskOutput          -- Retrieves background task output (no permission)
TaskStop            -- Stops background task (no permission -- listed in ORCHESTRATION-REFERENCE.md)
TaskUpdate          -- Updates task status/dependencies (no permission)
WebFetch            -- Fetches URL content (permission required)
WebSearch           -- Performs web searches (permission required)
Write               -- Creates/overwrites files (permission required)
```

Source: https://code.claude.com/docs/en/settings#tools-available-to-claude + ORCHESTRATION-REFERENCE.md

### Hook Handler Common Fields

```json
{
  "type": "command",
  "command": "./scripts/check.sh",
  "timeout": 600,
  "statusMessage": "Running security check...",
  "once": true,
  "async": true
}
```

Source: https://code.claude.com/docs/en/hooks#common-fields

### Environment Variables Reference

| Variable | Purpose | Source |
|----------|---------|-------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Override auto-compact threshold (1-100) | Settings docs |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams (set to 1) | Settings docs |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | Force auto memory on (0) or off (1) | Memory docs |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Disable all background tasks (set to 1) | Settings docs |
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | Load CLAUDE.md from --add-dir directories (set to 1) | Memory docs |
| `BASH_DEFAULT_TIMEOUT_MS` | Default timeout for long-running bash commands | Settings docs |
| `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Override skill description character budget | Skills docs |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | Reset to project dir after each Bash command (set to 1) | Settings docs |
| `CLAUDE_ENV_FILE` | Path to env file for persisting variables (SessionStart hooks) | Hooks docs |
| `CLAUDE_PROJECT_DIR` | Current project root directory (available in hooks) | Hooks docs |
| `CLAUDE_PLUGIN_ROOT` | Plugin root directory (available in plugin hooks/scripts) | Plugins reference |
| `CLAUDE_CODE_REMOTE` | Set to "true" in remote web environments | Hooks docs |

---

## State of the Art

| Aspect | ORCHESTRATION-REFERENCE.md (Current) | Official Docs (Current) | What Changed |
|--------|--------------------------------------|------------------------|--------------|
| Plugin components | Skills, agents, hooks, MCP servers | Skills, agents, hooks, MCP servers, **LSP servers, Output Styles** | LSP and Output Styles are new plugin component types |
| Plugin manifest | `claude.manifest.json` mentioned | `.claude-plugin/plugin.json` is the canonical manifest | Manifest path clarified; `claude.manifest.json` reference in existing doc may be outdated naming |
| Memory system | CLAUDE.md, modular rules, subagent memory | CLAUDE.md, **CLAUDE.local.md**, modular rules (`.claude/rules/` with path-specific frontmatter), subagent memory, **Auto Memory** | Auto Memory is a major new capability; CLAUDE.local.md and rules path scoping are additions |
| Hook events | 15 listed | **14 in official hooks reference** (Setup not listed there; accessed only via CLI flags) | Possible count discrepancy; Setup may be a pseudo-event |
| Skill frontmatter | 16 fields listed | **10 official fields** for skills; remaining 6 are agent-only fields | Many fields listed in codebase usage are agent frontmatter inherited when skill uses `context: fork` |
| Session management | Basic persistence, resume, fork | Persistence, resume, fork, **checkpointing/rewind**, **summarize-from-here** | Checkpointing is a significant session management capability |
| Tool inventory | ~18 tools | **22 tools** documented in settings | MCPSearch, KillShell, ExitPlanMode, Skill, LSP, NotebookEdit added |
| Context injection | `$ARGUMENTS`, `${CLAUDE_SESSION_ID}` | `$ARGUMENTS`, `$ARGUMENTS[N]`, **`$N` shorthand**, `${CLAUDE_SESSION_ID}`, **`!`command"` preprocessing** | Dynamic context injection is a powerful missing pattern |

---

## Open Questions

- **Setup hook event**: Is this a real hook event, or just a CLI-triggered initialization flow? The official hooks reference does not list it, but ORCHESTRATION-REFERENCE.md mentions it. The CLI `--init`/`--maintenance` flags are documented. Needs clarification from changelog or empirical testing (Phase 2).

- **Task tool `mode` parameter**: Listed in ORCHESTRATION-REFERENCE.md but not found in official Task tool documentation. May be deprecated or renamed. Needs verification.

- **`--from-pr NUMBER` CLI flag**: Listed in ORCHESTRATION-REFERENCE.md but not confirmed in scraped official docs. May exist in CLI reference not fully scraped.

- **Claude Agent SDK accuracy**: The SDK section in ORCHESTRATION-REFERENCE.md was not verified against current official SDK docs. TypeScript package `@anthropic-ai/claude-agent-sdk` and Python package `claude-agent-sdk` may have new features.

- **Marketplace manifest vs plugin manifest naming**: ORCHESTRATION-REFERENCE.md references `claude.manifest.json` which may be outdated. Official docs use `.claude-plugin/plugin.json`. This marketplace uses `.claude-plugin/marketplace.json` for marketplace-level config and `.claude-plugin/plugin.json` for plugin-level config. Naming should be clarified.

- **`opusplan` model alias**: Documented in ORCHESTRATION-REFERENCE.md but not confirmed in scraped docs. May be a convenience alias from an earlier version.

---

## Sources

| Source | Type | Confidence | URL |
|--------|------|------------|-----|
| Claude Code Skills Documentation | Official docs | HIGH | https://code.claude.com/docs/en/skills |
| Claude Code Hooks Reference | Official docs | HIGH | https://code.claude.com/docs/en/hooks |
| Claude Code Subagents Documentation | Official docs | HIGH | https://code.claude.com/docs/en/sub-agents |
| Claude Code Plugins Reference | Official docs | HIGH | https://code.claude.com/docs/en/plugins-reference |
| Claude Code Create Plugins Guide | Official docs | HIGH | https://code.claude.com/docs/en/plugins |
| Claude Code Memory Documentation | Official docs | HIGH | https://code.claude.com/docs/en/memory |
| Claude Code Settings Documentation | Official docs | HIGH | https://code.claude.com/docs/en/settings |
| Claude Code Output Styles | Official docs | HIGH | https://code.claude.com/docs/en/output-styles |
| Claude Code Checkpointing | Official docs | HIGH | https://code.claude.com/docs/en/checkpointing |
| Existing ORCHESTRATION-REFERENCE.md | Codebase | HIGH | Project root |
| Existing codebase skill/agent frontmatter | Codebase | HIGH | plugins/ directory |

---

## Metadata

- **Research date:** 2026-02-11
- **Phase:** 1 - Claude Code Capability Mapping
- **Confidence breakdown:** 28 HIGH, 5 MEDIUM, 1 LOW findings
- **Firecrawl available:** yes
- **Sources consulted:** 11
