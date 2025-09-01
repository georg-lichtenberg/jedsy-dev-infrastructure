# IAC Repository Documentation

## Overview

The Infrastructure as Code (IAC) repository manages all Jedsy infrastructure through Pulumi, defining both core infrastructure and services. It's organized as a monorepo with TypeScript-based Pulumi projects.

## Key Information

- **Environment Naming**: "dev" in the codebase refers to the staging environment, not local development
- **Production Environment**: No direct access to production environment from local machines
- **Local Testing**: Limited to frontend projects like vpn-dashboard or monitor-service

## Repository Structure

```
/iac
├── infra_core/             # Core infrastructure components
│   ├── global/             # Global infrastructure elements
│   ├── keycloak/           # Identity and access management
│   ├── postgres/           # Database infrastructure
│   └── ...
├── infra_services/         # Application services
│   ├── github-runner/      # GitHub runner service
│   ├── kafka/              # Messaging service
│   ├── logging/            # Logging infrastructure
│   ├── monitoring/         # Monitoring components
│   └── ...
└── util/                   # Shared utilities
```

## Deployment Workflow

1. **Infrastructure Core**: First deployed from infra_core directory

   - Creates EKS clusters, networking, and security infrastructure
   - Sets up base platform services like PostgreSQL operators

2. **Services Layer**: Then deployed from infra_services directory
   - Deploys application services like monitoring, logging, Kafka
   - Configures authentication via Keycloak

## Environment Management

The infrastructure supports multiple environments:

- **Staging**: Referenced as "dev" in Pulumi stacks
- **Production**: Referenced as "prod" in Pulumi stacks

## Key Services

- **AWS EKS**: Kubernetes clusters for application hosting
- **PostgreSQL**: Database services with backup to S3
- **Keycloak**: Authentication service (in eu-central-1 cluster)
- **Monitoring**: Prometheus-based monitoring setup
- **Logging**: Centralized logging infrastructure

## Deployment Commands

```sh
# Navigate to core infrastructure
cd infra_core

# Deploy infrastructure core (for staging environment)
pulumi stack select jedsy/dev
pulumi up

# Navigate to services
cd ../infra_services

# Deploy services (for staging environment)
pulumi stack select jedsy/infra_services/dev
pulumi up
```

## Notes

- The CloudFlare configuration is used for DNS and certificate management
- Karpenter is used for Kubernetes node autoscaling
- Different instance types are configured for production vs. staging environments
- AWS credentials and secrets are managed through Pulumi encrypted configuration
