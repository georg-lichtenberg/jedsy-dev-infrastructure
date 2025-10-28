# Jedsy Drone Network Platform – System Architecture

## Scope

This document describes the core platform services developed and maintained in the following repositories:

1. `iac`
2. `nebula-vpn-pki`
3. `nebula-healthcheck-service`
4. `vpn-dashboard`
5. `monitor-service`

All services are part of the Jedsy drone operations platform. The platform provides:
- secure network access for drones and pilot stations,
- live health and telemetry monitoring,
- long-term monitoring / incident analysis,
- controlled rollout to AWS infrastructure.

Other services owned by other teams (e.g. `ms-glider`) are not described here.

---

## High-level Architecture

The platform is built around a secure mesh VPN (Nebula). Every device that participates in flight operations — drones, pilot laptops, field terminals — is provisioned and authenticated through the PKI. After onboarding, each device becomes part of the Nebula network and receives an IP address in the private `192.168.100.x` range.

Once a device is on the network:
- The **Healthcheck Service (HC)** continuously measures connectivity (active ping) and ingests telemetry/log data from the drone (syslog feed).
- The **vpn-dashboard** shows live state of devices/endpoints to human operators.
- The **monitor-service** pulls historical logs from HC, stores them, classifies them into flights/incidents/statistics, and becomes the long-term historical source of truth.
- All services (including HC, PKI, dashboard, monitor) are deployed via infrastructure defined in `iac` to AWS Kubernetes clusters (`dev` and `prod`).
- Authentication/authorization for both humans and services is enforced via Keycloak (`realm: jedsy`) with role-based access (pilot vs. admin etc.).

---

## Repositories / Services

### 1. `iac`
**Purpose:**  
`iac` (Infrastructure as Code) defines how the platform is deployed to AWS for both `dev` and `prod` environments.  
It is the only source of truth for infrastructure rollout.

**Technology:**
- Pulumi → AWS
- GitHub Actions for CI
- Kubernetes on AWS as runtime environment

**Responsibilities:**
- Create and manage the AWS Kubernetes clusters for both environments (`dev`, `prod`).
- Configure environment variables/secrets for each service.
- Deploy all platform services (PKI, Healthcheck, Dashboard, Monitor, and other team services) into the correct cluster.
- Guarantee that local development and CI/CD use the same rules.

**Environment model:**
- `dev` = staging cluster on AWS  
- `prod` = production cluster on AWS
- Locally, the developer workflow mirrors CI/CD:
  - A `make`-based workflow is used locally.
  - The local environment values live under a `.dev/` directory at the root of each repo.
  - The same env variable names exist in the cluster and are provisioned by `iac`.
  - Goal: if `make` passes locally, GitHub Actions should pass, and rollout should succeed on cluster.

**Why this service matters:**
- `iac` is the deployment topology reference for MCP.
- The MCP agent must know where each service is supposed to run (dev vs. prod) to avoid generating changes against the wrong environment.
- `iac` encodes cluster ownership and boundary of trust (which namespace, which secrets, etc.).

---

### 2. `nebula-vpn-pki`  (PKI)
**Purpose:**  
Authoritative identity and access control layer for the drone network.

**What it does:**
- Maintains authoritative inventory of all devices that are allowed to join the Nebula VPN mesh.
- Issues and manages licenses and install bundles.
- Assigns and tracks Nebula VPN IP addresses (`192.168.100.x`).
- Exposes an authenticated GUI/API that lets authorized users download an installation script to onboard a device.

**Device model:**
- `Device` is the generic entity for any participant in the VPN:
  - drone (Jetson-based onboard computer),
  - pilot laptop (Ubuntu),
  - other field equipment.
- A device can have multiple VPN endpoints, e.g.:
  - A drone can expose `primary` and `FTS` (fault tolerant system) network interfaces.
- Each VPN endpoint has:
  - `ip_address` stored as PostgreSQL `inet`,
  - certificate / key material,
  - validity timestamps,
  - license binding.

**Data ownership:**
`nebula-vpn-pki` owns and persists in Postgres:
- Which device belongs to which tenant (`Tenant`).
- Which VPN endpoints exist for that device (`VpnEndpoint`).
- Which IPs are in use.
- License keys and their status.
- User accounts / permissions (e.g. pilots vs admins).
- Certificate lifecycle (issued, expires, revoked).

**Installer / Provisioning model:**
- The PKI provides an installer as a Linux shell script (not MSI anymore).
  - Drones (Jetson, Linux) and pilot laptops (Ubuntu) run this script.
  - The script installs Nebula and configures it with the correct certificate, keys, and `config.yaml`.
- The PKI issues license keys. A valid license key is required to obtain a working installer.
- Roles:
  - `pki_user` (e.g. pilot) can request and install.
  - `pki_admin` can create devices, assign licenses, manage tenants.

**Security / Auth:**
- Access to PKI endpoints and GUI is protected via Keycloak (`realm: jedsy`).
- Service-to-service access is also done using Keycloak clients (client ID + secret).
- PKI is the single source of truth for identity and allowed network membership.

