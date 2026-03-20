# Claude Super Team Workflow Guide

## Overview

Claude Super Team is a structured project planning and execution workflow for software delivery. It breaks work into phases, creates detailed execution plans, and routes tasks to specialized agents.

## The Sequential Pipeline

```
/new-project          → Initialize project vision (.planning/PROJECT.md)
                        Supports --discuss for open-ended brainstorming from zero context
/map-codebase         → Understand existing codebase (optional, brownfield only)
/create-roadmap       → Define phases and goals (.planning/ROADMAP.md + STATE.md)
/discuss-phase [N]    → Explore codebase, gather user decisions (.planning/phases/NN-name/NN-CONTEXT.md)
                        Recommends /research-phase next if no RESEARCH.md exists
/research-phase [N]   → Research ecosystem and patterns (.planning/phases/NN-name/NN-RESEARCH.md)
                        Uses Context7 for known library docs, Firecrawl for ecosystem discovery
                        Checks findings against CONTEXT.md, suggests /discuss-phase if conflicts found
/plan-phase [N]       → Create execution plans (.planning/phases/NN-name/*-PLAN.md)
/execute-phase [N]    → Execute plans and verify (.planning/phases/NN-name/*-SUMMARY.md + *-VERIFICATION.md)
/progress             → Detect sync issues and check status with smart routing to next action
```

### Analysis

```
/drift [N | --all] -> Compare codebase against planning artifacts (.planning/DRIFT-REPORT.md)
                      Extracts claims from SUMMARY.md, CONTEXT.md, PLAN.md
                      Spawns Explore agents to verify claims against actual code
                      Categorizes findings: confirmed drift, potential drift, aligned

/metrics           -> Analyze telemetry data for resource usage and threshold violations
                      Reads .planning/.telemetry/ session files (captured by hook-based telemetry)
                      Reports per-session: tool calls, agents, failures, duration
                      Compares against configurable thresholds in .planning/.telemetry/config.json
```

### Brainstorming

```
/brainstorm [topic]   → Explore features, improvements, architecture ideas (.planning/IDEAS.md)
                        Interactive mode: collaborative discussion with iterative exploration
                        Autonomous mode: 3 parallel agents generate bold ideas ranked by impact
                        Optionally invokes /create-roadmap for approved ideas
                        Auto-generates CONTEXT.md for each new phase using discuss-phase template
```

### Ad-Hoc Extensions

```
/quick-plan           → Insert lightweight phase (decimal numbering: 4.1)
/phase-feedback       → Quick fix or plan feedback subphase (creates subphase like 4.1 for non-trivial changes)
/code [N] [desc]      → Interactive coding session with project context (.planning/.sessions/)
/add-security-findings → Integrate security audit into roadmap
```

### Full Automation

```
/build [idea or PRD]  → Autonomously chains entire pipeline from idea to working application
                        Runs: /new-project -> [/map-codebase] -> /brainstorm -> /create-roadmap
                        Then per phase: [/discuss-phase] -> [/research-phase] -> /plan-phase -> /execute-phase
                        Creates .planning/BUILD-STATE.md (compaction resilience, auto-resume)
                        Creates .planning/BUILD-REPORT.md (final summary with decisions and validation)
                        Multi-phase sprints run in parallel (team+worktrees), sequential fallback
                        Supports: build-preferences.md for tech stack and style preferences
                        Auto-extend: detects existing project state and enters extend mode without prior build
                        Partial project: detects PROJECT.md only and skips /new-project
```

### Help

```
/cst-help [question]  → Context-aware help, troubleshooting, and artifact explanation
                        Explain mode: /cst-help explain .planning/path/to/artifact.md
                        Reads artifact + surrounding context (CONTEXT.md, RESEARCH.md, ROADMAP.md)
                        Produces concise narrative explaining purpose, constraints, and connections
```

## Key Concepts

### Phases

