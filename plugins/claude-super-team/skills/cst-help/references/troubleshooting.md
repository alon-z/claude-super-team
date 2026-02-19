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

**Solution:**
- Run `/map-codebase` to analyze existing code
- Then run `/new-project` again

### Roadmap and State

#### "No ROADMAP.md found"

**Symptom:** Skills fail saying roadmap missing

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

**Solution:**
- Run `/discuss-phase N` to gather user decisions
- Then run `/plan-phase N` again

#### "RESEARCH.md missing, planner picks wrong libraries"

**Symptom:** Plans use outdated libraries or miss established patterns

**Solution:**
- Run `/research-phase N` to investigate ecosystem
- Then run `/plan-phase N` again

#### "Research agent not using Context7"

**Symptom:** Research takes long and only uses Firecrawl even for known libraries

**Cause:** Context7 may not have the library indexed, or the question is ecosystem discovery (expected Firecrawl usage)

**Solution:**
- Context7 is used for specific named library documentation (e.g., "how to configure SSO in better-auth")
- Firecrawl is expected for ecosystem discovery questions (e.g., "best auth library for Next.js")
- If Context7 can't resolve a library, the agent automatically falls back to Firecrawl -- this is normal
- Check RESEARCH.md metadata section for `Context7 libraries queried` count

#### "Research found conflicts with CONTEXT.md decisions"

**Symptom:** `/research-phase` reports chosen libraries are deprecated or better alternatives exist

**Solution:**
- Re-run `/discuss-phase N` to update decisions with research insights
- Then run `/plan-phase N` with updated CONTEXT.md and RESEARCH.md

#### "Plans reference wrong files or paths"

**Symptom:** Generated plans mention non-existent files

**Cause:** Planner lacked codebase context

**Solution:**
- For brownfield: Ensure `/map-codebase` was run before `/plan-phase`
- Check `.planning/codebase/STRUCTURE.md` for correct paths
- Re-run `/plan-phase N` after mapping

### Phase Execution

#### "Branch guard blocks execution"

**Symptom:** `/execute-phase` warns about running on main/master

**Solution:**
- Switch to a feature branch: `git checkout -b feature/phase-N`
- Re-run `/execute-phase N`
- Or choose "Continue anyway" to work on main intentionally

#### "Wrong execution mode"

**Symptom:** `/execute-phase` runs in unexpected mode (task vs teams)

**Solution:**
- For teams mode: `/execute-phase N --team` or set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Check execution start message for mode and how to change it
- Single-plan waves auto-downgrade to task mode (expected)

#### "Cannot execute, no plans found"

**Symptom:** `/execute-phase N` fails with no PLAN.md files

**Solution:**
```
/plan-phase N
/execute-phase N
```

#### "Verification found gaps"

**Symptom:** Phase marked with `status: gaps_found` in VERIFICATION.md

**Solution:**
```
/plan-phase N --gaps          # Create gap closure plans
/execute-phase N --gaps-only  # Execute only gap plans
```

#### "Wave dependencies unclear"

**Symptom:** Plans execute in wrong order or block each other

**Solution:**
- Read plan files in `.planning/phases/{NN}-{name}/*-PLAN.md`
- Check wave assignments and dependencies
- Edit PLAN.md wave numbers if needed
- Re-run `/execute-phase N`

#### "Execute-phase lost track after compaction"

**Symptom:** Orchestrator confused about which wave/plan to execute after a long run

**Solution:**
- EXEC-PROGRESS.md and hooks handle this automatically
- Adjust `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` if needed (lower = earlier compaction, more headroom)

#### "How to configure compaction threshold"

**Symptom:** Compaction happens at wrong time during execute-phase

