# All-Phases Mode (--all)

## Phase 2.5: Discover Unplanned Phases (--all mode only)

Skip this phase if `--all` is not set.

Use the pre-loaded **PHASE_STATUS** and **ROADMAP_PHASES** data from the gather script. Each PHASE_STATUS line shows:

```
{dir_name}|plans={N}|context={N}|research={N}|verification={N}
```

Cross-reference ROADMAP_PHASES (phases listed in ROADMAP.md) against PHASE_STATUS (phases with directories). Build a `phases_to_plan` list containing only phases where `plans=0`.

**If the list is empty:** Show "All phases already planned. Nothing to do." and exit.

**Otherwise:** Show a brief overview before starting:

```
Planning all unplanned phases:

  Will plan:
  - Phase 2: Authentication
  - Phase 3: API Layer
  - Phase 5: Notifications

  Already planned (skipping):
  - Phase 1: Foundation
  - Phase 4: Dashboard
```

Initialize an empty `phase_results` list to collect per-phase outcomes for the combined summary.

Initialize an empty `prior_plans_index` string. After each phase completes, append a one-line-per-plan entry (plan ID + objective) so later phase planners can reference earlier plans for correct `depends_on` values.

Then loop over `phases_to_plan`, running Phases 3-8 for each. See Phase 3 for loop behavior.

## End-of-Phase Bookkeeping (--all mode)

After Phases 3-8 complete for one phase (whether verification passed, was skipped, or user overrode):

**1. Update prior plans index.** Read all PLAN.md files just created for this phase and append one line per plan to `prior_plans_index`:

```
Phase {N} / {plan_id}: {objective from plan frontmatter}
```

This lightweight index is passed to subsequent phase planners so they can set correct cross-phase `depends_on` references.

**2. Record result.** Append to `phase_results`:

```
{ phase_num, phase_name, plan_count, wave_count, verification: "Passed" | "Skipped" | "Passed with override" | "Failed" }
```

**3. Show progress:**

```
Phase {N} ({name}) planned. [{completed}/{total}]
```

**4. Error handling.** If the planner agent fails or the checker hits max iterations and the user chose "Abort" in the single-phase flow, use AskUserQuestion in --all mode instead:

- header: "Phase failed"
- question: "Phase {N} ({name}) failed. How do you want to proceed?"
- options:
  - "Skip and continue" -- Record as failed, move to next phase
  - "Retry" -- Re-attempt this phase from Phase 3
  - "Stop here" -- End loop, show partial summary with phases completed so far

After the loop ends (all phases done or user chose "Stop here"), proceed to Phase 9.

## Combined Summary (--all mode)

Use `phase_results` collected during the loop to build a summary table:

```
All phases planned.

| Phase | Name | Plans | Waves | Verification |
|-------|------|-------|-------|--------------|
| 1 | Foundation | 3 | 2 | Passed |
| 2 | Auth | 2 | 1 | Passed |
| 3 | API Layer | 4 | 3 | Skipped |

Total: {N} plans across {M} phases

---

## Next Steps

**Execute the plans:**
- Run /execute-phase 1

**Review all plans:**
- Read .planning/phases/*-PLAN.md

**Commit if desired:**
  git add .planning/phases/ && git commit -m "docs: plan all phases"

---
```

If some phases failed or were skipped (user chose "Skip and continue" or "Stop here"), note them:

```
Incomplete:
- Phase 4 (Dashboard): Failed -- skipped
- Phases 5-6: Not attempted (stopped early)
```
