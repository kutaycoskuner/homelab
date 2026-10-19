# Stack · PostgreSQL

**Optional.** One shared database server for your own apps, managed in the browser with pgAdmin.

## What it is and why we use it

- **PostgreSQL**: a database server; apps keep their data in it
    - why one shared server: one place to back up and update; each app gets its own database and user
    - not shared: apps that bring their own database version (e.g. Nextcloud with PostgreSQL 15) keep theirs, so an update of one can't break the other
- **pgAdmin**: a web UI for PostgreSQL: browse tables, run queries, manage users

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-ip>` | the server's LAN or Tailscale address | `192.168.x.x` |
| `<user>`, `<db>` | `POSTGRES_USER`, `POSTGRES_DB` from `.env` | `appuser`, `appdb` |
| `<app>` | an app that gets its own database | `umami` |

## Set it up

1. deploy [stacks/postgres](../stacks/postgres/README.md) with the keys from its `.env.example`
2. open pgAdmin at `http://<server-ip>:5050`, log in with `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD`
3. **register the server** (right-click **Servers → Register → Server**)
    - name: `postgres-core`
    - connection → host: `postgres-core` (the container name; pgAdmin reaches it inside `db_network`), port `5432`
    - username / password: `POSTGRES_USER` / `POSTGRES_PASSWORD`, tick **Save password**

## One database and user per app

In pgAdmin (**Query Tool** on the server) or with `psql`:

```sql
CREATE USER <app>_user WITH PASSWORD '<app-password>';
CREATE DATABASE <app>db OWNER <app>_user;
```

- the app's stack then connects to host `postgres-core`, database `<app>db`, user `<app>_user`, and joins the external network `db_network`
- the password goes into that app's `.env` / Portainer variables, never into its compose file

## psql basics

```bash
docker exec -it postgres-core psql -U <user> -d <db>    # open a SQL prompt
```

| Command | Does |
|---|---|
| `\conninfo` | which database and user you're on |
| `\l` | list databases |
| `\c <db>` | switch database |
| `\dt` | list tables; `\d <table>` shows one |
| `\q` | quit |

## Keep it private

- port `5432` is reachable on the home network and through [Tailscale](integrations/tailscale.md), e.g. a desktop client on `<server-ip>:5432`
- never add it to the Cloudflare Tunnel: databases aren't meant to face the internet
- `POSTGRES_USER` / `POSTGRES_PASSWORD` only apply to an empty data volume; change a password later with `ALTER USER <user> WITH PASSWORD '...';`

## Changes
- 2026-10-19 — first version, rewritten from the private notes: what and why, setup, pgAdmin server registration via `db_network`, per-app database and user, psql basics, keeping it private
