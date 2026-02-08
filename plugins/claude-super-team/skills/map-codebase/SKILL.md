---
name: map-codebase
description: Analyze codebase with parallel mapper agents to produce .planning/codebase/ documents. Use when user wants to understand existing code structure, refresh codebase understanding, onboard to unfamiliar codebase, or before major refactoring. Creates 7 structured documents (STACK, INTEGRATIONS, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS). Supports incremental updates to refresh specific topic areas without rewriting everything.
argument-hint: "[optional: topic to update e.g. 'db and auth', or 'refresh' to remap from scratch]"
context: fork
model: opus
allowed-tools: Read, Bash, Glob, Grep, Write, Task
disable-model-invocation: true
---

<objective>
Analyze existing codebase using parallel general-purpose agents to produce structured codebase documents.

Each mapper agent explores a focus area and **writes documents directly** to `.planning/codebase/`. The orchestrator only receives confirmations, keeping context usage minimal.

Supports two modes:
- **full-map**: Create all documents from scratch (first run or explicit refresh)
- **incremental-update**: Read existing documents, explore only for specific topics, merge findings while preserving unrelated content

Output: .planning/codebase/ folder with 7 structured documents about the codebase state.
</objective>

<context>
Arguments: $ARGUMENTS (optional - topic focus for incremental updates, or "refresh" for full remap)

**Load project state if exists:**
Check for .planning/STATE.md - loads context if project already initialized

**This command can run:**

- Before project initialization (brownfield codebases) - creates codebase map first
- After project initialization (greenfield codebases) - updates codebase map as code evolves
- Anytime to refresh or incrementally update codebase understanding
  </context>

<when_to_use>
**Use map-codebase for:**

- Brownfield projects before initialization (understand existing code first)
- Refreshing codebase map after significant changes
- Incrementally updating docs after changes to specific areas (e.g., `/map-codebase db and auth`)
- Onboarding to an unfamiliar codebase
- Before major refactoring (understand current state)
- When existing documentation is outdated

**Skip map-codebase for:**

- Greenfield projects with no code yet (nothing to map)
- Trivial codebases (<5 files)
  </when_to_use>

<process>

<step name="detect_mode">
Determine the operating mode based on existing docs and user arguments.

**1. Check if docs exist:**

```bash
ls .planning/codebase/*.md 2>/dev/null
```

**2. Parse arguments for "refresh" keyword:**

Check if `$ARGUMENTS` contains the word "refresh" (case-insensitive).

**3. Determine mode and topic focus:**

| Docs exist? | "refresh" in args? | Mode | Topic focus |
|---|---|---|---|
| No | N/A | `full-map` | $ARGUMENTS (or empty) |
| Yes | Yes | `full-map` | $ARGUMENTS with "refresh" stripped |
| Yes | No | `incremental-update` | $ARGUMENTS (or empty) |

**4. If mode is `full-map` and docs exist (refresh requested):**

```bash
rm -rf .planning/codebase/
```

**5. Tell the user what's happening:**

For full-map:
```
Mode: full-map
Creating codebase documentation from scratch...
```

For incremental-update:
```
Mode: incremental-update
Topic focus: {topic} (or "all areas" if empty)
Updating existing codebase documentation...
```

Continue to create_structure.
</step>

<step name="create_structure">
Create .planning/codebase/ directory:

```bash
mkdir -p .planning/codebase
```

**Expected output files:**

- STACK.md (from tech mapper)
- INTEGRATIONS.md (from tech mapper)
- ARCHITECTURE.md (from arch mapper)
- STRUCTURE.md (from arch mapper)
- CONVENTIONS.md (from quality mapper)
- TESTING.md (from quality mapper)
- CONCERNS.md (from concerns mapper)

Continue to spawn_agents.
</step>

<step name="spawn_agents">
Spawn 4 parallel general-purpose mapper agents.

Use Task tool with `subagent_type="general-purpose"`, `model="sonnet"`, and `run_in_background=true` for parallel execution.

**CRITICAL:** Each agent receives embedded mapper instructions from `references/mapper-instructions.md` and must write documents directly. Each agent also receives the **MODE** and **TOPIC FOCUS** determined in detect_mode.

Read `references/mapper-instructions.md` and `references/templates.md` first. Then spawn all 4 agents in a single message (parallel).

---

**Agent 1: Tech Focus**

