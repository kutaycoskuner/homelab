# portainer

Web UI for Docker: containers, logs, volumes and stacks. Setup and first login: [02 · Docker and Portainer](../../docs/02-docker-portainer.md).

- image: `portainer/portainer-ce:lts`
- ports: `9443` (HTTPS), `9000` (HTTP)
- data: volume `portainer_data`
- secrets: none, so no `.env.example`

## Start

```bash
cd stacks/portainer
docker compose up -d
```

## Switching from `docker run`

Portainer started earlier with `docker run` keeps its data in the `portainer_data` volume, which this compose file reuses.

```bash
docker stop portainer && docker rm portainer   # removes the container, not the volume
docker compose up -d
```

## Update

```bash
docker compose pull && docker compose up -d
```
