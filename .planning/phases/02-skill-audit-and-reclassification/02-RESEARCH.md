# Research for Phase 2: Skill Audit & Reclassification

## User Constraints

### Locked Decisions

1. **Execution Approach**: Manual interactive review -- each skill is presented individually with its frontmatter, behavior summary, and capability comparison. The user makes the final classification decision (remain/convert/hybrid/needs additions) for each skill.

2. **Review Grouping**: Review skills one at a time with deep focus per skill. No batching by plugin or role.

3. **Review Order**: Follow the pipeline workflow sequence: new-project -> create-roadmap -> discuss-phase -> research-phase -> plan-phase -> execute-phase -> progress -> quick-plan -> phase-feedback -> brainstorm -> add-security-findings -> cst-help -> map-codebase, then marketplace-utils skills (marketplace-manager, skill-creator), then task-management skills (linear-sync, github-issue-manager), and finally the phase-researcher agent.

### Claude's Discretion

- **Audit depth per skill**: How deep to go beyond frontmatter -- whether to also review prompt quality, logic structure, and behavioral patterns (decided per skill based on complexity)
- **Output format**: How to structure the per-skill audit findings document -- table-based vs narrative, single document vs per-skill files
- **Classification criteria thresholds**: What signals indicate "convert to agent" vs "hybrid" vs "needs feature additions" -- Claude should propose criteria based on the capability reference

### Deferred Ideas (OUT OF SCOPE)

- Implementing any frontmatter fixes or reclassifications (Phase 3 scope)
- Creating new agents from skills identified for conversion (Phase 3 scope)
- Hardening phase numbering or STATE.md coordination (Phase 4 scope)
- Testing capabilities empirically by creating scratch skills (Phase 3 scope)

---

## Summary

This phase is an audit/review phase, not a traditional software development phase. Research focuses on: (1) establishing clear classification criteria for skill vs agent decisions, (2) building a comprehensive frontmatter checklist from official docs, (3) cataloguing per-skill gaps against Phase 1 research findings, and (4) defining an audit output format that Phase 3 can directly consume.

The audit has 17 skills across 3 plugins plus 1 custom agent to review. Phase 1's RESEARCH.md provides the capability reference baseline (10 canonical skill frontmatter fields, 11 agent fields, 22 tools, hooks system, etc.). If Phase 1's CAPABILITY-REFERENCE.md is not yet created when the audit runs, the RESEARCH.md findings serve as the provisional reference.

Overall confidence: **HIGH** -- primary sources are official Claude Code documentation (verified February 2026) and direct codebase inspection.

---

## Standard Stack

This phase produces audit documentation only -- no libraries or tools beyond what is already in the codebase.

### Core Primitives (Audit Inputs)

| Primitive | Version/Source | Purpose | Confidence |
|-----------|---------------|---------|------------|
| Skill frontmatter (10 official fields) | code.claude.com/docs/en/skills | Audit checklist for every skill | HIGH |
| Agent frontmatter (11 official fields) | code.claude.com/docs/en/sub-agents | Classification reference for agent conversion candidates | HIGH |
| Phase 1 RESEARCH.md | .planning/phases/01-**/01-RESEARCH.md | Capability gaps, adoption heatmap, tool inventory | HIGH |
| Phase 1 CAPABILITY-REFERENCE.md (if exists) | CAPABILITY-REFERENCE.md at project root | Complete audit standard with adoption status flags | HIGH (if exists) |
| ORCHESTRATION-REFERENCE.md | Project root | Existing capability reference | HIGH |

### Supporting Files

| File | Purpose | Confidence |
|------|---------|------------|
| All 17 SKILL.md files | Direct audit targets | HIGH |
| phase-researcher.md agent | Agent audit target | HIGH |
| 3 plugin.json files | Plugin manifest audit | HIGH |
| marketplace.json | Marketplace manifest audit | HIGH |

---

## Architecture Patterns

### Recommended Audit Output Format

**Use a single consolidated document** per skill review session. The planner should create a single PLAN.md that drives the interactive review, not 17 separate PLANs.

**Per-skill audit entry structure** (recommended):

