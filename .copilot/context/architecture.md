# Jedsy System Architecture

## Core Services

1. **nebula-healthcheck-service**: Go service monitoring VPN endpoints and collecting drone telemetry
   - PostgreSQL database for status and telemetry
   - REST API + UDP listener
   - Device health monitoring

2. **monitor-service**: Telemetry processing and analysis

3. **nebula-vpn-pki**: Certificate management for VPN network 

4. **vpn-dashboard**: Web UI for VPN management

5. **iac**: Pulumi-based infrastructure (TypeScript)

## Communication Flow

- Drones → UDP/HTTP → Healthcheck Service → PostgreSQL
- VPN Dashboard ↔ PKI Service ↔ Certificate management
- All services connected via Nebula VPN

## Technology Stack

- **Backend**: Go (microservices)
- **Frontend**: TypeScript/React (dashboard)
- **Infrastructure**: Pulumi (TypeScript)
- **Containerization**: Docker, Kubernetes
- **Database**: PostgreSQL, MongoDB
- **Networking**: Nebula VPN
