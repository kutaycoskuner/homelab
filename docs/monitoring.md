# Monitoring

How the server notices that a site is down and tells you on Discord, configured entirely as code. The stack: [stacks/monitoring](../stacks/monitoring/README.md).

## What it is and why we use it

- **why**: without it, an outage is noticed only when someone opens the site
- **why these tools**: blackbox, Prometheus and Alertmanager are the standard open-source monitoring set; each reads its settings from a file, so every check, rule and route is in git, reviewed in pull requests, and comes back the same after a rebuild
- **limit**: it runs on the same server; if the whole server is down it can't tell you, see [When the server itself is down](#when-the-server-itself-is-down)
- **node-exporter**: collects the server's own numbers (CPU, RAM, temperature, disk) and values other stacks write as small files, e.g. the backup's last successful run ([The server's numbers](#the-servers-numbers-node-exporter))
- **Grafana**: draws what Prometheus stores as dashboards, also from files ([Dashboards: Grafana](#dashboards-grafana)); only for looking, the alerts stay in Alertmanager

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
| 2 | Prometheus | every 30 s, asks blackbox to check each URL; also checks that its parts are up (blackbox, Alertmanager, node-exporter, itself) | [prometheus/prometheus.yml](../stacks/monitoring/prometheus/prometheus.yml) |
| 3 | blackbox | does the actual check: an HTTP request to the site, 10 s timeout, redirects followed; reports success, status code, duration, certificate expiry | [blackbox/blackbox.yml](../stacks/monitoring/blackbox/blackbox.yml) |
| 4 | Prometheus | stores the results and evaluates the alert rules every 30 s | [prometheus/alert-rules.yml](../stacks/monitoring/prometheus/alert-rules.yml) |
| 5 | Alertmanager | receives firing alerts, groups them per alert and site, sends them to Discord, reminds every 12 h, posts again when resolved | [alertmanager/alertmanager.yml](../stacks/monitoring/alertmanager/alertmanager.yml) |
| 6 | `start.sh` (Alertmanager image) | writes `DISCORD_WEBHOOK_URL` into the file Alertmanager reads, readable only inside the container | [alertmanager/start.sh](../stacks/monitoring/alertmanager/start.sh) |

## The server's numbers: node-exporter

```text
the server's system (/, read-only) ──┐
                                     ├──> node-exporter ──every 30 s──> Prometheus (job "monitoring")
volume backup-status: *.prom files ──┘
        ^
        └── written by other stacks, e.g. the backup after a successful run
```

- **what**: Prometheus' official exporter for the machine it runs on: CPU, RAM, temperature, disk, network; the base for later dashboards
- **textfile folder**: node-exporter also reads every `*.prom` file in the volume `backup-status` and passes its values on, so a stack without its own metrics can still report one number, e.g. `backup_last_success_timestamp_seconds`
- **the volume**: created by this stack with the fixed name `backup-status`; other stacks mount it as an external volume, so deploy this stack first
- **health**: node-exporter is in the `monitoring` job, so `MonitoringPartDown` covers it
- **image**: downloaded (`prom/node-exporter`), not built: it needs no config file of its own, only its start options in `docker-compose.yml`
- **check**: `…:9090/targets` lists `node-exporter:9100` as **UP**; the query `node_load1` on `…:9090` shows the server's load

## Dashboards: Grafana

```text
Prometheus (15 days of numbers) ──> Grafana ──> http://<server-tailscale-ip>:3010, login admin
                                      ^
             grafana/provisioning ────┤  the data source (this Prometheus) and where the dashboards are
             grafana/dashboards ──────┘  one JSON file per dashboard, in the folder "Homelab"
```

| Dashboard | Shows | File |
|---|---|---|
| **Homelab** | sites up or down, response time, certificate days left, hours since the last backup, monitoring parts, CPU temperature | [homelab.json](../stacks/monitoring/grafana/dashboards/homelab.json) |
| **Node Exporter Full** | everything node-exporter collects: CPU, RAM, disk, network, temperature (community dashboard [1860](https://grafana.com/grafana/dashboards/1860), revision 46) | [node-exporter-full.json](../stacks/monitoring/grafana/dashboards/node-exporter-full.json) |

- **as code**: data source and dashboards are files built into the image, like the other parts; the UI can't save changes to them, so a change goes into the JSON file and is pushed
    - to rework a dashboard visually: change it in Grafana, then **Export** → **Export as JSON** and replace the file's content
- **login**: user `admin`; the password is `GRAFANA_ADMIN_PASSWORD`, generated by tofu in the owner's setup (`tofu output -raw grafana_admin_password` in the private repo's `tofu/portainer`)
    - Grafana reads it **only on its very first start** and keeps it in its volume `grafana_data`; a changed variable doesn't change it
    - to set it again: `docker exec monitoring-grafana grafana cli admin reset-admin-password <new>` on the server
    - deploy the variable **before** the first start, or Grafana starts with its default password `admin`
- **private**: port `3010` (inside the container 3000; on the server 3000 is AdGuard's setup page) like Prometheus' `9090`, for the home network and Tailscale, no tunnel route; sign-up and anonymous access are off, usage statistics and the update check too
- **check**: log in at `…:3010` → Dashboards → Homelab: every panel shows data; a wrong password is refused

## The alerts

| Alert | Fires when | Severity |
|---|---|---|
| `SiteDown` | a URL hasn't answered successfully for 2 minutes | critical |
| `SiteSlow` | answers took over 5 s for 10 minutes | warning |
| `CertificateExpiresSoon` | a site's certificate expires within 14 days | warning |
| `MonitoringPartDown` | blackbox, Prometheus, Alertmanager or node-exporter is unreachable for 5 minutes | critical |
| `BackupTooOld` | the [backup](backup.md)'s last success is over 26 hours old, for 10 minutes: runs fail or stopped entirely | critical |
| `BackupStatusMissing` | the backup's success time is missing for 1 hour (file or volume gone); `BackupTooOld` can't fire meanwhile | warning |

The waiting times ("for") keep a single slow or failed answer from sending a message.

## Why the config is built into the images

Portainer CE deploys a Git stack from its own copy of the repo, and can't mount files from that copy into containers (a Business Edition feature). So each part has a small `Dockerfile` that copies its config files into the official image, and the stack builds these images on the server (`pull_policy: build`), as the `hello` stack does.

- consequence: a changed file reaches the server when Portainer redeploys after the push, by polling or by hand with `tofu apply -replace` ([How a change reaches the server](updates.md#how-a-change-reaches-the-server)), which rebuilds the images
- the personal values (which URLs, which webhook) stay out of the files: they're variables, written into the config by the start scripts at start-up

## Set it up

1. **Discord**: create a webhook for the alerts channel ([Discord webhook](integrations/discord-web-hook.md)); one per tool, so it can be replaced on its own
2. **values**: the stack's three variables, e.g. in `tofu/portainer`'s `stack_env`
    - `PROBE_TARGETS`: e.g. `https://hello.<domain>,https://www.<domain>`; public addresses check the app, the tunnel and DNS at once
    - `DISCORD_WEBHOOK_URL`: the webhook
    - `GRAFANA_ADMIN_PASSWORD`: a long random password, set **before** the first deploy ([Dashboards: Grafana](#dashboards-grafana))
3. **deploy** the stack with re-pull images off (`pull_image = false` in `tofu/portainer`): the images are built on the server
4. **check**: `http://<server-tailscale-ip>:9090/targets` lists every URL with state **UP**; `…:9090/alerts` lists the rules, all **Inactive**; `…:3010` opens Grafana's login

## Daily use

- **add or remove a URL**: change `PROBE_TARGETS` and apply (`tofu apply`); the stack restarts with the new list
- **change a rule or a route**: edit the file here, commit, push; Portainer rebuilds and redeploys (or redeploy by hand, [How a change reaches the server](updates.md#how-a-change-reaches-the-server))
- **test an alert on purpose**: stop a checked service for 3 minutes (e.g. `docker stop hello` on the server); `SiteDown` arrives on Discord, and "resolved" after `docker start hello`
- **test the backup alert**: write an old time into the file, `docker exec backup sh -c 'echo backup_last_success_timestamp_seconds 1700000000 > /status/backup.prom'`; `BackupTooOld` arrives within about 11 minutes, "resolved" after a real run (`docker exec backup backup.sh`)
- **see what's happening**: Prometheus `…:9090/alerts` (rules and their state), Alertmanager `…:9093` (alerts being sent); both read-only

## When something doesn't work

| Symptom | Look at |
|---|---|
| a URL shows **DOWN** on `/targets` | blackbox can't reach it: open the URL from the server (`curl -I <url>`); public URLs go through the tunnel |
| no URLs on `/targets` | `PROBE_TARGETS` empty or misspelled: `docker logs monitoring-prometheus` shows "checking N URL(s)" |
| an alert fires but nothing reaches Discord | `docker logs monitoring-alertmanager`; a wrong or deleted webhook shows as a failed notify |
| a rule change doesn't apply | Portainer hasn't redeployed yet, or the build failed: Portainer → the stack's events |

## When the server itself is down

Monitoring that runs on the server goes silent with it: a power cut, a crash, a frozen system or a home internet outage sends no alert. The backup has a similar gap: it posts only when a run fails, so a backup that stops running at all posts nothing. Both need a check that doesn't depend on the server being up. Free options:

| Option | How | Catches | Misses |
|---|---|---|---|
| **Heartbeat service** (e.g. Healthchecks.io) | the server sends "I'm alive" every few minutes, the backup one after each run; silence → alert | server or internet down, backup stopped | a broken tunnel, a single site down |
| **Website checker** (e.g. UptimeRobot) | an outside service opens the public sites every few minutes | server or internet down, tunnel broken, a single site down | backup stopped |
| **Website checker + backup-age alert** (chosen here, both set up: [UptimeRobot](#the-outside-check-uptimerobot), `BackupTooOld` in [The alerts](#the-alerts)) | the website checker as above; the backup records the time of its last success, and a rule here alerts when it's older than about 26 h | everything above: the outside check covers the server being down, the rule covers the backup | nothing of these; the backup alert waits while the server is down, the outside check fires then |
| **"Backup fresh" URL** | after a backup, the server serves a URL for 24 h; the website checker watches it | backup stopped, server down | needs a web server, a public route and expiry logic; the alert doesn't say which of the two failed |

All four are free; health checks from AWS (~$0.50–1/month) or Cloudflare (paid plan) work too.

### The outside check: UptimeRobot

Set up as code in [tofu/uptimerobot](../tofu/uptimerobot/README.md): every public site is opened from the internet every 5 minutes; a failed check posts to Discord through its own webhook, and again when the site is back.

```text
UptimeRobot (internet) ──every 5 min──> https://<site>.<domain> ──Cloudflare tunnel──> the server
        │  no answer, or an error (e.g. 502 when the app is stopped)
        v
Discord: "Monitor is DOWN: <site>"   ...   "Monitor is UP: <site>"
```

- **both run side by side**: this server's monitoring checks every 30 s and says *which* site is down; UptimeRobot is slower but keeps working when the server itself is gone. When the whole server is down, only UptimeRobot's messages arrive, and they arrive for every site at once
- **which sites**: the public routes of the tunnel, except test pages and routes limited to a path (their front page answers 404 on purpose)
- **test**: stop a site's container for 10 minutes (`docker stop <container>`); DOWN arrives on Discord, UP within 5 minutes after `docker start <container>`

## Changes
- 2026-11-03 — Grafana: dashboards Homelab and Node Exporter Full, as files
- 2026-11-03 — backup-age alerts: BackupTooOld, BackupStatusMissing
- 2026-11-02 — node-exporter: the server's numbers and the shared volume backup-status
- 2026-11-02 — outside check set up: UptimeRobot through tofu/uptimerobot
- 2026-11-02 — when the server itself is down: options for an outside check and a backup-age alert
- 2026-10-30 — first version: pipeline (blackbox, Prometheus, Alertmanager), alerts, why the config is in the images, setup, daily use, troubleshooting
