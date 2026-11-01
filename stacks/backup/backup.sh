#!/bin/sh
# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# One backup run (see ../../docs/backup.md), started nightly by crond or by hand with
# `docker exec backup backup.sh`:
#   1. create the restic repository in the bucket, on the very first run only
#   2. dump all PostgreSQL databases into one SQL file (a dump is consistent; the raw files
#      of a running database are not)
#   3. upload /backup (the dump and the read-only mounts) with restic: encrypted, only changed parts
#   4. remove old backups: KEEP_DAILY / KEEP_WEEKLY / KEEP_MONTHLY (default 7 / 4 / 6)
# On any failure: a message to DISCORD_WEBHOOK_URL naming the step; success stays silent.
# Requires: the variables in .env.example; the postgres stack on its network; a database user
# that can read everything (e.g. one with pg_read_all_data from tofu/postgres, not the admin).

set -eu

# crond starts jobs without the container's variables; start.sh saved them here
[ -f /etc/backup.env ] && . /etc/backup.env

DUMP_DIR=/backup/postgres
HOST_NAME=homelab   # fixed, so old backups are found again after the container is recreated

log() { echo "backup: $(date '+%Y-%m-%d %H:%M:%S') $*"; }

notify_failure() {
    [ -n "${DISCORD_WEBHOOK_URL:-}" ] || return 0
    curl -fsS -H 'Content-Type: application/json' \
        -d "{\"content\": \"Backup failed at step: $1 (exit $2). Details: docker logs backup\"}" \
        "$DISCORD_WEBHOOK_URL" > /dev/null || log "could not reach Discord either"
}

step="starting"
finish() {
    rc=$?
    rm -rf "$DUMP_DIR"
    if [ "$rc" -ne 0 ]; then
        log "FAILED at: $step (exit $rc)"
        notify_failure "$step" "$rc"
    fi
}
trap finish EXIT

log "started"

# 1. repository (once)
step="opening the repository"
if ! restic cat config > /dev/null 2>&1; then
    log "no repository in the bucket yet: creating it"
    restic init
fi

# 2. database dump
step="dumping the databases"
mkdir -p "$DUMP_DIR"
# --no-role-passwords: works with a read-only user (no admin needed); the dump has the users but
# not their password hashes, which tofu/postgres sets again after a restore
PGPASSWORD="$POSTGRES_PASSWORD" pg_dumpall --no-role-passwords -h "${POSTGRES_HOST:-postgres-core}" -U "$POSTGRES_USER" \
    > "$DUMP_DIR/postgres-all.sql"
log "database dump: $(du -h "$DUMP_DIR/postgres-all.sql" | cut -f1)"

# 3. upload
step="uploading the backup"
restic backup --host "$HOST_NAME" --tag nightly /backup

# 4. retention
step="removing old backups"
restic forget --host "$HOST_NAME" --tag nightly --prune \
    --keep-daily "${KEEP_DAILY:-7}" --keep-weekly "${KEEP_WEEKLY:-4}" --keep-monthly "${KEEP_MONTHLY:-6}"

step="done"
log "done"
