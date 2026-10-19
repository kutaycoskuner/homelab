# temp_control

CPU temperature guard: posts a daily temperature report to Discord and shuts the machine down when the CPU gets too hot.

## What it is and why we use it

- a small Python loop that reads the CPU temperature once an hour
    - why: a fanless or badly ventilated server can overheat unnoticed; a clean shutdown beats a crash or damaged hardware
- **Discord webhook** for the messages, see [Discord webhook](../../docs/integrations/discord-web-hook.md)
    - why: the alert reaches the phone without running a bot

## Requirements

- any Linux machine; temperature from `vcgencmd` if present, otherwise `/sys/class/thermal/thermal_zone0/temp`
- Docker, or Python 3.11+ with a venv
- a Discord webhook URL

> **Example: Raspberry Pi**
> - `vcgencmd` is part of Raspberry Pi OS; the script runs as the container `script-temp_control`

## Settings

| What | Where | Value |
|---|---|---|
| webhook URL (secret) | `.env`: `DISCORD_WEBHOOK_URL` | see [.env.example](.env.example) |
| check interval | `CHECK_INTERVAL` in `temp_control.py` | 3600 s |
| shutdown above | `SHUTDOWN_THRESHOLD` in `temp_control.py` | 78 °C |
| report interval | `NORMAL_TEMP_REPORT_INTERVAL` in `temp_control.py` | 1 day |

## Run

- **Portainer** (recommended): Stacks → Add stack → **Repository**, compose path `scripts/temp_control/docker-compose.yml`, `DISCORD_WEBHOOK_URL` under Environment variables; see [Deploy from the Git repository](../../docs/02-docker-portainer.md#deploy-from-the-git-repository)
- **Docker Compose** on the server:
    ```bash
    cd scripts/temp_control
    cp .env.example .env          # then set DISCORD_WEBHOOK_URL
    docker compose up -d --build
    docker logs script-temp_control
    ```
- **Python** without Docker:
    ```bash
    cd scripts/temp_control
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    set -a; . ./.env; set +a      # load .env into the environment
    python temp_control.py
    ```

- the script stops with a message if `DISCORD_WEBHOOK_URL` is not set

## How it shuts down the host

- in a container: `nsenter -t 1 ... shutdown -h now`, i.e. `shutdown` run as the host's process 1
    - needs `pid: host` and `privileged: true` ([docker-compose.yml](docker-compose.yml))
    - trade-off: a privileged container has full access to the host; acceptable for own, reviewed code only
- without Docker: `sudo shutdown -h now` (the user needs sudo rights)
- if the shutdown fails, the error goes to Discord and the script keeps watching, instead of crashing into a restart loop

## Folders

```text
temp_control/
├── temp_control.py     the script
├── Dockerfile          image that runs it
├── docker-compose.yml  how it runs: env, restart, host access for the shutdown
├── requirements.txt
├── .env.example        copy to .env and fill in (.env is gitignored)
└── legacy/             superseded code, kept for reference only; see legacy/README.md
```
