#!/bin/sh
# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Start script of the backup image (see ../../docs/backup.md): schedules backup.sh with crond
# at BACKUP_SCHEDULE and keeps crond in the foreground as the container's main process.
# crond starts its jobs with an almost empty environment, so the container's variables are
# saved to a file (readable only inside the container) that backup.sh reads first.
# Requires: BACKUP_SCHEDULE in cron format; the other variables, see .env.example.

set -eu

: "${BACKUP_SCHEDULE:=0 3 * * *}"
ENV_FILE=/etc/backup.env

umask 077
export -p > "$ENV_FILE"

# the job's output goes to the container's log (docker logs backup)
echo "$BACKUP_SCHEDULE /usr/local/bin/backup.sh > /proc/1/fd/1 2>&1" > /etc/crontabs/root

echo "start.sh: backups run at '$BACKUP_SCHEDULE' (${TZ:-UTC}); run one now with: docker exec backup backup.sh"
exec crond -f -l 6
