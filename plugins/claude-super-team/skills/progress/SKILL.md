---
name: progress
description: Check project progress and route to next action. Analyzes .planning/ files to show current position, recent work, key decisions, and intelligently routes to the appropriate next step (/new-project, /create-roadmap, /plan-phase, /execute-phase, etc.). Use when user asks "where am I?", "what's next?", returns to project after time away, or completes a phase and needs direction.
allowed-tools: Read, Grep, Glob, Bash(bash *gather-data.sh)
context: fork
model: haiku
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/progress/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, SECURITY_AUDIT, BUILD_STATE_FILE, STRUCTURE, PHASE_MAP, RECENT_SUMMARIES, SYNC_CHECK, BUILD, GIT) before proceeding.

## Objective

Present a comprehensive status report of project progress and intelligently route to the next action.

**This is a navigation and context skill** -- helps users understand where they are in the project flow and what to do next.

All data is pre-loaded via dynamic context injection above. Use the injected file contents and structured sections (STRUCTURE, PHASE_MAP, RECENT_SUMMARIES, GIT) to build the report. No Bash calls needed.

## Process

### Phase 1: Verify Planning Structure

From the pre-loaded **STRUCTURE** section, check the flags:

**If `PLANNING_DIR=missing`:**

```
No planning structure found.

Run /new-project to start a new project.
```

Exit skill.

**Route based on what exists:**

| Condition | Meaning | Action |
|-----------|---------|--------|
| `HAS_PROJECT=false` | Brand new project | Show: "Run /new-project to initialize" |
| `HAS_PROJECT=true` but `HAS_ROADMAP=false` | Project defined, needs roadmap | Go to **Route: Between Milestones** |
| All three `true` | Active project | Continue to Phase 1b |

### Phase 1b: Detect Build Mode

Check the **BUILD** section from gather-data.sh output.

**If `HAS_BUILD_STATE=true` and `BUILD_STATUS=in_progress`:**

This project is being built autonomously by `/build`. Set a `BUILD_MODE=true` flag for use in later phases. Extract key build state:

- `BUILD_STAGE` -- current pipeline stage (e.g., `new-project`, `brainstorm`, `phase-3-pipeline`)
- `BUILD_PHASE` -- current phase number being processed
- `BUILD_COMPACTIONS` -- how many context compactions have occurred
- `BUILD_STARTED` -- when the build started
- `BUILD_INPUT` -- the original idea/PRD (truncated)
- `BUILD_PIPELINE` -- pipeline progress rows
- `BUILD_INCOMPLETE` -- any incomplete phases so far

**If `HAS_BUILD_STATE=true` and `BUILD_STATUS=complete`:**

Set `BUILD_MODE=false`. The build finished. Note the completed build for the status report.

**If `HAS_BUILD_STATE=true` and `BUILD_STATUS=partial` or `BUILD_STATUS=failed`:**

Set `BUILD_MODE=false`. The build ended with issues. Note for the status report and routing.

**If `HAS_BUILD_STATE=false`:**

Set `BUILD_MODE=false`. Standard manual workflow.

Continue to Phase 2.

### Phase 2: Detect Planning File Sync Issues

**Only runs when all three core files exist.** Use the pre-loaded **SYNC_CHECK** section which provides:

```
DIR_PHASES: 1 1.1 1.2 2 3        (phase numbers from directories)
ROADMAP_PHASES: 1 1.1 1.2 2 3    (phase numbers from ROADMAP.md)
STATE_PHASE: 3                    (current phase from STATE.md)
CHECKED: 1                        (phases with [x] in ROADMAP.md)
CHECKED: 1.1
UNCHECKED: 3                      (phases with [ ] in ROADMAP.md)
```

**Check 1: Directory vs Roadmap** -- Compare `DIR_PHASES` and `ROADMAP_PHASES` lists:
- **Orphan directories**: numbers in DIR_PHASES but not in ROADMAP_PHASES
- **Missing directories**: numbers in ROADMAP_PHASES but not in DIR_PHASES

**Check 2: STATE.md Drift** -- Verify `STATE_PHASE` appears in both ROADMAP_PHASES and DIR_PHASES.

**Check 3: Progress Table Inconsistencies** -- Parse the ROADMAP.md "## Progress" table from the injected content. Compare phase numbers there against ROADMAP_PHASES (from the Phases checklist). Report mismatches.

**Check 4: Stale Completion Status** -- Cross-reference CHECKED/UNCHECKED lines against PHASE_MAP metrics:
- CHECKED phase but PHASE_MAP shows summaries=0 (marked complete without evidence)
- UNCHECKED phase but PHASE_MAP shows summaries==plans>0 (executed but not marked)
- PHASE_MAP shows summaries>0 but Progress table shows "Not started" or "Planned"

