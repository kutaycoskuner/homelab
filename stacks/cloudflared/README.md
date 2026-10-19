# cloudflared

Cloudflare Tunnel connector: publishes chosen services under your domain (e.g. `media.<domain>`) through an outgoing connection, so no port is opened on the router. Background: [03 · Exposing services](../../docs/03-exposing-services.md); account and dashboard setup: [Cloudflare Tunnel](../../docs/integrations/cloudflare-tunnel.md).

- image: `cloudflare/cloudflared:latest`
- secret: `CLOUDFLARE_TUNNEL_TOKEN` (see [.env.example](.env.example)); routes are configured in the Cloudflare dashboard, not here

## Start

- **Portainer**: stack from the repository, `CLOUDFLARE_TUNNEL_TOKEN` under Environment variables
- **CLI**:
    ```bash
    cd stacks/cloudflared
    cp .env.example .env          # then set CLOUDFLARE_TUNNEL_TOKEN
    docker compose up -d
    docker logs cloudflared       # "Registered tunnel connection" = connected
    ```

## Switching from `docker run`

A connector started with `docker run ... --token <token>` keeps the token in its command line, visible in `docker inspect` and Portainer.

1. copy the token from the Cloudflare dashboard (Networking → Tunnels → your tunnel), not from the old container
2. remove the old container: `docker stop cloudflared && docker rm cloudflared`
3. start this stack with the same token; the dashboard shows the tunnel as **Healthy** again
4. if the token was ever pasted or shared somewhere: in the dashboard, refresh the tunnel token and use the new one
