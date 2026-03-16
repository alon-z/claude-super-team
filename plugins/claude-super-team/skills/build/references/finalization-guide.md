# Finalization Guide

Steps 10-13 of the /build pipeline. Final validation, auto-fix loop, BUILD-REPORT.md generation, completion summary, and success criteria.

### Step 10: Final Validation

After ALL phases have been processed:

1. Ensure on the main branch:
   ```bash
   git checkout main
   ```
   (Use the actual main branch name from BUILD-STATE.md.)

2. Update BUILD-STATE.md: set Current stage to `final-validation`.

3. ALWAYS run build + test validation regardless of per-phase results.

4. Detect validation commands using the same priority order from Step 9g-i.

5. Run build command. Capture full output.

6. Run test command. Capture full output.

7. Record results in BUILD-STATE.md Validation Results table as "Final" row.

**If both pass:** Print `Final validation passed.` Proceed to Step 12.

**If either fails:** Print `Final validation failed. Entering auto-fix loop.` Proceed to Step 11.

**If no build system detected:** Print `No build system detected -- skipping final validation.` Proceed to Step 12.

---

### Step 11: Auto-Fix Loop (Max 3 Attempts)

Update BUILD-STATE.md: set Current stage to `auto-fix`.

For attempt 1 to 3:

1. **Capture** the full build/test error output (stdout + stderr) from the previous run.

2. **Analyze** errors:
   - Parse error messages for file paths and line numbers.
   - Categorize: build error, type error, test failure, missing dependency.
   - Identify the most likely root cause for each error.

3. **Apply targeted fixes** using Edit/Write tools directly (no skill invocation):
   - Import errors: add missing imports.
   - Type errors: fix type mismatches.
   - Test failures: fix failing assertions or broken logic.
   - Missing dependencies: install via the project's package manager.

4. **Commit** the fixes:
   ```bash
   git add -A
   git commit -m "[build] Auto-fix attempt ${ATTEMPT}: ${FIX_SUMMARY}"
   ```

5. **Re-run** build + test commands.

6. **If pass:** Log success in BUILD-STATE.md. Print `Auto-fix attempt {N} succeeded.` Break out of loop. Proceed to Step 12.

7. **If fail:** Log the attempt in BUILD-STATE.md Errors section: attempt number, error summary, fix applied, result. Continue to next attempt.

**After 3 failures:**

- Log final errors in BUILD-STATE.md Errors section.
- Set BUILD-STATE.md Status to `partial`.
- Print: `Auto-fix failed after 3 attempts. Build status: partial.`
- Proceed to Step 12.

**Constraints:**
- Each attempt is logged in BUILD-STATE.md Errors section.
- Auto-fix must NOT make architectural changes -- only targeted fixes for build/test failures.
- The 3-attempt limit is hard -- do not extend it.

---

### Step 12: Generate BUILD-REPORT.md

Read the report template:

```
Read('${CLAUDE_SKILL_DIR}/assets/build-report-template.md')
```

(Resolved path: `${CLAUDE_PLUGIN_ROOT}/skills/build/assets/build-report-template.md`)

Populate all sections from BUILD-STATE.md:

- **Overview:** project name (from PROJECT.md), input ($IDEA_TEXT or PRD summary), start/end timestamps, final status.
- **Pipeline Summary:** sprints, phases planned, phases completed, phases incomplete, total plans executed, feedback loops used, compactions survived.
- **Phase Results:** from Phase Progress table -- one row per phase with sprint, name, status, validation result, notes.
- **Key Decisions:** from Decisions Log -- all decisions made during the build.
- **Low-Confidence Decisions:** filtered subset of Decisions Log where confidence = low. These are flagged for user review.
- **Validation Summary:** from Validation Results table -- per-phase build/test results.
- **Final Validation:** build/test results from Step 10, auto-fix attempts from Step 11 (if any).
- **Incomplete Items:** from Incomplete Phases section -- phases that failed validation after feedback.
- **Known Issues:** from Errors section -- all logged errors and unresolved problems.
- **Files Created:** summary from SUMMARY.md files across all phases.
- **Next Steps:** recommendations based on outcome:
  - If `complete`: "Application is built and validated. Review low-confidence decisions. Run manually. Deploy."
  - If `partial`: "Build/tests have failures after auto-fix. Review Known Issues. Run /phase-feedback on incomplete phases. Fix manually if needed."
  - If `failed`: "Critical failure prevented completion. Review Errors section. Address blockers and re-run /build to resume."

Write to `.planning/BUILD-REPORT.md`:

```
Write('.planning/BUILD-REPORT.md', populated_report)
```

Update BUILD-STATE.md:
- Set Status to the pre-audit value (`complete`, `partial`, or `failed` based on outcome so far). The completion audit (Step 12.5) may upgrade `partial` to `complete` if it resolves all gaps.
- Set Current stage to `completion-audit`.
- Write final BUILD-STATE.md.

Commit the final report:

```bash
git add .planning/BUILD-REPORT.md .planning/BUILD-STATE.md
git commit -m "[build] Build report: ${STATUS}"
```

---

### Step 12.5: Completion Audit

Scan for remaining work that the pipeline missed or could not resolve, then autonomously remediate what is possible within bounded limits.

Update BUILD-STATE.md: set Current stage to `completion-audit`. Add a Pipeline Progress row for `completion-audit` with status `in_progress`.

#### 12.5a. Gap Detection

Read BUILD-STATE.md and scan for gaps in these categories:

**Category 1 -- Incomplete Phases:** Check the Phase Progress table for any phase where Status is `incomplete` or Validate is `failed`. These are phases where execution or validation did not fully succeed.

