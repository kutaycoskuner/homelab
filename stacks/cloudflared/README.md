# cloudflared

Cloudflare Tunnel connector: publishes chosen services under your domain (e.g. `media.<domain>`) through an outgoing connection, so no port is opened on the router. Background: [03 · Exposing services](../../docs/03-exposing-services.md); account and dashboard setup: [Cloudflare Tunnel](../../docs/integrations/cloudflare-tunnel.md).

- image: `cloudflare/cloudflared`, pinned to a version; updates come as Renovate pull requests ([Updates](../../docs/updates.md))
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

1. copy the **tunnel token** from the Cloudflare dashboard (Networking → Tunnels → your tunnel → install page, the value after `--token`), not from the old container; it's not the API token in `tofu/cloudflare` ([two tokens](../../docs/integrations/cloudflare-tunnel.md#two-different-tokens))
2. put it into `tofu/portainer/terraform.tfvars`: the stack in `stacks`, the token as `CLOUDFLARE_TUNNEL_TOKEN` in `stack_env` (see [terraform.tfvars.example](../../tofu/portainer/terraform.tfvars.example))
3. check, on the PC in the repo root: `tofu -chdir=tofu/portainer plan` → `1 to add`
4. remove the old container, on the server: `docker stop cloudflared && docker rm cloudflared` (it holds no data; the tunnel is offline until step 5)
5. create the stack right after, on the PC: `tofu -chdir=tofu/portainer apply`, type `yes`; the dashboard shows the tunnel as **Healthy** again, connector version as in the compose file
6. if the token was ever pasted or shared somewhere: in the dashboard, refresh the tunnel token, put the new one in step 2's place, `apply` again

Without OpenTofu: start the stack in Portainer with the token under Environment variables instead of steps 2, 3 and 5.
