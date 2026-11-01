# portainer

Web UI for Docker: containers, logs, volumes and stacks. Setup and first login: [02 · Docker and Portainer](../../docs/02-docker-portainer.md).

- image: `portainer/portainer-ce:lts`
- ports: `9443` (HTTPS), `9000` (HTTP)
- data: volume `portainer_data`
- secrets: none, so no `.env.example`

## Start

With [scripts/server_base](../../scripts/server_base/README.md), which also installs Docker if needed: `bash scripts/server_base/server_base.sh --install`. By hand:

```bash
cd stacks/portainer
docker compose up -d
```

## Switching from `docker run`

Portainer started earlier with `docker run` keeps its data in the `portainer_data` volume, which this compose file reuses. `server_base.sh --install` detects such a container and offers this switch; by hand:

```bash
docker stop portainer && docker rm portainer   # removes the container, not the volume
docker compose up -d
```

## Update

After `git pull` (e.g. a merged Renovate update): `bash scripts/server_base/server_base.sh --update`, which restarts Portainer only if the image changed. By hand:

```bash
docker compose pull && docker compose up -d
```
