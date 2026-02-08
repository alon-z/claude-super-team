---
name: progress
description: Check project progress and route to next action. Analyzes .planning/ files to show current position, recent work, key decisions, and intelligently routes to the appropriate next step (/new-project, /create-roadmap, /plan-phase, /execute-phase, etc.). Use when user asks "where am I?", "what's next?", returns to project after time away, or completes a phase and needs direction.
allowed-tools: Read, Bash, Grep, Glob
context: fork
model: haiku
---

## Objective

Present a comprehensive status report of project progress and intelligently route to the next action.

**This is a navigation and context skill** -- helps users understand where they are in the project flow and what to do next.

**Reads:** `.planning/PROJECT.md`, `ROADMAP.md`, `STATE.md`, `phases/*-PLAN.md`, `phases/*-SUMMARY.md`, `phases/*-VERIFICATION.md`, `SECURITY-AUDIT.md`

**Outputs:** Rich status report + smart routing recommendation

## Process

### Phase 1: Verify Planning Structure

Use Bash to check if `.planning/` directory exists:

```bash
test -d .planning && echo "exists" || echo "missing"
```

**If missing:**

```
No planning structure found.

Run /new-project to start a new project.
```

Exit skill.

**If exists, check for core files:**

```bash
[ -f .planning/PROJECT.md ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f .planning/STATE.md ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
```

**Route based on what exists:**

| Condition | Meaning | Action |
|-----------|---------|--------|
| No PROJECT.md | Brand new project | Show: "Run /new-project to initialize" |
| PROJECT.md but no ROADMAP.md | Project defined, needs roadmap | Go to **Route: Between Milestones** |
| PROJECT.md + ROADMAP.md + STATE.md | Active project | Continue to Phase 2 |

### Phase 2: Load Context

Read the following files (use Bash `test -f` to check existence first):

**Required:**
- `.planning/PROJECT.md` -- extract project name from "What This Is" section
- `.planning/ROADMAP.md` -- extract all phases with goals
- `.planning/STATE.md` -- extract current phase number, position, blockers

**Optional (check if exists):**
- `.planning/SECURITY-AUDIT.md` -- count findings by severity

### Phase 3: Gather Recent Work

Find the 2-3 most recent SUMMARY.md files across all phases:

```bash
find .planning/phases -name "*-SUMMARY.md" -type f 2>/dev/null | xargs ls -t | head -3
```

For each SUMMARY.md found, extract:
- Phase and plan number (from filename, e.g., `02-01-SUMMARY.md` = Phase 2, Plan 1)
- What was accomplished (brief, 1 line)

### Phase 4: Parse Current Position

From STATE.md, extract:
- Current phase number
- Current phase name
- Any blockers or concerns listed

Find current phase directory (zero-pad the phase number first):

```bash
# Zero-pad: "5" -> "05", "2.1" -> "02.1"
if echo "$PHASE_NUM" | grep -q '\.'; then
  INT_PART=$(echo "$PHASE_NUM" | cut -d. -f1)
  DEC_PART=$(echo "$PHASE_NUM" | cut -d. -f2)
  PADDED=$(printf "%02d.%s" "$INT_PART" "$DEC_PART")
else
  PADDED=$(printf "%02d" "$PHASE_NUM")
fi
PHASE_DIR=$(ls -d .planning/phases/${PADDED}-* 2>/dev/null | head -1)
```

### Phase 5: Build Phase Map

Parse ROADMAP.md to extract ALL phases. For each phase, zero-pad the number before looking up directories:

