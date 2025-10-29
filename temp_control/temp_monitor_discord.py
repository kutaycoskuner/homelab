# py -m venv .venv
# .\.venv\scripts\activate
# pip install requests

import time
import requests
import subprocess

WEBHOOK_URL = "https://discord.com/api/webhooks/842859571054772225/shpU0uxDFUqWxZAT6w5zpsu69dLLb15PpxJJM4Ps4MkxTOGPmjxBzzXCeQHT7uTLT7Yz"  # paste your webhook URL here
INTERVAL_SECONDS = 3600  # 1 hour

def get_cpu_temperature():
    # Get temperature using vcgencmd
    output = subprocess.run(["vcgencmd", "measure_temp"], capture_output=True, text=True)
    if output.returncode != 0:
        return None
    temp_str = output.stdout.strip().replace("temp=", "").replace("'C", "")
    try:
        return float(temp_str)
    except ValueError:
        return None

def send_to_discord(message):
    data = {"content": message}
    try:
        response = requests.post(WEBHOOK_URL, json=data)
        if response.status_code != 204:
            print(f"Failed to send: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error sending to Discord: {e}")

while True:
    temp = get_cpu_temperature()
    if temp is None:
        send_to_discord("⚠️ Could not read CPU temperature.")
    else:
        if temp > 70:
            send_to_discord(f"🔥 WARNING! CPU temperature is {temp:.1f}°C")
        else:
            send_to_discord(f"🌡️ Current CPU temperature: {temp:.1f}°C")
    
    time.sleep(INTERVAL_SECONDS)

