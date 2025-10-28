# Environment & Deployment Contract

## Environments
We run the platform in:
- `dev` (staging) – AWS Kubernetes cluster
- `prod` (production) – AWS Kubernetes cluster

Both clusters are created and managed from the `iac` repo using Pulumi and GitHub Actions.

There is also a **local developer environment**.

## Local Development
- Every repo has a `.dev/` directory at the repo root.
- `.dev/` contains the environment variables and config required to run that service locally.
- We always run via `make` locally.

**Rule:**  
`make` locally must invoke the same steps/targets that CI uses.
Goal: if it works locally with `make`, the CI pipeline will pass, and the deploy to `dev`/`prod` will succeed.

This gives us maximum confidence pre-commit.

## CI/CD Pipeline
- GitHub Actions runs the same `make` targets.
- On success, Pulumi (in `iac`) applies the deployment to AWS:
  - picks the correct cluster (`dev` or `prod`),
  - applies manifests / Helm charts / k8s resources,
  - injects environment variables and secrets.

## Runtime Config
- The environment variables you define locally in `.dev/` map 1:1 to the variables that `iac` injects into pods in the cluster.
- No ad-hoc env var names per environment. Names are stable.
- Difference between `dev` and `prod` is values, not keys.

## What MCP / automation must respect
- MCP (or any AI automation) must:
  1. Understand which cluster is being targeted before generating deployment changes.
  2. Use only the env var contract defined in `.dev/` / iac, not invent new variable names.
  3. Assume Keycloak is mandatory for auth, even in `dev`.

If an agent wants to deploy something new, it should:
- generate a `make` target,
- update `.dev/`,
- update Pulumi config in `iac` for both `dev` and `prod`.

This contract is how we prevent "works on my machine, fails in cluster".

