---
name: new-project
description: Initialize a new project to produce .planning/PROJECT.md. Requires either a path to a project vision document (recommended) or a brief project idea as argument. Use when starting a new project, onboarding to existing codebase, or defining what to build next.
argument-hint: "<brief project idea OR path to project document>"
allowed-tools: Read, Bash, Write, AskUserQuestion, Glob, Grep
---

## Objective

Initialize a new project through deep questioning, creating `.planning/PROJECT.md` with clear project context.

This is a thinking partner session, not requirements gathering. Help the user discover and articulate what they want to build.

**Creates:** `.planning/PROJECT.md` — project vision, requirements, constraints, decisions

**After this command:** Continue with separate skills for research, requirements definition, and roadmap creation.


## Process

### Phase 1: Setup Checks

**Execute these checks before ANY user interaction:**

1. **Abort if project exists:**

   ```bash
   [ -f .planning/PROJECT.md ] && echo "ERROR: Project already initialized" && exit 1
   ```

2. **Initialize git repo:**

   ```bash
   if [ -d .git ] || [ -f .git ]; then
       echo "Git repo exists"
   else
       git init
       echo "Initialized new git repo"
   fi
   ```

3. **Detect existing code (brownfield detection):**
   ```bash
   CODE_FILES=$(find . -maxdepth 3 -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" 2>/dev/null | grep -v node_modules | grep -v .git | head -20)
   HAS_PACKAGE=$([ -f package.json ] || [ -f requirements.txt ] || [ -f Cargo.toml ] || [ -f go.mod ] && echo "yes")
   HAS_CODEBASE_MAP=$([ -d .planning/codebase ] && echo "yes")
   ```

**You MUST run all bash commands above before proceeding.**

### Phase 2: Brownfield Offer

**If existing code detected and .planning/codebase/ doesn't exist:**

Check results from setup:

- If `CODE_FILES` is non-empty OR `HAS_PACKAGE` is "yes"
- AND `HAS_CODEBASE_MAP` is NOT "yes"

Use AskUserQuestion:

- header: "Existing Code"
- question: "I detected existing code. Would you like to map the codebase first?"
- options:
  - "Map codebase first" — Run /map-codebase to understand existing architecture (Recommended)
  - "Skip mapping" — Proceed with project initialization

**If "Map codebase first":**

```
Run /map-codebase first, then return to /new-project
```

Exit skill.

**Otherwise:** Continue to Phase 3.

### Phase 3: Gather Project Vision

**$ARGUMENTS is required.** The user must provide either a file path to a project document OR a brief project idea. If $ARGUMENTS is empty, tell the user:

```
Usage: /new-project <brief project idea OR path to project document>

Examples:
  /new-project a CLI tool for managing dotfiles across machines
  /new-project ./docs/vision.md
  /new-project ~/projects/idea.md
```

Exit skill.

**Determine input type:** Check if $ARGUMENTS looks like a file path (starts with `/`, `./`, `~/`, or ends with `.md`/`.txt`). If so, treat as Path A. Otherwise, treat as Path B.

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

### Phase 4: Write PROJECT.md

Synthesize all context into `.planning/PROJECT.md` using the template from `assets/project.md`.

**For greenfield projects:**

Initialize requirements as hypotheses:

```markdown
## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

### Out of Scope

- [Exclusion 1] — [why]
- [Exclusion 2] — [why]
```

All Active requirements are hypotheses until shipped and validated.

**For brownfield projects (codebase map exists):**

Infer Validated requirements from existing code:

1. Read `.planning/codebase/ARCHITECTURE.md` and `STACK.md`
2. Identify what the codebase already does
3. These become the initial Validated set

```markdown
## Requirements

### Validated

- ✓ [Existing capability 1] — existing
- ✓ [Existing capability 2] — existing
- ✓ [Existing capability 3] — existing

### Active

- [ ] [New requirement 1]
- [ ] [New requirement 2]

### Out of Scope

- [Exclusion 1] — [why]
```

**Key Decisions:**

Initialize with any decisions made during questioning:

```markdown
## Key Decisions

| Decision                  | Rationale | Outcome   |
| ------------------------- | --------- | --------- |
| [Choice from questioning] | [Why]     | — Pending |
```

**Last updated footer:**

```markdown
---

_Last updated: [date] after initialization_
```

Do not compress. Capture everything gathered.

**Save PROJECT.md:**

```bash
mkdir -p .planning
```

Write the file to `.planning/PROJECT.md`.

**If git was initialized by this skill (new repo):** Commit automatically:

```bash
git add .planning/PROJECT.md
git commit -m "$(cat <<'EOF'
docs: initialize project

[One-liner from PROJECT.md What This Is section]
EOF
)"
```

**If git already existed (existing repo):** Do NOT commit. Tell the user:

```
Created .planning/PROJECT.md

To commit when ready:
  git add .planning/PROJECT.md && git commit -m "docs: initialize project"
```

### Phase 5: Done

Present completion with next steps:

```
Project initialized.

Created: .planning/PROJECT.md

---

## Next Steps

**Define what to build:**
- Continue with separate skills for research, requirements, and roadmap

**Review project context:**
- Read .planning/PROJECT.md to see captured vision

**Edit before continuing:**
- Update PROJECT.md if anything needs refinement

---
```

## Success Criteria

- [ ] .planning/ directory created
- [ ] Git repo initialized
- [ ] Brownfield detection completed
- [ ] At least one round of questions asked (even with thorough documents)
- [ ] PROJECT.md captures full context
- [ ] PROJECT.md written to .planning/
- [ ] If new repo: committed. If existing repo: user told how to commit
- [ ] User knows next steps