```markdown
### Skill: {name} ({plugin})

**Current Frontmatter:**
| Field | Value |
|-------|-------|
| name | ... |
| description | ... |
| allowed-tools | ... |
| model | ... |
| context | ... |
| ... | ... |

**Behavior Summary:** {1-2 sentence description of what the skill does and how}

**Frontmatter Audit:**
| Check | Status | Finding |
|-------|--------|---------|
| allowed-tools completeness | GAP / OK | {details} |
| model selection | GAP / OK | {details} |
| context mode | GAP / OK | {details} |
| argument-hint | GAP / OK | {details} |
| disable-model-invocation | GAP / OK | {details} |
| description quality | GAP / OK | {details} |

**Capability Gap Analysis:**
- {gap 1: e.g., "Missing dynamic context injection for X"}
- {gap 2: e.g., "Could benefit from hooks for Y"}

**Classification Recommendation:** {Remain as skill / Convert to agent / Hybrid / Needs feature additions}
**Rationale:** {Why this classification}

**User Decision:** {Filled during interactive review}
```

### Audit Flow Per Skill

1. **Present** current frontmatter + behavior summary
2. **Run** frontmatter completeness check (6 dimensions)
3. **Run** capability gap analysis (against Phase 1 reference)
4. **Recommend** classification with rationale
5. **Ask user** for final decision
6. **Record** decision in audit document

### Design Patterns

- **Capability-first audit**: Check each skill against the full capability inventory, not just what the skill currently uses. The question is "what SHOULD this skill use?" not "what DOES it use?"

- **Classification decision tree**: Use the criteria defined in the Classification Criteria section below to systematically recommend each skill's classification.

- **Cross-skill consistency checks**: After individual reviews, compare all skills for consistency in model selection, tool restriction patterns, and context mode usage.

### Anti-Patterns

- **Rubber-stamping**: Approving skills as "remain" without checking against the capability reference. Every skill must be checked against all 6 audit dimensions.

- **Over-conversion**: Converting skills to agents just because they CAN be agents. The bar for conversion should be high -- agents add complexity and lose main-context benefits.

- **Frontmatter-only audit**: Only checking YAML fields without reading the skill body. Several skills have behavioral issues (ad-hoc bash patterns, missing error handling) that frontmatter alone cannot reveal.

---

## Classification Criteria

These criteria determine whether a skill should remain as-is, convert to a custom agent, become a hybrid, or need feature additions. Based on official Claude Code documentation (code.claude.com/docs/en/skills, code.claude.com/docs/en/sub-agents).

### Remain as Skill

A skill should REMAIN as a skill when:

1. **Runs in main conversation context** -- needs access to conversation history, prior user messages, or interactive dialog (AskUserQuestion)
2. **Orchestrates other agents/tools** -- the skill is a coordinator that spawns subagents via Task, not a self-contained worker
3. **Has user-interactive flow** -- relies on multiple rounds of AskUserQuestion for decision-making
4. **Simple, focused behavior** -- one clear workflow that benefits from main context awareness
5. **Currently works well** -- no pain points, context issues, or behavioral problems

### Convert to Agent

A skill should become a **custom agent** when:

1. **Self-contained work with summary return** -- does a large chunk of work and returns a summary (official docs: "produces verbose output you don't need in your main context")
2. **Needs tool restrictions different from parent** -- requires specific tool allow/deny lists that differ from the main conversation
3. **Benefits from context isolation** -- burns through context with file reading, web scraping, or extensive analysis that would pollute the main conversation
4. **Reusable across multiple invocation patterns** -- could be spawned by multiple skills or used via Task from different contexts
5. **No user interaction needed** -- works autonomously without AskUserQuestion calls

### Hybrid (Skill + Agent)

A skill should become **hybrid** (skill orchestrator + agent worker) when:

1. **Has both interactive AND autonomous phases** -- e.g., gather user input (skill), then do heavy work (agent)
2. **Current skill already uses this pattern** -- spawns Task agents for heavy lifting while maintaining user interaction in the skill
3. **Would benefit from separating orchestration from execution** -- the skill does too much in one context

### Needs Feature Additions

A skill **needs feature additions** (but not reclassification) when:

1. **Missing frontmatter fields** that would improve behavior (allowed-tools, model, argument-hint, etc.)
2. **Could leverage unused capabilities** -- dynamic context injection, hooks, output styles, LSP
3. **Has incorrect configuration** -- wrong model selection, missing context: fork where it would help, overly broad tool access
4. **Description needs improvement** -- Claude cannot properly auto-invoke the skill because the description is unclear

---

## Frontmatter Completeness Checklist

