# Stale State Reconciliation

Use the **PHASE_COMPLETION** and **ROADMAP_CHECKED** sections from the gather script to detect and fix desync between filesystem reality and planning files.

**PHASE_COMPLETION** shows the actual status of each phase directory based on SUMMARY.md file counts:
- `complete` = all plans have summaries (phase was fully executed)
- `partial` = some summaries exist (execution was interrupted)
- `planned` = plans exist but no summaries (not yet executed)
- `empty` = directory exists but no plans

**ROADMAP_CHECKED** shows which phases ROADMAP.md marks as `[x]` vs `[ ]`.

**Compare and fix:**

For each phase in PHASE_COMPLETION with status `complete`:
1. Check if ROADMAP.md has it marked as `[x]`. If not (still `[ ]`), fix it:
   - In the **Phases** checklist: change `- [ ]` to `- [x]` for that phase's entry
   - In the **Progress** table: set Status to "Complete" and Completed to today's date

For each phase in PHASE_COMPLETION with status `complete` or `partial`:
2. Check if STATE.md's "Current Position" Phase number is behind the actual progress. If the current phase in STATE.md is equal to or lower than a completed phase, update STATE.md to point to the next incomplete phase.

**If any fixes were applied**, print:

```
Reconciled stale state: {N} phases marked complete in ROADMAP.md, STATE.md updated to phase {M}.
```

**If no desync detected**, skip silently.
