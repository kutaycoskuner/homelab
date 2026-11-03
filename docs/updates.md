# Updates

How new versions of the images reach the server: as pull requests you check and merge, then Portainer deploys them, by itself or by one tofu command ([How a change reaches the server](#how-a-change-reaches-the-server)).

## What it is and why we use it

- **Renovate**: a free GitHub app that reads the versions in this repo (compose `image:` lines, Dockerfiles, Terraform providers, GitHub Actions, Python `requirements.txt`) and opens a pull request for each new version
    - why: versions don't go stale unnoticed (e.g. a security fix like the `cloudflared` one in Oct 2026); every update is visible, tested by CI and merged by you
    - settings: [renovate.json](../renovate.json)
- **Portainer automatic updates**: a stack deployed from Git checks the repo regularly and redeploys when its files changed
    - set as code in [tofu/portainer](../tofu/portainer/README.md) (`update_interval`), not in Portainer's interface
    - why: after merging, the server updates itself; no SSH, no clicking "Pull and redeploy"
    - for an app whose CI pushes a new image under the same tag (e.g. `:latest`), a [Portainer webhook](integrations/portainer-webhook.md) instead: polling sees no changed file there

```text
new image version → Renovate pull request → CI checks → you merge into dev → Portainer redeploys the stack
```

## How a change reaches the server

A push to `dev` changes nothing on the server until Portainer redeploys the stack. Three ways, all set in [tofu/portainer](../tofu/portainer/README.md):

| Way | Used for | How | Status here (Portainer CE 2.45.3) |
|---|---|---|---|
| **polling** | every stack by default | Portainer checks the branch every `update_interval` (`5m`); a new commit → pull and redeploy | works for homelab stacks (tested again 2026-11-03: the new commit was deployed within 10 minutes); failed for homelab-private stacks on 2026-11-01 (see below) |
| **webhook** | apps whose CI pushes a new image under the same tag (`webhook = true`, e.g. archrium-uo) | the app's CI calls a secret URL after pushing the image; Portainer pulls and redeploys at once ([Portainer webhook](integrations/portainer-webhook.md)) | tested 2026-11-01: works |
| **by hand, as code** | when neither has run, or right away | `tofu apply '-replace=module.portainer.portainer_stack.stack["<stack>"]'` in the private repo's `tofu/portainer` (in this repo: `'-replace=portainer_stack.stack["<stack>"]'`); deletes and recreates the stack from the branch, volumes stay | always works; the fallback |

- **Community or Business Edition**: Portainer's stack docs list polling and webhook without a Business Edition label, its features page lists them as Business Edition; on this server (CE 2.45.3) both work
- **check whether polling ran**: Portainer → Stacks → the stack → the Git section shows the commit it deployed; after a push it should show the new commit within `update_interval` plus a few minutes. On the server, `docker inspect <container> --format '{{.Created}}'` shows when the container was last recreated (UTC)
- **polling on homelab-private stacks**: the private repo needs the GitHub token; tofu sends it write-only, only on create or when `github_token_version` goes up, which may be why Portainer couldn't fetch it

## Exceptions

- **postgres**: no pull requests for major versions (17 → 18): those need a dump and restore of the database, not just a new image
- **nextcloud**: one pull request per major version, because Nextcloud can't skip majors (see [Stack · Nextcloud](stack-nextcloud.md#updating))
- local image names of stacks built on the server (`script-temp_control`, `homelab-hello`) are skipped: they're on no registry; their `FROM` base images are still updated
- images without a version (`latest`, `lts`, `alpine`): Renovate adds a digest (`image:tag@sha256:...`), so a new build also shows up as a pull request
- **Python packages** (`requirements.txt`): one pull request "Update python packages" for all of them, not one per package; the file's lines sit next to each other, so separate pull requests conflicted after every merge (Nov 2026)
- **uptimerobot provider**: stays below 2.0 ([tofu/uptimerobot](../tofu/uptimerobot/README.md))

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
3. merge; within the polling interval Portainer redeploys the stack; if it doesn't, redeploy it by hand ([How a change reaches the server](#how-a-change-reaches-the-server))
4. check the service once (web UI, logs)

Don't want an update: **close** the pull request; Renovate won't propose that version again, only the next one.

**"This branch has conflicts"** after another merge: don't resolve it in GitHub's editor. Tick the rebase box at the bottom of the pull request's description; Renovate rebuilds it on the current `dev` within minutes. If several pull requests change neighbouring lines and keep conflicting, put their versions into one commit on `dev` yourself; Renovate then closes them.

**The Dependency Dashboard** issue stays open on purpose: Renovate keeps it up to date; closed, it opens a new one.

## Changes
- 2026-11-03 — Python packages in one pull request; handling conflicts; the Dependency Dashboard stays open
- 2026-11-03 — polling tested again: works for homelab stacks
- 2026-11-03 — how a change reaches the server: polling, webhook, by hand with tofu -replace; what was tested
- 2026-11-01 — Portainer webhook as the alternative to polling for apps whose CI pushes `:latest`
- 2026-10-28 — Portainer's automatic updates set from tofu/portainer instead of the interface
- 2026-10-28 — setup starts with getting renovate.json onto main; weekly routine, git pull afterwards, closing a pull request to skip a version
- 2026-10-28 — Python packages listed; local image names skipped
- 2026-10-28 — first version: Renovate pull requests, Portainer automatic updates, exceptions for postgres and nextcloud, handling a pull request
