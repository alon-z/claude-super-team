# Decision Conflict Detection

Before presenting the summary, compare research findings against CONTEXT.md decisions (if CONTEXT.md exists). Look for conflicts where research invalidates or challenges prior decisions:

**Conflict types to detect:**
- **Deprecated/abandoned packages:** A library chosen in CONTEXT.md is deprecated, unmaintained, or has known security issues
- **Better alternatives discovered:** Research found a well-maintained package or built-in solution that replaces something the user planned to do manually
- **API/compatibility issues:** A chosen approach won't work with the existing stack or has breaking changes in current versions
- **Pattern mismatches:** Research reveals that a decided architecture pattern is anti-pattern for the chosen framework or ecosystem

**Process:**

1. Read the RESEARCH.md that was just created
2. Read the phase CONTEXT.md (if it exists)
3. Cross-reference: for each decision in CONTEXT.md, check if research findings contradict, deprecate, or offer a significantly better alternative
4. Build a list of conflicts (if any)

**If conflicts found**, present them and ask the user:

Use AskUserQuestion:

- header: "Conflicts"
- question: "Research found findings that may affect decisions made during discussion:"
- multiSelect: false
- options:
  - label: "Re-discuss (Recommended)"
    description: "{Brief summary of conflicts, e.g., 'chosen package X is deprecated; found library Y that automates manual step Z'}"
  - label: "Keep decisions"
    description: "Proceed to planning with current context as-is"
  - label: "Review first"
    description: "Read both files before deciding"

**On "Re-discuss":** Set next step to `/discuss-phase {N}` in the summary.

**On "Keep decisions":** Set next step to `/plan-phase {N}` in the summary.

**On "Review first":** Show paths to both RESEARCH.md and CONTEXT.md, set next step to `/discuss-phase {N}` (since they'll likely want to update after reviewing).

**If no CONTEXT.md exists or no conflicts found**, set next step to `/plan-phase {N}`.
