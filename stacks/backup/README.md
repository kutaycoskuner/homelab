# backup

Every night: dumps all PostgreSQL databases and uploads them, together with Portainer's data, the media files and AdGuard's settings, to an S3 bucket, encrypted by restic. A Discord message if a run fails; success stays silent. What, why, and how to restore: [Backup](../../docs/backup.md).

- image: built on the server from this folder (`alpine` + `restic` + PostgreSQL 17 client + `curl`), because Portainer CE can't mount files from a Git stack
- the bucket: [tofu/aws](../../tofu/aws/README.md)
- reads, read-only: Postgres over `db_network`, the volume `portainer_data`, the folders `MEDIA_DIR` and `ADGUARD_CONF_DIR`
- variables ([.env.example](.env.example)): the bucket and its login, the **restic password**, the Postgres admin login, the folders, the Discord webhook, the schedule
- needs the postgres stack (its network `db_network`) and Portainer's volume to exist

## Start

- **Portainer / OpenTofu**: stack from the repository, path `stacks/backup/docker-compose.yml`, the variables, and re-pull images **off** (`pull_image = false`): the image is built, not downloaded
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d --build` here
- **run one now**: `docker exec backup backup.sh`
