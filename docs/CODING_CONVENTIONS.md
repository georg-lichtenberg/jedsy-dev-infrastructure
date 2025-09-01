# Jedsy Development Conventions and Standards

This document serves as a central reference for coding conventions, development standards, and best practices across all Jedsy projects.

## General Conventions

- Use meaningful variable/function names
- Comment complex logic
- Follow Git flow with feature/fix branches
- Apply semantic versioning
- Document APIs and interfaces
- Use English for all code, comments, and documentation

## Language-Specific Conventions

### Go (nebula-healthcheck-service, nebula-vpn-pki)

- Use standard Go formatting with `gofmt`
- Always handle and return errors appropriately
- Write Godoc-style comments for exported functions
- Apply dependency injection for testability
- Follow standard Go project structure:
  ```
  /cmd           # Main application entry point
  /internal      # Private application code
  /storage       # Database access and models
  /routes        # API endpoints and handlers
  /config        # Configuration code
  /scripts       # Helper scripts
  ```

### TypeScript/JavaScript (vpn-dashboard, iac)

- Use ESLint and Prettier for code formatting
- Define TypeScript types for all interfaces
- Use functional components with hooks in React
- Organize modules by functionality
- Use ES Modules (import/export) syntax
- For React projects, follow component-based architecture
- For Node.js backend, use Express.js conventions

## Docker & Container Management

- Use `docker compose build --no-cache` for building projects
- Never use language-specific build commands directly when Docker is involved
- Use multi-stage Docker builds where appropriate
- Follow the one-service-per-container principle
- Always stop containers before rebuilding

## Project Structure & Organization

- Each service maintains its own repository
- Standard directory structures for each language ecosystem
- Environment-specific configuration via environment variables
- Document API endpoints
- Include health check endpoints

## Testing Principles

- Never use mockups or mock services for testing
- Always test against real services when possible
- Never use artificial naming conventions (old, new, better, etc.)
- Git history is the source of truth for all changes
- Use Keycloak for authentication in test environments

## Deployment & Infrastructure

- Infrastructure defined as code using Pulumi (TypeScript)
- CI/CD managed via GitHub Actions
- Complete CI/CD pipeline must run before testing changes on staging for PKI and healthcheck services
- Staging environment is referenced as "dev" in the infrastructure code
- Production deployments require approval
- Local testing:
  - VPN Dashboard: Test locally with `npm run dev`
  - Monitor Service: Test locally with appropriate commands
  - PKI and Healthcheck services: Changes must be deployed via CI/CD to the staging system for testing

## Commit Message Format

Format:

```
<type>(<scope>): <subject>

<body>
```

Types:

- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Formatting
- refactor: Code restructuring
- test: Tests
- chore: Build process changes

Example:

```
fix(healthcheck): Fix ping status bug for drones with CIDR notation

- Extracts clean IP from CIDR notation
- Increases ping count from 1 to 3 for reliability
- Extends timeout from 3 to 5 seconds

<bugfix>
- Issue: Drones with CIDR notation (e.g., 172.20.0.7/32) showed as offline
- Root cause: Ping utility can't process CIDR notation directly
- Solution: Strip CIDR suffix before pinging
</bugfix>
```

## Service Integration Guidelines

- Use proper URLs for service communication
- Implement comprehensive error handling for external calls
- Add detailed logging for debugging
- Set appropriate timeouts for external service calls
- Use token-based authentication between services

## Development Workflow

- Before executing any command, always change to the correct project directory:
  - VPN Dashboard: `/Users/georg/projects/jedsy/vpn-dashboard`
  - PKI: `/Users/georg/projects/jedsy/nebula-vpn-pki`
  - Healthcheck: `/Users/georg/projects/jedsy/nebula-healthcheck-service`
  - Infrastructure: `/Users/georg/projects/jedsy/jedsy-dev-infrastructure`
  - Monitor Service: `/Users/georg/projects/jedsy/monitor-service`
- Use provided Makefiles for standard operations when available
- Follow project-specific README instructions for setup and development
- For local development of services:
  - Use separate terminals for running services and testing (e.g., one terminal for server, another for API tests)
  - For GUI testing, URLs will be provided but browser must be started manually
  - Default local development ports: Frontend (5173), Backend (3001)
- Never run untrusted code or commands

## Deployment & Infrastructure

- Infrastructure defined as code using Pulumi (TypeScript)
- CI/CD managed via GitHub Actions
- Complete CI/CD pipeline must run before testing changes on staging for PKI and healthcheck services
- Staging environment is referenced as "dev" in the infrastructure code
- Production deployments require approval
- Local testing:
  - VPN Dashboard: Test locally with `npm run dev`
  - Monitor Service: Test locally with appropriate commands
  - PKI and Healthcheck services: Changes must be deployed via CI/CD to the staging system for testing

## Error Prevention Checklist

- Check Git status before starting work
- Make small, incremental changes
- Test after each modification
- Document configuration changes
- When issues arise, restore to last working state first

## Additional Resources

Each project may contain more specific conventions in their respective repositories:

- nebula-healthcheck-service/BUILD.md
- vpn-dashboard/DEVELOPMENT_CONVENTIONS.md
- monitor-service/docs/development/DEVELOPMENT_CONVENTIONS.md

---

Last updated: August 27, 2025