**Why this service matters:**
- PKI defines “who is allowed in the network” and “which IP identity belongs to which drone”.
- Every other service trusts PKI as the ground truth for devices and endpoints.
- MCP will query PKI metadata to answer questions like:
  - “Which drone is `192.168.100.54`?”
  - “Is Drone X licensed and valid right now?”


---

### 3. `nebula-healthcheck-service`  (HC)
**Purpose:**  
Real-time operational visibility and connectivity assurance.

This service actually does two critical jobs:

#### (A) Active network reachability monitoring
- The Healthcheck Service actively pings every known drone/device on the Nebula network.
- Direction: `HC -> ping -> drone`.
- This validates:
  - connectivity,
  - latency,
  - whether the device is online from the network perspective.
- This is used to answer “is it reachable right now”.

#### (B) Telemetry & syslog ingestion
- Each drone collects its own status data locally via MAVLink (GPS position @1Hz, health state, CPU, MEM, system status, etc.).
- The drone forwards that data via its local syslog and then ships it into the central Healthcheck Service.
- Direction: `drone -> syslog -> HC`.
- The HC syslog endpoint is therefore a central ingestion point for:
  - Telemetry,
  - system logs,
  - flight-relevant events,
  - arbitrary operational messages.

**Important note about “heartbeat”:**
There are two “heartbeats” in the system:
1. Network heartbeat: HC actively pings the drone.
2. Flight/telemetry heartbeat: the drone emits MAVLink-based status and that is forwarded via syslog to HC.
We intentionally keep both. They answer different questions:
- “Can I reach you?” (network)
- “How healthy are you / where are you?” (telemetry)

**Data handling:**
- HC stores raw syslog / telemetry data in its own Postgres database.
- High write rate: GPS at ~1 Hz, plus other system data at lower frequencies.
- HC keeps these raw logs unparsed initially.
- Parsing / categorization (flight segments, incident tags, etc.) is done later by `monitor-service`.

**Performance profile:**
- HC is performance-critical.
- Implemented in Go for high-throughput UDP/syslog ingest and for efficient ping loops.
- Must scale to “many packets per second across many drones” in real time.

**Integration with PKI:**
- HC uses PKI as the source of truth for:
  - Which devices should exist,
  - Which IP addresses they should have,
  - What roles (drone primary interface, FTS interface, pilot laptop, etc.).

**Why this service matters:**
- HC is the live view of the fleet.
- vpn-dashboard queries HC to render the operational picture.
- monitor-service pulls from HC to build long-term history and analytics.
- MCP will use HC to answer runtime questions like:
  - “Is Drone A currently online?”
  - “What is the latest telemetry we saw from Drone B?”


---

### 4. `vpn-dashboard`
**Purpose:**  
Operational dashboard for human operators (pilots, NOC, support).

**Technology:**
- React frontend served via Node.js backend (no static Vite export).
- The service itself talks to HC via API.

**Data sources:**
- Live status: comes directly from `nebula-healthcheck-service` (HC).
  - Which devices are online,
  - last ping / last telemetry timestamp,
  - IP addresses, roles (primary / FTS),
  - GPS / status snapshots.
- Device and tenant info is indirectly based on PKI data, but vpn-dashboard does **not** talk to PKI directly.
  - HC already resolved “which IP is which device” using PKI.
  - Dashboard just consumes the enriched view from HC.

**Auth / Security:**
- Everything is protected via Keycloak (`realm: jedsy`).
  - Human users (pilots, support) authenticate via Keycloak.
  - Service-to-service access also uses Keycloak clients with client ID + secret.
- All access is within the Nebula VPN network space (`192.168.100.x`), so devices and pilots are already on the mesh.
- Goal state: multiple pilots should be able to monitor and (later) control multiple drones (n:m).  
  Today there is still some legacy 1:1 Zerotier coupling, but the target model is full n:m over Nebula.

**Why this service matters:**
- vpn-dashboard is the main human-facing entry point in operations.
- It is effectively “mission control”.
- For MCP, vpn-dashboard is the ideal place to expose summarized fleet state to an operator assistant:
  - “Show all drones that are currently degraded,”
  - “Highlight endpoints without recent telemetry,” etc.

---

### 5. `monitor-service`
**Purpose:**  
Historical analysis, compliance, incident review, and reporting.

This service turns raw live data into long-term operational knowledge.

**Data flow:**
- `monitor-service` periodically **pulls** logs and telemetry from `nebula-healthcheck-service`.
  - Pull is cursor-based / time-based: it remembers where it left off.
- It stores:
  - raw log/telemetry data (full fidelity, at least temporarily),
  - derived / structured data such as:
    - flight sessions (start/end of a flight),
    - incidents,
    - statistics over time.

**Data lifecycle:**
- Short term:
  - Both HC and monitor-service store raw events.
