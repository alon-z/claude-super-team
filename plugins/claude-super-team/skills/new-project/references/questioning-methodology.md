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
