# Phase Researcher Agent Memory

## Claude Code Hooks System (verified Feb 2026)

Key facts verified against official docs at code.claude.com/docs/en/hooks:

- **14 hook events** (not 15): SessionStart, SessionEnd, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, Notification, SubagentStart, SubagentStop, Stop, TeammateIdle, TaskCompleted, PreCompact
- **Setup hook** is triggered via --init/--maintenance CLI flags, not listed in hooks reference page
- **CLAUDE_ENV_FILE** is ONLY available in SessionStart hooks -- not other hook types
- **async: true** available only for `type: "command"` hooks (not prompt/agent)
- **once: true** available only for skill-scoped hooks (not agent-scoped)
- Token usage/cost data is NOT available through any hook event's JSON input
- Hook stdout on exit 0: for SessionStart/UserPromptSubmit it's added to Claude's context; for others it's shown only in verbose mode
- Skill-scoped hooks merge with settings-based hooks; multiple matcher groups for same event are additive
- Existing codebase has hooks only in execute-phase SKILL.md (PreCompact, SessionStart for compaction resilience)

## Research Patterns

- Always scrape code.claude.com/docs/en/{topic} for official docs -- they are comprehensive
- CAPABILITY-REFERENCE.md at project root has a thorough capability inventory from Phase 1
- Phase 1 research (01-RESEARCH.md) documents gaps and accuracy of existing references
- progress-gather.sh in scripts/ is the established pattern for shell scripts in this project

## Storage Format Decision

JSONL recommended over CSV/SQLite for shell-script telemetry:
- Appendable with `echo >> file`
- No dependencies needed
- Each line independent (corruption-resistant)
- Queryable with jq, grep, Claude Code Read/Grep tools
