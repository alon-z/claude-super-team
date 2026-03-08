# Project: MetricsPulse

## Vision
A multi-tenant SaaS analytics dashboard (Next.js) where businesses connect their data sources (Stripe, Google Analytics, custom APIs), visualize key metrics in customizable dashboards, set alerts on metric thresholds, and share reports with stakeholders. Includes team management, role-based access, and a billing system with Stripe subscriptions.

## Core Value
Business owners see all their key metrics in one place without building custom analytics infrastructure.

## Requirements

### Active
- R1: Multi-tenant architecture with workspace isolation
- R2: User auth with email/password, Google, SSO (SAML) for enterprise
- R3: Team management with roles (owner, admin, viewer)
- R4: Data source connectors: Stripe, Google Analytics, PostgreSQL, REST API
- R5: Dashboard builder: drag-and-drop widgets (line chart, bar chart, KPI card, table)
- R6: Real-time data refresh (configurable per widget: 1min, 5min, 15min, manual)
- R7: Alert rules: when metric crosses threshold, notify via email and in-app
- R8: Report generation: PDF export of dashboard snapshots
- R9: Billing: Stripe subscriptions with free/pro/enterprise tiers, usage-based pricing for API calls
- R10: Audit log for compliance (who accessed what data, when)
- R11: API for programmatic access to metrics data

## Constraints
- Next.js 15 with App Router
- PostgreSQL + TimescaleDB for time-series data
- Deploy on Vercel (frontend) + Railway (backend services)
- SOC 2 considerations for enterprise tier

## Key Decisions
- Separate backend API service for data ingestion (not in Next.js)
- TimescaleDB for time-series storage, regular PostgreSQL for application data
- Stripe Billing for subscriptions, Stripe Connect not needed
