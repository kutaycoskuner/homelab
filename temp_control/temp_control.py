# ----------------------------------------------------------------------------------------
#                notes
# ----------------------------------------------------------------------------------------
'''
Kutay Coskuner, 2025
This code is licensed under the MIT License. You can use, modify, and distribute it freely.
However, it is provided "as is," without any warranties or guarantees of any kind.
For details, visit: https://opensource.org/licenses/MIT

- description

- metadata

- use case

- install
    > py -m venv .venv
    > .\.venv\scripts\activate
    > pip install requests
    > (to get dependencies) pip freeze > requirements.txt
    > (on docker) pip install -r requirements.txt
    > docker build -t script-temp-control . 

- sources

- todo

'''
# ----------------------------------------------------------------------------------------
#                start
# ----------------------------------------------------------------------------------------
import time
import requests
import subprocess
import sys
from datetime import datetime, timedelta
from typing import Optional

WEBHOOK_URL: str = "https://discord.com/api/webhooks/842859571054772225/shpU0uxDFUqWxZAT6w5zpsu69dLLb15PpxJJM4Ps4MkxTOGPmjxBzzXCeQHT7uTLT7Yz"
CHECK_INTERVAL: int = 3600  # in seconds
SHUTDOWN_THRESHOLD: float = 78.0  # °C
NORMAL_TEMP_REPORT_INTERVAL: timedelta = timedelta(days=1)

last_normal_report_time: datetime = datetime.min

def get_cpu_temperature() -> Optional[float]:
    """Returns the CPU temperature as a float, or None if unavailable."""
    output: subprocess.CompletedProcess = subprocess.run(
        ["vcgencmd", "measure_temp"],
        capture_output=True,
        text=True
    )
    if output.returncode != 0:
        return None
    temp_str: str = output.stdout.strip().replace("temp=", "").replace("'C", "")
    try:
        return float(temp_str)
    except ValueError:
        return None

def send_to_discord(message: str) -> None:
    """Sends a message to the Discord webhook."""
    data: dict[str, str] = {"content": message}
    try:
        response: requests.Response = requests.post(WEBHOOK_URL, json=data)
        if response.status_code != 204:
            print(f"Failed to send: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error sending to Discord: {e}")

def shutdown_pi() -> None:
    """Sends a shutdown message and shuts down the Pi."""
    send_to_discord("⚠️ Shutting down due to high CPU temperature!")
    time.sleep(3)
    subprocess.run(["sudo", "shutdown", "-h", "now"])

def main() -> None:
    global last_normal_report_time
    while True:
        now: datetime = datetime.now()
        temp: Optional[float] = get_cpu_temperature()

        if temp is None:
            send_to_discord("⚠️ Could not read CPU temperature.")
        else:
            if temp > SHUTDOWN_THRESHOLD:
                send_to_discord(f"🔥 CRITICAL! CPU temperature is {temp:.1f}°C — shutting down!")
                shutdown_pi()
                sys.exit()
            elif now - last_normal_report_time >= NORMAL_TEMP_REPORT_INTERVAL:
                send_to_discord(f"🌡️ Daily Report: CPU temperature is {temp:.1f}°C")
                last_normal_report_time = now

        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
