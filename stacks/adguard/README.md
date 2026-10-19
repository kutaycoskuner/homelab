# adguard

AdGuard Home: the home network's DNS server, blocking ads and trackers for every device. Setup, router settings and tests: [Stack · AdGuard](../../docs/stack-adguard.md).

- image: `adguard/adguardhome:latest`
- ports: `53` (DNS), `3000` (first-time setup), `80` / `443` (web UI)
- data: `ADGUARD_DATA_DIR` (see [.env.example](.env.example)), with `conf/` (settings) and `work/` (statistics)
- secrets: none in files; the admin password is set in the first-time setup and stored in `conf/`

## Start

```bash
mkdir -p <data-dir>/conf <data-dir>/work      # once, on the server
```

- **Portainer**: stack from the repository, `ADGUARD_DATA_DIR` under Environment variables
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d` here

## Switching from a container started earlier

Settings and statistics live in the data folder, not in the container, so nothing is lost:

1. note the folder the old container uses (Portainer → container → **Volumes**), and use it as `ADGUARD_DATA_DIR`
2. `docker stop adguardhome && docker rm adguardhome`
3. deploy this stack; the web UI comes back with the old settings
