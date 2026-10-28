# Cloudflare Tunnel

Publishes chosen services on the server under your own domain, e.g. `https://analytics.<domain>`, without opening router ports.

## What it is and why we use it

- **Cloudflare Tunnel**: a connector on the server (`cloudflared`) keeps an outgoing connection to Cloudflare; Cloudflare sends requests for your subdomains through it
    - why: works behind CGNAT, no open ports, HTTPS certificates handled by Cloudflare, free
    - when: things meant to be public; private things go through [Tailscale](tailscale.md)
- background on why port forwarding didn't work here: [03 · Exposing services](../03-exposing-services.md)

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<domain>` | your domain on Cloudflare | `example.net` |
| `<server-ip>` | the server's fixed LAN address | `192.168.x.x` |
| `<port>` | the service's port on the server | `3001` |

## Set up

1. **a domain on Cloudflare**: buy one there (Domains → Register) or move an existing one to Cloudflare's name servers
2. **create the tunnel**: Cloudflare dashboard → **Networking → Tunnels → Create a tunnel**
    - type: **Cloudflared**
    - name: what it serves, e.g. `homelab`
3. **copy the token**: on the install page choose **Docker**; the shown command ends with `--token <long value>`, copy only that value
    - it's a secret: paste it straight into Portainer or `.env` as `CLOUDFLARE_TUNNEL_TOKEN`, never into a file in the repo, a note or a chat
4. **run the connector**: deploy [stacks/cloudflared](../../stacks/cloudflared/README.md); back in the dashboard the tunnel turns **Healthy**

## Publish a service

This server manages routes with Terraform, see [Manage routes as code](#manage-routes-as-code). By hand in the dashboard: tunnel → **Published application routes → Add a published application route**, one per service:

- subdomain: e.g. `analytics`
- domain: `<domain>`
- path: empty
- service type: `HTTP`, URL: `<server-ip>:<port>`

Then open `https://analytics.<domain>`; Cloudflare adds HTTPS by itself.

> **Example: this server**
> - `media.<domain>` → static media files on port `8090`
> - `analytics.<domain>` → self-hosted analytics on port `3001`, used by a website

## Manage routes as code

Instead of adding routes in the dashboard, list them in [tofu/cloudflare](../../tofu/cloudflare/README.md) and run `tofu apply` (OpenTofu); it also creates the DNS records. Once used, Terraform owns the route list: routes added in the dashboard are removed at the next apply. Background: [Terraform and OpenTofu](../terraform.md).

- first run, step by step (API token, values, init, plan, taking over existing records, apply): [tofu/cloudflare → First run](../../tofu/cloudflare/README.md#first-run)
- a subdomain that doesn't work (DNS error, 1033, 502): [tofu/cloudflare → When a subdomain doesn't work](../../tofu/cloudflare/README.md#when-a-subdomain-doesnt-work)

## Keep the token safe

- anyone with it can run your tunnel and serve content under your domain
- leaked or pasted somewhere: tunnel → **Refresh token** in the dashboard, then update `CLOUDFLARE_TUNNEL_TOKEN` and redeploy
- the dashboard links contain your account ID: don't copy them into docs

## Changes
- 2026-10-28 — routes managed from tofu/cloudflare with OpenTofu
- 2026-10-19 — routes on this server are managed with Terraform; links to its first run and troubleshooting
- 2026-10-19 — menu path corrected to Networking → Tunnels
- 2026-10-19 — added managing routes as code with Terraform
- 2026-10-19 — first version, rewritten from the private notes: what and why, domain, creating the tunnel, token handling, published routes with examples
