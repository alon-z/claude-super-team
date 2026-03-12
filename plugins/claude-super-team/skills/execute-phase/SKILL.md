---
name: execute-phase
description: Execute planned phase by routing tasks to specialized agents. Reads PLAN.md files, infers the best agent type per task (security, TDD, general-purpose, etc.), executes in wave order with parallel plans, then verifies phase goal achievement. Use after /plan-phase to execute a specific phase. Supports --gaps-only for executing only gap closure plans and --skip-verify to skip verification.
argument-hint: "[phase number] [--gaps-only] [--skip-verify] [--team]"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskGet, TaskList, TaskOutput, TaskStop, TeamCreate, TeamDelete, SendMessage, Bash(git *), Bash(mkdir *), Bash(ls *), Bash(grep *), Bash(test *), Bash(bash *gather-data.sh)
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
          command: 'echo "=== EXEC PROGRESS (resume from here) ==="; find .planning/phases -name "EXEC-PROGRESS.md" -exec cat {} \; 2>/dev/null || echo "No execution progress file found"; echo "=== RUN Step 0 to reload full context ==="'
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/execute-phase/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, PREFERENCES, PHASE_PLANS, PHASE_COMPLETION, ROADMAP_CHECKED, GIT) before proceeding.

**Context-aware skip:** If PROJECT.md, ROADMAP.md, or STATE.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/execute-phase/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Execute PLAN.md files for a roadmap phase by routing each task to the best available agent, then verifying the phase goal was achieved.

**Flow:** Validate -> Discover plans -> Group by wave -> For each wave: route tasks to agents -> simplify code (if enabled) -> verify wave -> Next wave -> Done

**Key difference from typical execution:** Each task is routed to a specialized agent (security-reviewer, tdd-guide, etc.) based on content analysis. Agents can use skills.

**Reads:** `.planning/phases/{phase-dir}/*-PLAN.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`
**Creates:** `.planning/phases/{phase-dir}/*-SUMMARY.md`, `.planning/phases/{phase-dir}/*-VERIFICATION.md`

## Process

### Phase 1: Validate Environment

PROJECT.md, ROADMAP.md, and STATE.md are pre-loaded via dynamic context injection. If their contents are empty/missing from the injection, show the appropriate error and exit:

- No ROADMAP.md content: "ERROR: No roadmap found. Run /create-roadmap first."
- No PROJECT.md content: "ERROR: No project found. Run /new-project first."

### Phase 1.1: Reconcile Stale State

Read `${CLAUDE_SKILL_DIR}/references/stale-state-reconciliation.md` for the detailed comparison and fix logic (PHASE_COMPLETION vs ROADMAP_CHECKED desync detection).

### Phase 1.5: Branch Guard

Use the pre-loaded **GIT** section from the gather script. The `BRANCH` value is already computed.

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

Set `EXEC_MODE` based on these conditions:
- If `--team` flag is set: `EXEC_MODE=team`
- Else if `teams-available: true` in the pre-loaded PREFERENCES section: `EXEC_MODE=team`
- Else: `EXEC_MODE=task`

When `EXEC_MODE=team`, waves use Agent Teams (TeamCreate + teammates) instead of parallel Task calls. This provides inter-agent messaging, shared task list coordination, and better progress visibility within waves.

Normalize:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/phase-utils.sh"
PHASE=$(normalize_phase "$PHASE_NUM")
```

### Phase 2.5: Log Execution Mode Decision

After determining `EXEC_MODE`, print one message so the user understands which mode was selected and how to change it:

**If `EXEC_MODE=team` triggered by `--team` flag:**
```
Using teams mode (--team flag).
```

**If `EXEC_MODE=team` triggered by PREFERENCES:**
```
Using teams mode (teams-available: true in preferences).
```

**If `EXEC_MODE=task`:**
```
Using task mode -- teams not enabled. Pass --team to use teams.
```

Print this once immediately after Phase 2 completes.

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

Use the pre-loaded **PREFERENCES** section from the gather script. Check the `execution-model` value.

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

### Phase 3.6: Resolve Simplifier Preference

Use the pre-loaded **PREFERENCES** section from the gather script. Check the `simplifier` value.

**If preference is set:** Use its value (`enabled` or `disabled`) as `$SIMPLIFIER_PREF`.

**If preference is NOT set (missing):** Default to `enabled` silently (no user prompt).

Log the resolved value:

```
Simplifier: {enabled|disabled}
```

### Phase 3.7: Resolve Verification Preference

Use the pre-loaded **PREFERENCES** section from the gather script. Check the `verification` value.

**If preference is set:** Use its value (`always`, `on-failure`, or `disabled`) as `$VERIFICATION_PREF`.

**If preference is NOT set (missing or "unset"):** Default to `on-failure` silently (no user prompt).

Log the resolved value:

```
Verification: {always|on-failure|disabled}
```

**Effect on Phase 6 (Verify Phase Goal):**

- If `$VERIFICATION_PREF` is `always`: Run the verifier (current behavior).
- If `$VERIFICATION_PREF` is `on-failure`: Skip the verifier ONLY when ALL of these are true: (1) all plans completed without errors in their SUMMARY.md files, (2) no spot-check failures occurred during wave execution, (3) `--skip-verify` was NOT explicitly set (respect explicit flags). If any plan had errors or spot-checks failed, run the verifier.
- If `$VERIFICATION_PREF` is `disabled`: Skip the verifier entirely (same as `--skip-verify`).

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

**Single-plan downgrade (teams mode only):**

If `EXEC_MODE=team` and the current wave contains only a single plan, downgrade to task mode for that wave and print:

```
Using task mode for wave {N} -- single plan in wave, teams not beneficial.
```

This is a per-wave decision. Teams mode adds overhead for inter-agent coordination. With only one plan in a wave, there is no cross-plan parallelism to benefit from. Subsequent waves with multiple plans still use teams mode.

Read `${CLAUDE_SKILL_DIR}/references/wave-execution-guide.md` for the detailed wave execution procedure (task parsing, agent routing, task/teams mode execution, result handling, simplification, summary creation, spot-checks, team cleanup).

### Phase 6: Verify Phase Goal

Skip if `--skip-verify` flag was set OR if `$VERIFICATION_PREF` is `disabled`.

If `$VERIFICATION_PREF` is `on-failure`: Skip the verifier when all plans completed cleanly (no errors in SUMMARY.md files, no spot-check failures). Run the verifier if any plan reported errors or spot-checks failed.

If `$VERIFICATION_PREF` is `always`: Always run the verifier (current default behavior).

Read `${CLAUDE_SKILL_DIR}/references/verifier-guide.md`. Collect all must_haves from all plans. Read all SUMMARY.md files.

Spawn verifier:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Verify Phase {N}"
  prompt: """
  ultrathink

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
- **Compact the Parallelism Map:** If a `### Parallelism Map` section exists, remove wave entries where all phases in the wave are now complete. Only keep waves that still contain at least one incomplete phase. If all waves are complete, remove the entire Parallelism Map section.
- **Prune Blockers/Concerns:** If a `### Blockers/Concerns` section exists, remove entries that were only relevant to the just-completed phase and have no bearing on future work. Keep entries that describe API quirks, SDK behaviors, or gotchas that future phases or maintenance will encounter. Use the phase's PLAN.md and SUMMARY.md to determine which concerns the phase addressed.