```
subagent_type: "general-purpose"
model: "sonnet"
run_in_background: true
description: "Map codebase tech stack"
prompt: """
[Paste full contents of references/mapper-instructions.md here]

MODE: {mode}
TOPIC FOCUS: {topic_focus}

Focus: tech

Analyze this codebase for technology stack and external integrations.

Write these documents to .planning/codebase/:
- STACK.md - Languages, runtime, frameworks, dependencies, configuration
- INTEGRATIONS.md - External APIs, databases, auth providers, webhooks

[Paste full contents of references/templates.md here — only the STACK.md and INTEGRATIONS.md templates]

{If mode is full-map:}
Explore thoroughly. Write documents directly using templates. Return confirmation only.

{If mode is incremental-update:}
Read existing documents from .planning/codebase/ first. Explore codebase specifically for: {topic_focus}. Update documents following the incremental update rules in your instructions. Write updated documents. Return confirmation only.
"""
```

---

**Agent 2: Architecture Focus**

```
subagent_type: "general-purpose"
model: "sonnet"
run_in_background: true
description: "Map codebase architecture"
prompt: """
[Paste full contents of references/mapper-instructions.md here]

MODE: {mode}
TOPIC FOCUS: {topic_focus}

Focus: arch

Analyze this codebase architecture and directory structure.

Write these documents to .planning/codebase/:
- ARCHITECTURE.md - Pattern, layers, data flow, abstractions, entry points
- STRUCTURE.md - Directory layout, key locations, naming conventions

[Paste full contents of references/templates.md here — only the ARCHITECTURE.md and STRUCTURE.md templates]

{If mode is full-map:}
Explore thoroughly. Write documents directly using templates. Return confirmation only.

{If mode is incremental-update:}
Read existing documents from .planning/codebase/ first. Explore codebase specifically for: {topic_focus}. Update documents following the incremental update rules in your instructions. Write updated documents. Return confirmation only.
"""
```

---

**Agent 3: Quality Focus**

```
subagent_type: "general-purpose"
model: "sonnet"
run_in_background: true
description: "Map codebase conventions"
prompt: """
[Paste full contents of references/mapper-instructions.md here]

MODE: {mode}
TOPIC FOCUS: {topic_focus}

Focus: quality

Analyze this codebase for coding conventions and testing patterns.

Write these documents to .planning/codebase/:
- CONVENTIONS.md - Code style, naming, patterns, error handling
- TESTING.md - Framework, structure, mocking, coverage

[Paste full contents of references/templates.md here — only the CONVENTIONS.md and TESTING.md templates]

{If mode is full-map:}
Explore thoroughly. Write documents directly using templates. Return confirmation only.

{If mode is incremental-update:}
Read existing documents from .planning/codebase/ first. Explore codebase specifically for: {topic_focus}. Update documents following the incremental update rules in your instructions. Write updated documents. Return confirmation only.
"""
```

---

**Agent 4: Concerns Focus**

```
subagent_type: "general-purpose"
model: "sonnet"
run_in_background: true
description: "Map codebase concerns"
prompt: """
[Paste full contents of references/mapper-instructions.md here]

MODE: {mode}
TOPIC FOCUS: {topic_focus}

Focus: concerns

Analyze this codebase for technical debt, known issues, and areas of concern.

Write this document to .planning/codebase/:
- CONCERNS.md - Tech debt, bugs, security, performance, fragile areas

[Paste full contents of references/templates.md here — only the CONCERNS.md template]

{If mode is full-map:}
Explore thoroughly. Write document directly using template. Return confirmation only.

{If mode is incremental-update:}
Read existing document from .planning/codebase/ first. Explore codebase specifically for: {topic_focus}. Update document following the incremental update rules in your instructions. Write updated document. Return confirmation only.
"""
```

Continue to collect_confirmations.
</step>

<step name="collect_confirmations">
Wait for all 4 agents to complete.

Read each agent's output to collect confirmations.

**Expected confirmation format from each agent (full-map):**

```
## Mapping Complete

**Focus:** {focus}
**Documents written:**
- `.planning/codebase/{DOC1}.md` ({N} lines)
- `.planning/codebase/{DOC2}.md` ({N} lines)

Ready for orchestrator summary.
```

**Expected confirmation format from each agent (incremental-update):**

```
## Mapping Updated

**Focus:** {agent_focus}
**Topic:** {topic_focus}
**Documents updated:**
- `.planning/codebase/{DOC1}.md` ({N} lines, updated: {sections changed})
- `.planning/codebase/{DOC2}.md` ({N} lines, updated: {sections changed})

Ready for orchestrator summary.
```

