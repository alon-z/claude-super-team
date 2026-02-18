# Research for Phase 8: Full Auto Mode

## User Constraints

### Locked Decisions

- **Adaptive Pipeline Depth**: LLM decides per-phase whether to run full pipeline (discuss->research->plan->execute) or skip discuss/research. Simple phases skip; complex phases get full treatment. /brainstorm always runs. /map-codebase always runs for brownfield.
- **Skill Tool Invocation**: Invoke all chained skills via the Skill tool (same session, shared context). Context compaction handles window pressure. May iterate to hybrid (Skill + Task) later.
- **LLM Reasoning**: Before each skill invocation, /build uses LLM reasoning for autonomous AskUserQuestion answers based on project context and build preferences.
- **Log and Continue on Ambiguity**: When truly ambiguous, pick best guess and log as "low confidence" in BUILD-STATE.md.
- **Dynamic Input**: $ARGUMENTS accepts inline idea string, file path to PRD, or combination. Auto-detect file paths.
- **Build Preferences File**: `~/.claude/build-preferences.md` (global) and `.planning/build-preferences.md` (per-project). Both optional.
- **One Feedback Attempt**: After phase fails verification, run one /phase-feedback cycle. If still fails, mark incomplete and continue.
- **Skip and Continue**: Failed phases logged in BUILD-STATE.md, marked "incomplete" in ROADMAP.md, proceed to next phase.
- **Adaptive Validation**: LLM judges which phases warrant build/test validation. Always runs after final phase.
- **Auto-Fix on Final Failure**: 3-attempt fix loop on final build/test failure.
- **Git Autonomy**: Feature branch per phase execution (build/{phase-name}), auto-commit during execution, squash-merge to main on phase completion, never push to origin. Planning work happens on main before execution.
- **Auto-Resume**: /build auto-resumes from BUILD-STATE.md on re-invocation.
- **Current Directory Only**: No target directory argument.

### Claude's Discretion

- BUILD-STATE.md format and structure
- build-preferences.md structure and sections
- File path vs inline text detection heuristic
- Adaptive pipeline depth heuristic
- Adaptive validation heuristic
- Feature branch naming convention
- Squash-merge commit message format
- How /build interacts with skills' own AskUserQuestion calls
- Hook structure for compaction resilience
- Whether to generate a final BUILD-REPORT.md

### Deferred Ideas (OUT OF SCOPE)

- Hybrid invocation (Skill tool + Task tool): May be needed if context pressure becomes unmanageable in v1. Revisit after initial implementation and testing.
- Parallel phase execution: Some phases may be independent and could run in parallel. Not in v1 -- sequential is simpler and sufficient.
- Remote git operations: /build could optionally push to origin and create PRs. Deferred as local-only is safer for autonomous execution.
- Target directory argument: /build could accept --dir to create and work in a specified directory. Deferred for simplicity.
- Build profiles: Pre-defined configurations for common project types (Next.js SaaS, CLI tool, API server). Deferred until build-preferences.md patterns stabilize.

---

## Summary

Phase 8 creates a `/build` skill that chains all 14 claude-super-team skills autonomously from idea to working application. The primary technical challenges are: (1) maintaining coherent state across many compactions when chaining 30+ Skill tool calls in a single session, (2) autonomously answering the ~92 AskUserQuestion calls embedded across the 14 skills, (3) managing git branches and squash-merges programmatically, and (4) implementing bounded retry loops for self-validation.

The research confirms the Skill tool is the correct mechanism for same-session skill chaining (skills invoked via Skill tool share conversation context), and that the existing PreCompact/SessionStart hook pattern from execute-phase is directly applicable but must be extended to track higher-level build pipeline state. The BUILD-STATE.md file is the critical artifact -- it must be the single source of truth that enables full recovery after any compaction or session restart.

Overall confidence: HIGH -- all building blocks exist in the codebase, the ORCHESTRATION-REFERENCE.md confirms the architectural approach, and the patterns are proven in execute-phase.

---

## Standard Stack

### Core Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| Skill tool | Claude Code built-in | Invoke chained skills in same session context | HIGH |
| AskUserQuestion tool | Claude Code built-in | User interaction (intercepted autonomously by /build) | HIGH |
| Bash tool | Claude Code built-in | Git operations, build/test commands, file detection | HIGH |
| Read/Write/Edit tools | Claude Code built-in | BUILD-STATE.md management, preferences files | HIGH |
| PreCompact hook | Claude Code built-in | Emit build state before compaction | HIGH |
| SessionStart hook | Claude Code built-in | Re-inject build state after compaction | HIGH |

