---
phase: 01
plan: 01
completed: 2026-02-11
key_files:
  created:
    - CAPABILITY-REFERENCE.md
  modified: []
decisions:
  - "Cross-reference format: table column 'ORCH-REF Section' with section name or 'Not covered'"
  - "Expanded notes below tables for capabilities not in ORCHESTRATION-REFERENCE.md"
  - "Skill-only vs agent-only frontmatter fields separated into distinct sections"
deviations:
  - "Firecrawl skill not available in execution agent; used WebFetch for doc page research instead"
---

# Phase 01 Plan 01: Capability Reference Document Summary

Complete Claude Code ecosystem capability inventory (CAPABILITY-REFERENCE.md) created as the audit standard for Phase 2, documenting all capabilities with adoption status flags and cross-references to ORCHESTRATION-REFERENCE.md.

## Tasks Completed

| # | Task | Commit | Files | Status |
|---|------|--------|-------|--------|
| 1 | Collect Claude Code changelog from user | N/A (checkpoint) | N/A | complete |
| 2 | Research gaps and determine adoption status | N/A (research) | N/A | complete |
| 3 | Assemble and write CAPABILITY-REFERENCE.md | 9dc7b45 | CAPABILITY-REFERENCE.md | complete |

## What Was Built

**CAPABILITY-REFERENCE.md** (597 lines) at project root -- a structured capability inventory organized into 12 sections:

1. Skills (frontmatter fields, features, invocation)
2. Agents (frontmatter fields, built-in types, invocation)
3. Hooks (15 events, handler types, handler fields, input/output, config locations)
4. Plugins (components, manifest schema, distribution, management)
5. Tools (25 tools with permission requirements)
6. CLI Flags (agent/model, session, execution, system prompt, config)
7. Settings & Permissions (precedence, permission modes, sandbox)
8. Memory & Context (CLAUDE.md locations, auto memory, modular rules, compaction)
9. Session Management (persistence, resumption, checkpointing/rewind, remote)
10. Monitoring & UI (status line, built-in commands, OTEL, keybindings)
11. Agent Teams (team tools, coordination, display modes)
12. Environment Variables (40+ vars with purpose and status)

**Capability counts by adoption status:**
- In use: ~58 capabilities actively leveraged
- Documented but unused: ~200+ capabilities identified as Phase 2 adoption opportunities
- Unverified: 2 items (Task tool `mode` parameter, Claude Agent SDK details)

**Key findings -- most impactful unused capabilities:**
- Hooks system (15 events, 0 in use) -- largest untapped area
- Output Styles -- custom system prompts via plugin distribution
- Dynamic context injection (`!`command``) -- shell preprocessing in skills
- Checkpointing/Rewind -- session state management
- LSP Servers -- code intelligence via plugins
- `.claude/rules/` modular rules -- path-specific context loading
- Auto Memory for agents -- persistent learning across sessions
- `$N` argument shorthand -- simpler argument access in skills

**Changelog discoveries not in original research:**
- 8 additional hook events confirmed (TeammateIdle, TaskCompleted, PermissionRequest, SubagentStart, PreCompact, Notification, UserPromptSubmit, SessionStart/SessionEnd)
- Hook input modification (updatedInput, additionalContext) capabilities
- Prompt-based stop hooks with model parameter
- Previously unverified items confirmed: --from-pr (v2.1.27), Setup hook (v2.1.10), opusplan (v1.0.77)

## Deviations From Plan

Firecrawl skill was specified for web research but was not preloaded in the execution agent. WebFetch was used instead, successfully fetching all 8 official doc pages.

## Decisions Made

- Cross-referencing format: ORCH-REF Section column in every table, with expanded notes below tables for uncovered capabilities
- Skill-only and agent-only frontmatter fields documented in separate sections for audit clarity
- Output Styles included despite deprecation/un-deprecation history -- documented current status

## Issues / Blockers

None. Clean execution.