Cohesive delivery milestone with:
- **Number**: Sequential (1, 2, 3) or decimal for insertions (2.1, 4.2)
- **Name**: Descriptive identifier (e.g., "foundation", "authentication")
- **Goal**: Observable, user-verifiable outcome (not a task list)
- **Directory**: `.planning/phases/{NN}-{name}/` (zero-padded)

### Plans

Executable unit of work:
- **File**: `.planning/phases/{NN}-{name}/{NN}-{plan}-PLAN.md`
- **Structure**: Objective, constraints, tasks, wave assignments
- **Execution**: Produces `{NN}-{plan}-SUMMARY.md`

### Waves

Plans grouped for execution:
- **Within wave**: Parallel execution (independent work)
- **Between waves**: Sequential execution (dependencies)

### State Tracking

- **ROADMAP.md**: All phases with goals and status
- **STATE.md**: Current position, decisions, blockers
- **VERIFICATION.md**: Phase goal verification results
- **Sync detection**: `/progress` checks for mismatches between directories, ROADMAP.md, STATE.md, and progress table
- **Dependency routing**: `/progress` parses "Depends on" lines from ROADMAP.md to determine which phases are blocked vs unblocked; Route A/B/C list ALL actionable phases rather than stopping at the first match

## Workflow Patterns

### Starting a New Project (Greenfield)

```
1. /new-project <project idea or path to vision doc>
   → Creates .planning/PROJECT.md
   → Gathers vision through iterative questioning

2. /create-roadmap
   → Creates .planning/ROADMAP.md + STATE.md
   → Defines phases with goals

3. /discuss-phase 1
   → Creates .planning/phases/01-{name}/01-CONTEXT.md
   → Explores codebase for phase-relevant context, gathers user decisions
   → Recommends /research-phase 1 next

4. /research-phase 1
   → Creates .planning/phases/01-{name}/01-RESEARCH.md
   → Investigates libraries, patterns, pitfalls
   → If findings conflict with CONTEXT.md decisions (deprecated packages,
     better alternatives): recommends re-running /discuss-phase 1 to update

5. /plan-phase 1
   → Creates .planning/phases/01-{name}/*-PLAN.md files
   → Breaks phase into executable plans

6. /execute-phase 1
   → Executes plans, creates *-SUMMARY.md files
   → Verifies phase goal achievement

7. /progress
   → Shows status, routes to next action
```

### Working with Existing Code (Brownfield)

```
1. /new-project <project description>
   → Detects existing code
   → Offers to run /map-codebase first

2. /map-codebase
   → Analyzes codebase architecture
   → Creates .planning/codebase/ (7 docs)

3. /new-project <project description>
   → Run again after mapping
   → Creates PROJECT.md with brownfield context

4. Continue with /create-roadmap...
```

### Brainstorming Features and Changes

```
# Want to explore ideas for the project

1. /brainstorm
   → Asks: Interactive or Autonomous mode?

   Interactive:
   → Asks focus area (new features, improvements, architecture)
   → Generates 3-5 ideas, user selects which to explore
   → Deep-dives each idea with 3-4 questions
   → Each idea gets a decision: approve, defer, reject

   Autonomous:
   → Asks optional focus area (or explores everything)
   → Spawns 3 parallel agents: Codebase Explorer, Creative Strategist, Architecture Reviewer
   → Synthesizes results into categorized, ranked ideas
   → User reviews and decides on each idea

2. Both modes:
   → Writes .planning/IDEAS.md
   → If ideas approved, offers to invoke /create-roadmap to add as phases
```

### Interactive Coding

```
# Just want to code with project context
/code                    → Free-form session
/code 3                  → Refine Phase 3 interactively
/code fix the login bug  → Free-form with focus description
```

### Inserting Urgent Work

```
# Currently on phase 5, need to add urgent security fix after phase 2

1. /quick-plan
   → Asks for phase position, title, description
   → Creates decimal phase (e.g., 02.1-security-hardening)
   → Spawns planner (1-3 tasks, no research)
   → Updates ROADMAP.md with inserted phase

2. /execute-phase 2.1
   → Executes the inserted phase
```