### Supporting Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| gather-data.sh (new) | N/A | Pre-load BUILD-STATE.md, preferences, git status for dynamic context injection | HIGH |
| telemetry.sh (existing) | N/A | Telemetry capture for /build execution events | HIGH |

### Alternatives Considered

| Alternative | Why Not |
|-------------|---------|
| Task tool for skill chaining | Each Task gets isolated context; state sharing requires file-based IPC. Skill tool shares conversation context which is simpler and proven. Locked decision: Skill tool first, may iterate to hybrid. |
| Agent Teams for parallel phases | Phases execute sequentially (locked decision). Teams overhead not justified. |
| CLI headless mode (-p) for chaining | Would require separate processes, lose context sharing, add complexity. Skill tool is the native mechanism. |

---

## Architecture Patterns

### Project Structure

```
plugins/claude-super-team/skills/build/
  SKILL.md                          # Main skill (~600-900 lines)
  gather-data.sh                    # Dynamic context: BUILD-STATE.md, preferences, git
  assets/
    build-state-template.md         # Template for BUILD-STATE.md
    build-preferences-template.md   # Template for build-preferences.md
    build-report-template.md        # Template for BUILD-REPORT.md (final summary)
  references/
    autonomous-decision-guide.md    # Heuristics for AskUserQuestion auto-answers
    pipeline-guide.md               # Pipeline depth heuristics, validation heuristics
```

### Design Patterns

- **State Machine with File Persistence**: BUILD-STATE.md is the authoritative state machine. Each pipeline stage (init, brainstorm, roadmap, phase-N-discuss, phase-N-research, phase-N-plan, phase-N-execute, phase-N-validate, complete) is an explicit state. The skill reads BUILD-STATE.md on invocation to determine where to resume, and writes state transitions atomically after each step. This is the same pattern as EXEC-PROGRESS.md in execute-phase, elevated to the full build pipeline level.

- **Autonomous Decision Proxy**: When /build invokes a child skill via the Skill tool, that skill's AskUserQuestion calls will be presented to the LLM in the /build session context. Since /build's instructions include autonomous decision-making guidance, the LLM will use /build's reasoning framework to select the best option autonomously. This works because the Skill tool shares conversation context -- the child skill's AskUserQuestion is just another tool call in /build's session, and /build's system prompt instructs it to answer autonomously. No interception mechanism is needed; the LLM's instruction-following handles it.

- **Compaction Resilience via Hook + File State**: PreCompact hook emits the current BUILD-STATE.md contents to stdout (preserved in compaction summary). SessionStart(compact) hook re-reads BUILD-STATE.md and core planning files, re-injecting them as context. After compaction, the skill body's first step is always "read BUILD-STATE.md and determine current position." This is the execute-phase pattern elevated to build level.

- **Bounded Retry Pattern**: All retry loops (phase-feedback, final auto-fix) have explicit attempt limits stored in BUILD-STATE.md. The pattern: attempt -> validate -> if fail and attempts < max, retry -> if fail and attempts >= max, log and continue. This prevents infinite loops.

- **Branch-Per-Phase Git Isolation**: Planning artifacts (discuss, research, plan) are committed on main. Before execute-phase, create feature branch `build/{phase-slug}`. After execute-phase completes, squash-merge to main. This isolates execution work and keeps main clean with one semantic commit per phase execution.

### Anti-Patterns

- **Storing state in context only**: Context compaction destroys in-memory state. All critical state MUST be written to BUILD-STATE.md before each skill invocation. Never rely on the LLM "remembering" where it was.

- **Hard-coded decision maps for AskUserQuestion**: Skills add and modify their AskUserQuestion calls across versions. Hard-coding expected questions and answers would be brittle and break on any skill update. Use LLM reasoning with general heuristics instead.

- **Unlimited retry loops**: Any fix/retry loop without a bound risks consuming the entire session budget on a single failing phase. Always cap retries (1 for phase-feedback, 3 for final auto-fix).

- **Committing on feature branches then rebasing**: Squash-merge is simpler and avoids rebase conflicts entirely. One commit per phase on main is clean and reversible.

---

## Don't Hand-Roll

