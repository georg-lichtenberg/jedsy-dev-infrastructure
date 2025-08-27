# Project Structure

## Workspace Organization

```
/Users/georg/projects/jedsy/
├── nebula-healthcheck-service/   # VPN endpoint health monitoring
├── monitor-service/              # Telemetry processing
├── nebula-vpn-pki/               # Certificate management
├── vpn-dashboard/                # Web interface
└── iac/                          # Infrastructure as Code
```

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
