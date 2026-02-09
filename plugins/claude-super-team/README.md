# Claude Super Team Plugin

A comprehensive project planning and execution framework for Claude Code users. This plugin provides a structured workflow to transform project ideas into delivered features through organized phases, detailed planning, and guided execution.

## Overview

The Claude Super Team plugin is a set of 9 slash commands that form a sequential workflow for managing software projects. It combines **project initialization**, **roadmap creation**, **phase planning**, and **execution guidance** into a cohesive system designed to help you ship better software more predictably.

The plugin works by creating and maintaining a `.planning/` directory in your project that stores:

- **Project vision and requirements** (PROJECT.md)
- **Phase-based roadmap** (ROADMAP.md, STATE.md)
- **Executable phase plans** (PLAN.md files with tasks and dependencies)
- **Execution summaries and verification** (SUMMARY.md, VERIFICATION.md files)

## Core Commands

### 1. `/new-project` — Initialize a Project

Start a new project by defining its vision and scope.

**Usage:**

```
/new-project <brief project idea OR path to project document>
```

**What it does:**

- Detects existing code (brownfield projects) and optionally maps it
- Guides you through discovery questions to clarify your project vision
- Creates `.planning/PROJECT.md` with captured context
- Initializes git repo if needed

**Example:**

```
/new-project a CLI tool for managing dotfiles
/new-project ./docs/vision.md
```

**When to use:** Starting a new project or when onboarding to existing code that needs planning.

---

### 2. `/map-codebase` — Understand Existing Architecture

Analyze and document an existing codebase before planning changes.

**What it does:**

- Creates 7 documentation files in `.planning/codebase/`:
  - `STACK.md` — Technology choices
  - `ARCHITECTURE.md` — System design
  - `STRUCTURE.md` — Directory layout
  - `CONVENTIONS.md` — Code patterns and standards
  - `TESTING.md` — Test approach
  - `INTEGRATIONS.md` — External dependencies
  - `CONCERNS.md` — Known issues and limitations

**When to use:** Before planning changes to existing projects, or when you need to understand code structure.

---

### 3. `/create-roadmap` — Build a Phased Delivery Plan

Transform your project vision into a phased roadmap with observable success criteria.

**Usage:**

```
/create-roadmap
/create-roadmap add a security phase
/create-roadmap insert urgent auth fix after phase 2
```

**What it does:**

- Derives phases from your project requirements (not arbitrary structure)
- Creates `.planning/ROADMAP.md` with:
  - Phase goals and descriptions
  - Success criteria (observable outcomes)
  - Requirement coverage mapping
  - Progress tracking
- Creates `.planning/STATE.md` for tracking current position

**Key philosophy:** Each phase delivers one complete, verifiable capability. Success criteria are outcomes users can observe, not task checklists.

**Examples of good success criteria:**

- "User can log in with email/password and stay logged in across browser sessions"
- "API endpoints are deployed and respond within 500ms for 95% of requests"

**When to use:** After your project is defined, or to add/modify phases during execution.

---

### 4. `/plan-phase` — Create Executable Plans

Decompose a roadmap phase into executable tasks and dependencies.

**Usage:**

```
/plan-phase 1
/plan-phase --all
/plan-phase 3 --gaps
```

**Flags:**

- `--all` — Plan all unplanned phases sequentially
- `--gaps` — Fix verification failures (gap closure mode)
- `--skip-verify` — Skip plan verification

**What it does:**

- Spawns a planner agent with full project context
- Decomoses the phase goal into concrete tasks
- Creates PLAN.md files with:
  - Task descriptions and objectives
  - Dependencies between tasks
  - Wave structure (parallel execution groups)
  - Estimated effort and complexity
- Verifies plans against phase goals
- Iterates on issues until plans pass verification (up to 3 cycles)

**Output files:** `.planning/phases/{NN}-{name}/{NN}-01-PLAN.md`, etc.

**When to use:** After your roadmap is approved, before executing a phase.

---

