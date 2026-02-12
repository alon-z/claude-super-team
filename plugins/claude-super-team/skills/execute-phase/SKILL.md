---
name: execute-phase
description: Execute planned phase by routing tasks to specialized agents. Reads PLAN.md files, infers the best agent type per task (security, TDD, general-purpose, etc.), executes in wave order with parallel plans, then verifies phase goal achievement. Use after /plan-phase to execute a specific phase. Supports --gaps-only for executing only gap closure plans and --skip-verify to skip verification.
argument-hint: "[phase number] [--gaps-only] [--skip-verify] [--team]"
allowed-tools: Read, Bash, Write, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskGet, TaskList, TaskOutput, TaskStop, TeamCreate, TeamDelete, SendMessage
hooks:
  PreCompact:
    - matcher: "auto"
      hooks:
        - type: command
          command: 'echo "EXECUTION STATE TO PRESERVE:"; find .planning/phases -name "EXEC-PROGRESS.md" -exec cat {} \; 2>/dev/null || echo "No execution progress file found"'
  SessionStart:
    - matcher: "compact"
      hooks:
        - type: command
          command: '{ echo "=== STATE ==="; cat .planning/STATE.md 2>/dev/null; echo "=== PROJECT ==="; cat .planning/PROJECT.md 2>/dev/null; echo "=== EXEC PROGRESS ==="; find .planning/phases -name "EXEC-PROGRESS.md" -exec cat {} \; 2>/dev/null; echo "=== PLANS ==="; PHASE_DIR=$(find .planning/phases -name "EXEC-PROGRESS.md" -exec dirname {} \; 2>/dev/null | head -1); [ -n "$PHASE_DIR" ] && cat "$PHASE_DIR"/*-PLAN.md 2>/dev/null; }'
---

## Objective

Execute PLAN.md files for a roadmap phase by routing each task to the best available agent, then verifying the phase goal was achieved.

**Flow:** Validate -> Discover plans -> Group by wave -> For each wave: route tasks to agents -> simplify code -> verify wave -> Next wave -> Done

**Key difference from typical execution:** Each task is routed to a specialized agent (security-reviewer, tdd-guide, etc.) based on content analysis. Agents can use skills.

**Reads:** `.planning/phases/{phase-dir}/*-PLAN.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`
**Creates:** `.planning/phases/{phase-dir}/*-SUMMARY.md`, `.planning/phases/{phase-dir}/*-VERIFICATION.md`

## Process

### Phase 1: Validate Environment

```bash
[ ! -f .planning/ROADMAP.md ] && echo "ERROR: No roadmap found. Run /create-roadmap first." && exit 1
[ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
```

You MUST run these checks before proceeding.

### Phase 1.5: Branch Guard

Check the current git branch before proceeding:

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
```

**If git is unavailable or the command fails** (non-zero exit code), or **if HEAD is detached** (output is `"HEAD"`):

Print a note and continue:

```
Note: Could not determine branch (git unavailable or detached HEAD). Continuing.
```

**If the branch is `main` or `master`:**

Use AskUserQuestion:

```
AskUserQuestion:
  header: "Branch warning"
  question: "You are on the '{CURRENT_BRANCH}' branch. Running execute-phase on main/master is not recommended."
  options:
    - "Switch branch" -- Tell the user to switch to a feature branch and re-run, then STOP execution.
    - "Continue anyway" -- Proceed with execution on the current branch.
```

**Otherwise:** Proceed normally.

### Phase 2: Parse Arguments

Extract from $ARGUMENTS:

- Phase number (integer). If not provided, detect next unexecuted phase from roadmap.
- `--gaps-only` flag: Execute only plans with `gap_closure: true` in frontmatter
- `--skip-verify` flag: Skip the verifier after wave completion
- `--team` flag: Force teams mode for wave execution

**Execution mode detection:**

```
if --team flag is set:
  EXEC_MODE=team
elif CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 in environment:
  EXEC_MODE=team
else:
  EXEC_MODE=task
