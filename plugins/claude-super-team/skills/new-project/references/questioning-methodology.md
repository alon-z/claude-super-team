# Questioning Methodology

**Path A: Project document provided**

Read the file. Extract everything relevant: vision, features, constraints, target users, technical decisions, scope boundaries.

A well-defined document is the best possible input -- far richer context than a back-and-forth conversation.

Assess what's covered vs what's missing against the context checklist:

- [ ] What they're building (concrete enough to explain to a stranger)
- [ ] Why it needs to exist (the problem or desire driving it)
- [ ] Who it's for (even if just themselves)
- [ ] What "done" looks like (observable outcomes)

**Always ask at least one round of questions, even for thorough documents.** No document is perfect -- there are always implicit assumptions, unstated priorities, or edges worth probing. Examples of good questions for comprehensive docs:

- Prioritization: "Your doc lists many features -- if you could only ship three, which three?"
- Edges: "You describe X -- what happens when Y goes wrong?"
- Motivation: "What's the one thing that made you start this?"
- Tradeoffs: "You mention both A and B -- if they conflict, which wins?"
- Scope: "Is Z deliberately excluded or just not mentioned yet?"

If clear gaps exist in the checklist, ask about those first via AskUserQuestion. Reference specific parts of their document in the question text.

Use AskUserQuestion for every question. Craft options that reference the document: "Your doc mentions X but doesn't clarify Y" with concrete interpretations as options.

After at least one round of AskUserQuestion calls, proceed to the decision gate.

**Path B: Brief idea provided**

The user gave a short description. Use it to formulate your first AskUserQuestion. Based on what they wrote, identify the most important thing to clarify and ask about it using AskUserQuestion with concrete options.

Example: if they said "a CLI tool for managing dotfiles", your first question might be:

- header: "Dotfiles"
- question: "What kind of dotfiles management are you after?"
- options: ["Sync across machines", "Version control configs", "Auto-setup new machines", "Let me explain"]

**Follow the thread:**

Each answer informs the next AskUserQuestion. Keep probing with AskUserQuestion calls:

- What excited them
- What problem sparked this
- What they mean by vague terms
- What it would actually look like
- What's already decided

**Questioning techniques (use these as AskUserQuestion question text, with concrete options):**

- Challenge vagueness: "Good" means what? "Users" means who? "Simple" means how?
- Make abstract concrete: "Walk me through using this" / "What does that look like?"
- Clarify ambiguity: "When you say Z, do you mean A or B?"
- Surface motivation: "What prompted this?" / "What does this replace?"
- Find success criteria: "How will you know this is working?"

**Use AskUserQuestion effectively:**

Present concrete options to help users think by reacting:

**Good options:**

- Interpretations of what they might mean
- Specific examples to confirm or deny
- Concrete choices that reveal priorities

**Bad options:**

- Generic categories ("Technical", "Business", "Other")
- Leading options that presume an answer
- Too many options (2-4 is ideal)

**Example — vague answer:**
User says "it should be fast"

- header: "Fast"
- question: "Fast how?"
- options: ["Sub-second response", "Handles large datasets", "Quick to build", "Let me explain"]

**Example — following thread:**
User mentions "frustrated with current tools"

- header: "Frustration"
- question: "What specifically frustrates you?"
- options: ["Too many clicks", "Missing features", "Unreliable", "Let me explain"]

**Context checklist (background, not spoken -- Path B only):**

Mentally check these as you go. If gaps remain, weave questions naturally:

- [ ] What they're building (concrete enough to explain to a stranger)
- [ ] Why it needs to exist (the problem or desire driving it)
- [ ] Who it's for (even if just themselves)
- [ ] What "done" looks like (observable outcomes)

**Path C: Discussion mode (no input)**

The user invoked `/new-project --discuss` with little or no seed context. The goal is to progressively narrow from a broad domain to a concrete enough vision for PROJECT.md.

**Progressive narrowing pattern:**

1. **Domain** -- What area? (developer tools, consumer, SaaS, data/AI, open-ended)
2. **Problem** -- What frustration or opportunity within that domain?
3. **Users** -- Who specifically has this problem? What does their workflow look like?
4. **Solution shape** -- What would using this actually feel like? CLI? Web app? Library?
5. **Success criteria** -- How will you know it's working? What changes for the user?

