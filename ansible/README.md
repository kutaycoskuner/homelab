# ansible

The server itself as code: base packages and data folders, Docker, Portainer and the server's own DNS servers. A fresh server needs only its operating system, SSH key login and one playbook run; then OpenTofu ([tofu/](../tofu/)) sets up what runs on it.

**Status:** written 2026-11-28, not run yet. Until it has been tested on a real server, [scripts/server_base](../scripts/server_base/README.md) stays the way to install and update Docker and Portainer.

## Which layer

| Layer | Tool |
|---|---|
| the server: packages, Docker, Portainer, folders, DNS | **Ansible** (this folder) |
| what runs in Portainer, routes, databases and users, outside accounts | OpenTofu ([tofu/](../tofu/), [Databases](../docs/databases.md)) |

## Files

| File | Holds |
|---|---|
| `site.yml` | the playbook: servers in the group `servers` get the roles below |
| `roles/base` | base packages (`base_packages`), time zone (`base_timezone`), data folders (`srv_dirs`) |
| `roles/docker` | Docker's apt repository, the Docker packages, the service, users in the `docker` group |
| `roles/portainer` | copies [stacks/portainer/docker-compose.yml](../stacks/portainer/docker-compose.yml) to `/opt/portainer` and starts it; data stays in the `portainer_data` volume |
| `roles/dns` | fixed DNS servers in the NetworkManager connection (as `server_base --dns`) |
| `requirements.yml` | the collections the roles use |
| `inventory.example.yml` | one server, with placeholders |

Your values (the server's address, folders, sudo password) don't go here: they live in your own configuration folder, e.g. a private repo's `ansible/` with `ansible.cfg`, `inventory.yml` (gitignored) and `group_vars/servers/` (`vars.yml`, and `vault.yml` encrypted with Ansible Vault).

## Run

Ansible doesn't run on Windows: use WSL (Ubuntu). The commands are typed into the WSL terminal, in your configuration folder.

```bash
pipx install ansible-core                                   # once; or: sudo apt install ansible-core
ansible-galaxy collection install -r ../../homelab/ansible/requirements.yml
export ANSIBLE_CONFIG=$PWD/ansible.cfg                       # see "Good to know"
ansible servers -m ping                                      # expected: pong
ansible-playbook ../../homelab/ansible/site.yml --check --diff   # shows what would change; changes nothing
ansible-playbook ../../homelab/ansible/site.yml              # makes the changes
ansible-playbook ../../homelab/ansible/site.yml -e server_update=true   # also updates Docker and Portainer
ansible-playbook ../../homelab/ansible/site.yml --tags dns   # one role only
```

## Good to know

- **SSH key in WSL**: WSL has its own `~/.ssh`, separate from Windows'; the key must be there (or copied there, `chmod 600`)
- **`ANSIBLE_CONFIG`**: Ansible ignores an `ansible.cfg` in a world-writable folder, and Windows folders under `/mnt/c` look world-writable from WSL; naming the file explicitly avoids that
- **a Portainer started with `docker run`** can't be taken over (its container name is in use); `server_base --install` replaces it with the compose stack first
- **the Docker role** removes `/etc/apt/sources.list.d/docker.list` (written by Docker's install script) and sets up the same repository in Docker's own format; both at once make apt fail
- **`server_update=true`** restarts Docker when its packages change: all containers stop for a moment and come back by their restart policy
- **not here yet**: firewall, SSH hardening, unattended upgrades; a mistake there can lock you out of the server, so each comes on its own, tested with a second SSH session open

## Changes
- 2026-11-28 — first version: roles base, docker, portainer, dns (what scripts/server_base does, plus data folders); not run yet