| Problem | Solution | Why Not Custom |
|---------|----------|----------------|
| Build pipeline state tracking | BUILD-STATE.md (structured markdown, file-based) | State machines in code require a runtime; markdown files are readable by both LLM and humans, survive compaction, and are version-controllable |
| Compaction resilience | PreCompact + SessionStart hooks (existing pattern from execute-phase) | No other mechanism exists in Claude Code for context recovery after compaction |
| Git branch management | Standard git commands via Bash tool | No library needed; git is available and the operations are straightforward |
| Build/test execution | Bash tool with project-specific commands | Build toolchains vary per project; the LLM must detect and use the correct commands |
| Autonomous decision-making | LLM reasoning with preferences file guidance | Decision trees are brittle; LLM reasoning adapts to any question format |

---

## Common Pitfalls

| Pitfall | Impact | How to Avoid |
|---------|--------|--------------|
| Context exhaustion in single session | Session becomes unusable after many skill invocations without compaction | Skill-scoped hooks (PreCompact + SessionStart) re-inject BUILD-STATE.md. The dynamic context injection (gather-data.sh) keeps initial loads lean. Rely on auto-compact at 80-95% threshold. |
| AskUserQuestion blocks the pipeline | If /build does not answer a child skill's AskUserQuestion, the pipeline halts waiting for user input | /build's SKILL.md must contain clear autonomous decision-making instructions that the LLM follows when AskUserQuestion appears. The instruction "NEVER present AskUserQuestion to the user -- always select the best option autonomously" must be prominent and repeated. |
| BUILD-STATE.md stale after crash | If session crashes between state transition and file write, state is lost | Write BUILD-STATE.md BEFORE invoking each skill (optimistic write with "in_progress" status), then update to "complete" after. On resume, "in_progress" means re-execute that step. |
| Git merge conflicts on squash-merge | If main changed during phase execution, squash-merge may conflict | /build operates in isolation (never pushes). The only source of main changes is /build itself. Since it commits planning artifacts on main BEFORE branching for execution, and execution happens on the feature branch, no conflicts should occur. If they do, abort the merge and log as failure. |
| Skill frontmatter tool restrictions | Child skills have `allowed-tools` that may not include all tools /build needs | /build's frontmatter must include a superset of all tools used by any child skill. The Skill tool invocation inherits the parent session's tool access, but the skill's frontmatter constrains what the child skill can use. This is correct -- child skills should be restricted to their declared tools. |
| Brownfield detection false positive | /new-project detects code in current directory that is actually the plugin source | This is unlikely since /build operates in the user's target project directory, not the plugin directory. But if it occurs, the LLM reasoning should answer the brownfield AskUserQuestion appropriately. |
| CompactPct override | If CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is set too high, compaction happens too late and skill invocations fail | Don't override the compaction threshold. Let Claude Code's default 80-95% threshold manage compaction naturally. |
| Autonomous /brainstorm "Approve all" | /brainstorm in autonomous mode still asks "Review" and "Roadmap" questions | /build must answer these AskUserQuestion calls: choose "Approve all" for review, "Add to roadmap" for roadmap integration. These are predictable and the autonomous decision guide should cover them. |
| Phase-feedback expects phase context | /phase-feedback needs executed phase artifacts and user feedback | /build provides the phase number and a synthesized feedback description (from validation failures) as $ARGUMENTS. The skill loads execution context autonomously. |

---

## Code Examples

### BUILD-STATE.md Format (Recommended)