**Collect all issues found.** Store for output in Phase 5 if any exist, otherwise omit entirely.

### Phase 3: Extract Context

From the pre-loaded file contents, extract:

**From PROJECT.md:** project name (from "What This Is" section)
**From ROADMAP.md:** all phases with goals, Phases checklist, Progress table
**From STATE.md:** current phase number, position, blockers, decisions
**From SECURITY-AUDIT.md (if present):** count findings by severity

### Phase 4: Build Phase Map

From the pre-loaded **PHASE_MAP** data, parse each line:

```
{dir_name}|plans={N}|summaries={N}|gaps={N}|context={N}|research={N}
```

Extract the phase number from `dir_name` (e.g., `05-auth` = phase 5, `02.1-security` = phase 2.1).

Assign each phase a status label:
- `done` -- summaries == plans > 0, gaps == 0
- `gaps` -- gaps > 0
- `executing` -- summaries > 0 but summaries < plans
- `planned` -- plans > 0, summaries == 0
- `current` -- the phase STATE.md points to (overlay on other statuses)
- `upcoming` -- plans == 0, not current

From the **RECENT_SUMMARIES** section, parse each line:

```
{phase_dir}/{filename}|{excerpt}
```

### Phase 5: Present Status Report

**Output the report in this format.** Build a progress bar: for each 10% of completion, use `█`. For remaining, use `░`. Always 10 characters wide.

Example: 7 of 10 plans done = `███████░░░` 70%

```
# {Project Name}

**Progress:** {bar} {completed}/{total} plans
**Phase:** {current_phase_num} of {total_phases} -- {current_phase_name}

### Autonomous Build  (only show if BUILD_MODE=true)

/build is actively running this project autonomously.

| Field | Value |
|-------|-------|
| Status | {BUILD_STATUS} |
| Stage | {BUILD_STAGE} |
| Building Phase | {BUILD_PHASE} |
| Started | {BUILD_STARTED} |
| Compactions | {BUILD_COMPACTIONS} |
| Input | {BUILD_INPUT} |

Pipeline:
{For each BUILD_PIPELINE row, show: stage -- status}

{If BUILD_INCOMPLETE has entries:}
Incomplete phases: {list from BUILD_INCOMPLETE}

---

### Build Result  (only show if BUILD_MODE=false AND HAS_BUILD_STATE=true)

/build completed with status: {BUILD_STATUS}

{If BUILD_STATUS=complete:} All phases built and validated successfully.
{If BUILD_STATUS=partial:} Build finished with some incomplete phases. Review BUILD-REPORT.md.
{If BUILD_STATUS=failed:} Build failed. Review BUILD-REPORT.md for errors.

---

### Sync Issues

- Directory `02.1-security-hardening` has no matching entry in ROADMAP.md
- ROADMAP.md Phase 3 has no matching directory
- STATE.md references Phase 7 which is not in ROADMAP.md
- Progress table lists "Phase 3" but it is not in the Phases checklist

---

### Phases

| # | Phase | Status | Steps | Plans |
|---|-------|--------|-------|-------|
| 1 | Foundation | ✓ done | - - - | 3/3 |
| 2 | Authentication | ▸ executing | D R P | 1/2 |
| 3 | API Layer | ○ planned | D · P | 0/1 |
| 4 | Dashboard | · upcoming | · · · | -- |

---
```

**Status indicators for the table:**
- `✓ done` -- phase complete
- `⚠ gaps` -- verification gaps found
- `▸ executing` -- plans exist, execution in progress
- `○ planned` -- plans created, not started
- `· upcoming` -- not yet planned

**Steps column:** `D` discuss | `R` research | `P` plan (`·` = not done, `- - -` = phase complete)

**Sync Issues block:** Only show if Phase 2 found issues. Omit entirely when clean.

**Add sections only if they have content:**

```
### Recent Work
- Phase {X}, Plan {Y}: {one-line summary from RECENT_SUMMARIES excerpt}
- Phase {X}, Plan {Z}: {one-line summary}

### Decisions
- {decision from STATE.md}

### Blockers
- {blocker from STATE.md}

### Security
| Severity | Count |
|----------|-------|
| Critical | {N} |
| High | {N} |
| Medium | {N} |
| Low | {N} |
```

Omit any section with no content.

**Append routing output from Phase 6.**

### Phase 6: Smart Routing

