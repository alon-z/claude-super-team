# Coding Conventions

**Analysis Date:** 2026-02-11

## Naming Patterns

**Files:**
- Markdown documentation uses UPPERCASE.md (e.g., `SKILL.md`, `PROJECT.md`, `ROADMAP.md`, `CLAUDE.md`)
- Template/asset files use lowercase-with-hyphens.md (e.g., `project.md`, `roadmap.md`, `context-template.md`)
- Reference documentation uses lowercase-with-hyphens.md (e.g., `planner-guide.md`, `workflow-guide.md`, `mapper-instructions.md`)
- Agent definitions use lowercase-with-hyphens.md (e.g., `phase-researcher.md`)
- Directories use lowercase with hyphens (e.g., `claude-super-team`, `map-codebase`, `marketplace-utils`)
- Phase directories use zero-padded numbering: `{NN}-{name}` (e.g., `01-foundation`, `02-auth`)
- Decimal phase numbering for inserted phases: `{NN}.{N}` (e.g., `02.1-security-hardening`)

**Functions:**
- Not applicable (no code functions - this is a documentation/configuration project)

**Variables:**
- Bash variables use UPPERCASE_WITH_UNDERSCORES (e.g., `$ARGUMENTS`, `$PHASE_NUM`, `$EXEC_MODE`)
- SKILL.md files use `$ARGUMENTS` for user-provided arguments
- Placeholder variables in templates use `{placeholder}` format (e.g., `{phase_number}`, `{phase_name}`)

**Types:**
- Not applicable (no type definitions - this is a documentation/configuration project)

## Code Style

**Formatting:**
- No automated formatting tool detected
- Markdown documents use consistent formatting
- YAML frontmatter uses `key: value` format without quotes unless necessary
- Bash scripts use 2-space indentation for readability

**Linting:**
- No linter configuration detected

## Import Organization

**Order:**
- Not applicable (no imports - this is a documentation/configuration project)

**Path Aliases:**
- File path references use absolute paths with backticks: `path/to/file.md`
- `.planning/` is the root directory for all generated artifacts
- Skills reference assets via `assets/` subdirectory
- Skills reference guides via `references/` subdirectory

## Error Handling

**Patterns:**
- Bash validation checks at start of skills using `[ ! -f file ] && echo "ERROR: ..." && exit 1` pattern
- Early validation before user interaction (e.g., check for required files before proceeding)
- Clear error messages with actionable guidance (e.g., "Run /create-roadmap first")
- Graceful degradation when optional context is missing (e.g., CONTEXT.md, RESEARCH.md)

## Logging

**Framework:** Not applicable (no runtime logging)

**Patterns:**
- Skills provide progress updates via text output
- Orchestrators collect confirmations from agents
- Completion messages include file paths and line counts
- Clear separation between informational output and actionable next steps

## Comments

**When to Comment:**
- Markdown documents use HTML comments for explanatory notes: `<!-- Comment -->`
- YAML frontmatter documents allowed tools and configuration
- Inline documentation explains workflows, philosophy, and decision-making
- Template placeholders include context about what to fill in
- Skills include extensive process documentation with numbered phases

**JSDoc/TSDoc:**
- Not applicable (no code - this is a documentation/configuration project)

## Function Design

**Size:**
- Not applicable (no functions - this is a documentation/configuration project)
- Skills are structured into numbered phases/steps for clarity
- Each phase has a clear objective and success criteria
- Phases typically range from 5-50 lines of instruction

**Parameters:**
- Skills accept `$ARGUMENTS` as user input
- Arguments are parsed for flags (e.g., `--gaps-only`, `--skip-verify`, `--all`, `--team`)
- Phase numbers are normalized to zero-padded format: `printf "%02d" $PHASE_NUM`
- Decimal phase numbers handled with special parsing: `01.2` format

**Return Values:**
- Skills output completion messages with file paths created
- Agents return structured confirmations to orchestrators
- Verification steps check for specific observable outcomes

## Module Design

**Exports:**
- Not applicable (no modules - this is a documentation/configuration project)

**Barrel Files:**
- Not applicable

## Documentation Structure

**Skills (SKILL.md files):**
- YAML frontmatter (`---` block) with `name`, `description`, `argument-hint`, `allowed-tools`, optional `model`, `context`, `disable-model-invocation`
- `## Objective` section explaining what the skill does
- `## Process` section with numbered phases/steps
- `## Success Criteria` checklist at the end
- Reference to template files via `assets/` and guidance via `references/`

**Templates (assets/):**
- Markdown templates with placeholder format: `[Placeholder text]` or `{variable}`
- Section headers clearly delineated with `##` and `###`
- Inline comments using HTML comments or markdown comments
- Footer metadata sections (dates, last updated, etc.)

**Reference Guides (references/):**
- Comprehensive guides for agent prompts (e.g., `planner-guide.md`, `mapper-instructions.md`)
- Troubleshooting documentation with problem/solution format
- Workflow patterns with code examples

**Agents (agents/):**
- YAML frontmatter with `name`, `description`, `tools`, `model`, optional `skills`
- Extensive embedded instructions including role, philosophy, process, success criteria
- Self-contained context (no `@` file references across Task boundaries)

## File Organization

**Plugin Structure:**
```
plugins/{plugin-name}/
  .claude-plugin/plugin.json          -- metadata, version
  agents/{agent-name}.md               -- custom subagent definitions (optional)
  skills/{skill-name}/
    SKILL.md                           -- skill definition and process
    assets/{template}.md               -- templates embedded in prompts
    references/{guide}.md              -- guidance embedded in agent prompts
  README.md                            -- plugin documentation
```

**Generated Artifacts Structure:**
```
.planning/
  PROJECT.md                           -- project vision and requirements
  ROADMAP.md                           -- phased delivery plan
  STATE.md                             -- current phase, decisions, blockers
  IDEAS.md                             -- brainstorming output (optional)
  SECURITY-AUDIT.md                    -- security findings (optional)
  codebase/                            -- codebase analysis (7 documents)
    STACK.md
    INTEGRATIONS.md
    ARCHITECTURE.md
    STRUCTURE.md
    CONVENTIONS.md
    TESTING.md
    CONCERNS.md
  phases/{NN}-{name}/                  -- phase-specific artifacts
    {NN}-CONTEXT.md                    -- user decisions
    {NN}-RESEARCH.md                   -- ecosystem research
    {NN}-{plan}-PLAN.md                -- execution plans
    {NN}-{plan}-SUMMARY.md             -- execution summaries
    {NN}-VERIFICATION.md               -- phase verification results
```

---

*Convention analysis: 2026-02-11*
