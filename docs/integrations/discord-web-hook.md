# Discord webhook

How scripts on the server send messages (reports, alerts) to a Discord channel.

## What it is and why we use it

- **Discord webhook**: a URL that posts a message to one channel when it receives an HTTP request; no bot or login needed
    - why: the simplest way to get server alerts on the phone
    - the URL contains its own token: anyone who has it can post to the channel, so it's a secret

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<webhook-url>` | the webhook's URL | `https://discord.com/api/webhooks/<id>/<token>` |

## Create a webhook

1. Discord: **Server Settings → Integrations → Webhooks → New Webhook**
2. set its name and the channel it posts to
3. **Copy Webhook URL**

## Use it

- store it only in the `.env` of the script or stack that uses it, never in code or committed files (see [Secrets and example files](../secrets-and-examples.md)):
    ```bash
    WEBHOOK_URL=<webhook-url>
    ```
- test it from any machine (Discord answers `204 No Content`):
    ```bash
    curl -H "Content-Type: application/json" -d '{"content":"test from the server"}' "<webhook-url>"
    ```
- messages are limited to 2000 characters

## Replace a leaked webhook

A webhook URL that was committed, pasted or logged counts as leaked, even after it's deleted from the repo.

1. **Server Settings → Integrations → Webhooks**, open the old webhook, **Delete Webhook**: the old URL stops working at once
2. create a new one as above
3. put the new URL in each `.env` that used the old one, and restart those containers

## Used by

- [temp_control](../../temp_control/): daily temperature report and shutdown alert

## Changes
- 2026-10-19 — first version: what a webhook is, creating, storing in `.env`, testing, replacing a leaked one
