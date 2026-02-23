# Gray Area Identification Methodology

**Domain-aware, codebase-aware, and cross-phase-aware analysis.** Don't use generic categories. Analyze this specific phase -- informed by codebase context (Phase 3.7) and prior phase plans (Phase 3.5) -- to find 3-4 actual ambiguities.

**Process:**

1. Read the phase goal, success criteria, codebase context (Phase 3.7), AND prior phase summary (Phase 3.5)
2. Identify the domain (auth, payments, API design, data modeling, etc.)
3. Derive 3-4 specific gray areas where reasonable people would disagree, grounded in what the codebase already has AND what earlier phases will create

**Cross-phase-aware gray areas** leverage prior phase plans:
- "Phase 3 plans a `PermissionService` with role-based access -- should this phase extend it with resource-level permissions or keep it role-only?" (cross-phase-aware)
- "How should we handle permissions?" (generic, ignores prior phases, bad)

**Codebase-grounded gray areas** reference actual code:
- "The codebase uses Prisma with a `User` model but no role field -- how should we model permissions?" (grounded)
- "How should we handle permissions?" (generic, bad)

**Good gray areas** (domain-specific, phase-specific):
- "Should password reset tokens expire after first use or after time limit?"
- "Where should we validate payment amounts: client, API, or both?"
- "Should deleted items be soft-deleted (flagged) or hard-deleted (removed)?"

**Bad gray areas** (generic, could apply to any phase):
- "What technologies should we use?"
- "How should we structure the code?"
- "What about performance?"

**Anti-pattern: Pre-made category lists.** Every phase gets unique gray areas derived from its goal, not recycled from a template.

**Domain examples:**

| Domain | Example Gray Areas |
|--------|-------------------|
| Authentication | Token storage location, session duration, MFA approach, password requirements |
| Payments | Idempotency strategy, refund flow, currency handling, failed payment retries |
| Multi-tenancy | Tenant isolation level, shared vs separate DBs, cross-tenant references |
| Search | Indexing approach, fuzzy match threshold, result ranking algorithm |
| File uploads | Storage location, size limits, virus scanning, CDN strategy |
