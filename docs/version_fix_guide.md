# Behebung des Version-Informationsproblems im Nebula Healthcheck Service

## Problem-Analyse

Nach Untersuchung der IAC- und Build-Konfigurationen wurde das folgende Problem identifiziert:

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

2. Im Dockerfile wird jedoch einfach `go build -o nebula-healthcheck ./cmd` ausgeführt, ohne die LDFLAGS zu übergeben, was dazu führt, dass die Standardwerte ("dev", "unknown") beibehalten werden.

## Lösung

Die Lösung besteht darin, das Dockerfile zu aktualisieren, um das Makefile für den Build zu verwenden oder die LDFLAGS direkt an den Go-Build-Befehl zu übergeben.

### Option 1: Aktualisierung des Dockerfiles (empfohlen)

```dockerfile
FROM golang:1.22-alpine

RUN apk add --no-cache iputils postgresql-client sshpass openssh-client make git

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Verwende make für den Build mit korrekten LDFLAGS
RUN make build

COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
```

### Option 2: Direkte Ergänzung der LDFLAGS im Dockerfile

```dockerfile
FROM golang:1.22-alpine

RUN apk add --no-cache iputils postgresql-client sshpass openssh-client git

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Extrahiere Version, Git-Commit und Build-Zeit und setze sie als Build-Flags
RUN VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "$(date +%Y%m%d)") && \
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "$(date +%s)") && \
    BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") && \
    SCHEMA_FIX=2025-08-27 && \
    go build -ldflags "-s -w -X main.Version=${VERSION} -X main.GitCommit=${GIT_COMMIT} -X main.BuildTime=${BUILD_TIME} -X main.SchemaFIX=${SCHEMA_FIX}" -o nebula-healthcheck ./cmd

COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
```

## GitHub Actions Workflow

Das Problem kann auch im GitHub Actions Workflow behoben werden, falls dort der Docker-Build direkt gesteuert wird. Die Überprüfung des GitHub Repositories und der GitHub Actions Workflows wäre der nächste Schritt, um sicherzustellen, dass die Lösung an der richtigen Stelle implementiert wird.

## Implementierungsschritte

1. Aktualisieren Sie das Dockerfile im `nebula-healthcheck-service` Repository
2. Commiten und pushen Sie die Änderung
3. Die GitHub Actions CI/CD-Pipeline wird automatisch ausgelöst
4. Warten Sie auf den Abschluss der Pipeline
5. Überprüfen Sie den neuen Build auf dem Staging-Server:
   ```bash
   curl "https://ping.uphi.cc/uptime" | jq
   ```

## CI/CD-Pipeline Beachtung

Wichtiger Hinweis: Für den `nebula-vpn-pki` und `nebula-healthcheck-service` muss die komplette CI/CD-Pipeline durchlaufen werden, bevor Änderungen auf dem Staging-Server getestet werden können. Die Bestätigung des Deployments kann über den GitHub Actions Status überprüft werden.
