# Changelog

All notable changes to the claude-super-team marketplace are documented in this file.

## [1.0.52] - 2026-03-27

### claude-super-team
- Add JSON schema infrastructure for planning files: json-sync.sh converts PROJECT/ROADMAP/STATE/IDEAS MD files to structured JSON
- Update gather-common.sh with _JQ_AVAILABLE caching and JSON-first emit_* functions (emit_preferences, emit_sync_check, emit_structure)
- Update 6 gather-data.sh scripts with inline JSON-first extraction paths (progress, plan-phase, research-phase, phase-feedback, code, create-roadmap)
- Add dual MD+JSON output to /new-project, /create-roadmap, and /brainstorm skills
- Add /cst-help migrate action for generating JSON from existing MD-only projects
- Update workflow-guide.md with JSON Data Layer section and troubleshooting.md with JSON troubleshooting
- Update CLAUDE.md with JSON data layer conventions

## [1.0.51] - 2026-03-26

### claude-super-team
- Switch model from haiku to sonnet in /progress, /metrics, and /cst-help skills. ToolSearch is not available on the haiku model

### marketplace-utils
- Switch model from haiku to sonnet in /marketplace-manager skill

### task-management
- Switch model from haiku to sonnet in /github-issue-manager skill

## [1.0.50] - 2026-03-20

### claude-super-team
- Add /metrics skill for telemetry resource reporting and threshold violation detection. Includes gather-data.sh (JSONL aggregation with jq/grep fallback), SKILL.md (haiku model, context: fork), and report-template.md
- Update /cst-help with /metrics documentation in skill reference, workflow guide, and troubleshooting
- Add "metrics" and "telemetry" keywords to plugin manifests

## [1.0.49] - 2026-03-20

### claude-super-team
- create-roadmap: Fix sprint sizing always capping at 2 phases. Updated roadmap template to show 3-phase sprints and phase-derivation guide to remove artificial sprint size limits. Only dependency barriers should create new sprints.
- execute-phase: Auto-switch to feature branch instead of warning when on main

## [1.0.48] - 2026-03-18

### claude-super-team
- Fix timestamp hallucination across all skills. Add `Bash(date *)` to allowed-tools and explicit `date` command instructions in code, execute-phase, drift, map-codebase, and add-security-findings skills. Extends the fix from v1.0.46 (which only covered build) to every skill that uses timestamps
- config: Bump version to 1.0.48

## [1.0.47] - 2026-03-18