Use current phase status to determine routing. Append routing block after status report.

**If `BUILD_MODE=true`:** Skip normal routing. Use **Route F: Build In Progress** instead.

**If `BUILD_MODE=false` and `HAS_BUILD_STATE=true` and `BUILD_STATUS=partial`:** Use **Route G: Build Needs Attention** instead.

**Otherwise, routing priority (first match wins):**

| Current phase status | Route |
|----------------------|-------|
| `gaps` | Route E |
| `executing` or `planned` with unexecuted plans | Route A |
| `done` + more phases remain | Route C |
| `done` + last phase | Route D |
| `upcoming` (no plans) | Route B |

---

## Route Output Templates

Each route appends a `### Next` section to the status report. Use these exact formats:

### Route A: Execute Phase

Find first PLAN.md without matching SUMMARY.md. Use Read to get its objective if needed.

```
### Next

▸ **Execute Phase {N}** -- {objective from first unexecuted plan}

  /execute-phase {N}
```

### Route B: Plan Phase

Check PHASE_MAP context and research counts for the upcoming phase.

**If context=0 (no context gathered):**

```
### Next

▸ **Discuss Phase {N}: {Name}** -- clarify implementation decisions before planning

  /discuss-phase {N}

Alternative (plan without context):
  /plan-phase {N}
```

**If context>0 and research=0 (context gathered, no research):**

```
### Next

▸ **Research Phase {N}: {Name}** -- investigate ecosystem before planning

  /research-phase {N}

Alternative (plan without research):
  /plan-phase {N}
```

**If context>0 and research>0 (both gathered):**

```
### Next

▸ **Plan Phase {N}: {Name}** -- {goal from ROADMAP.md}

  /plan-phase {N}
```

### Route C: Next Phase

Current phase done, more remain. Show completion then route forward.

```
### Next

✓ Phase {Z} complete

▸ **Plan Phase {Z+1}: {Name}** -- {goal from ROADMAP.md}

  /plan-phase {Z+1}

**Refine interactively?**
  /code {Z} to start a coding session on Phase {Z}
```

### Route D: All Phases Complete

```
### Next

✓ All {N} phases complete

▸ **Define next phases** -- add new phases or start a new roadmap

  /create-roadmap
```

### Route E: Verification Gaps

```
### Next

⚠ Phase {N} verification found gaps

▸ **Plan fixes** -- create gap closure plans

  /plan-phase {N} --gaps
```

### Route: No Roadmap

PROJECT.md exists but no ROADMAP.md.

```
### Next

▸ **Create roadmap** -- define phases, goals, success criteria

  /create-roadmap
```

### Route: No Project

No .planning/ or no PROJECT.md.

```
### Next

▸ **Initialize project** -- define what you're building

  /new-project
```

### Route F: Build In Progress

/build is actively running. Do not suggest manual actions that would conflict.

```
### Next

▸ **/build is running autonomously**

Currently at stage: {BUILD_STAGE}
{If BUILD_PHASE != N/A: "Building phase: {BUILD_PHASE}"}
Compactions survived: {BUILD_COMPACTIONS}

The build is running without user intervention. You can:
  - Wait for it to complete
  - Check BUILD-STATE.md for detailed progress
  - Interrupt and resume later with: /build (auto-resumes)
```

### Route G: Build Needs Attention

/build finished but with issues.

```
### Next

⚠ **/build finished with status: {BUILD_STATUS}**

{If BUILD_STATUS=partial:}
  Some phases are incomplete. Review the report and fix remaining issues:
    cat .planning/BUILD-REPORT.md

  Options:
    /phase-feedback {N}   -- fix a specific incomplete phase
    /build                -- re-run to resume from where it left off

{If BUILD_STATUS=failed:}
  The build hit a blocking error. Review the report:
    cat .planning/BUILD-REPORT.md

  Fix the blocker, then:
    /build                -- auto-resumes from last position
```

## Edge Cases

**Blockers present:** Highlight blockers in status report before offering next action. Ask user if they want to address blockers first.

**Security audit exists with open findings:** Mention in status report. If critical/high findings exist and no corresponding phases in roadmap, suggest running `/add-security-findings` to integrate.

**Phase directory exists but no plans:** Treat as "phase not yet planned" (Route B).

## Success Criteria

- [ ] Planning structure validated
- [ ] Sync issues detected and reported when found
- [ ] Current position clear with recent work, decisions, blockers
- [ ] Build mode detected and reported when BUILD-STATE.md exists with in_progress status
- [ ] Smart routing provided based on project state (including build-aware routes)
- [ ] User knows exact next action
