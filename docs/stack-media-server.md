# Stack · Media server

**Optional.** Serves files from a folder on the server as plain web addresses, e.g. the images of a website or blog, so they don't have to live in the website's repo.

## What it is and why we use it

- **a static file server**: nginx shows the files of one folder; `photo.jpg` in the folder becomes `https://media.<domain>/images/photo.jpg`
    - why: large media stays out of website repos and git history; a new image is online the moment it's copied over
- **no database**: the folder *is* the content
    - adding, renaming or deleting a file changes the site at once
    - backups = a copy of the folder
    - nothing to log in to: files are managed with `scp`/SSH, not a web page

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<user>` | your user on the server | `admin` |
| `<server-ip>` | the server's LAN or Tailscale address | `192.168.x.x` |
| `<media-dir>` | the folder that is served (`MEDIA_DIR`) | `/srv/media-server/data-images` |
| `<domain>` | your domain on Cloudflare | `example.net` |

## How the folder maps to URLs

```text
<media-dir>/                        → http://<server-ip>:8090/images/
├── test.txt                        → http://<server-ip>:8090/images/test.txt
├── 20260410-cover.gif              → http://<server-ip>:8090/images/20260410-cover.gif
└── blog/
    └── 20230203-first-post/
        └── header.jpg              → http://<server-ip>:8090/images/blog/20230203-first-post/header.jpg
```

- the URL is the file's path inside the folder; names are case sensitive
- use names without spaces (e.g. `YYYYMMDD-short-name.jpg`), so URLs need no escaping
- there's no folder listing: a URL that doesn't name a file shows nothing, so files can only be found by their exact address

## Set it up

1. **create the folder and give your user ownership** (on the server)
    ```bash
    sudo mkdir -p <media-dir>
    sudo chown -R <user>:<user> <media-dir>      # you copy files in without sudo
    sudo chmod 755 <media-dir>                    # owner writes; the web server can read and enter
    ```
2. **test file**
    ```bash
    echo "hello from the media server" > <media-dir>/test.txt
    ```
3. **deploy** [stacks/media-server](../stacks/media-server/README.md) with `MEDIA_DIR` set to `<media-dir>`
4. **check**
    ```bash
    curl http://localhost:8090/images/test.txt          # on the server
    ```
    and in a browser: `http://<server-ip>:8090/images/test.txt`

## Add files

From the PC (`-r` for folders):

```bash
# one file
scp "<local-file>" <user>@<server-ip>:<media-dir>/

# a whole folder, e.g. a blog post's images
scp -r "<local-folder>" <user>@<server-ip>:<media-dir>/blog/
```

Files copied from another system sometimes arrive unreadable for the web server (it then answers `403 Forbidden`). Fix the permissions:

```bash
find <media-dir> -type d -exec chmod 755 {} \;    # folders: enter and read
find <media-dir> -type f -exec chmod 644 {} \;    # files: read only for others
```

## Make it public

- [Cloudflare Tunnel](integrations/cloudflare-tunnel.md#publish-a-service) route: subdomain `media`, domain `<domain>`, service `HTTP` `<server-ip>:8090`
- check: `https://media.<domain>/images/test.txt`
- use in a website: `<img src="https://media.<domain>/images/blog/20230203-first-post/header.jpg" alt="...">`
- **everything in the folder is public** once published: no private photos, documents or anything with personal data; keep those in [Nextcloud](stack-nextcloud.md)

## Changes
- 2026-10-19 — first version, rewritten from the private notes: what and why (folder instead of database), folder-to-URL mapping, setup with ownership and permissions, copying files, 403 fix, publishing through the tunnel