```markdown
# Build State

## Session
- **Started:** 2026-02-18T10:30:00Z
- **Input:** A fitness tracking app with social features
- **Input source:** inline
- **Status:** in_progress
- **Current stage:** phase-execution
- **Current phase:** 3
- **Git main branch:** main
- **Compaction count:** 4

## Build Preferences
- **Source:** ~/.claude/build-preferences.md + .planning/build-preferences.md
- **Exec model:** opus
- **Tech stack preference:** React, Node.js, PostgreSQL
- **Architecture style:** modular monolith

## Pipeline Progress
| Stage | Status | Started | Completed | Notes |
|-------|--------|---------|-----------|-------|
| input-detection | complete | 10:30:00 | 10:30:01 | Inline idea detected |
| new-project | complete | 10:30:01 | 10:32:15 | PROJECT.md created |
| map-codebase | skipped | - | - | Greenfield project |
| brainstorm | complete | 10:32:15 | 10:38:42 | 8 ideas approved |
| create-roadmap | complete | 10:38:42 | 10:42:10 | 5 phases created |
| phase-1-discuss | skipped | - | - | Simple foundation phase |
| phase-1-research | skipped | - | - | Simple foundation phase |
| phase-1-plan | complete | 10:42:10 | 10:48:33 | 3 plans, 2 waves |
| phase-1-execute | complete | 10:48:33 | 11:15:22 | All plans executed |
| phase-1-validate | complete | 11:15:22 | 11:16:00 | Build passes |
| phase-1-git | complete | 11:16:00 | 11:16:30 | Squash-merged to main |
| phase-2-discuss | complete | 11:16:30 | 11:22:15 | Auth decisions locked |
| phase-2-research | complete | 11:22:15 | 11:30:08 | OAuth2 + Passport.js |
| phase-2-plan | complete | 11:30:08 | 11:38:45 | 2 plans, 1 wave |
| phase-2-execute | in_progress | 11:38:45 | - | Wave 1 in progress |
| phase-3-discuss | pending | - | - | - |
| phase-3-research | pending | - | - | - |
| phase-3-plan | pending | - | - | - |
| phase-3-execute | pending | - | - | - |

## Decisions Log
| Phase | Skill | Question | Answer | Confidence |
|-------|-------|----------|--------|------------|
| - | new-project | Brownfield detection | Skip mapping (greenfield) | high |
| - | new-project | Exec model | Opus | high |
| - | brainstorm | Mode | Autonomous | high |
| - | brainstorm | Review | Approve all | high |
| - | brainstorm | Roadmap | Add to roadmap | high |
| 1 | adaptive | Pipeline depth | Skip discuss/research (foundation) | high |
| 1 | execute-phase | Branch warning | Continue anyway | high |
| 1 | execute-phase | Exec model | Opus (from preferences) | high |
| 2 | adaptive | Pipeline depth | Full pipeline (auth is complex) | high |
| 2 | discuss-phase | Token storage | httpOnly cookies | medium |
| 2 | discuss-phase | Session duration | 7 days | low |

## Validation Results
| Phase | Build | Tests | Feedback | Final Status |
|-------|-------|-------|----------|-------------|
| 1 | pass | pass | - | complete |
| 2 | - | - | - | in_progress |

## Incomplete Phases
(None yet)

## Errors
(None yet)
```

Source: Original design based on EXEC-PROGRESS.md pattern from execute-phase and CI/CD pipeline state patterns.

### build-preferences.md Format (Recommended)

```markdown
# Build Preferences

## Tech Stack
- **Frontend:** React with TypeScript
- **Backend:** Node.js with Express
- **Database:** PostgreSQL with Prisma ORM
- **Auth:** OAuth2 with Passport.js
- **Styling:** Tailwind CSS

## Execution Model
- **Preference:** opus
- **Reasoning:** Higher quality for all tasks

## Architecture Style
- **Pattern:** Modular monolith
- **API style:** REST with OpenAPI spec
- **State management:** Server-side sessions

## Coding Style
- **Language:** TypeScript strict mode
- **Testing:** Jest with React Testing Library
- **Linting:** ESLint + Prettier
- **Comments:** JSDoc for public APIs only

## Testing Strategy
- **Unit tests:** Required for business logic
- **Integration tests:** Required for API endpoints
- **E2E tests:** Optional, Playwright if needed

## Git Preferences
- **Commit style:** Conventional commits
- **Branch prefix:** build/
```

Source: Original design based on user preference patterns and project conventions.

### Adaptive Pipeline Depth Heuristic

```
For each phase in ROADMAP.md, analyze the goal and success criteria:

COMPLEXITY SIGNALS (run full pipeline: discuss -> research -> plan -> execute):
- Goal mentions a new technical domain: auth, payments, search, real-time,
  file uploads, email, notifications, deployment, CI/CD, monitoring
- Goal mentions integration with external services or APIs
- Success criteria reference security, compliance, or data protection
- The phase has 4+ success criteria
- Prior phase artifacts don't cover this domain

SIMPLICITY SIGNALS (skip discuss/research: plan -> execute directly):
- Goal mentions: setup, init, config, scaffold, boilerplate, structure
- Goal mentions: update, tweak, adjust, rename, move, refactor
- Goal extends patterns already established in earlier phases
- The phase has 1-2 success criteria
- build-preferences.md already specifies the tech decisions for this domain

DEFAULT: If unclear, run the full pipeline (discuss + research are cheap
relative to building the wrong thing).
```

Source: Original heuristic based on analysis of discuss-phase gray area generation and research-phase scope patterns.

### Adaptive Validation Heuristic