Each skill should be audited against these 6 dimensions, derived from the official skill frontmatter reference (code.claude.com/docs/en/skills#frontmatter-reference):

### Dimension 1: Tool Restrictions (`allowed-tools`)

| Check | Question | Source |
|-------|----------|--------|
| Present? | Does the skill declare `allowed-tools`? | Official docs: "Skills that define allowed-tools grant Claude access to those tools without per-use approval when the skill is active" |
| Minimal? | Does it grant only tools the skill actually needs? | Principle of least privilege |
| Bash-specific? | If Bash is allowed, are patterns specific (e.g., `Bash(gh issue *)`) rather than blanket `Bash`? | Official docs: "use specific patterns like `Bash(gh issue create *)` instead of unrestricted `Bash`" |

**Current codebase status:** 15 of 17 skills have `allowed-tools`. 2 missing: marketplace-manager (uses haiku model but no tool restriction) and one other to verify. Most skills that include Bash use blanket `Bash` rather than specific patterns.

### Dimension 2: Model Selection (`model`)

| Check | Question | Source |
|-------|----------|--------|
| Appropriate? | Is the model selection right for the skill's complexity? | Official docs: "Control costs by routing tasks to faster, cheaper models like Haiku" |
| Consistent? | Do similar skills use the same model? | Cross-skill consistency |

**Current codebase model assignments:**

| Model | Skills | Pattern |
|-------|--------|---------|
| opus | map-codebase | Heavy analysis orchestrator |
| haiku | progress, cst-help, marketplace-manager | Read-only analysis, help systems |
| sonnet | skill-creator, github-issue-manager | Content creation, focused tasks |
| (default/inherit) | new-project, create-roadmap, discuss-phase, research-phase, plan-phase, execute-phase, quick-plan, phase-feedback, brainstorm, add-security-findings, linear-sync | Orchestrators, interactive skills |

**Findings:**
- Orchestrator skills (plan-phase, execute-phase, research-phase) do not set a model because they delegate to subagents with explicit model choices. This is correct -- the orchestrator itself just reads files and constructs prompts.
- Interactive skills (new-project, create-roadmap, discuss-phase) inherit the main conversation model. This is appropriate since they need to maintain conversation quality for user interaction.
- map-codebase uses opus but its actual mapper agents use sonnet. The skill itself uses opus because it needs high-quality orchestration for parallel agent management. This seems correct.

### Dimension 3: Context Mode (`context`)

| Check | Question | Source |
|-------|----------|--------|
| fork needed? | Would this skill benefit from running in an isolated subagent? | Official docs: "`context: fork` only makes sense for skills with explicit instructions" and "Add `context: fork` when you want a skill to run in isolation" |
| fork harmful? | Would forking lose access to needed conversation history? | Official docs: "It won't have access to your conversation history" |

**Current codebase:** Only 2 of 17 skills use `context: fork`: map-codebase and progress.

**Official guidance on when to use `context: fork`:**
- The skill produces verbose output you do not need in main context
- The skill is self-contained with explicit instructions
- The skill does NOT need conversation history
- The skill does NOT need interactive dialog (AskUserQuestion is not available in forked context unless explicitly allowed in tools)

**Key finding:** `context: fork` is NOT appropriate for most CST skills because they rely on AskUserQuestion for interactive decision-making. Skills that already use Task to spawn subagents (plan-phase, execute-phase, research-phase, discuss-phase) should NOT use `context: fork` themselves -- they are orchestrators that need main context.

### Dimension 4: Invocation Control (`disable-model-invocation`, `user-invocable`)

| Check | Question | Source |
|-------|----------|--------|
| Auto-invoke appropriate? | Should Claude be able to auto-load this skill? | Official docs: "disable-model-invocation: true removes the skill from Claude's context entirely" |
| Menu visibility? | Should this appear in the `/` menu? | Official docs: "`user-invocable` field only controls menu visibility" |

**Current codebase:** Only 2 skills use `disable-model-invocation: true`: map-codebase and add-security-findings. This is correct for orchestrator-heavy skills that should only be explicitly invoked.

**Potential additions:** Several other skills arguably should not be auto-invoked:
- execute-phase: Heavy orchestrator, accidental auto-invocation could be destructive
- plan-phase: Creates artifacts, should be deliberate
- create-roadmap: Modifies ROADMAP.md, should be deliberate
- quick-plan: Modifies ROADMAP.md, should be deliberate
- phase-feedback: Modifies ROADMAP.md, should be deliberate

### Dimension 5: Description Quality (`description`)

| Check | Question | Source |
|-------|----------|--------|
| Clear? | Does the description explain WHAT the skill does AND WHEN to use it? | Official docs: "Claude uses the description to decide when to load the skill" |
| Concise? | Within the character budget (default ~16,000 chars)? | Official docs: `SLASH_COMMAND_TOOL_CHAR_BUDGET` |
| Differentiating? | Does it distinguish this skill from similar ones? | Cross-skill clarity |

**Current codebase status:** All 17 skills have descriptions. Most are comprehensive. Some are very long (execute-phase, plan-phase descriptions include option flags). The descriptions serve double duty: they tell Claude when to auto-invoke AND they tell users what the command does.

### Dimension 6: Argument Handling (`argument-hint`)

| Check | Question | Source |
|-------|----------|--------|
| Present? | Does the skill declare argument-hint for autocomplete? | Official docs show `argument-hint` field |
| Accurate? | Does the hint match actual argument parsing in the skill body? | Consistency check |

**Current codebase:** Most skills that accept arguments have `argument-hint`. Notable gaps:
- marketplace-manager: No `argument-hint` despite accepting operations
- progress: No `argument-hint` (correct -- it takes no arguments)
- add-security-findings: No `argument-hint` (correct -- it takes no arguments)

---

## Per-Skill Pre-Audit Findings

Preliminary gaps identified from codebase inspection and Phase 1 research. These feed directly into the interactive audit.

### claude-super-team Plugin (13 skills)

| Skill | Key Gaps Identified | Preliminary Classification |
|-------|-------------------|--------------------------|
| new-project | No model override (inherits); blanket Bash; no hooks | Remain -- interactive, user-facing |
| create-roadmap | `disable-model-invocation: false` explicitly set (redundant); blanket Bash | Remain -- interactive orchestrator |
| discuss-phase | Uses Task for Explore agent; blanket Bash; complex multi-phase process | Remain -- interactive orchestrator with agent delegation |
| research-phase | Spawns custom phase-researcher agent; clean orchestrator pattern | Remain -- clean hybrid already |
| plan-phase | Spawns planner + checker agents; complex `--all` mode; blanket Bash | Remain -- complex orchestrator |
| execute-phase | Most complex skill; agent teams support; task management tools; blanket Bash | Remain -- heavy orchestrator |
| progress | `context: fork` + haiku -- good lightweight pattern; no AskUserQuestion | Remain -- correctly configured |
| quick-plan | Includes Edit tool (unique); spawns planner; modifies ROADMAP.md | Remain -- interactive, modifies state |
| phase-feedback | Two paths (quick fix / standard); spawns planner on standard path | Remain -- interactive with branching |
| brainstorm | Uses Skill tool (unique); spawns 3 parallel agents; two modes | Remain -- complex interactive orchestrator |
| add-security-findings | `disable-model-invocation: true`; Uses Skill tool to invoke create-roadmap | Remain -- orchestrator with delegation |
| cst-help | haiku model; no `context: fork` despite being read-only; references files in skills/ | Needs additions -- could use `context: fork` like progress |
| map-codebase | `context: fork` + opus + `disable-model-invocation: true`; spawns 4 agents | Remain -- well-configured orchestrator |

### marketplace-utils Plugin (2 skills)

| Skill | Key Gaps Identified | Preliminary Classification |
|-------|-------------------|--------------------------|
| marketplace-manager | haiku model but **no `allowed-tools`**; no `argument-hint`; references docs | Needs additions -- missing tool restrictions |
| skill-creator | sonnet; has `Bash(uv run *)`-specific pattern; references external docs.md | Remain -- well-configured |

### task-management Plugin (2 skills)

| Skill | Key Gaps Identified | Preliminary Classification |
|-------|-------------------|--------------------------|
| linear-sync | Has `Bash(shasum *)` specific pattern; depends on external `linear-cli` skill | Needs additions -- external dependency unclear |
| github-issue-manager | sonnet; has very specific `Bash(gh ...)` patterns -- best practice example | Remain -- well-configured |

### Custom Agent (1)

| Agent | Key Gaps Identified | Preliminary Classification |
|-------|-------------------|--------------------------|
| phase-researcher | opus; preloads firecrawl skill; clean agent definition | Remain -- well-configured |

---

## Don't Hand-Roll

| Problem | Solution | Why Not Custom |
|---------|----------|----------------|
| Skill frontmatter validation | Use the 10 official fields from docs as checklist | Official docs are definitive; don't invent extra fields |
| Classification decisions | Use the decision tree above (Remain/Convert/Hybrid/Needs additions) | Consistent, repeatable criteria better than ad-hoc judgment |
| Adoption status tracking | Use Phase 1's "In use" / "Documented but unused" / "Unverified" system | Already established in Phase 1 research |
| Audit output format | Use the per-skill entry template above | Structured format that Phase 3 can directly consume |

---

## Common Pitfalls

| Pitfall | Impact | How to Avoid |
|---------|--------|--------------|
| Auditing frontmatter without reading skill body | Miss behavioral gaps (ad-hoc bash, missing error handling, context leaks) | Read at least the first 50 lines of each skill body during audit |
| Recommending `context: fork` for interactive skills | Breaks AskUserQuestion flow, loses conversation history | Only recommend fork for non-interactive, self-contained skills |
| Converting orchestrator skills to agents | Agents cannot spawn other agents; orchestrators need main context | Never convert a skill that uses Task tool to spawn subagents |
| Ignoring cross-skill consistency | Different model choices for identical patterns confuse users | Compare model/tool choices across all skills after individual reviews |
| Treating all "missing frontmatter" as equal severity | Some missing fields are critical (allowed-tools), others are cosmetic (argument-hint) | Prioritize gaps by security impact and behavioral correctness |
| Not distinguishing "skill-only" vs "agent-only" frontmatter fields | Recommending agent fields for skills or vice versa | Reference the official 10 skill fields vs 11 agent fields from Phase 1 research |
| Blanket Bash as acceptable | Security risk -- any skill with `Bash` can execute arbitrary commands | Flag every blanket `Bash` in allowed-tools as a gap; recommend specific patterns where possible |

---

## Code Examples

### Official Skill Frontmatter (Complete, 10 Fields)

```yaml
---
name: my-skill                      # Required. Lowercase, hyphens, max 64 chars
description: What this skill does    # Required. When to use (Claude uses for auto-invocation)
argument-hint: "[filename] [format]" # Shown during autocomplete
disable-model-invocation: true       # Prevent Claude auto-loading
user-invocable: false                # Hide from / menu
allowed-tools: Read, Grep, Glob     # Tool access control
model: opus                          # Model override (opus, haiku, sonnet)
context: fork                        # Run in forked subagent context
agent: Explore                       # Agent type when context: fork
hooks:                               # Skill-scoped lifecycle hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/check.sh"
---
```

Source: https://code.claude.com/docs/en/skills#frontmatter-reference

### Official Agent Frontmatter (Complete, 11 Fields)

```yaml
---
name: code-reviewer                  # Unique identifier
description: Reviews code quality    # When Claude should delegate
tools: Read, Grep, Glob, Bash       # Tool allowlist
disallowedTools: Write, Edit         # Tool denylist
model: sonnet                        # sonnet, opus, haiku, or inherit
permissionMode: default              # Permission handling
maxTurns: 50                         # Max agentic turns
skills:                              # Skills preloaded at startup
  - api-conventions
mcpServers:                          # MCP servers for this agent
  - slack
hooks:                               # Agent-scoped hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
memory: user                         # user, project, or local
---
```

Source: https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields

### Best Practice: Specific Bash Tool Patterns

```yaml
# GOOD: Specific command patterns
allowed-tools: Read, Grep, Glob, Bash(gh issue create *), Bash(gh issue edit *)

# BAD: Blanket Bash access
allowed-tools: Read, Grep, Glob, Bash
```

Source: https://code.claude.com/docs/en/skills#restrict-tool-access and skill-creator SKILL.md

### When context: fork Is Appropriate

From official docs (code.claude.com/docs/en/skills#run-skills-in-a-subagent):

> `context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like "use these API conventions" without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output.

> Add `context: fork` to your frontmatter when you want a skill to run in isolation. The skill content becomes the prompt that drives the subagent. It won't have access to your conversation history.

### Skill vs Subagent Decision (Official Guidance)

From official docs (code.claude.com/docs/en/sub-agents#work-with-subagents):

> Use **subagents** when:
> - The task produces verbose output you don't need in your main context
> - You want to enforce specific tool restrictions or permissions
> - The work is self-contained and can return a summary
>
> Consider **Skills** instead when you want reusable prompts or workflows that run in the main conversation context rather than isolated subagent context.

> Subagents cannot spawn other subagents. If your workflow requires nested delegation, use Skills or chain subagents from the main conversation.

---

## State of the Art

| Aspect | Current Codebase | Official Best Practice | Gap |
|--------|-----------------|----------------------|-----|
| Tool restrictions | 15/17 skills have `allowed-tools`; most use blanket `Bash` | Use specific Bash patterns like `Bash(gh issue create *)` | Most skills need Bash pattern specificity |
| Model selection | 7/17 have explicit model; 10 inherit | Set model explicitly for cost/speed optimization | Some skills could benefit from explicit haiku/sonnet |
| Context mode | 2/17 use `context: fork` | Use fork for isolated, non-interactive work | cst-help is a candidate for fork |
| Invocation control | 2/17 use `disable-model-invocation` | Disable for destructive or heavy orchestrators | Several orchestrators should consider this |
| Dynamic context injection | 0/17 use `!`command`` syntax | Available for runtime context embedding | Some skills could benefit (e.g., git status in progress) |
| Hooks | 0/17 use skill-scoped hooks | Available for pre/post validation | Could add pre-execution checks to destructive skills |
| Argument shorthand | 0/17 use `$0`, `$1` syntax | Available as shorthand for `$ARGUMENTS[0]` | Minor improvement, low priority |
| Description quality | All adequate but some very long | Clear, concise, differentiating descriptions | Some descriptions could be trimmed |

---

## Open Questions

- **Phase 1 dependency**: If CAPABILITY-REFERENCE.md does not exist when Phase 2 executes, the audit must use Phase 1's RESEARCH.md findings as the provisional reference. The planner should check for the file and adapt accordingly.

- **cst-help context: fork**: The cst-help skill reads `.planning/` files and provides status -- similar to progress which uses `context: fork`. However, cst-help also uses AskUserQuestion for interactive troubleshooting. Is `context: fork` appropriate here given the AskUserQuestion dependency? Official docs say forked skills lose conversation history but can still use tools if listed in `allowed-tools`. Need to verify if AskUserQuestion works in forked context -- if so, `context: fork` is viable.

- **Blanket Bash remediation**: Many skills use Bash for `mkdir -p`, `grep`, `ls -d`, and `find` commands as setup checks. Restricting to specific patterns would be very verbose (e.g., `Bash(mkdir *), Bash(ls *), Bash(grep *), Bash(test *)`). Is the security benefit worth the verbosity? The audit should document the specific Bash commands each skill uses and recommend per-skill patterns.

- **Agent teams maturity**: execute-phase supports `--team` mode with Agent Teams, but the feature is behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. The audit should note this as experimental and not penalize the skill for including it, but also flag any gaps in the teams implementation.

---

## Sources

| Source | Type | Confidence | URL |
|--------|------|------------|-----|
| Claude Code Skills Documentation | Official docs | HIGH | https://code.claude.com/docs/en/skills |
| Claude Code Subagents Documentation | Official docs | HIGH | https://code.claude.com/docs/en/sub-agents |
| Claude Code Hooks Reference | Official docs | HIGH | https://code.claude.com/docs/en/hooks |
| Claude Code Plugins Reference | Official docs | HIGH | https://code.claude.com/docs/en/plugins-reference |
| Phase 1 RESEARCH.md | Codebase | HIGH | .planning/phases/01-claude-code-capability-mapping/01-RESEARCH.md |
| Phase 2 CONTEXT.md | Codebase | HIGH | .planning/phases/02-skill-audit-&-reclassification**/02-CONTEXT.md |
| All 17 SKILL.md files | Codebase | HIGH | plugins/*/skills/*/SKILL.md |
| phase-researcher.md agent definition | Codebase | HIGH | plugins/claude-super-team/agents/phase-researcher.md |
| CLAUDE.md project instructions | Codebase | HIGH | CLAUDE.md |

---

## Metadata

- **Research date:** 2026-02-11
- **Phase:** 2 - Skill Audit & Reclassification
- **Confidence breakdown:** 22 HIGH, 3 MEDIUM, 0 LOW findings
- **Firecrawl available:** yes
- **Sources consulted:** 9
