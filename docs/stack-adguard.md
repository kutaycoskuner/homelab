# Stack · AdGuard

**Optional.** Runs the home network's DNS on the server, so ads and trackers are blocked for every device without installing anything on them. Needs [02 · Docker and Portainer](02-docker-portainer.md).

## What it is and why we use it

- **DNS**: turns names (`example.net`) into addresses; every device asks a DNS server first
- **AdGuard Home**: a DNS server that answers "nothing here" for ad and tracker domains
    - why: blocking for phones, TVs and guests too, one place to see what the network looks up
    - in Docker: started and updated like every other stack; earlier it ran as Pi-hole and then on the host, see [First setup, before Docker](legacy/first-setup-without-docker.md)

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<server-ip>` | the server's fixed LAN address | `192.168.x.x` |
| `<data-dir>` | AdGuard's data folder on the server | `/home/<user>/docker/adguard` |

## Set it up

1. **port 53 must be free**: `sudo lsof -i :53` prints nothing
    - something listed: an old Pi-hole or AdGuard on the host, remove it as in [First setup, before Docker](legacy/first-setup-without-docker.md) step 8
2. **deploy** [stacks/adguard](../stacks/adguard/README.md) with `ADGUARD_DATA_DIR` set to `<data-dir>`
3. **first-time setup**: open `http://<server-ip>:3000`, keep the suggested ports, create the admin user
    - afterwards the web UI is on `http://<server-ip>`
4. **router**
    - give the server a fixed address (DHCP reservation), see [01](01-headless-server-setup.md#give-the-server-a-fixed-address)
    - set `<server-ip>` as the DNS server the router hands out (DHCP / DNS settings); optionally a public one (`1.1.1.1`) as second, so the internet still works if the server is down (that second one bypasses blocking)
    - reconnect a device (or wait for its DHCP renewal) to pick it up
5. **block lists**: web UI → **Filters → DNS blocklists → Add blocklist**: pick lists for your region/language besides the default one

## When the server itself can't resolve names

Symptom: containers (or `apt`) fail with DNS errors after the router points to the server. The server then asks itself for DNS, which only works while AdGuard runs.

- give Docker fixed DNS servers: `sudo nano /etc/docker/daemon.json`
    ```json
    {
      "dns": ["1.1.1.1", "8.8.8.8"]
    }
    ```
- if the host itself still fails: check `cat /etc/resolv.conf`; if it lists only `<server-ip>`, set public servers
    ```bash
    sudo bash -c 'echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" > /etc/resolv.conf'
    ```
    - NetworkManager may write this file again later; then set the DNS servers in its connection settings instead
- restart Docker and check what containers get:
    ```bash
    sudo systemctl restart docker
    docker run --rm busybox cat /etc/resolv.conf
    ```

The AdGuard stack itself already sets `dns: 1.1.1.1, 8.8.8.8` for the same reason.

## Test it

- blocking: `dig doubleclick.net @<server-ip>` answers `0.0.0.0`, `::` or `NXDOMAIN`
- leaks: run the extended test on [dnsleaktest.com](https://www.dnsleaktest.com) or [ipleak.net](https://ipleak.net); only AdGuard's upstream DNS servers should show up
- web UI → **Dashboard**: queries from your devices appear

## With Tailscale

Tailscale can push its own DNS to the server, which would replace the setup above. Log the server in with `--accept-dns=false` (see [Tailscale](integrations/tailscale.md)).

## Changes
- 2026-10-19 — renamed from `04-dns-adguard.md`: optional stack, not a core setup step
- 2026-10-19 — first version, rewritten from the private notes: what and why, setup, router, block lists, the server's own DNS fix, tests, Tailscale
