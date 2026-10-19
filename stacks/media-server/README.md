# media-server

Serves the files of one folder on the server as web URLs, e.g. images for a website. No database and no upload page: you put files into the folder, they're online. Folder setup, copying files and publishing: [Stack · Media server](../../docs/stack-media-server.md).

- image: `nginx:alpine`
- port: `8090`; files at `http://<server-ip>:8090/images/<path>`
- data: the folder `MEDIA_DIR` on the server (see [.env.example](.env.example)), mounted read-only
- secrets: none

## Start

- create the folder first, see the docs
- **Portainer**: stack from the repository, `MEDIA_DIR` under Environment variables
- **CLI**: `python main.py --sync` in the repo root creates `.env`; then `docker compose up -d` here

Files added or changed in the folder are served right away; no restart needed.
