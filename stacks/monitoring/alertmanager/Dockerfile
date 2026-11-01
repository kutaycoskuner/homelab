# Alertmanager with this repo's routing baked in (Portainer CE can't mount files from a Git stack);
# start.sh writes the Discord webhook from DISCORD_WEBHOOK_URL into a file first. The image is busybox-based.
FROM prom/alertmanager:v0.34.2
COPY alertmanager.yml /etc/alertmanager/alertmanager.yml
COPY --chmod=755 start.sh /start.sh
ENTRYPOINT ["/start.sh"]
CMD ["--config.file=/etc/alertmanager/alertmanager.yml", "--storage.path=/alertmanager"]
