---
name: drift
description: "Compare actual codebase state against planning artifacts to surface divergence. Reads SUMMARY.md, CONTEXT.md, PLAN.md files and spawns Explore agents to verify claims. Produces a categorized DRIFT-REPORT.md with confirmed drift, potential drift, and aligned findings."
argument-hint: "[phase number | --all]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion, Bash(test *), Bash(ls *), Bash(grep *), Bash(bash *gather-data.sh)
model: sonnet
---

## Step 0: Load Context

Run the gather script to load planning files and structured data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/drift/gather-data.sh"
```

Parse the output sections (PROJECT, ROADMAP, STATE, PHASE_ARTIFACTS, CODEBASE_DOCS) before proceeding.

**Context-aware skip:** If PROJECT.md, ROADMAP.md, or STATE.md are already in conversation context (e.g., loaded by a parent `/build` invocation or re-injected after compaction), skip re-loading them by prefixing: `SKIP_PROJECT=1 SKIP_ROADMAP=1 SKIP_STATE=1 bash "${CLAUDE_PLUGIN_ROOT}/skills/drift/gather-data.sh"`. Only set flags for files genuinely already in context.

## Objective

Compare actual codebase state against planning artifacts to detect divergence. Extract concrete claims from SUMMARY.md, CONTEXT.md, and PLAN.md files, then spawn Explore agents to verify each claim against the real codebase. Produce a categorized DRIFT-REPORT.md.

**Flow:** Validate -> Parse args -> Extract claims -> Spawn agents -> Assemble report -> Present results

**Why agents:** Claim verification requires deep file inspection (Read, Grep, Glob across many files). Each phase gets its own agent with fresh context to avoid overloading the orchestrator.

**Why sonnet orchestrator + opus agents:** The orchestrator's job is coordination -- reading artifacts, parsing claims, spawning agents, assembling the report. The Explore agents need opus-level reasoning for nuanced claim verification and categorization.

**Reads:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/phases/{N}-{name}/*-SUMMARY.md`, `*-CONTEXT.md`, `*-PLAN.md`, `.planning/codebase/*.md`
**Creates:** `.planning/DRIFT-REPORT.md`

## Process

### Phase 1: Validate Environment

PROJECT.md, ROADMAP.md, and STATE.md are pre-loaded via dynamic context injection. If their contents are empty/missing from the injection, show the appropriate error and exit:

- No PROJECT.md content: "ERROR: No project found. Run /new-project first."
- No ROADMAP.md content: "ERROR: No roadmap found. Run /create-roadmap first."

Check the **PHASE_ARTIFACTS** section from the gather script output. If no phase directories exist or no phase has summaries > 0:

```
No executed phases found. Run /execute-phase first to execute a phase before running drift analysis.
```

Exit skill.

### Phase 2: Parse Arguments

Extract from `$ARGUMENTS`:

- **A phase number** (e.g., `3`, `03`, `2.1`): Analyze that single phase only.
- **`--all`**: Analyze all completed phases (those with at least one SUMMARY.md).
- **No argument**: Same as `--all` -- analyze all completed phases.

**Determine target phases:**

From **PHASE_ARTIFACTS**, each line has format:
```
{dir_name}|context={N}|research={N}|plans={N}|summaries={N}|verification={N}
```

- If a specific phase number is given, find the matching directory (extract phase number from dir_name prefix, e.g., `03-auth` matches phase 3). If no match, exit: "Phase {N} not found."
- If the matched phase has summaries=0, exit: "Phase {N} has not been executed. No claims to verify."
- If `--all` or no argument, collect all directories where summaries > 0.

Normalize phase numbers using zero-padded format:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/phase-utils.sh"
PHASE=$(normalize_phase "$PHASE_NUM")
```

Report scope:

```
Drift analysis scope: {Phase N: Name | All completed phases ({N} phases)}
```

### Phase 3: Extract Claims

For each phase being analyzed, read the planning artifacts and extract verifiable claims.

**Step 3a: Read SUMMARY.md files**

For each `*-SUMMARY.md` in the phase directory:

1. Parse YAML frontmatter for `key_files` (both `created` and `modified` arrays). Each file path is a file-existence claim.
2. Read the "What Was Built" section. Extract:
   - File paths mentioned (file-existence claims)
   - Patterns described as implemented (pattern claims)
   - Libraries or tools described as added (library claims)
3. Read the "Files" section or task completion tables. Extract file paths (file-existence claims).

**Step 3b: Read CONTEXT.md**

If `*-CONTEXT.md` exists in the phase directory:

1. Find the "Implementation Decisions" section (or equivalent decision records).
2. For each locked decision, extract:
   - The chosen approach/technology (decision claim -- verify presence)
   - The rejected alternative, if recorded (decision claim -- verify absence)

**Step 3c: Read PLAN.md files**

For each `*-PLAN.md` in the phase directory:

1. Extract file paths from `<files>` tags in task definitions. Each is a file-existence claim.
2. Extract `must_haves` from the plan frontmatter. Cross-reference with SUMMARY.md claims for completeness.

**Step 3d: Deduplicate and Categorize**

Group all extracted claims by type:

- **File-existence claims:** Unique file paths with their source artifact.
- **Pattern claims:** Architectural patterns or implementation approaches.
- **Decision claims:** Technology choices and locked decisions from CONTEXT.md.

Remove exact duplicates (same file path from multiple sources -- keep the most specific source reference).

**Step 3e: Scope Check**

Count total unique claims across all target phases. If more than ~40 claims in a single analysis run:

```
AskUserQuestion:
  header: "Large scope"
  question: "Found {N} claims across {M} phases. This may consume significant context. Proceed or narrow scope?"
  options:
    - "Proceed" -- "Analyze all {N} claims"
    - "Narrow scope" -- "Pick specific phases to analyze"