```
After each phase execution, determine whether to run build/test validation:

VALIDATE (run build + tests):
- Phase created or modified source code files (*.ts, *.js, *.py, *.go, etc.)
- Phase created or modified package.json, requirements.txt, Cargo.toml, etc.
- Phase created or modified test files
- Phase goal mentions: build, implement, create, code, develop
- A build system exists (package.json with scripts, Makefile, etc.)
- It is the FINAL phase (always validate)

SKIP VALIDATION:
- Phase only created/modified .planning/ files
- Phase only created/modified documentation (*.md)
- Phase only created/modified config files with no code changes
- No build system exists yet (too early in the pipeline)

VALIDATION COMMANDS (detect from project):
1. Check package.json scripts: build, test, lint
2. Check Makefile targets: build, test
3. Check Cargo.toml (cargo build, cargo test)
4. Check for pytest.ini / setup.py (pytest)
5. Fall back to: "find a way to verify the project builds and tests pass"
```

Source: Original heuristic based on analysis of execute-phase verification patterns.

### File Path Detection Heuristic

```
Detect whether $ARGUMENTS contains a file path:

1. Split $ARGUMENTS on whitespace
2. For each token:
   a. If token starts with /, ./, ~/, or ../ -> potential file path
   b. If token ends with .md, .txt, .doc, .pdf -> potential file path
   c. If token matches a readable file on disk -> confirmed file path
3. If confirmed file path found:
   - Read file contents as PRD/vision document
   - Remaining tokens (if any) are additional context
4. If no confirmed file path:
   - Entire $ARGUMENTS is the project idea string

Implementation: Use Bash(test -f "$token") for each potential path
```

Source: Derived from existing pattern in new-project SKILL.md Phase 3 (Path A vs Path B detection).

### Compaction Resilience Hooks

```yaml
hooks:
  PreCompact:
    - matcher: "auto"
      hooks:
        - type: command
          command: |
            echo "BUILD STATE TO PRESERVE:"
            cat .planning/BUILD-STATE.md 2>/dev/null || echo "No build state found"
  SessionStart:
    - matcher: "compact"
      hooks:
        - type: command
          command: |
            {
              echo "=== BUILD STATE ==="
              cat .planning/BUILD-STATE.md 2>/dev/null
              echo "=== PROJECT ==="
              cat .planning/PROJECT.md 2>/dev/null
              echo "=== ROADMAP ==="
              cat .planning/ROADMAP.md 2>/dev/null
              echo "=== STATE ==="
              cat .planning/STATE.md 2>/dev/null
              echo "=== BUILD PREFERENCES ==="
              cat .planning/build-preferences.md 2>/dev/null
              cat ~/.claude/build-preferences.md 2>/dev/null
            }
```

Source: Direct adaptation of execute-phase SKILL.md hook pattern (lines 8-16), verified against official hooks documentation at code.claude.com/docs/en/hooks-guide.

### Git Branch Flow

```
Pipeline git operations for each phase:

1. PLANNING (on main):
   git add .planning/phases/{NN}-{slug}/ && git commit -m "plan phase {N}: {name}"

2. BRANCH CREATION (before execute):
   git checkout -b build/{NN}-{slug}

3. EXECUTION (on feature branch):
   /execute-phase {N}
   # execute-phase does NOT auto-commit, but /build will:
   git add -A && git commit -m "build phase {N}: {name}"

4. SQUASH-MERGE (after execution + validation):
   git checkout main
   git merge --squash build/{NN}-{slug}
   git commit -m "[build] Phase {N}: {phase_name}

   Autonomous build execution. {brief summary of what was built}.
   Validation: {pass/fail/skipped}

   Squash-merged from build/{NN}-{slug}"
   git branch -d build/{NN}-{slug}

5. RESUME HANDLING:
   If /build resumes and a feature branch exists:
   - Check if execution completed (SUMMARY.md files exist)
   - If yes: squash-merge and continue to next phase
   - If no: checkout the branch and resume execution
```

Source: Original design based on CONTEXT.md git autonomy decisions and standard git squash-merge workflow.

### Autonomous Decision Guide (Core Pattern)

