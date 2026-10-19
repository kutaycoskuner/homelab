# Documentation

Index of the docs for this repo. Start with the repo's [README](../README.md) for what it is and the first setup.

- Conventions
    - [Secrets and example files](secrets-and-examples.md): how passwords, keys and personal data stay out of git
        - [What counts as confidential](secrets-and-examples.md#what-counts-as-confidential)
        - [The `.example` convention](secrets-and-examples.md#the-example-convention)
        - [Placeholders](secrets-and-examples.md#placeholders)
        - [Syncing your copies](secrets-and-examples.md#syncing-your-copies)
        - [Before every commit](secrets-and-examples.md#before-every-commit)
- Setup guides
    - [01 · Headless server setup](01-headless-server-setup.md): OS install and network access without a screen, Raspberry Pi as the example
        - [Placeholders](01-headless-server-setup.md#placeholders-used-on-this-page)
        - [Requirements](01-headless-server-setup.md#requirements)
        - [Install the operating system](01-headless-server-setup.md#install-the-operating-system)
        - [Find the server on the network](01-headless-server-setup.md#find-the-server-on-the-network)
        - [First login](01-headless-server-setup.md#first-login)
        - [Give the server a fixed address](01-headless-server-setup.md#give-the-server-a-fixed-address)
        - [Optional: remote desktop over VNC](01-headless-server-setup.md#optional-remote-desktop-over-vnc)
        - [Daily use](01-headless-server-setup.md#daily-use)
        - [Git access from the server](01-headless-server-setup.md#git-access-from-the-server)
- Setup guides (planned)
    - Docker and Portainer
    - Exposing services: port forwarding, CGNAT and Cloudflare Tunnel
    - DNS with AdGuard
    - Troubleshooting

## Changes
- 2026-10-19 — setup guide renamed to Headless server setup (hardware-agnostic, Pi as the example)
- 2026-10-19 — added the Raspberry Pi headless setup guide
- 2026-10-19 — first version: index with the secrets convention and the planned setup guides
