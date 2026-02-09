# Issue Decomposition Guide

This guide provides the reasoning framework for decomposing PLAN.md files into Linear issues with intelligent parent/sub-issue structure.

## Philosophy

Create issues like a team leader would: group related work meaningfully, split complex work into manageable pieces, and avoid mechanical 1:1 task mapping.

**Goal:** Each Linear issue should represent a cohesive unit of work that can be assigned, tracked, and completed independently.

## Decision Matrix

| Plan Shape | Strategy | Example |
|-----------|----------|---------|
| 1 task, simple (<5 files) | Single issue, no sub-issues | "Add logout button" → one issue |
| 1 task, complex (5+ files) | Parent + 2-3 sub-issues by concern | "Implement auth system" → parent + sub-issues for (API, UI, tests) |
| 2-3 substantial tasks | Parent + one sub-issue per task | "Build user profile" → parent + sub-issues for each feature area |
| 2-3 mixed tasks (some small) | Parent + group smalls, split larges | Group setup tasks, split implementation tasks |
| 4+ tasks, all small | Parent + group by concern area | Group by file type, feature area, or phase of work |
| 4+ tasks, varied complexity | Parent + meaningful sub-issues, group where sensible | Split complex, group simple, aim for 3-6 sub-issues max |

## Grouping Strategies

### By Concern Area
Group tasks that touch the same part of the system:
- Frontend tasks → "Update UI components"
- Backend tasks → "Add API endpoints"
- Database tasks → "Update schema"
- Test tasks → "Add test coverage"

### By Phase of Work
Group tasks that represent a sequence:
- Setup/scaffolding tasks → "Initialize infrastructure"
- Implementation tasks → "Implement core logic"
- Integration tasks → "Wire up components"
- Verification tasks → "Add tests and validation"

### By File/Component
Group tasks that modify the same files or components:
- Tasks modifying `user.ts` → "Update user service"
- Tasks modifying `auth/` → "Refactor auth module"

## Splitting Strategies

### By Technical Layer
Split complex tasks by architectural layers:
- Data layer (models, migrations)
- API layer (routes, controllers)
- UI layer (components, views)
- Test layer (unit, integration, e2e)

### By Scope
Split large tasks by functional scope:
- Core functionality
- Edge cases and validation
- Error handling
- Documentation and tests

### By Dependencies
Split to reflect dependency chains:
- Foundation (must complete first)
- Build-on tasks (depend on foundation)
- Integration tasks (combine multiple pieces)

## Title Conventions

### Parent Issue Titles
Use descriptive objectives from the plan (not mechanical labels):

**Good:**
- "Implement JWT authentication system"
- "Build user profile management"
- "Refactor data access layer"

**Bad:**
- "Plan 01-02"
- "Execute phase 1 tasks"
- "PLAN.md implementation"

### Sub-Issue Titles
Use actionable verb + specific component:

**Good:**
- "Add JWT auth middleware"
- "Create login API endpoint"
- "Build profile settings UI"
- "Write authentication integration tests"

**Bad:**
- "Task 1"
- "Frontend work"
- "Tests"
- "Refactor things"

## Description Templates

### Parent Issue Description

```markdown
**Objective:** [What this accomplishes from PLAN.md]

**Purpose:** [Why from PLAN.md objective/context]

**Must-haves:**
- [Truth 1 from plan frontmatter]
- [Truth 2]
- [Artifact 1]

**Success Criteria:**
[From PLAN.md success_criteria section]

**Verification:**
[From PLAN.md verification section]

**Related Files:**
[Aggregate files_modified from all tasks]
```

### Sub-Issue Description

```markdown
**Files:**
- `path/to/file1.ts`
- `path/to/file2.ts`

**Action:**
[Task action from PLAN.md, condensed]

**Verification:**
[Task verify command/criteria]

**Done When:**
[Task done criteria]
```

## Sizing Guidelines

### Target Sub-Issue Size
Aim for sub-issues that take **1-4 hours** to complete:
- Too small: "Change variable name" (just a checklist item)
- Too large: "Build entire auth system" (needs splitting)
- Just right: "Implement JWT token generation endpoint"

### Maximum Sub-Issues
Prefer **3-6 sub-issues** per parent:
- Less than 3: consider if parent is needed
- More than 6: look for grouping opportunities

## Special Cases

### Single Simple Task (No Sub-Issues)
When PLAN.md has one task touching 1-3 files with clear scope:
- Create single issue with combined parent + task content
- No sub-issues needed
- Title from task action
- Description includes all plan context