**Category 2 -- Failed Verifications:** Check the Validation Results table for any row where Final Status is `incomplete` or `fail`. Cross-reference with VERIFICATION.md files in phase directories -- look for `status: gaps_found` or similar failure indicators.

**Category 3 -- Unresolved Errors:** Check the Errors section of BUILD-STATE.md for logged errors that were not resolved by auto-fix (Step 11). Errors with no corresponding fix attempt are candidates.

**Category 4 -- Build/Test Failures Still Present:** If Step 10/11 final validation ended with status `partial` (auto-fix failed after 3 attempts), the build or tests still fail.

Compile a gap list with: gap category, phase number (if applicable), brief description.

**If no gaps found:** Print `Completion audit: no gaps detected.` Set Pipeline Progress `completion-audit` to `complete`. Skip to Step 13.

**If gaps found:** Print `Completion audit: {N} gap(s) detected. Starting remediation.` Continue to 12.5b.

#### 12.5b. Bounded Remediation (Max 2 Cycles)

For cycle 1 to 2:

1. **Prioritize gaps:** Sort by impact -- build/test failures first, then incomplete phases, then failed verifications, then unresolved errors.

2. **For each gap (in priority order):**

   **Build/test failures (Category 4):** Run one more targeted auto-fix attempt using the same approach as Step 11 (analyze errors, apply targeted fixes, re-run build+test). This gives a total of up to 5 auto-fix attempts across the pipeline (3 from Step 11 + 2 from audit).

   **Incomplete phases (Category 1):** Invoke `/phase-feedback` for the phase with a synthesized error description from the Errors section or Validation Results. Answer all AskUserQuestion calls autonomously per the decision guide. If /phase-feedback creates a subphase, invoke `/execute-phase` for it. Commit results.

   **Failed verifications (Category 2):** Invoke `/phase-feedback` for the phase, describing the verification gap. Same autonomous handling as above.

   **Unresolved errors (Category 3):** Attempt a direct fix using Edit/Write tools if the error is clear and localized. If the error is architectural or unclear, log it as unresolvable and skip.

3. **After processing all gaps in this cycle:** Re-run build + test validation (same detection logic as Step 10). Record results.

4. **If all gaps resolved and build+tests pass:** Print `Completion audit cycle {N}: all gaps resolved.` Break out of loop.

5. **If gaps remain:** Log remaining gaps in BUILD-STATE.md Errors section. Continue to next cycle.

**After 2 cycles (or earlier if all gaps resolved):**

Update BUILD-REPORT.md with audit results. Add a new section "## Completion Audit" to BUILD-REPORT.md (before the "Next Steps" section) containing:
- Gaps detected (count and categories)
- Remediation attempts (count and outcomes)
- Remaining unresolved gaps (if any)

Update BUILD-STATE.md:
- Set Pipeline Progress `completion-audit` to `complete`.
- If audit resolved all gaps and build status was `partial`, upgrade Status to `complete`.
- If gaps remain, keep Status as-is (`partial` or `failed`).

Print: `Completion audit finished. {resolved}/{total} gaps resolved.`

---

### Step 13: Present Completion Summary

Print the final summary:

```
=== BUILD COMPLETE ===

Project: {project_name}
Status: {complete | partial | failed}
Duration: {start_time} to {end_time}

Sprints: {total_sprints}
Phases: {completed}/{total} completed
  {For each sprint S:}
  Sprint {S}:
    {list each phase: "  Phase N: {name} -- {status}"}
    Boundary validation: {pass | fail | skipped}

Validation:
  Per-phase: {N} passed, {M} failed, {K} skipped
  Sprint boundary: {N} passed, {M} failed, {K} skipped
  Final: {pass | fail | skipped}
  Auto-fix attempts: {0-3}

Decisions: {total} made autonomously
  High confidence: {count}
  Medium confidence: {count}
  Low confidence: {count} (review recommended)

{If incomplete phases exist:}
Incomplete Phases:
  {list each: "  Phase N: {name} -- {reason}"}

Git: {total_commits} commits on main branch. No remote pushes.

Report: .planning/BUILD-REPORT.md
State:  .planning/BUILD-STATE.md

--- Next Steps ---

{If complete:}
  - Review BUILD-REPORT.md, especially low-confidence decisions
  - Test the application manually
  - Run /phase-feedback on any phase to adjust behavior or style
  - Push to remote when ready: git push

{If partial:}
  - Review Known Issues in BUILD-REPORT.md
  - Run /phase-feedback on incomplete phases
  - Or fix manually and re-run: /build (auto-resumes)

{If failed:}
  - Review Errors section in BUILD-REPORT.md
  - Address the blocking issue
  - Re-run: /build (auto-resumes from last position)
```

**END OF PROCESS.**

---

## Success Criteria

- [ ] Application code exists and was generated from the provided idea/PRD
- [ ] All sprints and phases in ROADMAP.md were processed (completed or marked incomplete)
- [ ] Phases within the same sprint were planned in parallel (multi-phase sprints)
- [ ] Sprint boundary validation ran after each sprint's phases were merged
- [ ] BUILD-STATE.md tracks the full execution journey with sprint and phase progress
- [ ] BUILD-REPORT.md summarizes results with all decisions logged
- [ ] Low-confidence decisions are flagged for user review
- [ ] Git history shows one squash-merge commit per completed phase
- [ ] No user interaction occurred during the entire build
- [ ] Final validation ran (build + tests) with auto-fix if needed
- [ ] Incomplete phases are documented with reasons
- [ ] User sees a clear completion summary with next steps
- [ ] Completion audit ran and scanned for gaps after BUILD-REPORT.md generation
- [ ] Audit remediation bounded to max 2 cycles
- [ ] Audit results recorded in BUILD-REPORT.md
