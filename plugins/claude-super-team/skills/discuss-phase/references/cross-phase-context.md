# Cross-Phase Context Loading

Before exploring the codebase, understand what earlier phases will create. This phase may depend on infrastructure, APIs, models, or patterns that don't exist yet but are planned.

**Why:** Phase 5 might use an auth system being built in phase 3. Without cross-phase context, the discussion asks questions that were already answered or plans features that ignore what's coming.

**Process:**

1. Use the pre-loaded **PHASE_ARTIFACTS** data from the gather script. Each line shows:

```
{dir_name}|status={executed|planned|discussed|not_started}|summaries={N}|plans={N}|context={N}|research={N}
```

Filter to phases with a lower number than the current one.

2. For each earlier phase, load the most informative artifact available (in priority order):
   - **SUMMARY.md** (phase already executed -- shows what was actually built)
   - **PLAN.md files** (phase planned but not executed -- shows what will be built, including specific APIs, models, endpoints, patterns)
   - **CONTEXT.md** (phase discussed but not planned -- shows locked decisions)
   - **ROADMAP.md entry** (fallback -- just the goal and success criteria)

3. Build a concise "Prior Phase Summary" focusing on what each earlier phase provides that this phase might consume:
   - APIs, endpoints, or services being created
   - Data models, schemas, or database tables
   - Shared utilities, middleware, or patterns
   - Auth flows, permissions, or access control mechanisms
   - Configuration, environment variables, or infrastructure

```
PRIOR PHASES FOR PHASE {N}:

Phase 1 ({name}) [executed]:
- Built: {key deliverables}
- Provides: {what this phase can use}

Phase 2 ({name}) [planned]:
- Will build: {key deliverables from PLAN.md}
- Will provide: {what this phase can piggyback on}

Phase 3 ({name}) [discussed]:
- Decided: {key decisions from CONTEXT.md}
- Will provide: {expected deliverables based on decisions}
```

4. Identify **cross-phase dependencies** -- specific things this phase needs that an earlier phase creates. These feed directly into gray area generation (Phase 4) and deep-dive questions (Phase 6).

**Skip this step** if the current phase is Phase 1 (no prior phases).
