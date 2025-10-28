# Operational Flows

This document describes the main end-to-end flows in the platform:
1. Device onboarding into the Nebula mesh
2. Live operations & monitoring
3. Historical analytics & cleanup

Each flow shows which service is authoritative at each step.

---

## 1. Device Onboarding Flow (Provisioning / Licensing)

**Goal:** Bring a new unit (drone, pilot laptop, FTS node) into the secure Nebula VPN with the correct identity, IP and permissions.

**Actors / Services:**
- Admin or pilot (human)
- `nebula-vpn-pki` (PKI)
- Keycloak (auth)
- Target device (Linux, e.g. Jetson drone or Ubuntu laptop)

**Steps:**
1. Admin or pilot authenticates via Keycloak against PKI.
   - `pki_user` role: allowed to request installer for their device.
   - `pki_admin` role: allowed to register new devices, assign tenant, generate license keys.

2. In PKI:
   - A `Tenant` exists or is created.
   - A `Device` entry is created for this unit.
     - `device_type` might be `"drone"` or `"pilot_laptop"` etc.
   - One or more `VpnEndpoint` entries are created for that device.
     - PKI allocates `ip_address` within `192.168.100.x`.
     - PKI associates a `license_key` (active).
     - PKI generates certificate material and validity timestamps.

3. PKI generates an install package as a **Linux shell script**.
   - This script contains (or retrieves on run):
     - certificate/key material for Nebula,
     - Nebula `config.yaml` pre-configured with the assigned IP, routes, etc.,
     - any required service URLs,
     - cluster Keycloak / client info if needed.
   - Windows/MSI is not used right now. The standard target platforms are Linux-based (Jetson drone, Ubuntu laptop).

4. The pilot or technician runs this installer script on the device.
   - The device gets Nebula installed.
   - It comes online in the mesh with the assigned IP(s).
   - From that moment on, the device can reach platform services over Nebula.

**Result:**
- PKI now has a licensed, known device (and its VPN endpoints).
- The device is authenticated into the secure mesh.
- Other services can reliably address it by its Nebula IP.
- Compliance: PKI is the authority that the device is permitted.

---

## 2. Live Operations Flow (Real-time Monitoring)

**Goal:** Maintain live situational awareness of the fleet:
- Who is online?
- Where are they (GPS)?
- Are they healthy?

**Actors / Services:**
- Drone / device in the field
- `nebula-healthcheck-service` (HC)
- `vpn-dashboard`
- Keycloak

**Steps (Connectivity):**
1. Using the list of `VpnEndpoint` entries from PKI (IP + role), HC continuously pings each known endpoint.
   - Direction: `HC -> ping -> drone`.
   - HC measures RTT / success / failure.

2. HC updates its `ConnectivityStatus` table:
   - `status` (`online`, `offline`, `degraded`)
   - `last_ping_success`
   - `rtt_ms`

This is the network heartbeat: “Can I reach you over Nebula right now?”

**Steps (Telemetry / Syslog):**
3. On the drone side, onboard software collects:
   - MAVLink heartbeat,
   - GPS position (~1 Hz),
   - CPU/MEM/system health,
   - any flight / system events.
4. The drone forwards this data via syslog into HC.
   - Direction: `drone -> syslog -> HC`.
   - HC stores each incoming message as a `TelemetryRecord` (raw, unparsed, timestamped, with source IP / device reference).

5. HC can derive the latest known state per device:
   - last GPS fix,
   - last system status,
   - last telemetry timestamp.

**Steps (Operator Visibility):**
6. `vpn-dashboard` authenticates to HC via Keycloak (service client credentials or user token).
7. `vpn-dashboard` queries HC for:
   - current ConnectivityStatus per device/vpn endpoint,
   - latest telemetry snapshot per device (not bulk logs),
   - any classification like role (`primary`, `fts`), device type, etc.

8. `vpn-dashboard` renders:
   - Which drones are online,
   - Their Nebula IP(s),
   - Telemetry summary (position, health),
   - Pilot-relevant context.

**Result:**
- Operations / pilots get a live drone monitor UI.
- Every visible data point ultimately comes from HC (which trusts PKI to map IP → device, and trusts its own telemetry intake).

---

## 3. Historical Analytics Flow (Post-flight / Compliance / Incidents)

**Goal:** Convert raw, high-frequency telemetry into structured flight history, incidents and statistics.

**Actors / Services:**
- `nebula-healthcheck-service` (HC)
- `monitor-service`
- Postgres (monitor-service DB)
- (future) Prometheus / Grafana

**Steps:**
1. `monitor-service` periodically **pulls** raw telemetry and logs from HC.
   - It uses a time-based cursor or similar offset.
   - It ingests:
     - `TelemetryRecord` entries,
     - possibly snapshots of `ConnectivityStatus`.

2. `monitor-service` stores this data in its own Postgres:
   - short-term: raw copies of telemetry (full fidelity),
   - long-term: derived entities.

3. Background workers in `monitor-service` classify the raw data into:
   - `Flight`
     - start_time / end_time,
     - which `Device` flew,
     - summary statistics.
   - `Incident`
     - anomaly events such as link drops, GPS loss, overheating, etc.
   - `ProcessedMetric` / statistics buckets
     - e.g. latency trends, packet loss over time, stability per 5-minute window.

4. Once a `Flight` is “closed” (e.g. landing detected) and data has been summarized:
   - Raw telemetry for that flight can be archived and eventually pruned from hot storage.
   - HC may also delete/rotate old raw telemetry because long-term custody now lives in `monitor-service`.

5. In the future, Prometheus / Grafana will be connected to `monitor-service` (or fed by it) to produce dashboards, trend lines and SLA reporting without directly hammering HC.

**Result:**
- `monitor-service` becomes the authoritative system of record for:
  - flight history,
  - incidents,
  - compliance-grade analytics,
  - long-term performance statistics.

- When someone asks “What happened yesterday at 14:21 with Drone X?”, `monitor-service` is the one answering.

---

## Flow Responsibility Matrix

- PKI (`nebula-vpn-pki`)
  - Authorizes and provisions devices.
  - Assigns IPs.
  - Issues installer scripts (Linux).
  - Enforces license keys.

- HC (`nebula-healthcheck-service`)
  - Validates live connectivity via active ping.
  - Receives and stores raw telemetry via syslog.
  - Holds short-term live state + last known telemetry snapshot.

- vpn-dashboard
  - Authenticated UI for humans.
  - Reads live state from HC.
  - Shows operational status (online/offline, GPS, health).

- monitor-service
  - Pulls data from HC.
  - Converts raw telemetry into long-term history: flights, incidents, statistics.
  - Provides historical queries and analytics.

- iac
  - Deploys all of the above into AWS Kubernetes clusters (`dev`, `prod`) using Pulumi and GitHub Actions.
  - Keeps local `.dev` environments aligned with real cluster config via `make`.

