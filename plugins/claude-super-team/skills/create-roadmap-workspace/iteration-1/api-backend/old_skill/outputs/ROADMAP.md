# Roadmap: ShipTrack API

## Overview

ShipTrack API is a high-throughput logistics tracking service built in Rust (Axum) that ingests GPS events from IoT devices, computes predictive ETAs, and exposes REST + WebSocket APIs for shipping companies. The roadmap moves from foundational API and authentication, through the high-throughput event pipeline, into real-time delivery mechanisms (WebSocket and webhooks), then location intelligence (ETA and geofencing), administration capabilities, and finally operational maturity with data retention and multi-region deployment.

## Phases

- [ ] **Phase 1: Core API & Authentication** - Shipment CRUD endpoints with API key auth and rate limiting
- [ ] **Phase 2: Event Ingestion Pipeline** - High-throughput GPS event intake via TimescaleDB and Redis Streams
- [ ] **Phase 3: Real-Time Delivery** - WebSocket live tracking and webhook notifications on status changes
- [ ] **Phase 4: Location Intelligence** - ETA computation from historical patterns and geofence trigger engine
- [ ] **Phase 5: Administration & Observability** - Admin API for client management, usage stats, and system health
- [ ] **Phase 6: Operational Maturity** - Data retention policies and multi-region deployment with data locality

## Phase Details

### Phase 1: Core API & Authentication
**Goal**: Establish the foundational API service that clients can authenticate against and use to manage shipments.
**Depends on**: Nothing (first phase)
**Requirements**: R1 (Shipment CRUD), R6 (API key auth + rate limiting)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A client can create, read, update, and list shipments through REST endpoints with proper filtering
  2. API requests without a valid API key are rejected with appropriate error responses
  3. Rate limiting enforces per-client request caps and returns 429 when exceeded
  4. PostgreSQL schema for shipments and API keys is in place and migrations run cleanly

### Phase 2: Event Ingestion Pipeline
**Goal**: Accept high-throughput GPS location events from IoT devices and store them efficiently for downstream processing.
**Depends on**: Phase 1
**Requirements**: R2 (Event ingestion at high throughput)
**Success Criteria** (what must be TRUE when this phase completes):
  1. POST /events accepts GPS location + timestamp + device_id payloads and persists them to TimescaleDB hypertables
  2. The ingestion path sustains 10k events/second with 50k burst without dropping data or degrading response times
  3. Redis Streams buffer incoming events for asynchronous downstream consumers
  4. Events are correctly associated with their parent shipment for later querying

### Phase 3: Real-Time Delivery
**Goal**: Enable clients to receive live shipment updates via WebSocket subscriptions and automated webhook callbacks on status changes.
**Depends on**: Phase 2
**Requirements**: R3 (WebSocket live tracking), R7 (Webhook delivery)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A client can open a WebSocket connection, subscribe to a shipment_id, and receive location updates as they arrive
  2. Multiple concurrent WebSocket subscribers to the same shipment each receive every update via Redis pub/sub fan-out
  3. When a shipment status changes (picked_up, in_transit, delivered, delayed), registered webhook URLs receive a POST with the event payload
  4. Failed webhook deliveries are retried with exponential backoff and logged for debugging

### Phase 4: Location Intelligence
**Goal**: Provide predictive ETAs based on historical route data and trigger automated events when shipments enter or exit defined geographic zones.
**Depends on**: Phase 2
**Requirements**: R4 (ETA computation), R5 (Geofencing)
**Success Criteria** (what must be TRUE when this phase completes):
  1. The API returns an ETA for any active shipment, computed from current position and historical route patterns for that corridor
  2. ETAs update as new location events arrive, converging toward the actual delivery time
  3. Clients can define geofence zones (warehouse, delivery area) with geographic boundaries via the API
  4. Entry and exit events fire automatically when a shipment's location crosses a geofence boundary

### Phase 5: Administration & Observability
**Goal**: Give operators an admin API to manage clients, monitor usage, and assess system health.
**Depends on**: Phase 1
**Requirements**: R8 (Admin API)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Admin endpoints allow creating, updating, and disabling client accounts and their API keys
  2. Usage statistics (request counts, event volumes, active connections) are queryable per client and over time ranges
  3. A system health endpoint reports service status, database connectivity, Redis connectivity, and queue depth

### Phase 6: Operational Maturity
**Goal**: Enforce data lifecycle policies and deploy across multiple regions with proper data locality guarantees.
**Depends on**: Phases 1-5
**Requirements**: R9 (Data retention policies), R10 (Multi-region deployment)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Raw GPS events older than 90 days are automatically purged while aggregated data is retained indefinitely
  2. The service runs on Fly.io in multiple regions with read replicas serving local traffic
  3. EU-originated data is stored and served from EU regions, never routed through non-EU infrastructure
  4. Failover between regions works without data loss or extended downtime

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Core API & Authentication | Not started | - |
| 2. Event Ingestion Pipeline | Not started | - |
| 3. Real-Time Delivery | Not started | - |
| 4. Location Intelligence | Not started | - |
| 5. Administration & Observability | Not started | - |
| 6. Operational Maturity | Not started | - |

---
*Created: 2026-03-05*
