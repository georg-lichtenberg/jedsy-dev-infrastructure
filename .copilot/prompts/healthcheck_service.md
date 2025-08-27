# Nebula-Healthcheck-Service

## Overview
Go service monitoring VPN endpoints and collecting drone telemetry data.

## Core Functionality
- Ping monitoring of VPN endpoints (drones, laptops)
- UDP/HTTP telemetry data collection
- REST API for status and telemetry queries
- Admin interface for database schema and analysis

## Code Organization
- `/cmd/main.go`: Entry point, initialization
- `/routes/routes.go`: HTTP handlers, API endpoints
- `/storage/schema.go`: Database schema management
- `/internal/`: Helper functions, logger, DB access

## Database
PostgreSQL with tables:
- `endpoint_status`: Current ping status of endpoints
- `structured_logs`: Telemetry data from drones
- `device_info`: Information about connected devices

## Key APIs
- `/status`: Returns current status of all endpoints
- `/telemetry/:ip`: Returns telemetry data for a specific endpoint
- `/admin/schema`: Returns database schema
- `/uptime`: Returns uptime and version information

## Recent Changes
- Added version information (Version, BuildTime, GitCommit, SchemaFix)
- Simplified schema extraction in `/storage/schema.go`
- Enhanced uptime endpoint to include version data
- Added schema fix tracking for deployment monitoring
