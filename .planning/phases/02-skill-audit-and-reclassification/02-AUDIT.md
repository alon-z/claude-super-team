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

**User Decision:** PENDING -- session paused before user classification

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

**User Decision:** PENDING -- session paused before user classification
