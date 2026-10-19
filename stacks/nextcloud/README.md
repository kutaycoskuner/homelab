# nextcloud

Private cloud storage: files, calendar, contacts and office documents on your own server. Setup and use: [Stack · Nextcloud](../../docs/stack-nextcloud.md).

- images: `nextcloud:31` (`nextcloud_app`), `postgres:15` (`nextcloud_db`, its own database)
- port: `8080`
- data: volumes from `NEXTCLOUD_DATA_VOLUME_NAME` (app and files) and `NEXTCLOUD_DB_VOLUME_NAME` (database)
- secrets: database password, see [.env.example](.env.example); the admin account is created in the browser

## Start

- **Portainer**: stack from the repository, every key from `.env.example` under Environment variables
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d` here

## Switching from an existing stack without losing data

1. find both volumes: `docker volume ls | grep nextcloud` (e.g. `nextcloud-stack_db_data`, `nextcloud-stack_nextcloud_data`)
2. set them as `NEXTCLOUD_DB_VOLUME_NAME` / `NEXTCLOUD_DATA_VOLUME_NAME`, and the old database password as `NEXTCLOUD_DB_PASSWORD`
3. check the running version (Nextcloud → Administration → Overview); the image tag must be that major version (e.g. `31`), never lower
4. delete the old stack without ticking its volumes, then deploy this one
