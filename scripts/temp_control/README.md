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

```bash
# 1. Go to the script's folder and create your .env (then set DISCORD_WEBHOOK_URL in it)
cd scripts/temp_control
cp .env.example .env

# 2a. With Docker
docker build -t script-temp_control .
docker run -d --name script-temp_control --restart unless-stopped --env-file .env script-temp_control

# 2b. Or with Python
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
set -a; . ./.env; set +a      # load .env into the environment
python temp_control.py
```

- the script stops with a message if `DISCORD_WEBHOOK_URL` is not set
- shutting down the host from inside a container needs extra access (privileges or device mounts); not documented yet

## Folders

```text
temp_control/
├── temp_control.py     the script
├── Dockerfile          image that runs it
├── requirements.txt
├── .env.example        copy to .env and fill in (.env is gitignored)
└── legacy/             superseded code, kept for reference only; see legacy/README.md
```
