# Deep-Dive Questioning Loop

For each selected area from Phase 5, run this loop:

**6.1. Generate 4 targeted questions** for this area. Questions should:
- Progress from high-level to specific
- Be answerable with concrete decisions, not philosophy
- Build on previous answers within the same area

Example for "Token storage location" area:
1. "Where should access tokens be stored?"
2. "Where should refresh tokens be stored?"
3. "What's the acceptable token lifetime?"
4. "How should expired tokens be handled?"

**6.2. Ask each question sequentially** using AskUserQuestion with 2-4 options. Always include:
- Concrete options (e.g., "httpOnly cookies", "localStorage", "sessionStorage")
- "You decide" option (captures areas for Claude's Discretion)

**6.3. After 4 questions, check if more needed** via AskUserQuestion:

- header: "Continue"
- question: "Anything else to clarify about {area name}?"
- multiSelect: false
- options:
  - label: "All set"
    description: "Move to next area"
  - label: "Keep discussing"
    description: "Ask more questions about this area"

**On "Keep discussing":** Generate 2-4 more questions, ask them, then check again. Limit: 3 rounds per area.

**6.4. Track decisions:**

Build a structured record as you go:

```
{
  "area": "{area name}",
  "decisions": [
    {"question": "...", "answer": "...", "rationale": "..." }
  ],
  "discretion": [ "..." ],  // "You decide" answers
  "deferred": [ "..." ]      // Ideas mentioned but out of scope
}
```

**Identifying deferred ideas:** If user mentions something clearly outside phase scope during discussion (e.g., "we should also add 2FA" when phase is just basic auth), acknowledge it and ask:

- header: "Defer"
- question: "'{idea}' sounds valuable but may be outside Phase {N} scope. How should we handle it?"
- options:
  - label: "Defer to later"
    description: "Capture for future phase"
  - label: "Include now"
    description: "Expand this phase scope"

If "Defer to later", add to deferred list. If "Include now", integrate into current area decisions.