**Solution:**
- Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` environment variable (1-100)
- Lower values = earlier compaction with more headroom
- Start with 50-60 for large phases, adjust based on behavior

### Decimal Phase Insertion

#### "Decimal phase doesn't appear in order"

**Symptom:** Phase 02.1 appears after phase 03 in listings

**Solution:**
- Ensure ROADMAP.md lists phases in numeric order (2, 2.1, 3)
- Zero-padded directory names auto-sort correctly (02.1-name)

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

#### "/progress shows sync issues"

**Symptom:** Progress report shows "Sync Issues" warning block

**Solution:**
- Read specific warnings to identify sync problems
- Orphan directories: add phase to ROADMAP.md or delete directory
- Missing directories: create directory or remove phase from ROADMAP.md
- STATE.md drift: update STATE.md to reference valid phase
- Progress table issues: sync table entries with phases checklist
- Run `/progress` again to verify resolution

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

**Solution:**
- Rename: `mv .planning/phases/5-design .planning/phases/05-design`
- Always use zero-padded format (01, 02, ..., 10, 11)

#### "Multiple VERIFICATION.md files"

**Symptom:** More than one verification file in phase directory

**Solution:**
- Keep only the latest verification file
- Delete or consolidate others

#### "CONTEXT.md in wrong location"

**Symptom:** CONTEXT.md outside phase directory

**Solution:**
- Move to `.planning/phases/{NN}-{name}/{NN}-CONTEXT.md`
- Use naming pattern `{NN}-CONTEXT.md` (e.g., `02-CONTEXT.md`)

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

**Solution:**
- Read agent output for specific error
- Fix underlying issue (missing files, syntax errors)
- Re-run the skill

#### "Plans execute but produce no summaries"

**Symptom:** SUMMARY.md files missing after execution

**Solution:**
- Check terminal for error logs
- Verify work was completed
- Re-run `/execute-phase N` if incomplete

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

**Solution:**
- Check git diff for simplifier's commit
- Revert specific behavior-changing edits
- Note: Simplifier is instructed to preserve all functionality

### Brainstorming

#### "No project found" when running /brainstorm

**Symptom:** `/brainstorm` fails saying no PROJECT.md exists

**Solution:**
```
/new-project <project idea>
/brainstorm
```

#### "Autonomous mode agents return empty results"

**Symptom:** Analysis agents produce no useful output

**Solution:**
- Ensure PROJECT.md has substantive content
- Run `/map-codebase` first for brownfield projects
- Try Interactive mode for early-stage projects

#### "Brainstorm didn't create CONTEXT.md for new phases"

**Symptom:** `/brainstorm` added phases to roadmap but no CONTEXT.md files generated

**Solution:**
- Context generation only runs when roadmap update completes within brainstorm
- Run `/discuss-phase N` manually for each new phase for full exploration
- Auto-generated CONTEXT.md is a starting point; `/discuss-phase` provides deeper coverage

#### "IDEAS.md keeps growing with duplicate sessions"

**Symptom:** Multiple brainstorming sessions add overlapping ideas

**Solution:**
- Edit IDEAS.md to consolidate
- Remove superseded sessions
- Track approved ideas in ROADMAP.md

### Build Automation

#### "/build stopped or seems stuck"

**Symptom:** `/build` stopped mid-pipeline or appears to have stalled

**Solution:**
- Check `.planning/BUILD-STATE.md` to see exactly where the pipeline stopped
- Re-invoke `/build` -- it reads BUILD-STATE.md and auto-resumes from the last completed step
- If BUILD-STATE.md is missing or corrupt, start fresh with a new `/build` invocation

#### "BUILD-STATE.md shows incomplete phases"

**Symptom:** BUILD-STATE.md lists phases as incomplete after `/build` finished

**Solution:**
- Review `.planning/BUILD-REPORT.md` for details on what succeeded and what failed
- Use `/phase-feedback` manually on incomplete phases to address remaining issues
- Run `/progress` to see overall project state

#### "Build preferences not being used"

**Symptom:** `/build` ignores tech stack or style preferences

**Solution:**
- Check file locations: `~/.claude/build-preferences.md` (global) or `.planning/build-preferences.md` (per-project)
- Ensure the file uses plain markdown with clear preference declarations
- Per-project preferences override global preferences

#### "Git branch conflicts during squash-merge"

**Symptom:** `/build` reports merge conflicts when squash-merging phase branches

**Solution:**
- `/build` operates locally and never pushes -- check `git status` for conflict markers
- Resolve conflicts manually, then re-invoke `/build` to continue from where it stopped
- If needed, use `git log --oneline --graph` to understand branch state

### Interactive Coding

#### "When to use /code vs /phase-feedback"

`/code` is for interactive back-and-forth coding sessions where you describe changes conversationally. `/phase-feedback` is for structured feedback that needs the planning/research/execution pipeline. Use `/code` when you want to iterate quickly; use `/phase-feedback` when changes are substantial enough to warrant a subphase with plans.

#### "Session log not found"

**Symptom:** Can't find session log after `/code` session

**Solution:**
- Check `.planning/.sessions/` directory
- Sessions are named `{YYYY-MM-DD-HHMM}-{slug}.md`
- Note: `.planning/.sessions/` is gitignored by default

### Quick Plan and Phase Feedback

#### "/quick-plan inserts phase at wrong position"

**Symptom:** Phase 4.1 created but currently on phase 2

**Solution:**
- Review insertion position question carefully
- Decimal phases can insert anywhere, not just after current phase

#### "/phase-feedback creates duplicate work"

**Symptom:** Feedback subphase overlaps with main phase tasks

**Solution:**
- Be specific in feedback about what to change
- Use `/phase-feedback` for modifications, not new features
- Use `/quick-plan` for new features

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
- Planning files might be out of sync (after manual edits or interrupted skills)

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
- Optionally use `--skip-verify` to skip verification, `--team` for teams mode
- Note: warns if on main/master branch. Requires code-simplifier plugin for post-task code refinement
- Compaction resilient: hooks preserve execution state for long-running sessions. Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` for large phases

### Use `/quick-plan` when:
- Need to insert urgent work (bug fix, small feature)
- Don't want full phase ceremony
- Want lightweight planning (1-3 tasks)

### Use `/phase-feedback` when:
- Just finished executing a phase
- Want changes to delivered work
- Need to iterate on completed phase

### Use `/code` when:
- Want direct changes without planning overhead
- Quick iteration on specific files or features
- Ad-hoc fixes, experiments, or exploratory coding
- Conversational phase refinement after execution
- Prefer back-and-forth over structured pipeline

### Use `/brainstorm` when:
- Exploring what to build next
- Evaluating new features, improvements, or architectural changes
- Want Claude to autonomously analyze the project for opportunities
- Need a structured way to capture and decide on ideas
- Want to feed approved ideas directly into the roadmap

### Use `/build` when:
- Want full automation from idea to working code with zero intervention
- Starting a greenfield project and want the entire pipeline handled autonomously
- Want to let Claude make all implementation decisions end-to-end
- Need compaction-resilient, resumable full-pipeline execution

### Use `/add-security-findings` when:
- Have security audit results
- Want to integrate findings into roadmap
- Need to plan security remediation
- After a security scan or analysis

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
1. Let skills run to completion (do not interrupt)
2. Code-simplifier runs automatically after each plan's tasks complete
3. Review SUMMARY.md files after execution (reflects post-simplification state)
4. Check VERIFICATION.md for gaps

### After Phases
1. Always run `/progress` to see where you are
2. Follow smart routing recommendations
3. Address blockers before continuing

### Maintenance
1. Keep STATE.md and ROADMAP.md in sync
2. Do not manually edit state files unless necessary
3. Use zero-padded directory names (01, 02, not 1, 2)
4. Commit planning files regularly
