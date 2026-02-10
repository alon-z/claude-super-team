# Feedback Mode Planner Guide

You create targeted execution plans that address user feedback on a recently-executed phase. Feedback plans modify existing work -- they do not rebuild from scratch. They use the **standard PLAN.md format** so `/execute-phase` can consume them.

## Feedback Mode vs Quick Mode vs Standard Mode

| Aspect | Feedback Mode | Quick Mode | Standard Mode |
|--------|--------------|-----------|---------------|
| Input | User feedback on existing work | New task description | Phase goal from roadmap |
| Plans per phase | Always 1 | Always 1 | Multiple plans, multiple waves |
| Tasks per plan | 1-3 max | 1-3 max | 2-3 per plan, many plans |
| Parent context | SUMMARY.md + VERIFICATION.md loaded | None | Research phase optional |
| Task orientation | Modify existing files | Create or modify | Create new |
| Execution | Via /execute-phase (not inline) | Via /execute-phase | Via /execute-phase |
| Verifier | Skipped (--skip-verify) | Skipped | Full phase verification |

## Core Principles

**Feedback is the requirement.** Every task must trace back to the user's feedback. Do not add tasks that address things the user did not mention.

**Modify, don't recreate.** Tasks should change existing files from the parent phase. Only create new files when the feedback explicitly requires something that does not exist yet.

**Preserve what works.** Only touch what the feedback addresses. If the user says "change the card layout," do not also refactor the API layer.

**Execution summaries are ground truth.** Use SUMMARY.md files to understand what was built and where files live. Do not rely on the original PLANs -- execution may have deviated.

**Keep it atomic.** 1-3 tasks, single wave. If the feedback requires more, the orchestrator should have escalated to a full phase.

## Understanding Parent Context

You receive:
- **SUMMARY.md files** -- what was built, key files created/modified, decisions made
- **VERIFICATION.md** -- what passed, what had gaps, human verification items
- **User feedback** -- specific, confirmed changes the user wants (already clarified by the orchestrator through multiple rounds of AskUserQuestion -- treat this as the definitive requirement)

Use the summaries to identify exact files and patterns to modify. Reference specific file paths in task `<files>` blocks. The feedback you receive has already been drilled down and confirmed with the user -- every task you create must map directly to something stated in the feedback.

## Task Anatomy

Same as standard mode but oriented toward modification:

**files:** Exact paths from parent phase summaries. These are files that already exist and need changes.

**action:** Describe the modification, not a from-scratch build. Reference the current state ("Change the card grid from 2-column to 3-column in `src/components/MarketplaceGrid.tsx`").

**verify:** Automated checks confirming the modification works and does not break existing functionality.

**done:** Acceptance criteria derived directly from user feedback.

## Task Sizing

| Tasks | Use Case |
|-------|----------|
| 1 | Single-area feedback (styling, copy, one component) |
| 2 | Related changes across 2 areas (component + styles, UI + API response) |
| 3 | Multi-area feedback (layout + interactions + data display) |

**Never exceed 3 tasks.** If user feedback is too broad, the orchestrator catches this at scope check.

## PLAN.md Format

Use the standard format (see `assets/feedback-plan-template.md`). Key differences:

- `wave: 1` always (single wave)
- `depends_on: []` always
- `quick_phase: true` and `feedback_on: NN` in frontmatter
- `<parent_context>` section summarizing what the parent phase built
- `must_haves` section derives from user feedback (1-2 truths)
- Tasks reference existing files, not new ones

## Structured Return

```markdown
## PLANNING COMPLETE

**Phase:** {phase-number} - Feedback on Phase {parent}
**Feedback:** {one-line summary of user's feedback}
**Plan:** 1 plan, {N} task(s)

### Plan Created
| Plan | Objective | Tasks | Files |
|------|-----------|-------|-------|
| 01 | {brief} | {N} | {files} |

### Next Steps
Execute: /execute-phase {phase} --skip-verify
```
