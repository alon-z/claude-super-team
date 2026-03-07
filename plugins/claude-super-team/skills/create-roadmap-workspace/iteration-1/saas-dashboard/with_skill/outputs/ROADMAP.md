# Roadmap: MetricsPulse

## Overview

MetricsPulse is delivered in 8 phases across 4 sprints. Sprint 1 establishes multi-tenant auth and a basic working dashboard with one data source -- so users can log in and see a real chart from day one. Sprint 2 expands the data pipeline and builds the full drag-and-drop dashboard builder with team management. Sprint 3 adds alerting, report generation, and the public API. Sprint 4 completes the product with billing, audit logging, and enterprise SSO. Phases within each sprint run in parallel.

## Phases

- [ ] **Phase 1: Multi-Tenant Foundation & Auth** [Sprint 1] [M] - Workspace isolation, email/password + Google auth, basic user model
- [ ] **Phase 2: Data Ingestion Service & First Connector** [Sprint 1] [M] - Backend ingestion service with Stripe connector and TimescaleDB storage
- [ ] **Phase 3: Dashboard Viewer & KPI Widgets** [Sprint 1] [M] - Basic dashboard screen rendering line chart, bar chart, and KPI card from ingested data
- [ ] **Phase 4: Data Source Connectors** [Sprint 2] [L] - Google Analytics, PostgreSQL, and REST API connectors with configurable refresh intervals
- [ ] **Phase 5: Dashboard Builder & Reports** [Sprint 2] [L] - Drag-and-drop widget layout, table widget, and PDF export of dashboard snapshots
- [ ] **Phase 6: Team Management & Audit Log** [Sprint 2] [M] - Roles (owner, admin, viewer), team invitations, and compliance audit log
- [ ] **Phase 7: Alerts & API** [Sprint 3] [L] - Threshold-based alert rules with email/in-app notifications, and programmatic metrics API
- [ ] **Phase 8: Billing & Enterprise SSO** [Sprint 4] [L] - Stripe subscriptions (free/pro/enterprise), usage-based pricing, and SAML SSO for enterprise tier

## Phase Details

### Phase 1: Multi-Tenant Foundation & Auth
**Goal**: Deliver a working multi-tenant application where users can sign up, log in, and land in their isolated workspace.
**Sprint**: 1
**Size**: M
**Depends on**: Nothing (first phase)
**Requirements**: R1, R2 (email/password + Google only; SSO deferred to Phase 8)
**Success Criteria** (what must be TRUE when this phase completes):
  1. User can sign up with email/password and log in to reach their workspace dashboard
  2. User can sign in with Google OAuth and land in the same workspace
  3. Data created in one workspace is never visible from another workspace
  4. Unauthenticated users are redirected to the login page

### Phase 2: Data Ingestion Service & First Connector
**Goal**: Stand up the separate backend ingestion service with TimescaleDB storage and a working Stripe data connector, so real metrics data flows into the system.
**Sprint**: 1
**Size**: M
**Depends on**: Nothing
**Requirements**: R4 (Stripe connector only), R6 (refresh scheduling infrastructure)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Backend ingestion service runs independently from the Next.js app and writes to TimescaleDB
  2. User can connect their Stripe account and see revenue metrics ingested into the system
  3. Configurable refresh interval (1min, 5min, 15min, manual) is stored per data source

### Phase 3: Dashboard Viewer & KPI Widgets
**Goal**: Deliver a basic dashboard screen that renders real Stripe data in line chart, bar chart, and KPI card widgets, giving users an immediate visual payoff.
**Sprint**: 1
**Size**: M
**Depends on**: Phase 1, Phase 2
**Requirements**: R5 (viewer portion: line chart, bar chart, KPI card)
**Success Criteria** (what must be TRUE when this phase completes):
  1. User sees a default dashboard with widgets displaying live Stripe metrics
  2. Line chart, bar chart, and KPI card widgets render correctly with time-series data
  3. Dashboard auto-refreshes based on the configured interval for the underlying data source

