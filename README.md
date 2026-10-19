<h1 align="center">
    homelab
</h1>

<p align="center">
    Infrastructure as code for a self-hosted Raspberry Pi server: Docker stacks, helper scripts and write-ups of the setup and the problems solved along the way.
</p>

<p align="center">
    <img alt="Last Update" src="https://img.shields.io/github/last-commit/kutaycoskuner/homelab" />
    <img alt="Stacks" src="https://github.com/kutaycoskuner/homelab/actions/workflows/stacks.yml/badge.svg" />
    <img alt="Secrets" src="https://github.com/kutaycoskuner/homelab/actions/workflows/secrets.yml/badge.svg" />
</p>

------------------------------------------------------------------------------------------

## What this repo does

- describes every service running on the Pi as a Docker Compose stack, so the server can be rebuilt from this repo
- holds small helper scripts that run next to the stacks (e.g. a CPU temperature guard)
- documents how the server was set up and why things are the way they are
- contains **no secrets and no personal data**: every confidential file is committed only as a `.example` copy with placeholder values (see [Secrets and example files](docs/secrets-and-examples.md))

------------------------------------------------------------------------------------------

## Folders

```text
homelab/
├── README.md              this file
├── docs/                  setup guides and write-ups, see docs/README.md
├── stacks/<service>/      docker-compose.yml + .env.example + README per service
│   └── portainer/         Docker web UI
├── scripts/               helper scripts
│   └── temp_control/      CPU temperature guard (Discord report, shutdown when too hot)
│
│   planned:
├── stacks/...             the other services
└── roadmap.md             services to add next
```

------------------------------------------------------------------------------------------

## Usage

Every file that holds a password, key, token, IP address or other personal value exists in the repo only as `<file>.example`. Before running anything, create your own copy and fill in your values:

```bash
# 1. Clone the repository
git clone https://github.com/kutaycoskuner/homelab.git
cd homelab

# 2. For each example file you need, copy it and fill in your own values
#   e.g. a stack's environment file:
cp stacks/<service>/.env.example stacks/<service>/.env
#   e.g. a script's config:
cp scripts/<script>/config.yaml.example scripts/<script>/config.yaml
```

Your copies (`.env`, `config.yaml`, ...) are gitignored and never committed. A sync script that creates and updates them from the examples is planned, see [Secrets and example files](docs/secrets-and-examples.md#syncing-your-copies).

------------------------------------------------------------------------------------------

## Documentation

- [docs/README.md](docs/README.md): index of all docs
    - [Secrets and example files](docs/secrets-and-examples.md): how confidential values are kept out of the repo
    - [CI](docs/ci.md): what GitHub Actions checks on every push
    - [01 · Headless server setup](docs/01-headless-server-setup.md): install the OS and reach the server over the network (Raspberry Pi as the example)
    - [02 · Docker and Portainer](docs/02-docker-portainer.md): container runtime and its web UI
    - [Discord webhook](docs/integrations/discord-web-hook.md): messages from scripts to a Discord channel
    - [GitHub read-only token](docs/integrations/github-read-token.md): lets Portainer clone the private repo
    - Scripts: [temp_control](scripts/temp_control/README.md)
