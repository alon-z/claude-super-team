# Plan Checker Verification and Revision Loop

### Phase 7: Spawn Plan Checker

Skip unless `--verify` flag was set.

Spawn via Task tool using the custom `plan-checker` agent (read-only, no Bash access).
The agent has its own instructions -- no need to embed the checker guide.

```
Task(
  subagent_type: "plan-checker"
  description: "Verify Phase {N} plans"
  prompt: """
  Verify the plans for Phase {phase_number}.

  Phase goal (from roadmap): {phase_goal}

  Plans directory: {phase_dir}

  Requirements (if exists):
  {requirements_content}

  Phase context (user decisions -- plans must honor these):
  {context_md_content}

  Verify these plans against all dimensions. Return VERIFICATION PASSED or ISSUES FOUND.
  """
)
```

### Phase 8: Handle Checker Return and Revision Loop

**`## VERIFICATION PASSED`:** Plans verified. Continue to Phase 9.

**`## ISSUES FOUND`:** Parse issues. Track iteration count (starts at 1).

**If iteration_count < 3:**

Show issues to user, then re-spawn planner in revision mode:

```
Task(
  subagent_type: "general-purpose"
  model: "opus"
  description: "Revise Phase {N} plans"
  prompt: """
  You are a planner agent in REVISION mode. Follow these instructions:

  {planner_guide_content}

  ---

  Phase: {phase_number}
  Mode: revision

  Existing plans:
  {current_plans_content}

  Checker issues to fix:
  {structured_issues}

  Phase context (user decisions):
  {context_md_content}

  Make targeted updates to address issues. Do NOT rewrite from scratch.
  Return REVISION COMPLETE when done.
  """
)
```

After revision, re-spawn checker (back to Phase 7). Increment iteration_count.

**If iteration_count >= 3:**

Show remaining issues. Use AskUserQuestion:

- header: "Issues"
- question: "Max revision iterations reached. {N} issues remain."
- options:
  - "Proceed anyway" -- Accept plans with known issues
  - "Provide guidance" -- Give direction for another attempt
  - "Abort" -- Exit (in --all mode, this stops the entire loop)
