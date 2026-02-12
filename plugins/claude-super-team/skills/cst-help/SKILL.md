---
name: cst-help
description: Interactive help system for Claude Super Team workflow. Analyzes current project state in .planning/ to provide context-aware guidance on which skill to run next. Explains workflow concepts, troubleshoots issues, provides skill reference. Use when user asks "what's next?", "how does this work?", "I'm stuck", or needs help understanding the planning pipeline.
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion
model: haiku
---

## Objective

Provide context-aware help for Claude Super Team workflow by analyzing current project state and offering targeted guidance.

**This is an interactive help system** -- not just documentation, but a diagnostic and guidance tool.

**Reads:** `.planning/PROJECT.md`, `ROADMAP.md`, `STATE.md`, phase directories

**Outputs:** Current state analysis, specific guidance, concept explanations, or troubleshooting steps

## Output Style

**Be concise.** Responses must be short and actionable:
- Lead with the answer or command to run -- no preamble
- Max 2-3 sentences of explanation per topic
- Use bullet points and code blocks, not paragraphs
- Never repeat information the user already knows
- Omit "This will:" lists unless the user explicitly asks what a skill does
- For "what to do next": state + one command + one-line rationale. That's it.

## Process

### Phase 1: Classify Request

Determine whether the user needs **general workflow knowledge** or **project-specific guidance**.

**General workflow question** -- user asks about how CST works in the abstract:
- "After making a new phase, how should I proceed?"
- "What's the difference between discuss-phase and plan-phase?"
- "When should I use quick-plan vs create-roadmap?"
- "How do waves work?"
- "What does execute-phase do?"

→ Answer directly from workflow knowledge. Do NOT analyze `.planning/` state. Skip Phase 2 entirely.

**Project-specific guidance** -- user asks about their current situation:
- "What should I do next?" (no general context, wants specific advice)
- "Where am I?"
- "I'm stuck" (with no further context about what concept confuses them)
- Anything that only makes sense in the context of their specific project

→ Analyze `.planning/` state in Phase 2, then provide targeted guidance.

**If $ARGUMENTS is empty or generic ("help"):**

Use AskUserQuestion to clarify:

- header: "Help type"
- question: "What do you need help with?"
- options:
  - "Ask a question about the workflow" -- How CST works, what skills do, when to use them
  - "What to do next in my project" -- Analyze my current state and suggest next step
  - "Troubleshoot issue" -- Help diagnose a problem or error
  - "Skill reference" -- List all skills with descriptions

**If $ARGUMENTS contains a specific question:**

Classify as general vs project-specific using the criteria above. When in doubt, treat as general -- answer the question directly without state analysis.

### Phase 2: Analyze Project State (project-specific only)

**Skip this phase for general workflow questions.**

Only run state detection when the user needs project-specific guidance. Use Bash to check:

```bash
# Check for planning structure
[ -d .planning ] && echo "HAS_PLANNING=true" || echo "HAS_PLANNING=false"

# Check core files
[ -f .planning/PROJECT.md ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f .planning/STATE.md ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"

# Check for phases
[ -d .planning/phases ] && ls -d .planning/phases/*/ 2>/dev/null && echo "HAS_PHASES=true" || echo "HAS_PHASES=false"

# Check for codebase map (brownfield indicator)
[ -d .planning/codebase ] && echo "HAS_CODEBASE_MAP=true" || echo "HAS_CODEBASE_MAP=false"
```

**State categories:**

| Files Present | State | Meaning |
|---------------|-------|---------|
| None | `brand_new` | Never used Claude Super Team |
| .planning/ only | `initialized` | Directory exists, nothing else |
| PROJECT.md only | `project_defined` | Vision defined, no roadmap |
| PROJECT.md + ROADMAP.md | `roadmap_created` | Phases defined, not started |
| All core files + phase dirs | `active_project` | Work in progress |

**Extract for active projects:**

If state is `active_project`, read:
- `.planning/STATE.md` → current phase number
- `.planning/ROADMAP.md` → total phases, phase names
- Find phase directory → check for PLAN.md and SUMMARY.md counts

### Phase 3: Route to Help Response

Based on classification from Phase 1:

