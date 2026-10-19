# Stack · Umami

**Optional.** Self-hosted analytics for your websites: visitors, pages, referrers, without cookies or a third party.

## What it is and why we use it

- **Umami**: a small analytics app; a script on your website reports page views to it
    - why: you own the data, no cookie banner needed, no Google Analytics
    - stores everything in the shared [PostgreSQL](stack-postgres.md) server

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-ip>` | the server's LAN or Tailscale address | `192.168.x.x` |
| `<domain>` | your domain on Cloudflare | `example.net` |
| `<website-id>` | the id Umami gives a website | `xxxxxxxx-xxxx-...` |

## Set it up

1. **database**: on the postgres stack, create a database and user for umami ([how](stack-postgres.md#one-database-and-user-per-app)), e.g. `umamidb` owned by `umami_user`
2. **deploy** [stacks/umami](../stacks/umami/README.md) with the keys from its `.env.example`
    - `UMAMI_APP_SECRET`: `openssl rand -hex 32`
3. **first login**: `http://<server-ip>:3001`, user `admin`, password `umami`; **change the password right away** (Settings → Profile)
4. **add your website**: Settings → Websites → **Add website** (name and domain)

## Make it public

The tracking script must be reachable by every visitor, so Umami goes through the [Cloudflare Tunnel](integrations/cloudflare-tunnel.md#publish-a-service):

- route: subdomain `analytics`, domain `<domain>`, service `HTTP` `<server-ip>:3001`
- check: `https://analytics.<domain>` shows the Umami login

## Add the tracking code to a website

- Umami → the website → **Edit → Tracking code**: copy the `<script>` tag
- put it into the `<head>` of every page, e.g.
    ```html
    <script defer src="https://analytics.<domain>/script.js" data-website-id="<website-id>"></script>
    ```
- frameworks: add it through the framework's head config instead of a page template
    > **Example: this server**
    > - a Nuxt site on GitHub Pages: pasting the tag into a page didn't report anything; adding it to the `head` scripts in the Nuxt config did

## Don't count your own visits

In your browser on the website: open the developer tools (F12) → **Console**:

```js
localStorage.setItem('umami.disabled', 1)
```

Repeat in each browser you use; remove it with `localStorage.removeItem('umami.disabled')`.

## Changes
- 2026-10-19 — first version, rewritten from the private notes: what and why, database, setup, first login, publishing through the tunnel, tracking code, own-visit opt-out