### Phase 4: Data Source Connectors
**Goal**: Expand the data pipeline to support all remaining connectors so users can pull metrics from Google Analytics, PostgreSQL databases, and arbitrary REST APIs.
**Sprint**: 2
**Size**: L
**Depends on**: Phase 2
**Requirements**: R4 (Google Analytics, PostgreSQL, REST API connectors), R6 (per-widget refresh)
**Success Criteria** (what must be TRUE when this phase completes):
  1. User can connect a Google Analytics property and see pageview/session metrics on their dashboard
  2. User can connect a PostgreSQL database, write a query, and see results as a metric
  3. User can configure a REST API endpoint and see its JSON response rendered as metrics
  4. Each widget can have its own independent refresh interval

### Phase 5: Dashboard Builder & Reports
**Goal**: Enable users to create and customize their own dashboards with drag-and-drop widget placement and export dashboard snapshots as PDF reports.
**Sprint**: 2
**Size**: L
**Depends on**: Phase 3
**Requirements**: R5 (drag-and-drop, table widget), R8
**Success Criteria** (what must be TRUE when this phase completes):
  1. User can create a new dashboard and add widgets by dragging them onto a grid layout
  2. User can rearrange and resize widgets by dragging them
  3. Table widget displays tabular metric data with sorting
  4. User can click "Export PDF" and receive a PDF snapshot of the current dashboard state

### Phase 6: Team Management & Audit Log
**Goal**: Allow workspace owners to invite team members with role-based access, and record all data access events for compliance.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 1
**Requirements**: R3, R10
**Success Criteria** (what must be TRUE when this phase completes):
  1. Workspace owner can invite users by email and assign them owner, admin, or viewer roles
  2. Viewers can see dashboards but cannot modify widgets, connectors, or team settings
  3. Admins can modify dashboards and connectors but cannot manage billing or delete the workspace
  4. Every data access event (dashboard view, data export, connector change) is recorded with user, timestamp, and action in the audit log

### Phase 7: Alerts & API
**Goal**: Let users set threshold-based alerts on any metric and provide a programmatic API for external integrations.
**Sprint**: 3
**Size**: L
**Depends on**: Phase 4, Phase 5
**Requirements**: R7, R11
**Success Criteria** (what must be TRUE when this phase completes):
  1. User can create an alert rule specifying a metric, threshold, and comparison operator (above/below)
  2. When a metric crosses its threshold, the user receives both an email notification and an in-app notification
  3. External systems can query metrics data via authenticated REST API endpoints
  4. API responses return time-series data in a documented JSON format

### Phase 8: Billing & Enterprise SSO
**Goal**: Monetize the product with Stripe subscriptions across free/pro/enterprise tiers and unlock enterprise onboarding with SAML SSO.
**Sprint**: 4
**Size**: L
**Depends on**: Phase 6, Phase 7
**Requirements**: R9, R2 (SAML SSO)
**Success Criteria** (what must be TRUE when this phase completes):
  1. New workspaces start on the free tier with enforced limits (e.g., connector count, refresh frequency)
  2. User can upgrade to pro or enterprise tier via a Stripe Checkout flow
  3. Usage-based pricing for API calls is tracked and reflected on the Stripe invoice
  4. Enterprise tier users can configure SAML SSO so their team logs in via their identity provider

## Sprint Summary

| Sprint | Phases | What's Demoable After |
|--------|--------|-----------------------|
| 1 | Phase 1, Phase 2, Phase 3 | User can sign up, connect Stripe, and see revenue metrics on a live dashboard |
| 2 | Phase 4, Phase 5, Phase 6 | User can connect any data source, build custom dashboards with drag-and-drop, invite team members, and export PDF reports |
| 3 | Phase 7 | User can set metric alerts and access data via API |
| 4 | Phase 8 | User can subscribe to a paid plan and enterprise teams can log in with SSO |

## Progress

| Phase | Sprint | Size | Status | Completed |
|-------|--------|------|--------|-----------|
| 1. Multi-Tenant Foundation & Auth | 1 | M | Not started | - |
| 2. Data Ingestion Service & First Connector | 1 | M | Not started | - |
| 3. Dashboard Viewer & KPI Widgets | 1 | M | Not started | - |
| 4. Data Source Connectors | 2 | L | Not started | - |
| 5. Dashboard Builder & Reports | 2 | L | Not started | - |
| 6. Team Management & Audit Log | 2 | M | Not started | - |
| 7. Alerts & API | 3 | L | Not started | - |
| 8. Billing & Enterprise SSO | 4 | L | Not started | - |

---
*Created: 2026-03-05*
