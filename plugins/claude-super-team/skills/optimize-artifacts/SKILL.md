---
name: optimize-artifacts
description: "Rewrite existing PLAN.md and RESEARCH.md files to be concise: replace verbose code blocks with prose descriptions and critical-only snippets. Run on any project with a .planning/ directory."
argument-hint: "[path to .planning/ directory]"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion, Bash(wc *), Bash(ls *)
disable-model-invocation: true
---

## Objective

Rewrite existing PLAN.md and RESEARCH.md files to follow concise artifact guidelines: prose-first descriptions with only critical code snippets (max ~10 lines each). Processes files in parallel per phase directory.

**Reads:** `.planning/phases/**/*-PLAN.md`, `.planning/phases/**/*-RESEARCH.md`
**Modifies:** Same files, in-place

## Process

### Phase 1: Resolve Target Directory

Parse `$ARGUMENTS` for a path. If empty, default to `.planning/` in the current working directory.

Validate the path exists and contains a `phases/` subdirectory:

```bash
ls "${TARGET_PATH}/phases/" 2>/dev/null
```

If not found:

```
No .planning/phases/ directory found at {path}. Provide the path to a project's .planning/ directory.
```

Exit skill.

### Phase 2: Scan Files

Find all PLAN.md and RESEARCH.md files:

Use Glob to find:
- `{TARGET_PATH}/phases/**/*-PLAN.md`
- `{TARGET_PATH}/phases/**/*-RESEARCH.md`

Group files by phase directory. For each file, collect line count via `wc -l`.

If no files found:

```
No PLAN.md or RESEARCH.md files found.
```

Exit skill.

### Phase 3: Show Summary and Confirm

Present what was found:

```
Found {N} files across {M} phase directories:

| Phase | PLANs | RESEARCHs | Total Lines |
|-------|-------|-----------|-------------|
| 02-agent-daemon | 4 | 1 | 1,842 |
| 03-central-server | 3 | 1 | 1,650 |
| ... | ... | ... | ... |

Total: {N} files, {L} lines
```

Use AskUserQuestion:

- header: "Scope"
- question: "Which files do you want to optimize?"
- options:
  - label: "All files"
    description: "Process all {N} files across {M} phase directories"
  - label: "Plans only"
    description: "Only PLAN.md files ({P} files)"
  - label: "Research only"
    description: "Only RESEARCH.md files ({R} files)"

### Phase 4: Process Files

Spawn one Task agent per phase directory, running all phase directories in parallel. Each agent processes all target files (PLANs, RESEARCHs, or both based on user selection) within its assigned phase directory.

For each phase directory, spawn:

```
Task(
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Optimize {phase-dir} artifacts"
  prompt: """
  You are an artifact optimizer. Rewrite planning files to be concise by replacing
  verbose code blocks with prose descriptions and critical-only code snippets.

  ## Rules for PLAN.md files

  For each `<action>` block in the file:

  1. PRESERVE exactly: YAML frontmatter (everything between --- markers), all XML tags
     and their structure (<objective>, <context>, <tasks>, <task>, <name>, <files>,
     <verify>, <done>, <verification>, <success_criteria>, <output>).

  2. REWRITE `<action>` content:
     - Replace full code implementations with prose descriptions of what to build.
     - Keep code snippets ONLY when they show a non-obvious pattern the executor
       would likely get wrong. Examples:
       * Framework-specific patterns (e.g., Bun's `export default { port, fetch }`)
       * Exact constants from requirements (e.g., backoff values)
       * Critical type shapes or protocol contracts
       * Non-obvious wiring or config
     - Each kept snippet: max ~10 lines, with a 1-sentence explanation of why it matters.
     - Remove: full file implementations, boilerplate, imports, class scaffolding,
       test implementations, anything the executor would trivially derive from prose.

  3. DO NOT CHANGE: <files>, <verify>, <done>, <name>, <objective>, <context>,
     <verification>, <success_criteria>, <output> sections. Leave them exactly as-is.

  ## Rules for RESEARCH.md files

  1. Rename `## Code Examples` to `## Key Patterns` (if present).

  2. For each code block under that section:
     - Extract only the critical lines (the non-obvious pattern, max ~10 lines).
     - Add a 1-2 sentence description of why the pattern matters.
     - Preserve the Source: attribution line.
     - Remove: full implementations, boilerplate, obvious code.

  3. DO NOT CHANGE any other sections (User Constraints, Standard Stack,
     Architecture Patterns, Don't Hand-Roll, Common Pitfalls, State of the Art,
     Open Questions, Sources, Metadata, Summary). Leave them exactly as-is.

  ## Files to process

  Phase directory: {phase_dir_path}

  Files:
  {list of file paths}

  ## Process

  For each file:
  1. Read the file completely
  2. Apply the appropriate rules (PLAN.md or RESEARCH.md)
  3. Write the optimized version back to the same path
  4. Report: file path, lines before, lines after

  After all files are processed, return:

  ## OPTIMIZATION COMPLETE

  | File | Before | After | Reduction |
  |------|--------|-------|-----------|
  | {filename} | {lines} | {lines} | {percent}% |
  """
)
```

### Phase 5: Collect Results and Report

After all agents complete, collect their results and present a combined summary:

```
Optimization complete.

| Phase | Files | Lines Before | Lines After | Reduction |
|-------|-------|-------------|-------------|-----------|
| 02-agent-daemon | 5 | 1,842 | 1,105 | 40% |
| 03-central-server | 4 | 1,650 | 990 | 40% |
| ... | ... | ... | ... | ... |
| **Total** | **{N}** | **{B}** | **{A}** | **{R}%** |

Estimated token savings: ~{tokens} per plan-phase invocation

To review changes:
  git diff .planning/phases/

To commit:
  git add .planning/phases/ && git commit -m "chore: optimize planning artifacts for conciseness"
```

## Edge Cases

### Files with no code blocks
Skip -- nothing to optimize. Report as "Already concise" in the results.

### Files with only critical snippets
If all code blocks are already short (<10 lines), skip. Report as "Already concise."

### Research files without "Code Examples" section
Skip -- nothing to rename. Report as "No code examples section."

## Success Criteria

- [ ] All target files scanned and categorized
- [ ] User confirmed scope before processing
- [ ] Each file rewritten with prose-first actions / key patterns
- [ ] YAML frontmatter and structural XML tags preserved exactly
- [ ] Non-code sections left untouched
- [ ] Before/after line counts reported
- [ ] User told how to review and commit (never auto-commit)
