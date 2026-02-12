# Phase 2: Skill Audit & Reclassification

**Date:** 2026-02-12
**Auditor:** Claude (with user classification decisions)
**Reference:** CAPABILITY-REFERENCE.md (2026-02-11)
**Total items:** 17 skills + 1 agent across 3 plugins

## Classification Criteria

| Classification | When to Use |
|---------------|-------------|
| Remain as Skill | Runs in main context, orchestrates agents, interactive flow, works well |
| Convert to Agent | Self-contained, needs tool restrictions, benefits from context isolation, no user interaction |
| Hybrid (Skill + Agent) | Has both interactive AND autonomous phases |
| Needs Feature Additions | Missing frontmatter, could leverage unused capabilities, incorrect config |

## Frontmatter Checklist (6 Dimensions)

1. **Tool Restrictions** (allowed-tools): Present? Minimal? Bash-specific patterns?
2. **Model Selection** (model): Appropriate? Consistent with similar skills?
3. **Context Mode** (context): Fork needed? Fork harmful?
4. **Invocation Control** (disable-model-invocation, user-invocable): Auto-invoke appropriate?
5. **Description Quality** (description): Clear? Concise? Differentiating?
6. **Argument Handling** (argument-hint): Present? Accurate?

---

## Audit Results

### Skill: new-project (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | new-project |
| description | "Initialize a new project to produce .planning/PROJECT.md..." |
| allowed-tools | Read, Bash, Write, AskUserQuestion, Glob, Grep |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `<brief project idea OR path to project document>` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill that guides users through project initialization via multi-round AskUserQuestion dialog, supporting both greenfield (brief idea) and brownfield (existing code) paths. Creates `.planning/PROJECT.md`.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` -- skill uses `git init`, `git add/commit`, `find`, `mkdir -p`, `test -f`. Could restrict to specific patterns. |
| model selection | OK | Inherits default. Appropriate for interactive conversation-heavy skill. |
| context mode | OK | Default `skill` context. Needs AskUserQuestion + conversation history. Fork would break it. |
| disable-model-invocation | GAP | Not set (false). Project initialization should be deliberate -- auto-invocation could confuse. |
| description quality | OK | Clear, concise, explains when to use it. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted to specific patterns (`Bash(git *)`, `Bash(mkdir *)`, `Bash(find *)`, `Bash(test *)`)
- Missing `disable-model-invocation: true` -- project initialization is a deliberate action

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (interactive, AskUserQuestion-heavy, main context needed). Has 2 frontmatter gaps: blanket Bash and missing disable-model-invocation.

**User Decision:** Needs Feature Additions + Remain as Skill

---

### Skill: create-roadmap (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | create-roadmap |
| description | Long (creates/modifies roadmap, explains all 5 modes) |
| allowed-tools | Read, Bash, Write, AskUserQuestion, Glob, Grep |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | false (explicitly set -- redundant, false is default) |
| argument-hint | `[modification description]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill that transforms project context into a phased delivery roadmap with goal-backward success criteria. Supports 5 modes: create new, add phase, insert urgent phase, reorder, replace entirely. Heavy AskUserQuestion usage for approval.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` -- only uses `test -f`, file existence checks. Could restrict. |
| model selection | OK | Inherits default. Interactive, conversation-heavy. Appropriate. |
| context mode | OK | Default `skill`. Needs AskUserQuestion + conversation history. |
| disable-model-invocation | GAP | Explicitly set to `false` (redundant since false is default). Keep as auto-invocable but remove redundant explicit setting. |
| description quality | GAP | Very verbose -- explains all 5 operational modes. Extract mode specifics to supporting files to reduce description length. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted to specific patterns
- Description too verbose -- extract operational mode details to supporting MD files that skill loads as needed
- Redundant `disable-model-invocation: false` should be removed (false is default)

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (interactive, modifies state files, AskUserQuestion-heavy). Has gaps: blanket Bash, verbose description, redundant frontmatter field.

**User Decision:** Needs Feature Additions + Remain as Skill (keep auto-invocation enabled, extract operational modes to supporting files, fix blanket Bash)

---

### Skill: discuss-phase (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | discuss-phase |
| description | "Gather implementation decisions through adaptive questioning..." |
| allowed-tools | Read, Write, Bash, Glob, Grep, AskUserQuestion, Task |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `<phase number>` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive orchestrator that identifies implementation gray areas through codebase exploration (spawns Explore agent via Task) and multi-round AskUserQuestion dialog, producing CONTEXT.md with locked decisions for downstream planning.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` -- uses `test -f`, `ls -d`, `grep`, `mkdir -p`. Could restrict. Task included correctly for Explore agent. |
| model selection | OK | Inherits default. Interactive, conversation-heavy. Appropriate. |
| context mode | OK | Default `skill`. Needs AskUserQuestion + conversation history. |
| disable-model-invocation | OK | Not set (false). Auto-invocation reasonable -- "discuss phase 3 before planning" is natural trigger. |
| description quality | OK | Clear, concise, explains pipeline position. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted to specific patterns
- Otherwise well-configured -- correct Task usage for Explore agent, good description, proper pipeline positioning

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (hybrid orchestrator + interactive questioning). Only gap is blanket Bash.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash)

---

