````markdown
# Jedsy Development Infrastructure

This repository contains development infrastructure for the Jedsy project, including workspace configurations, Copilot context, and setup scripts.

## Workspace Structure

This repository is part of a multi-repository workspace structure. All repositories should be cloned as siblings in the same parent directory:

```
jedsy/
├── jedsy-dev-infrastructure/  # 🔧 Dev Infrastructure - This repository
├── vpn-dashboard/            # 🚀 VPN Dashboard - Frontend for VPN monitoring
├── iac/                      # 🏗️ Infrastructure - Infrastructure as Code
├── monitor-service/          # 📊 Monitor Service - Monitoring service
├── nebula-vpn-pki/           # 🛡️ VPN PKI - VPN Certificate management
└── nebula-healthcheck-service/ # ❤️ Healthcheck - VPN endpoint health monitoring
```

## Project Relationships

- **VPN Dashboard** (Frontend): Provides UI for monitoring VPN endpoints

  - Communicates with the Healthcheck Service for status information
  - Uses enhanced status API endpoints for detailed monitoring

- **Nebula Healthcheck Service** (Backend): Provides health status of VPN endpoints
  - Offers enhanced status API for detailed monitoring
  - Handles interface_type conversion for VPN endpoints (main/FTS)

## Structure

- `.copilot/`: Context information for GitHub Copilot
  - `context/`: General architecture, conventions, and domain information
  - `prompts/`: Service-specific information
- `workspaces/`: VS Code workspace configurations
  - `jedsy-all.code-workspace`: Workspace for all Jedsy projects
- `setup/`: Setup scripts
  - `setup-workspace.sh`: Script to set up the workspace
  - `clone-all-repos.sh`: Script to clone all repositories

## Getting Started

1. Clone this repository:

   ```
   git clone git@github.com:georg-lichtenberg/jedsy-dev-infrastructure.git
   ```

2. Clone all Jedsy repositories:

   ```
   cd jedsy-dev-infrastructure/setup
   ./clone-all-repos.sh
   ```

3. Set up the workspace:

   ```
   ./setup-workspace.sh
   ```

4. Open VS Code with the workspace:
   ```
   code ../jedsy-dev-infrastructure/workspaces/jedsy-all.code-workspace
   ```

## Recent Work and Next Steps

### VPN Dashboard

- ✅ Fixed API endpoint URL format
- ✅ Improved connection status display in monitor view
- ✅ Enhanced performance by minimizing unnecessary re-rendering
- ✅ Reorganized test scripts

### Nebula Healthcheck Service

- ✅ Improved interface_type handling to support both string and numeric values
- ✅ Enhanced status API to provide detailed endpoint information

### Next Steps

- [ ] Deploy both services to staging environment
- [ ] Add performance metrics collection
- [ ] Implement additional monitoring features

## Using with GitHub Copilot

When starting a new GitHub Copilot Chat session, use:

```
Please read the files in jedsy-dev-infrastructure/.copilot to understand the project context.
Remember the workspace structure as defined in jedsy-dev-infrastructure/README.md
```

## Maintenance

- Update the workspace configuration in `workspaces/jedsy-all.code-workspace` when needed
- Keep the Copilot context in `.copilot/` up-to-date with project changes
- Document all significant changes in the "Recent Work and Next Steps" section of this README

## Build and Deploy

### Local Development

Each project has its own Makefile with standardized commands:

- `make local-dev`: Build and run in development mode with hot-reloading
- `make local-start`: Start service locally in background
- `make local-restart`: Restart local service
- `make local-stop`: Stop local service
- `make clean install local-restart`: Full clean rebuild and restart

### Testing

- Use the scripts in each project's `scripts/` directory for testing
- For VPN Dashboard: `./scripts/test_healthcheck_apis.sh` tests the Healthcheck APIs

### Deployment

- Staging: `make deploy-staging`
- Production: `make deploy-prod`
````
