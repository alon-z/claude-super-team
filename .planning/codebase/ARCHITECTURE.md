# Architecture

**Analysis Date:** 2026-02-11

## Pattern Overview

**Overall:** Plugin-based skill marketplace with multi-agent orchestration

**Key Characteristics:**
- Declarative skill definitions via SKILL.md files with YAML frontmatter
- Template-driven artifact generation (assets/*.md templates consumed by skills)
- Agent orchestration through Task API and custom agent definitions
- Sequential pipeline workflow with file-based state management (`.planning/` directory)

## Layers

**Marketplace Registry:**
- Purpose: Central registry for plugin discovery and installation
- Location: `.claude-plugin/marketplace.json`
- Contains: Plugin metadata, versioning, source mappings
- Depends on: Plugin manifests at `plugins/*/. claude-plugin/plugin.json`
- Used by: Claude Code CLI for plugin installation and discovery

**Plugin Layer:**
- Purpose: Modular skill distribution units
- Location: `plugins/{plugin-name}/`
- Contains: Skills (slash commands), custom agents, metadata
- Depends on: Claude Code plugin API
- Used by: Claude Code runtime to register and execute skills

**Skill Definitions:**
- Purpose: Individual slash command implementations
- Location: `plugins/{plugin-name}/skills/{skill-name}/SKILL.md`
- Contains: YAML frontmatter (config), markdown body (instructions)
- Depends on: Assets (templates), references (guides), allowed-tools list
- Used by: Claude Code to execute user commands

**Agent Definitions:**
- Purpose: Reusable subagent configurations for spawning via Task tool
- Location: `plugins/{plugin-name}/agents/{agent-name}.md`
- Contains: YAML frontmatter (tools, model, skills), markdown body (instructions)
- Depends on: Task tool, optional skill access
- Used by: Orchestrator skills to spawn specialized agents

**Asset Templates:**
- Purpose: Structured document templates for artifact generation
- Location: `plugins/{plugin-name}/skills/{skill-name}/assets/{template-name}.md`
- Contains: Markdown templates with placeholder variables
- Depends on: Nothing (leaf nodes)
- Used by: Skills to generate user-facing documents in `.planning/`

**Reference Guides:**
- Purpose: Instructions embedded into agent prompts
- Location: `plugins/{plugin-name}/skills/{skill-name}/references/{guide-name}.md`
- Contains: Markdown instructions for subagents
- Depends on: Nothing (leaf nodes)
- Used by: Skills to inline context into Task spawns

**Output Artifacts:**
- Purpose: Planning documents and project state
- Location: `.planning/` directory in user projects
- Contains: PROJECT.md, ROADMAP.md, STATE.md, phases/*, codebase/*
- Depends on: Skill execution
- Used by: Sequential skills reading prior outputs, user review

## Data Flow

**Sequential Skill Pipeline (claude-super-team):**

1. `/new-project` → Writes `.planning/PROJECT.md` (project definition)
2. `/map-codebase` (optional) → Spawns 4 mapper agents in parallel → Each writes to `.planning/codebase/{DOC}.md`
3. `/create-roadmap` → Reads PROJECT.md → Writes `.planning/ROADMAP.md` + `.planning/STATE.md`
4. `/brainstorm` (optional) → Interactive or autonomous mode → Updates `.planning/IDEAS.md` → Can update ROADMAP.md
5. For each phase:
   - `/discuss-phase N` → Writes `.planning/phases/{NN}-{name}/{NN}-CONTEXT.md` (user decisions)
   - `/research-phase N` → Spawns researcher agent (reads CONTEXT.md) → Writes `{NN}-RESEARCH.md`
   - `/plan-phase N` → Spawns planner agent (reads CONTEXT.md + RESEARCH.md) → Writes `{NN}-{plan}-PLAN.md` files
   - `/execute-phase N` → Reads all PLAN.md files → Spawns executor agents per task → Writes `{NN}-{plan}-SUMMARY.md` + `{NN}-{plan}-VERIFICATION.md`
6. `/progress` → Reads STATE.md + ROADMAP.md → Routes to next step

**Parallel Mapper Pattern (map-codebase):**

1. Orchestrator spawns 4 mapper agents via Task tool (tech, arch, quality, concerns)
2. Each mapper explores codebase independently using Glob/Grep/Read
3. Each mapper writes directly to `.planning/codebase/{DOC}.md` (no context return)
4. Orchestrator receives only confirmations, merges into summary

**Wave Execution Pattern (execute-phase):**

1. Read all `*-PLAN.md` files for phase
2. Group plans by `wave` frontmatter field
3. For each wave:
   - Spawn agent per plan (in parallel within wave)
   - Each agent executes tasks, writes SUMMARY.md
   - Wait for wave completion
   - Run code-simplifier skill on modified files
   - Spawn verifier agent (reads SUMMARY files, runs checks)
4. Proceed to next wave

**State Management:**
- `.planning/STATE.md` tracks current phase number, decisions, blockers
- `.planning/ROADMAP.md` tracks phase completion checkboxes
- Skills read state → perform work → update state → next skill reads updated state

## Key Abstractions

**Skill:**
- Purpose: Executable slash command
- Examples: `plugins/claude-super-team/skills/new-project/SKILL.md`, `plugins/marketplace-utils/skills/marketplace-manager/SKILL.md`
- Pattern: YAML frontmatter + markdown instructions, consumed by Claude Code runtime

**Agent:**
- Purpose: Reusable subagent configuration for Task spawning
- Examples: `plugins/claude-super-team/agents/phase-researcher.md`
- Pattern: YAML frontmatter (tools, model, skills) + markdown role definition

**Plan:**
- Purpose: Executable task list for phase implementation
- Examples: `.planning/phases/01-foundation/01-01-PLAN.md`
- Pattern: YAML frontmatter (metadata) + XML-like `<task>` blocks with `<files>`, `<action>`, `<verify>`, `<done>`

**Template:**
- Purpose: Structured output format
- Examples: `plugins/claude-super-team/skills/create-roadmap/assets/roadmap.md`
- Pattern: Markdown with placeholder variables replaced by skills

**Phase:**
- Purpose: Delivery milestone with discrete success criteria
- Examples: Phase 1 (foundation), Phase 2 (auth), inserted phases like 4.1 (gap closure)
- Pattern: Directory `.planning/phases/{NN}-{name}/` containing CONTEXT, RESEARCH, PLAN, SUMMARY, VERIFICATION files

## Entry Points

**Marketplace Root:**
- Location: `.claude-plugin/marketplace.json`
- Triggers: Claude Code CLI installation commands
- Responsibilities: Plugin discovery, version resolution, source mapping

**Plugin Manifest:**
- Location: `plugins/{name}/.claude-plugin/plugin.json`
- Triggers: Marketplace registration, plugin installation
- Responsibilities: Metadata declaration, skill registration

**Skill Definition:**
- Location: `plugins/{name}/skills/{skill-name}/SKILL.md`
- Triggers: User typing `/{skill-name}` in Claude Code
- Responsibilities: Parse frontmatter, execute markdown body as prompt

**Agent Definition:**
- Location: `plugins/{name}/agents/{agent-name}.md`
- Triggers: Task tool invocation by orchestrator skills
- Responsibilities: Spawn subagent with tools/model/skills, execute role instructions

## Error Handling

**Strategy:** Fail-fast validation with clear error messages

**Patterns:**
- Bash guards at skill start: `[ ! -f .planning/PROJECT.md ] && echo "ERROR: ..." && exit 1`
- Frontmatter validation: Skills verify required files exist before proceeding
- User prompts via AskUserQuestion: Skills request missing arguments rather than guessing
- Git safety: Skills never auto-commit (except `/new-project` on new repo init)
- No destructive git operations: No force push, reset --hard, etc. without user confirmation

## Cross-Cutting Concerns

**Logging:** Not applicable (CLI tools don't log; users see stdout)

**Validation:**
- YAML frontmatter parsing by Claude Code runtime
- Bash existence checks (`[ -f file ]`) before file operations
- JSON schema validation for marketplace.json (implied by `/marketplace-manager`)

**Authentication:** Not applicable (local CLI tool, no auth required)

**Versioning:**
- Plugin versions in `plugin.json` files
- Marketplace syncs versions from `plugin.json` to `marketplace.json`
- Git tags for release versioning (not enforced by code)

**Tool Access Control:**
- `allowed-tools` whitelist in SKILL.md frontmatter
- Skills restricted to declared tools only
- Custom agents inherit tool restrictions from spawning skill

**Model Selection:**
- `model: opus` in frontmatter for planner/researcher skills
- Default sonnet for checkers/verifiers
- Execution agents configurable via project preferences

**Context Behavior:**
- `context: fork` in frontmatter isolates skill from conversation history
- `disable-model-invocation: true` for pure orchestrators (no LLM calls at top level)
- Templates loaded via `@` syntax in skill bodies (e.g., `@.planning/PROJECT.md`)

---

*Architecture analysis: 2026-02-11*