### Skill: research-phase (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | research-phase |
| description | "Research how to implement a phase before planning..." |
| allowed-tools | Read, Write, Bash, Glob, Grep, Task, AskUserQuestion |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `<phase number>` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Lean orchestrator that spawns a custom `phase-researcher` agent (opus, with Firecrawl preloaded) to investigate ecosystem/libraries/patterns. The agent definition contains the methodology; this skill handles validation, context loading, and result presentation.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` -- uses `test -f`, `ls -d`, `grep`. Could restrict. |
| model selection | OK | Inherits. Correct for lean orchestrator -- heavy work in agent (opus). |
| context mode | OK | Default `skill`. Needs AskUserQuestion for blocked/conflict handling. |
| disable-model-invocation | OK | Not set (false). Auto-invocation reasonable. |
| description quality | OK | Clear, explains pipeline position and agent delegation. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Clean orchestrator pattern -- well-designed separation between skill (context) and agent (methodology)

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (lean orchestrator delegating to custom agent). Only gap is blanket Bash.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash)

---

### Skill: plan-phase (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | plan-phase |
| description | "Create execution plans (PLAN.md files) for a roadmap phase..." |
| allowed-tools | Read, Bash, Write, Glob, Grep, Task, AskUserQuestion |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[phase number \| --all] [--gaps] [--skip-verify]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Complex orchestrator that spawns planner (opus) and checker (sonnet) agents to create and verify PLAN.md files. Supports single-phase, `--all` batch, and `--gaps` closure modes with a planner-checker revision loop (max 3 iterations).

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` -- uses `test -f`, `ls -d`, `grep`, `cat`. Could restrict. |
| model selection | OK | Inherits. Lean orchestrator -- planner gets opus, checker gets sonnet. |
| context mode | OK | Default `skill`. Needs AskUserQuestion for user decisions. |
| disable-model-invocation | OK | Not set (false). Auto-invocation reasonable -- "plan phase 3" is natural. |
| description quality | OK | Clear, explains modes and pipeline position. |
| argument-hint | OK | Present, comprehensive, accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Otherwise well-designed -- correct model routing (opus planner, sonnet checker), good argument handling

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (complex orchestrator with multiple agent delegation). Only gap is blanket Bash.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash)

---

### Skill: execute-phase (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | execute-phase |
| description | "Execute planned phase by routing tasks to specialized agents..." |
| allowed-tools | Read, Bash, Write, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskGet, TaskList, TaskOutput, TaskStop, TeamCreate, TeamDelete, SendMessage |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[phase number] [--gaps-only] [--skip-verify] [--team]` |
| user-invocable | not set (default: true) |
| hooks | PreCompact + SessionStart (compaction resilience for EXEC-PROGRESS.md) |

**Behavior Summary:** Most complex skill in the marketplace. Orchestrates wave-based parallel execution by spawning agents per task/plan, routing to specialized agent types based on content analysis. Supports agent teams mode (`--team`), code simplification, and phase verification. Uses skill-scoped hooks for context compaction resilience.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` in a skill with 16 tools declared. Uses git, mkdir, ls, grep, test. Could restrict. Wide tool set justified by teams + task management. |
| model selection | OK | Inherits. Correct -- lean orchestrator delegates to agents with explicit model routing. |
| context mode | OK | Default `skill`. Needs AskUserQuestion, Task orchestration, and conversational state. |
| disable-model-invocation | OK | Not set (false). User decision: keep auto-invocable. |
| description quality | OK | Clear, explains routing and execution modes. |
| argument-hint | OK | Present, comprehensive. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Notable positive: Only skill using hooks (PreCompact + SessionStart for compaction resilience)
- Wide tool list (16 tools) justified by teams mode + task management
- Overall well-designed despite complexity

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (heavy orchestrator with complex agent routing). Only gap is blanket Bash. Hooks usage is exemplary.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash, keep auto-invocable)

---

### Skill: progress (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | progress |
| description | "Check project progress and route to next action..." |
| allowed-tools | Read, Bash, Grep, Glob |
| model | haiku |
| context | fork |
| disable-model-invocation | not set (default: false) |
| argument-hint | not set |
| user-invocable | not set (default: true) |

**Behavior Summary:** Read-only status skill that runs in forked haiku context. Analyzes `.planning/` files to produce a progress bar, phase status table, sync issue detection, and smart routing to the next action.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` -- uses `test -d`, `ls -d`, `find`, `grep` extensively. No Write (correct for read-only). No AskUserQuestion (correct for fork context). |
| model selection | OK | haiku. Appropriate for read-only status analysis. |
| context mode | OK | `context: fork`. Correct -- produces verbose output, doesn't need conversation history. |
| disable-model-invocation | OK | Not set (false). Auto-invocation desirable -- "what's next?" should trigger this. |
| description quality | OK | Clear, lists multiple natural trigger phrases. |
| argument-hint | OK | Not set. Correct -- takes no arguments. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Could benefit from dynamic context injection (`!`command``) for injecting current git status
- Well-configured as a model pattern for read-only forked skills

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (read-only status, forked context, haiku). Only gap is blanket Bash.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash)

---

### Skill: quick-plan (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | quick-plan |
| description | "Quickly plan an ad-hoc feature or fix as a lightweight phase..." |
| allowed-tools | Read, Bash, Write, Edit, Glob, Grep, Task, AskUserQuestion |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[task description]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill that inserts a lightweight phase into the roadmap using decimal numbering, includes a mini-discussion (2-3 gray areas), and spawns an opus planner for a 1-3 task plan. Uses Edit tool (unique among skills) for ROADMAP.md annotation.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash`. Edit is justified for ROADMAP.md annotation (unique among skills). |
| model selection | OK | Inherits. Interactive orchestrator with agent delegation. |
| context mode | OK | Default `skill`. Needs AskUserQuestion + conversation history. |
| disable-model-invocation | OK | Not set (false). Auto-invocation useful. |
| description quality | OK | Clear, differentiates from full phase ceremony. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Edit tool usage is justified and unique -- good practice for targeted ROADMAP.md modification

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (interactive orchestrator with agent delegation + Edit tool for ROADMAP.md). Only gap is blanket Bash.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash)

---

