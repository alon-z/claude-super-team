---
name: progress
description: Check project progress and route to next action. Analyzes .planning/ files to show current position, recent work, key decisions, and intelligently routes to the appropriate next step (/new-project, /create-roadmap, /plan-phase, /execute-phase, etc.). Use when user asks "where am I?", "what's next?", returns to project after time away, or completes a phase and needs direction.
allowed-tools: Read, Grep, Glob
context: fork
model: haiku
---

<!-- Dynamic context injection: pre-load core planning files -->
!`cat .planning/PROJECT.md 2>/dev/null`
!`cat .planning/ROADMAP.md 2>/dev/null`
!`cat .planning/STATE.md 2>/dev/null`
!`cat .planning/SECURITY-AUDIT.md 2>/dev/null | head -20`

<!-- Structure: which planning files exist -->
!`echo "=== STRUCTURE ==="; P=.planning; [ -d "$P" ] && echo "PLANNING_DIR=exists" || echo "PLANNING_DIR=missing"; [ -f "$P/PROJECT.md" ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"; [ -f "$P/ROADMAP.md" ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"; [ -f "$P/STATE.md" ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"; [ -f "$P/SECURITY-AUDIT.md" ] && echo "HAS_SECURITY=true" || echo "HAS_SECURITY=false"`

<!-- Phase map: per-phase plan/summary/gap/context/research counts -->
!`echo "=== PHASE_MAP ==="; for dir in .planning/phases/*/; do [ -d "$dir" ] || continue; n=$(basename "$dir"); p=$(find "$dir" -maxdepth 1 -name "*-PLAN.md" 2>/dev/null | wc -l | tr -d " "); s=$(find "$dir" -maxdepth 1 -name "*-SUMMARY.md" 2>/dev/null | wc -l | tr -d " "); g=$(grep -l "status: gaps_found" "${dir}"*-VERIFICATION.md 2>/dev/null | wc -l | tr -d " "); c=$(find "$dir" -maxdepth 1 -name "*-CONTEXT.md" 2>/dev/null | wc -l | tr -d " "); r=$(find "$dir" -maxdepth 1 -name "*-RESEARCH.md" 2>/dev/null | wc -l | tr -d " "); echo "$n|plans=$p|summaries=$s|gaps=$g|context=$c|research=$r"; done 2>/dev/null`

<!-- Recent summaries: 3 most recent with excerpts -->
!`echo "=== RECENT_SUMMARIES ==="; find .planning/phases -name "*-SUMMARY.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -3 | while IFS= read -r f; do rel=${f#.planning/phases/}; exc=$(grep -m1 -vE "^(#|---|[[:space:]]*$)" "$f" 2>/dev/null | head -c 120); echo "$rel|$exc"; done`

<!-- Sync check: pre-computed phase number lists for sync issue detection -->
!`echo "=== SYNC_CHECK ==="; echo -n "DIR_PHASES: "; for dir in .planning/phases/*/; do [ -d "$dir" ] || continue; basename "$dir" | sed 's/^\([0-9.]*\)-.*/\1/' | sed 's/^0*//'; done 2>/dev/null | sort -V | tr '\n' ' '; echo; echo -n "ROADMAP_PHASES: "; grep -oE 'Phase [0-9]+(\.[0-9]+)?' .planning/ROADMAP.md 2>/dev/null | awk '{print $2}' | sort -V | uniq | tr '\n' ' '; echo; echo -n "STATE_PHASE: "; grep -E '^Phase:' .planning/STATE.md 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1; grep -E '^\s*- \[x\] Phase' .planning/ROADMAP.md 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "CHECKED: %s\n", $2}'; grep -E '^\s*- \[ \] Phase' .planning/ROADMAP.md 2>/dev/null | grep -oE 'Phase [0-9]+(\.[0-9]+)?' | awk '{printf "UNCHECKED: %s\n", $2}'`

<!-- Git: recent commits, branch, dirty count -->
!`echo "=== GIT ==="; git log --oneline -5 2>/dev/null || echo "(no git)"; echo "---"; echo "BRANCH=$(git branch --show-current 2>/dev/null || echo detached)"; echo "DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d " ")"`

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
| All three `true` | Active project | Continue to Phase 2 |

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