```bash
# CRITICAL: Phase directories use zero-padded names (e.g., 05-design-polish)
# but ROADMAP.md uses plain numbers (e.g., Phase 5). Always pad.
if echo "$PHASE_NUM" | grep -q '\.'; then
  # Decimal phase (e.g., 2.1 from inserted phases)
  INT_PART=$(echo "$PHASE_NUM" | cut -d. -f1)
  DEC_PART=$(echo "$PHASE_NUM" | cut -d. -f2)
  PADDED=$(printf "%02d.%s" "$INT_PART" "$DEC_PART")
else
  PADDED=$(printf "%02d" "$PHASE_NUM")
fi
PHASE_DIR=$(ls -d .planning/phases/${PADDED}-* 2>/dev/null | head -1)
```

For each phase directory found, check:

```bash
PLAN_COUNT=$(ls -1 "${PHASE_DIR}"/*-PLAN.md 2>/dev/null | wc -l)
SUMMARY_COUNT=$(ls -1 "${PHASE_DIR}"/*-SUMMARY.md 2>/dev/null | wc -l)
grep -l "status: gaps_found" "${PHASE_DIR}"/*-VERIFICATION.md 2>/dev/null
```

Assign each phase a status label:
- `done` -- all plans have matching summaries, verification passed or skipped
- `gaps` -- verification found gaps
- `executing` -- some summaries exist but not all
- `planned` -- plans exist, no summaries
- `current` -- the phase STATE.md points to (overlay on other statuses)
- `upcoming` -- no plans yet, not current

### Phase 6: Present Status Report

**Output the report exactly in this format.** Use the unicode characters shown. Compute the progress bar from total completed plans / total plans across all phases.

Build a progress bar: for each 10% of total plan completion, use `█`. For remaining, use `░`. Always 10 characters wide.

Example: 7 of 10 plans done = `███████░░░` 70%

```
# {Project Name}

**Progress:** {bar} {completed}/{total} plans
**Phase:** {current_phase_num} of {total_phases} -- {current_phase_name}

---

### Phases

| # | Phase | Status | Plans |
|---|-------|--------|-------|
| 1 | Foundation | ✓ done | 3/3 |
| 2 | Authentication | ▸ executing | 1/2 |
| 3 | API Layer | · upcoming | -- |
| 4 | Dashboard | · upcoming | -- |

---
```

**Status indicators for the table:**
- `✓ done` -- phase complete
- `⚠ gaps` -- verification gaps found
- `▸ executing` -- plans exist, execution in progress
- `○ planned` -- plans created, not started
- `· upcoming` -- not yet planned

**After the phase table, add sections only if they have content:**

```
### Recent Work
- Phase {X}, Plan {Y}: {one-line summary from SUMMARY.md}
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

Omit "Recent Work" if no summaries exist. Omit "Decisions" if none in STATE.md. Omit "Blockers" if none. Omit "Security" if no SECURITY-AUDIT.md.

**After all sections, add the routing output from Phase 7.**

### Phase 7: Smart Routing

Use the current phase status (from Phase 5 map) to determine routing. Append the routing block directly after the status report -- it is part of the same output.

**Routing priority (first match wins):**

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

Find first PLAN.md without matching SUMMARY.md. Read its objective.

```
### Next

▸ **Execute Phase {N}** -- {objective from first unexecuted plan}

  /execute-phase {N}
```

### Route B: Plan Phase

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
```

### Route D: All Phases Complete

```
### Next

✓ All {N} phases complete

▸ **Define next milestone** -- add phases or start new milestone

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

## Edge Cases

**Blockers present:** Highlight blockers in status report before offering next action. Ask user if they want to address blockers first.

**Security audit exists with open findings:** Mention in status report. If critical/high findings exist and no corresponding phases in roadmap, suggest running `/add-security-findings` to integrate.

**Phase directory exists but no plans:** Treat as "phase not yet planned" (Route B).

## Success Criteria

- [ ] `.planning/` structure validated
- [ ] Recent work identified (2-3 most recent summaries)
- [ ] Current position clear (phase, plan counts, blockers)
- [ ] Security findings counted if audit exists
- [ ] Smart routing determined based on project state
- [ ] Clear "Next Up" guidance provided
- [ ] User knows to run `/clear` before next action
