# Secrets and example files

This repo is public. Nothing that grants access, costs money if leaked or identifies the owner's network is ever committed. Instead, every file that would hold such a value is committed as an example with placeholders, and each user keeps their own filled-in copy locally.

## What counts as confidential

- passwords and database credentials
- API keys, access tokens, tunnel tokens
- webhook URLs (a Discord webhook URL contains its token)
- connection strings with credentials
- personal or network details
    - LAN and Tailscale IP addresses
    - usernames on the server
    - router model and settings
    - domain names and links to provider dashboards
    - account IDs (e.g. Cloudflare)

If in doubt, treat it as confidential.

## The `.example` convention

- the committed file is named after the real file with `.example` added at the end
    - `.env` → `.env.example`
    - `config.yaml` → `config.yaml.example`
    - `docker-compose.yml` with personal values → move the values into `.env`, keep the compose file itself committed
- the example sits in the same folder as the real file
- the example has the same keys and structure as the real file, filled with placeholders, so readers see what the file looks like
- the real file is gitignored (`.env`, `config.yaml`); `.gitignore` explicitly keeps `*.example` files committed
- secrets go in `.env`, read by the code or by Docker Compose; everything else that controls a tool goes in `config.yaml`
- `.env` style: keys in `UPPER_SNAKE_CASE` named after the service (`DISCORD_WEBHOOK_URL`), values in double quotes, a comment above each key saying what it is and where to get it
    - `docker run --env-file` keeps the quotes as part of the value; code reading such a value strips them, Compose's `env_file` removes them itself

Example `.env.example`:

```bash
# Discord webhook for the daily report and alerts (Server Settings → Integrations → Webhooks)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/<id>/<token>"
```

## Placeholders

| Real value | Placeholder |
|---|---|
| LAN IP address | `192.168.x.x` |
| host name | `pi.local` |
| domain | `example.net` (subdomains as `analytics.example.net`) |
| user on the server | `<user>` |
| password, token, key | `<your-password>`, `<your-token>`, `<your-api-key>` |
| webhook URL | `https://discord.com/api/webhooks/<id>/<token>` |

- placeholders are obviously fake, so nobody mistakes them for working values
- keep the format of the real value (a URL stays a URL), so the example shows what is expected

## Syncing your copies

> Planned: the sync script isn't written yet. Until then, copy the examples by hand as shown in the [README](../README.md#usage).

Example files change when the repo is updated (a stack gains a new variable, a script a new setting). Your own copies are made once, so they go stale. The planned sync script will, for every `*.example` in the repo:

- if your copy is missing: offer to create it from the example
- if your copy exists: compare its keys with the example's and show missing keys (new in the example) and unknown keys (dropped from the example)
    - only key names are compared; your values are yours and never count as a difference
- offer to merge (new keys added, your values kept), replace or keep
- back up your copy (`<file>.bak`, gitignored) before changing it
- write nothing without a `y`

## Before every commit

- [ ] `git status` shows no `.env`, `config.yaml` or `.bak` files
- [ ] every new confidential value went into the real file, and only a placeholder into the `.example`
- [ ] no real IP, user name, domain or account ID in code, compose files or docs
- [ ] a new key in a real file was also added to its `.example`

## Changes
- 2026-10-19 — `.env` style: service-prefixed keys, quoted values, a comment per key
- 2026-10-19 — first version: what counts as confidential, the `<file>.example` naming, placeholders, the planned sync script, pre-commit checklist
