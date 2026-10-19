# First setup, before Docker (legacy)

How the server ran its services directly on the operating system, before everything moved into containers. Kept as a record of that setup and of the migration; **not the current way**: see [01 · Headless server setup](../01-headless-server-setup.md) and [02 · Docker and Portainer](../02-docker-portainer.md).

## What it was and why it changed

- every service ran as a process on the host
    - Python scripts in a virtual environment, kept alive with **tmux** (a terminal that keeps running after SSH disconnects)
    - a Node.js bot under **pm2** (a process manager for Node.js)
    - DNS ad blocking (**Pi-hole**, then **AdGuard Home**) and **Tailscale** installed as system services
- why it changed: processes started by hand didn't come back after a reboot, settings were spread over the system, and removing a service left files behind; containers fix all three

## Placeholders used on this page

| Placeholder | Meaning |
|---|---|
| `<user>` | your user on the server |
| `<server-ip>` | the server's fixed LAN address, e.g. `192.168.x.x` |
| `<session>` | a tmux session name, e.g. `monitor_temperature` |
| `<repo>` | a Git repository of yours |

## Steps

1. **Install the OS and log in over SSH**
    - as in [01 · Headless server setup](../01-headless-server-setup.md)

2. **Run a Python script** (here: the temperature monitor)
    ```bash
    # copy the script to the server (from the PC), or write it there with: nano <script>.py
    scp temp_monitor_discord.py <user>@<server-ip>:/home/<user>/Desktop/_scripts/
    cd ~/Desktop/_scripts

    # virtual environment and dependencies
    python -m venv .venv
    source .venv/bin/activate
    pip install requests

    python temp_monitor_discord.py
    ```
    - problem: the script stops as soon as the SSH window closes

3. **Keep it running with tmux**
    ```bash
    sudo apt install tmux
    tmux new -s <session>             # new session
    cd ~/Desktop/_scripts && source .venv/bin/activate && python temp_monitor_discord.py
    # detach (script keeps running): Ctrl+B, then D

    tmux ls                           # list sessions
    tmux attach -t <session>          # back into a session
    tmux kill-session -t <session>    # stop it
    ```
    - still a problem: after a reboot every session has to be started again by hand

4. **Run a Node.js bot with pm2**
    ```bash
    # Node.js 24 and pnpm
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo corepack enable
    sudo corepack prepare pnpm@latest --activate

    # pm2 keeps the bot running and restarts it on crashes
    sudo npm install -g pm2
    git clone git@github.com:<owner>/<repo>.git && cd <repo>
    pnpm install
    pm2 start pnpm --name "<bot-name>" -- start
    ```

5. **Network-wide ad blocking with Pi-hole**
    ```bash
    curl -sSL https://install.pi-hole.net | bash   # installer asks for interface, upstream DNS, block lists
    sudo pihole setpassword                        # admin page: http://<server-ip>/admin
    ```
    - router: give the server a fixed address, and set `<server-ip>` as the network's DNS server (a public one such as `1.1.1.1` as second)
    - check from a client: `nslookup pi.hole`
    - later stopped in favour of AdGuard Home: `sudo systemctl stop pihole-FTL && sudo systemctl disable pihole-FTL`

6. **Switch to AdGuard Home** (installed on the host)
    ```bash
    curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
    sudo /opt/AdGuardHome/AdGuardHome -s start      # also: stop | restart | status | uninstall
    ```
    - first-time setup in the browser: `http://<server-ip>:3000`
    - router DNS as in step 5 (IPv4 and IPv6)
    - check that blocking works: `dig doubleclick.net @<server-ip>` answers `0.0.0.0`, `::` or `NXDOMAIN`

7. **Private remote access with Tailscale** (installed on the host)
    ```bash
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up          # opens a login link
    tailscale ip               # the server's Tailscale address (100.x.x.x)
    ```

8. **Move to Docker: remove the host installs**
    - Tailscale
        ```bash
        sudo systemctl stop tailscaled && sudo systemctl disable tailscaled
        sudo apt remove tailscale
        sudo rm -rf /var/lib/tailscale /etc/systemd/system/tailscaled.service
        which tailscale                 # must print nothing
        ```
    - AdGuard Home
        ```bash
        sudo systemctl stop AdGuardHome && sudo systemctl disable AdGuardHome
        sudo rm -rf /opt/AdGuardHome /etc/AdGuardHome /var/lib/AdGuardHome
        sudo rm -f /etc/systemd/system/AdGuardHome.service
        sudo systemctl daemon-reload
        sudo lsof -i :53                # DNS port must be free for the container
        ```
    - scripts and bot: stop their tmux sessions and pm2 processes, then run them as containers
    - continue with [02 · Docker and Portainer](../02-docker-portainer.md)

## Changes
- 2026-10-19 — first version, rewritten from the private setup notes: scripts with venv and tmux, bot with pm2, Pi-hole, AdGuard Home and Tailscale on the host, removal before moving to Docker
