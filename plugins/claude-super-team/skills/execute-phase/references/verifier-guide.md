# Verifier Guide

You verify that a phase ACHIEVED ITS GOAL, not just that tasks completed. Task completion does not equal goal achievement.

**Do NOT trust SUMMARY.md claims. Verify the ACTUAL codebase.**

## Process

### 1. Establish Must-Haves

Extract from plan frontmatter `must_haves:` fields. If missing, derive using goal-backward:

1. State the phase goal as an outcome (not a task)
2. Derive 3-7 **observable truths** from user perspective. Each verifiable by a human using the app.
3. Derive **required artifacts** -- specific files that must exist for each truth.
4. Derive **key links** -- critical connections between artifacts. Where stubs hide.

### 2. Verify Artifacts (Three Levels)

For each required artifact:

**Level 1 -- Existence:** File exists?
- MISSING = immediate failure

**Level 2 -- Substantive:** Not a stub?
- Check line count (Component 15+, API 10+, Hook 10+, Schema 5+)
- Check for stub patterns: TODO, FIXME, empty returns, placeholder text, `console.log`-only implementations
- React stubs: `<div>Component</div>`, `onClick={() => {}}`, `onSubmit={e => e.preventDefault()}`
- API stubs: `return Response.json([])` with no DB query
- Status: SUBSTANTIVE, STUB, PARTIAL

**Level 3 -- Wired:** Connected to the system?
- Is it imported anywhere?
- Is it actually called/used?
- Wiring stubs: fetch exists but response ignored, query exists but result not returned, form handler only prevents default, state exists but never rendered
- Status: WIRED, ORPHANED, PARTIAL

**Artifact Status Matrix:**

| Exists | Substantive | Wired | Status |
|--------|-------------|-------|--------|
| yes | yes | yes | VERIFIED |
| yes | yes | no | ORPHANED |
| yes | no | - | STUB |
| no | - | - | MISSING |

### 3. Verify Key Links

Check that artifacts are actually connected:

| Link Type | What to Check |
|-----------|---------------|
| Component -> API | fetch/axios call with response handling |
| API -> Database | Prisma/DB query with result returned |
| Form -> Handler | onSubmit with real implementation |
| State -> Render | State variable displayed in JSX |
| Route -> Page | Route defined and page component exists |

### 4. Verify Observable Truths

For each truth: does the codebase enable it?
- VERIFIED: All supporting artifacts pass three levels + key links wired
- FAILED: Any artifact MISSING, STUB, or ORPHANED
- UNCERTAIN: Needs human verification (visual, UX, real-time behavior)

### 5. Scan Anti-Patterns

Check for:
- TODO/FIXME comments in new code
- Placeholder content ("Lorem ipsum", "Example data")
- Empty implementations (`{}`, `pass`, `return null`)
- Console.log-only implementations

Severity: BLOCKER (must fix), WARNING (should fix), INFO (suggestion)

### 6. Determine Status

- `passed`: All truths VERIFIED, no BLOCKER anti-patterns
- `gaps_found`: Any truth FAILED, artifacts MISSING/STUB/ORPHANED, BLOCKER anti-patterns
- `human_needed`: Automated checks pass but items need human verification

### 7. Output VERIFICATION.md

```yaml
---
phase: XX-name
verified: YYYY-MM-DDTHH:MM:SSZ
status: passed | gaps_found | human_needed
score: N/M must-haves verified
gaps:  # only if gaps_found
  - truth: "Observable truth that failed"
    status: failed
    reason: "Why it failed"
    artifacts:
      - path: "src/path/to/file.tsx"
        issue: "STUB -- only 5 lines, placeholder content"
    missing:
      - "Specific thing to add or fix"
human_verification:  # only if human_needed
  - test: "What to verify manually"
    expected: "What should happen"
    why_human: "Why automated check insufficient"
---

# Phase {X}: {Name} Verification Report

## Observable Truths

| Truth | Status | Evidence |
|-------|--------|----------|
| {truth} | VERIFIED/FAILED | {evidence} |

## Required Artifacts

| Artifact | Exists | Substantive | Wired | Status |
|----------|--------|-------------|-------|--------|
| {path} | yes/no | yes/no | yes/no | {status} |

## Key Links

| From | To | Via | Status |
|------|----|----|--------|
| {component} | {api} | {mechanism} | WIRED/NOT_WIRED |

## Anti-Patterns

| File | Pattern | Severity |
|------|---------|----------|
| {path} | {description} | BLOCKER/WARNING |

## Gaps Summary

{Narrative: what's missing, what needs to be fixed, recommended actions}
```

## Re-Verification Mode

If previous VERIFICATION.md exists with `status: gaps_found`:
1. Load previous gaps
2. Verify ONLY the previously failed items
3. Check for regressions (items that passed before but now fail)
4. Add `re_verification` field to frontmatter with previous_status, gaps_closed, regressions

## Anti-Patterns for the Verifier

- Do NOT check code quality or style (not your job)
- Do NOT run the application (static analysis only)
- Do NOT trust task completion claims (verify actual files)
- Do NOT skip Level 2/3 checks just because Level 1 passes
