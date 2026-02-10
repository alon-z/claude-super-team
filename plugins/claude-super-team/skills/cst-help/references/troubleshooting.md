# Troubleshooting Guide

## Common Issues and Solutions

### Project Initialization

#### "Project already initialized"

**Symptom:** `/new-project` fails with error about existing PROJECT.md

**Cause:** `.planning/PROJECT.md` already exists

**Solution:**
- If starting fresh: Delete `.planning/` and run `/new-project` again
- If continuing: Skip `/new-project`, use `/progress` to see where you are

#### "No codebase map but code detected"

**Symptom:** `/new-project` detects code but you skipped mapping

**Cause:** Brownfield project without codebase analysis

**Solution:**
- Run `/map-codebase` to analyze existing code
- Then run `/new-project` again for better context

### Roadmap and State

#### "No ROADMAP.md found"

**Symptom:** Skills fail saying roadmap missing

**Cause:** Haven't run `/create-roadmap` yet

**Solution:**
```
/create-roadmap
```

#### "STATE.md points to non-existent phase"

**Symptom:** Current phase number in STATE.md doesn't match ROADMAP.md

**Cause:** Manual edit or phase deletion without state update

**Solution:**
- Read `.planning/STATE.md` and `.planning/ROADMAP.md`
- Update STATE.md current phase to match a valid phase from ROADMAP.md
- Or run `/progress` to diagnose and suggest fixes

### Phase Planning

#### "Phase directory doesn't exist"

**Symptom:** `/plan-phase N` fails, no phase directory found

**Cause:** Phase N not defined in ROADMAP.md or directory naming mismatch

**Solution:**
- Check `.planning/ROADMAP.md` for phase N
- If phase exists but directory missing: Create `.planning/phases/{NN}-{name}/`
- If phase doesn't exist: Add it with `/create-roadmap` (pass modification intent)

#### "CONTEXT.md missing, planning struggles"

**Symptom:** Plans lack clarity or miss implementation decisions

**Cause:** Skipped `/discuss-phase` before planning

**Solution:**
- Run `/discuss-phase N` to gather user decisions first
- Then run `/plan-phase N` again

#### "RESEARCH.md missing, planner picks wrong libraries"

**Symptom:** Plans use outdated libraries or miss established patterns

**Cause:** Skipped `/research-phase` before planning

**Solution:**
- Run `/research-phase N` to investigate ecosystem
- Then run `/plan-phase N` again

#### "Research found conflicts with CONTEXT.md decisions"

**Symptom:** `/research-phase` reports that chosen libraries are deprecated or better alternatives exist

**Cause:** Decisions made during `/discuss-phase` were based on incomplete or outdated information

**Solution:**
- Re-run `/discuss-phase N` to update decisions with research insights
- The updated CONTEXT.md will have research-informed choices
- Then run `/plan-phase N` with both CONTEXT.md and RESEARCH.md

#### "Plans reference wrong files or paths"

**Symptom:** Generated plans mention non-existent files

**Cause:** Planner lacked codebase context

**Solution:**
- For brownfield: Ensure `/map-codebase` was run before `/plan-phase`
- Check `.planning/codebase/STRUCTURE.md` for correct paths
- Re-run `/plan-phase N` after mapping

### Phase Execution

#### "Cannot execute, no plans found"

**Symptom:** `/execute-phase N` fails with no PLAN.md files

**Cause:** Haven't run `/plan-phase N` yet

**Solution:**
```
/plan-phase N
/execute-phase N
```

#### "Verification found gaps"

**Symptom:** Phase marked with `status: gaps_found` in VERIFICATION.md

**Cause:** Phase goal not fully achieved (expected, not an error)

**Solution:**
```
/plan-phase N --gaps          # Creates gap closure plans
/execute-phase N --gaps-only  # Executes only gap plans
```

#### "Wave dependencies unclear"

**Symptom:** Plans execute in wrong order or block each other

**Cause:** Planner assigned waves incorrectly

**Solution:**
- Read plan files (`.planning/phases/{NN}-{name}/*-PLAN.md`)
- Check wave assignments and dependencies
- Edit PLAN.md files if needed (update wave numbers)
- Re-run `/execute-phase N`

### Decimal Phase Insertion

#### "Decimal phase doesn't appear in order"

**Symptom:** Phase 02.1 appears after phase 03 in listings

**Cause:** Directory sorting or ROADMAP.md ordering

