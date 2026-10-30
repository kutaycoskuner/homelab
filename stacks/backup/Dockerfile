# The backup image: restic (encrypted, deduplicated backups), the PostgreSQL 17 client (pg_dumpall,
# same major version as the postgres stack), curl (Discord) and tzdata (the schedule's time zone);
# the scripts are copied in because Portainer CE can't mount files from a Git stack.
FROM alpine:3.22@sha256:2e0b81d60597f449baa56dc25d355367869d2dca4cd57e866f1e2b52af3eb55f
RUN apk add --no-cache restic postgresql17-client curl tzdata
COPY --chmod=755 backup.sh start.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/start.sh"]
