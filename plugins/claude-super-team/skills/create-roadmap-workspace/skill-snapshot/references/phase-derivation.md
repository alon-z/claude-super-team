# Phase Derivation Methodology

**Philosophy: requirements drive structure, not templates.**

Analyze the requirements and derive natural delivery boundaries:

1. **Group by capability** -- Which requirements cluster into coherent deliverables?
2. **Identify dependencies** -- Which capabilities depend on others?
3. **Create phases** -- Each phase delivers one complete, verifiable capability.

**Goal-backward thinking for each phase:**

Don't ask "what should we build?" -- ask "what must be TRUE for users when this phase completes?"

For each phase, derive 2-5 success criteria that are:

- Observable from the user's perspective
- Verifiable by a human using the application
- Stated as outcomes, not tasks

Good: "User can log in with email/password and stay logged in across browser sessions"
Bad: "Build authentication system"

**Phase count guidance:**

- Let the work determine the count. Don't pad small projects or compress complex ones.
- 3-5 phases for focused projects, 5-8 for medium, 8-12 for large
- Each phase should feel inevitable given the requirements, not arbitrary

**Anti-patterns:**

- Horizontal layers (all models, then all APIs, then all UI)
- Arbitrary splits to hit a number
- Enterprise PM artifacts (time estimates, Gantt charts, risk matrices)
- Phases for team coordination, documentation, or ceremonies
