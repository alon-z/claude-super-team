# Roadmap: ShipTrack API

## Overview

ShipTrack API is a high-throughput logistics tracking service built with Rust/Axum, TimescaleDB, and Redis, deployed on Fly.io. The roadmap is organized into 4 sprints across 8 phases. Sprint 1 establishes the core API with shipment CRUD, authentication, and the event ingestion pipeline in parallel. Sprint 2 layers on real-time features (WebSocket tracking, geofencing, webhooks) that all consume the event pipeline independently. Sprint 3 adds intelligence and operational tooling (ETA engine, admin API, data retention). Sprint 4 handles multi-region deployment once the system is stable. Every sprint produces something a client can integrate with and test.

## Phases

- [ ] **Phase 1: Shipment API & Authentication** [Sprint 1] [M] - REST API for shipment CRUD with API key auth and rate limiting
- [ ] **Phase 2: Event Ingestion Pipeline** [Sprint 1] [L] - High-throughput GPS event ingestion with TimescaleDB and Redis Streams
- [ ] **Phase 3: WebSocket Live Tracking** [Sprint 2] [M] - Real-time shipment location updates via WebSocket subscriptions
- [ ] **Phase 4: Geofencing Engine** [Sprint 2] [M] - Zone definitions with entry/exit event triggers on location updates
- [ ] **Phase 5: Webhook Delivery** [Sprint 2] [M] - Reliable webhook notifications to client URLs on shipment status changes
- [ ] **Phase 6: ETA Computation Engine** [Sprint 3] [L] - Predictive ETA calculation using historical route data and current position
- [ ] **Phase 7: Admin API & Data Retention** [Sprint 3] [M] - Client management, usage stats, system health, and data lifecycle policies
- [ ] **Phase 8: Multi-Region Deployment** [Sprint 4] [L] - Fly.io multi-region with data locality, read replicas, and region-aware routing

## Phase Details

### Phase 1: Shipment API & Authentication
**Goal**: Clients can authenticate with API keys and perform full shipment lifecycle management through a rate-limited REST API.
**Sprint**: 1
**Size**: M
**Depends on**: Nothing (first phase)
**Requirements**: R1 (Shipment CRUD), R6 (API key auth + rate limiting)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A client can create, read, update, and list shipments through REST endpoints with proper filtering and pagination
  2. Requests without a valid API key receive a 401 response; requests exceeding the rate limit receive a 429 response
  3. Each API key is scoped to a client, and clients can only access their own shipments
  4. The shipment lifecycle states (created, picked_up, in_transit, delivered) are enforced with valid transitions

### Phase 2: Event Ingestion Pipeline
**Goal**: IoT devices can submit GPS location events at high throughput, and events are stored in time-series optimized storage for downstream consumption.
**Sprint**: 1
**Size**: L
**Depends on**: Nothing
**Requirements**: R2 (Event ingestion endpoint)
**Success Criteria** (what must be TRUE when this phase completes):
  1. POST /events accepts GPS location, timestamp, and device_id payloads and returns acknowledgment within 50ms at p99
  2. The pipeline sustains 10k events/second with graceful handling of 50k burst via Redis Streams buffering
  3. Events are persisted to TimescaleDB hypertables partitioned by time, with device_id and shipment_id indexed for fast lookups
  4. Event data is queryable: a client can retrieve the location history for a shipment over a time range

### Phase 3: WebSocket Live Tracking
**Goal**: Clients can subscribe to a shipment and receive real-time location updates as GPS events arrive.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 2 (event ingestion pipeline provides the location data stream)
**Requirements**: R3 (WebSocket live tracking)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A client can open a WebSocket connection and subscribe to a shipment_id to receive live location updates
  2. When a GPS event arrives for a subscribed shipment, the location update is pushed to the WebSocket client within 500ms
  3. Multiple clients can subscribe to the same shipment simultaneously without interference
  4. WebSocket connections require valid API key authentication and respect client scope

### Phase 4: Geofencing Engine
**Goal**: Clients can define geographic zones and receive automatic event triggers when shipments enter or exit those zones.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 2 (location events to evaluate against geofences)
**Requirements**: R5 (Geofencing)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A client can define geofence zones (warehouse, delivery area) as polygons or circles via the API
  2. When a shipment's location enters or exits a defined zone, a geofence event is generated with zone_id, event_type (enter/exit), and timestamp
  3. Geofence evaluation happens in the event processing pipeline without degrading ingestion throughput
  4. Geofence events are available through the REST API and pushed via WebSocket to subscribed clients