- **General workflow question** → Answer directly using workflow knowledge below and references/workflow-guide.md. No state analysis needed.
- **Project-specific guidance** → Use state from Phase 2 to route to "What to Do Next" response.
- **Troubleshoot** → Use diagnostics from Phase 2.
- **Skill reference** → Output skill list.

---

## Help Response: General Workflow Question

**Goal:** Answer the user's question about CST workflow directly and concisely.

Use your knowledge of the CST pipeline to answer. Read `references/workflow-guide.md` if you need details on a specific topic. Answer the question asked -- nothing more.

**The standard flow:**
1. `/new-project` → define vision
2. `/create-roadmap` → define phases with goals
3. `/discuss-phase N` → gather user decisions (optional but recommended; suggests research next)
4. `/research-phase N` → research ecosystem and patterns (optional but recommended; may suggest re-discussing if findings conflict with decisions)
5. `/plan-phase N` → create execution plans
6. `/execute-phase N` → execute and verify
7. `/progress` → check status, route to next

**Discuss-research loop:** `/discuss-phase` recommends running `/research-phase` if no RESEARCH.md exists. `/research-phase` compares findings against CONTEXT.md and recommends re-running `/discuss-phase` if it finds conflicts (deprecated packages, better alternatives, etc.). This loop refines decisions before planning.

**Ad-hoc skills:** `/brainstorm` (explore ideas interactively or let Claude analyze autonomously), `/quick-plan` (insert urgent phase), `/phase-feedback` (iterate on delivered work), `/add-security-findings` (security integration)

Example answers:
- "After creating a new phase?" → Run `/discuss-phase N` to clarify decisions, then `/research-phase N` to investigate the ecosystem, then `/plan-phase N`.
- "What's the difference between discuss-phase and plan-phase?" → `/discuss-phase` gathers user decisions and context before planning. `/plan-phase` creates executable plans with tasks and waves.
- "When should I use quick-plan?" → When you need to insert urgent work (bug fix, small feature) without full phase ceremony. Creates a decimal phase (e.g., 2.1).
- "Should I research after discussing?" → Yes, `/discuss-phase` will suggest it. Research can find that a chosen library is deprecated or a better tool exists, and will suggest re-discussing if so.

---

## Help Response: What to Do Next (project-specific)

**Goal:** Tell user exactly which skill to run and why.

**For `brand_new` state:**

```
You haven't started using Claude Super Team yet.

Start here:
  /new-project <brief project idea OR path to vision doc>

This will:
- Gather your project vision through questions
- Create .planning/PROJECT.md
- Detect if you have existing code (brownfield)

Example:
  /new-project a CLI tool for managing dotfiles
  /new-project ./docs/vision.md
```

**For `initialized` or `project_defined` state:**

Read PROJECT.md title. Then:

```
Project: {title from PROJECT.md}

Next step: Create roadmap
  /create-roadmap

This will:
- Define phases with goals
- Create .planning/ROADMAP.md and STATE.md
- Set up structure for planning and execution
```

**For `roadmap_created` state:**

Read ROADMAP.md to get Phase 1 name and goal:

```
Project: {title from PROJECT.md}
Roadmap: {N} phases defined

Next step: Start Phase 1
  /discuss-phase 1    (optional but recommended)
  /plan-phase 1

/discuss-phase gathers implementation decisions before planning.
Skip it if the path is obvious.
```

**For `active_project` state:**

Use the extracted state to provide specific guidance:

```
Project: {title}
Phase: {current_phase_num} of {total_phases} -- {phase_name}

Plans: {summary_count} of {plan_count} executed
```

**Then route based on execution status:**

| Condition | Next Action |
|-----------|-------------|
| Plans exist, not all executed | `/execute-phase {N}` |
| All plans executed, no verification | `/execute-phase {N}` (will auto-verify) |
| All complete, more phases remain | `/plan-phase {N+1}` or `/discuss-phase {N+1}` |
| All complete, last phase | `/create-roadmap` to add more phases |
| Context exists, no research, no plans | `/research-phase {N}` (recommended) or `/plan-phase {N}` |
| Research exists with decision conflicts noted | `/discuss-phase {N}` to update decisions |
| No plans for current phase | `/plan-phase {N}` |

