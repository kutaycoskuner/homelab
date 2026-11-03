# Grafana with this repo's data source and dashboards baked in (Portainer CE can't mount files from a
# Git stack). The dashboards live outside /var/lib/grafana, so the data volume never hides a newer copy.
FROM grafana/grafana-oss:13.0.2@sha256:5dad0df181cb644a14e13617b913b261a54f7d4fd4510721dba420929f35bea2
COPY provisioning /etc/grafana/provisioning
COPY dashboards /etc/grafana/dashboards
