# Monitoring

How the server notices that a site is down and tells you on Discord, configured entirely as code. The stack: [stacks/monitoring](../stacks/monitoring/README.md).

## What it is and why we use it

- **why**: without it, an outage is noticed only when someone opens the site
- **why these tools**: blackbox, Prometheus and Alertmanager are the standard open-source monitoring set; each reads its settings from a file, so every check, rule and route is in git, reviewed in pull requests, and comes back the same after a rebuild
- **limit**: it runs on the same server; if the whole server is down it can't tell you (an outside heartbeat check covers that, a later step)
- **later**: node-exporter (CPU, RAM, temperature, disk) and Grafana dashboards, also as files

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-tailscale-ip>` | the server's address in the tailnet | `100.x.x.x` |
| `<domain>` | your domain on Cloudflare | `example.net` |

## The pipeline

```text
PROBE_TARGETS ──> start.sh ──> target file
                                   │
                                   v
 every 30 s:  Prometheus ──"check https://<site>"──> blackbox ──HTTP request──> the site
                  │   <──── result: success? status? time? cert expiry? ────┘
                  │
                  │ stores results (15 days), evaluates alert-rules.yml every 30 s
                  │
                  │ a rule holds for its "for" time -> alert fires
                  v
             Alertmanager ── groups, waits 30 s ──> Discord: "[FIRING:1] SiteDown … <site> is down"
                                                    ... fixed: "[RESOLVED] SiteDown …"
```

| Step | Module | What it does | File |
|---|---|---|---|
| 1 | `start.sh` (Prometheus image) | turns `PROBE_TARGETS` (comma-separated URLs) into the target file Prometheus reads | [prometheus/start.sh](../stacks/monitoring/prometheus/start.sh) |
| 2 | Prometheus | every 30 s, asks blackbox to check each URL; also checks that the three parts are up | [prometheus/prometheus.yml](../stacks/monitoring/prometheus/prometheus.yml) |
| 3 | blackbox | does the actual check: an HTTP request to the site, 10 s timeout, redirects followed; reports success, status code, duration, certificate expiry | [blackbox/blackbox.yml](../stacks/monitoring/blackbox/blackbox.yml) |
| 4 | Prometheus | stores the results and evaluates the alert rules every 30 s | [prometheus/alert-rules.yml](../stacks/monitoring/prometheus/alert-rules.yml) |
| 5 | Alertmanager | receives firing alerts, groups them per alert and site, sends them to Discord, reminds every 12 h, posts again when resolved | [alertmanager/alertmanager.yml](../stacks/monitoring/alertmanager/alertmanager.yml) |
| 6 | `start.sh` (Alertmanager image) | writes `DISCORD_WEBHOOK_URL` into the file Alertmanager reads, readable only inside the container | [alertmanager/start.sh](../stacks/monitoring/alertmanager/start.sh) |

## The alerts

| Alert | Fires when | Severity |
|---|---|---|
| `SiteDown` | a URL hasn't answered successfully for 2 minutes | critical |
| `SiteSlow` | answers took over 5 s for 10 minutes | warning |
| `CertificateExpiresSoon` | a site's certificate expires within 14 days | warning |
| `MonitoringPartDown` | blackbox, Prometheus or Alertmanager is unreachable for 5 minutes | critical |

The waiting times ("for") keep a single slow or failed answer from sending a message.

## Why the config is built into the images

Portainer CE deploys a Git stack from its own copy of the repo, and can't mount files from that copy into containers (a Business Edition feature). So each part has a small `Dockerfile` that copies its config files into the official image, and the stack builds these images on the server (`pull_policy: build`), as the `hello` stack does.

- consequence: a changed file reaches the server when Portainer redeploys after the push (within its polling interval), which rebuilds the images
- the personal values (which URLs, which webhook) stay out of the files: they're variables, written into the config by the start scripts at start-up

## Set it up

1. **Discord**: create a webhook for the alerts channel ([Discord webhook](integrations/discord-web-hook.md)); one per tool, so it can be replaced on its own
2. **values**: the stack's two variables, e.g. in `tofu/portainer`'s `stack_env`
    - `PROBE_TARGETS`: e.g. `https://hello.<domain>,https://www.<domain>`; public addresses check the app, the tunnel and DNS at once
    - `DISCORD_WEBHOOK_URL`: the webhook
3. **deploy** the stack with re-pull images off (`pull_image = false` in `tofu/portainer`): the images are built on the server
4. **check**: `http://<server-tailscale-ip>:9090/targets` lists every URL with state **UP**; `…:9090/alerts` lists the rules, all **Inactive**

## Daily use

- **add or remove a URL**: change `PROBE_TARGETS` and apply (`tofu apply`); the stack restarts with the new list
- **change a rule or a route**: edit the file here, commit, push; Portainer rebuilds and redeploys
- **test an alert on purpose**: stop a checked service for 3 minutes (e.g. `docker stop hello` on the server); `SiteDown` arrives on Discord, and "resolved" after `docker start hello`
- **see what's happening**: Prometheus `…:9090/alerts` (rules and their state), Alertmanager `…:9093` (alerts being sent); both read-only

## When something doesn't work

| Symptom | Look at |
|---|---|
| a URL shows **DOWN** on `/targets` | blackbox can't reach it: open the URL from the server (`curl -I <url>`); public URLs go through the tunnel |
| no URLs on `/targets` | `PROBE_TARGETS` empty or misspelled: `docker logs monitoring-prometheus` shows "checking N URL(s)" |
| an alert fires but nothing reaches Discord | `docker logs monitoring-alertmanager`; a wrong or deleted webhook shows as a failed notify |
| a rule change doesn't apply | Portainer hasn't redeployed yet, or the build failed: Portainer → the stack's events |

## Changes
- 2026-10-30 — first version: pipeline (blackbox, Prometheus, Alertmanager), alerts, why the config is in the images, setup, daily use, troubleshooting