### Iterating on Delivered Work

```
# Just finished /execute-phase 4, user wants changes

1. /phase-feedback
   → Reads execution summaries and verification from phase 4
   → Gathers specific feedback through clarification
   → Quick fix: applies trivial changes directly (no subphase)
   → Standard: creates subphase (e.g., 04.1-feedback), plans it, then user runs /execute-phase
```

### When Lost or Returning

```
/progress
→ Detects sync issues between phase directories, ROADMAP.md, STATE.md, and progress table
→ Analyzes .planning/ state
→ Shows recent work, current position, blockers
→ Smart routes to next action (/plan-phase, /execute-phase, etc.)
```

## Agent Orchestration

### Planning

- `/plan-phase` and `/execute-phase` spawn subagents via Task tool
- Planners get opus model (high reasoning)
- Checkers get sonnet model (efficient verification)
- Context embedded inline (no `@` references across Task boundaries)

### Execution

- **Branch guard**: Warns if running on main/master, offers to switch branch or continue
- **Mode logging**: Prints which execution mode (team/task) was selected and how to change it
- Plans route to specialized agents (security, TDD, general-purpose)
- After each plan's tasks complete, code-simplifier refines output for clarity, consistency, and maintainability
- **Single-plan wave downgrade**: Waves with only one plan auto-downgrade from teams to task mode (no parallelism benefit)
- Wave structure enables parallel execution
- Verification ensures phase goals achieved
- Requires code-simplifier plugin: `/plugin install code-simplifier@claude-plugins-official`
- **Agent lifecycle**: Press ESC to cancel the main thread without killing background agents. Use ctrl+f to kill all background agents. Shift+Down navigates between teammates.
- **`--no-team` flag**: Forces task mode regardless of preferences. Used by `/build` sprint teammates to avoid nested teams.

### Parallel Sprint Execution (/build)

Multi-phase sprints in `/build` execute in parallel via Agent Teams + git worktrees:

- **Parallel mode** (multi-phase sprint, teams available): Lead creates a sprint team, spawns one teammate per phase. Each teammate enters a worktree (isolated repo copy), runs `/execute-phase --no-team`, validates, commits, then exits. Lead merges all worktree branches to main.
- **Sequential fallback** (single-phase sprint or teams unavailable): Original branch-per-phase flow. Lead checks out `build/{slug}` branch per phase, executes sequentially.
- **Merge conflict handling**: Planning file conflicts auto-resolved (lead manages state). Source code conflicts preserve the worktree branch for manual resolution.
- **Sprint boundary validation**: After all phases merged, build+test on main catches integration issues that per-phase worktree validation missed.

### Compaction Resilience

Long-running `/execute-phase` sessions can trigger context compaction. Handled automatically:

- **PreCompact hook**: Injects EXEC-PROGRESS.md into compaction summary to preserve execution state
- **SessionStart(compact) hook**: Re-injects STATE.md, PROJECT.md, EXEC-PROGRESS.md, and PLAN.md files after compaction
- **EXEC-PROGRESS.md**: Tracks current wave, plan statuses, team name, teammate assignments

**Configuration:** Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (1-100) to control compaction timing. Lower values = earlier compaction with more headroom. Ideal value depends on phase size.

## Success Criteria Philosophy

Phases define **observable, user-verifiable outcomes**, not task lists.

**Good:**
- "Users can register, log in, and manage profile"
- "API serves data with <200ms latency under 1000 concurrent users"
- "Code passes security scan with 0 high/critical findings"

**Bad:**
- "Complete authentication implementation"
- "Write tests"
- "Refactor codebase"

## File Structure Reference