fi
```

When `EXEC_MODE=team`, waves use Agent Teams (TeamCreate + teammates) instead of parallel Task calls. This provides inter-agent messaging, shared task list coordination, and better progress visibility within waves.

Normalize:

```bash
# Handle decimal phase numbers (e.g., 2.1 from inserted phases)
if echo "$PHASE_NUM" | grep -q '\.'; then
  INT_PART=$(echo "$PHASE_NUM" | cut -d. -f1)
  DEC_PART=$(echo "$PHASE_NUM" | cut -d. -f2)
  PHASE=$(printf "%02d.%s" "$INT_PART" "$DEC_PART")
else
  PHASE=$(printf "%02d" "$PHASE_NUM")
fi
```

### Phase 2.5: Log Execution Mode Decision

After determining `EXEC_MODE`, print one of the following messages so the user understands which mode was selected and how to change it:

- **If `EXEC_MODE=team` and triggered by the `--team` flag:**

```
Using teams mode (--team flag).
```

- **If `EXEC_MODE=team` and triggered by the environment variable** (no `--team` flag, but `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set):

```
Using teams mode (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1).
```

- **If `EXEC_MODE=task`:**

```
Using task mode -- teams not enabled. Pass --team or set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to use teams.
```

This message is printed once, immediately after Phase 2 completes.

### Phase 3: Discover Plans

```bash
PHASE_DIR=$(ls -d .planning/phases/${PHASE}-* 2>/dev/null | head -1)
```

If no phase directory, show error and exit.

Find all PLAN.md files:

```bash
ls "${PHASE_DIR}"/*-PLAN.md 2>/dev/null
```

If no plans found, show error: "No plans found. Run /plan-phase {N} first."

Filter completed plans (SUMMARY.md exists):

```bash
# For each PLAN.md, check if corresponding SUMMARY.md exists
# e.g., 01-02-PLAN.md is complete if 01-02-SUMMARY.md exists
```

If `--gaps-only`, filter to only plans with `gap_closure: true` in frontmatter.

Report discovery:

```
Found {N} plans, {M} already completed, {K} to execute.
```

If all plans completed, show message and exit.

### Phase 3.5: Resolve Execution Model Preference

Read `.planning/STATE.md` and check for `execution-model` in the `## Preferences` section.

**If preference is set:** Use it as `$EXEC_MODEL_PREF` (`sonnet` or `opus`).

**If preference is NOT set (missing or placeholder):** Ask the user:

```
AskUserQuestion:
  header: "Exec model"
  question: "Which model should execution agents use when building code?"
  options:
    - "Sonnet (Recommended)" -- "Faster and cheaper. Opus still used for TDD, security, planning, and verification."
    - "Opus" -- "Higher reasoning quality for all execution tasks. Slower and more expensive."
```

Persist the answer to STATE.md under `## Preferences`:

```markdown
## Preferences

execution-model: {chosen_model}
```

Use Edit tool to update STATE.md. Set `$EXEC_MODEL_PREF` to the chosen value.

### Phase 4: Group Plans by Wave

Read `wave` field from each plan's YAML frontmatter. Group plans into waves.

```
Wave structure:
| Wave | Plans | What it builds |
|------|-------|----------------|
| 1 | 01, 02 | {brief from objectives} |
| 2 | 03 | {brief from objective} |
```

### Phase 4.5: Team Setup (Teams Mode Only)

Skip if `EXEC_MODE=task`.

Create a team scoped to this phase execution:

```
TeamCreate(
  team_name: "phase-{PHASE}-exec"
  description: "Executing phase {PHASE} - {phase_name}"
)
```

The team persists across all waves in this phase. Teammates spawned in wave 1 go idle after completing their plan and can be re-messaged with new work in wave 2 (avoids context startup overhead).

### Phase 4.7: Initialize Progress Tracking

Create `${PHASE_DIR}/EXEC-PROGRESS.md` to track execution state for compaction resilience:

