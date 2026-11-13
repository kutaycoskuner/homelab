# The backup image: restic (encrypted, deduplicated backups), the PostgreSQL 17 client (pg_dumpall,
# same major version as the postgres stack), curl (Discord) and tzdata (the schedule's time zone);
# the scripts are copied in because Portainer CE can't mount files from a Git stack.
FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
RUN apk add --no-cache restic postgresql17-client curl tzdata
COPY --chmod=755 backup.sh start.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/start.sh"]
