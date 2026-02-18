# Autonomous Decision Guide

How /build answers AskUserQuestion calls from child skills without user input.

## 1. Core Decision Framework

When a child skill presents an AskUserQuestion, follow these steps exactly:

1. **READ** the question: header, question text, all option labels and descriptions.
2. **CHECK** `build-preferences.md` for a directly relevant preference (tech stack, exec model, architecture, coding style, testing strategy).
3. **If preference found:** SELECT that option. Log the decision with **high** confidence.
4. **If no preference found:** REASON about the best option using:
   - Project context: what is being built, current phase goal, success criteria
   - Prior decisions: BUILD-STATE.md Decisions Log -- maintain consistency with earlier choices
   - Software engineering best practices for the project's domain
   - The principle of forward motion: always move the pipeline forward
5. **SELECT** using these priorities (in order):
   a. Preference match from `build-preferences.md`
   b. Option that moves the pipeline forward -- never select "Abort", "Cancel", "Stop", or "Exit"
   c. Recommended or default option (often the first option, or one labeled "Recommended")
   d. Option that accepts reasonable defaults over custom configuration
   e. Option that favors completeness and quality over speed
6. **LOG** the decision to BUILD-STATE.md Decisions Log with: phase, skill, question summary, chosen answer, confidence level.
7. **NEVER** present the question to the user. Always select and continue autonomously.

## 2. Confidence Levels

- **high** -- Preference match from `build-preferences.md`, or a clearly best option supported by strong reasoning and project context. No ambiguity.
- **medium** -- Reasonable choice with sound justification, but one or more alternatives were also viable. The decision is defensible but not obvious.
- **low** -- Genuinely ambiguous situation where multiple options had comparable merit. Picked the best guess based on available context. Flag for user review in BUILD-REPORT.md.

## 3. Special Cases by Skill

### /new-project

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Existing project detected" | If BUILD-STATE.md shows greenfield intent, log a warning and continue. If brownfield, acknowledge. | Brownfield vs greenfield is detected at input, not here. |
| "Brownfield detection: Map codebase first?" | **"Skip mapping"** | /new-project exits without creating PROJECT.md if you pick "Map first". /build handles /map-codebase independently in Step 6 of the pipeline. Always skip here. |
| "Keep exploring / More questions" vs "Create PROJECT.md" / "All set" | **"Create PROJECT.md" / "All set"** | Move forward after reasonable exploration. Do not loop endlessly on clarification rounds. |
| "Exec model preference" | Use `build-preferences.md` exec model value. If unset, default to **opus**. | Preference > default. |

### /map-codebase

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Mode" (Full map / Refresh / Partial) | **"Full map"** on first run. **"Refresh"** if `.planning/codebase/` already has docs. | First run needs comprehensive mapping; subsequent runs only need delta. |

### /brainstorm

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Mode" (Interactive / Autonomous) | **"Autonomous"** | Locked decision: brainstorm always runs in autonomous mode during /build. |
| "Review ideas" / "Approve all" | **"Approve all"** | Move forward. Ideas are captured in IDEAS.md for later reference. |
| "Update roadmap?" | **"Add to roadmap"** | Ideas should flow into the roadmap so /create-roadmap can incorporate them. |

### /create-roadmap

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Phase count / structure" | **Accept the LLM recommendation** | The roadmap skill reasons about phase decomposition well. Accept its proposed structure. |
| "Confirm roadmap" / "Approve roadmap" | **Accept / Approve** | Move forward with the generated roadmap. |

### /discuss-phase

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| Gray area questions (tech choices, patterns, tradeoffs) | Answer based on: project context, `build-preferences.md` tech stack, and common patterns for the domain. Log as **medium** confidence for domain-specific decisions. | Gray areas require reasoning. Use all available context. |
| "Continue discussing / All set" | **"All set"** after answering all presented gray areas. | Do not request additional question rounds. One pass through gray areas is sufficient. |

### /research-phase

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Continue research / Done" | **"Done"** | Research ran autonomously. Accept results. |
| "RESEARCH.md already exists" | **"Replace entirely"** | Fresh run. BUILD-STATE tracks no prior research for this phase; start clean. |
| "Research was blocked" / "Research failed" | **"Plan without research"** | Skip and continue. Consistent with locked decision: never block the pipeline on research failure. |
| "Research conflicts with discuss-phase decisions" | **"Keep decisions"** | CONTEXT.md locked decisions always take precedence over research suggestions. |

### /plan-phase

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Plan revision needed" / "Accept plans" vs "Revise" | **"Accept plans"** unless the checker found critical issues (security vulnerabilities, missing core requirements, architectural violations). If critical: **"Revise"** (one revision max). | Quality gate: only revise for critical issues. Accept otherwise. |
| "Verify plans" / "Skip verification" | **"Verify plans"** (always) | Plan verification catches issues early. Always verify. |

### /execute-phase

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Branch warning: on main" | **"Continue anyway"** | /build manages its own branch flow. It will be on a `build/` branch or intentionally on main for planning stages. |
| "Exec model" | Use `build-preferences.md` preference. If unset, use STATE.md preference. If both unset, default to **opus**. | Preference chain: explicit preference > state > default. |
| "Task blocked" / "Task needs human input" | **"Skip task"** | Cannot provide human guidance autonomously. Skip and log. |
| "Checkpoint: human-verify" | **AUTO-APPROVE.** Log as **low** confidence. | Human checkpoints cannot be verified autonomously. Approve and flag for review. |
| "Checkpoint: decision" | Use LLM reasoning based on project context. Log the decision with appropriate confidence. | Treat as a gray area decision -- reason from context. |
| "Verification gaps found" / "Run gap closure" | **"Accept as-is"** | Do NOT trigger execute-phase's internal gap closure. Rely on the external build/test validation in the pipeline, and /phase-feedback for the single permitted feedback attempt. |

### /phase-feedback

| Question Pattern | Autonomous Answer | Rationale |
|---|---|---|
| "Which phase?" | **Current phase** from BUILD-STATE.md `Current phase` field. | Always targets the phase that just executed. |
| "Feedback scope" | **"Standard feedback"** (plan + execute path for verification failures). | Standard feedback includes both planning and execution for the fix. |
| "Research needed?" | Follow the **adaptive pipeline depth heuristic** from `pipeline-guide.md`. | Feedback subphases use the same heuristic as regular phases. |

## 4. Fallback Rules

When no special case from Section 3 matches the question:

1. If options include **"Continue"** or **"Proceed"**: select it.
2. If options include **"Accept"** or **"Approve"**: select it.
3. If an option has a **"Recommended"** label or suffix: select it.
4. If options are feature choices (which library, which pattern, which approach):
   - Check `build-preferences.md` for relevant preferences.
   - Check BUILD-STATE.md Decisions Log for consistency with prior choices.
   - Reason from project context, tech stack, and domain best practices.
   - Log as **medium** confidence.
5. If truly stuck with no distinguishing signal: pick the **first option**. Log as **low** confidence.
6. **NEVER** select "Abort", "Cancel", "Stop", or "Exit" -- unless the question is specifically about whether to abort a failing sub-task, in which case prefer **"Skip"** over "Abort".

## 5. Post-Compaction Reminder

After context compaction, this guide may no longer be in the active context window. The SKILL.md includes a compaction re-injection instruction that re-reads this file when compaction is detected (via the compaction count in BUILD-STATE.md).

The core principle that must survive compaction:

**NEVER present AskUserQuestion to the user. Always answer autonomously using this decision framework. Check BUILD-STATE.md and build-preferences.md for context. Move the pipeline forward. Log every decision.**
