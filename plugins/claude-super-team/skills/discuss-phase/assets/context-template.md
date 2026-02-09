# Context for Phase {phase_number}: {phase_name}

## Phase Boundary (from ROADMAP.md)

**Goal:** {phase_goal}

**Success Criteria:**
{list success criteria from roadmap}

**What's in scope for this phase:**
{brief summary of what this phase will deliver}

**What's explicitly out of scope:**
{brief summary of what is deferred or belongs to other phases}

---

## Implementation Decisions

{For each gray area discussed, document the user's decisions}

### {Area Name}

**Decision:** {What was decided}

**Rationale:** {Why this approach was chosen}

**Constraints:** {Any specific requirements or limitations}

---

## Claude's Discretion

{List areas where the user explicitly deferred decisions to Claude}

- {Area}: {Brief description of what Claude should decide}

---

## Specific Ideas

{User-provided references, examples, or specific implementation guidance}

- {Idea/Reference}: {Description or link}

---

## Deferred Ideas

{Ideas that came up during discussion but are explicitly out of scope for this phase}

- {Idea}: {Brief description and why it's deferred}

---

## Examples

### Good Example: Specific, actionable decisions

**Area:** Authentication Token Storage

**Decision:** Use httpOnly cookies for refresh tokens, localStorage for access tokens

**Rationale:** httpOnly cookies protect against XSS attacks on refresh tokens (long-lived, high value). Access tokens are short-lived (15 min) so localStorage acceptable for client-side access.

**Constraints:** Must implement CSRF protection for cookie-based refresh flow. Must clear localStorage on logout.

### Bad Example: Vague vision statement

**Area:** Authentication

**Decision:** Make it secure and user-friendly

(This doesn't constrain planning at all -- too vague)
