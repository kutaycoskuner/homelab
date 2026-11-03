# monitoring

Checks that your sites answer and posts to Discord when one fails, and again when it's fixed. Everything is configured as code in this folder; no web UI is used to set it up. How it works, step by step: [Monitoring](../../docs/monitoring.md).

| Part | Image | Port on the server | Configured in |
|---|---|---|---|
| blackbox | `prom/blackbox-exporter` | none | [blackbox/blackbox.yml](blackbox/blackbox.yml) |
| Prometheus | `prom/prometheus` (busybox) | `9090` | [prometheus/prometheus.yml](prometheus/prometheus.yml), [prometheus/alert-rules.yml](prometheus/alert-rules.yml) |
| Alertmanager | `prom/alertmanager` | `9093` | [alertmanager/alertmanager.yml](alertmanager/alertmanager.yml) |
| node-exporter | `prom/node-exporter` (downloaded, not built) | none | [docker-compose.yml](docker-compose.yml) |
| Grafana | `grafana/grafana-oss` | `3000` | [grafana/provisioning/](grafana/provisioning/), [grafana/dashboards/](grafana/dashboards/) |

- variables ([.env.example](.env.example)): `PROBE_TARGETS` (the URLs to check, comma-separated), `DISCORD_WEBHOOK_URL` (secret), `GRAFANA_ADMIN_PASSWORD` (secret, read only on Grafana's first start: set it before the first deploy)
- data: volumes `prometheus_data` (15 days of results), `alertmanager_data` (what was already sent) and `grafana_data` (Grafana's users); all can be lost without harm, Grafana then takes the password from the variable again
- **Grafana**: dashboards of what Prometheus stores (Homelab, Node Exporter Full), loaded from JSON files; login `admin` at `:3000`
- **node-exporter**: the server's own numbers (CPU, RAM, temperature, disk), for later dashboards; reads the server's system through a read-only mount of `/`, and `*.prom` files from the volume `backup-status`
- **volume `backup-status`**: created by this stack under that fixed name; other stacks mount it as an external volume and write one small file there, e.g. the backup's last successful run, which Prometheus then reads through node-exporter. Deploy this stack before those stacks
- the images are **built on the server** from the folders here, so the config files are inside them (Portainer CE can't mount files from a Git stack); a changed file goes live when Portainer redeploys after the push ([How a change reaches the server](../../docs/updates.md#how-a-change-reaches-the-server))

## Start

- **Portainer / OpenTofu**: stack from the repository, path `stacks/monitoring/docker-compose.yml`, the three variables, and re-pull images **off** (`pull_image = false`): the images are built, not downloaded
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d --build` here
