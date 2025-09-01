# Commit Message Template

Follow this format for commit messages:

```
<type>(<scope>): <subject>

<body>

<progress>
- What has been completed?
- What is the next step?
- What issues were encountered?
</progress>
```

## Types

- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Formatting
- refactor: Code restructuring
- test: Tests
- chore: Build process changes

## Scopes

- healthcheck: nebula-healthcheck-service
- monitor: monitor-service
- pki: nebula-vpn-pki
- dashboard: vpn-dashboard
- iac: Infrastructure as Code
- global: Repository-wide changes

## Example:

```
feat(healthcheck): Add endpoint for drone telemetry

- Implements new REST endpoint for /telemetry/drone/:id
- Extends database schema with new fields for drone telemetry
- Adds tests for new endpoint

<progress>
- Completed: REST API endpoint and tests
- Next step: Dashboard integration
- Issues: Performance optimization for large datasets still pending
</progress>
```

This format can be configured for git commit-template.
