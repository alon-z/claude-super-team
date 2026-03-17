---
name: new-project
description: Initialize a new project to produce .planning/PROJECT.md. Requires either a path to a project vision document (recommended), a brief project idea, or `--discuss` for open-ended brainstorming. Use when starting a new project, onboarding to existing codebase, or defining what to build next.
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

**Check for --discuss flag first.** If $ARGUMENTS contains `--discuss`, strip the flag from $ARGUMENTS and enter Path C (Discussion mode). If $ARGUMENTS is ONLY `--discuss` (nothing else after stripping), that is valid -- do not exit.

**If $ARGUMENTS is empty (and --discuss was NOT present)**, tell the user:

```
Usage: /new-project <brief project idea OR path to project document>

Examples:
  /new-project a CLI tool for managing dotfiles across machines
  /new-project ./docs/vision.md
  /new-project --discuss
```

Exit skill.

**Determine input type:** Check if $ARGUMENTS looks like a file path (starts with `/`, `./`, `~/`, or ends with `.md`/`.txt`). If so, treat as Path A. If `--discuss` was detected, use Path C. Otherwise, treat as Path B.

**Path A: Project document provided** -- Analyze the document, identify gaps, ask clarifying questions.

**Path B: Brief idea provided** -- Use the idea to drive an exploratory questioning conversation.

**Path C: Discussion mode** -- Open-ended brainstorming session starting from zero context.

1. Start with a broad domain question using AskUserQuestion:
   - header: "What area?"
   - question: "What domain or area are you interested in building for?"
   - options:
     - "Developer tools" -- CLIs, libraries, DevOps, productivity for engineers
     - "Consumer app" -- Mobile, web, social, lifestyle, entertainment
     - "Business/SaaS" -- B2B workflows, dashboards, internal tools, automation
     - "Data/AI" -- Pipelines, ML tools, analytics, LLM applications
     - "Let me describe" -- I have something specific in mind

2. Based on the answer, ask progressively narrower questions using AskUserQuestion to discover:
   - **Core problem:** What frustration or opportunity drives this? What exists today and why is it insufficient?
   - **Target users:** Who specifically would use this? What does their day look like?
   - **Success shape:** What does "working" look like? What would a user actually do with it?
   - **Key constraints:** Timeline, solo vs team, technical preferences, scale expectations

3. Use the same questioning techniques as Path B (challenge vagueness, make abstract concrete, surface motivation) but start from zero context rather than a provided idea. Each answer narrows the next question.

4. When enough context has been gathered to write a clear PROJECT.md, hit the same decision gate as Paths A and B ("Ready to create PROJECT.md?" / "Keep exploring").

If $ARGUMENTS contained text beyond `--discuss`, use that text as additional seed context for the first question (e.g., `/new-project --discuss something for developers` -- start the domain question pre-focused on developer tools).

Read `${CLAUDE_SKILL_DIR}/references/questioning-methodology.md` for the detailed questioning methodology (Path A: document analysis, Path B: brief idea exploration, Path C: discussion mode, AskUserQuestion patterns, anti-patterns).

### Phase 3.5: Execution Model Preference

Before writing PROJECT.md, ask the user about their preferred execution model:

```
AskUserQuestion:
  header: "Exec model"
  question: "Which model should execution agents use when building code?"
  options:
    - "Opus (Recommended)" -- "Higher reasoning quality for all execution tasks."
    - "Sonnet" -- "Faster and cheaper. Opus still used for TDD, security, planning, and verification."
```

Store the answer as `$EXEC_MODEL` (`sonnet` or `opus`). This will be written to the `## Preferences` section in PROJECT.md.

### Phase 4: Write PROJECT.md

Read `${CLAUDE_SKILL_DIR}/references/project-writing-guide.md` for PROJECT.md population details (greenfield/brownfield requirements, key decisions, save/commit flow).

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
