#!/bin/sh
# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Start script of the monitoring stack's Prometheus image (see ../../../docs/monitoring.md).
# Prometheus can't read environment variables in its config, so this writes the URLs to check
# (PROBE_TARGETS, comma-separated) as a target file that prometheus.yml reads
# (file_sd_configs), then starts Prometheus with the image's arguments.
# Requires: PROBE_TARGETS set; a shell (the busybox image variant).

set -eu

TARGET_FILE=/tmp/probe-targets.json

: "${PROBE_TARGETS:?PROBE_TARGETS is empty: set the URLs to check, comma-separated}"

# [{"targets": ["https://a", "https://b"]}]
list=""
old_ifs=$IFS
IFS=','
for url in $PROBE_TARGETS; do
    url=$(printf '%s' "$url" | tr -d ' ')
    [ -n "$url" ] || continue
    list="${list:+$list, }\"$url\""
done
IFS=$old_ifs

printf '[{"targets": [%s]}]\n' "$list" > "$TARGET_FILE"
echo "start.sh: checking $(printf '%s' "$list" | tr -cd ',' | wc -c | awk '{print $1 + 1}') URL(s)"

exec /bin/prometheus "$@"