### Skill: phase-feedback (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | phase-feedback |
| description | "Collect user feedback on a just-executed phase..." |
| allowed-tools | Read, Bash, Write, Edit, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskList |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[phase number] [feedback description]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill with two paths: quick fix (direct code changes, no subphase) and standard feedback (creates decimal-numbered subphase, spawns researcher if needed, spawns opus planner). Uses Edit for code modifications on quick fix path.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash`. TaskCreate/TaskUpdate/TaskList appear unnecessary -- skill creates plans, not task list items. Not used in process steps. |
| model selection | OK | Inherits. Interactive orchestrator. |
| context mode | OK | Default `skill`. Needs conversation history + AskUserQuestion. |
| disable-model-invocation | OK | Not set (false). Auto-invocation useful -- "I want to change X" is natural. |
| description quality | OK | Clear, explains both paths, differentiates from quick-plan. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- TaskCreate/TaskUpdate/TaskList may be unnecessary -- not used in any process step. Should be removed to follow principle of least privilege.

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (interactive with two paths, agent delegation). Gaps: blanket Bash, possibly unnecessary Task* tools.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash, remove unnecessary TaskCreate/TaskUpdate/TaskList)

---

### Skill: brainstorm (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | brainstorm |
| description | "Brainstorm features, improvements, and architectural changes..." |
| allowed-tools | Read, Write, Bash, Glob, Grep, AskUserQuestion, Task, Skill |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[optional topic or focus area]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill with two modes -- Interactive (collaborative AskUserQuestion dialog with iterative idea exploration) and Autonomous (spawns 3 parallel agents: Explore codebase, opus Creative Strategist, architect reviewer). Uses Skill tool to invoke /create-roadmap for approved ideas. Creates/updates IDEAS.md and auto-generates CONTEXT.md for new phases.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` (uses `test -f`, `ls`, `cat`). Skill tool justified for /create-roadmap. Task justified for 3 parallel agents. |
| model selection | OK | Inherits. Interactive orchestrator, heavy work delegated to agents with explicit model choices in skill body. |
| context mode | OK | Default `skill`. Needs AskUserQuestion + conversation history for both modes. |
| disable-model-invocation | CONCERN | Not set (false). "brainstorm" is a very common word -- Claude might auto-trigger eagerly on casual mentions like "let me brainstorm ideas". |
| description quality | GAP | Should harden trigger conditions to reduce false-positive auto-invocation. Make "when to use" more specific. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Description should be hardened to reduce false-positive auto-invocation (the word "brainstorm" appears in casual conversation)
- Skill tool usage is well-designed -- clean delegation to /create-roadmap
- Agent routing in autonomous mode (Explore, opus, architect) is good practice

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (dual-mode interactive/autonomous, AskUserQuestion-heavy, Skill tool delegation). Gaps: blanket Bash, description needs hardening for invocation precision.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash, harden description to reduce false-positive auto-invocation, keep auto-invocable)

---

### Skill: add-security-findings (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | add-security-findings |
| description | "Store security audit findings in .planning/SECURITY-AUDIT.md..." |
| allowed-tools | Read, Bash, Write, Edit, AskUserQuestion, Glob, Grep, Skill |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | true |
| argument-hint | not set |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill that collects security findings (paste or file), writes SECURITY-AUDIT.md with severity-based grouping, and integrates remediation into roadmap via /create-roadmap delegation. Priority logic: critical = urgent inserted phases, high = grouped with critical or separate, medium = regular phase, low = backlog.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` (uses `test -f` only). Edit justified for ROADMAP.md backlog section. Skill justified for /create-roadmap. |
| model selection | CHANGE | Inherits default. User wants lighter model (haiku could work for organizing/writing findings). |
| context mode | CHANGE | Default `skill`. User wants `context: fork` for cleaner context management, especially when auto-invoked. |
| disable-model-invocation | CHANGE | Currently `true`. User wants to enable auto-invocation so it can chain after security research/scanning skills. |
| description quality | OK | Clear, explains priority-based integration. |
| argument-hint | OK | Not set. Skill takes no arguments (always starts with AskUserQuestion). |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Remove `disable-model-invocation: true` to enable auto-invocation after security scans
- Explore dual-mode design (autonomous for model-triggered, interactive for user-invoked) to support auto-invocation cleanly
- Consider `context: fork` + haiku for the autonomous path
- Current heavy AskUserQuestion flow (4-5 interactions) conflicts with auto-invocation -- needs autonomous path that auto-classifies and asks for final approval only

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (interactive, Skill tool delegation to /create-roadmap). Significant redesign opportunity: enable auto-invocation with dual-mode (autonomous/interactive), add context: fork + lighter model for leaner auto-triggered flow.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash, remove disable-model-invocation, explore dual-mode autonomous/interactive + context:fork + lighter model for auto-triggered use)

---

### Skill: cst-help (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | cst-help |
| description | "Interactive help system for Claude Super Team workflow..." |
| allowed-tools | Read, Bash, Grep, Glob, AskUserQuestion |
| model | haiku |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | not set |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive help system that classifies user request (general workflow, project-specific, troubleshoot, skill reference), analyzes .planning/ state when needed, reads references/workflow-guide.md, and provides targeted guidance with specific commands to run.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` (uses `test -d`, `test -f`, `ls -d`, `grep`, `find`). |
| model selection | OK | haiku. Appropriate for help routing and state analysis. |
| context mode | OK | Default `skill` is correct. Unlike progress (fork + no AskUserQuestion), cst-help uses AskUserQuestion extensively. RESEARCH.md suggested adding `context: fork` -- this was incorrect; fork would break interactive help flow. |
| disable-model-invocation | OK | Not set (false). Auto-invocation desirable -- "help", "I'm stuck" should trigger. |
| description quality | OK | Clear, lists multiple trigger phrases. |
| argument-hint | GAP | Missing. Accepts `[question]` as argument. Should have `argument-hint: "[question]"`. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted
- Missing `argument-hint: "[question]"` for direct questions
- Context mode difference from progress is justified -- different interaction patterns (interactive vs read-only) require different configs
- Cross-skill observation: both progress and cst-help use haiku, but progress forks (read-only) while cst-help doesn't (interactive). This is consistent design, not a bug.

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (interactive help, AskUserQuestion-heavy, haiku). Gaps: blanket Bash, missing argument-hint.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash, add argument-hint: "[question]")

---

