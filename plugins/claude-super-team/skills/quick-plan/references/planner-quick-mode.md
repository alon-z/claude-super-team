# Quick Mode Planner Guide

You create lightweight execution plans for quick phases -- ad-hoc tasks inserted into the roadmap with decimal numbering. Quick plans are simpler and faster than full phase plans but use the **standard PLAN.md format** so `/execute-phase` can consume them.

## Quick Mode vs Standard Mode

| Aspect | Quick Mode | Standard Phase Mode |
|--------|-----------|---------------------|
| Plans per phase | Always 1 | Multiple plans, multiple waves |
| Tasks per plan | 1-3 max | 2-3 per plan, many plans |
| Research | Skipped | Optional phase researcher |
| Plan checker | Skipped | Checker + revision loop |
| Verifier | Skipped (--skip-verify) | Full phase verification |
| Context budget | ~30% (lean) | ~50% (thorough) |
| Wave structure | Single wave (wave: 1) | Multiple waves |
| PLAN.md format | Standard (execute-phase compatible) | Standard |

## Core Principles

**Quick phases are atomic.** Each should be self-contained and completable in one sitting (30-90 minutes execution time).

**Quality degrades with scope creep.** If the task needs >3 tasks or touches >5 files, it belongs as a full roadmap phase.

**Autonomy first.** No plan checker or verifier runs. Plans must be executable without human intervention.

**Standard format required.** The plan must use the standard PLAN.md format with YAML frontmatter, XML tasks, must_haves, etc. -- because `/execute-phase` will execute it.

## Task Anatomy

Same as standard mode but stricter sizing:

**files:** Exact paths. Maximum 5 files per task.

**action:** Specific instructions. One paragraph max.

**verify:** Automated checks (tests, linting, curl commands).

**done:** Clear acceptance criteria.

## Task Sizing

| Tasks | Complexity | Context | Typical Use |
|-------|-----------|---------|-------------|
| 1 | Simple fix or update | ~10-15% | Bug fix, config change, doc update |
| 2 | Small feature or refactor | ~20-25% | Add endpoint + test, refactor + update callers |
| 3 | Medium complexity | ~30-35% | Small feature (impl + test + integration) |

**Never exceed 3 tasks.** If you need more, the orchestrator should have caught this at scope check.

## PLAN.md Format

Use the standard format (see `assets/quick-plan-template.md`). Key differences from full phase planning:

- `wave: 1` always (single wave)
- `depends_on: []` always (quick phases are independent)
- `quick_phase: true` in frontmatter
- `must_haves` section is minimal (1-2 truths, matching the ROADMAP annotation's success criteria)
- Single plan per phase (no multi-plan decomposition)

## Structured Return

```markdown
## PLANNING COMPLETE

**Phase:** {phase-number} - {description}
**Plan:** 1 plan, {N} task(s)

### Plan Created
| Plan | Objective | Tasks | Files |
|------|-----------|-------|-------|
| 01 | {brief} | {N} | {files} |

### Next Steps
Execute: /execute-phase {phase} --skip-verify
```
