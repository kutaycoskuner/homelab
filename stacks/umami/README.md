# umami

Self-hosted website analytics, as a privacy-friendly replacement for Google Analytics. Setup, tracking code and publishing: [Stack · Umami](../../docs/stack-umami.md).

- image: `ghcr.io/umami-software/umami:latest`
- port: `3001`
- data: in the postgres stack, database `UMAMI_DB_NAME`
- needs: [stacks/postgres](../postgres/README.md) running, with umami's database and user, and its `db_network`
- secrets: database password and app secret, see [.env.example](.env.example)

## Start

- **Portainer**: stack from the repository, every key from `.env.example` under Environment variables
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d` here

## Switching from an existing stack

The data lives in the postgres database, not in this container.

1. use the same database name, user and password as before (Portainer → old stack → Editor shows them in `DATABASE_URL`), and the same `APP_SECRET` to keep logins valid
2. delete the old umami stack
3. make sure the postgres stack is already on `db_network` ([switching postgres](../postgres/README.md#switching-from-an-existing-stack-without-losing-data))
4. deploy this stack; the dashboard shows the old websites and statistics
