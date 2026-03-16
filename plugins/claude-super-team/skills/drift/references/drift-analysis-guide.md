# Drift Analysis Guide

Methodology reference for the Explore agent spawned by the /drift skill. Follow these instructions to extract claims from planning artifacts and verify them against the actual codebase state.

## Claim Extraction Methodology

### From SUMMARY.md

Extract concrete, verifiable claims:

- **File claims:** Files listed in YAML frontmatter `key_files` (both `created` and `modified` arrays), files mentioned in "Files" or "What Was Built" sections, and file paths in task completion tables.
- **Pattern claims:** Architectural patterns, design decisions, or implementation approaches described as completed (e.g., "implemented middleware pattern", "uses repository pattern").
- **Library claims:** Libraries, frameworks, or dependencies described as added or configured.
- **Decision claims:** Architectural or implementation decisions recorded as made and applied.

### From CONTEXT.md

Extract locked decisions -- these form the "contract" between planning and implementation:

- **Technology choices:** If a decision says "use library X", verify X is actually used (present in package.json, imported in code, etc.).
- **Architectural patterns:** If a decision locks a specific pattern (e.g., "server components only", "event-driven"), verify the pattern is present in the relevant code.
- **Rejected alternatives:** If CONTEXT.md records that option B was rejected in favor of option A, verify option B is NOT present and option A IS present.
- Focus on the "Implementation Decisions" section. Ignore discussion notes or open questions.

### From PLAN.md

Extract planned targets from task definitions:

- **File paths from `<files>` tags:** These are the files each task was supposed to create or modify. Verify they exist at the stated paths.
- **Task objectives:** The `<action>` descriptions state what each task should accomplish. Cross-reference with SUMMARY.md claims.
- **Must-haves:** The plan's `must_haves` section defines the acceptance criteria. These should be reflected in the codebase.

### From VERIFICATION.md

If a VERIFICATION.md exists with `status: passed`:

- The must_haves were verified as true at execution time.
- Drift means something changed AFTER verification passed.
- Compare VERIFICATION.md timestamp against recent git history to assess whether post-verification changes could have introduced drift.

If `status: gaps_found`, the gaps are known issues -- do not re-report them as drift. Focus on claims that were marked as passing.

### Unexecuted Phases

Skip phases with no SUMMARY.md files -- they have not been executed yet. Record them as "unverifiable" in the report with reason: "Phase not yet executed."

## Claim Verification Protocol

### File Existence

1. Check if the claimed file exists at its stated path using Glob or Read.
2. If missing, search for renamed or moved versions:
   - Use Grep to search for unique identifiers from the claim (function names, class names, export names).
   - Check common rename patterns (e.g., `utils.ts` -> `helpers.ts`, `api/` -> `routes/`).
3. If a replacement is found, categorize as "potential drift" (moved/renamed) rather than "confirmed drift" (missing).

### Pattern Verification

For claims about architectural patterns or implementation approaches:

1. Identify the files where the pattern should be present (from SUMMARY.md or PLAN.md file lists).
2. Search those files for evidence of the pattern (imports, class structures, function signatures).
3. Surface-level verification is sufficient -- confirm the pattern exists, do not audit every line for correctness.
4. If the pattern is partially implemented (some files follow it, others do not), categorize as "potential drift."

### Decision Verification

For CONTEXT.md locked decisions:

1. Identify the decision and its chosen approach.
2. Verify the chosen approach is present in the codebase (library installed, pattern used, configuration set).
3. Check that the rejected alternative is NOT present (no imports of rejected library, no use of rejected pattern).
4. A contradicted decision (rejected approach found, chosen approach absent) is "confirmed drift."

### Depth Calibration

- Focus on observable, verifiable claims. A claim like "created src/auth/login.ts with OAuth flow" is verifiable. A claim like "improved error handling" is too vague.
- Flag vague claims as "unverifiable" rather than guessing.
- Do not read every line of every file. Check existence, verify key identifiers, confirm structural patterns.
- Prioritize high-impact claims: file existence, library usage, architectural decisions.

## Categorization Rules

### Confirmed Drift

Use when the evidence is unambiguous:

- A claimed file is missing with no replacement found anywhere in the codebase.
- A locked decision from CONTEXT.md was contradicted: the rejected approach is used, or the chosen approach is absent.
- A claimed file exists but serves a clearly different purpose than described (e.g., claimed as "auth middleware" but contains unrelated utility functions).
- A must_have from a passed VERIFICATION.md is no longer true.

### Potential Drift

Use when something changed but intent may be preserved:

- A file exists but its content differs significantly from the description (different exports, different structure).
- A pattern is partially implemented (present in some files, missing in others).
- A file was renamed or moved but its purpose seems preserved.
- A library is installed but configured differently than described.

### Aligned

Use when the codebase matches the artifacts:

- File exists at the stated path and serves the described purpose.
- Locked decisions are reflected in the code (chosen approach present, rejected approach absent).
- Architectural patterns are present in the expected files.
- Library is installed and used as described.

### Unverifiable

Use when verification is not possible:

- Claim is too vague to check (e.g., "improved performance", "better error handling").
- Claim references internal runtime behavior that cannot be observed from file inspection.
- Phase has no SUMMARY.md (not yet executed).
- Referenced files or patterns are in areas the agent cannot access.

## Output Format

For each claim analyzed, provide:

1. **Source:** The artifact file and section where the claim was found.
2. **Claim:** The specific assertion being verified (quote or paraphrase).
3. **Category:** confirmed_drift | potential_drift | aligned | unverifiable
4. **Evidence:** What was found in the codebase (file path, grep result, or absence).
5. **Impact** (for drift only): high (breaks functionality or contradicts locked decision), medium (structural mismatch but function preserved), low (cosmetic or naming difference).
6. **Rationale:** Brief explanation of why this categorization was chosen.

Group findings by category for easy assembly into the drift report.
