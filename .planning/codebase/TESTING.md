# Testing Patterns

**Analysis Date:** 2026-02-11

## Test Framework

**Runner:**
- Not detected - no test framework configuration found
- No `package.json`, `pytest.ini`, `jest.config.*`, `vitest.config.*`, or similar test configuration

**Assertion Library:**
- Not detected

**Run Commands:**
- Not applicable

## Test File Organization

**Location:**
- No test files detected in repository
- No `.test.*` or `.spec.*` files found

**Naming:**
- Not applicable

**Structure:**
- Not applicable

## Test Structure

**Suite Organization:**
- Not applicable - no test suites detected

**Patterns:**
- Not applicable

## Mocking

**Framework:**
- Not detected

**Patterns:**
- Not applicable

**What to Mock:**
- Not applicable

**What NOT to Mock:**
- Not applicable

## Fixtures and Factories

**Test Data:**
- Not applicable

**Location:**
- Not applicable

## Coverage

**Requirements:**
- No coverage requirements detected

**View Coverage:**
- Not applicable

## Test Types

**Unit Tests:**
- Not detected

**Integration Tests:**
- Not detected

**E2E Tests:**
- Not detected

## Common Patterns

**Async Testing:**
- Not applicable

**Error Testing:**
- Not applicable

## Testing Philosophy (Inferred from Skill Design)

While this repository contains no code tests, the skill architecture embodies testing principles:

**Verification-first Design:**
- Skills include `## Success Criteria` checklists
- Each phase/plan includes verification steps
- Observable, user-verifiable outcomes prioritized over task completion
- Verification agents validate phase goal achievement

**Automation-first Approach:**
- Tasks specify `<verify>` blocks with concrete validation commands
- Prefer automated checks (e.g., `npm test`, `curl`, CLI commands) over manual verification
- Checkpoint tasks (`checkpoint:human-verify`) used only for visual/functional verification that cannot be automated

**Execution Verification Pattern (from `/execute-phase`):**
- After plan execution, verification agent validates phase success criteria
- Produces `VERIFICATION.md` with pass/fail status
- Gaps trigger gap closure planning (`/plan-phase --gaps`)
- Iterative feedback loop until verification passes

**Agent Orchestration Testing (from skills):**
- Planner agents create plans with explicit verification steps
- Executor agents run tasks and verify completion
- Checker/verifier agents validate outcomes against success criteria
- Wave-based execution allows parallel testing of independent work

**Quality Gates:**
- No auto-commit (user reviews before committing)
- Security scan for secrets before allowing commit (in `/map-codebase`)
- Research validation against locked decisions (in `/research-phase`)
- Plan verification loop before execution (in `/plan-phase`)

---

*Testing analysis: 2026-02-11*
