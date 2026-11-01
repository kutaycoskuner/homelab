# monitoring

Checks that your sites answer and posts to Discord when one fails, and again when it's fixed. Everything is configured as code in this folder; no web UI is used to set it up. How it works, step by step: [Monitoring](../../docs/monitoring.md).

| Part | Image | Port on the server | Configured in |
|---|---|---|---|
| blackbox | `prom/blackbox-exporter` | none | [blackbox/blackbox.yml](blackbox/blackbox.yml) |
| Prometheus | `prom/prometheus` (busybox) | `9090` | [prometheus/prometheus.yml](prometheus/prometheus.yml), [prometheus/alert-rules.yml](prometheus/alert-rules.yml) |
| Alertmanager | `prom/alertmanager` | `9093` | [alertmanager/alertmanager.yml](alertmanager/alertmanager.yml) |

- variables ([.env.example](.env.example)): `PROBE_TARGETS` (the URLs to check, comma-separated), `DISCORD_WEBHOOK_URL` (secret)
- data: volumes `prometheus_data` (15 days of results) and `alertmanager_data` (what was already sent); both can be lost without harm
- the images are **built on the server** from the folders here, so the config files are inside them (Portainer CE can't mount files from a Git stack); a changed file goes live when Portainer redeploys after the push

## Start

- **Portainer / OpenTofu**: stack from the repository, path `stacks/monitoring/docker-compose.yml`, the two variables, and re-pull images **off** (`pull_image = false`): the images are built, not downloaded
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d --build` here
