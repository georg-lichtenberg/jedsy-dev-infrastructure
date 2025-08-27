# Coding Conventions

## General

- Meaningful variable/function names
- Comments for complex logic
- Git feature/fix branches
- Semantic versioning

## Go (nebula-healthcheck-service, monitor-service)

- Standard Go formatting with `gofmt`
- Error handling: always return errors
- Godoc-style comments for exported functions
- Dependency injection for testability

### Project Structure
```
/cmd           # Main application entry point
/internal      # Private application code
/storage       # Database access and models
/routes        # API endpoints and handlers
/config        # Configuration code
/scripts       # Helper scripts
```

## TypeScript (vpn-dashboard, iac)

- ESLint and Prettier for formatting
- TypeScript types for all interfaces
- Functional components with hooks in React
- Modules organized by functionality

## Commit Messages

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