Each stage uses AskUserQuestion with concrete options derived from the previous answer. Never ask generic questions -- always ground options in what the user just said.

**Example sequence 1 -- "Developer tools":**

```
AskUserQuestion:
  header: "Developer tools"
  question: "What kind of developer pain are you looking to solve?"
  options:
    - "Local dev environment" -- Setup, config, toolchain management
    - "Code quality" -- Linting, testing, review automation
    - "Deployment/DevOps" -- CI/CD, infrastructure, monitoring
    - "Let me describe" -- Something else
```

User picks "Local dev environment":

```
AskUserQuestion:
  header: "Local dev"
  question: "What specifically frustrates you about local dev setup?"
  options:
    - "Inconsistent environments" -- Works on my machine, breaks on yours
    - "Slow onboarding" -- New team members take days to get running
    - "Config drift" -- Dotfiles, tool versions, settings get out of sync
    - "Let me explain"
```

User picks "Config drift":

```
AskUserQuestion:
  header: "Config drift"
  question: "What have you tried so far to manage this?"
  options:
    - "Dotfile repos" -- Git-tracked dotfiles, but it's manual
    - "Nix/Homebrew bundles" -- Package managers, but they drift
    - "Nothing systematic" -- Just re-configure when things break
    - "Let me explain"
```

Now the conversation has enough specificity to ask about scope, target users, and success criteria -- the same depth Path B reaches after a few rounds.

**Example sequence 2 -- "Let me describe":**

```
AskUserQuestion:
  header: "Your idea"
  question: "Give me the elevator pitch -- what would this thing do?"
  options:
    - "Let me type it out" -- Free-form description
```

User describes their idea. From here, treat it like Path B -- you now have a brief idea to probe. Ask about the most ambiguous part of what they described.

**Example sequence 3 -- "Data/AI":**

```
AskUserQuestion:
  header: "Data/AI"
  question: "What part of the data/AI space are you targeting?"
  options:
    - "Data pipelines" -- ETL, transformation, orchestration
    - "ML tooling" -- Training, evaluation, experiment tracking
    - "LLM applications" -- Agents, RAG, prompt management
    - "Analytics" -- Dashboards, reporting, business intelligence
    - "Let me describe"
```

**Key differences from Path B:**
- Path B starts with a concrete idea and probes outward (clarifying, challenging, exploring edges)
- Path C starts with nothing and funnels inward (domain -> problem -> users -> shape -> criteria)
- Path C requires more AskUserQuestion rounds before reaching the decision gate (typically 4-6 vs 2-4 for Path B)
- Once Path C reaches sufficient specificity, it converges with Path B's questioning style

**Same anti-patterns apply** (see below). Additionally for Path C, avoid:
- Asking "What do you want to build?" as the first question -- too open, paralyzing
- Skipping the domain stage -- it anchors the whole conversation
- Treating the domain choice as final -- users often pivot as they think out loud

**Same decision gate applies.** When you could write a clear PROJECT.md, ask "Ready to create PROJECT.md?" / "Keep exploring" -- identical to Paths A and B.

**Anti-patterns to avoid:**

- Checklist walking — Going through domains regardless of what they said
- Canned questions — "What's your core value?" regardless of context
- Corporate speak — "What are your success criteria?" "Who are your stakeholders?"
- Interrogation — Firing questions without building on answers
- Rushing — Minimizing questions to get to "the work"
- Shallow acceptance — Taking vague answers without probing
- Premature constraints — Asking about tech stack before understanding the idea

**Decision gate:**

When you could write a clear PROJECT.md, use AskUserQuestion:

- header: "Ready?"
- question: "I think I understand what you're after. Ready to create PROJECT.md?"
- options:
  - "Create PROJECT.md" — Let's move forward
  - "Keep exploring" — I want to share more / ask me more

If "Keep exploring" — ask what they want to add, or identify gaps and probe naturally.

Loop until "Create PROJECT.md" selected.
