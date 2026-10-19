# CI

GitHub Actions checks every push and pull request. Workflows are in [.github/workflows/](../.github/workflows/).

## What is checked

- **stacks** ([stacks.yml](../.github/workflows/stacks.yml)), for every `stacks/<service>/docker-compose.yml`
    - validate: `docker compose config` passes, with `.env.example` copied to `.env`
        - fails if the compose file uses a variable that `.env.example` doesn't list
    - smoke test: `docker compose up -d --wait`, containers still running after 15 s, optional URL responds, then `down -v`
        - runs on x86 (`ubuntu-latest`), and also on arm64 (`ubuntu-24.04-arm`, the Pi's CPU type) once the repo is public
- **secrets** ([secrets.yml](../.github/workflows/secrets.yml))
    - [gitleaks](https://github.com/gitleaks/gitleaks) scans the files and the full git history for keys and tokens
    - a check for real Discord webhook URLs, which gitleaks has no rule for

## Per-stack options (`x-ci`)

Set in the stack's own `docker-compose.yml`; Docker ignores top-level `x-` keys.

```yaml
x-ci:
  smoke: false                  # skip the smoke test (default: true), e.g. a stack that needs a real token
  url: https://localhost:9443   # must respond during the smoke test (optional; -k, self-signed certs are fine)
```

## Not covered

- anything that needs the real server or network: `vcgencmd`, host DNS on port 53, tunnels and VPN logins
- placeholder values only: a stack that works with them in CI can still fail with wrong real values

## Changes
- 2026-10-19 — first version: stacks (validate, smoke test, arm64 once public), secrets (gitleaks, Discord webhooks), `x-ci` options