```
.planning/
├── PROJECT.md                           # Project vision
├── ROADMAP.md                           # All phases with goals
├── STATE.md                             # Current position, decisions
├── IDEAS.md                             # Brainstormed ideas (from /brainstorm)
├── SECURITY-AUDIT.md                    # Security findings (optional)
├── BUILD-STATE.md                       # Build pipeline state and recovery (from /build)
├── BUILD-REPORT.md                      # Final build summary (from /build)
├── build-preferences.md                 # Per-project build preferences (optional)
├── .telemetry/                          # Telemetry data (captured by hooks)
│   ├── config.json                      # Threshold configuration (optional)
│   └── session-{id}.jsonl               # Per-session event logs
├── .sessions/                           # Coding session logs (gitignored)
│   └── 2026-02-16-1430-phase-3-refinement.md
├── codebase/                            # Codebase map (brownfield only)
│   ├── STACK.md
│   ├── ARCHITECTURE.md
│   ├── STRUCTURE.md
│   ├── CONVENTIONS.md
│   ├── TESTING.md
│   ├── INTEGRATIONS.md
│   └── CONCERNS.md
└── phases/
    ├── 01-foundation/
    │   ├── 01-CONTEXT.md                # User decisions (from /discuss-phase)
    │   ├── 01-RESEARCH.md               # Research findings (from /research-phase)
    │   ├── 01-01-PLAN.md                # Execution plan 1
    │   ├── 01-01-SUMMARY.md             # Execution summary 1
    │   ├── 01-02-PLAN.md
    │   ├── 01-02-SUMMARY.md
    │   └── 01-VERIFICATION.md           # Phase goal verification
    ├── 02-authentication/
    │   ├── 02-CONTEXT.md
    │   ├── 02-01-PLAN.md
    │   ├── 02-01-SUMMARY.md
    │   └── 02-VERIFICATION.md
    └── 02.1-security-hardening/         # Inserted phase (decimal)
        ├── 02.1-01-PLAN.md
        ├── 02.1-01-SUMMARY.md
        └── 02.1-VERIFICATION.md
```

## Phase Numbering

- **Sequential**: 1, 2, 3, 4... (standard phases)
- **Decimal**: 2.1, 4.2, 5.1... (inserted phases)
- **Directories**: Zero-padded (01-foundation, 02-auth, 02.1-security)
- **In ROADMAP.md**: Plain numbers (Phase 1, Phase 2, Phase 2.1)

## Common Patterns

### Gap Closure

When verification finds gaps:

```
1. /progress
   → Shows "⚠ gaps" status

2. /plan-phase N --gaps
   → Creates gap closure plans (numbered after existing plans)

3. /execute-phase N --gaps-only
   → Executes only gap closure plans
```

### Skipping Verification

For trusted phases or iteration speed:

```
/execute-phase N --skip-verify
→ Skips goal verification step
```

### Planning All Phases at Once

```
/plan-phase --all
→ Plans every unplanned phase sequentially
```

### Checking for Drift

After executing multiple phases, after long breaks, or before starting a new roadmap cycle:

```
/drift 3              → Check phase 3 claims against codebase
/drift --all          → Check all executed phases
```

`/drift` verifies that what was planned and reported matches the actual codebase. Use it to catch divergence before it compounds.

### Reviewing Telemetry Metrics

```
/metrics
→ Reads .planning/.telemetry/ session files
→ Reports per-session resource usage (tool calls, agent spawns, durations)
→ Flags threshold violations from .planning/.telemetry/config.json
```

Use `/metrics` when:
- Want to see resource usage across sessions (tool calls, agent spawns, durations)
- Checking if any session exceeded configured thresholds
- Reviewing efficiency after completing several phases
- Diagnosing slow or resource-heavy skill invocations

## Anti-Patterns

**Avoid:**
- Phases with task lists as goals
- Skipping `/discuss-phase` for complex decisions
- Running `/execute-phase` before `/plan-phase`
- Manually editing STATE.md
- Non-zero-padded directories (use 01 not 1)
- Ignoring research conflicts with decisions

**Do:**
- Define observable outcomes per phase
- Use `/discuss-phase` before planning
- Use `/research-phase` after discussion to validate decisions
- Re-run `/discuss-phase` if research finds conflicts
- Let `/progress` route to next actions
- Follow zero-padded naming (01-foundation)