**What you receive:** Just file paths, line counts, and (in update mode) which sections changed. NOT document contents.

If any agent failed, note the failure and continue with successful documents.

Continue to verify_output.
</step>

<step name="verify_output">
Verify all documents created successfully:

```bash
ls -la .planning/codebase/
wc -l .planning/codebase/*.md
```

**Verification checklist:**

- All 7 documents exist
- No empty documents (each should have >20 lines)

If any documents missing or empty, note which agents may have failed.

Continue to scan_for_secrets.
</step>

<step name="scan_for_secrets">
**CRITICAL SECURITY CHECK:** Scan output files for accidentally leaked secrets before user decides whether to commit.

Run secret pattern detection:

```bash
# Check for common API key patterns in generated docs
grep -E '(sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]+|sk_test_[a-zA-Z0-9]+|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9_-]+|AKIA[A-Z0-9]{16}|xox[baprs]-[a-zA-Z0-9-]+|-----BEGIN.*PRIVATE KEY|eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.)' .planning/codebase/*.md 2>/dev/null && SECRETS_FOUND=true || SECRETS_FOUND=false
```

**If SECRETS_FOUND=true:**

```
SECURITY ALERT: Potential secrets detected in codebase documents!

Found patterns that look like API keys or tokens in:
[show grep output]

This would expose credentials if committed.

**Action required:**
1. Review the flagged content above
2. If these are real secrets, they must be removed before committing
3. Consider adding sensitive files to Claude Code "Deny" permissions

Pausing. Reply "safe to proceed" if the flagged content is not actually sensitive, or edit the files first.
```

Wait for user confirmation before continuing to offer_next.

**If SECRETS_FOUND=false:**

Continue to offer_next.
</step>

<step name="offer_next">
Present completion summary and next steps.

**Get line counts:**

```bash
wc -l .planning/codebase/*.md
```

**Output format for full-map mode:**

````
Codebase mapping complete.

Created .planning/codebase/:
- STACK.md ([N] lines) - Technologies and dependencies
- ARCHITECTURE.md ([N] lines) - System design and patterns
- STRUCTURE.md ([N] lines) - Directory layout and organization
- CONVENTIONS.md ([N] lines) - Code style and patterns
- TESTING.md ([N] lines) - Test structure and practices
- INTEGRATIONS.md ([N] lines) - External services and APIs
- CONCERNS.md ([N] lines) - Technical debt and issues


---

## Next Steps

**Review documents:**
Read any of the generated documents to understand the codebase better

**Commit if desired:**
```bash
git add .planning/codebase/*.md
git commit -m "docs: map existing codebase"
````

**Also available:**

- Re-run mapping to refresh
- Review specific file: `cat .planning/codebase/STACK.md`
- Edit any document before committing

---

```

**Output format for incremental-update mode:**

````
Codebase mapping updated.

Topic focus: {topic_focus} (or "all areas")

Updated .planning/codebase/:
- STACK.md ([N] lines) - {sections changed or "unchanged"}
- ARCHITECTURE.md ([N] lines) - {sections changed or "unchanged"}
- STRUCTURE.md ([N] lines) - {sections changed or "unchanged"}
- CONVENTIONS.md ([N] lines) - {sections changed or "unchanged"}
- TESTING.md ([N] lines) - {sections changed or "unchanged"}
- INTEGRATIONS.md ([N] lines) - {sections changed or "unchanged"}
- CONCERNS.md ([N] lines) - {sections changed or "unchanged"}


---

## Next Steps

**Review changes:**
Check the updated sections in the documents above

**Commit if desired:**
```bash
git add .planning/codebase/*.md
git commit -m "docs: update codebase map ({topic_focus})"
````

**Also available:**

- Update another area: `/map-codebase {other topic}`
- Full refresh: `/map-codebase refresh`
- Review specific file: `cat .planning/codebase/STACK.md`

---

```

End workflow.
</step>

</process>

<success_criteria>
- .planning/codebase/ directory created
- Mode correctly detected (full-map vs incremental-update)
- 4 parallel general-purpose agents spawned with run_in_background=true and model=sonnet
- Agents receive correct MODE and TOPIC FOCUS in their prompts
- In incremental-update mode, agents read existing docs, explore only for topic focus, and merge
- Agents write documents directly (orchestrator doesn't receive document contents)
- Read agent output to collect confirmations
- All 7 codebase documents exist
- Security scan for secrets completed
- Clear completion summary with line counts (and section changes in update mode)
- User offered clear next steps
</success_criteria>
