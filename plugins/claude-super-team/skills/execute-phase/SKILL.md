---
name: execute-phase
description: Execute planned phase by routing tasks to specialized agents. Reads PLAN.md files, infers the best agent type per task (security, TDD, general-purpose, etc.), executes in wave order with parallel plans, then verifies phase goal achievement. Use after /plan-phase to execute a specific phase. Supports --gaps-only for executing only gap closure plans and --skip-verify to skip verification.
argument-hint: "[phase number] [--gaps-only] [--skip-verify]"
allowed-tools: Read, Bash, Write, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
---

## Objective

Execute PLAN.md files for a roadmap phase by routing each task to the best available agent, then verifying the phase goal was achieved.

**Flow:** Validate -> Discover plans -> Group by wave -> For each wave: route tasks to agents -> verify wave -> Next wave -> Done

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

### Phase 2: Parse Arguments

Extract from $ARGUMENTS:

- Phase number (integer). If not provided, detect next unexecuted phase from roadmap.
- `--gaps-only` flag: Execute only plans with `gap_closure: true` in frontmatter
- `--skip-verify` flag: Skip the verifier after wave completion

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

### Phase 4: Group Plans by Wave

Read `wave` field from each plan's YAML frontmatter. Group plans into waves.

```
Wave structure:
| Wave | Plans | What it builds |
|------|-------|----------------|
| 1 | 01, 02 | {brief from objectives} |
| 2 | 03 | {brief from objective} |
```

### Phase 5: Execute Waves

For each wave (sequential):

#### 5a. Parse Tasks from Plans

For each plan in this wave, parse the `<tasks>` section. Extract each `<task>`:
- `<name>`, `<files>`, `<action>`, `<verify>`, `<done>`
- Task type attribute (`auto`, `checkpoint:human-verify`, `checkpoint:decision`)

#### 5b. Route Tasks to Agents

For each task, infer the best agent type using these heuristics (first match wins):

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

For each plan in the wave, process its tasks sequentially. Use Task tool to spawn agents for tasks across different plans in parallel when possible.

Read `references/task-execution-guide.md`. Build the agent prompt by embedding:

1. The task execution guide
2. The specific task details (`<name>`, `<files>`, `<action>`, `<verify>`, `<done>`)
3. Plan objective and must_haves (from plan frontmatter)
4. Prior task results from same plan (if task 2+, include task 1's report)
5. Project context: PROJECT.md content (abbreviated if large)
6. Codebase context: relevant files from `.planning/codebase/` (if exist)

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

#### 5e. Create SUMMARY.md Per Plan

After all tasks in a plan complete, read `assets/summary-template.md` and create:

```
${PHASE_DIR}/${PHASE}-${PLAN}-SUMMARY.md
```

Populate with:
- Task results (commits, files, deviations)
- Aggregate from all task reports
- Decisions made during execution

#### 5f. Spot-Check Wave Results

After all plans in wave complete:

1. Verify first 2 files from each plan's created files actually exist
2. Verify commits exist: `git log --oneline --all --grep="{phase}-{plan}"`
3. Check for `SELF_CHECK: FAILED` in any task report

If any spot-check fails, report and ask user whether to continue.

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
Phase {N} executed.

Plans completed: {M}/{total}
Tasks executed: {T} total across {M} plans

Wave summary:
| Wave | Plans | Status |
|------|-------|--------|
| 1 | 01, 02 | complete |
| 2 | 03 | complete |

Verification: {Passed | Gaps found | Skipped}

---

## Next Steps

**If gaps found:**
- Run /plan-phase {N} --gaps to create fix plans
- Then /execute-phase {N} --gaps-only to execute fixes

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

## Resumption

If execution is interrupted and restarted:
1. `discover_plans` finds completed SUMMARYs
2. Completed plans are skipped
3. Execution resumes from first incomplete plan
4. Within an incomplete plan, check git log for task commits to determine resume point

## Success Criteria

- [ ] .planning/ROADMAP.md and PROJECT.md exist
- [ ] Phase directory with PLAN.md files found
- [ ] Plans grouped by wave correctly
- [ ] Each task routed to appropriate agent with full context
- [ ] Tasks within plans execute sequentially
- [ ] Plans within waves execute in parallel
- [ ] SUMMARY.md created for each completed plan
- [ ] Spot-checks pass after each wave
- [ ] Verifier spawned (unless --skip-verify)
- [ ] Verification result handled (gaps -> suggest fixes, passed -> next steps)
- [ ] STATE.md updated
- [ ] User sees clear completion summary
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps
