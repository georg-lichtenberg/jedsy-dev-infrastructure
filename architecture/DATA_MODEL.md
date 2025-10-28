# Core Data Model

This document defines the core domain entities across the platform.
For each entity we specify:
- Which service "owns" the data (source of truth),
- Key fields,
- Relationships to other entities,
- How other services are allowed to use it.

All databases are PostgreSQL.

---

## Tenant
**Owner:** nebula-vpn-pki  
**Purpose:** Represents a customer / operational unit / legal owner of devices.

**Key fields (representative):**
- `id` (UUID) – primary key
- `name` (text) – tenant name
- `description` (text)
- `contact_email` (text)
- `created_at` (timestamp)

**Relationships:**
- One `Tenant` can have many `Device` instances.
- Licensing and operational permissions are scoped per tenant.

**Access pattern:**
- Used by PKI to decide which devices/pilots belong to whom.
- Used indirectly by HC/monitor for reporting context, but HC/monitor do not mutate tenant data.

---

## Device
**Owner:** nebula-vpn-pki  
**Purpose:** Logical representation of any physical/virtual unit that participates in the secure mesh.

A `Device` can be:
- a drone (Jetson-based onboard compute),
- a pilot laptop (Ubuntu),
- a supporting/FTS unit (fault tolerant backup link),
- or any other network participant that needs Nebula access.

**Key fields:**
- `id` (UUID)
- `tenant_id` (UUID → Tenant.id)
- `name` (text, human-readable identifier)
- `device_type` (text; e.g. `"drone"`, `"pilot_laptop"`, `"fts"`)
- `created_at` (timestamp)
- `last_updated_at` (timestamp)

**Relationships:**
- One `Device` can have multiple `VpnEndpoint` entries (e.g. drone primary link + FTS link).
- Healthcheck and monitoring data are keyed against either `Device.id` or `VpnEndpoint`.

**Access pattern:**
- PKI creates/updates devices.
- HC reads device info (to label telemetry and pings).
- vpn-dashboard and monitor-service consume resolved device metadata through HC; they don’t talk to PKI directly.

---

## VpnEndpoint
**Owner:** nebula-vpn-pki  
**Purpose:** A concrete network identity of a device within the Nebula mesh.

**Key fields:**
- `id` (UUID)
- `device_id` (UUID → Device.id)
- `ip_address` (`inet`) – assigned Nebula VPN IP (e.g. `192.168.100.x`)
- `interface_role` (text; e.g. `"primary"`, `"fts"`)
- `certificate_pem` (text / stored blob or reference)
- `certificate_valid_from` (timestamp)
- `certificate_valid_to` (timestamp)
- `license_key` (text / reference)
- `created_at` (timestamp)
- `revoked_at` (timestamp, nullable)

**Relationships:**
- Belongs to exactly one `Device`.
- A `Device` may expose more than one VPN endpoint (e.g. primary vs FTS link).

**Access pattern:**
- PKI is authoritative for IP assignment and certificate lifecycle.
- HC uses these endpoints to:
  - know which IPs to ping,
  - map incoming syslog/telemetry to the correct device.
- vpn-dashboard indirectly sees endpoint data via HC.
- monitor-service eventually stores historical references to endpoints for analytics and traceability.

---

## License / LicenseKey
**Owner:** nebula-vpn-pki  
**Purpose:** Controls whether a device is allowed to join the secure mesh.

**Key fields:**
- `id` (UUID)
- `tenant_id` (UUID → Tenant.id)
- `license_key` (string, human-readable or structured)
- `status` (enum; e.g. `"active"`, `"revoked"`, `"expired"`)
- `created_at` (timestamp)
- `expires_at` (timestamp)

**Relationships:**
- A `LicenseKey` can be assigned to one or more devices/endpoints depending on your policy model.
- A `VpnEndpoint` references a license key to prove entitlement.

**Access pattern:**
- PKI enforces licensing policy.
- The installer script uses this license to request Nebula credentials.
- Other services should treat license info as read-only classification.

---

## TelemetryRecord (raw)
**Owner:** nebula-healthcheck-service  
**Purpose:** The raw incoming “drone status stream” as delivered via syslog/MAVLink.

A TelemetryRecord represents a single ingested message, not yet interpreted.

