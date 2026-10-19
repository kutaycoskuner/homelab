# Stack · Nextcloud

**Optional.** Your own cloud storage: files, calendar, contacts and office documents, synced to your devices.

## What it is and why we use it

- **Nextcloud**: a self-hosted alternative to Google Drive / Dropbox, with apps for calendar, contacts, notes and more
    - why: files stay on your own hardware, no storage plan to pay for
    - with its own PostgreSQL 15, separate from the shared [PostgreSQL](stack-postgres.md) on purpose: Nextcloud's updates follow their own pace

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-ip>` | the server's LAN or Tailscale address | `192.168.x.x` |

## Set it up

1. deploy [stacks/nextcloud](../stacks/nextcloud/README.md) with the keys from its `.env.example`
2. open `http://<server-ip>:8080` and create the **admin account** (user and strong password; this is the Nextcloud login, not the database one)
3. install the recommended apps when asked (calendar, contacts, mail, office, notes, talk), or later under **Apps**
4. install the Nextcloud app on your phone / PC and log in with `http://<server-ip>:8080`

## Reach it from other addresses

Nextcloud only answers on addresses it trusts. Opening it through Tailscale (or a new address) shows "Access through untrusted domain". Add the address once:

```bash
docker exec -u www-data nextcloud_app php occ config:system:set trusted_domains 1 --value=<server-tailscale-ip>
```

Use the next number (`2`, `3` ...) for each further address.

## Updating

- Nextcloud can't skip major versions: from 31 go to 32, then 33, never 31 → 33
- change the image tag in `docker-compose.yml` by one major (e.g. `nextcloud:32`), redeploy, open the web UI and let the upgrade finish
- back up both volumes before a major update

## Changes
- 2026-10-19 — first version, rewritten from the private notes: what and why, own database, setup, trusted domains, major-by-major updates
