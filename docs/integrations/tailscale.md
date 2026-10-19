# Tailscale

Private network between your own devices, so the server's admin pages, SSH and databases are reachable from anywhere without being public.

## What it is and why we use it

- **Tailscale**: a VPN service; every device you log in gets a private `100.x.x.x` address in your "tailnet"
    - why: no ports opened on the router, works behind CGNAT, free for personal use
    - when: anything only you use (SSH, Portainer, pgAdmin); public things go through the [Cloudflare Tunnel](cloudflare-tunnel.md)

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-tailscale-ip>` | the server's address in the tailnet | `100.x.x.x` |
| `<user>` | your user on the server | `admin` |

## Set up

1. create an account at [tailscale.com](https://tailscale.com) (log in with an existing Google/GitHub/Microsoft account)
2. install the Tailscale app on your PC and phone and log in with the same account
3. on the server: deploy [stacks/tailscale](../../stacks/tailscale/README.md), then log it in:
    ```bash
    docker exec -it tailscale tailscale up --accept-dns=false
    ```
    - open the printed link, approve the server
    - `--accept-dns=false`: the server keeps its own DNS (e.g. AdGuard) instead of Tailscale's
4. Tailscale admin console → **Machines** → the server → **Disable key expiry**
    - otherwise the server drops out of the tailnet after a few months and needs a new login, possibly while you're away
5. check: `docker exec -it tailscale tailscale status` lists your devices and `<server-tailscale-ip>`

## Use it

- SSH from anywhere: `ssh <user>@<server-tailscale-ip>`
- web UIs: `https://<server-tailscale-ip>:9443` (Portainer), any other port the same way
- other services by address, e.g. pgAdmin connecting to a database on `<server-tailscale-ip>:5432`

## Changes
- 2026-10-19 — first version, rewritten from the private notes: what and why, account, devices, server login with `--accept-dns=false`, key expiry, use
