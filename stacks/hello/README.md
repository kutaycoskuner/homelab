# hello

A one-page test site: deploy it to check that a stack from this repo works end to end. Delete the stack afterwards, or keep it as the simplest example.

- image: built from `nginx:alpine` with [index.html](index.html)
- port: `8088`
- secrets: none

## Test the whole path

1. **deploy from Git**: Portainer → Stacks → Add stack → **Repository**, compose path `stacks/hello/docker-compose.yml` ([how](../../docs/02-docker-portainer.md#deploy-from-the-git-repository))
2. **home network**: open `http://<server-ip>:8088`
3. **Tailscale**: open `http://<server-tailscale-ip>:8088` from a device in your tailnet ([Tailscale](../../docs/integrations/tailscale.md))
4. **public**: add a tunnel route `hello.<domain>` → `HTTP`, `<server-ip>:8088` ([how](../../docs/integrations/cloudflare-tunnel.md#publish-a-service)), then open `https://hello.<domain>`

Each step only adds one link to the chain, so the first one that fails shows where the problem is.

## Remove

- Portainer → Stacks → `hello` → **Delete**
- Cloudflare: delete the `hello` route