```
When a child skill presents AskUserQuestion, /build follows this decision framework:

1. READ the question header, question text, and all options
2. CHECK build-preferences.md for a relevant preference
3. If preference exists: SELECT that option, log as HIGH confidence
4. If no preference: REASON about the best option given:
   - Project context (PROJECT.md, ROADMAP.md)
   - Current phase goal and success criteria
   - Prior decisions in BUILD-STATE.md
   - General software engineering best practices
5. SELECT the option that:
   - Moves the pipeline forward (never "Abort", "Cancel", "Exit")
   - Accepts reasonable defaults over custom configuration
   - Prefers recommended options (often the first option)
   - Favors completeness over speed when quality matters
6. LOG the decision in BUILD-STATE.md with confidence level
7. CONTINUE -- never present the question to the user

SPECIAL CASES:
- "Keep exploring" / "More questions" -> "Create PROJECT.md" / "All set"
  (Move forward, don't loop)
- "Map codebase first" (brownfield) -> Yes, map first
- "Research first" -> Follow adaptive pipeline depth heuristic
- Branch warning "on main" -> "Continue anyway"
  (/build manages its own branches)
- Verification "gaps found" -> "Plan fixes"
  (Triggers one feedback attempt)
- "Provide guidance" (blocked task) -> "Skip task"
  (Can't provide human guidance autonomously)
- "Checkpoint: human-verify" -> AUTO-APPROVE
  (Log as low confidence for post-build review)
```

Source: Original design based on analysis of all 92 AskUserQuestion instances across the 14 skills.

### gather-data.sh for /build

```bash
#!/usr/bin/env bash
# gather-data.sh - Pre-compute build state for /build skill

# Build state
echo "=== BUILD_STATE ==="
if [ -f .planning/BUILD-STATE.md ]; then
  echo "EXISTS=true"
  cat .planning/BUILD-STATE.md
else
  echo "EXISTS=false"
fi

# Build preferences (merged: global + project)
echo "=== PREFERENCES ==="
if [ -f "$HOME/.claude/build-preferences.md" ]; then
  echo "GLOBAL_PREFS=true"
  cat "$HOME/.claude/build-preferences.md"
else
  echo "GLOBAL_PREFS=false"
fi
if [ -f .planning/build-preferences.md ]; then
  echo "PROJECT_PREFS=true"
  cat .planning/build-preferences.md
else
  echo "PROJECT_PREFS=false"
fi

# Git state
echo "=== GIT ==="
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "BRANCH=$(git branch --show-current 2>/dev/null || echo detached)"
  echo "HAS_UNCOMMITTED=$(git status --porcelain 2>/dev/null | head -1 | wc -l | tr -d ' ')"
  # Check for existing build branches
  git branch --list 'build/*' 2>/dev/null | sed 's/^[* ]*/BUILD_BRANCH=/'
else
  echo "BRANCH=none"
  echo "GIT_AVAILABLE=false"
fi

# Project state
echo "=== PROJECT ==="
[ -f .planning/PROJECT.md ] && echo "HAS_PROJECT=true" || echo "HAS_PROJECT=false"
[ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
[ -f .planning/STATE.md ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
[ -d .planning/codebase ] && echo "HAS_CODEBASE=true" || echo "HAS_CODEBASE=false"

# Brownfield detection
CODE_COUNT=$(find . -maxdepth 3 \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) 2>/dev/null | grep -v node_modules | grep -v .git | wc -l | tr -d ' ')
echo "CODE_FILES=${CODE_COUNT}"
```

Source: Adapted from existing gather-data.sh scripts in execute-phase, progress, and phase-feedback skills.

---

## State of the Art

| Aspect | Old Approach | Current Approach | What Changed |
|--------|-------------|-----------------|--------------|
| Pipeline state | In-memory only, lost on compaction | File-based BUILD-STATE.md with hook-based re-injection | execute-phase proved this pattern in Phase 1.4; /build extends it to full pipeline level |
| Autonomous decisions | Hard-coded decision trees | LLM reasoning with preferences file guidance | Skills evolve their AskUserQuestion calls; LLM reasoning adapts without code changes |
| Skill chaining | Manual user invocation of sequential skills | Skill tool programmatic invocation in same session | Skills documentation confirms Skill tool shares conversation context (verified Feb 2026) |
| Git workflow | User-managed branches and commits | Autonomous feature-branch-per-phase with squash-merge | Clean main history with one commit per phase, automatic cleanup |
| Build validation | Manual user testing | Adaptive LLM-driven validation with bounded auto-fix | Project-aware: detects build system, runs appropriate commands, retries with fix agents |

---

## Critical Design Decisions (Research Recommendations)

### 1. BUILD-STATE.md Format: Structured Markdown Tables

**Recommendation:** Use the format shown in Code Examples above.

