#!/bin/sh
# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Start script of the monitoring stack's Alertmanager image (see ../../../docs/monitoring.md).
# Alertmanager can't read environment variables in its config, so this writes the Discord webhook
# (DISCORD_WEBHOOK_URL) into the file alertmanager.yml reads (webhook_url_file), readable only by
# this container's user, then starts Alertmanager with the image's arguments.
# Requires: DISCORD_WEBHOOK_URL set; a shell (the busybox-based image).

set -eu

WEBHOOK_FILE=/tmp/discord-webhook-url

: "${DISCORD_WEBHOOK_URL:?DISCORD_WEBHOOK_URL is empty: set the Discord webhook for alerts}"

umask 077
printf '%s' "$DISCORD_WEBHOOK_URL" > "$WEBHOOK_FILE"

exec /bin/alertmanager "$@"