### Phase 5: Webhook Delivery
**Goal**: Clients receive reliable HTTP notifications at their configured URLs when shipment status changes occur.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 1 (shipment status model)
**Requirements**: R7 (Webhook delivery)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A client can register webhook URLs and specify which status change events to receive (picked_up, in_transit, delivered, delayed)
  2. When a shipment status changes, the webhook payload is delivered to all registered URLs within 30 seconds
  3. Failed deliveries are retried with exponential backoff (at least 3 retries over 1 hour)
  4. Webhook delivery attempts and outcomes are logged and queryable for debugging

### Phase 6: ETA Computation Engine
**Goal**: The system provides accurate, continuously updating ETAs for in-transit shipments based on historical patterns and current position.
**Sprint**: 3
**Size**: L
**Depends on**: Phase 2 (historical event data for route pattern analysis)
**Requirements**: R4 (ETA computation)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Each in-transit shipment has a computed ETA that updates as new GPS events arrive
  2. ETA calculations use historical route data (same origin-destination corridors) to establish baseline travel times
  3. Current position and velocity are factored in to adjust ETAs based on real-time progress
  4. ETA is available via the shipment REST endpoint and pushed through WebSocket updates to subscribed clients

### Phase 7: Admin API & Data Retention
**Goal**: Platform operators can manage clients, monitor usage, check system health, and data lifecycle policies are automatically enforced.
**Sprint**: 3
**Size**: M
**Depends on**: Phase 1 (client model), Phase 2 (event data for retention)
**Requirements**: R8 (Admin API), R9 (Data retention policies)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Admin endpoints allow creating, suspending, and managing client accounts and their API keys
  2. Usage statistics (event counts, API call volumes, active shipments) are available per client and system-wide
  3. A system health endpoint reports database connectivity, Redis status, ingestion lag, and queue depth
  4. Raw GPS events older than 90 days are automatically purged while aggregated route data is retained indefinitely
  5. Data retention runs as a background job without impacting query performance

### Phase 8: Multi-Region Deployment
**Goal**: The service runs across multiple Fly.io regions with data locality guarantees, ensuring EU data stays in EU infrastructure.
**Sprint**: 4
**Size**: L
**Depends on**: Phase 1, Phase 2, Phase 3, Phase 7 (stable system with all core features)
**Requirements**: R10 (Multi-region with data locality)
**Success Criteria** (what must be TRUE when this phase completes):
  1. The API is deployed to at least two Fly.io regions (one EU, one US) with requests routed to the nearest region
  2. EU-origin shipment data is stored exclusively in EU database instances and never replicated to non-EU regions
  3. Read replicas serve queries from the nearest region with acceptable replication lag (under 1 second)
  4. Region failover works: if one region goes down, traffic is redirected to another region within the same data locality zone

## Sprint Summary

| Sprint | Phases | What's Demoable After |
|--------|--------|-----------------------|
| 1 | Phase 1, Phase 2 | Client can authenticate, create shipments, and submit GPS events at high throughput; shipment location history is queryable |
| 2 | Phase 3, Phase 4, Phase 5 | Client can track shipments live via WebSocket, receive geofence entry/exit alerts, and get webhook notifications on status changes |
| 3 | Phase 6, Phase 7 | Shipments show predictive ETAs that update in real-time; operators can manage clients and monitor system health; old data is auto-purged |
| 4 | Phase 8 | Service runs multi-region with EU data locality; clients experience low-latency responses from their nearest region |

## Progress

| Phase | Sprint | Size | Status | Completed |
|-------|--------|------|--------|-----------|
| 1. Shipment API & Authentication | 1 | M | Not started | - |
| 2. Event Ingestion Pipeline | 1 | L | Not started | - |
| 3. WebSocket Live Tracking | 2 | M | Not started | - |
| 4. Geofencing Engine | 2 | M | Not started | - |
| 5. Webhook Delivery | 2 | M | Not started | - |
| 6. ETA Computation Engine | 3 | L | Not started | - |
| 7. Admin API & Data Retention | 3 | M | Not started | - |
| 8. Multi-Region Deployment | 4 | L | Not started | - |

---
*Created: 2026-03-05*
