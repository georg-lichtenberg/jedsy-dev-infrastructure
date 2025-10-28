# Security & Access Model

## Identity Provider
All human and service authentication is handled via Keycloak.
- Realm: `jedsy`

## Roles
### Human-facing roles
- `pki_user`
  - Typical: pilot / field operator.
  - May authenticate against `nebula-vpn-pki` (PKI).
  - May request / download an installer script for their device.
  - Goal: get a drone or pilot laptop onto the Nebula VPN.
- `pki_admin`
  - Typical: backend / ops engineer.
  - May create and manage:
    - Tenants
    - Devices
    - VpnEndpoints
    - License keys
  - Controls who is allowed to join the secure mesh.

### Service-facing roles
- `service`
  - Used for machine-to-machine calls between platform services.
  - These clients use Keycloak client credentials (client ID + secret).
  - Example: `vpn-dashboard` authenticates to `nebula-healthcheck-service` this way.

## Access Boundaries Per Service
### nebula-vpn-pki (PKI)
- Protected by Keycloak.
- Enforces RBAC (`pki_user`, `pki_admin`).
- Exposes:
  - Device registry
  - License key issuance
  - VPN installer script (Linux)
- PKI is the single source of truth for:
  - which device belongs to which tenant
  - which IP(s) they are allowed to use in `192.168.100.x`
  - certificate validity
  - license validity

### nebula-healthcheck-service (HC)
- Protected by Keycloak (service credentials).
- Accepts:
  - syslog / telemetry from drones (inside Nebula network)
  - requests from trusted services (e.g. vpn-dashboard) to read live status
- Stores:
  - raw telemetry (GPS @1Hz, CPU/MEM, MAVLink heartbeat)
  - connectivity status from active ping
- HC is the live operational view of the fleet.

### vpn-dashboard
- React + Node.js.
- Requires Keycloak login for human operators (pilots, NOC).
- Reads live state from HC. Does **not** talk to PKI directly.

### monitor-service
- Backend = FastAPI.
- Will also be Keycloak-protected (in progress).
- Pulls data from HC (cursor-based).
- Produces long-term / compliance data:
  - Flight records
  - Incidents
  - Statistics

## Network Boundary
- All relevant services (PKI, HC, vpn-dashboard, monitor-service) and all field devices (drones, pilot laptops) sit inside the Nebula VPN mesh.
- Address space: `192.168.100.x`
- Only devices provisioned by PKI (with valid license and certificate) may join.

## Summary Rules
- Nobody bypasses PKI to join the mesh.
- Nobody bypasses Keycloak to consume data.
- vpn-dashboard is for live ops.
- monitor-service is for historical / forensic analysis.
- HC and PKI never trust unauthenticated calls.