```markdown
## Execution Progress

- **Phase:** {PHASE} - {phase_name}
- **Mode:** {EXEC_MODE}
- **Team:** {team_name or "N/A (task mode)"}
- **Current wave:** 1
- **Started:** {current date}

### Wave Progress
| Wave | Plans | Status |
|------|-------|--------|
| 1 | {plan_list} | pending |
| 2 | {plan_list} | pending |

### Plan Status
| Plan | Wave | Teammate | Status |
|------|------|----------|--------|
| {plan} | {wave} | - | pending |
```

Populate the tables from the wave groupings determined in Phase 4. This file is re-injected by hooks after context compaction, allowing the orchestrator to resume from where it left off.

### Phase 5: Execute Waves

For each wave (sequential):

**Update EXEC-PROGRESS.md:** Set "Current wave" to this wave number and update the wave's status to "in_progress" in the Wave Progress table.

**Single-plan downgrade (teams mode only):** If `EXEC_MODE=team` and the current wave contains only a single plan, downgrade to task mode for that wave and print:

```
Using task mode for wave {N} -- single plan in wave, teams not beneficial.
```

Teams mode adds overhead for inter-agent coordination; with only one plan in a wave there is no cross-plan parallelism to benefit from, so task mode is used instead. This is a per-wave decision -- subsequent waves with multiple plans still use teams mode.

#### 5a. Parse Tasks from Plans

For each plan in this wave, parse the `<tasks>` section. Extract each `<task>`:
- `<name>`, `<files>`, `<action>`, `<verify>`, `<done>`
- Task type attribute (`auto`, `checkpoint:human-verify`, `checkpoint:decision`)

#### 5b. Route Tasks to Agents

For each task, infer the best agent type using these heuristics (first match wins):

**If `$EXEC_MODEL_PREF` = `opus`:** All execution tasks use opus regardless of signal analysis. Skip the routing table below -- every task gets `model: "opus"`.

**If `$EXEC_MODEL_PREF` = `sonnet` (default):** Use the routing table:

| Signal | Agent Type | Model |
|--------|-----------|-------|
| Plan `type: tdd` | `general-purpose` | opus |
| Action mentions security, auth hardening, vulnerability, OWASP, encryption | `general-purpose` | opus |
| Action mentions refactor, simplify, cleanup, consolidate | `general-purpose` | sonnet |
| Files are all test files (`.test.`, `.spec.`) | `general-purpose` | sonnet |
| Default | `general-purpose` | sonnet |

**Note on agent types:** While the Task tool supports specialized `subagent_type` values, `general-purpose` with appropriate prompting and model selection provides the most flexibility. The routing value comes from the **prompt content and model choice**, not the agent type label. Security tasks get opus + security-focused instructions. Refactoring gets sonnet + simplification focus. The agent's skills and tools remain available regardless.

#### 5c. Execute Tasks