**Rationale:**
- Markdown tables are parseable by both LLM (via Read tool) and grep/awk
- Sections separate concerns: session metadata, pipeline progress, decisions, validation, errors
- Pipeline Progress table is the core state machine -- each row is a state with explicit status
- The format mirrors EXEC-PROGRESS.md but at pipeline level
- Human-readable for post-build review

**Confidence:** HIGH -- directly adapted from proven EXEC-PROGRESS.md pattern.

### 2. AskUserQuestion Autonomy: Inline LLM Reasoning

**Recommendation:** Do NOT intercept or suppress AskUserQuestion calls. Instead, embed strong autonomous decision-making instructions in /build's SKILL.md body so that when a child skill triggers AskUserQuestion, the LLM (which is running /build's instructions) autonomously selects the best option.

**Key insight:** When /build invokes a child skill via the Skill tool, the child skill's content becomes part of /build's conversation context (confirmed by official docs: "Skills run inline so Claude can use them alongside your conversation context"). The child skill's AskUserQuestion call is just another tool call that the LLM processes. If /build's instructions say "always answer AskUserQuestion autonomously," the LLM will do so.

**Risk:** The LLM might occasionally present the question to the user despite instructions. Mitigation: Repeat the autonomous instruction prominently at the start of the skill, before each skill invocation section, and in the compaction re-injection.

**Confidence:** HIGH -- this is how the LLM naturally processes shared-context skill invocations. The autonomous mode of /brainstorm uses a similar pattern (the brainstorm skill body says "this is the ONLY question asked before Claude takes over").

### 3. Compaction Strategy: Aggressive State Persistence

**Recommendation:** Write BUILD-STATE.md after EVERY state transition, not just at major milestones.

**Rationale:** Compaction can happen at any moment. If the last state write was 3 skills ago, resumption requires re-executing those 3 skills. The cost of frequent writes (a few Write tool calls) is negligible compared to re-executing skills.

**Pattern:**
1. Before invoking skill: Update BUILD-STATE.md with `in_progress` status for next stage
2. After skill completes: Update BUILD-STATE.md with `complete` status
3. PreCompact hook emits current BUILD-STATE.md (preserved in summary)
4. SessionStart(compact) hook re-reads BUILD-STATE.md + core files

**Confidence:** HIGH -- validated by execute-phase compaction resilience (Phase 1.4).

### 4. Feature Branch Naming: `build/{NN}-{slug}`

**Recommendation:** Use `build/{NN}-{slug}` format, e.g., `build/01-foundation`, `build/02-auth`.

**Rationale:**
- Matches the phase directory naming convention (zero-padded)
- `build/` prefix makes these branches easily identifiable and cleanable
- The slug provides human-readable context
- git branch --list 'build/*' finds all build branches for resume detection

**Confidence:** HIGH -- standard git branch naming convention.

### 5. Squash-Merge Commit Message Format

**Recommendation:**
```
[build] Phase {N}: {phase_name}

{1-2 sentence summary of what was built}

Validation: {pass | fail (with reason) | skipped}
Plans executed: {M}/{total}

Autonomous build by /build skill.
```

**Rationale:** Follows the project's commit convention format `[plugin] (type): Title`. The `[build]` tag distinguishes autonomous commits from manual work. The body includes validation status and plan count for traceability.

**Confidence:** MEDIUM -- follows existing convention but the `[build]` tag is new.

### 6. BUILD-REPORT.md: Yes, Generate It

**Recommendation:** Generate a BUILD-REPORT.md at the end of the build pipeline.

**Contents:**
- Project idea (input)
- Total elapsed time (approximate, from timestamps)
- Phases completed vs skipped
- Key decisions made (from BUILD-STATE.md decisions log)
- Low-confidence decisions (highlighted for user review)
- Validation results per phase
- Final build/test status
- Files created/modified count
- Incomplete items and known issues

**Rationale:** The user needs a summary of what /build did autonomously. The decisions log is particularly important -- the user should know what choices were made on their behalf, especially low-confidence ones.

**Confidence:** HIGH -- this is a user need (build transparency) and the data is already in BUILD-STATE.md.

### 7. Skill Invocation Order (Full Pipeline)

