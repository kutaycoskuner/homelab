# Stack · Uptime Kuma

**Idle: not in use, kept for a later decision.** Replaced by [Monitoring](monitoring.md), whose checks and alerts are configured as code; Kuma is configured in its web UI. The stack lives in `stacks/_idle/uptime-kuma/`.

Tells you when a service is down, before someone else does.

## What it is and why we use it

- **Uptime Kuma**: one container with a web UI; each "monitor" checks one thing every minute (a website answers, a port is open) and sends a message when it fails and when it recovers
    - why: without it, an outage is noticed only when someone opens the site
    - why this one: a single tool with notifications built in (Discord, email, ...); metrics such as CPU or RAM history are a separate, later step (e.g. Prometheus and Grafana)
- limit: it runs on the same server, so if the whole server is down it can't tell you; an outside check (e.g. a free heartbeat service the server pings) covers that

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-tailscale-ip>` | the server's address in the tailnet | `100.x.x.x` |
| `<server-ip>` | the server's LAN address | `192.168.x.x` |
| `<domain>` | your domain on Cloudflare | `example.net` |

## Set it up

1. **deploy** [stacks/_idle/uptime-kuma](../stacks/_idle/uptime-kuma/README.md) (move it back to `stacks/uptime-kuma/` first), e.g. one line in `tofu/portainer`'s stacks; no variables
2. **first login**: `http://<server-tailscale-ip>:3002` from a device in your tailnet ([Tailscale](integrations/tailscale.md))
    - database: choose **SQLite** (one file in the data volume, no extra server)
    - create the admin user right away: the first visitor gets to create it
3. **Discord**: Settings → Notifications → **Setup Notification** → type **Discord**, paste a webhook URL ([Discord webhook](integrations/discord-web-hook.md)), tick **Default enabled** so every new monitor uses it, **Test**, **Save**

## Which monitors to add

| Kind | Monitor type | Address | Catches |
|---|---|---|---|
| public website | HTTP(s) | `https://<subdomain>.<domain>` | the app, the tunnel and DNS in one check |
| service on the server | HTTP(s) | `http://<server-ip>:<port>` | the app itself, without the tunnel |
| database or other non-web port | TCP Port | `<server-ip>` and the port, e.g. `5432` | the port accepts connections |
| DNS server | DNS | a name to resolve, resolver `<server-ip>` | ad blocking DNS still answers |

- one public check per website is the most useful start; add the internal ones for services that have no public address
- a public check failing while the internal one passes points at the tunnel or DNS, not the app

## Backup

All monitors, their history and the settings are in the volume `uptime-kuma_data` (one SQLite file). Back up the volume; without it, the monitors have to be added again.

## Changes
- 2026-10-30 — idle: replaced by the monitoring stack (configured as code); stack moved to stacks/_idle/
- 2026-10-30 — first version: what and why, first login, Discord, which monitors to add, backup
