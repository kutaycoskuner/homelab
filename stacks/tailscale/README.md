# tailscale

Private access to the server from your own devices (SSH, Portainer, any service), without opening ports. Background and when to use it instead of the tunnel: [03 · Exposing services](../../docs/03-exposing-services.md); account and dashboard setup: [Tailscale](../../docs/integrations/tailscale.md).

- image: `tailscale/tailscale:latest`, host network
- data: volume `tailscale-var` (login state)
- secrets: none in files; the login is done once in the browser

## Start and log in

```bash
# 1. Start (or deploy as a Portainer stack, see docs/02-docker-portainer.md)
cd stacks/tailscale
docker compose up -d

# 2. Log in once: open the printed link and approve the device
#    --accept-dns=false: keep the server's own DNS (e.g. AdGuard) instead of Tailscale's
docker exec -it tailscale tailscale up --accept-dns=false

# 3. Check: lists your devices and the server's Tailscale address (100.x.x.x)
docker exec -it tailscale tailscale status
```

- start over with a broken login: `docker exec -it tailscale tailscale up --accept-dns=false --reset`
- a Tailscale installed directly on the host must be removed first, see [First setup, before Docker](../../docs/legacy/first-setup-without-docker.md)