### Checkpoint Tasks
Tasks with `type="checkpoint:human-verify"` or `type="checkpoint:decision"`:
- Always create as separate sub-issue
- Mark in description: "⚠️ Checkpoint: Requires human review"
- Helps team know when to pause and review

### Wave Dependencies
When plan has explicit wave structure and dependencies:
- Don't create cross-wave sub-issues
- Keep sub-issues within same wave (same milestone)
- Use parent issue to represent overall wave goal
- Each wave maps to a milestone within the project
- Note wave in labels: `wave-1`, `wave-2`, etc.

## Examples

### Example 1: Simple Plan (Single Issue)

**PLAN.md:**
```yaml
tasks:
  - name: Add logout button
    files: src/components/Header.tsx
    action: Add logout button to header, call auth.logout()
    verify: Click button, verify redirect to login
    done: Logout button visible and functional
```

**Linear Structure:**
- One issue: "Add logout button to header"
- No sub-issues
- Description includes action, verify, done

### Example 2: Complex Plan (Parent + Sub-Issues)

**PLAN.md:**
```yaml
tasks:
  - name: Implement JWT generation
    files: src/auth/jwt.ts, src/auth/types.ts
    action: Create JWT generation with 1h expiry

  - name: Add login endpoint
    files: src/api/auth.ts, src/api/routes.ts
    action: POST /auth/login endpoint with JWT response

  - name: Add auth middleware
    files: src/middleware/auth.ts
    action: Verify JWT on protected routes

  - name: Write integration tests
    files: tests/auth.test.ts
    action: Test login flow, token validation, expiry
```

**Linear Structure:**
- Parent: "Implement JWT authentication system"
- Sub-issue 1: "Create JWT token generation"
- Sub-issue 2: "Add login API endpoint"
- Sub-issue 3: "Add JWT auth middleware"
- Sub-issue 4: "Write authentication integration tests"

### Example 3: Mixed Plan (Grouped Sub-Issues)

**PLAN.md:**
```yaml
tasks:
  - name: Update schema
    files: migrations/001.sql
    action: Add user_preferences table

  - name: Add ORM models
    files: src/models/user_preferences.ts
    action: Create Prisma model

  - name: Create API endpoints
    files: src/api/preferences.ts
    action: GET/PUT /preferences endpoints

  - name: Build settings UI
    files: src/pages/Settings.tsx, src/components/PreferenceForm.tsx
    action: Create settings page with form

  - name: Add form validation
    files: src/components/PreferenceForm.tsx
    action: Validate inputs, show errors

  - name: Write tests
    files: tests/preferences.test.ts
    action: Test API and UI
```

**Linear Structure:**
- Parent: "Build user preferences system"
- Sub-issue 1: "Set up preferences data layer" (groups schema + ORM)
- Sub-issue 2: "Create preferences API endpoints"
- Sub-issue 3: "Build settings UI with validation" (groups UI + validation)
- Sub-issue 4: "Add preferences test coverage"

## Anti-Patterns to Avoid

### Don't: Create Too Many Trivial Sub-Issues
```
Parent: Update user service
├─ Sub 1: Import new types
├─ Sub 2: Add one function
├─ Sub 3: Export function
└─ Sub 4: Update index.ts
```
Too granular. Combine into one or two meaningful sub-issues.

### Don't: Create Vague Parent Issues
```
Parent: Implement stuff
├─ Sub 1: Do frontend things
├─ Sub 2: Do backend things
└─ Sub 3: Write tests
```
Too vague. Use specific objectives and actionable titles.

### Don't: Mirror PLAN.md Structure Mechanically
```
PLAN.md has 8 tasks → create 8 sub-issues
```
Group related tasks. Split complex tasks. Aim for cohesion over 1:1 mapping.

### Don't: Ignore Task Dependencies
```
Sub 1: Build feature (depends on Sub 2)
Sub 2: Set up infrastructure (must complete first)
```
Order sub-issues logically. Foundation tasks first, build-on tasks after.

## Verification Checklist

Before finalizing issue structure, verify:

- [ ] Each sub-issue is independently completable
- [ ] Sub-issue titles are actionable and specific
- [ ] Parent title describes overall objective clearly
- [ ] Related work is grouped, complex work is split
- [ ] 3-6 sub-issues per parent (or justify deviation)
- [ ] Descriptions include context from plan
- [ ] Dependencies and wave structure respected
- [ ] Checkpoint tasks marked for human review
- [ ] No mechanical 1:1 task mapping