### 5. `/execute-phase` — Run Phase Tasks

Execute phase plans by routing tasks to specialized agents and verifying completion.

**Usage:**

```
/execute-phase 1
/execute-phase --gaps-only
/execute-phase 2 --skip-verify
```

**Flags:**

- `--gaps-only` — Execute only gap-closure tasks (for fixing verification failures)
- `--skip-verify` — Skip post-wave verification

**What it does:**

- Discovers PLAN.md files for the phase
- Groups tasks into waves (execution groups that can run in parallel)
- Routes each task to a specialized agent:
  - Security tasks → security reviewer
  - Tests → TDD guide
  - Refactoring → code simplifier
  - General → general-purpose agent
- Executes waves sequentially (waves run in parallel internally)
- Verifies each wave meets its goals
- Creates SUMMARY.md and VERIFICATION.md files

**Output files:** `.planning/phases/{NN}-{name}/{NN}-01-SUMMARY.md`, `{NN}-01-VERIFICATION.md`

**When to use:** After a phase is planned and ready to build.

---

### 6. `/quick-plan` — Lightweight Ad-hoc Planning

Insert and plan a small urgent task (bug fix, small feature) without full phase ceremony.

**Usage:**

```
/quick-plan fix critical authentication bug
/quick-plan add dark mode support
```

**What it does:**

- Inserts a decimal phase (e.g., 2.1) into the roadmap
- Creates 1-3 lightweight tasks (no research, no verification loop)
- Annotates ROADMAP.md with the quick phase
- Hands off to `/execute-phase` for execution

**When to use:** For urgent fixes, small features, or refactoring that shouldn't interrupt the main roadmap.

---

### 7. `/phase-feedback` — Iterate on Delivered Work

Collect feedback on a just-executed phase and immediately plan + execute targeted modifications.

**Usage:**

```
/phase-feedback 3
/phase-feedback 2 fix the navbar alignment and add loading states
```

**What it does:**

- Reads execution summaries and verification results from the parent phase
- Guides you through iterative feedback collection (visual/design, behavior, missing features, quality)
- Scopes feedback and creates a decimal subphase (e.g., 3.1)
- Spawns a feedback-aware planner that modifies existing work rather than building from scratch
- Executes all tasks immediately with opus agents
- Writes a summary and annotates the roadmap

**When to use:** After `/execute-phase` when you want changes to the delivered work -- visual tweaks, behavioral fixes, missing polish, or quality improvements.

---

### 8. `/progress` — Check Project Status

Get a comprehensive status report and smart routing to next action.

**Usage:**

```
/progress
```

**What it does:**

- Shows current project state (phase position, completed work)
- Displays recent decisions and blockers
- Recommends next action based on roadmap state:
  - If no project: suggest `/new-project`
  - If no roadmap: suggest `/create-roadmap`
  - If phases unplanned: suggest `/plan-phase --all`
  - If phase in progress: show completion status
  - Etc.

**When to use:** When you return to a project, after completing a phase, or when unsure what to do next.

---

### 9. `/add-security-findings` — Document Security Audit Results

Integrate security audit findings into your roadmap as security-hardening phases.

**Usage:**

```
/add-security-findings ./security-audit.md
```

**What it does:**

- Reads a security audit document
- Creates `.planning/SECURITY-AUDIT.md` with findings
- Proposes security-hardening phases based on severity
- Integrates them into your roadmap

**When to use:** After running a security audit, to ensure findings drive roadmap updates.

---

## Workflow in Action

Here's a typical end-to-end flow:

