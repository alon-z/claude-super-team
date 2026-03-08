# Project: ShipTrack API

## Vision
A logistics tracking API service (no frontend) that shipping companies integrate with to track packages in real-time. Accepts events from IoT devices (GPS trackers on trucks), processes location data, computes ETAs using historical patterns, and exposes a REST + WebSocket API for clients to query shipment status and receive live updates. Handles high throughput (10k events/second peak).

## Core Value
Shipping companies get accurate, real-time package tracking with predictive ETAs without building their own infrastructure.

## Requirements

### Active
- R1: REST API for shipment CRUD (create, read, update status, list with filters)
- R2: Event ingestion endpoint: POST /events accepting GPS location + timestamp + device_id at high throughput
- R3: WebSocket endpoint for live shipment tracking (subscribe to shipment_id, receive location updates)
- R4: ETA computation engine using historical route data and current position
- R5: Geofencing: define zones (warehouse, delivery area), trigger events on entry/exit
- R6: API key authentication with rate limiting per client
- R7: Webhook delivery: notify client URLs on status changes (picked_up, in_transit, delivered, delayed)
- R8: Admin API for client management, usage stats, system health
- R9: Data retention policies: raw events kept 90 days, aggregated data indefinitely
- R10: Multi-region deployment with data locality (EU data stays in EU)

## Constraints
- Rust (Axum framework) for performance
- PostgreSQL + TimescaleDB for event storage
- Redis for real-time pub/sub and caching
- Deploy on Fly.io with multi-region
- Must handle 10k events/second sustained, 50k burst

## Key Decisions
- Rust + Axum for the core API (performance critical)
- TimescaleDB hypertables for GPS events (time-series optimized)
- Redis Streams for event pipeline, Redis pub/sub for WebSocket fan-out
- Fly.io multi-region with read replicas
