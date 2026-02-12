---
name: add-security-findings
description: Store security audit findings in .planning/SECURITY-AUDIT.md and integrate remediation into the project roadmap. Critical/high findings become urgent inserted phases. Medium findings become regular phases. Low findings go to backlog. Use after a security review or scan, or invoked automatically after security analysis to capture findings.
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Grep, Skill, Bash(test *)
---

## Objective

Transform security audit findings into a structured document and integrate remediation work into the project roadmap with priority-based phase insertion.

**Reads:** `.planning/PROJECT.md` (required), `.planning/ROADMAP.md` (optional), `.planning/STATE.md` (optional), `.planning/SECURITY-AUDIT.md` (if exists)
**Creates/Updates:** `.planning/SECURITY-AUDIT.md`
**Delegates to:** `/create-roadmap` for all roadmap modifications

## Mode Detection

This skill supports two invocation modes. Detect which mode applies BEFORE starting the process:

**Interactive mode** (user explicitly invoked `/add-security-findings`):
- Full AskUserQuestion flow for gathering, classifying, and approving findings
- Follow the standard Process below as-is

**Autonomous mode** (model auto-invoked after security analysis/scanning):
- Security findings are already present in the conversation context from prior analysis
- Skip Phase 2 (Gather Findings) -- extract findings directly from conversation context
- Auto-classify severity based on finding content (Critical: RCE/injection/credential exposure, High: auth bypass/privilege escalation, Medium: misconfig/weak policies, Low: informational/outdated deps)
- Present findings summary (Phase 4) with a single approval checkpoint before writing
- Proceed through Phase 5-7 normally

**How to detect mode:**
- If `$ARGUMENTS` is empty AND no security findings are visible in conversation context: Interactive mode
- If security findings are present in conversation context (from a prior scan, research, or analysis): Autonomous mode
- If `$ARGUMENTS` contains a file path or "paste": Interactive mode

## Process

### Phase 1: Setup Checks

**Execute before any interaction:**

1. **Require PROJECT.md:**

   ```bash
   [ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
   ```

2. **Detect existing context:**

   ```bash
   [ -f .planning/ROADMAP.md ] && echo "HAS_ROADMAP=true" || echo "HAS_ROADMAP=false"
   [ -f .planning/STATE.md ] && echo "HAS_STATE=true" || echo "HAS_STATE=false"
   [ -f .planning/SECURITY-AUDIT.md ] && echo "HAS_AUDIT=true" || echo "HAS_AUDIT=false"
   ```

**You MUST run all bash commands above before proceeding.**

### Phase 2: Gather Findings

Use AskUserQuestion:

- header: "Input"
- question: "How would you like to provide security findings?"
- options:
  - "Paste findings" -- Interactive loop collecting findings
  - "From file" -- Read from a provided file path

**If "Paste findings":** Interactive loop. For each finding, collect:

1. Title/description
2. Use AskUserQuestion for severity:
   - header: "Severity"
   - question: "What is the severity of this finding?"
   - options: "Critical", "High", "Medium", "Low"
3. Affected component/files
4. Recommended fix

After each finding, use AskUserQuestion:
- header: "Continue"
- question: "Add another finding?"
- options: "Yes", "Done"

Loop until "Done".

**If "From file":** Ask for file path, read file, parse findings. Detect severity from keywords (critical, high, medium, low) or ask user to classify.

Assign sequential IDs starting from `SA-001`, `SA-002`, etc. If HAS_AUDIT=true, check highest existing ID and continue sequence.

### Phase 3: Handle Existing Audit

**If HAS_AUDIT=false:** Skip to Phase 4.

**If HAS_AUDIT=true:** Read `.planning/SECURITY-AUDIT.md` and use AskUserQuestion:

- header: "Existing audit"
- question: "SECURITY-AUDIT.md already exists. What would you like to do?"
- options:
  - "Merge" -- Append new findings, continue IDs from highest existing
  - "Replace" -- Start fresh with new findings
  - "Review existing first" -- Show current findings, then re-ask

If "Merge": Parse existing findings, find highest SA-XXX ID, start new findings at next number.

If "Replace": Set mode to replace existing file.

If "Review existing first": Display findings grouped by severity, then re-ask this question.

### Phase 4: Present Findings Summary

Display findings grouped by severity with counts:

```
Security Findings Summary:

Critical (2):
- SA-001: SQL injection in user input handler
- SA-002: Hardcoded API credentials in config

High (1):
- SA-003: Missing authentication on admin endpoints

Medium (3):
- SA-004: CORS misconfiguration
- SA-005: Weak password policy
- SA-006: Missing rate limiting

Low (2):
- SA-007: Outdated dependency versions
- SA-008: Missing security headers
```

Use AskUserQuestion:

- header: "Findings"
- question: "Review the findings summary. What would you like to do?"
- options:
  - "Approve" -- Continue to writing SECURITY-AUDIT.md
  - "Adjust severities" -- Change severity classifications
  - "Add more findings" -- Return to Phase 2

Loop until "Approve".

### Phase 5: Write SECURITY-AUDIT.md

Read `assets/security-audit.md` template. Populate with:

- Project name from PROJECT.md
- Current date
- Findings grouped by severity (Critical, High, Medium, Low)
- Summary table with counts (all findings start as "Open")
- Remediation Phase initially set to "Not yet planned"

Write to `.planning/SECURITY-AUDIT.md`.

If replacing (from Phase 3), overwrite. If merging, read existing, append new findings, recalculate summary table.

### Phase 6: Roadmap Integration

**If HAS_ROADMAP=false:**

Show message:

