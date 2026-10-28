# Updates

How new versions of the images reach the server: as pull requests you check and merge, then Portainer deploys them by itself.

## What it is and why we use it

- **Renovate**: a free GitHub app that reads the versions in this repo (compose `image:` lines, Dockerfiles, Terraform providers, GitHub Actions, Python `requirements.txt`) and opens a pull request for each new version
    - why: versions don't go stale unnoticed (e.g. a security fix like the `cloudflared` one in Oct 2026); every update is visible, tested by CI and merged by you
    - settings: [renovate.json](../renovate.json)
- **Portainer automatic updates**: a stack deployed from Git checks the repo regularly and redeploys when its files changed
    - set as code in [tofu/portainer](../tofu/portainer/README.md) (`update_interval`), not in Portainer's interface
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

1. **get `renovate.json` onto `main`**: Renovate only reads its settings from the repo's default branch (`main`); `renovate.json` there then sends the update pull requests to `dev`
    - commit and push it on `dev`, then open a pull request `dev → main` on GitHub and merge it
    - without it, Renovate opens its own "Configure Renovate" pull request with default settings
2. **install Renovate** (browser): [github.com/apps/renovate](https://github.com/apps/renovate) → **Install** → **Only select repositories** → this repo
    - Renovate reads `renovate.json` and creates an issue **Dependency Dashboard**: the list of all updates it found; repository Issues must be turned on (Settings → General → Features)
    - the first pull requests add digests to `latest` images; merge them like any other
3. **automatic updates in Portainer**: list the stacks in [tofu/portainer](../tofu/portainer/README.md) and run `tofu apply`; it sets polling (`update_interval`, default `5m`) and re-pull image for each
    - by hand instead (not recommended, overwritten by the next `tofu apply`): Stacks → the stack → **Automatic updates** → Polling, `5m`, Re-pull image on

## Routine (e.g. once a week)

1. GitHub → **Issues → Dependency Dashboard**: everything Renovate found, open or waiting
2. **Pull requests** with the label `dependencies`: one per update, handle each as below
3. afterwards, locally on `dev`: `git pull` (fetches the merged updates from GitHub, so your folder isn't behind)

Nothing changes on the server until you merge: Renovate only proposes.

## Handle an update pull request

1. read the title: which image, from which version to which
    - patch / minor (`2026.10.2 → 2026.10.3`): usually safe
    - major (`31 → 32`): read the release notes linked in the pull request first
2. wait for CI to be green (the stack is validated and, where possible, started)
3. merge; within the polling interval Portainer redeploys the stack
4. check the service once (web UI, logs)

Don't want an update: **close** the pull request; Renovate won't propose that version again, only the next one.

## Changes
- 2026-10-28 — Portainer's automatic updates set from tofu/portainer instead of the interface
- 2026-10-28 — setup starts with getting renovate.json onto main; weekly routine, git pull afterwards, closing a pull request to skip a version
- 2026-10-28 — Python packages listed; local image names skipped
- 2026-10-28 — first version: Renovate pull requests, Portainer automatic updates, exceptions for postgres and nextcloud, handling a pull request