```
1. /new-project "Build an invoicing SaaS"
   → Creates PROJECT.md with vision, requirements, constraints

2. /create-roadmap
   → Creates ROADMAP.md with 5 phases:
     - Phase 1: Authentication & Core Models
     - Phase 2: Invoice Generation
     - Phase 3: Payments Integration
     - Phase 4: Admin Dashboard
     - Phase 5: Analytics & Reporting

3. /plan-phase --all
   → Plans all 5 phases:
     - Phase 1: 4 tasks in 2 waves
     - Phase 2: 6 tasks in 3 waves
     - Etc.

4. /execute-phase 1
   → Routes tasks to agents, executes waves, verifies phase goal

5. /phase-feedback 1
   → "The login form needs better error messages and a loading spinner"
   → Creates Phase 1.1, plans modifications, executes with opus agents

6. /progress
   → Shows Phase 1 + 1.1 complete, recommends /execute-phase 2

7. /quick-plan "fix OAuth token refresh bug"
   → Inserts Phase 1.2 with urgent fix

8. /execute-phase 1.2
   → Executes the urgent fix

9. /execute-phase 2
   → Moves forward with Phase 2
```

## Key Concepts

### Wave Structure

Tasks within a phase are grouped into **waves**:

- **Wave 1:** Initial setup, foundational work
- **Wave 2:** Built on Wave 1, can run in parallel with others in Wave 2
- **Wave 3:** Final integration

Waves execute sequentially, but tasks within a wave run in parallel. This lets you structure dependencies without a full DAG.

### State Tracking

`STATE.md` tracks:

- Current phase position
- Completed phases
- Key decisions made during execution
- Blockers and notes

This lets you return to a project after weeks away and quickly understand the state.

### Decimal Phase Numbering

Inserted phases use decimal numbering:

- Phase 2 (main)
- Phase 2.1 (inserted urgently)
- Phase 2.2 (another insert)
- Phase 3 (next main phase)

This lets you insert urgent work without renumbering the entire roadmap.

## Files Created

```
.planning/
├── PROJECT.md                 # Project vision, requirements, decisions
├── ROADMAP.md                 # Phase definitions, goals, success criteria
├── STATE.md                   # Current position, decisions, blockers
├── REQUIREMENTS.md            # (optional) Formal requirements
├── SECURITY-AUDIT.md          # (optional) Security findings
├── research/
│   └── SUMMARY.md             # (optional) Research findings
├── codebase/
│   ├── ARCHITECTURE.md        # System design (from /map-codebase)
│   ├── STACK.md               # Tech choices
│   ├── STRUCTURE.md           # Directory layout
│   ├── CONVENTIONS.md         # Code patterns
│   ├── TESTING.md             # Test approach
│   ├── INTEGRATIONS.md        # External dependencies
│   └── CONCERNS.md            # Known issues
└── phases/
    ├── 01-authentication/
    │   ├── 01-01-PLAN.md      # Plan for task 1
    │   ├── 01-01-SUMMARY.md   # Execution summary
    │   └── 01-01-VERIFICATION.md
    ├── 02-payments/
    │   ├── 02-01-PLAN.md
    │   ├── 02-01-SUMMARY.md
    │   └── ...
    └── 02.1-urgent-fix/       # Inserted phase (decimal)
        ├── 02.1-01-PLAN.md
        └── ...
```

## Integration with Claude Code

This plugin fully integrates with Claude Code's ecosystem:

- **Specialized agents** — Tasks are routed to security-reviewer, tdd-guide, code-simplifier, and other specialized agents
- **Context preservation** — Full project context is embedded in agent prompts (no `@` references across boundaries)

## Philosophy

The Claude Super Team plugin is built on these principles:

1. **Requirements drive structure** — Phases come from what needs to be built, not templates
2. **Observable outcomes matter** — Success criteria are what users can see, not task lists
3. **One capability per phase** — Each phase delivers something complete and verifiable
4. **State is explicit** — Where you are, what you've decided, and what's blocking you
5. **Flexibility without chaos** — Urgent work fits in without breaking the roadmap
6. **No hidden assumptions** — Everything is written down in `.planning/`

## Getting Started

```bash
# 1. Start a new project
/new-project "Your project idea"

# 2. Follow the guided workflow
/create-roadmap
/plan-phase --all
/execute-phase 1
/progress
```

For existing projects, start with `/map-codebase` to understand the architecture before creating a roadmap, then follow the same workflow.