```
SECURITY-AUDIT.md created with {N} findings.

No roadmap found. Security findings are documented but not yet integrated into delivery plan.

To integrate remediation into roadmap:
- Run /create-roadmap to create initial roadmap
- Then re-run /add-security-findings with merge mode to integrate
```

Skip to Phase 7.

**If HAS_ROADMAP=true:**

1. Read STATE.md to determine current phase number (insertion anchor).

2. Apply priority logic to determine what roadmap changes are needed:

   - **Critical findings**: Urgent inserted phase after current phase. Name: "Critical Security Remediation". Groups all critical findings.
   - **High findings**: If 3+ high findings, separate urgent inserted phase ("High-Priority Security Fixes"). If fewer than 3, group with critical findings.
   - **Medium findings**: Regular appended phase ("Security Hardening").
   - **Low findings**: Backlog items (not formal phases).

3. Present integration proposal:

   ```
   Proposed roadmap integration:

   Inserted phases (block feature work):
   - Phase {N}.1: Critical Security Remediation (2 findings: SA-001, SA-002)
   - Phase {N}.2: High-Priority Security Fixes (1 finding: SA-003)

   Appended phases:
   - Phase {M}: Security Hardening (3 findings: SA-004, SA-005, SA-006)

   Backlog (added to ROADMAP.md ## Backlog section):
   - SA-007, SA-008 (low priority)
   ```

4. Use AskUserQuestion:
   - header: "Integration"
   - question: "Integrate security findings into roadmap?"
   - options:
     - "Approve all" -- Invoke /create-roadmap for each change
     - "Adjust" -- Refine phase groupings or priorities
     - "Skip roadmap integration" -- Keep SECURITY-AUDIT.md only

5. **On approve:** Delegate to `/create-roadmap` via the Skill tool for each roadmap modification. Run them sequentially since each modifies ROADMAP.md:

   **For critical/high findings (urgent inserted phases):**

   Build a description string from the grouped findings and invoke:

   ```
   Skill(skill: "create-roadmap", args: "insert urgent Critical Security Remediation phase after phase {N}. Goal: remediate critical security vulnerabilities ({finding_ids}). Success criteria: {derived from findings, e.g. 'All SQL injection vulnerabilities patched and verified', 'No hardcoded credentials in codebase'}.")
   ```

   If high findings need a separate phase, invoke again:

   ```
   Skill(skill: "create-roadmap", args: "insert urgent High-Priority Security Fixes phase after phase {N}. Goal: fix high-severity security issues ({finding_ids}). Success criteria: {derived from findings}.")
   ```

   **For medium findings (appended phase):**

   ```
   Skill(skill: "create-roadmap", args: "add Security Hardening phase. Goal: address medium-severity security findings ({finding_ids}). Success criteria: {derived from findings}.")
   ```

   **For low findings (backlog):**

   Low findings are not formal phases. After the `/create-roadmap` invocations complete, directly append a `## Backlog` section to ROADMAP.md (or append to existing one):

   ```markdown
   ## Backlog

   Low-priority security items for future consideration:

   - **SA-007**: Outdated dependency versions
   - **SA-008**: Missing security headers
   ```

6. After all `/create-roadmap` invocations complete, read the updated ROADMAP.md to determine the actual phase numbers that were assigned (create-roadmap computes the decimal/integer numbers). Then update `.planning/SECURITY-AUDIT.md` `## Roadmap Integration` section with finding-to-phase mapping:

   ```markdown
   ## Roadmap Integration

   | Finding | Severity | Phase | Status |
   |---------|----------|-------|--------|
   | SA-001  | Critical | Phase 2.1 | Planned |
   | SA-002  | Critical | Phase 2.1 | Planned |
   | SA-003  | High     | Phase 2.2 | Planned |
   | SA-004  | Medium   | Phase 6 | Planned |
   | SA-005  | Medium   | Phase 6 | Planned |
   | SA-006  | Medium   | Phase 6 | Planned |
   | SA-007  | Low      | Backlog | Deferred |
   | SA-008  | Low      | Backlog | Deferred |
   ```

### Phase 7: Done

Show completion summary:

**If roadmap integration was performed:**

```
Security audit complete.

Created/Updated:
- .planning/SECURITY-AUDIT.md ({N} findings)
- .planning/ROADMAP.md ({M} security phases added)
- .planning/STATE.md (updated focus)

Findings integrated:
- {X} critical/high findings → urgent phases (block feature work)
- {Y} medium findings → regular phase
- {Z} low findings → backlog

To commit:
  git add .planning/ && git commit -m "docs: add security audit findings"

Next steps:
- Plan urgent remediation: /plan-phase 2.1
- Review security phase details in ROADMAP.md
```

**If no roadmap integration:**

```
Security audit complete.

Created/Updated:
- .planning/SECURITY-AUDIT.md ({N} findings)

Findings documented but not yet integrated into roadmap.

To commit:
  git add .planning/SECURITY-AUDIT.md && git commit -m "docs: add security audit findings"

Next steps:
- Create roadmap: /create-roadmap
- Then re-run this skill to integrate findings
```

## Success Criteria

- [ ] PROJECT.md exists and was read
- [ ] Findings collected with IDs, severities, components, and recommended fixes
- [ ] Existing audit handled (merge/replace) if present
- [ ] Findings approved by user before writing
- [ ] SECURITY-AUDIT.md written with proper template structure
- [ ] Roadmap integration proposed with priority-based grouping logic
- [ ] User approved integration (or explicitly skipped)
- [ ] /create-roadmap invoked for each roadmap modification (insert urgent, add)
- [ ] SECURITY-AUDIT.md updated with finding-to-phase mappings after roadmap changes
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps
