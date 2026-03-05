---
name: brainstorm
description: "Run a structured brainstorming session for project features, improvements, and architecture. Two modes: Interactive (collaborative Q&A) or Autonomous (3 parallel agents analyze codebase and generate ideas). Captures decisions in IDEAS.md, optionally updates ROADMAP.md. Invoke explicitly with /brainstorm -- not for casual ideation mentions."
argument-hint: "[optional topic or focus area]"
allowed-tools: Read, Write, Glob, Grep, AskUserQuestion, Task, Skill, Bash(test *), Bash(ls *), Bash(cat *)
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

Read `${CLAUDE_SKILL_DIR}/references/interactive-mode.md` for the full interactive brainstorming procedure (topic definition, iterative idea exploration, deep-dive questions, decision gates).

---

## Autonomous Path

Read `${CLAUDE_SKILL_DIR}/references/autonomous-mode.md` for the full autonomous analysis procedure (focus gathering, 3 parallel agent prompts, synthesis methodology, results presentation).

---

## Shared Completion (Both Modes)

### Phase 10: Write IDEAS.md

Read `${CLAUDE_SKILL_DIR}/assets/ideas-template.md` as structural reference. Populate with all ideas from the session.

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

### Phase 11.5: Generate Context Files for New Phases

Read `${CLAUDE_SKILL_DIR}/references/context-generation.md` for the context file generation procedure for new roadmap phases.

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

{If context files created:}
- .planning/phases/{NN}-{slug}/{NN}-CONTEXT.md (for each new phase)

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
- [ ] If phases were added to roadmap, CONTEXT.md files created for each new phase using the standard context template
- [ ] User told how to commit (never auto-commit)
- [ ] User knows next steps

## Scope Guardrails

**This skill explores, not executes.** Does not create execution plans or write code.

**Roadmap updates delegated.** Invokes `/create-roadmap` rather than editing ROADMAP.md directly.

**Grounded in context.** Ideas reference real project state. Generic ideas that ignore the codebase waste time.

**Autonomous mode is bold, not reckless.** Claude should propose ambitious ideas but always explain the reasoning. Strong opinions, loosely held.