**Within a plan:** Tasks execute sequentially (task 2 depends on task 1's output).
**Across plans in same wave:** Plans execute in parallel.

Read `references/task-execution-guide.md`. Build the agent prompt by embedding:

1. The task execution guide
2. The specific task details (`<name>`, `<files>`, `<action>`, `<verify>`, `<done>`)
3. Plan objective and must_haves (from plan frontmatter)
4. Prior task results from same plan (if task 2+, include task 1's report)
5. Project context: PROJECT.md content (abbreviated if large)
6. Codebase context: relevant files from `.planning/codebase/` (if exist)

##### Task Mode (EXEC_MODE=task)

For each plan in the wave, process its tasks sequentially. Use Task tool to spawn agents for tasks across different plans in parallel when possible.

```
Task(
  subagent_type: "{routed_agent_type}"
  model: "{routed_model}"
  description: "Execute {phase}-{plan} Task {N}"
  prompt: """
  {task_execution_guide_content}

  ---

  Plan: {phase}-{plan}
  Plan objective: {objective}
  Plan must_haves: {must_haves}

  Your task:

  <task type="{type}">
    <name>{name}</name>
    <files>{files}</files>
    <action>{action}</action>
    <verify>{verify}</verify>
    <done>{done}</done>
  </task>

  Prior tasks in this plan:
  {prior_task_reports or "This is the first task."}

  Project context:
  {project_md_content}

  Codebase context:
  {codebase_docs_content}
  """
)
```

##### Teams Mode (EXEC_MODE=team)

Spawn one teammate per plan in the wave. Each teammate owns all tasks in its plan (executed sequentially within the teammate's context). Cross-plan parallelism happens naturally because teammates run concurrently.

For each plan in the wave, spawn a teammate and update EXEC-PROGRESS.md: set the plan's Teammate column to the teammate name (e.g., "plan-{plan}").

```
Task(
  subagent_type: "{routed_agent_type}"
  model: "{routed_model}"
  team_name: "phase-{PHASE}-exec"
  name: "plan-{plan}"
  description: "Execute {phase}-{plan}"
  prompt: """
  You are a teammate executing plan {phase}-{plan}. Execute ALL tasks in this plan sequentially.

  {task_execution_guide_content}

  ---

  Plan: {phase}-{plan}
  Plan objective: {objective}
  Plan must_haves: {must_haves}

  Tasks to execute (in order):
  {all_tasks_in_plan_xml}

  Project context:
  {project_md_content}

  Codebase context:
  {codebase_docs_content}

  ---

  Instructions:
  - Execute each task in order. Task 2 may depend on task 1's output.
  - After completing ALL tasks, run the code-simplifier agent on all created/modified files:
    Task(subagent_type: "code-simplifier:code-simplifier", model: "sonnet", description: "Simplify {phase}-{plan} code", prompt: "Simplify and refine the recently modified files for clarity, consistency, and maintainability. Preserve ALL functionality. Files: {all created/modified files from task results}")
  - After simplification, write the plan SUMMARY.md to: {phase_dir}/{phase}-{plan}-SUMMARY.md
  - Use the summary template: {summary_template_content}
  - If any task is blocked, report ## TASK BLOCKED with the reason and stop.
  - When done, report ## PLAN COMPLETE with a brief summary of what was built.
  """
)
```

**Key differences from Task mode:**

- Each teammate gets ALL tasks for its plan at once (not one task at a time from the orchestrator). This eliminates round-trips between the orchestrator and agents for sequential tasks within a plan.
- Teammates run code-simplifier and write their own SUMMARY.md (skip Phase 5e/5f for teams -- teammates handle both).
- The team lead monitors progress via `SendMessage` broadcasts:

```
SendMessage(
  team_name: "phase-{PHASE}-exec"
  type: "broadcast"
  message: "Status check: report your current task and any blockers."
)
```

- If a teammate reports `## TASK BLOCKED`, the team lead handles it the same as Phase 5d (AskUserQuestion), then messages the teammate with guidance:

```
SendMessage(
  team_name: "phase-{PHASE}-exec"
  type: "message"
  to: "plan-{plan}"
  message: "User guidance for blocked task: {user_response}"
)
```

**Reusing teammates across waves:**

After wave N completes, idle teammates from wave N can be re-messaged with wave N+1 plans instead of spawning new teammates. This preserves their context (codebase understanding, prior decisions) and avoids cold-start overhead:

```
SendMessage(
  team_name: "phase-{PHASE}-exec"
  type: "message"
  to: "plan-{prev_plan}"  // idle teammate from prior wave
  message: "New assignment: execute plan {new_plan}. {new_plan_prompt}"
)
```

If the wave has more plans than available idle teammates, spawn additional teammates. If fewer, let extras stay idle until cleanup.

#### 5d. Handle Task Results

Parse each agent's return:

**`## TASK COMPLETE`:** Record result. If more tasks in plan, feed report to next task as context. Continue.

**`## TASK BLOCKED`:** Show blocker to user. Use AskUserQuestion:

- header: "Blocked"
- question: "Task '{name}' is blocked: {reason}. What do you want to do?"
- options:
  - "Provide guidance" -- User gives direction, re-spawn task
  - "Skip task" -- Mark as skipped, continue with next task
  - "Abort plan" -- Stop this plan, continue other plans in wave

**Checkpoint tasks (`checkpoint:human-verify`, `checkpoint:decision`):** Do NOT spawn an agent. Present the checkpoint to the user directly:

- Show what was built so far (prior task results)
- Show the checkpoint question/verification request
- Wait for user response
- Feed user's response as context to the next task

#### 5e. Simplify Code

After all tasks in a plan complete, spawn the code-simplifier agent to refine the code that was just written. The simplifier focuses on recently modified files for clarity, consistency, and maintainability while preserving all functionality.

**Collect files from task reports:** Gather all created/modified file paths from the task reports for the completed plan.

**Task Mode:**

```
Task(
  subagent_type: "code-simplifier:code-simplifier"
  model: "sonnet"
  description: "Simplify {phase}-{plan} code"
  prompt: """
  Simplify and refine the code in the following files that were just written as part of plan {phase}-{plan}.

  Focus on:
  - Clarity and readability
  - Consistency with existing codebase patterns
  - Removing unnecessary complexity
  - Clean naming and structure

  Preserve ALL functionality -- do not change behavior, only improve code quality.

  Files to review:
  {created_and_modified_files_from_task_reports}
  """
)
```

Run simplifiers for plans in the same wave in parallel.

**Teams Mode:** The simplifier call is embedded in the teammate prompt (see Phase 5c teams mode). Each teammate spawns the simplifier after executing all tasks but before writing SUMMARY.md.

#### 5f. Create SUMMARY.md Per Plan (Task Mode Only)

In teams mode, teammates write their own SUMMARY.md as part of their prompt. Skip this step.

In task mode, after all tasks in a plan complete, read `assets/summary-template.md` and create:

```
${PHASE_DIR}/${PHASE}-${PLAN}-SUMMARY.md
```

Populate with:
- Task results (commits, files, deviations)
- Aggregate from all task reports
- Decisions made during execution

**Update EXEC-PROGRESS.md:** Set the plan's status to "complete" and its teammate to "idle" (teams mode) or "-" (task mode) in the Plan Status table.

#### 5g. Spot-Check Wave Results

After all plans in wave complete:

1. Verify first 2 files from each plan's created files actually exist
2. Verify commits exist: `git log --oneline --all --grep="{phase}-{plan}"`
3. Check for `SELF_CHECK: FAILED` in any task report

If any spot-check fails, report and ask user whether to continue.

**Update EXEC-PROGRESS.md:** Set this wave's status to "complete" in the Wave Progress table.

#### 5h. Team Cleanup (Teams Mode Only)

After all waves complete, shut down the team:

1. Send graceful shutdown to all teammates:

```
SendMessage(
  team_name: "phase-{PHASE}-exec"
  type: "shutdown_request"
  message: "All waves complete. Shutting down."
)
```

2. Wait for shutdown responses, then delete the team:

```
TeamDelete(
  team_name: "phase-{PHASE}-exec"
)
```

**Update EXEC-PROGRESS.md:** Set status to "all waves complete" and record the team shutdown.

### Phase 6: Verify Phase Goal

Skip if `--skip-verify` flag was set.

Read `references/verifier-guide.md`. Collect all must_haves from all plans. Read all SUMMARY.md files.

Spawn verifier:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Verify Phase {N}"
  prompt: """
  You are a phase verifier. Follow these instructions:

  {verifier_guide_content}

  ---

  Phase: {phase_number} - {phase_name}
  Phase goal (from roadmap): {phase_goal}

  Must-haves (from all plans):
  {aggregated_must_haves}

  Execution summaries:
  {all_summaries_content}

  Write VERIFICATION.md to: {phase_dir}/
  """
)
```

### Phase 7: Handle Verification Result

Read the VERIFICATION.md created by the verifier.

**`status: passed`:** Phase verified. Continue to Phase 8.

**`status: human_needed`:** Present human verification items to user. Ask if they approve or want fixes.

**`status: gaps_found`:** Present gaps summary. Use AskUserQuestion:

- header: "Gaps"
- question: "Verification found gaps. {N} observable truths failed."
- options:
  - "Plan fixes" -- Suggest: run `/plan-phase {N} --gaps`
  - "Accept as-is" -- Proceed despite gaps
  - "Abort" -- Stop

### Phase 8: Update State

Update `.planning/STATE.md` with:
- Phase execution status (complete, gaps_found, etc.)
- Key decisions made during execution
- Any blockers or issues for next phases

Do NOT auto-commit. Do NOT update ROADMAP.md (that's for /complete-milestone).

### Phase 9: Done

Present completion summary:

```
Phase {N} executed ({task mode | teams mode}).
Execution mode: {the Phase 2.5 message that was printed at start}

Plans completed: {M}/{total}
Tasks executed: {T} total across {M} plans

Wave summary:
| Wave | Plans | Mode | Status |
|------|-------|------|--------|
| 1 | 01, 02 | teams | complete |
| 2 | 03 | task (single plan) | complete |

Verification: {Passed | Gaps found | Skipped}

---

## Next Steps

**If gaps found:**
- Run /plan-phase {N} --gaps to create fix plans
- Then /execute-phase {N} --gaps-only to execute fixes

**Want changes?**
- Run /phase-feedback {N} to give feedback, plan, and execute changes in one step
- Clarifies your feedback iteratively, then spawns opus agents to apply modifications
- Addresses visual, behavioral, or quality adjustments to delivered work

**If passed:**
- Run /verify-work {N} for manual UAT (if needed)
- Or proceed to next phase: /plan-phase {N+1}

**Commit if desired:**
  git add .planning/phases/{phase-dir}/ && git commit -m "execute phase {N}"

---
```

## Agent Routing Details

The routing in Phase 5b is intentionally simple. The value is in **prompt specialization and model selection**, not agent type labels.

For security-sensitive tasks (auth, encryption, input validation), use opus for higher reasoning quality. For straightforward implementation tasks, sonnet is sufficient and faster.

If the user has specific agent preferences, they can be communicated before execution and the orchestrator adjusts routing accordingly.

In teams mode, model selection still applies per-teammate. The `model` parameter on the Task call determines the teammate's model, using the same routing heuristics from Phase 5b.

## Resumption

If execution is interrupted and restarted:
1. `discover_plans` finds completed SUMMARYs
2. Completed plans are skipped
3. Execution resumes from first incomplete plan
4. Within an incomplete plan, check git log for task commits to determine resume point

After context compaction, the skill's hooks automatically re-inject `EXEC-PROGRESS.md` along with `STATE.md`, `PROJECT.md`, and the current phase's PLAN files. The existing SUMMARY-based resumption logic still applies, but `EXEC-PROGRESS.md` provides finer-grained state within a wave -- including which plans are in-flight, which teammates are active or idle, and the current wave number.

## Success Criteria

- [ ] .planning/ROADMAP.md and PROJECT.md exist
- [ ] Phase directory with PLAN.md files found
- [ ] Plans grouped by wave correctly
- [ ] Each task routed to appropriate agent with full context
- [ ] Tasks within plans execute sequentially
- [ ] Plans within waves execute in parallel
- [ ] Code-simplifier spawned after each plan's tasks complete
- [ ] SUMMARY.md created for each completed plan (reflects post-simplification state)
- [ ] Spot-checks pass after each wave
- [ ] Verifier spawned (unless --skip-verify)
- [ ] Verification result handled (gaps -> suggest fixes, passed -> next steps)
- [ ] STATE.md updated
- [ ] User sees clear completion summary
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps
- [ ] (Teams mode) Team created before first wave
- [ ] (Teams mode) Teammates spawned per plan with team_name parameter
- [ ] (Teams mode) Idle teammates reused across waves when possible
- [ ] (Teams mode) Team deleted after all waves complete
