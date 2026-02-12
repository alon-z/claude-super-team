# Claude Super Team Workflow Guide

## Overview

Claude Super Team is a structured project planning and execution workflow for software delivery. It breaks work into phases, creates detailed execution plans, and routes tasks to specialized agents.

## The Sequential Pipeline

```
/new-project          → Initialize project vision (.planning/PROJECT.md)
/map-codebase         → Understand existing codebase (optional, brownfield only)
/create-roadmap       → Define phases and goals (.planning/ROADMAP.md + STATE.md)
/discuss-phase [N]    → Explore codebase + gather user decisions (.planning/phases/NN-name/NN-CONTEXT.md)
                        Recommends /research-phase next if no RESEARCH.md exists
/research-phase [N]   → Research ecosystem and patterns (.planning/phases/NN-name/NN-RESEARCH.md)
                        Checks findings against CONTEXT.md; suggests /discuss-phase if conflicts found
/plan-phase [N]       → Create execution plans (.planning/phases/NN-name/*-PLAN.md)
/execute-phase [N]    → Execute plans and verify (.planning/phases/NN-name/*-SUMMARY.md + *-VERIFICATION.md)
/progress             → Check status and get smart routing to next action
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
/add-security-findings → Integrate security audit into roadmap
```

## Key Concepts

### Phases

A phase is a cohesive delivery milestone with:
- **Number**: Sequential (1, 2, 3) or decimal for inserted phases (2.1, 4.2)
- **Name**: Descriptive identifier (e.g., "foundation", "authentication")
- **Goal**: Observable, user-verifiable outcome (not a task list)
- **Directory**: `.planning/phases/{NN}-{name}/` (zero-padded: 01, 02, etc.)

### Plans

A plan is an executable unit of work:
- **File**: `.planning/phases/{NN}-{name}/{NN}-{plan}-PLAN.md`
- **Structure**: Objective, constraints, tasks, wave assignments
- **Execution**: Produces `{NN}-{plan}-SUMMARY.md` after completion

### Waves

Plans are grouped into waves:
- **Within a wave**: Plans execute in parallel (independent work)
- **Between waves**: Waves execute sequentially (dependencies)
- **Example**: Wave 1 (data model, API routes), Wave 2 (integration tests)

### State Tracking

- **ROADMAP.md**: All phases with goals, status (`complete` vs `active`)
- **STATE.md**: Current phase position, decisions, blockers
- **VERIFICATION.md**: Phase goal verification results (success or gaps found)

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
   → Explores codebase for phase-relevant context, then gathers user decisions
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
- After each plan's tasks complete, `code-simplifier:code-simplifier` refines the output for clarity, consistency, and maintainability
- **Single-plan wave downgrade**: Waves with only one plan auto-downgrade from teams to task mode (no parallelism benefit)
- Wave structure enables parallel execution
- Verification ensures phase goals achieved
- Requires `code-simplifier` plugin: `/plugin install code-simplifier@claude-plugins-official`

### Compaction Resilience

Long-running `/execute-phase` sessions (especially teams mode with many plans) can trigger context compaction. The skill handles this automatically:

- **PreCompact hook**: Injects EXEC-PROGRESS.md content into the compaction summary so execution state survives
- **SessionStart(compact) hook**: Re-injects STATE.md, PROJECT.md, EXEC-PROGRESS.md, and all PLAN.md files for the current phase after compaction
- **EXEC-PROGRESS.md**: Written to the phase directory during execution; tracks current wave, plan statuses, team name, and teammate assignments

**Configuration:** Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (1-100) to control when auto-compaction triggers. Lower values compact more aggressively (preserving headroom but losing more context). The ideal value depends on phase size -- test empirically.

## Success Criteria Philosophy

Phases define **observable, user-verifiable outcomes**, not task lists:

**Good criteria:**
- "Users can register, log in, and manage profile"
- "API serves data with <200ms latency under 1000 concurrent users"
- "Code passes security scan with 0 high/critical findings"

**Bad criteria:**
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

## Anti-Patterns

**Don't:**
- Create phases with task lists as goals
- Skip `/discuss-phase` for complex implementation decisions
- Run `/execute-phase` before `/plan-phase`
- Manually edit STATE.md (skills manage this)
- Use non-zero-padded directories (use 01 not 1)
- Ignore research conflicts with prior decisions -- re-discuss instead

**Do:**
- Define clear observable outcomes per phase
- Use `/discuss-phase` to clarify decisions before planning
- Use `/research-phase` after discussion -- let it validate decisions against real ecosystem data
- Re-run `/discuss-phase` if research finds conflicts (deprecated packages, better alternatives)
- Skip `/research-phase` for phases using well-known patterns you're confident about
- Let `/progress` route you to next actions
- Trust the state files managed by skills
- Follow zero-padded naming (01-foundation)
