# Codebase Exploration

Before identifying gray areas, explore the actual codebase to ground the discussion in reality.

**Why:** Generic gray areas ("JWT vs sessions?") waste the user's time. Codebase-aware gray areas ("There's an existing `middleware/auth.ts` using Passport.js -- extend it or replace?") surface real decisions.

**Step 1: Check for codebase mapping**

```bash
ls .planning/codebase/ 2>/dev/null
```

If `.planning/codebase/` exists, read the docs most relevant to this phase's domain:
- Always read: `ARCHITECTURE.md`, `STACK.md`
- Read `CONVENTIONS.md` if the phase involves writing new code patterns
- Read `INTEGRATIONS.md` if the phase involves external services or APIs
- Read `TESTING.md` if the phase has testing-related success criteria

Store key findings (existing patterns, relevant files, tech choices) for use in Phase 4.

**Step 2: Spawn Explore agent for targeted codebase analysis**

Regardless of whether codebase mapping exists, spawn an Explore agent (subagent_type: "Explore") to find code directly relevant to this phase. The agent should:

- Search for files, functions, and patterns related to the phase domain keywords
- Identify existing implementations that the phase will extend, modify, or interact with
- Note conventions, patterns, and tech choices already established in the codebase
- Flag potential conflicts or constraints the user should know about

**Prompt template for the Explore agent:**

```
Explore this codebase to find code relevant to implementing: "{phase_goal}"

Phase success criteria:
{list success criteria from roadmap}

Find and report:
1. Existing files/modules directly related to this phase's domain
2. Patterns and conventions already established (naming, structure, error handling)
3. Dependencies and tech choices relevant to this phase
4. Integration points -- code this phase will need to interact with
5. Potential constraints or conflicts (e.g., existing implementations that overlap)

Be thorough but focused on what matters for planning this specific phase.
Report findings as a structured summary, not raw file contents.
```

Use `subagent_type: "Explore"` and set thoroughness to "medium" in the prompt.

**Step 3: Synthesize findings**

Combine codebase mapping docs (if available) and Explore agent results into a concise "Codebase Context" summary:

```
CODEBASE CONTEXT FOR PHASE {N}:
- Existing related code: {list key files/modules found}
- Established patterns: {relevant conventions, tech choices}
- Integration points: {code this phase will interact with}
- Constraints: {things that limit implementation choices}
```

This summary feeds directly into Phase 4 to produce grounded gray areas.
