# Phase 2: Skill Audit & Reclassification

**Date:** 2026-02-12
**Auditor:** Claude (with user classification decisions)
**Reference:** CAPABILITY-REFERENCE.md (2026-02-11)
**Total items:** 17 skills + 1 agent across 3 plugins

## Classification Criteria

| Classification | When to Use |
|---------------|-------------|
| Remain as Skill | Runs in main context, orchestrates agents, interactive flow, works well |
| Convert to Agent | Self-contained, needs tool restrictions, benefits from context isolation, no user interaction |
| Hybrid (Skill + Agent) | Has both interactive AND autonomous phases |
| Needs Feature Additions | Missing frontmatter, could leverage unused capabilities, incorrect config |

## Frontmatter Checklist (6 Dimensions)

1. **Tool Restrictions** (allowed-tools): Present? Minimal? Bash-specific patterns?
2. **Model Selection** (model): Appropriate? Consistent with similar skills?
3. **Context Mode** (context): Fork needed? Fork harmful?
4. **Invocation Control** (disable-model-invocation, user-invocable): Auto-invoke appropriate?
5. **Description Quality** (description): Clear? Concise? Differentiating?
6. **Argument Handling** (argument-hint): Present? Accurate?

---

## Audit Results
