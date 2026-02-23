# Autonomous Analysis Procedure

### Phase 6: Gather Focus (Optional)

If $ARGUMENTS provided, use as focus area for the analysis (e.g., "performance", "user experience", "new integrations").

If $ARGUMENTS empty, use AskUserQuestion:

- header: "Scope"
- question: "Any area you want me to focus on, or should I explore everything?"
- multiSelect: false
- options:
  - label: "Explore all"
    description: "Analyze the entire project -- features, architecture, DX, performance, security, integrations"
  - label: "Features only"
    description: "Focus on new capabilities and user-facing additions"
  - label: "Technical"
    description: "Focus on architecture, performance, DX, and tech debt"
  - label: "Let me specify"
    description: "I have a specific area in mind"

This is the ONLY question asked before Claude takes over. After this, Claude works autonomously until presenting results.

### Phase 7: Deep Analysis

Spawn 3 parallel analysis agents via the Task tool. Each agent receives the full project context (PROJECT.md content, ROADMAP.md content, codebase docs content) inlined in its prompt.

**Agent 1: Codebase Explorer** (subagent_type: "Explore", thoroughness: "very thorough", model: "opus")

```
Prompt: Deeply explore this codebase to find opportunities for improvement and new features.

PROJECT CONTEXT:
{inline PROJECT.md content}

CURRENT ROADMAP:
{inline ROADMAP.md content or "No roadmap yet"}

CODEBASE DOCS:
{inline ARCHITECTURE.md, STACK.md, CONVENTIONS.md content or "Not mapped yet"}

Analyze and report:
1. ARCHITECTURE GAPS: Missing abstractions, inconsistent patterns, coupling issues, scaling bottlenecks
2. FEATURE OPPORTUNITIES: Capabilities the codebase is close to supporting but doesn't yet, natural extensions of existing features
3. DEVELOPER EXPERIENCE: Pain points in the codebase -- complex code, missing types, test gaps, confusing patterns, documentation holes
4. INTEGRATION POTENTIAL: External services, APIs, or tools the project could benefit from based on its stack and domain
5. TECHNICAL DEBT: Code that should be refactored, deprecated patterns, performance risks

For each finding, note the specific files/modules involved and why it matters.
Be bold and specific. Don't hedge -- state what you'd change and why.
```

**Agent 2: Creative Strategist** (subagent_type: "general-purpose", model: "opus")

```
Prompt: You are a senior product strategist analyzing a software project. Think beyond the obvious. Generate creative, ambitious ideas.

PROJECT CONTEXT:
{inline PROJECT.md content}

CURRENT ROADMAP:
{inline ROADMAP.md content or "No roadmap yet"}

CODEBASE DOCS:
{inline ARCHITECTURE.md, STACK.md content or "Not mapped yet"}

{If focus area specified: "FOCUS AREA: {focus}"}

Generate ideas across these dimensions:
1. FEATURES USERS WOULD LOVE: What would make users say "finally" or "I didn't know I needed this"? Think about workflows, not just features.
2. MOONSHOTS: Bold ideas that could transform the project. What would a 10x version look like?
3. QUICK WINS: Low-effort changes with outsized impact. What's the fastest path to more value?
4. COMPETITIVE EDGES: What would make this project stand out? What are similar projects doing that this one isn't?
5. EXPERIENCE IMPROVEMENTS: UX polish, performance gains, developer experience, error handling, onboarding

For each idea:
- Give it a clear, memorable name
- Describe what it does in 2-3 sentences
- Explain WHY it matters (the motivation, not just the feature)
- Estimate effort: Low / Medium / High
- Rate potential impact: Low / Medium / High / Transformative

Be opinionated. Take strong positions. Propose things the user hasn't thought of.
Generate at least 8-12 ideas. Quality over quantity, but don't hold back.
```

**Agent 3: Architecture Reviewer** (subagent_type: "everything-claude-code:architect", model: "opus")

```
Prompt: Review this project's architecture and propose improvements.

PROJECT CONTEXT:
{inline PROJECT.md content}

CURRENT ROADMAP:
{inline ROADMAP.md content or "No roadmap yet"}

CODEBASE DOCS:
{inline ARCHITECTURE.md, STACK.md, CONVENTIONS.md content or "Not mapped yet"}

Analyze and propose:
1. STRUCTURAL IMPROVEMENTS: Better module boundaries, clearer separation of concerns, improved data flow
2. SCALABILITY: What breaks at 10x scale? What should be redesigned now?
3. RESILIENCE: Error handling gaps, missing fallbacks, single points of failure
4. PATTERNS: Modern patterns the project could adopt (from its ecosystem) that would simplify code
5. SECURITY HARDENING: Attack surface reduction, auth improvements, data protection

For each proposal, explain the current state, the proposed change, and the concrete benefit.
Prioritize by impact. Be specific about what to change and where.
```

### Phase 8: Synthesize Results

Collect all three agent outputs. Deduplicate overlapping ideas. Merge complementary findings.

Organize into a unified list of ideas, categorized as:

- **Quick Wins** -- Low effort, clear value. Do these first.
- **Strategic Features** -- Medium-to-high effort, significant user value.
- **Architecture & Technical** -- Infrastructure, performance, DX improvements.
- **Moonshots** -- Bold, ambitious ideas that could transform the project.
- **Deferred / Nice-to-Have** -- Good ideas with unclear timing.

For each idea, synthesize a final entry:
- **Name**: Clear, memorable
- **What**: 2-3 sentence description
- **Why**: Motivation and expected impact
- **Effort**: Low / Medium / High
- **Impact**: Low / Medium / High / Transformative
- **Source**: Which analysis surfaced it (codebase / strategy / architecture)

Rank ideas within each category by impact-to-effort ratio.

### Phase 9: Present Autonomous Results

Display the full results to the user as a structured report before writing to file.

Present the top ideas across categories. Be bold -- include Claude's opinion on what matters most.

Then use AskUserQuestion:

- header: "Review"
- question: "These are my recommendations. How do you want to proceed?"
- multiSelect: false
- options:
  - label: "Review each"
    description: "Go through ideas one by one and decide: approve, defer, or reject"
  - label: "Approve all"
    description: "Accept all recommendations as-is"
  - label: "Save as-is"
    description: "Write everything to IDEAS.md without decisions"

**If "Review each":** For each idea, use AskUserQuestion with options: "Approve" / "Defer" / "Reject" / "Discuss further". If "Discuss further", ask 2-3 clarifying questions about that idea, then re-present the decision.

**If "Approve all":** Mark all ideas as approved.

**If "Save as-is":** Write all ideas without decision markers. User will review later.
