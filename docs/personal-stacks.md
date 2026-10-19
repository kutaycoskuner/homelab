# Personal stacks

**Personal, not for general use.** The owner's own apps that run on this server. Listed here as a reminder of what runs where and what it depends on; their code, images and setup live in their own repositories, so there's nothing to deploy from this repo.

## Overview

| Stack | What it is | Repository | Ports | Depends on |
|---|---|---|---|---|
| `app-cauldron` | web app: backend API + frontend | [cauldron](https://github.com/kutaycoskuner/cauldron) | `8000` (API), `3003` (web) | images on `ghcr.io` (registry login in Portainer) |
| `app-karel` | web app | [karel](https://github.com/kutaycoskuner/karel) | `4000` | [PostgreSQL](stack-postgres.md): database `kareldb` |
| `bot-mima-discordbot` | Discord bot (Node.js) | [mima-js](https://github.com/kutaycoskuner/mima-js) | none | a Discord bot token (in its own setup) |

## Reminders

- **app-cauldron**
    - images: `ghcr.io/kutaycoskuner/cauldron-backend` and `-frontend`, built for `linux/arm64`
    - the frontend's `PUBLIC_API_BASE_URL` points at the backend: `http://<server-tailscale-ip>:8000` (private) or a tunnel address once public
    - Portainer needs the `ghcr.io` registry login (Registries) to pull private images; that's a different token than the Git one, see [GitHub read-only token](integrations/github-read-token.md)
- **app-karel**
    - its schema lives on the shared postgres: database `kareldb`, created from the repo's `init.sql` (pgAdmin → Query Tool), test data from `test_data.sql`
    - after the postgres stack moved to `db_network`, karel's stack must join that network too
- **bot-mima-discordbot**
    - before Docker it ran under pm2 in tmux ([First setup, before Docker](legacy/first-setup-without-docker.md)); now as a container
    - its token stays in the bot's own `.env` / Portainer variables, never in a repo

## Changes
- 2026-10-19 — first version: overview of the personal stacks (cauldron, karel, mima discord bot) and what each depends on
