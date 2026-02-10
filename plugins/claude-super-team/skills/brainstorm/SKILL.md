---
name: brainstorm
description: Brainstorm features, improvements, and architectural changes for a project. Two modes -- Interactive (collaborative discussion) or Autonomous (Claude deeply analyzes the project and generates bold, creative ideas on its own). Captures decisions in IDEAS.md and optionally updates ROADMAP.md. Use when thinking about what to build next.
argument-hint: "[optional topic or focus area]"
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion, Task, Skill
---

## Objective

Explore new features, improvements, and architectural changes. Two modes: collaborative discussion or autonomous deep analysis. Produces structured IDEAS.md and optionally updates the roadmap.

**Reads:** `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/codebase/` (if exists)
**Creates:** `.planning/IDEAS.md` (or updates existing)
**May invoke:** `/create-roadmap` to add approved ideas as phases

## Process

### Phase 1: Load Context

```bash
[ ! -f .planning/PROJECT.md ] && echo "ERROR: No project found. Run /new-project first." && exit 1
```

You MUST run this check before proceeding.

Read `.planning/PROJECT.md` -- core value, constraints, requirements, key decisions.

Read `.planning/ROADMAP.md` if exists -- current phases, completion status, what's planned.

Read `.planning/STATE.md` if exists -- current position, preferences, blockers.

Check for codebase docs:

```bash
[ -d .planning/codebase ] && ls .planning/codebase/
```

If mapped, read `ARCHITECTURE.md`, `STACK.md`, and `CONVENTIONS.md`.

### Phase 2: Choose Mode

Use AskUserQuestion:

- header: "Mode"
- question: "How do you want to brainstorm?"
- multiSelect: false
- options:
  - label: "Interactive"
    description: "We explore ideas together through discussion"
  - label: "Autonomous"
    description: "Claude goes deep -- analyzes the project, explores the codebase, researches patterns, and comes back with bold ideas"

**If "Interactive":** Continue to Phase 3 (Interactive Path).

**If "Autonomous":** Jump to Phase 6 (Autonomous Path).

---

## Interactive Path

### Phase 3: Define Topic

**If $ARGUMENTS provided:** Use as starting topic.

**If $ARGUMENTS empty:** Use AskUserQuestion:

- header: "Focus"
- question: "What would you like to brainstorm about?"
- multiSelect: false
- options:
  - label: "New feature"
    description: "Explore a feature to add to the project"
  - label: "Improvement"
    description: "Enhance existing functionality"
  - label: "Architecture"
    description: "Evaluate architectural changes"
  - label: "Open-ended"
    description: "Let's explore what's possible"

Follow up with 1-2 targeted questions to narrow focus. Generate options based on actual project context -- reference real modules, features, and constraints from the loaded context.

### Phase 4: Explore Ideas (Iterative)

**4.1. Generate 3-5 concrete ideas** based on topic, project context, and codebase constraints. Each idea: name, brief description, why it matters, key tradeoffs, complexity estimate.

**4.2. Present for selection** via AskUserQuestion (multiSelect: true). User picks which to explore.

**4.3. Deep-dive each selected idea.** Ask 3-4 targeted questions:
1. Scope -- "What should this include vs exclude?"
2. Tradeoffs -- "How do we balance X vs Y?"
3. Integration -- "How does this fit with existing work?"
4. Risk -- "What could go wrong?"

Use AskUserQuestion with concrete options. Always include a "You decide" option.

After questions, present a structured summary. Check if more refinement needed:

- header: "Refine"
- options: "Looks good" / "Needs tweaks" / "Pivot"

**4.4. Decision point** for each idea:

- header: "Decision"
- options: "Approve" / "Defer" / "Reject" / "Keep exploring"

**4.5. After all selected ideas processed:**

- header: "Continue"
- options: "More ideas" (return to 4.1) / "Different topic" (return to Phase 3) / "Wrap up" (continue to Phase 10)

---

## Autonomous Path

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

**Agent 1: Codebase Explorer** (subagent_type: "Explore", thoroughness: "very thorough")

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

**Agent 3: Architecture Reviewer** (subagent_type: "everything-claude-code:architect")

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

---

## Shared Completion (Both Modes)

### Phase 10: Write IDEAS.md

Read `assets/ideas-template.md` as structural reference. Populate with all ideas from the session.

For each idea: name, description, motivation, tradeoffs, implementation notes, decision status.

Create summary sections: approved table, deferred list, rejected list.

```bash
[ -f .planning/IDEAS.md ] && echo "IDEAS_EXISTS=true" || echo "IDEAS_EXISTS=false"
```

**If IDEAS_EXISTS=true:** Read existing file. Prepend new session at top with a `---` separator.

**If IDEAS_EXISTS=false:** Create new `.planning/IDEAS.md`.

Write the file. Do NOT commit.

### Phase 11: Update Roadmap (Optional)

If any ideas were approved:

- header: "Roadmap"
- question: "You approved {N} idea(s). Add them to the roadmap?"
- multiSelect: false
- options:
  - label: "Add to roadmap"
    description: "Invoke /create-roadmap to add new phases"
  - label: "Manual later"
    description: "I'll handle it myself"

**If "Add to roadmap":** Invoke the create-roadmap skill:

```
Use Skill tool with skill: "create-roadmap" and args:
"Add phases for approved brainstorming ideas: {comma-separated idea names with brief descriptions}"
```

### Phase 12: Present Summary

```
Brainstorming session complete: {TOPIC}
Mode: {Interactive / Autonomous}

Ideas explored: {TOTAL_COUNT}
- Approved: {APPROVED_COUNT}
- Deferred: {DEFERRED_COUNT}
- Rejected: {REJECTED_COUNT}

Created/updated:
- .planning/IDEAS.md

{If roadmap updated:}
Updated:
- .planning/ROADMAP.md (added {N} new phase(s))

To commit when ready:
  git add .planning/IDEAS.md && git commit -m "docs: brainstorming session on {topic}"

---

## Next Steps

{Route based on outcomes -- same as before}

---
```

## Success Criteria

- [ ] Project context loaded (PROJECT.md, ROADMAP.md, codebase docs)
- [ ] Mode chosen (Interactive or Autonomous)
- [ ] **Interactive:** Topic established, ideas explored collaboratively, decisions made per idea
- [ ] **Autonomous:** 3 parallel analysis agents spawned, results synthesized, user reviewed output
- [ ] IDEAS.md created or updated
- [ ] If approved ideas exist, user offered roadmap update via /create-roadmap
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps

## Scope Guardrails

**This skill explores, not executes.** Does not create execution plans or write code.

**Roadmap updates delegated.** Invokes `/create-roadmap` rather than editing ROADMAP.md directly.

**Grounded in context.** Ideas reference real project state. Generic ideas that ignore the codebase waste time.

**Autonomous mode is bold, not reckless.** Claude should propose ambitious ideas but always explain the reasoning. Strong opinions, loosely held.
