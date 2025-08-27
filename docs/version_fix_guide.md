# Behebung des Version-Informationsproblems im Nebula Healthcheck Service

## Problem-Analyse

Nach Untersuchung der Build-Konfigurationen wurde das folgende Problem identifiziert:

1. Der Healthcheck-Service enthält korrekte LDFLAGS-Definitionen im Makefile:
   ```makefile
   # Version information
   VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
   GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
   BUILD_TIME ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
   SCHEMA_FIX ?= 2025-08-27

   # Build flags (compatible with existing Dockerfile)
   LDFLAGS=-ldflags "-s -w -X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -X main.BuildTime=$(BUILD_TIME) -X main.SchemaFix=$(SCHEMA_FIX)"
   BUILD_FLAGS=-trimpath $(LDFLAGS)
   ```

2. Diese LDFLAGS werden jedoch im tatsächlichen Build-Prozess über Pulumi/GitHub Actions nicht korrekt an den Go-Build-Befehl übergeben, was dazu führt, dass die Standardwerte ("dev", "unknown") beibehalten werden.

## Hinweis zum Deployment-Prozess

**Wichtig:** Jedsy verwendet Pulumi für Deployments, nicht Docker. Dockerfiles im Repository werden nur für lokale Entwicklungsumgebungen verwendet.

## Nächste Schritte

Um dieses Problem zu lösen, müssen wir:

1. Die GitHub Actions Workflows untersuchen, um zu verstehen, wie der Build-Prozess genau funktioniert
2. Identifizieren, an welcher Stelle im Build-Prozess die LDFLAGS gesetzt werden sollten
3. Die entsprechenden Anpassungen im Build-Prozess vornehmen

## Priorität

Dieses Problem wird für später priorisiert, da wir zunächst das VPN-Dashboard mit der schnelleren /status API testen möchten.

## CI/CD-Pipeline Beachtung

Wichtiger Hinweis: Für den `nebula-vpn-pki` und `nebula-healthcheck-service` muss die komplette CI/CD-Pipeline durchlaufen werden, bevor Änderungen auf dem Staging-Server getestet werden können. Die Bestätigung des Deployments kann über den GitHub Actions Status überprüft werden.
