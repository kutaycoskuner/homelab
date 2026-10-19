# 01 · Headless server setup

How the server's operating system is installed and reached over the network without a screen or keyboard ("headless"). The steps work for any small Linux machine: a mini PC, an old laptop, a virtual machine or a single-board computer. Each step ends with how it was done on this repo's server, a Raspberry Pi. Every later guide assumes this is done.

## Placeholders used on this page

Replace these with your own values. They never go into the repo (see [Secrets and example files](secrets-and-examples.md)).

| Placeholder | Meaning | Example |
|---|---|---|
| `<hostname>` | name the server gets on the network | `server` (reachable as `server.local`) |
| `<user>` | your user on the server | `admin` |
| `<server-ip>` | the server's fixed LAN address | `192.168.x.x` |
| `<wifi-ssid>`, `<wifi-password>` | your Wi-Fi network, if not on Ethernet | |
| `<your-email>` | e-mail used for the GitHub SSH key | `you@example.net` |

## Requirements

- a 64-bit machine that runs a Debian-based Linux (Debian, Ubuntu Server, Raspberry Pi OS)
- enough storage for the OS and the containers' data (32 GB or more)
- an Ethernet cable for the first boot (Wi-Fi works too, but a cable makes the first connection easier to debug)
- check the CPU type, it decides which container images can run
    - `x86_64` / `amd64`: most PCs and laptops
    - `aarch64` / `arm64`: Raspberry Pi and other ARM boards; a stack needs an image published for `arm64`
    - on a running Linux machine: `uname -m`

> **Example: Raspberry Pi**
> - a Raspberry Pi with a 64-bit CPU, official power supply, microSD card
> - a case that leaves the card slot reachable, so the card can be taken out without opening it

## Install the operating system

1. Download a server image of your distribution (e.g. [Debian](https://www.debian.org/distrib/) or [Ubuntu Server](https://ubuntu.com/download/server)) and write it to a USB stick or the boot disk.
2. During installation (or in the image's pre-configuration) set:
    - host name: `<hostname>`
    - user name and password: `<user>` and a strong password
    - network: Ethernet, or `<wifi-ssid>` and `<wifi-password>`
    - locale: time zone and keyboard layout
    - **SSH server**: enabled, so the machine can be reached without a screen
    - no desktop environment, unless you want remote desktop (see below)
3. Boot the machine with Ethernet and power connected.

> **Example: Raspberry Pi**
> 1. Install [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on the PC and insert the microSD card.
> 2. Choose the device, then **Raspberry Pi OS (64-bit)** (Debian based), then the card.
> 3. Before writing, open **Edit settings** (OS customisation): host name, user and password, Wi-Fi with country, locale, and **Services → Enable SSH** with password authentication. Tick "hidden SSID" only if the network really is hidden.
> 4. Write the image, put the card in the Pi, connect Ethernet and power.
>
> Older guides create an empty `ssh` file and a `wpa_supplicant.conf` on the boot partition by hand. The Imager settings do both, and since Raspberry Pi OS Bookworm Wi-Fi is managed by NetworkManager, so a `wpa_supplicant.conf` there is ignored.

## Find the server on the network

Give it a minute to boot, then from the PC:

```powershell
# by name (mDNS)
ping <hostname>.local

# or list devices the PC has seen, and look for the server's address
arp -a
```

The router's device list (usually at the gateway address shown by `ipconfig`) also shows the server with its address.

## First login

```bash
# 1. Connect from the PC (password is not echoed while typing)
ssh <user>@<hostname>.local

# 2. Update the system
sudo apt update && sudo apt upgrade -y

# 3. Change the password, if you used a temporary one during setup
passwd
```

## Give the server a fixed address

Services on the server (and DNS later) are reached by its address, so it must not change.

- in the router's admin page, find the server in the list of network devices
- reserve its current address for it (often called "always assign this IPv4 address" or a DHCP reservation)
- from now on use `<server-ip>` or `<hostname>.local`

## Optional: remote desktop over VNC

Only if a desktop environment is installed; a headless server doesn't need one.

- enable a VNC server on the machine, then connect from the PC with a VNC viewer such as [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) to `<server-ip>` with `<user>` and its password

> **Example: Raspberry Pi** (Raspberry Pi OS with desktop)
> - `sudo raspi-config` → **Interface Options** → **VNC** → enable

## Daily use

```bash
# copy a file or folder from the PC to the server (run on the PC; -r for folders, paths are case sensitive)
scp -r "<local-folder>" <user>@<server-ip>:/home/<user>/

# copy from the server to the PC
scp <user>@<server-ip>:/home/<user>/<file> "<local-folder>"

# CPU temperature (install once with: sudo apt install lm-sensors)
sensors

# reboot / shut down
sudo reboot
sudo shutdown -h now
```

Reboot once after the setup is complete to check everything comes back on its own, as it would after a power cut.

> **Example: Raspberry Pi**
> - temperature without extra packages: `vcgencmd measure_temp`

## Git access from the server

Use an SSH key instead of a personal access token, so no token is ever written down.

```bash
# 1. Create a key (press Enter for the default location, set a passphrase)
ssh-keygen -t ed25519 -C "<your-email>"

# 2. Load it into the agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. Show the public key and add it on GitHub: Settings → SSH and GPG keys → New SSH key
cat ~/.ssh/id_ed25519.pub

# 4. Test, then clone with the SSH URL
ssh -T git@github.com
git clone git@github.com:<owner>/<repo>.git
```

## Changes
- 2026-10-19 — made hardware-agnostic: steps for any Debian-based machine, Raspberry Pi as the worked example per step, CPU type note, `sensors` for temperature; taken over from `01-pi-headless-setup.md` (renamed)
- 2026-10-19 — first version, rewritten from the private setup notes: OS install, finding the server, first login, fixed address, VNC, daily commands, Git over SSH
