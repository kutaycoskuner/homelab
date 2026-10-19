# 03 · Exposing services

How services on the server are reached from outside the home network: publicly through a Cloudflare Tunnel, privately through Tailscale. Includes what was tried first and why it failed. Needs [02 · Docker and Portainer](02-docker-portainer.md).

## What they are and why we use them

- **Cloudflare Tunnel**: a connector on the server opens an outgoing connection to Cloudflare; Cloudflare forwards requests for your subdomains through it
    - why: works without opening router ports and behind CGNAT (see below); HTTPS certificates come from Cloudflare
- **Tailscale**: a private network (VPN) between your own devices
    - why: SSH, Portainer and admin pages stay private, but reachable from anywhere

| Use | Way |
|---|---|
| public site or API (e.g. analytics, media) | Cloudflare Tunnel |
| admin pages, SSH, anything only you use | Tailscale |

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<domain>` | your domain on Cloudflare | `example.net` |
| `<server-ip>` | the server's fixed LAN address | `192.168.x.x` |
| `<port>` | a service's port on the server | `8090` |

## What was tried first, and why it failed

1. **port forwarding** on the router, plus a free dynamic DNS name (no-ip), so the changing home IP has a name
2. **nginx proxy manager** as reverse proxy, with a **Let's Encrypt** certificate for HTTPS
3. the certificate request failed, and port checkers (e.g. canyouseeme.org) couldn't reach the forwarded port
4. cause: **CGNAT** (carrier-grade NAT): the provider shares one public IP between many customers, so the router has no public address of its own and nothing from outside reaches it, whatever the port forwarding says

**Check if you're behind CGNAT**: compare the WAN/internet IPv4 address on the router's status page with the address shown by a site like whatismyipaddress.com. Different, or the router's starts with `100.64`–`100.127`: CGNAT, use the tunnel.

## Set them up

- private access: [Tailscale](integrations/tailscale.md), with [stacks/tailscale](../stacks/tailscale/README.md)
- public access: [Cloudflare Tunnel](integrations/cloudflare-tunnel.md), with [stacks/cloudflared](../stacks/cloudflared/README.md)

## Changes
- 2026-10-19 — setup steps moved to `integrations/tailscale.md` and `integrations/cloudflare-tunnel.md`
- 2026-10-19 — first version, rewritten from the private notes: what the tunnel and Tailscale are and why, the port forwarding / no-ip / nginx proxy manager attempt and CGNAT, Tailscale and tunnel setup
