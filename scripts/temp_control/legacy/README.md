# legacy

Superseded code, kept for reference only. Nothing here is run, imported or maintained.

| File | What it was | Superseded | Replaced by | Not carried over |
|---|---|---|---|---|
| `temp_monitor_discord.py` | first version of the temperature monitor (tmux era): reads `vcgencmd`, posts to Discord every hour | 2025-10-29, `e0de9b4` | [`../temp_control.py`](../temp_control.py) | hourly report (now daily); warning message above 70 °C (now only the shutdown alert above 78 °C) |

## Changes
- 2026-10-19 — added `temp_monitor_discord.py`; its hardcoded webhook URL was replaced by reading `DISCORD_WEBHOOK_URL` from the environment before the move, nothing else changed
