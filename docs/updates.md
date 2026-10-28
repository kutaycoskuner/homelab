# Updates

How new versions of the images reach the server: as pull requests you check and merge, then Portainer deploys them by itself.

## What it is and why we use it

- **Renovate**: a free GitHub app that reads the versions in this repo (compose `image:` lines, Dockerfiles, Terraform providers, GitHub Actions, Python `requirements.txt`) and opens a pull request for each new version
    - why: versions don't go stale unnoticed (e.g. a security fix like the `cloudflared` one in Oct 2026); every update is visible, tested by CI and merged by you
    - settings: [renovate.json](../renovate.json)
- **Portainer automatic updates**: a stack deployed from Git checks the repo regularly and redeploys when its files changed
    - why: after merging, the server updates itself; no SSH, no clicking "Pull and redeploy"

```text
new image version → Renovate pull request → CI checks → you merge into dev → Portainer redeploys the stack
```

## Exceptions

- **postgres**: no pull requests for major versions (17 → 18): those need a dump and restore of the database, not just a new image
- **nextcloud**: one pull request per major version, because Nextcloud can't skip majors (see [Stack · Nextcloud](stack-nextcloud.md#updating))
- local image names of stacks built on the server (`script-temp_control`, `homelab-hello`) are skipped: they're on no registry; their `FROM` base images are still updated
- images without a version (`latest`, `lts`, `alpine`): Renovate adds a digest (`image:tag@sha256:...`), so a new build also shows up as a pull request

## Set it up

1. **install Renovate** (browser): [github.com/apps/renovate](https://github.com/apps/renovate) → **Install** → **Only select repositories** → this repo
    - Renovate reads `renovate.json` and creates an issue **Dependency Dashboard**: the list of all updates it found; repository Issues must be turned on (Settings → General → Features)
    - the first pull requests add digests to `latest` images; merge them like any other
2. **turn on automatic updates in Portainer**, per stack deployed from Git: Stacks → the stack → **Automatic updates** (GitOps updates) → on
    - mechanism: **Polling**, interval e.g. `5m`
    - **Re-pull image**: on, so a changed image is actually pulled
    - **Force redeployment**: off (only redeploy when the repo changed)

## Handle an update pull request

1. read the title: which image, from which version to which
    - patch / minor (`2026.10.2 → 2026.10.3`): usually safe
    - major (`31 → 32`): read the release notes linked in the pull request first
2. wait for CI to be green (the stack is validated and, where possible, started)
3. merge; within the polling interval Portainer redeploys the stack
4. check the service once (web UI, logs)

## Changes
- 2026-10-28 — Python packages listed; local image names skipped
- 2026-10-28 — first version: Renovate pull requests, Portainer automatic updates, exceptions for postgres and nextcloud, handling a pull request