```

If user chooses "Narrow scope", use AskUserQuestion to let them select which phases to include, then filter the claim list.

### Phase 4: Spawn Explore Agent(s)

Read the drift analysis guide:

```
Read file: ${CLAUDE_SKILL_DIR}/references/drift-analysis-guide.md
```

Store its full content as `$DRIFT_GUIDE`.

Read the codebase docs from the gather script CODEBASE_DOCS section (already loaded in Step 0). Store as `$CODEBASE_CONTEXT`.

**For each target phase, spawn one Agent:**

```
Agent(
  subagent_type: "general-purpose"
  model: "opus"
  prompt: """
  ultrathink

  You are a drift analysis agent. Your job is to verify claims from planning artifacts against the actual codebase state.

  ## Methodology

  {$DRIFT_GUIDE -- full content of drift-analysis-guide.md}

  ## Codebase Architecture Context

  {$CODEBASE_CONTEXT -- content from CODEBASE_DOCS section, or "(no codebase map available)" if empty}

  ## Phase Being Analyzed

  Phase: {phase_number} - {phase_name}
  Phase directory: .planning/phases/{phase_dir}/

  ## Claims to Verify

  ### File-Existence Claims
  {For each claim: "- Source: {artifact file} | Path: {file_path} | Description: {what it should be}"}

  ### Pattern Claims
  {For each claim: "- Source: {artifact file} | Pattern: {description} | Expected in: {file paths if known}"}

  ### Decision Claims
  {For each claim: "- Source: {artifact file} | Decision: {what was chosen} | Rejected: {what was rejected, if known} | Verify in: {relevant files}"}

  ## Instructions

  1. Verify each claim using Read, Glob, and Grep tools.
  2. For file-existence claims: check the path exists, briefly confirm its purpose matches the description.
  3. For pattern claims: search relevant files for evidence of the pattern.
  4. For decision claims: verify chosen approach is present and rejected approach is absent.
  5. Categorize each as: confirmed_drift, potential_drift, aligned, or unverifiable.
  6. For drift items, assess impact: high, medium, or low.

  ## Output Format

  Return your findings as structured markdown with these exact sections:

  ### Confirmed Drift
  | # | Artifact | Claim | Actual State | Impact |
  |---|----------|-------|--------------|--------|
  {numbered rows}

  ### Potential Drift
  | # | Artifact | Claim | Actual State | Why Unclear |
  |---|----------|-------|--------------|-------------|
  {numbered rows}

  ### Aligned
  | # | Artifact | Claim | Verification |
  |---|----------|-------|-------------|
  {numbered rows}

  ### Unverifiable
  | # | Artifact | Claim | Reason |
  |---|----------|-------|--------|
  {numbered rows}

  ### Summary Counts
  - Confirmed Drift: {N}
  - Potential Drift: {N}
  - Aligned: {N}
  - Unverifiable: {N}
  """
)
```

**Important:** All claims are embedded inline in the prompt. Do NOT use @ file references -- they do not work across Agent boundaries.

**Parallel execution:** If analyzing multiple phases, spawn agents in parallel using `run_in_background`. Wait for all agents to complete before proceeding to Phase 5.

### Phase 5: Assemble Report

Read the drift report template:

```
Read file: ${CLAUDE_SKILL_DIR}/assets/drift-report-template.md
```

Collect results from all completed agents. Parse each agent's output to extract the findings tables and summary counts.

Populate the template:

1. **Header:** Set date to today, list analyzed phases, set scope.
2. **Summary table:** Aggregate counts across all phases.
3. **Findings:** For each phase, insert the agent's findings tables under a `### Phase {N}: {Name}` heading. Include all four categories (Confirmed Drift, Potential Drift, Aligned, Unverifiable). Omit empty category tables.
4. **Recommendations:** Compile a prioritized list from all confirmed and potential drift items, ordered by impact (high first). For each recommendation, state what should be done (e.g., "Recreate missing file X", "Update SUMMARY.md to reflect renamed file Y").

Write the assembled report to `.planning/DRIFT-REPORT.md`.

### Phase 6: Present Results

Print a summary to the user:

```
Drift analysis complete.

| Category | Count |
|----------|-------|
| Confirmed Drift | {N} |
| Potential Drift | {N} |
| Aligned | {N} |
| Unverifiable | {N} |
```

**If confirmed drift > 0:**

```
Top confirmed drift items:
- {top 3 items, each showing: artifact -> claim, actual state}

Full report: .planning/DRIFT-REPORT.md

To address drift:
  /phase-feedback {N} -- fix a specific phase's drift
  /quick-plan -- create a drift-fix phase
```

**If confirmed drift == 0 and potential drift > 0:**

```
No confirmed drift found. {N} items need manual review.

Full report: .planning/DRIFT-REPORT.md
```

**If all aligned:**

```
All {N} claims verified -- codebase matches planning artifacts.

Full report: .planning/DRIFT-REPORT.md
```

## Success Criteria

- [ ] Planning artifacts read and claims extracted for each target phase
- [ ] Claims grouped by type: file-existence, pattern, decision
- [ ] Explore agent(s) spawned with full context (drift-analysis-guide + claims + codebase docs) embedded inline
- [ ] Each claim categorized as confirmed drift, potential drift, aligned, or unverifiable
- [ ] DRIFT-REPORT.md created at `.planning/DRIFT-REPORT.md` with structured findings
- [ ] Summary counts accurate across all analyzed phases
- [ ] User sees inline summary with counts and top drift items
- [ ] User given actionable next steps for addressing drift