Delete `${PHASE_DIR}/EXEC-PROGRESS.md` -- it served its purpose during execution and stale files would confuse the hooks on future phase runs.

Update `.planning/ROADMAP.md`:
- In the **Phases** checklist, change `- [ ]` to `- [x]` for the completed phase entry
- In the **Progress** table, update the phase row: set Status to "Complete" and Completed to today's date (YYYY-MM-DD format)
- **Compact the completed phase's detail section:** Replace the full detail block (Goal, Depends on, Requirements, Success Criteria) with a 1-2 line summary of what was built. Keep `### Phase N: Name` heading and append `[COMPLETE]`. Include any Completion Notes if relevant. Example:

  Before:
  ```markdown
  ### Phase 3: Authentication
  **Goal**: Users can sign in via Apple or Google and manage their profile.
  **Depends on**: Phase 2
  **Requirements**:
  - better-auth configuration with Apple + Google providers
  - Session management endpoints
  - User profile CRUD
  **Success Criteria** (what must be TRUE when this phase completes):
    1. POST /api/auth/sign-in/social creates a user + session
    2. GET /api/users/me returns the full user profile
    3. POST /api/users/delete marks account for deletion
  ```

  After:
  ```markdown
  ### Phase 3: Authentication [COMPLETE]
  better-auth with Apple/Google social sign-in, session management, user profile CRUD, account deletion with 30-day grace period.
  ```

  Write the summary from the phase's SUMMARY.md and VERIFICATION.md artifacts (what was actually built), not from the original requirements. Keep it to 1-2 sentences.

- **Compact the overview paragraph:** If the Overview section contains dependency or sequencing details about the just-completed phase, rewrite the overview to focus on remaining work. Keep it to 2-3 sentences covering: what's done (count), what's next, and key remaining dependencies.

Update `.planning/PROJECT.md` (if it exists):
- **Move completed requirements to Validated:** Read the completed phase's `Requirements` field from ROADMAP.md (before compaction removed it -- use the phase's PLAN.md or SUMMARY.md as fallback). For each requirement covered by this phase, find the matching `- [ ]` checkbox in PROJECT.md's `### Active` section and move it to `### Validated` with `- [x]`. If the requirement text doesn't match exactly, match by semantic intent (e.g., phase covers "Auth screen" -> check off "Auth screen (Apple Sign-In + Google Sign-In only)").
- **Update Context section:** If the completed phase changes a factual statement in the Context section, update it. Common triggers:
  - Backend phase completes -> "Backend is a placeholder" becomes outdated
  - Auth phase completes -> "No real auth" becomes outdated
  - Styling/theme phase completes -> "not yet installed, needs setup" becomes outdated
  Only update statements that are now factually wrong. Don't rewrite the whole section.
- **Update Key Decisions:** If the phase implemented a pending decision (status "-- Pending"), change it to "Done" with the completion date.
- **Update Out of Scope:** If the phase delivered something listed as Out of Scope, remove that line from Out of Scope (it's now in scope and delivered).

Do NOT auto-commit.

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
1. Find completed SUMMARY.md files
2. Skip completed plans
3. Resume from first incomplete plan
4. Within an incomplete plan, check git log for task commits to determine resume point

After context compaction, the skill's hooks automatically re-inject `EXEC-PROGRESS.md` along with `STATE.md`, `PROJECT.md`, and the current phase's PLAN files. EXEC-PROGRESS.md provides finer-grained state within a wave: which plans are in-flight, which teammates are active or idle, and the current wave number. The existing SUMMARY-based resumption logic still applies.

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