### claude-super-team
- execute-phase: Fix teams detection by replacing unreliable gather-output parsing with explicit bash env var check (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`). The LLM now runs a dedicated command at the decision point instead of searching for `teams-available: true` in prior text output
- build: Call `emit_preferences()` in gather-data.sh to include `teams-available` flag; rename build-specific preferences to `BUILD_PREFERENCES` section to avoid collision
- build: Pass `--team` explicitly to execute-phase in sequential sprint path when teams are available, as belt-and-suspenders alongside the env check
- config: Bump version to 1.0.47

## [1.0.46] - 2026-03-18

### claude-super-team
- build: Parallelize sprint research with dependency-aware scheduling. Split Step 9c into sequential discuss and parallel research. Overlap analysis scans CONTEXT.md files for shared technical domains -- independent phases research simultaneously, overlapping phases chain sequentially so later phases get prior RESEARCH.md context
- build: Fix timestamp hallucination throughout the build pipeline. Add explicit `date` command instructions since the model has no clock and was fabricating timestamps in BUILD-STATE.md
- config: Bump version to 1.0.46

## [1.0.45] - 2026-03-18

### claude-super-team
- build: Add parallel sprint execution via Agent Teams + git worktrees. Multi-phase sprints spawn one teammate per phase, each in an isolated worktree, executing concurrently. Falls back to sequential branch-per-phase when teams are unavailable or for single-phase sprints
- build: Add sprint-teammate-guide.md reference with self-contained instructions for worktree-based phase execution (enter worktree, execute, validate, feedback, commit, exit, report)
- build: Smarter merge conflict handling for parallel mode -- auto-resolves .planning/ file conflicts, preserves worktree branches on source code conflicts for manual resolution
- build: Add Agent, TeamCreate, TeamDelete, SendMessage, TaskCreate, TaskUpdate, TaskList, TaskGet, TaskOutput, TaskStop to allowed-tools for sprint team orchestration
- build: Update resume logic to handle interrupted worktree-based executions
- execute-phase: Add `--no-team` flag to force task mode regardless of preferences (prevents nested teams when running inside a sprint teammate)
- reference: Update CAPABILITY-REFERENCE.md -- EnterWorktree/ExitWorktree now "In use", Agent Teams shared task list and graceful shutdown now "In use"
- reference: Update ORCHESTRATION-REFERENCE.md -- add "Team + worktree combo" orchestration pattern
- config: Bump version to 1.0.45

## [1.0.44] - 2026-03-17

### claude-super-team
- Migrate all `model: sonnet` references to `model: opus` across frontmatter (plan-checker agent, map-codebase, drift skills) and inline agent spawns (map-codebase mapper agents, execute-phase code-simplifier, optimize-artifacts). Driven by high Sonnet error rates observed over the past week; Opus provides more reliable execution for all agent workloads
- Change default execution-model preference from sonnet to opus in create-roadmap, state templates, and new-project recommendation. Users can still explicitly choose sonnet if preferred
- config: Bump version to 1.0.44

### marketplace-utils
- skill-studio: Migrate `model: sonnet` frontmatter to `model: opus` for consistency with the broader migration
- config: Bump version to 1.0.7

## [1.0.43] - 2026-03-17

### claude-super-team
- new-project: Add `--discuss` flag (Path C) for interactive brainstorming from zero context -- progressive narrowing from domain to problem to users to success criteria, producing PROJECT.md without requiring upfront input
- build: Add auto-extend detection (Branch 2a) -- `/build` auto-detects existing PROJECT.md + ROADMAP.md without BUILD-STATE.md and enters extend mode; add partial-project detection (Branch 2b) for PROJECT.md-only state that skips /new-project
- build: gather-data.sh emits `AUTO_EXTEND` and `PARTIAL_PROJECT` signals for 5-way entry branching
- build: sprint-execution-guide.md Step 8-E documents auto-extend entry path
- execute-phase: Add "What Changed" section to Phase 9 completion summary -- concise bullet-point summary of user-facing changes derived from SUMMARY.md artifacts
- config: Bump version to 1.0.43

### marketplace-utils
- release: Remove hardcoded `model: sonnet` from frontmatter, defaults to parent model
- config: Bump version to 1.0.6

## [1.0.42] - 2026-03-16

### claude-super-team
- cst-help: Add `/cst-help explain` capability for reading `.planning/` artifacts plus phase context (CONTEXT.md, RESEARCH.md, ROADMAP.md) and producing a concise narrative explaining purpose, constraints, and connections
- cst-help: Update workflow-guide.md with explain documentation and troubleshooting.md with artifact explanation entries and "When to Use /cst-help" section
- build: Add Step 12.5 (Completion Audit) to finalization pipeline -- scans for gaps across 4 categories (incomplete phases, failed verifications, unresolved errors, build/test failures), runs bounded remediation (max 2 cycles via /phase-feedback), records results in BUILD-REPORT.md
- build: Update SKILL.md pipeline description, key behaviors, and finalization steps list to reference the completion audit
- config: Bump version to 1.0.42

## [1.0.41] - 2026-03-16

### claude-super-team
- skill: Add `/drift` skill for comparing actual codebase state against planning artifacts to surface divergence
- drift: `SKILL.md` orchestrator (sonnet model) extracts claims from SUMMARY.md, CONTEXT.md, PLAN.md, spawns opus Explore agents to verify against codebase, produces `.planning/DRIFT-REPORT.md`
- drift: `gather-data.sh` sources `gather-common.sh`, emits PHASE_ARTIFACTS and CODEBASE_DOCS sections for drift analysis context
- drift: `references/drift-analysis-guide.md` defines claim extraction methodology, verification protocol, and four-category classification (confirmed drift, potential drift, aligned, unverifiable)
- drift: `assets/drift-report-template.md` provides structured report skeleton with summary counts and per-phase findings tables
- cst-help: Add `/drift` to skill reference (new "Analysis" subsection), workflow-guide.md pipeline overview, troubleshooting.md (3 entries), and "When to Use Each Skill" section
- config: Bump version to 1.0.41

## [1.0.40] - 2026-03-16

### claude-super-team
- scripts: Create `gather-common.sh` as a sourceable library with 7 shared functions (`emit_project_section`, `emit_roadmap_section`, `emit_state_section`, `emit_phase_completion`, `emit_sync_check`, `emit_preferences`, `emit_structure`) -- replaces duplicated code across gather scripts
- scripts: Add `create_phase_dir()` to `phase-utils.sh` -- derives phase name from ROADMAP.md, slugifies, creates directory, returns path; replaces inline ls/grep/sed/mkdir pipelines in 4 skills
- gather scripts: Migrate all 9 active gather-data.sh scripts to source `gather-common.sh`; high-overlap scripts (build, execute-phase, progress) replace inline sections with shared function calls
- emit_state_section: Truncates STATE.md output at `### Decision Archive` delimiter via awk, keeping archived decisions out of active context injection
- discuss-phase, plan-phase, execute-phase: Replace inline phase directory creation pipelines with `create_phase_dir()` calls
- quick-plan: Retain inline directory creation with explanatory comment (slug derived from user description, not ROADMAP.md)
- execute-phase: Add STATE.md decision archival step to Phase 8 compaction -- moves completed-phase decisions below `### Decision Archive` delimiter
- execute-phase, create-roadmap: Fix missing `Edit` in allowed-tools (Phase 8 state updates and roadmap modification flows both require surgical edits)
- research-phase: Fix missing `Bash(mkdir *)` in allowed-tools (Phase 1.5 creates phase directory)

### marketplace-utils
- marketplace-manager: Fix missing `Bash(mkdir *)` in allowed-tools (plugin registration creates `.claude-plugin/` directory)

## [1.0.39] - 2026-03-13

### claude-super-team
- plan-phase: Expand `gather-data.sh` with 6 new pre-assembled context sections (ROADMAP_TRIMMED, STATE_TRIMMED, CODEBASE_DOCS, PHASE_CONTEXT, PHASE_RESEARCH, PHASE_REQUIREMENTS) -- eliminates 6+ sequential LLM Read calls before planner agent spawn
- plan-phase: Streamline SKILL.md Phase 4 to use pre-assembled sections directly; add Phase 3.5 for second gather-data.sh invocation with PHASE_NUM/PHASE_DIR and SKIP flags
- plan-phase: Update context-loading.md to document pre-assembled sections and remove manual trimming rules

## [1.0.38] - 2026-03-12

### claude-super-team
- Centralize phase number normalization into shared `scripts/phase-utils.sh` with `normalize_phase()` and `find_phase_dir()` functions
- Replace inline normalization code in 6 skills (discuss-phase, execute-phase, plan-phase, research-phase, phase-feedback, plan-phase-workspace/skill-snapshot) with calls to the shared script -- eliminates 24 lines of duplicated code
- Decompose build/SKILL.md from 1084 to 498 lines by extracting Steps 8-E and 9 into `references/sprint-execution-guide.md` and Steps 10-13 + Success Criteria into `references/finalization-guide.md`

## [1.0.37] - 2026-03-09

### claude-super-team
- build: Sprint-based execution loop -- phases from the same sprint are grouped, planned in parallel, and validated together at a sprint boundary before moving to the next sprint
- build: Sprint Progress table added to BUILD-STATE.md tracking per-sprint status and boundary validation result
- build: Sprint column added to Phase Progress table in BUILD-STATE.md and Phase Results table in BUILD-REPORT.md
- build: Sprint Boundary Validation step runs build+tests on main after all phases in a sprint are merged, catching cross-phase integration issues early
- build: Sprint-aware resume logic in Step 1 -- rebuilds SPRINT_MAP from ROADMAP.md after compaction, handles multiple in-flight branches per sprint
- build: Backward compatibility -- roadmaps without sprint annotations treat each phase as its own single-phase sprint, preserving sequential behavior
- build: pipeline-guide updated with Section 5 (Sprint-Based Execution) explaining grouping logic, execution strategy, and sprint-aware git flow

## [1.0.36] - 2026-03-08

### claude-super-team
- execute-phase: Compact completed phase detail blocks in ROADMAP.md to 1-2 line `[COMPLETE]` summaries on phase completion, reducing roadmap token usage by ~78% on mature projects
- execute-phase: Rewrite ROADMAP.md overview paragraph to focus on remaining work after each phase completes
- execute-phase: Sync PROJECT.md on phase completion -- move covered requirements from Active to Validated, fix stale Context statements, mark pending Key Decisions as Done, remove delivered Out of Scope items
- execute-phase: Compact STATE.md on phase completion -- remove completed wave entries from Parallelism Map, prune Blockers/Concerns entries that no longer apply to remaining work
- create-roadmap: Document `[COMPLETE]` compact format in roadmap template and modification procedures; enforce that compacted phases are never re-expanded

## [1.0.35] - 2026-03-07

### tools
- Added fly.io CLI skill: deploy apps, view logs, check machine status, scale VMs and machine count, manage secrets, volumes, Postgres clusters, SSH, certificates, IPs, and health checks -- with built-in safety rules for destructive operations and auto-detection of fly.toml context

## [1.0.34] - 2026-03-06

### claude-super-team
- create-roadmap: Value-first phase ordering -- phases now deliver demoable vertical slices early instead of front-loading infrastructure
- create-roadmap: Sprint grouping -- roadmap organizes phases into parallel sprints; each sprint produces something the user can demo
- create-roadmap: T-shirt sizing (S/M/L/XL) added to phases for effort estimation
- create-roadmap: Improved skill description for broader and more reliable triggering
- plan-phase: Parallel-first planning stance -- planner defaults to parallel plans unless dependencies force sequential ordering
- plan-phase: Context trimming -- planner receives only the relevant phase section from ROADMAP.md and current position from STATE.md, reducing unnecessary context load
- plan-phase: Improved skill description for broader and more reliable triggering

## [1.0.33] - 2026-03-05

### claude-super-team
- All 13 SKILL.md files updated to use `${CLAUDE_SKILL_DIR}/` prefix for internal file references (references/, assets/) -- ensures correct path resolution when skills are installed from the marketplace

### marketplace-utils
- Renamed `skill-creator` skill to `skill-studio` to avoid conflict with Anthropic's official `skill-creator` skill
- marketplace-manager: Updated reference table to use `${CLAUDE_SKILL_DIR}/` prefix

### masterclass
- addictive-apps-design: Updated reference to use `${CLAUDE_SKILL_DIR}/` prefix

### task-management
- linear-sync: Updated reference to use `${CLAUDE_SKILL_DIR}/` prefix

## [1.0.32] - 2026-03-03

### claude-super-team
- progress: Added dependency-aware multi-phase routing -- /progress now parses "Depends on" lines from ROADMAP.md and marks phases as blocked or unblocked based on whether all dependency phases are complete
- progress: gather-data.sh gains a new DEPENDENCIES section that extracts phase dependency graphs using portable awk
- progress: Phase 4 (Build Phase Map) now annotates each phase with its blocked/unblocked state and lists unsatisfied dependencies
- progress: Phases table gains a Deps column showing dependency satisfaction status per phase; blocked phases show ⊘ blocked status
- progress: Phase 6 routing now scans ALL phases instead of stopping at the first match -- Route A lists all executable unblocked phases, Route B lists all plannable unblocked phases, Route C finds all newly-unblocked phases (not just Z+1), Route E lists all gap phases
- progress: Added Route H for the edge case where all remaining phases are blocked (dependency deadlock detection)

## [1.0.31] - 2026-03-03

### claude-super-team
- plan-phase: Added refinement mode -- when plans already exist, users can now choose to surgically update plans based on new context (RESEARCH.md, CONTEXT.md) rather than replanning from scratch
- plan-phase/context-loading.md: Added "Refine existing plans (Recommended)" as the default option when plans already exist for a phase
- plan-phase/planner-guide.md: Added full Refinement Mode section with editor mindset, impact classification (no/minor/moderate/major), preservation rules, and REFINEMENT COMPLETE return format

## [1.0.30] - 2026-02-25

### masterclass
- Committed initial plugin files for `addictive-apps-design` skill (files were registered in v1.0.28 but not included in the release commit)
- addictive-apps-design: Added Pencil MCP read tools to `allowed-tools` -- skill can now audit .pen design files directly
- addictive-apps-design: Added design file review workflow using `get_editor_state`, `batch_get`, `snapshot_layout`, `get_screenshot`, `get_variables`, and `search_all_unique_properties`

## [1.0.29] - 2026-02-25

### claude-super-team
- build: Fixed extend mode stopping after /create-roadmap -- added rule 6 to AUTONOMOUS OPERATION section instructing Claude to ignore child skill "Next Steps" output during /build pipeline execution
- build: Added explicit IMPORTANT override in Step 8 and Step 8-E to ignore /create-roadmap's "Next Steps" directives and continue to Step 9 (phase execution loop)

## [1.0.28] - 2026-02-25

### masterclass
- Added new `masterclass` plugin to the marketplace -- a knowledge plugin for research-distilled expert skills
- Added `addictive-apps-design` skill: emotional design principles (micro-interactions, feedback loops, trust-building polish, premium feel) distilled from case studies on Duolingo, Phantom, and Revolut
- Skill includes a 16-item review checklist for auditing existing implementations and a case studies reference file with outcome data and key lessons

## [1.0.27] - 2026-02-25

### claude-super-team
- execute-phase: Fixed teams detection bug -- `teams-available` now read from gather script PREFERENCES section instead of directly checking the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable (which is inaccessible to skills)
- execute-phase: Added verification preference (`always|on-failure|disabled`) via gather-data.sh grep and new Phase 3.7 resolution step; Phase 6 now conditionally skips verifier when preference is `disabled` or `on-failure` with clean execution
- execute-phase: `gather-data.sh` PREFERENCES section gains a `verification:` line (4 total: execution-model, simplifier, verification, teams-available)
- /build: Enhanced adaptive pipeline depth heuristic with three new dimensions: Tech Stack Coverage (bias SIMPLE when all tech decisions specified in build-preferences), Project Complexity Class (standard vs complex classification after roadmap creation), and Cumulative Knowledge Discount (pattern-following later phases lean SIMPLE)
- /build: Added `$PREF_VERIFICATION` preference resolution in Step 3, persisted to STATE.md in Step 4, and documented passthrough to execute-phase in Step 9g; complexity class logged to BUILD-STATE.md after Step 8
- plan-phase: Strengthened wave batching rules in planner-guide.md with 4 explicit rules favoring same-wave placement, updated algorithm with read-conflict awareness, vertical slice examples with shared-read safety, and clear write-overlap vs read-overlap distinction

## [1.0.26] - 2026-02-22

### claude-super-team
- Slimmed 9 SKILL.md files by extracting heavy content into `references/*.md` files loaded via `Read()` on demand, reducing post-compaction "Skills restored" token cost by ~20K tokens per compaction (~40-60K saved across a typical `/build` session)
- execute-phase: Extracted wave execution guide (5a-5h) and stale state reconciliation into 2 reference files (747 -> 429 lines)
- brainstorm: Extracted interactive mode, autonomous mode, and context generation into 3 reference files (457 -> 168 lines)
- discuss-phase: Extracted cross-phase context, codebase exploration, gray area methodology, and deep-dive methodology into 4 reference files (474 -> 279 lines)
- phase-feedback: Extracted feedback collection, quick fix guide, and subphase guide into 3 reference files (449 -> 192 lines)
- plan-phase: Extracted all-phases mode, checker loop, and context loading into 3 reference files (474 -> 241 lines)
- new-project: Extracted questioning methodology and project writing guide into 2 reference files (369 -> 154 lines)
- create-roadmap: Extracted roadmap modification procedures and phase derivation into 2 reference files (289 -> 166 lines)
- research-phase: Extracted prior research selection and conflict detection into 2 reference files (304 -> 252 lines)
- build: Removed 4 redundant summary sections that duplicated process steps (1029 -> 969 lines)
- Total: 21 new reference files created, ~80KB saved from SKILL.md restored content

## [1.0.25] - 2026-02-21

### claude-super-team
- execute-phase: Teams mode teammates now evaluate newly created/modified directories for strategic CLAUDE.md files after each task; task-execution-guide defines concise rules (max 3-5 lines, most dirs skip, critical non-obvious context only)
- research-phase: New Phase 3.5 scans prior RESEARCH.md files from completed phases and selectively includes relevant ones in the researcher agent prompt (0-3 files max, orchestrator judges relevance by phase goal comparison)

### marketplace-utils
- release: PR title now derived from commit messages following repo convention `[plugin] (type): Description (vX.Y.Z)` instead of static "Release vX.Y.Z"

## [1.0.24] - 2026-02-21

### claude-super-team
- Added `teams-available` flag to `/execute-phase` gather-data.sh: detects `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` env var and outputs availability in the PREFERENCES section

## [1.0.23] - 2026-02-21

### claude-super-team
- Added conditional gather scripts: all 9 `gather-data.sh` scripts now support `SKIP_PROJECT`, `SKIP_ROADMAP`, `SKIP_STATE` env vars to skip re-dumping files already in context, reducing redundant token usage during `/build` pipeline and after compaction resume
- Updated `/build` SKILL.md with "Context-Aware Gathering" section: instructs Claude to prefix child skill gather commands with skip flags when core planning files are already loaded
- Added context-aware skip guidance to Step 0 of all 8 child skill SKILL.md files (create-roadmap, discuss-phase, execute-phase, plan-phase, phase-feedback, progress, code, research-phase)
- Added `ToolSearch` to `phase-researcher` agent tools: agent can now discover platform-specific MCP servers (e.g., Apple docs, Stripe, Supabase) at research time
- Added section 6 "ToolSearch -- Discover MCP Tools" to researcher tool strategy with when/how guidance and MCP tool results treated as HIGH confidence sources
- Updated `phase-researcher` source hierarchy and execution flow routing to include MCP tool discovery step for platform-specific phases

## [1.0.22] - 2026-02-21

### claude-super-team
- Added extend mode to `/build` skill: auto-detects completed prior builds and skips initialization stages (new-project, map-codebase, brainstorm) when adding a new feature
- `gather-data.sh` now emits `EXTEND_CANDIDATE=true` when BUILD-STATE.md shows `Status: complete` with existing PROJECT.md and ROADMAP.md
- Extend pipeline: invokes `/create-roadmap "add {feature}"` to append a new phase, then skips completed phases in the execution loop
- `BUILD-STATE.md` gains a `Build mode: {fresh|extend}` field and `extend` as an input source option
- Added Section 7 (Extend Mode) to `pipeline-guide.md` documenting detection, skipped stages, and pipeline flow
- Added `/create-roadmap (Extend Mode)` decision table to `autonomous-decision-guide.md` for autonomous "Add a phase" and "Approve" answers

## [1.0.21] - 2026-02-20

### claude-super-team
- Added "Code in Actions" section to planner guide: actions are prose-first with critical snippets only (non-obvious API patterns, exact constants, tricky wiring -- max ~10 lines each)
- Renamed `## Code Examples` to `## Key Patterns` in researcher template: same conciseness rules apply, eliminates full implementations from RESEARCH.md
- Updated planner guide Research Fidelity section to reference `Key Patterns` and discourage expanding snippets into full code
- Added `/optimize-artifacts` skill: rewrites existing PLAN.md and RESEARCH.md files to be concise, processing phase directories in parallel with sonnet agents
- Added `disable-model-invocation: true` to `/optimize-artifacts` (user-only, not auto-invocable)
- Updated `/cst-help` skill reference with `/optimize-artifacts` entry

## [1.0.20] - 2026-02-20

### claude-super-team
- Optimized plan-phase speed: flipped checker from default to opt-in (`--verify` flag)
- Added pre-flight checklist to planner guide covering the 6 most common checker dimensions (task completeness, scope, dependencies, key links, must-haves, context compliance)
- Eliminates 3 out of 4 agent spawns in the common case (planner only, no checker/revision loop)
- Updated /build skill to not request verification by default
- Updated /cst-help skill reference, workflow-guide, and troubleshooting with new `--verify` flag

## [1.0.19] - 2026-02-19

### claude-super-team
- Added Context7 MCP integration to `phase-researcher` agent for fast, indexed library documentation lookups
- Agent now intelligently routes research questions: Context7 for known library docs (configuration, API, patterns), Firecrawl for ecosystem discovery and novel tech
- Added `mcp__context7__resolve-library-id` and `mcp__context7__query-docs` to agent tool list
- Updated source hierarchy: Context7 indexed docs are highest priority, official docs via Firecrawl/WebFetch are second
- Updated RESEARCH.md metadata template with Context7 availability and library query count
- Updated researcher-guide.md reference copy to mirror agent changes
- Updated /cst-help workflow-guide and troubleshooting with Context7 documentation

## [1.0.18] - 2026-02-18

### claude-super-team
- Added `/build` skill for autonomous full-pipeline application building from idea to working code
- Chains all 14 claude-super-team skills via Skill tool with zero user intervention
- Maintains BUILD-STATE.md for compaction resilience and auto-resume across context compactions
- Adaptive pipeline depth: LLM decides per-phase whether to run discuss/research or skip to plan/execute
- Git autonomy: feature branch per phase execution, squash-merge to main, never pushes
- Adaptive validation with bounded auto-fix (3 attempts) on final build/test failure
- One feedback attempt per failed phase, then mark incomplete and continue
- build-preferences.md support (global ~/.claude/ and per-project .planning/) for tech stack and style preferences
- BUILD-REPORT.md generated at completion with full decisions log and low-confidence decision highlights
- Updated /cst-help with /build documentation, troubleshooting entries, and workflow guide updates

## [1.0.17] - 2026-02-17

### claude-super-team
- Added hook-based telemetry capture for passive, zero-token-cost event tracking
- Created `telemetry.sh` shell script that captures 6 event types (skill_start, skill_end, agent_spawn, agent_complete, tool_use, tool_failure) as JSONL
- Script features: session file persistence via CLAUDE_ENV_FILE, graceful no-op when `.planning/` missing, jq-based extraction with grep/sed fallback, never writes to stdout, always exits 0
- Added 24 telemetry hook declarations across 4 orchestrator skills: `/execute-phase`, `/plan-phase`, `/research-phase`, `/brainstorm`
- Hook configuration: SessionStart (with `once: true`), Stop, SubagentStart/SubagentStop (async), PostToolUse/PostToolUseFailure (async)
- Existing `/execute-phase` compaction resilience hooks (PreCompact, SessionStart compact matcher) preserved unchanged
- Telemetry data accumulates in `.planning/.telemetry/` (gitignored)

## [1.0.16] - 2026-02-16

### claude-super-team
- Added `/code` skill for interactive coding sessions with project context
- Two modes: phase-linked (loads phase artifacts, creates REFINEMENT.md) and free-form (project awareness only)
- Session logs tracked in `.planning/.sessions/` (gitignored)
- Moved data gathering to dynamic context injection across 5 skills: `/create-roadmap`, `/discuss-phase`, `/execute-phase`, `/phase-feedback`, `/plan-phase` -- each now uses a `gather-data.sh` script instead of inline Bash checks
- `/execute-phase` now auto-marks phases complete in ROADMAP.md (checks off Phases checklist, updates Progress table)
- `/phase-feedback` now reverts parent phase completion in ROADMAP.md when creating a feedback subphase
- Updated `/progress` Route C to offer `/code` as a phase refinement alternative
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting with `/code` documentation

### marketplace-utils
- Added `/release` skill for automated release ceremony: detects changes, bumps versions, updates docs, syncs marketplace, commits, pushes, and opens PR
- Bumped version to 1.0.2

## [1.0.15] - 2026-02-13

### claude-super-team
- Audited all 18 skills across 3 plugins
- Redesigned `/add-security-findings` with dual-mode support: Interactive (manual invocation) and Autonomous (auto-invoked after security analysis with findings in context)
- Downgraded `/map-codebase` model from opus to sonnet for cost/speed efficiency
- Added `maxTurns: 40` and `memory: project` to `phase-researcher` agent for safety limits and session persistence
- Added `disable-model-invocation: true` to `/new-project` to prevent spurious auto-invocation
- Added `argument-hint` to `/cst-help` and dynamic context injection (`!` commands) to `/cst-help` and `/progress`
- Added `allowed-tools` to `/marketplace-manager` (was missing entirely)
- Added `Skill` tool to `/linear-sync` for invoking Linear CLI
- Downgraded `/github-issue-manager` model from sonnet to haiku
- Added `argument-hint` to `/marketplace-manager` and `/github-issue-manager`

## [1.0.14] - 2026-02-12

### claude-super-team
- Added inline research detection to `/phase-feedback`: LLM analyzes confirmed feedback for unfamiliar packages/APIs/patterns and conditionally spawns the `phase-researcher` agent before planning
- Added planning file sync detection to `/progress`: detects directory-vs-roadmap mismatches, STATE.md drift, and progress table inconsistencies; outputs "Sync Issues" warning block when problems found
- Added per-project simplifier toggle to `/execute-phase`: `simplifier: enabled|disabled` preference in STATE.md gates the code-simplifier step in both task mode and teams mode
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting with sync detection documentation

## [1.0.13] - 2026-02-12

### claude-super-team
- Added compaction resilience to `/execute-phase`: skill-scoped hooks (`PreCompact`, `SessionStart`) preserve and re-inject execution state when context compaction occurs during long team-mode runs
- Added `EXEC-PROGRESS.md` tracking to `/execute-phase`: initializes wave/plan/team state in Phase 4.7, updates at 5 execution points (wave start, teammate spawn, plan completion, wave completion, team cleanup), and cleans up in Phase 8
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting with compaction resilience documentation

## [1.0.12] - 2026-02-12

### claude-super-team
- Added branch guard to `/execute-phase`: warns when running on main/master and offers to switch branch or continue
- Added execution mode logging to `/execute-phase`: prints which mode (team/task) was selected and how to change it
- Added single-plan wave downgrade in `/execute-phase`: waves with only one plan automatically use task mode even in teams mode, since cross-plan parallelism has no benefit
- Updated `/execute-phase` completion summary with Mode column in wave table
- Enhanced `/brainstorm` with Phase 11.5: auto-generates CONTEXT.md files for new roadmap phases created from brainstorm ideas, using the discuss-phase context template
- Enhanced `/progress` phase table with Steps column showing discuss/research/plan status (D/R/P) per phase

## [1.0.11] - 2026-02-11

### claude-super-team
- Reworked `/phase-feedback` to route by scope: quick fixes are applied directly inline (no subphase, no agents), while standard feedback creates a subphase + plan and directs the user to run `/execute-phase` instead of executing immediately
- Updated `/cst-help` workflow-guide, troubleshooting, and skill reference to reflect new routing behavior

## [1.0.10] - 2026-02-10

### claude-super-team
- Added `/brainstorm` skill with two modes: Interactive (collaborative discussion) and Autonomous (parallel agent analysis with bold recommendations)
- Interactive mode: iterative idea exploration with AskUserQuestion, deep-dives, and per-idea decisions
- Autonomous mode: spawns 3 parallel agents (Codebase Explorer, Creative Strategist, Architecture Reviewer) to generate comprehensive ideas ranked by impact-to-effort ratio
- Both modes write to `.planning/IDEAS.md` and optionally invoke `/create-roadmap` to add approved ideas as new phases
- Updated `/cst-help`, workflow-guide, and troubleshooting to document brainstorming workflow

## [1.0.9] - 2026-02-10

### claude-super-team
- Added execution model preference (`execution-model: sonnet|opus`) to `## Preferences` section in STATE.md and PROJECT.md
- `/new-project` now asks user for preferred execution model during project initialization (Phase 3.5)
- `/create-roadmap` carries execution model preference from PROJECT.md to STATE.md when creating state
- `/execute-phase` reads preference from STATE.md and asks on first run if not set (Phase 3.5); opus preference overrides routing table to use opus for all execution tasks
- Updated STATE.md and PROJECT.md templates with `## Preferences` section

## [1.0.8] - 2026-02-10

### claude-super-team
- Added code-simplifier step to `/execute-phase`: after all tasks in a plan complete, spawns `code-simplifier:code-simplifier` agent to refine written code for clarity, consistency, and maintainability before summary creation
- Updated teams mode to embed simplifier call in teammate prompt (runs after task execution, before SUMMARY.md)
- Requires `code-simplifier` plugin: install via `/plugin install code-simplifier@claude-plugins-official`
- Updated `/cst-help`, workflow-guide, and troubleshooting to document the simplification step

## [1.0.7] - 2026-02-10

### claude-super-team
- Added discuss-research feedback loop: `/discuss-phase` now recommends `/research-phase` when no RESEARCH.md exists, and `/research-phase` cross-references findings against CONTEXT.md decisions to detect conflicts (deprecated packages, better alternatives) and recommend re-discussion
- Updated `/discuss-phase` Phase 8 to check for RESEARCH.md and prompt user to research before planning
- Updated `/research-phase` with new Phase 6 (decision conflict detection) that compares research against CONTEXT.md and routes user back to `/discuss-phase` if conflicts found
- Updated README, `/cst-help`, workflow-guide, and troubleshooting to document the discuss-research-discuss flow

## [1.0.6] - 2026-02-10

### claude-super-team
- Enhanced `/discuss-phase` with cross-phase context loading (Phase 3.5) -- reads earlier phase SUMMARY/PLAN/CONTEXT.md to understand what prior phases will create, enabling dependency-aware gray areas
- Enhanced `/discuss-phase` with codebase exploration (Phase 3.7) -- spawns Explore agent to find phase-relevant code patterns and constraints before generating gray areas
- Added `Task` to discuss-phase allowed-tools for agent spawning
- Updated context-template.md with new "Codebase Context" and "Cross-Phase Dependencies" sections for downstream planners
- Updated `/cst-help` skill reference, workflow-guide, and troubleshooting to reflect codebase-aware discuss-phase

## [1.0.5] - 2026-02-10

### claude-super-team
- Added `/research-phase` skill for ecosystem research before planning
- Added custom `phase-researcher` agent (`agents/phase-researcher.md`) with embedded research methodology, template, and preloaded Firecrawl skill
- Updated `/plan-phase` to offer research when RESEARCH.md missing
- Updated `/progress` routing to suggest research after discussion
- Added RESEARCH.md interpretation guidance to planner-guide.md
- Updated `/cst-help` with research-phase documentation

## [1.0.4] - 2026-02-09

### claude-super-team
- Added `/cst-help` skill for interactive workflow help, concept explanations, and troubleshooting
- Updated README with `/discuss-phase` and `/cst-help` documentation, renumbered all commands

## [1.0.3] - 2026-02-09

### claude-super-team
- Added `/discuss-phase` skill for capturing user implementation decisions before planning
- Integrated lightweight discussion step into `/quick-plan`
- Updated `/progress` routing to suggest discussion when no context exists
- Added informational note to `/plan-phase` when CONTEXT.md is missing

## [1.0.2] - 2026-02-09

### task-management (new plugin)
- Added `/linear-sync` skill for syncing `.planning/` artifacts to Linear
- Added `/github-issue-manager` skill for creating and managing GitHub issues

### marketplace-utils
- Added `/skill-creator` skill for guided skill scaffolding

## [1.0.1] - 2026-02-09

### claude-super-team
- Added `/phase-feedback` skill for feedback-driven subphases with opus agents
- Added teams mode to `/execute-phase` for multi-agent parallel execution
- Added `/quick-plan` skill for lightweight phase insertion with decimal numbering

### marketplace-utils (new plugin)
- Added `/marketplace-manager` skill for auditing and managing plugin marketplaces

## [1.0.0] - 2026-02-08

### claude-super-team (new plugin)
- Initial release with core planning and execution pipeline
- Skills: `/new-project`, `/create-roadmap`, `/plan-phase`, `/execute-phase`, `/progress`
