# uptime-kuma (idle)

**Idle: not in use, kept for a later decision.** Replaced by [monitoring](../../monitoring/README.md), whose checks and alerts are configured as code; Kuma is configured in its web UI. Stacks in `stacks/_idle/` are neither tested by CI nor deployed.

Checks every minute that your services answer (websites, ports) and posts to Discord when one fails and when it's back. Setup, notifications and which monitors to add: [Stack · Uptime Kuma](../../../docs/stack-uptime-kuma.md).

- image: `louislam/uptime-kuma:2`
- port: `3002` (Kuma's own 3001 is taken by umami); open it through Tailscale, not publicly
- data: volume `uptime-kuma_data`, one SQLite file with monitors, history and settings; back it up
- secrets: none in the repo; the Discord webhook is entered in Kuma's web UI and stays in its data volume

## Start

- move the folder back to `stacks/uptime-kuma/` first, so CI checks it again
- **Portainer / OpenTofu**: stack from the repository, path `stacks/uptime-kuma/docker-compose.yml`; no variables
- **CLI**: `docker compose up -d` here
