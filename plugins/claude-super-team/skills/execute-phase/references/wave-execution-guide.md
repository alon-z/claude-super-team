# Wave Execution Guide

#### 5a. Parse Tasks from Plans

For each plan in this wave, parse the `<tasks>` section. Extract each `<task>`:
- `<name>`, `<files>`, `<action>`, `<verify>`, `<done>`
- Task type attribute (`auto`, `checkpoint:human-verify`, `checkpoint:decision`)

#### 5b. Route Tasks to Agents

For each task, infer the best agent type using these heuristics:

**If `$EXEC_MODEL_PREF` = `opus`:**
All execution tasks use opus regardless of signal analysis. Every task gets `model: "opus"`.

**If `$EXEC_MODEL_PREF` = `sonnet` (default):**
Use the routing table (first match wins):

| Signal | Agent Type | Model |
|--------|-----------|-------|
| Plan `type: tdd` | `general-purpose` | opus |
| Action mentions security, auth hardening, vulnerability, OWASP, encryption | `general-purpose` | opus |
| Action mentions refactor, simplify, cleanup, consolidate | `general-purpose` | sonnet |
| Files are all test files (`.test.`, `.spec.`) | `general-purpose` | sonnet |
| Default | `general-purpose` | sonnet |

**Note on agent types:** The routing value comes from prompt content and model choice, not the agent type label. While the Task tool supports specialized `subagent_type` values, `general-purpose` with appropriate prompting and model selection provides the most flexibility. Security tasks get opus with security-focused instructions. Refactoring gets sonnet with simplification focus. The agent's skills and tools remain available regardless.

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
  - After each task, evaluate if any directory you created or heavily modified needs a CLAUDE.md (see task execution guide for rules -- only when something non-obvious and critical exists, max 3-5 lines, most dirs do NOT need one).
  - If simplifier is enabled ($SIMPLIFIER_PREF = enabled): After completing ALL tasks, run the code-simplifier agent on all created/modified files:
    Task(subagent_type: "code-simplifier:code-simplifier", model: "sonnet", description: "Simplify {phase}-{plan} code", prompt: "Simplify and refine the recently modified files for clarity, consistency, and maintainability. Preserve ALL functionality. Files: {all created/modified files from task results}")
  - If simplifier is disabled: Skip the code-simplifier step and proceed directly to writing SUMMARY.md.
  - After simplification (or skipping it), write the plan SUMMARY.md to: {phase_dir}/{phase}-{plan}-SUMMARY.md
  - Use the summary template: {summary_template_content}
  - If any task is blocked, report ## TASK BLOCKED with the reason and stop.
  - When done, report ## PLAN COMPLETE with a brief summary of what was built.
  """
)
```

**Key differences from Task mode:**

- Each teammate gets ALL tasks for its plan at once, not one task at a time from the orchestrator. This eliminates round-trips between the orchestrator and agents for sequential tasks within a plan.
- Teammates run code-simplifier and write their own SUMMARY.md. Skip Phase 5e and 5f for teams mode.
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

After wave N completes, idle teammates can be re-messaged with wave N+1 plans instead of spawning new teammates. This preserves their context (codebase understanding, prior decisions) and avoids cold-start overhead:

```
SendMessage(
  team_name: "phase-{PHASE}-exec"
  type: "message"
  to: "plan-{prev_plan}"
  message: "New assignment: execute plan {new_plan}. {new_plan_prompt}"
)
```

If the wave has more plans than idle teammates, spawn additional teammates. If fewer, let extras stay idle until cleanup.

#### 5d. Handle Task Results

Parse each agent's return:

**`## TASK COMPLETE`:**
Record result. If more tasks in plan, feed report to next task as context. Continue.

**`## TASK BLOCKED`:**
Show blocker to user. Use AskUserQuestion:
- header: "Blocked"
- question: "Task '{name}' is blocked: {reason}. What do you want to do?"
- options:
  - "Provide guidance" -- User gives direction, re-spawn task
  - "Skip task" -- Mark as skipped, continue with next task
  - "Abort plan" -- Stop this plan, continue other plans in wave

**Checkpoint tasks (`checkpoint:human-verify`, `checkpoint:decision`):**
Do NOT spawn an agent. Present the checkpoint to the user directly:
- Show what was built so far (prior task results)
- Show the checkpoint question/verification request
- Wait for user response
- Feed user's response as context to the next task

#### 5e. Simplify Code (Conditional)

After all tasks in a plan complete, check `$SIMPLIFIER_PREF` to decide whether to run the code-simplifier.

**If `$SIMPLIFIER_PREF` = `enabled`:**

Spawn the code-simplifier agent to refine the code that was just written. The simplifier focuses on recently modified files for clarity, consistency, and maintainability while preserving all functionality.

Gather all created/modified file paths from the task reports for the completed plan.

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

**Teams Mode:**
The simplifier call is embedded in the teammate prompt (see Phase 5c teams mode). Each teammate spawns the simplifier after executing all tasks but before writing SUMMARY.md.

**If `$SIMPLIFIER_PREF` = `disabled`:**

Skip code simplification. Print:

```
Simplifier disabled -- skipping code simplification for {phase}-{plan}.
```

Proceed directly to SUMMARY.md creation (Phase 5f).

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