### Skill: map-codebase (claude-super-team)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | map-codebase |
| description | Detailed (7 docs, modes, incremental updates) |
| allowed-tools | Read, Bash, Glob, Grep, Write, Task |
| model | opus |
| context | fork |
| disable-model-invocation | true |
| argument-hint | `[optional: topic to update e.g. 'db and auth', or 'refresh' to remap from scratch]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Autonomous fork+opus skill that spawns 4 parallel sonnet mapper agents to analyze existing codebase. Produces 7 structured documents in .planning/codebase/. Supports full-map and incremental-update modes. Agents write directly to files; orchestrator collects confirmations. Includes secret scanning.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | Blanket `Bash` (uses `ls`, `rm -rf`, `mkdir -p`, `wc -l`, `grep`). No AskUserQuestion correct for fork. |
| model selection | CONCERN | `opus` for lean orchestrator, but agents use sonnet. Orchestrator logic is straightforward (mode detection, spawning, verification). Could downgrade. |
| context mode | OK | `context: fork` correct. Autonomous, no user interaction, verbose output. |
| disable-model-invocation | OK | `true`. Codebase mapping should be deliberate. |
| description quality | OK | Detailed, excellent argument-hint with examples. |
| argument-hint | OK | Comprehensive with examples. |

**Capability Gap Analysis:**
- Blanket Bash should be restricted (note: includes `rm -rf` for refresh mode -- needs careful restriction)
- Opus may be over-specified for a lean orchestrator -- agents do the heavy lifting in sonnet
- Secret scanning step is excellent security practice (unique among skills)
- Well-designed agent delegation: orchestrator is lean, agents write directly

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Well-configured skill (fork + disable-model-invocation, good agent pattern). Gaps: blanket Bash, over-specified orchestrator model.

**User Decision:** Needs Feature Additions + Remain as Skill (fix blanket Bash, downgrade orchestrator model to sonnet/haiku)

---

### Skill: marketplace-manager (marketplace-utils)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | marketplace-manager |
| model | haiku |
| description | "Manage and fix Claude Code plugin marketplaces..." |
| allowed-tools | **NOT SET** |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | not set |
| user-invocable | not set (default: true) |

**Behavior Summary:** Reference-based skill for marketplace manifest operations -- registering, removing, auditing, syncing plugins. Detailed procedural documentation for JSON manifest manipulation and marketplace.json maintenance.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | **CRITICAL GAP** | **No `allowed-tools` at all.** Unrestricted access to ALL tools. Needs Read, Write, Edit, Bash (specific patterns), Glob, Grep at minimum. |
| model selection | OK | haiku (user chose to keep). |
| context mode | OK | Default `skill`. Interactive marketplace operations. |
| disable-model-invocation | OK | Not set (false). Auto-invocation reasonable. |
| description quality | OK | Clear, lists all operations. |
| argument-hint | GAP | Missing. Supports subcommands (audit, register, remove, sync, configure). |

**Capability Gap Analysis:**
- **Missing `allowed-tools` is the biggest gap in the entire audit** -- unrestricted tool access violates principle of least privilege
- Missing argument-hint for subcommand routing
- Cross-plugin convention gap: marketplace-utils much less rigorous than claude-super-team

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Correctly a skill (reference-based marketplace operations). Critical gaps: missing allowed-tools, missing argument-hint.

**User Decision:** Needs Feature Additions + Remain as Skill (add allowed-tools with specific Bash patterns, add argument-hint, keep haiku model)

---

### Skill: skill-creator (marketplace-utils)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | skill-creator |
| description | "Guide for creating effective skills..." |
| allowed-tools | AskUserQuestion, Edit, Glob, Grep, Read, WebFetch, WebSearch, Write, Bash(uv run *) |
| model | sonnet |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[skill-description]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Interactive skill that guides users through creating new skills. Uses `Bash(uv run *)` for init scripts and validation. References docs.md and multiple reference files for design patterns.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | EXCELLENT | `Bash(uv run *)` is the **best practice example** in the entire audit. Specific, minimal, justified. |
| model selection | OK | sonnet. Appropriate for creative skill generation. |
| context mode | OK | Default `skill`. Interactive refinement. |
| disable-model-invocation | OK | Not set (false). Specific trigger. |
| description quality | OK | Clear. |
| argument-hint | OK | Present and accurate. |

**Capability Gap Analysis:**
- **Gold standard for Bash restrictions** -- `Bash(uv run *)` is how other skills should restrict Bash
- WebFetch and WebSearch may not be actively used but retained for flexibility
- Overall excellent configuration -- reference example for other skills

**Classification Recommendation:** Good as-is
**Rationale:** Best-configured skill for tool restrictions. sonnet appropriate. No significant gaps.

**User Decision:** Good as-is (no changes needed, best practice reference)

---

### Skill: linear-sync (task-management)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | linear-sync |
| description | "Sync .planning/ artifacts to Linear..." |
| allowed-tools | Read, Write, Edit, Bash(shasum *), Glob, Grep, AskUserQuestion |
| model | not set (inherits) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | `[init | projects | milestones | docs | issues [phase] | status]` |
| user-invocable | not set (default: true) |

**Behavior Summary:** Complex orchestrator that syncs .planning/ artifacts to Linear. Delegates ALL Linear API operations to external `linear-cli` skill via Skill tool. Uses `Bash(shasum *)` for content hashing. Supports 6 subcommands with different workflows.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP | `Bash(shasum *)` is good specific restriction. **Missing `Skill` tool** -- explicitly delegates to `linear-cli` but can't invoke it without Skill in allowed-tools. |
| model selection | OK | Inherits. Orchestrator logic is computation (delta detection, hash comparison). |
| context mode | OK | Default `skill`. Needs AskUserQuestion for team selection, initiative choices. |
| disable-model-invocation | OK | Not set (false). Auto-invocation reasonable. |
| description quality | OK | Comprehensive subcommand listing. |
| argument-hint | OK | Excellent -- lists all 6 subcommands. |

**Capability Gap Analysis:**
- **Missing `Skill` tool is a critical gap** -- cannot delegate to `linear-cli` without it
- `Bash(shasum *)` is good specific restriction practice (alongside github-issue-manager and skill-creator)
- Edit tool justified for LINEAR-SYNC.json updates
- External dependency on `linear-cli` should be validated at startup

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Well-designed orchestrator with good Bash restriction. Critical gap: missing Skill tool for linear-cli delegation.

**User Decision:** Needs Feature Additions + Remain as Skill (add Skill tool to allowed-tools for linear-cli delegation)

---

### Skill: github-issue-manager (task-management)

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | github-issue-manager |
| description | "Create and maintain GitHub issues following best practices..." |
| model | sonnet |
| allowed-tools | Read, Grep, Glob, Bash(gh repo view *), Bash(gh issue create *), Bash(gh issue edit *), Bash(gh issue view *), Bash(gh issue list *), Bash(gh issue close *), Bash(gh label create *), Bash(gh label list *) |
| context | not set (default: skill) |
| disable-model-invocation | not set (default: false) |
| argument-hint | not set |
| user-invocable | not set (default: true) |

**Behavior Summary:** GitHub issue management with 7 specific `Bash(gh ...)` patterns. Creates, edits, triages, manages issues. Supports bulk creation from task documents, epic hierarchies, area labels.

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | **EXCELLENT** | 7 specific `Bash(gh ...)` patterns -- **THE best practice example** in the audit. Each gh command narrowly scoped. No Write (correct). |
| model selection | CHANGE | sonnet. User wants to downgrade to haiku -- issue management is straightforward enough. |
| context mode | OK | Default `skill`. Conversational issue management. |
| disable-model-invocation | OK | Not set (false). Auto-invocation reasonable. |
| description quality | OK | Clear, comprehensive. |
| argument-hint | GAP | Missing. Should have subcommand routing hint. |

**Capability Gap Analysis:**
- **Gold standard for Bash patterns** -- 7 specific gh commands, each narrowly scoped
- Missing argument-hint for subcommand routing
- Model should be downgraded to haiku per user preference
- Together with skill-creator, the template for how other skills should restrict Bash

**Classification Recommendation:** Needs Feature Additions + Remain as Skill
**Rationale:** Best-configured for Bash restrictions. Gaps: missing argument-hint, model should be haiku.

**User Decision:** Needs Feature Additions + Remain as Skill (add argument-hint, change model to haiku)

---

### Agent: phase-researcher (claude-super-team)

**Current Frontmatter (Agent fields):**
| Field | Value |
|-------|-------|
| name | phase-researcher |
| description | "Research ecosystem, libraries, architecture patterns, and pitfalls..." |
| tools | Read, Write, Bash, Glob, Grep, WebSearch, WebFetch |
| model | opus |
| skills | firecrawl |
| maxTurns | not set |
| permissionMode | not set |
| memory | not set |
| mcpServers | not set |
| hooks | not set |

**Behavior Summary:** Custom agent spawned by /research-phase. Deep research specialist with verification protocol (HIGH/MEDIUM/LOW confidence), source hierarchy, and structured RESEARCH.md output. Preloads firecrawl skill with graceful WebSearch/WebFetch fallback.

**Agent Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| tool restrictions | GAP | Blanket `Bash` in tools. Agent `tools` field may not support `Bash(pattern)` syntax -- needs investigation. |
| model selection | OK | opus. Appropriate for deep research requiring reasoning quality. |
| safety limits (maxTurns) | GAP | Not set. Research can spiral. A limit (30-50 turns) would prevent runaway research. |
| skill preloads | OK | `skills: [firecrawl]` correct. Graceful fallback if unavailable. |
| description quality | OK | Clear, explains role and output. |
| memory / learning | GAP | Not set. Should add `memory: project` to learn research patterns across sessions. |

**Capability Gap Analysis:**
- Blanket Bash -- investigate if agent `tools` field supports pattern restrictions
- Missing maxTurns safety limit -- research can spiral without bounds
- Should add `memory: project` for cross-session learning of research patterns
- Well-designed methodology: verification protocol, confidence levels, source hierarchy, honest reporting philosophy

**Classification Recommendation:** Needs Feature Additions + Remain as Agent
**Rationale:** Well-designed research agent. Gaps: missing maxTurns, blanket Bash (investigate), should add memory.

**User Decision:** Needs Feature Additions + Remain as Agent (add maxTurns, investigate Bash restriction for agents, add memory: project)

---

## Cross-Skill Consistency Review

### Model Selection Patterns

**Orchestrator skills** (plan-phase, execute-phase, research-phase, discuss-phase, quick-plan, phase-feedback, brainstorm): All inherit the default model. This is consistent -- they are lean orchestrators that delegate heavy work to agents with explicit model routing (opus for planners/researchers, sonnet for checkers/mappers). No changes needed for this group.

**Read-only/utility skills** (progress, cst-help): Both use haiku. Consistent. progress uses `context: fork` (no user interaction), cst-help keeps default `skill` context (interactive AskUserQuestion). The difference is justified by interaction patterns, not an inconsistency.

**Autonomous heavyweight skills** (map-codebase): Uses opus for orchestration, but agents use sonnet. The orchestrator logic (mode detection, spawning, verification) is straightforward enough for sonnet or haiku. User decision: downgrade. This is the only case where the orchestrator model exceeds what the role requires.

**Creative/generation skills** (brainstorm, skill-creator): brainstorm inherits default, skill-creator uses sonnet. Both delegate creative work. Consistent enough -- skill-creator's explicit sonnet is appropriate for its generation role.

**Cross-plugin model comparison** (marketplace-manager: haiku, github-issue-manager: sonnet->haiku): marketplace-manager already uses haiku; github-issue-manager will downgrade to haiku. After Phase 3, both utility skills from non-core plugins will use haiku. Consistent.

**Summary of model inconsistencies:**
- map-codebase opus orchestrator is the only unjustified over-specification (user already decided to downgrade)
- add-security-findings inherits default but user wants lighter model for the autonomous path
- No other model mismatches detected

### Tool Restriction Patterns

| Skill | Bash Access | Actual Bash Usage | Restriction Feasibility |
|-------|-------------|-------------------|------------------------|
| new-project | Blanket `Bash` | git init/add/commit, find, mkdir, test | `Bash(git *)`, `Bash(mkdir *)`, `Bash(find *)`, `Bash(test *)` |
| create-roadmap | Blanket `Bash` | test -f | `Bash(test *)` |
| discuss-phase | Blanket `Bash` | test -f, ls -d, grep, mkdir | `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(mkdir *)` |
| research-phase | Blanket `Bash` | test -f, ls -d, grep | `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)` |
| plan-phase | Blanket `Bash` | test -f, ls -d, grep, cat | `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(cat *)` |
| execute-phase | Blanket `Bash` | git, mkdir, ls, grep, test | `Bash(git *)`, `Bash(mkdir *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(test *)` |
| progress | Blanket `Bash` | test -d, ls -d, find, grep | `Bash(test *)`, `Bash(ls *)`, `Bash(find *)`, `Bash(grep *)` |
| quick-plan | Blanket `Bash` | test, ls, grep, mkdir | `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(mkdir *)` |
| phase-feedback | Blanket `Bash` | test, ls, grep, mkdir | `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(mkdir *)` |
| brainstorm | Blanket `Bash` | test -f, ls, cat | `Bash(test *)`, `Bash(ls *)`, `Bash(cat *)` |
| add-security-findings | Blanket `Bash` | test -f | `Bash(test *)` |
| cst-help | Blanket `Bash` | test -d, test -f, ls -d, grep, find | `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(find *)` |
| map-codebase | Blanket `Bash` | ls, rm -rf, mkdir, wc -l, grep | `Bash(ls *)`, `Bash(rm *)`, `Bash(mkdir *)`, `Bash(wc *)`, `Bash(grep *)` |
| marketplace-manager | **NO allowed-tools** | Unknown (unrestricted) | Needs full allowed-tools definition first |
| **skill-creator** | **`Bash(uv run *)`** | uv run | **GOLD STANDARD** |
| **linear-sync** | **`Bash(shasum *)`** | shasum | **GOLD STANDARD** |
| **github-issue-manager** | **7x `Bash(gh ...)`** | gh commands | **GOLD STANDARD** |
| phase-researcher (agent) | Blanket `Bash` (tools) | Unknown | Investigate if agent tools support patterns |

**Systemic pattern:** 14 of 17 skills use blanket Bash. Only 3 skills (skill-creator, linear-sync, github-issue-manager) follow the specific-pattern best practice. All 14 blanket-Bash skills could feasibly restrict -- the most common commands are `test`, `ls`, `grep`, `mkdir`, and `find`, which map cleanly to `Bash(pattern)` syntax.

**Common Bash command groups across skills:**
- **File existence checks** (`test -f`, `test -d`): Used by 13 skills. Pattern: `Bash(test *)`
- **Directory listing** (`ls -d`, `ls`): Used by 10 skills. Pattern: `Bash(ls *)`
- **Content search** (`grep`): Used by 9 skills. Pattern: `Bash(grep *)`
- **Directory creation** (`mkdir -p`): Used by 6 skills. Pattern: `Bash(mkdir *)`
- **File discovery** (`find`): Used by 3 skills. Pattern: `Bash(find *)`
- **Git operations** (`git`): Used by 2 skills. Pattern: `Bash(git *)`
- **Destructive operations** (`rm -rf`): Used by 1 skill (map-codebase refresh). Pattern: `Bash(rm *)` -- needs careful scoping

**Recommendation:** Create a standard Bash restriction template for orchestrator skills: `Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(mkdir *)`. Skills add specific patterns on top as needed (e.g., `Bash(git *)` for new-project/execute-phase).

### Context Mode Consistency

| Skill | context | AskUserQuestion | Justification |
|-------|---------|-----------------|---------------|
| progress | fork | No | Read-only, verbose output, no conversation needed |
| map-codebase | fork | No | Autonomous, agents write directly, no interaction |
| cst-help | skill (default) | Yes | Interactive help dialog, needs conversation history |
| add-security-findings | skill (default) | Yes | Interactive, but user wants fork for auto-invoked path |
| All other 13 skills | skill (default) | Yes | Interactive orchestrators needing conversation state |

**Analysis:** Context mode usage is consistent. The two `fork` skills (progress, map-codebase) are both autonomous with no AskUserQuestion. All interactive skills correctly use default `skill` context. No skills are missing `context: fork` that should have it, with one exception: add-security-findings is being redesigned for dual-mode (auto-invoke with fork, manual with skill context).

**Candidates for fork that were correctly rejected:**
- cst-help: RESEARCH.md incorrectly suggested fork; the audit correctly identified that AskUserQuestion usage requires skill context
- brainstorm: Has autonomous mode but also interactive mode; fork would break the interactive path

**`agent` field opportunity:** The `agent` field (pairs with `context: fork`) is unused. map-codebase and progress both use `context: fork` but do not specify an agent type. map-codebase could benefit from `agent: general-purpose` (explicit) or a custom agent type for the orchestrator role. Lower priority.

### Invocation Control

| # | Skill | disable-model-invocation | user-invocable | Assessment |
|---|-------|--------------------------|----------------|------------|
| 1 | new-project | not set (false) | not set (true) | GAP: should be true -- deliberate action |
| 2 | create-roadmap | false (explicit, redundant) | not set (true) | GAP: remove redundant explicit false |
| 3 | discuss-phase | not set (false) | not set (true) | OK: natural auto-trigger |
| 4 | research-phase | not set (false) | not set (true) | OK: natural auto-trigger |
| 5 | plan-phase | not set (false) | not set (true) | OK: natural auto-trigger |
| 6 | execute-phase | not set (false) | not set (true) | OK: user decided keep auto-invocable |
| 7 | progress | not set (false) | not set (true) | OK: desirable auto-trigger |
| 8 | quick-plan | not set (false) | not set (true) | OK: useful auto-trigger |
| 9 | phase-feedback | not set (false) | not set (true) | OK: natural auto-trigger |
| 10 | brainstorm | not set (false) | not set (true) | CONCERN: common word, but user decided keep |
| 11 | add-security-findings | true | not set (true) | CHANGE: user wants to remove (enable auto-invoke) |
| 12 | cst-help | not set (false) | not set (true) | OK: desirable auto-trigger |
| 13 | map-codebase | true | not set (true) | OK: deliberate action |
| 14 | marketplace-manager | not set (false) | not set (true) | OK: reasonable auto-trigger |
| 15 | skill-creator | not set (false) | not set (true) | OK: specific trigger |
| 16 | linear-sync | not set (false) | not set (true) | OK: reasonable auto-trigger |
| 17 | github-issue-manager | not set (false) | not set (true) | OK: reasonable auto-trigger |

**Summary:** 3 invocation control issues found:
1. new-project missing `disable-model-invocation: true` (deliberate action)
2. create-roadmap has redundant explicit `false`
3. add-security-findings changing from `true` to `false` (enable auto-invoke per user decision)

**`user-invocable: false` opportunity:** No skill currently uses this. No strong candidates -- all 17 skills are user-facing. If future internal-only/helper skills are created, this field should be used.

### Description & Argument Patterns

**Description quality patterns:**
- Most descriptions follow a consistent pattern: brief action phrase + when to use
- create-roadmap is the outlier: overly verbose (explains all 5 modes in description). User decided to extract modes to supporting files.
- brainstorm's description needs hardening to reduce false-positive auto-invocation of the common word "brainstorm"
- progress and cst-help have good trigger phrase lists in their descriptions

**Missing argument-hint:**

| Skill | Has argument-hint | Accepts Arguments | Gap |
|-------|------------------|-------------------|-----|
| cst-help | No | Yes (`[question]`) | Missing |
| marketplace-manager | No | Yes (subcommands) | Missing |
| github-issue-manager | No | Yes (subcommands) | Missing |
| add-security-findings | No | No (AskUserQuestion start) | OK -- no arguments |
| progress | No | No | OK -- no arguments |

**`$ARGUMENTS[N]` / `$N` shorthand opportunity:** Skills that parse complex multi-argument inputs (plan-phase: `[phase number | --all] [--gaps] [--skip-verify]`, execute-phase: `[phase number] [--gaps-only] [--skip-verify] [--team]`, linear-sync: `[init | projects | milestones | docs | issues [phase] | status]`) currently parse `$ARGUMENTS` as a single string. Indexed access via `$ARGUMENTS[N]` or `$N` shorthand could simplify argument parsing in these skills. Medium priority.

### Cross-Plugin Convention Gaps

**claude-super-team** (13 skills, 1 agent): Most mature plugin. All skills have `allowed-tools`. Consistent patterns for model routing, context mode, and agent delegation. Primary gap is universal blanket Bash.

**marketplace-utils** (2 skills): Mixed quality.
- skill-creator: Gold standard -- best `Bash(pattern)` example, proper model, good description
- marketplace-manager: **Worst-configured skill in the audit** -- no `allowed-tools` at all, missing argument-hint

Convention gap: marketplace-utils lacks the rigor that claude-super-team applies. The plugin has one exemplary skill and one critically under-configured skill.

**task-management** (2 skills): Good quality with specific gaps.
- linear-sync: Good `Bash(shasum *)` restriction, but missing `Skill` tool for linear-cli delegation (critical functional bug)
- github-issue-manager: Best Bash patterns (7 specific `gh` commands), but missing argument-hint and model needs downgrade

Convention gap: task-management skills show better Bash restriction practices than claude-super-team skills but have their own specific gaps (missing Skill tool, missing argument-hint).

**Cross-plugin pattern summary:**
| Convention | claude-super-team | marketplace-utils | task-management |
|-----------|------------------|-------------------|-----------------|
| allowed-tools present | Yes (all 13) | 1 of 2 (CRITICAL) | Yes (both) |
| Bash restricted | 0 of 13 | 1 of 2 | 2 of 2 |
| argument-hint where needed | 11 of 11 | 1 of 2 | 1 of 2 |
| Model appropriate | 12 of 13 | 2 of 2 | 1 of 2 |
| Hooks usage | 1 of 13 | 0 of 2 | 0 of 2 |

### Unused Capability Adoption Opportunities

Analysis of CAPABILITY-REFERENCE.md "Documented but unused" items with specific adoption recommendations:

**1. `disallowedTools` (tool denylist)**
- **Candidate:** marketplace-manager. Currently has NO allowed-tools. Since it needs most tools but should block a few dangerous ones (e.g., Task, TeamCreate), a denylist approach via `disallowedTools` might be simpler than an allowlist. However, allowlist is safer -- recommend allowlist first, consider denylist only if the list becomes unwieldy.
- **Verdict:** Low priority. Allowlist is the safer default for all current skills.

**2. `$ARGUMENTS[N]` indexed access / `$N` shorthand**
- **Candidates:** plan-phase, execute-phase, linear-sync -- all parse complex multi-flag argument strings
- plan-phase: `$0` could extract phase number, `$1` could extract `--all`/`--gaps`/`--skip-verify`
- execute-phase: `$0` for phase number, then flags
- linear-sync: `$0` for subcommand, `$1` for optional phase number
- **Verdict:** Medium priority. Would simplify argument parsing logic in 3 skills.

**3. Dynamic context injection (`!`command``)**
- **Candidates:** progress, cst-help -- both analyze project state
- progress could inject `!`ls .planning/phases/`` or `!`git status --short`` to pre-load state before Claude processes the skill body
- cst-help could inject `!`ls .planning/`` to pre-detect project state
- **Verdict:** Medium-high priority. Would reduce Bash calls during execution and provide immediate state context. This is the single most impactful unused feature for read-only/status skills.

**4. `agent` field with `context: fork`**
- **Candidates:** map-codebase, progress -- both already use `context: fork`
- map-codebase could specify `agent: general-purpose` (or a custom agent name) to control the forked agent's behavior more precisely
- progress could benefit less (haiku + fork is already lean)
- **Verdict:** Low priority. Current fork behavior is adequate. Would only matter if agent-specific tool restrictions or memory were needed.

**5. Skill-scoped hooks**
- **Currently used:** execute-phase (PreCompact + SessionStart for compaction resilience)
- **Candidates for adoption:**
  - map-codebase: `PreCompact` hook to preserve mapping progress during long codebase analysis
  - plan-phase: `SubagentStop` hook to validate planner output before accepting (currently done via checker agent -- hook could supplement)
  - brainstorm: `Stop` hook to force-continue if Claude stops prematurely during autonomous mode (3 parallel agents)
- **Verdict:** Medium priority. execute-phase's hook pattern is proven and could extend to other long-running orchestrators.

**6. `maxTurns` for agents**
- **Candidate:** phase-researcher agent (already identified in individual audit)
- **Verdict:** High priority. Safety limit prevents runaway research. Recommend 30-50 turns.

**7. `memory: project` for agents**
- **Candidate:** phase-researcher agent (already identified)
- **Verdict:** Medium priority. Would let the researcher learn which sources are reliable, which libraries are preferred, etc.

**8. `permissionMode` override**
- **Candidates:** map-codebase (could use `acceptEdits` for agent file writes), execute-phase agents (could use `acceptEdits` for code generation)
- **Verdict:** Low priority. Current permission model works; this is an optimization for trusted automation.

**9. `.claude/rules/` modular rules**
- **Not directly applicable** to skills, but the marketplace could ship path-scoped rules in `.claude/rules/` that activate when Claude works in `.planning/` directories. For example, a rule that loads when editing ROADMAP.md could enforce roadmap conventions.
- **Verdict:** Low priority for Phase 3, but interesting for future exploration.

**10. `skills` (nested skill preloading)**
- **Candidate:** brainstorm (preloads /create-roadmap via Skill tool), add-security-findings (delegates to /create-roadmap via Skill tool)
- If `skills: [create-roadmap]` were added to frontmatter, the skill would be preloaded rather than invoked dynamically. However, current Skill tool invocation works and is more explicit.
- **Verdict:** Low priority. Current Skill tool pattern is clear and working.

---

## Audit Summary

### Classification Results

| # | Item | Plugin | Type | Classification | Key Gaps |
|---|------|--------|------|---------------|----------|
| 1 | new-project | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, missing disable-model-invocation |
| 2 | create-roadmap | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, verbose description, redundant frontmatter |
| 3 | discuss-phase | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash |
| 4 | research-phase | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash |
| 5 | plan-phase | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash |
| 6 | execute-phase | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash |
| 7 | progress | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash |
| 8 | quick-plan | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash |
| 9 | phase-feedback | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, unnecessary Task* tools |
| 10 | brainstorm | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, description needs hardening |
| 11 | add-security-findings | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, model/context/invocation redesign |
| 12 | cst-help | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, missing argument-hint |
| 13 | map-codebase | claude-super-team | skill | Needs Feature Additions + Remain as Skill | blanket Bash, over-specified model |
| 14 | marketplace-manager | marketplace-utils | skill | Needs Feature Additions + Remain as Skill | NO allowed-tools, missing argument-hint |
| 15 | skill-creator | marketplace-utils | skill | Good as-is | none |
| 16 | linear-sync | task-management | skill | Needs Feature Additions + Remain as Skill | missing Skill tool |
| 17 | github-issue-manager | task-management | skill | Needs Feature Additions + Remain as Skill | missing argument-hint, model downgrade |
| 18 | phase-researcher | claude-super-team | agent | Needs Feature Additions + Remain as Agent | blanket Bash (investigate), missing maxTurns, missing memory |

### Statistics
- **Remain as Skill (with feature additions):** 16
- **Good as-is:** 1 (skill-creator)
- **Remain as Agent (with feature additions):** 1 (phase-researcher)
- **Convert to Agent:** 0
- **Hybrid (Skill + Agent):** 0
- **Total items audited:** 18
- **Total gaps identified:** 33
  - Blanket Bash: 15 (14 skills + 1 agent)
  - Missing allowed-tools: 1 (marketplace-manager)
  - Missing argument-hint: 3 (cst-help, marketplace-manager, github-issue-manager)
  - Missing Skill tool: 1 (linear-sync)
  - Missing disable-model-invocation: 1 (new-project)
  - Redundant frontmatter: 1 (create-roadmap explicit false)
  - Unnecessary tools: 1 (phase-feedback Task* tools)
  - Model over-specification: 2 (map-codebase opus, github-issue-manager sonnet)
  - Description issues: 2 (create-roadmap verbose, brainstorm trigger hardening)
  - Invocation control changes: 1 (add-security-findings redesign)
  - Missing agent safety limits: 2 (phase-researcher maxTurns, memory)
  - Verbose description: 1 (create-roadmap)
  - Dual-mode redesign needed: 1 (add-security-findings)
  - Agent Bash pattern investigation: 1 (phase-researcher)

### Priority Recommendations for Phase 3

1. **Fix marketplace-manager missing allowed-tools** -- the only skill with completely unrestricted tool access. Critical security gap. Add `allowed-tools: Read, Write, Edit, Bash(test *), Bash(cat *), Bash(ls *), Glob, Grep` (adjust patterns to actual usage).

2. **Add missing Skill tool to linear-sync** -- critical functional bug. linear-sync explicitly delegates to linear-cli via the Skill tool but cannot invoke it. Add `Skill` to allowed-tools.

3. **Restrict blanket Bash across all 14 skills** -- the single most pervasive gap. Create a standard template (`Bash(test *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(mkdir *)`) and apply per-skill additions. Reference skill-creator and github-issue-manager as models.

4. **Investigate agent `tools` field Bash pattern support** -- determines whether phase-researcher can restrict Bash. If patterns are supported, restrict. If not, document the limitation.

5. **Add missing argument-hints** -- 3 skills (cst-help: `[question]`, marketplace-manager: `[audit | register | remove | sync | configure]`, github-issue-manager: `[create | edit | triage | bulk-create | close]`).

6. **Add `disable-model-invocation: true` to new-project** -- project initialization should be deliberate.

7. **Remove unnecessary TaskCreate/TaskUpdate/TaskList from phase-feedback** -- principle of least privilege.

8. **Downgrade map-codebase orchestrator model** from opus to sonnet or haiku -- orchestrator is lean, agents do the work in sonnet.

9. **Downgrade github-issue-manager model** from sonnet to haiku per user preference.

10. **Add maxTurns (30-50) to phase-researcher agent** -- safety limit for runaway research.

11. **Adopt dynamic context injection** (`!`command``) in progress and cst-help for pre-loaded project state.

12. **Harden brainstorm description** to reduce false-positive auto-invocation from casual "brainstorm" mentions.

13. **Redesign add-security-findings** for dual-mode (autonomous auto-invoked path with fork + lighter model, interactive user-invoked path).

14. **Clean up create-roadmap** -- remove redundant `disable-model-invocation: false`, extract verbose operational modes to supporting files.

15. **Add `memory: project` to phase-researcher agent** for cross-session research pattern learning.

### Phase 2 Complete

All 17 skills and 1 agent audited across 3 plugins. 33 gaps identified. Cross-skill consistency review completed covering model selection, tool restrictions, context modes, invocation control, descriptions, arguments, cross-plugin conventions, and unused capability adoption. Findings ready for Phase 3: Apply Audit Recommendations.