- Mid term (target state):
  - Background workers in monitor-service parse + classify the raw telemetry.
  - After classification (e.g. after landing or after a timeout), monitor-service persists the structured result (flight records, incident records, metrics).
  - Raw data is then pruned/archived (removed from HC and eventually from monitor-service’s hot DB).
- This means: monitor-service becomes the system of record for historical and analytical questions.

**Technology:**
- Backend: FastAPI (Python).
- UI / client: React.
- Database: Postgres.
- Future: integrate Prometheus / Grafana for metrics dashboards.

**Who uses monitor-service:**
- Currently internal / backoffice only.
- vpn-dashboard does **not** call monitor-service directly.
- In the future: operations, compliance, analytics, post-flight review.

**Why this service matters:**
- monitor-service is the “black box recorder”.
- It can answer:
  - “Which flights happened in the last 24h?”
  - “Show incidents for Drone X in the last mission.”
  - “Was there packet loss / link instability yesterday at 14:21?”
- For MCP, monitor-service is where we’ll get historical and statistical context, not just live status.

---

## Cross-cutting Concerns

### Networking / Connectivity Model
- All relevant services (PKI, HC, vpn-dashboard, monitor-service) and all field devices (drones, pilot laptops) are part of the Nebula VPN mesh.
- Each participant receives an IP like `192.168.100.x`.
- The PKI is the single allocator for these IPs and enforces who is allowed to join.
- Goal state:
  - Multiple pilots ↔ multiple drones (n:m control/monitoring) over Nebula.
  - The old 1:1 Zerotier coupling is being phased out.

### Authentication / Authorization
- Keycloak (`realm: jedsy`) is the central identity provider for:
  - human operators (pilots, admins),
  - machine-to-machine service calls (client credentials).
- vpn-dashboard already enforces Keycloak-based auth.
- PKI enforces Keycloak auth and role-based permissions:
  - `pki_user` can onboard a device (installer download).
  - `pki_admin` can create tenants, assign licenses, manage device records.
- monitor-service will be pulled under the same Keycloak model (work in progress).
- Everything sensitive (installer download, flight data, incident history) is behind auth.

### Databases
- All backend services use Postgres.
- Ownership:
  - `nebula-vpn-pki`: device identity, tenants, VPN endpoints, license keys, IP assignments.
  - `nebula-healthcheck-service`: live connectivity data (ping results), telemetry/syslog raw events.
  - `monitor-service`: historical copies of telemetry + derived “flight / incident / stats” data.

No other service is allowed to be the source of truth for these domains.

---

## Deployment / Runtime Topology

- AWS hosts two Kubernetes clusters:
  - `dev`
  - `prod`
- Both clusters are provisioned and updated via `iac` (Pulumi → AWS).
- GitHub Actions is responsible for CI/CD:
  - Build,
  - Test,
  - Deploy to the correct cluster.
- Local development mirrors CI/CD via `make`:
  - `.dev/` in each repo defines local env variables.
  - The variable names and structure match what `iac` sets in the cluster.
  - Goal: if it works locally with `make`, it will work in CI, and rollout will work in the cluster.

---

## Data Flow Summary (text diagram)

1. **Provisioning / Access Control**
   - Admin uses PKI (nebula-vpn-pki) → registers Device + licenses → gets install script.
   - Pilot / Drone runs install script → joins Nebula mesh with assigned `192.168.100.x`.

2. **Live Ops**
   - HC continuously pings all known Nebula endpoints (connectivity check).
   - Drone streams telemetry via syslog → HC stores raw telemetry in Postgres.
   - vpn-dashboard queries HC (with Keycloak auth) → displays live drone/device status to humans.

3. **Historical / Analytics**
   - monitor-service pulls raw telemetry + logs from HC.
   - monitor-service classifies data into flights, incidents, statistics.
   - monitor-service stores structured history in its own Postgres.
   - Old raw telemetry is purged/archived.

This separation ensures:
- PKI = identity, authorization, licensing, IP ownership
- HC = live state
- vpn-dashboard = human ops surface
- monitor-service = historical truth / analytics
- iac = infrastructure definition, deployment, and environment consistency

---

## MCP Integration (Planned)

We will expose a machine-readable system description via MCP so that an AI agent can operate with authoritative context instead of guessing.

### MCP Server #1: repo-context-server
- Read-only.
- Serves static / slow-changing facts:
  - List of repos and their responsibilities.
  - Mapping of which service owns which data.
  - Current environment topology (dev/prod clusters).
  - Auth model (Keycloak, roles).
  - Which service to ask for:
    - live drone status → `nebula-healthcheck-service`
    - historical incidents → `monitor-service`
    - IP / license / device ownership → `nebula-vpn-pki`

### MCP Server #2: runtime-check-server (future)
- Controlled access to live data:
  - “List all currently reachable drones from HC.”
  - “Give me last telemetry timestamp for device X.”
  - “Show me unlicensed endpoints attempting to talk to the network.”
- Will require Keycloak client credentials and strict scoping.

The MCP agent will *not* guess architecture.  
Instead, it will ask the MCP server(s) for truth.

---

