# Backup

How the server's data that git can't rebuild is copied off the server every night, encrypted, and how to get it back. The stack: [stacks/backup](../stacks/backup/README.md); the storage: [tofu/aws](../tofu/aws/README.md).

## What it is and why we use it

- **why**: everything in git (compose files, tofu code, docs) can be rebuilt; database contents, Portainer's data and your files can't. A dead SD card or disk would lose them
- **restic**: a backup tool that encrypts on the server before uploading, stores only parts that changed since the last run, and keeps many versions cheaply
- **S3 bucket** (AWS): the copy lives outside your home; never public, versioned, so even a deleted backup stays recoverable for 30 days ([tofu/aws](../tofu/aws/README.md))
- **the restic password** is the key: without it, nobody can read the backups, including you; it lives in your password manager

## What is backed up

| Data | Why | How |
|---|---|---|
| all PostgreSQL databases (e.g. your apps' databases, umami) | can't be rebuilt | `pg_dumpall` into one SQL file: consistent, unlike the raw files of a running database |
| `portainer_data` | stacks created in Portainer's UI, registry logins, users | the volume, read-only |
| media folder (`MEDIA_DIR`) | your files, served as web addresses | the folder, read-only |
| AdGuard `conf/` (`ADGUARD_CONF_DIR`) | filters, clients, settings | the folder, read-only; `work/` (query logs, downloaded lists) is left out |

Not backed up, on purpose:

- anything in git: rebuilt by OpenTofu and Portainer
- container images: downloaded or built again
- Tailscale's state: a new login is enough
- monitoring data (Prometheus, Alertmanager): 15 days of check results, worthless after a rebuild
- tofu state and secrets on your PC: a separate step (password manager; a later backup from the PC)

## The pipeline

```text
every night (BACKUP_SCHEDULE, default 03:00):
crond ──> backup.sh
            1. restic cat config     repository in the bucket? (first run: restic init)
            2. pg_dumpall            postgres-core ──db_network──> /backup/postgres/postgres-all.sql
            3. restic backup /backup the dump + /backup/portainer + /backup/media + /backup/adguard-conf
                                     ──encrypted, only changed parts──> S3 bucket
            4. restic forget --prune keep 7 daily, 4 weekly, 6 monthly; delete the rest
            any step fails ──> Discord: "Backup failed at step: <step>"
            success ──> silent; the dump file is deleted either way
```

| File | Does |
|---|---|
| [docker-compose.yml](../stacks/backup/docker-compose.yml) | the container, its variables, the read-only mounts, `db_network` |
| [Dockerfile](../stacks/backup/Dockerfile) | `alpine` + `restic` + PostgreSQL 17 client + `curl` + `tzdata`, scripts copied in |
| [start.sh](../stacks/backup/start.sh) | puts `backup.sh` on the schedule and runs crond |
| [backup.sh](../stacks/backup/backup.sh) | the 4 steps and the failure message |

## Set it up

1. **bucket**: [tofu/aws](../tofu/aws/README.md) applied; its outputs give the region, bucket and login
2. **restic password**: create a long random one in your password manager **before** the first run
3. **values**: the stack's variables ([.env.example](../stacks/backup/.env.example)), e.g. in `tofu/portainer`'s `stack_env`
    - `RESTIC_REPOSITORY`: `s3:s3.<region>.amazonaws.com/<bucket-name>`
    - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: from `tofu output` in `tofu/aws`
    - `POSTGRES_USER`, `POSTGRES_PASSWORD`: the postgres stack's admin
    - `POSTGRES_NETWORK`: the postgres stack's network, `db_network` when deployed from `stacks/postgres`; a stack started under another name has `<stack>_db_network` (check: `docker inspect postgres-core --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'`)
4. **deploy** with re-pull images off (`pull_image = false`): the image is built on the server
5. **first run by hand**, on the server: `docker exec backup backup.sh`; expect "no repository in the bucket yet: creating it", then "done"
6. **restore test** (below), once: a backup you've never restored is a hope, not a backup

## Daily use

All on the server, over SSH; `docker exec backup` runs a command inside the backup container, which has the bucket's address, login and password.

```bash
# the run's log, e.g. last night's
docker logs --tail 30 backup

# run one now
docker exec backup backup.sh

# list the backups (snapshots)
docker exec backup restic snapshots

# what's in the latest one
docker exec backup restic ls latest
```

## Restore

1. **into a folder inside the container** (nothing on the server is overwritten):
    ```bash
    docker exec backup restic restore latest --target /tmp/restore
    ```
2. **copy it out to the server**:
    ```bash
    docker cp backup:/tmp/restore ./restore
    ```
    the files are under `./restore/backup/` (`postgres/postgres-all.sql`, `portainer/`, `media/`, `adguard-conf/`)
3. **databases**: load the dump into a running postgres (into an empty server, e.g. after a rebuild; on a running one it fails for objects that already exist):
    ```bash
    docker exec -i postgres-core psql -U <postgres-user> -d postgres < ./restore/backup/postgres/postgres-all.sql
    ```
4. **files**: copy back what you need, e.g. the media folder to `MEDIA_DIR`; Portainer's data into its volume while Portainer is stopped
5. **clean up**: `docker exec backup rm -rf /tmp/restore` and the local `./restore`

An older backup instead of the latest: take its ID from `restic snapshots` in place of `latest`.

## When something doesn't work

| Symptom | Look at |
|---|---|
| deploy fails: "network … declared as external, but could not be found" | `POSTGRES_NETWORK` doesn't match the postgres stack's network (check command in Set it up) |
| "Backup failed at step: dumping the databases" | postgres down, a wrong `POSTGRES_NETWORK`, or a wrong `POSTGRES_USER` / `POSTGRES_PASSWORD` |
| "… opening the repository" / "… uploading" | the bucket's login or `RESTIC_REPOSITORY` (region, bucket name); `docker logs backup` shows AWS's answer |
| "wrong password or no key found" | `RESTIC_PASSWORD` differs from the one the repository was created with |
| no message, but no backups either | the schedule: `docker logs backup` shows "backups run at …" on start; time zone `TZ` |

## Changes
- 2026-10-30 — first version: what is backed up and why, pipeline, setup, daily use, restore, troubleshooting
