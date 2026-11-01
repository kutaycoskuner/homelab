# Prometheus with this repo's config and alert rules baked in (Portainer CE can't mount files from a
# Git stack); start.sh turns PROBE_TARGETS into a target file first. busybox variant: start.sh needs a shell.
FROM prom/prometheus:v3.15.1-busybox
COPY prometheus.yml alert-rules.yml /etc/prometheus/
COPY --chmod=755 start.sh /start.sh
ENTRYPOINT ["/start.sh"]
CMD ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus", "--storage.tsdb.retention.time=15d"]