Append:

```
Not sure? Run /progress for detailed status and smart routing.
```

---

## Help Response: Understand Concepts

**Goal:** Explain workflow concepts clearly and concisely.

**If user asks about specific concept** (phases, waves, plans, etc.):

Explain that concept using examples from their project if possible.

**If general "how does this work":**

Provide workflow overview:

```
Claude Super Team is a structured planning and execution workflow.

Core Concepts:

**Phases** -- Cohesive delivery milestones
- Example: "Foundation", "Authentication", "API Layer"
- Each has an observable goal (not a task list)
- Directory: .planning/phases/01-foundation/

**Plans** -- Executable units of work
- Break phases into concrete tasks
- File: .planning/phases/01-foundation/01-01-PLAN.md
- Execution produces SUMMARY.md

**Waves** -- Grouping for parallelization
- Plans in same wave: run in parallel (independent)
- Waves run sequentially (handle dependencies)

**The Flow:**
1. /new-project → Define vision
2. /create-roadmap → Define phases
3. /discuss-phase → Gather decisions (optional)
4. /research-phase → Research ecosystem (optional)
5. /plan-phase → Create execution plans
6. /execute-phase → Execute and verify
7. /progress → Check status, route to next

Read references/workflow-guide.md for comprehensive documentation.
```

**Available reference materials:**

Tell user about reference files:

```
Detailed guides available:
- references/workflow-guide.md -- Full workflow documentation
- references/troubleshooting.md -- Common issues and solutions

Read these with:
  Read tool on the file paths
```

---

## Help Response: Troubleshoot Issue

**Goal:** Diagnose and solve specific problems.

**Step 1: Gather problem details**

If not clear from $ARGUMENTS, use AskUserQuestion:

- header: "Issue type"
- question: "What's the problem?"
- options:
  - "Skill failed or errored" -- Command threw error
  - "Wrong state or files" -- Files missing or inconsistent
  - "Unclear what to do" -- Stuck or confused
  - "Results not expected" -- Skill ran but output wrong

**Step 2: Run diagnostics**

Based on issue type, run relevant checks:

**For "Skill failed":**

```bash
# Check file prerequisites for failed skill
# Example: if /plan-phase failed, check for ROADMAP.md
[ -f .planning/ROADMAP.md ] && echo "ROADMAP exists" || echo "ROADMAP missing"

# Check phase directory
PHASE=${PHASE_NUM}
PADDED=$(printf "%02d" "$PHASE")
ls -d .planning/phases/${PADDED}-* 2>/dev/null || echo "Phase directory missing"
```

**For "Wrong state":**

```bash
# Check phase directories match roadmap
grep "^## Phase" .planning/ROADMAP.md | wc -l
ls -d .planning/phases/*/ 2>/dev/null | wc -l

# Check plan vs summary counts
find .planning/phases -name "*-PLAN.md" | wc -l
find .planning/phases -name "*-SUMMARY.md" | wc -l
```

**Step 3: Provide solution**

Match the diagnosed issue to troubleshooting guide:

```
Issue: {diagnosed problem}

Solution:
{specific steps to fix}

{relevant commands to run}

For more: see references/troubleshooting.md
```

**Common quick fixes:**

| Issue | Solution |
|-------|----------|
| No PROJECT.md | Run `/new-project <idea>` |
| No ROADMAP.md | Run `/create-roadmap` |
| No plans for phase | Run `/plan-phase {N}` |
| Plans without summaries | Run `/execute-phase {N}` |
| Phase directory naming | Rename to zero-padded format (01, 02) |
| Verification gaps | Run `/plan-phase {N} --gaps` then `/execute-phase {N} --gaps-only` |

---

## Help Response: Skill Reference

**Goal:** Provide quick reference for all available skills.

**Output format:**

