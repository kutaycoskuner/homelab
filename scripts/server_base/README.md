# server_base

Installs, updates and checks the server's base software in one script: **Docker** and **Portainer**. Everything else (stacks, `tofu/portainer`, automatic updates) runs on top of these two.

## What it is and why we use it

- **Docker** runs the containers; **Portainer** is the web UI and the deployer for the Git stacks, and `tofu/portainer` works through Portainer's API, so both are needed
- why a script: neither can be managed from inside the stack system. Portainer can't update itself (it would stop its own container), `tofu/portainer` only manages the stacks inside Portainer, and Docker comes from the system's packages

| Part | Installed by `--install` | Updated by `--update` |
|---|---|---|
| Docker (engine, Compose plugin) | Docker's official script `get.docker.com`, then your user into the `docker` group | `apt` packages `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin`, `docker-buildx-plugin` |
| Portainer | [stacks/portainer/docker-compose.yml](../../stacks/portainer/docker-compose.yml); replaces an old `docker run` container (data kept) | pulls the image tag the compose file names; restarts only if it changed |

## Run

On the server (SSH), in the repo clone; code blocks are typed into the terminal.

```bash
# what's installed, versions, how Portainer was started; changes nothing
bash scripts/server_base/server_base.sh --status

# see what --install would do, then do it (asks before every change)
bash scripts/server_base/server_base.sh --install --dry-run
bash scripts/server_base/server_base.sh --install

# update: first get the newest compose file (e.g. a merged Renovate update), then update
git pull
bash scripts/server_base/server_base.sh --update
```

- `bash scripts/...`: runs the script with bash, so it doesn't need to be marked executable
- a bare run only prints the help; `--dry-run` alone is refused with a hint

## Good to know

- after being added to the `docker` group, log out and back in (or `newgrp docker`), then run `--install` again for the Portainer part
- updating Docker restarts the Docker service: all containers stop for a moment and come back by their restart policy
- first Portainer start: open `https://<server-ip>:9443` and create the admin user right away; Portainer stops the first-time setup after a few minutes
- nothing deletes data: Portainer's settings stay in the `portainer_data` volume, the stacks' data in their own volumes and folders
- Debian-based systems only (Raspberry Pi OS, Debian, Ubuntu): the update step uses `apt`
