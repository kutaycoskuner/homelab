# 02 · Docker and Portainer

Installs the container runtime every service in this repo runs on, and a web UI to manage it. Needs a server set up as in [01 · Headless server setup](01-headless-server-setup.md).

## What they are and why we use them

- **Docker** runs each service in its own container: an isolated package of the app and everything it needs.
    - why: services don't conflict with each other or the OS, are removed cleanly, and are rebuilt from a compose file in this repo
- **Docker Compose** describes one or more containers (image, ports, volumes, settings) in a `docker-compose.yml`.
    - why: the setup is a file in git instead of a command typed once and forgotten
- **Portainer** is a web UI for Docker: containers, logs, volumes and stacks (Portainer's name for a compose project).
    - optional: everything in this repo also runs with `docker compose` over SSH
    - why we use it anyway: it shows what's running at a glance, and makes logs, checks and redeploys a click away in the browser

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-ip>` | the server's fixed LAN address | `192.168.x.x` |

## Install Docker

```bash
# 1. Install Docker Engine and the Compose plugin with Docker's script
curl -fsSL https://get.docker.com | sh

# 2. Allow your user to run docker without sudo, then log out and back in
sudo usermod -aG docker $USER

# 3. Check
docker version
docker compose version
docker run hello-world
```

> **Example: Raspberry Pi**
> - the same script works on Raspberry Pi OS (`arm64`)

## Install Portainer

Portainer is started with Compose from [stacks/portainer/](../stacks/portainer/), not as a Portainer stack: it can't update the container it runs in.

```bash
# 1. Get this repo on the server
git clone git@github.com:<owner>/homelab.git
cd homelab/stacks/portainer

# 2. Start it
docker compose up -d
```

Then open `https://<server-ip>:9443` and **create the admin user right away**: Portainer stops the first-time setup if no admin is created within a few minutes (fix: `docker restart portainer`).

Already running Portainer from a `docker run` command? See [stacks/portainer/README.md](../stacks/portainer/README.md#switching-from-docker-run).

## Test with a first container

In Portainer: **Containers → Add container**

- name: `nginx-test`, image: `nginx:alpine`
- port mapping: host `8080` → container `80`
- **Deploy**, then open `http://<server-ip>:8080`; remove the container afterwards

## Deploy a stack from this repo

1. **Stacks → Add stack**, name it after the folder (e.g. `adguard`)
2. paste the folder's `docker-compose.yml` into the web editor
3. under **Environment variables**, add each key from the folder's `.env.example` with your own value
4. **Deploy the stack**

## Deploy from the Git repository

Portainer clones the repo itself, so updates are one click and nothing has to be copied to the server.

1. **Stacks → Add stack → Repository**
    - repository URL: `https://github.com/<owner>/homelab`
    - reference: `refs/heads/main`
    - compose path: `stacks/<service>/docker-compose.yml` (or `scripts/<script>/docker-compose.yml`)
2. **Environment variables**: each key from the folder's `.env.example` with your own value
3. **Deploy the stack**; later updates: the stack → **Pull and redeploy**, or automatically after a merge, see [Updates](updates.md)

### Private repo access

A private repo needs a read-only GitHub token under **Authentication**: see [GitHub read-only token](integrations/github-read-token.md).

## Check after a reboot

Containers come back on their own when their compose file sets `restart: always` or `unless-stopped`. Check once:

```bash
sudo reboot
# after reconnecting
docker ps
```

## Changes
- 2026-10-28 — link to automatic updates (Renovate + Portainer)
- 2026-10-19 — private repo token steps moved to `integrations/github-read-token.md`
- 2026-10-19 — added deploying from the Git repository, with GitHub token access for a private repo
- 2026-10-19 — Portainer marked as optional (convenience UI, not required)
- 2026-10-19 — first version, from the private server notes: what Docker, Compose and Portainer are and why, Docker install, Portainer via Compose, test container, deploying stacks, reboot check
