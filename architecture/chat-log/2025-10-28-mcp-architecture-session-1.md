# Jedsy MCP Architecture – Session 1  
**Date:** 2025-10-28  
**Author:** Georg Lichtenberg  
**Topic:** MCP-Server Architektur für das Jedsy Drohnennetzwerk

---

## 1. Ziel dieser Session
Entwurf einer modularen Architektur für das **Jedsy-Drohnennetzwerk**, die später von einem **MCP-Server** (Model Context Protocol Server) kontrolliert und verstanden werden kann.  
Der MCP soll langfristig alle aktiven Repos lesen, API-Schemas verstehen und mit Runtime-Daten aus Healthcheck- und Monitor-Services arbeiten.

---

## 2. Projektübersicht (Repos)
Basierend auf der aktuellen Umgebung:

| Repo | Zweck | Technologie |
|------|-------|-------------|
| **iac** | Deployment-Mechanismen für AWS EKS (staging = dev, production = prod). Pulumi + GitHub Actions. | Pulumi, AWS EKS |
| **nebula-vpn-pki (PKI)** | Zentrale PKI + Datenbank aller Devices, Tenants, VPN-Endpoints und Lizenzen. | FastAPI / Python, Postgres |
| **nebula-healthcheck-service (HC)** | High-performance Healthcheck-Service: Ping zu Drohnen + Syslog-Ingest von Telemetrie. | Go, Postgres |
| **vpn-dashboard** | React/Node-basierte UI für Operatoren: Anzeige aller Devices, Status, Telemetrie. | Node.js |
| **monitor-service** | Langzeit-Archiv und Analyse von Logs aus HC (Flüge, Incidents, Statistiken). | FastAPI + Postgres, evtl. Grafana/Prometheus |

---

## 3. Architekturprinzipien

### Deployment / Runtime Topology
- **Alle Deployments** über `iac` (Pulumi → AWS EKS).
- **Zwei Cluster/Stacks:** `dev` und `prod`.
- Lokale Entwicklung via `make`, mit denselben Regeln wie in CI/CD.
- Environment-Variablen identisch zwischen `.dev` (lokal) und AWS-Cluster-Environments.
- **Ziel:** reproduzierbare Deployments mit maximaler CI-Konformität.

### Identity & Access (PKI)
- Zentrale Wahrheit für alle Devices und VPN-Endpoints.
- Enthält Tabellen:
  - `tenant`, `device`, `vpn_endpoint`, `license`, `user_account`.
- Jede Drohne oder jedes Gerät ist ein **Device**.
- Device kann mehrere VPN-Endpoints besitzen (z. B. `primary`, `fts`).
- IP-Adressen werden ausschließlich von PKI verwaltet (`ip_address inet`).
- Lizenzschlüssel (z. B. `CLAB-2025-DEMO`) werden serverseitig generiert.
- PKI liefert Linux-Installer (Shell-Script), kein Windows-MSI.
- Authentifizierung über **Keycloak (Realm `jedsy`)**.

### Healthcheck Service (HC)
- **Aktiver Ping** von HC → Drohne zur Netzwerküberwachung.
- **Passiver Syslog-Ingest** von Drohne → HC zur Telemetrie.
- **Zwei Heartbeats:**
  1. HC → Drone (Ping)
  2. Drone → HC (Mavlink Heartbeat über Syslog)
- Speicherung aller Rohdaten in Postgres.
- Performance: ca. 1 Hz GPS-Updates, Go-basierter Code.
- Verantwortlich für Live-Status („wer ist online, RTT, GPS, CPU, MEM …“).

### vpn-dashboard
- React/Node.js Frontend + Backend.
- Holt Daten **nur von HC**, nicht direkt von PKI.
- HC wiederum bezieht Stammdaten aus PKI.
- Authentifizierung über Keycloak.
- Haupt-UI für Operatoren (und später für MCP).

### monitor-service
- Pullt Logs regelmäßig von HC (cursor-basiert).
- Speichert sowohl Rohdaten als auch aggregierte Flugdaten.
- Analysiert abgeschlossene Flüge und Incidents.
- Plant spätere Integration mit Prometheus/Grafana.
- Primärer Ort für historische Daten (Compliance, Reports).

---

## 4. Querschnittsthemen

### Netzwerk
- Alle relevanten Services im VPN (`192.168.100.x`).
- Piloten-Laptops und Drohnen ebenfalls im VPN.
- Ziel: 1-zu-n-Beziehung zwischen Piloten und Drohnen via Nebula.

### Authentifizierung & Security
- Zentral über **Keycloak (Realm `jedsy`)**.
- Menschliche User (z. B. Piloten, Admins) + Service-Accounts (per Client ID + Secret).
- PKI Rollen:
  - `pki_user` (Pilot)
  - `pki_admin` (Admin)
- Alle Services sollen per JWT validieren; monitor-service muss noch nachziehen.

---

## 5. MCP Integration – Zielarchitektur

### a. repo-context-server (MCP #1)
- Liest Metadaten aus allen Repos (iac, PKI, HC, Dashboard, Monitor).
- Stellt konsolidierte Architektur- und Schema-Infos bereit.
- Nutzt lokale Dateien (`ARCHITECTURE.md`, `DATA_MODEL.md`, `FLOWS.md`).
- Später: Parst automatisch OpenAPI-Schemas aus `/openapi.json`.

### b. runtime-check-server (MCP #2)
- Aggregiert **Live-Status-Informationen** aus HC und PKI.
- Liefert:
  - Aktuelle Online/Offline-Zustände,
  - Telemetriedaten (GPS, Battery, CPU),
  - Lizenz-Status aus PKI.
- Wird später vom MCP-Agent befragt („Which drones are offline?“).
- Soll selbst API anbieten, z. B. `/mcp/live/online-devices`.

---

## 6. Offene Aufgaben / Next Steps

| Bereich | Aufgabe |
|----------|----------|
| **PKI** | `curl -s https://vpn.uphi.cc/openapi.json` ausführen und OpenAPI-Schema exportieren (für Device/VpnEndpoint/Licenses). |
| **HC (OpenAPI)** | Neue API-Definition erstellen mit Endpoints:<br>  – `GET /devices/live` (alle Devices mit Status)<br>  – `GET /devices/{id}/telemetry/latest`<br>  – `GET /devices/{id}/connectivity` |
| **HC Implementation** | OpenAPI unter `/openapi.json` verfügbar machen (analog PKI). |
| **LIVE_API.md** | Erstellen eines zentralen API-Vertrags zwischen PKI ↔ HC ↔ Dashboard. |
| **runtime-check-server** | Entwurf und Implementierung des MCP-Servers, der beide Datenquellen zusammenführt. |
| **Data Model** | Konsolidierung von Device, VpnEndpoint und Telemetry in `DATA_MODEL.md`. |

---

## 7. Hinweise zur Projektstruktur (aktueller Repo-Stand)


