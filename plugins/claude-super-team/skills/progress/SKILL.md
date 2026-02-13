---
name: progress
description: Check project progress and route to next action. Analyzes .planning/ files to show current position, recent work, key decisions, and intelligently routes to the appropriate next step (/new-project, /create-roadmap, /plan-phase, /execute-phase, etc.). Use when user asks "where am I?", "what's next?", returns to project after time away, or completes a phase and needs direction.
allowed-tools: Read, Grep, Glob, Bash(test *), Bash(ls *), Bash(find *), Bash(grep *)
context: fork
model: haiku
---

<!-- Dynamic context injection: pre-load project state for faster analysis -->
!`ls .planning/ 2>/dev/null`
!`ls -d .planning/phases/*/ 2>/dev/null`
!`cat .planning/STATE.md 2>/dev/null | head -20`

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

### Phase 2: Detect Planning File Sync Issues

**Only runs when all three core files exist.** Performs three sync checks using Bash/Grep:

**Check 1: Directory vs Roadmap**

List all phase directories and extract phase numbers. Parse all phases from ROADMAP.md. Compare:

```bash
# Get phase numbers from directories
ls -d .planning/phases/*/ 2>/dev/null | sed 's|.*/\([0-9.]*\)-.*|\1|' | sed 's/^0//' | sort -V

# Get phase numbers from ROADMAP.md Phases checklist
grep -oP '(?<=Phase )\d+(\.\d+)?' .planning/ROADMAP.md | sort -V
```

Report:
- **Orphan directories**: directories without a matching ROADMAP.md entry
- **Missing directories**: ROADMAP.md phases without a matching directory

**Check 2: STATE.md Drift**

Extract the current phase number from STATE.md. Verify it matches a phase listed in ROADMAP.md and has a corresponding directory:

```bash
# Get current phase from STATE.md
grep -oP '(?<=Current Phase:\s)\d+(\.\d+)?' .planning/STATE.md

# Check if that phase exists in ROADMAP.md and has a directory
```

Report if the STATE.md phase number is not found in ROADMAP.md or has no matching directory.

**Check 3: Progress Table Inconsistencies**

Parse phase entries from the ROADMAP.md "## Progress" table and from the "## Phases" checklist. Compare:

```bash
# Get phases from Progress table (if it exists)
grep -oP '(?<=Phase )\d+(\.\d+)?' .planning/ROADMAP.md  # within ## Progress section

# Get phases from Phases checklist
grep -oP '(?<=Phase )\d+(\.\d+)?' .planning/ROADMAP.md  # within ## Phases section
```

Report:
- Progress table entries with no matching Phases checklist entry
- Phases checklist entries missing from the Progress table

**Collect all issues found.** Store for output in Phase 7 if any exist, otherwise omit entirely.

### Phase 3: Load Context

Read the following files (use Bash `test -f` to check existence first):

**Required:**
- `.planning/PROJECT.md` -- extract project name from "What This Is" section
- `.planning/ROADMAP.md` -- extract all phases with goals
- `.planning/STATE.md` -- extract current phase number, position, blockers

**Optional (check if exists):**
- `.planning/SECURITY-AUDIT.md` -- count findings by severity

### Phase 4: Gather Recent Work

Find the 2-3 most recent SUMMARY.md files across all phases:

```bash
find .planning/phases -name "*-SUMMARY.md" -type f 2>/dev/null | xargs ls -t | head -3
```

For each SUMMARY.md found, extract:
- Phase and plan number (from filename, e.g., `02-01-SUMMARY.md` = Phase 2, Plan 1)
- What was accomplished (brief, 1 line)

### Phase 5: Parse Current Position

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

**Check for CONTEXT.md and RESEARCH.md in current phase directory:**

```bash
[ -n "$PHASE_DIR" ] && ls "${PHASE_DIR}"/*-CONTEXT.md 2>/dev/null && echo "HAS_CONTEXT=true" || echo "HAS_CONTEXT=false"
[ -n "$PHASE_DIR" ] && ls "${PHASE_DIR}"/*-RESEARCH.md 2>/dev/null && echo "HAS_RESEARCH=true" || echo "HAS_RESEARCH=false"
```

### Phase 6: Build Phase Map

Parse ROADMAP.md to extract ALL phases. For each phase, zero-pad the number before looking up directories:

```bash
# Phase directories use zero-padded names (05-design-polish)
# ROADMAP.md uses plain numbers (Phase 5). Always pad before lookup.
if echo "$PHASE_NUM" | grep -q '\.'; then
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
HAS_CONTEXT=$(ls "${PHASE_DIR}"/*-CONTEXT.md 2>/dev/null | wc -l)
HAS_RESEARCH=$(ls "${PHASE_DIR}"/*-RESEARCH.md 2>/dev/null | wc -l)
HAS_PLANS=$(ls -1 "${PHASE_DIR}"/*-PLAN.md 2>/dev/null | wc -l)
```

Assign each phase a status label:
- `done` -- all plans have matching summaries, verification passed or skipped
- `gaps` -- verification found gaps
- `executing` -- some summaries exist but not all
- `planned` -- plans exist, no summaries
- `current` -- the phase STATE.md points to (overlay on other statuses)
- `upcoming` -- no plans yet, not current

### Phase 7: Present Status Report

**Output the report in this format.** Build a progress bar: for each 10% of completion, use `█`. For remaining, use `░`. Always 10 characters wide.

Example: 7 of 10 plans done = `███████░░░` 70%

```
# {Project Name}

**Progress:** {bar} {completed}/{total} plans
**Phase:** {current_phase_num} of {total_phases} -- {current_phase_name}

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

Omit any section with no content.

**Append routing output from Phase 8.**

### Phase 8: Smart Routing

Use current phase status to determine routing. Append routing block after status report.

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

Check if CONTEXT.md and RESEARCH.md exist for the upcoming phase (from Phase 5 map).

**If CONTEXT_EXISTS=false (no context gathered):**

```
### Next

▸ **Discuss Phase {N}: {Name}** -- clarify implementation decisions before planning

  /discuss-phase {N}

Alternative (plan without context):
  /plan-phase {N}
```

**If CONTEXT_EXISTS=true and HAS_RESEARCH=false (context gathered, no research):**

```
### Next

▸ **Research Phase {N}: {Name}** -- investigate ecosystem before planning

  /research-phase {N}

Alternative (plan without research):
  /plan-phase {N}
```

**If CONTEXT_EXISTS=true and HAS_RESEARCH=true (both gathered):**

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

- [ ] Planning structure validated
- [ ] Sync issues detected and reported when found
- [ ] Current position clear with recent work, decisions, blockers
- [ ] Smart routing provided based on project state
- [ ] User knows exact next action
