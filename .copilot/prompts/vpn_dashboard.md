```markdown
# VPN Dashboard

## Overview

Node.js/React frontend application for monitoring VPN endpoints and visualizing their status.

## Core Functionality

- Display status of VPN endpoints (drones, laptops, etc.)
- Real-time monitoring of endpoint health
- Device detail views with connectivity information
- Live monitoring for drone telemetry data
- Visualization of network status

## Code Organization

- `/server.js`: Express.js backend server, API proxying
- `/src/api/healthcheck.ts`: API client for Healthcheck Service
- `/src/pages/`: React page components
  - `DashboardPage.tsx`: Main dashboard overview
  - `DevicesPage.tsx`: Device listing and filtering
  - `DeviceDetailPage.tsx`: Single device details
  - `DroneMonitorPage.tsx`: Real-time drone monitoring
- `/scripts/`: Test and utility scripts

## Key Features

- Integration with Healthcheck Service for real-time status
- Device filtering and categorization
- Different views for various device types
- Distinction between different network interfaces (main/FTS)
- Performance optimized real-time monitoring

## Recent Changes

- Fixed API endpoint URL format for enhanced status API
- Improved connection status display in monitor view
- Enhanced performance by minimizing unnecessary re-rendering
- Added support for different interface types (main/FTS)
- Fixed status display for online/offline endpoints
- Reorganized test scripts for better maintenance

## Next Steps

- Deployment to staging environment
- Additional visualization features
- Enhanced filtering and search capabilities
- User authentication improvements
```
