---
name: new-project
description: Initialize a new project to produce .planning/PROJECT.md. Requires either a path to a project vision document (recommended) or a brief project idea as argument. Use when starting a new project, onboarding to existing codebase, or defining what to build next.
argument-hint: "<brief project idea OR path to project document>"
allowed-tools: Read, Write, AskUserQuestion, Glob, Grep, Bash(git *), Bash(mkdir *), Bash(find *), Bash(test *)
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

**Path A: Project document provided** -- Analyze the document, identify gaps, ask clarifying questions.

**Path B: Brief idea provided** -- Use the idea to drive an exploratory questioning conversation.

Read `references/questioning-methodology.md` for the detailed questioning methodology (Path A: document analysis, Path B: brief idea exploration, AskUserQuestion patterns, anti-patterns).

### Phase 3.5: Execution Model Preference

Before writing PROJECT.md, ask the user about their preferred execution model:

```
AskUserQuestion:
  header: "Exec model"
  question: "Which model should execution agents use when building code?"
  options:
    - "Sonnet (Recommended)" -- "Faster and cheaper. Opus still used for TDD, security, planning, and verification."
    - "Opus" -- "Higher reasoning quality for all execution tasks. Slower and more expensive."
```

Store the answer as `$EXEC_MODEL` (`sonnet` or `opus`). This will be written to the `## Preferences` section in PROJECT.md.

### Phase 4: Write PROJECT.md

Read `references/project-writing-guide.md` for PROJECT.md population details (greenfield/brownfield requirements, key decisions, save/commit flow).

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