**Solution:**
- Ensure ROADMAP.md lists phases in numeric order (2, 2.1, 3)
- Directory names auto-sort correctly if zero-padded (02.1-name)

#### "Conflicting decimal phases"

**Symptom:** Multiple phases with same decimal (e.g., two 02.1 phases)

**Cause:** Multiple insertions without coordination

**Solution:**
- Manually edit ROADMAP.md to renumber (2.1, 2.2, 2.3)
- Rename directories to match (02.1-first, 02.2-second)
- Update STATE.md if current phase affected

### Progress and Routing

#### "/progress shows wrong status"

**Symptom:** Progress report doesn't match actual state

**Cause:** Inconsistent file states (plans without summaries, etc.)

**Solution:**
- Manually check `.planning/phases/` directories
- Ensure each PLAN.md has matching SUMMARY.md if executed
- Ensure VERIFICATION.md exists if phase complete

#### "/progress routes to wrong skill"

**Symptom:** Next action suggestion doesn't make sense

**Cause:** State files inconsistent or unexpected project structure

**Solution:**
- Run `/progress` and review status sections
- Manually fix inconsistencies (add missing files, update STATE.md)
- Run `/progress` again

### File Structure Issues

#### "Phase directory naming mismatch"

**Symptom:** Phase 5 directory named `5-design` instead of `05-design`

**Cause:** Manual creation without zero-padding

**Solution:**
- Rename directory: `mv .planning/phases/5-design .planning/phases/05-design`
- Skills expect zero-padded format (01, 02, ..., 10, 11)

#### "Multiple VERIFICATION.md files"

**Symptom:** More than one verification file in phase directory

**Cause:** Manual duplication or re-runs without cleanup

**Solution:**
- Keep only the latest verification file
- Delete others or consolidate into one

#### "CONTEXT.md in wrong location"

**Symptom:** CONTEXT.md outside phase directory

**Cause:** Manual file move or skill bug

**Solution:**
- Move to `.planning/phases/{NN}-{name}/{NN}-CONTEXT.md`
- Follow naming pattern: `{NN}-CONTEXT.md` (e.g., `02-CONTEXT.md`)

### Security Integration

#### "Security findings not in roadmap"

**Symptom:** `.planning/SECURITY-AUDIT.md` exists but no security phases

**Cause:** Audit created but not integrated

**Solution:**
```
/add-security-findings
```

### Agent and Execution Errors

#### "Agent task failed or timed out"

**Symptom:** Task tool returns error during planning/execution

**Cause:** Agent encountered unexpected state or constraint

**Solution:**
- Read agent output for specific error
- Fix underlying issue (missing files, syntax errors, etc.)
- Re-run the skill

#### "Plans execute but produce no summaries"

**Symptom:** SUMMARY.md files missing after execution

**Cause:** Agent execution failed silently or was interrupted

**Solution:**
- Check for error logs in terminal
- Manually verify work was done
- If work incomplete: re-run `/execute-phase N`

### Code Simplification

#### "code-simplifier agent not found"

**Symptom:** `/execute-phase` fails when spawning code-simplifier agent

**Cause:** `code-simplifier` plugin not installed

**Solution:**
```
/plugin install code-simplifier@claude-plugins-official
```

#### "Simplifier changed behavior"

**Symptom:** Code works differently after simplification pass

**Cause:** Simplifier made changes beyond cosmetic refinement (rare)

**Solution:**
- Check git diff for the simplifier's commit
- Revert specific changes that affected behavior
- Re-run `/execute-phase N` -- the simplifier is instructed to preserve all functionality

### Brainstorming

#### "No project found" when running /brainstorm

**Symptom:** `/brainstorm` fails saying no PROJECT.md exists

**Cause:** Project not initialized yet

**Solution:**
```
/new-project <project idea>
```
Then run `/brainstorm` after project is defined.

#### "Autonomous mode agents return empty results"

**Symptom:** One or more analysis agents produce no useful output

**Cause:** Codebase is very small or project context is minimal

**Solution:**
- Ensure `.planning/PROJECT.md` has substantive content
- Run `/map-codebase` first for brownfield projects
- Try Interactive mode instead for early-stage projects

#### "IDEAS.md keeps growing with duplicate sessions"

**Symptom:** Multiple brainstorming sessions add overlapping ideas

**Cause:** Each session prepends to IDEAS.md without deduplication

**Solution:**
- Edit `.planning/IDEAS.md` manually to consolidate
- Remove older sessions that have been superseded
- Approved ideas should be tracked in ROADMAP.md, not just IDEAS.md

