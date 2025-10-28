# Make Rules Contract

## Goal
`make` is our single source of truth for how to:
- run locally,
- run tests,
- build images,
- prepare deployment artifacts for CI/CD.

CI calls the same `make` targets.  
If `make` works on your laptop, CI *should* pass.

## Required Targets (baseline)

### `make build`
- Build the service container/image or binary.
- Uses env from `.dev/` if running locally.
- CI calls this before pushing images.

### `make test`
- Run unit/integration tests for the repo.
- Must not reach out to production resources.
- CI fails if this fails.

### `make run`
- Bring the service up locally with the `.dev/` config.
- For web APIs, this should start the HTTP server (FastAPI, Node.js, etc.).
- For high-performance services like `nebula-healthcheck-service`, this should start the ping loop + syslog listener in a controlled/local-friendly way.

### `make lint` (recommended)
- Static checks, formatting, code conventions.
- Enforces `CODING_CONVENTIONS.md` where relevant.

### `make deploy-dev`
- Produces deployment artifacts consistent with `iac` so they can be applied to the `dev` (staging) cluster on AWS.
- CI uses the same logic post-merge.

## Why this matters for automation / MCP
When we later let an agent propose changes (new endpoint, new worker, new parser job), it must:
1. Update code,
2. Update or add tests,
3. Update `make` targets if needed,
4. Update `iac` so that `deploy-dev` can roll it out.

This is how we stop the agent from giving us code that "kinda works" but isn't shippable.

