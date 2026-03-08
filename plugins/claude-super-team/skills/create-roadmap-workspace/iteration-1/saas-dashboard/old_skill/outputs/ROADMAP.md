# Roadmap: MetricsPulse

## Overview

MetricsPulse is a multi-tenant SaaS analytics dashboard built with Next.js 15. The roadmap progresses from foundational multi-tenant authentication and team management, through data ingestion and visualization, to alerts, reporting, billing, and compliance -- each phase delivering a complete, verifiable capability that builds on the previous ones.

## Phases

- [ ] **Phase 1: Multi-Tenant Foundation & Authentication** - Workspace isolation, user auth, and team roles
- [ ] **Phase 2: Data Source Connectors** - Connect and ingest data from Stripe, Google Analytics, PostgreSQL, and REST APIs
- [ ] **Phase 3: Dashboard Builder & Real-Time Data** - Drag-and-drop widget builder with configurable refresh intervals
- [ ] **Phase 4: Alerts & Report Generation** - Threshold-based alerts and PDF dashboard exports
- [ ] **Phase 5: Billing & Subscriptions** - Stripe-powered subscription tiers with usage-based pricing
- [ ] **Phase 6: Audit Log & Public API** - Compliance audit trail and programmatic API access

## Phase Details

### Phase 1: Multi-Tenant Foundation & Authentication
**Goal**: Establish a secure, isolated multi-tenant workspace system where users can sign up, authenticate through multiple providers, and manage teams with role-based permissions.
**Depends on**: Nothing (first phase)
**Requirements**: R1 (multi-tenant architecture), R2 (user auth), R3 (team management)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A new user can create a workspace, and that workspace's data is fully isolated from other workspaces
  2. Users can sign up and log in with email/password, Google OAuth, and SAML SSO, and remain authenticated across sessions
  3. A workspace owner can invite team members and assign roles (owner, admin, viewer) that restrict access appropriately
  4. A viewer cannot modify workspace settings or invite new members; an admin can manage members but not billing

### Phase 2: Data Source Connectors
**Goal**: Enable workspaces to connect external data sources and continuously ingest metrics data into TimescaleDB for time-series querying.
**Depends on**: Phase 1
**Requirements**: R4 (data source connectors)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can connect a Stripe account and see transaction metrics flowing into their workspace
  2. A user can connect Google Analytics and see traffic/engagement metrics ingested
  3. A user can connect a PostgreSQL database and query specific tables for metric extraction
  4. A user can configure a custom REST API endpoint and see its data ingested on a schedule
  5. Connection credentials are stored securely and scoped to the workspace that created them

### Phase 3: Dashboard Builder & Real-Time Data
**Goal**: Let users build custom dashboards with draggable widgets that visualize their connected data and refresh automatically at configurable intervals.
**Depends on**: Phase 2
**Requirements**: R5 (dashboard builder), R6 (real-time data refresh)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can create a dashboard and add widgets (line chart, bar chart, KPI card, table) by dragging them onto a canvas
  2. Each widget can be configured to pull data from any connected data source and display the selected metric
  3. A user can set per-widget refresh intervals (1min, 5min, 15min, manual) and see data update automatically
  4. Dashboards persist across sessions and are scoped to the workspace

### Phase 4: Alerts & Report Generation
**Goal**: Allow users to set up threshold-based alerts on their metrics and export dashboard snapshots as PDF reports for stakeholder sharing.
**Depends on**: Phase 3
**Requirements**: R7 (alert rules), R8 (report generation)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can define an alert rule that fires when a metric crosses a threshold (above or below)
  2. When an alert fires, the user receives both an email notification and an in-app notification
  3. A user can export any dashboard as a PDF that accurately reflects the current widget layout and data
  4. Generated PDF reports can be downloaded and shared with stakeholders outside the platform

### Phase 5: Billing & Subscriptions
**Goal**: Monetize the platform with Stripe-powered subscription tiers and usage-based pricing for API calls, gating features by plan level.
**Depends on**: Phase 4
**Requirements**: R9 (billing)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A workspace can subscribe to free, pro, or enterprise tiers through a self-service billing flow
  2. Plan limits are enforced (e.g., free tier has restricted data sources or widget counts)
  3. API call usage is tracked and billed according to the usage-based pricing model
  4. A workspace owner can view billing history, update payment methods, and change plans

### Phase 6: Audit Log & Public API
**Goal**: Provide a compliance-ready audit trail of all data access and a public API for programmatic access to metrics data.
**Depends on**: Phase 5
**Requirements**: R10 (audit log), R11 (API)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Every data access event is logged with who accessed what data and when, viewable by workspace admins
  2. Audit logs can be filtered by user, resource, and time range for compliance investigations
  3. External systems can authenticate via API key and retrieve metrics data programmatically
  4. API access respects workspace isolation and role-based permissions

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Multi-Tenant Foundation & Authentication | Not started | - |
| 2. Data Source Connectors | Not started | - |
| 3. Dashboard Builder & Real-Time Data | Not started | - |
| 4. Alerts & Report Generation | Not started | - |
| 5. Billing & Subscriptions | Not started | - |
| 6. Audit Log & Public API | Not started | - |

---
*Created: 2026-03-05*
