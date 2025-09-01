```markdown
# Nebula-Healthcheck-Service

## Overview

Go service monitoring VPN endpoints and collecting drone telemetry data.

## Core Functionality

- Ping monitoring of VPN endpoints (drones, laptops)
- UDP/HTTP telemetry data collection
- REST API for status and telemetry queries
- Enhanced status API for detailed device monitoring
- Interface type handling (main/FTS) for different network connections

## Code Organization

- `/cmd/main.go`: Entry point, initialization
- `/routes/routes.go`: HTTP handlers, API endpoints
- `/storage/helpers.go`: Helper functions for data transformation
- `/storage/schema.go`: Database schema management
- `/internal/`: Helper functions, logger, DB access

## Database

PostgreSQL with tables:

- `endpoint_status`: Current ping status of endpoints
- `structured_logs`: Telemetry data from drones
- `device_info`: Information about connected devices

## Key APIs

- `/status`: Returns current status of all endpoints
- `/status?device_name=NAME`: Returns status for a specific device
- `/devices/:deviceName/status`: Enhanced status API with connection details
- `/telemetry/:ip`: Returns telemetry data for a specific endpoint
- `/admin/schema`: Returns database schema
- `/uptime`: Returns uptime and version information

## Recent Changes

- Improved interface_type handling to support both string and numeric values
- Enhanced MapInterfaceType function to handle various input formats
- Added device_name parameter to status endpoint for filtering
- Enhanced status API to include detailed connection information
- Fixed issue with interface type detection for M24-12 device

## Next Steps

- Deployment to staging environment
- Performance optimization for high-load scenarios
- Additional monitoring metrics implementation
```