```
1. [Optional] Detect and read file path from $ARGUMENTS
2. Invoke /new-project with idea/PRD content
3. [If brownfield] Invoke /map-codebase
4. Invoke /brainstorm (autonomous mode, approve all)
5. Invoke /create-roadmap
6. For each phase N in ROADMAP.md:
   a. Evaluate adaptive pipeline depth heuristic
   b. [If full] Invoke /discuss-phase N
   c. [If full] Invoke /research-phase N
   d. Invoke /plan-phase N
   e. Git: commit planning artifacts, create feature branch
   f. Invoke /execute-phase N
   g. Git: commit execution results
   h. [If adaptive validation says yes] Run build/test validation
   i. [If validation fails] Invoke /phase-feedback N (one attempt)
   j. Git: squash-merge feature branch to main
   k. Update BUILD-STATE.md
7. Run final validation (always)
8. [If final fails] Auto-fix loop (3 attempts)
9. Generate BUILD-REPORT.md
10. Present completion summary
```

**Confidence:** HIGH -- directly follows locked decisions from CONTEXT.md.

---

## Open Questions

- **AskUserQuestion tool suppression**: Can /build reliably prevent AskUserQuestion from being shown to the user through instructions alone, or will the LLM sometimes "forget" after compaction? The compaction re-injection must include the autonomous decision instruction prominently. Testing will reveal if additional measures are needed.

- **Context window budget**: Chaining 14+ skills in one session with shared context will accumulate significant context before each compaction. The exact behavior under heavy load (e.g., how much of each skill's content is retained vs compacted) is unknown. The compaction hooks mitigate this, but real-world testing is needed.

- **Skill tool + allowed-tools interaction**: When /build invokes a child skill via the Skill tool, the child skill's `allowed-tools` frontmatter restricts its tool access. Verify that /build's broader tool list does not override child skill restrictions (it should not -- the child skill's frontmatter is authoritative). Also verify that /build declaring `Skill` in its allowed-tools is sufficient to invoke all 14 child skills.

- **Autonomous /discuss-phase quality**: discuss-phase generates gray areas by analyzing the phase goal with codebase context. In autonomous mode, the LLM must both generate meaningful gray areas and answer them. The quality of autonomous answers may be lower than interactive discussion. The adaptive pipeline depth heuristic should route simple phases to skip discuss/research entirely, minimizing this risk.

- **Build/test command detection**: The validation heuristic must detect how to build and test each specific project. Projects vary widely (npm, bun, cargo, make, etc.). The LLM must read package.json or equivalent to discover commands. If no build system exists yet (early phases), validation must gracefully skip.

---

## Sources

| Source | Type | Confidence | URL |
|--------|------|------------|-----|
| Claude Code Skills Documentation | Official docs | HIGH | https://code.claude.com/docs/en/skills |
| Claude Code Hooks Guide | Official docs | HIGH | https://code.claude.com/docs/en/hooks-guide |
| execute-phase SKILL.md (712 lines) | Codebase | HIGH | plugins/claude-super-team/skills/execute-phase/SKILL.md |
| brainstorm SKILL.md (457 lines) | Codebase | HIGH | plugins/claude-super-team/skills/brainstorm/SKILL.md |
| phase-feedback SKILL.md (445 lines) | Codebase | HIGH | plugins/claude-super-team/skills/phase-feedback/SKILL.md |
| new-project SKILL.md | Codebase | HIGH | plugins/claude-super-team/skills/new-project/SKILL.md |
| discuss-phase SKILL.md | Codebase | HIGH | plugins/claude-super-team/skills/discuss-phase/SKILL.md |
| research-phase SKILL.md | Codebase | HIGH | plugins/claude-super-team/skills/research-phase/SKILL.md |
| plan-phase SKILL.md | Codebase | HIGH | plugins/claude-super-team/skills/plan-phase/SKILL.md |
| create-roadmap SKILL.md | Codebase | HIGH | plugins/claude-super-team/skills/create-roadmap/SKILL.md |
| progress SKILL.md | Codebase | HIGH | plugins/claude-super-team/skills/progress/SKILL.md |
| ORCHESTRATION-REFERENCE.md | Codebase reference | HIGH | ORCHESTRATION-REFERENCE.md |
| hooks.json (telemetry) | Codebase | HIGH | plugins/claude-super-team/hooks/hooks.json |
| 08-CONTEXT.md | Phase decisions | HIGH | .planning/phases/08-full-auto-mode/08-CONTEXT.md |
| /deep-plan plugin article | Blog | MEDIUM | https://pierce-lamb.medium.com/building-deep-plan-a-claude-code-plugin-for-comprehensive-planning-30e0921eb841 |

---

## Metadata

- **Research date:** 2026-02-18
- **Phase:** 8 - Full Auto Mode
- **Confidence breakdown:** 14 HIGH, 1 MEDIUM, 0 LOW findings
- **Firecrawl available:** yes
- **Sources consulted:** 15
