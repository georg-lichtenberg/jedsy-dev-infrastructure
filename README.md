# Jedsy Development Infrastructure

This repository contains development infrastructure for the Jedsy project, including workspace configurations, Copilot context, and setup scripts.

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
   code /Users/georg/projects/jedsy/jedsy.code-workspace
   ```

## Using with GitHub Copilot

When starting a new GitHub Copilot Chat session, use:

```
Please read the files in jedsy-dev-infrastructure/.copilot to understand the project context.
```

## Maintenance

- Update the workspace configuration in `workspaces/jedsy-all.code-workspace` when needed
- Keep the Copilot context in `.copilot/` up-to-date with project changes
