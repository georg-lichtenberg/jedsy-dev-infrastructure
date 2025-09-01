# Project Structure

## Workspace Organization

````markdown
# Project Structure

## Workspace Organization

```
/Users/georg/projects/jedsy/
├── jedsy-dev-infrastructure/     # 🔧 Dev Infrastructure - Workspace configuration
├── nebula-healthcheck-service/   # ❤️ Healthcheck - VPN endpoint health monitoring
├── monitor-service/              # 📊 Monitor Service - Telemetry processing
├── nebula-vpn-pki/               # 🛡️ VPN PKI - Certificate management
├── vpn-dashboard/                # 🚀 VPN Dashboard - Web interface
└── iac/                          # 🏗️ Infrastructure - Infrastructure as Code
```

Each project has its own repository and should be cloned as siblings in the same parent directory.

## Project Relationships

- **VPN Dashboard** communicates with **Nebula Healthcheck Service** to display endpoint status
- **Nebula Healthcheck Service** interacts with **Nebula VPN PKI** for certificate information
- **Monitor Service** collects telemetry data from endpoints
- **IAC** manages deployment infrastructure for all services

## nebula-healthcheck-service

```
/nebula-healthcheck-service/
├── cmd/                    # Application entry point
├── routes/                 # API endpoints
│   └── routes.go           # HTTP handlers
├── storage/                # Database access
│   └── schema.go           # Schema definitions
├── internal/               # Private code
│   ├── db.go               # Database connection
│   └── logger.go           # Structured logging
├── scripts/                # Utility scripts
│   └── extract-schema.sql  # Schema extraction
└── Makefile                # Build automation
```

## Key Files

- **cmd/main.go**: Application initialization, version information
- **routes/routes.go**: API handlers, endpoint definitions
- **storage/schema.go**: Database schema extraction
- **internal/db.go**: Database connection pool
- **Makefile**: Build process with version injection
````