### Quick Plan and Phase Feedback

#### "/quick-plan inserts phase at wrong position"

**Symptom:** Phase 4.1 created but currently on phase 2

**Cause:** User specified insertion position manually

**Solution:**
- Quick-plan asks where to insert -- review the question carefully
- Decimal phases can go anywhere (not just after current)

#### "/phase-feedback creates duplicate work"

**Symptom:** Feedback subphase overlaps with main phase tasks

**Cause:** Feedback requests too broad or unclear

**Solution:**
- Be specific about what to change in feedback
- Use `/phase-feedback` for modifications, not new features
- For new features: use `/quick-plan` instead

## Diagnostic Commands

### Check project state
```bash
# Verify core files exist
ls -la .planning/{PROJECT,ROADMAP,STATE}.md

# Check phase directories
ls -la .planning/phases/

# Count plans vs summaries
find .planning/phases -name "*-PLAN.md" | wc -l
find .planning/phases -name "*-SUMMARY.md" | wc -l
```

### Validate phase structure
```bash
# For phase N (e.g., 02)
PHASE=02
ls -la .planning/phases/${PHASE}-*/

# Check for verification
ls -la .planning/phases/${PHASE}-*/*-VERIFICATION.md
```

### Check current state
```bash
# Current phase from STATE.md
grep "Current Phase:" .planning/STATE.md

# Phase completion from ROADMAP.md
grep -A 2 "^## Phase" .planning/ROADMAP.md
```

## When to Use Each Skill

### Use `/progress` when:
- Returning to project after time away
- Just completed a phase
- Unsure what to do next
- Want to see overall status

### Use `/new-project` when:
- Starting a brand new project
- No `.planning/PROJECT.md` exists
- Want to define project vision

### Use `/create-roadmap` when:
- PROJECT.md exists but no ROADMAP.md
- Want to add new phases to existing roadmap
- Need to reorder or restructure phases

### Use `/discuss-phase` when:
- About to plan a phase with multiple valid approaches
- Implementation decisions need user input
- Want to clarify technical choices before planning
- Want codebase-grounded gray areas instead of generic questions
- `/research-phase` found conflicts with prior decisions (re-discuss to update)

### Use `/research-phase` when:
- Phase involves unfamiliar technology or domain
- Need to choose between libraries/frameworks
- Want to understand current best practices and pitfalls
- Building something with multiple valid architecture approaches
- `/discuss-phase` recommended it (after creating CONTEXT.md)

### Use `/plan-phase` when:
- Phase is defined in roadmap
- Ready to break phase into executable plans
- Optionally: use `--gaps` for fixing verification failures

### Use `/execute-phase` when:
- Plans exist for the phase
- Ready to execute work
- Optionally: use `--skip-verify` to skip verification
- Note: requires `code-simplifier` plugin for post-task code refinement

### Use `/quick-plan` when:
- Need to insert urgent work (bug fix, small feature)
- Don't want full phase ceremony
- Want lightweight planning (1-3 tasks)

### Use `/phase-feedback` when:
- Just finished executing a phase
- Want changes to delivered work
- Need to iterate on completed phase

### Use `/brainstorm` when:
- Exploring what to build next
- Evaluating new features, improvements, or architectural changes
- Want Claude to autonomously analyze the project for opportunities
- Need a structured way to capture and decide on ideas
- Want to feed approved ideas directly into the roadmap

### Use `/add-security-findings` when:
- Have security audit results
- Want to integrate findings into roadmap
- Need to plan security remediation

## Best Practices

### Before Starting
1. Run `/new-project` with a clear vision document
2. For brownfield: run `/map-codebase` first
3. Review PROJECT.md before continuing

### During Planning
1. Use `/discuss-phase` for complex phases
2. Run `/research-phase` after discussion -- if research finds conflicts with decisions, re-run `/discuss-phase` to update
3. Don't skip context gathering
4. Review PLAN.md files before execution

### During Execution
1. Let skills run to completion (don't interrupt)
2. Code-simplifier runs automatically after each plan's tasks complete
3. Review SUMMARY.md files after execution (reflects post-simplification state)
4. Check VERIFICATION.md for gaps

### After Phases
1. Always run `/progress` to see where you are
2. Follow smart routing recommendations
3. Address blockers before continuing

### Maintenance
1. Keep STATE.md and ROADMAP.md in sync
2. Don't manually edit state files unless necessary
3. Use zero-padded directory names (01, 02, not 1, 2)
4. Commit planning files regularly
