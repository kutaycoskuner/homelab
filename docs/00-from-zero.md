# 00 · From zero to a running server

The whole setup in order, from an empty machine to all stacks running and updating themselves. Each step links to the guide with the details; this page is the map.

```text
A. accounts      (browser, any time before C)   GitHub token, Cloudflare tunnel, Tailscale, Discord webhook
B. server        (on the server, over SSH)      OS, SSH, fixed address -> clone homelab -> Docker + Portainer
C. as code       (on your PC, with OpenTofu)    Portainer stacks -> Cloudflare routes and DNS
D. other stacks  (Portainer)                    services not managed by OpenTofu yet
E. updates       (GitHub)                       Renovate pull requests
```

Why this order: the server only needs Docker and Portainer by hand (B); everything after that is deployed from git by OpenTofu (C), so a rebuilt server comes back the same way.

## A. Accounts and tokens

In the browser; collect each value somewhere safe (a password manager), never in the repo.

1. **GitHub read-only token**: lets Portainer clone the repos the stacks come from ([GitHub read-only token](integrations/github-read-token.md))
2. **Cloudflare**: your domain on Cloudflare, a tunnel created in the dashboard, and from it ([Cloudflare Tunnel](integrations/cloudflare-tunnel.md), [Two different tokens](integrations/cloudflare-tunnel.md#two-different-tokens))
    - the **tunnel token** (for the `cloudflared` stack)
    - an **API token** plus account, zone and tunnel ID (for `tofu/cloudflare`)
3. **Tailscale** account, for private access from your own devices ([Tailscale](integrations/tailscale.md))
4. optional: a **Discord webhook** for the temperature guard ([Discord webhook](integrations/discord-web-hook.md))

## B. The server

1. **Operating system, SSH, fixed address**: [01 · Headless server setup](01-headless-server-setup.md)
    - Raspberry Pi OS is the example there; on **Ubuntu Server**, tick *Install OpenSSH server* in the installer, then continue at [First login](01-headless-server-setup.md#first-login)
2. **Get this repo** on the server (in your home folder):
    ```bash
    git clone https://github.com/kutaycoskuner/homelab.git
    cd homelab
    ```
3. **Docker and Portainer** with one script ([02 · Docker and Portainer](02-docker-portainer.md), [server_base](../scripts/server_base/README.md)):
    ```bash
    bash scripts/server_base/server_base.sh --install   # installs Docker, adds you to the docker group
    newgrp docker                                       # or log out and back in
    bash scripts/server_base/server_base.sh --install   # second run starts Portainer
    ```
4. **Portainer, first login**: open `https://<server-ip>:9443` right away and create the admin user (Portainer locks the first setup after a few minutes); then
    - note the **environment ID**: the number after `#!/` in Portainer's address
    - create an **access token**: your user (top right) > My account > Access tokens

From here on, nothing is deployed by hand on the server.

## C. Stacks and routes as code

On your PC, where you edit the repo ([Terraform and OpenTofu](terraform.md): install, commands, state).

1. **Install OpenTofu** and clone this repo on the PC
2. **Portainer stacks** ([tofu/portainer](../tofu/portainer/README.md)): copy `terraform.tfvars.example` to `terraform.tfvars`, fill in the Portainer address, access token, environment ID, GitHub token, and the stacks to deploy, with `cloudflared` among them and its tunnel token in `stack_env`
    ```powershell
    tofu -chdir=tofu/portainer init
    tofu -chdir=tofu/portainer plan
    tofu -chdir=tofu/portainer apply
    ```
    - Portainer now deploys each stack from git and polls it for changes; `cloudflared` connects the tunnel
3. **Cloudflare routes and DNS** ([tofu/cloudflare](../tofu/cloudflare/README.md)): the same with `tofu/cloudflare`; every route becomes `<subdomain>.<domain>`
4. **Check**: deploy `stacks/hello` with a route `hello`, then open `https://hello.<domain>` ([hello](../stacks/hello/README.md))

**With a private repo of your own** (how the owner runs it): skip the `terraform.tfvars` files here; clone your private repo next to this one, fill its `secrets.auto.tfvars`, and run the same commands there ([Your own values in a private repo](terraform.md#your-own-values-in-a-private-repo)).

## D. Stacks not managed as code yet

Deployed in Portainer as Git stacks, each following its own page; any of them can move into `tofu/portainer` later (one line in `stacks`, its variables in `stack_env`):

- [Tailscale](integrations/tailscale.md): private access, also to services without a public route
- recommended: [Monitoring](monitoring.md): a message to Discord when a site stops answering, configured as code; deploy it with `tofu/portainer` like the stacks in C
- optional: [AdGuard](stack-adguard.md), [PostgreSQL](stack-postgres.md), [Umami](stack-umami.md), [Nextcloud](stack-nextcloud.md), [Media server](stack-media-server.md)

## E. Updates

- **Renovate** opens pull requests for new image versions; after a merge, Portainer's polling redeploys ([Updates](updates.md))
- the server itself: `git pull && bash scripts/server_base/server_base.sh --update` for Docker and Portainer

## Changes
- 2026-10-30 — Monitoring in phase D (Uptime Kuma idle)
- 2026-10-30 — Uptime Kuma in phase D
- 2026-10-28 — first version: the whole setup in order (accounts, server, OpenTofu, other stacks, updates), with the private-repo variant