```
# Claude Super Team Skills

## Core Workflow

/new-project <idea or path>
  Initialize project vision
  → Creates .planning/PROJECT.md

/map-codebase
  Analyze existing codebase (brownfield)
  → Creates .planning/codebase/ (7 docs)

/create-roadmap
  Define phases and goals
  → Creates .planning/ROADMAP.md + STATE.md

/discuss-phase [N]
  Explore codebase for phase-relevant context, then gather user decisions before planning
  → Creates .planning/phases/{NN}-{name}/{NN}-CONTEXT.md

/research-phase [N]
  Research ecosystem, libraries, patterns before planning
  → Creates .planning/phases/{NN}-{name}/{NN}-RESEARCH.md

/plan-phase [N]
  Create execution plans for phase
  → Creates .planning/phases/{NN}-{name}/*-PLAN.md
  Options: --gaps (create gap closure plans), --all (plan all phases)

/execute-phase [N]
  Execute plans, simplify code, and verify phase goals
  → Branch guard: warns if running on main/master, offers to switch
  → Logs execution mode (team/task) and how to change it
  → Single-plan waves auto-downgrade from teams to task mode
  → Runs code-simplifier on each plan's output before summary
  → Creates .planning/phases/{NN}-{name}/*-SUMMARY.md + *-VERIFICATION.md
  -> Compaction resilient: hooks re-inject execution state after context compaction
  -> Set CLAUDE_AUTOCOMPACT_PCT_OVERRIDE to control when compaction triggers (user-configured)
  Options: --gaps-only (execute only gap plans), --skip-verify (skip verification), --team (use teams mode)
  Requires: code-simplifier plugin (/plugin install code-simplifier@claude-plugins-official)

/progress
  Check status and get smart routing
  → Shows current position, recent work, next action
  → Steps column (D/R/P) shows discuss, research, plan status per phase

## Brainstorming

/brainstorm [topic]
  Explore features, improvements, and architecture ideas
  Two modes:
    Interactive -- collaborative discussion with iterative exploration
    Autonomous -- 3 parallel agents (codebase, strategy, architecture) generate bold ideas
  → Creates/updates .planning/IDEAS.md
  → Optionally invokes /create-roadmap to add approved ideas as phases
  → Auto-generates CONTEXT.md for each new phase using discuss-phase template

## Ad-Hoc Extensions

/quick-plan
  Insert lightweight phase (1-3 tasks)
  → Creates decimal phase (e.g., 02.1-hotfix)
  → Includes discussion + planning

/phase-feedback
  Gather feedback on executed phase
  → Quick fix: applies trivial changes directly
  → Standard: plans subphase (e.g., 04.1-feedback), user runs /execute-phase

/add-security-findings
  Integrate security audit into roadmap
  → Creates .planning/SECURITY-AUDIT.md
  → Adds security phases to roadmap

## Help

/cst-help [question]
  This skill -- context-aware help and troubleshooting
```

**Then add current state context:**

```
Your current state: {state from Phase 2}
Suggested next step: {specific skill command}
```

---

## Edge Cases

### User has existing `.planning/` but corrupt state

Diagnose specific corruption:

```bash
# Check for common issues
[ -f .planning/PROJECT.md ] || echo "MISSING: PROJECT.md"
[ -f .planning/ROADMAP.md ] || echo "MISSING: ROADMAP.md"
[ -f .planning/STATE.md ] || echo "MISSING: STATE.md"

# Check phase directories
ls .planning/phases/ 2>/dev/null | grep -v "^[0-9]" && echo "WARNING: Non-standard phase directory names"
```

Suggest specific fixes:
- Missing core files: which skills to re-run
- Malformed phase directories: how to rename
- Inconsistent state: which files to review/edit

### User asks about multiple topics

Use AskUserQuestion to focus:

- header: "Priority"
- question: "Which should we address first?"
- options: [the multiple topics as options]

Then handle one at a time.

### User asks about non-CST topics

```
This help skill covers the Claude Super Team workflow only.

For general Claude Code help:
  /help

For other plugins:
- /marketplace-utils:marketplace-manager -- Plugin marketplace
- /task-management:linear-sync -- Linear integration
- /task-management:github-issue-manager -- GitHub issues
```

## Success Criteria

- [ ] User need identified (what to do next, concepts, troubleshooting, or reference)
- [ ] Project state analyzed (always, before any guidance)
- [ ] Targeted response provided based on state + need
- [ ] Specific commands or next steps given (not generic advice)
- [ ] Reference materials mentioned when relevant
- [ ] User knows how to proceed