**Key fields (representative, this can evolve):**
- `id` (bigint / serial)
- `device_id` (UUID → Device.id) or `vpn_endpoint_id` (UUID → VpnEndpoint.id)
- `timestamp` (timestamp with timezone)
- `source_ip` (`inet`) – IP within Nebula mesh that sent the data
- `message_type` (text; e.g. `"gps"`, `"system"`, `"battery"`, `"mavlink_heartbeat"`, etc.)
- `payload_raw` (jsonb or text) – unparsed body
- `ingest_channel` (text; e.g. `"syslog_udp"`, `"syslog_tcp"`)

**Notes:**
- GPS data is expected at ~1 Hz.
- System health data (CPU/MEM, etc.) is typically slower.
- HC stores this raw feed in Postgres for a short/medium-term window.

**Access pattern:**
- vpn-dashboard asks HC for “latest known state” per device (not bulk raw logs).
- monitor-service periodically pulls TelemetryRecords from HC using a time cursor.

---

## ConnectivityStatus
**Owner:** nebula-healthcheck-service  
**Purpose:** Current reachability of a device, as measured by active ping.

**Key fields:**
- `vpn_endpoint_id` (UUID → VpnEndpoint.id)
- `last_ping_success` (timestamp)
- `rtt_ms` (numeric / float)
- `status` (enum; e.g. `"online"`, `"offline"`, `"degraded"`)
- `last_updated_at` (timestamp)

**Notes:**
- HC updates this as it pings each endpoint (`HC -> ping -> drone`).
- This is the “network heartbeat”.

**Access pattern:**
- vpn-dashboard consumes this to decide if a device is “up”.
- monitor-service may snapshot it to reconstruct incident timelines.

---

## Flight
**Owner:** monitor-service  
**Purpose:** A derived, higher-level representation of an operational mission / flight.

**Key fields (planned / representative):**
- `id` (UUID)
- `device_id` (UUID → Device.id)
- `start_time` (timestamp)
- `end_time` (timestamp, nullable until landed)
- `status` (enum; e.g. `"in_progress"`, `"completed"`, `"aborted"`)
- `summary_stats` (jsonb) – computed metrics like distance flown, altitudes, packet loss, etc.

**Notes:**
- monitor-service infers flights by analyzing TelemetryRecords (GPS movement patterns, arming/disarming states, etc.) pulled from HC.
- Once a flight is “closed” (e.g. landing detected or timeout reached), monitor-service persists it.
- After finalizing, raw TelemetryRecords can be pruned/archived.

**Access pattern:**
- Today internal only.
- Future: dashboards, compliance reporting, incident review.

---

## Incident
**Owner:** monitor-service  
**Purpose:** A detected anomaly or event of interest (loss of connectivity, battery anomaly, unexpected behavior).

**Key fields (planned / representative):**
- `id` (UUID)
- `device_id` (UUID → Device.id)
- `flight_id` (UUID → Flight.id, nullable if not flight-related)
- `timestamp_detected` (timestamp)
- `incident_type` (text; e.g. `"link_drop"`, `"thermal_warning"`, `"gps_loss"`)
- `severity` (enum; e.g. `"info"`, `"warning"`, `"critical"`)
- `details` (jsonb) – structured description or extracted metrics

**Access pattern:**
- monitor-service writes and queries incidents.
- vpn-dashboard does not directly read incidents yet.
- Long term: incident data will be exposed to ops teams and potentially regulators.

---

## ProcessedMetric / Statistics
**Owner:** monitor-service  
**Purpose:** Aggregated statistics for reporting and long-term trend analysis.

**Key fields (planned / representative):**
- `id` (UUID)
- `device_id` (UUID → Device.id)
- `metric_name` (text; e.g. `"avg_rtt_ms"`, `"gps_signal_quality"`, `"packet_loss_rate"`)
- `time_bucket_start` (timestamp)
- `time_bucket_end` (timestamp)
- `value` (numeric / jsonb)

**Access pattern:**
- Generated asynchronously by background workers.
- Queried for dashboards, Prometheus/Grafana integration, SLA/quality reporting.

---

## Summary of Ownership

- **nebula-vpn-pki**
  - Tenant
  - Device
  - VpnEndpoint
  - LicenseKey
  - (Authority for Nebula IP assignment and provisioning)

- **nebula-healthcheck-service**
  - TelemetryRecord (raw, recent)
  - ConnectivityStatus (live reachability)
  - (Authority for "who is online right now / what is the last telemetry state")

- **monitor-service**
  - Flight
  - Incident
  - ProcessedMetric / Statistics
  - (Authority for "what actually happened over time / compliance record / analytics")

