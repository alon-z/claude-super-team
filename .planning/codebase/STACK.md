# Technology Stack

**Analysis Date:** 2026-02-11

## Languages

**Primary:**
- Markdown - Skill definitions, documentation, templates, and agent definitions throughout repository

**Secondary:**
- JSON - Plugin manifests, marketplace configuration, state tracking
- YAML - Frontmatter in SKILL.md files for metadata and tool restrictions

## Runtime

**Environment:**
- Claude Code CLI - Skills run within Claude Code environment
- No traditional runtime dependencies (not a code project - this is a plugin marketplace)

**Package Manager:**
- Not applicable - This repository contains Claude Code plugins distributed via JSON manifests
- Lockfile: Not applicable

## Frameworks

**Core:**
- Claude Code Plugin System - Marketplace distributes three plugins via `.claude-plugin/marketplace.json` and per-plugin `plugin.json` manifests

**Testing:**
- Not detected - No automated test framework (skills are validated through Claude Code execution)

**Build/Dev:**
- Not applicable - Skills are markdown files executed directly by Claude Code

## Key Dependencies

**Critical:**
- Claude Code SDK - All skills depend on Claude Code's tool system (Task, AskUserQuestion, Read, Write, Bash, Glob, Grep, Edit, WebSearch, WebFetch, Skill, etc.)
- Task tool - Used for subagent orchestration across all planning/execution skills (`plugins/claude-super-team/skills/plan-phase/SKILL.md`, `plugins/claude-super-team/skills/execute-phase/SKILL.md`, `plugins/claude-super-team/skills/research-phase/SKILL.md`, etc.)

**Infrastructure:**
- YAML frontmatter parser - Skills declare `allowed-tools`, `model`, `description`, and `argument-hint` in frontmatter
- JSON manifests - `.claude-plugin/marketplace.json` registers plugins; each plugin has `.claude-plugin/plugin.json` with metadata

## Configuration

**Environment:**
- No environment variables required for the marketplace itself
- Skills that integrate with external services (Linear, GitHub, Firecrawl) rely on external CLI tools or skills being configured separately
- All configuration is declarative via JSON manifests and YAML frontmatter

**Build:**
- No build process - Skills are interpreted at runtime

## Platform Requirements

**Development:**
- Claude Code CLI installed and configured
- Git for version control
- Text editor for editing markdown/JSON files

**Production:**
- Claude Code CLI with marketplace feature enabled
- Plugin installation via marketplace.json or direct plugin source paths
- No deployment infrastructure (plugins execute locally in user's Claude Code environment)

---

*Stack analysis: 2026-02-11*
