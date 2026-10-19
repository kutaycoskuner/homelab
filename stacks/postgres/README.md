# postgres

One shared PostgreSQL server for own apps (e.g. analytics, a web app), with pgAdmin as web UI. Usage, pgAdmin and per-app databases: [Stack · PostgreSQL](../../docs/stack-postgres.md).

- images: `postgres:17` (`postgres-core`), `dpage/pgadmin4` (`pgadmin-core`)
- ports: `5432` (database), `5050` (pgAdmin)
- data: volume from `POSTGRES_VOLUME_NAME` (database), `pgadmin_data` (pgAdmin settings)
- network: `db_network`, which app stacks join
- secrets: logins in `.env` / Portainer variables, see [.env.example](.env.example)

## Start

- **Portainer**: stack from the repository, every key from `.env.example` under Environment variables
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d` here

## Switching from an existing stack without losing data

1. find the database volume: `docker volume ls | grep postgres` (e.g. `postgres-stack_postgres_data`)
2. set that name as `POSTGRES_VOLUME_NAME`; user, password and database stay what they were (they're only applied to an empty volume)
3. remove the old stack (Portainer → Stacks → old stack → **Delete**; volumes are kept unless you tick them)
4. deploy this stack, then check the data: `docker exec -it postgres-core psql -U <user> -d <db> -c '\l'`
5. stacks that used the old network (e.g. umami): redeploy them on `db_network`

pgAdmin starts without saved servers once (its data had no volume before); register the server again as in the docs.
