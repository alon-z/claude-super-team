# Phase Derivation Methodology

**Philosophy: requirements drive structure, not templates.**

Analyze the requirements and derive natural delivery boundaries:

1. **Group by capability** -- Which requirements cluster into coherent deliverables?
2. **Identify dependencies** -- Which capabilities depend on others?
3. **Slice vertically** -- Each phase delivers one complete, demoable vertical slice.
4. **Group into sprints** -- Independent phases run in parallel sprints, like a real dev team.

## Value-First Vertical Slices

The single most important ordering principle: **every sprint should deliver something the user can try.**

Real development teams don't build all the infrastructure first and then all the features. They build thin end-to-end slices -- frontend + backend + data for the same user journey -- so each sprint produces a working, demoable increment. This matters because:

- Users can review and give feedback on real features, not abstractions
- Integration issues surface early instead of piling up at the end
- The project is always in a "show something" state

**How to slice vertically:**

Instead of horizontal layers:
```
Sprint 1: All database models
Sprint 2: All API endpoints
Sprint 3: All UI screens
```

Slice by user journey:
```
Sprint 1: [S] Design system + [M] Home screen + [M] Places API + search endpoint
Sprint 2: [L] Place detail (frontend + backend) + [M] User auth (frontend + backend)
Sprint 3: [XL] Live tour (frontend + backend + AI engine)
```

Each sprint delivers a testable feature. The user can open the app and try searching for places after Sprint 1, view place details after Sprint 2, take a tour after Sprint 3.

**When infrastructure is unavoidable:** Some foundation work (project scaffolding, CI/CD, design tokens) has no user-visible output. Keep these phases small (S-sized) and bundle them into Sprint 1 alongside a real feature slice. Never let a full sprint be pure infrastructure.

## Sprint Grouping

Phases that have no dependencies between them belong in the same sprint. Think of sprints like a development team working in parallel on different features during the same time period.

**Sprint assignment rules:**

1. Phases with **no shared dependencies** -> same sprint
2. Phases where one **consumes the output** of another -> sequential sprints
3. When in doubt, **same sprint** -- the cost of unnecessary sequencing (delayed feedback, blocked features) exceeds the cost of minor integration work later

**Annotate phases with their sprint:**
```
- [ ] **Phase 1: Foundation & Design System** [Sprint 1] [S] - Scaffolding, theme, tokens
- [ ] **Phase 2: Home Screen & Places API** [Sprint 1] [M] - Home UI + backend search endpoint
- [ ] **Phase 3: Auth Flow** [Sprint 1] [M] - Sign-in UI + backend auth
- [ ] **Phase 4: Place Detail** [Sprint 2] [L] - Detail screen + backend place data
```

Phases 1, 2, and 3 run in parallel during Sprint 1. Phase 4 waits for Sprint 2 because it depends on the places API from Phase 2.

## T-Shirt Sizing

Estimate each phase with a T-shirt size to give users a sense of relative effort:

| Size | Scope | Typical Plans | Signal |
|------|-------|---------------|--------|
| **S** | Config, scaffolding, single-screen UI, simple CRUD | 1 plan | Done in one focused session |
| **M** | Feature with frontend + backend, moderate complexity | 2-3 plans | A solid day of work |
| **L** | Complex feature spanning multiple subsystems | 3-5 plans | Multi-day effort |
| **XL** | Major capability (real-time systems, AI pipelines, payment flows) | 5+ plans | Week-level effort, consider splitting |

**Sizing signals:**
- Count the subsystems touched (UI, API, DB, external services, AI)
- S = 1 subsystem, M = 2, L = 3, XL = 4+
- If a phase touches 4+ subsystems and has complex integration logic, it's XL

**If an XL feels too big**, split it into two L-sized phases that can go in the same sprint. The goal is phases that are completable and verifiable, not phases that drag on indefinitely.

## Goal-Backward Success Criteria

Don't ask "what should we build?" -- ask "what must be TRUE for users when this phase completes?"

For each phase, derive 2-5 success criteria that are:

- Observable from the user's perspective
- Verifiable by a human using the application
- Stated as outcomes, not tasks

Good: "User can log in with email/password and stay logged in across browser sessions"
Bad: "Build authentication system"

## Phase Count Guidance

- Let the work determine the count. Don't pad small projects or compress complex ones.
- 3-5 phases for focused projects, 5-8 for medium, 8-12 for large
- Each phase should feel inevitable given the requirements, not arbitrary

## Anti-Patterns

- Horizontal layers (all models, then all APIs, then all UI)
- Infrastructure-first ordering (3 phases of setup before any user-facing feature)
- Arbitrary splits to hit a number
- Enterprise PM artifacts (time estimates in hours/days, Gantt charts, risk matrices)
- Phases for team coordination, documentation, or ceremonies
- Single-phase sprints when phases could run in parallel
