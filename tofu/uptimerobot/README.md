# tofu/uptimerobot

The outside check as code: UptimeRobot opens the public sites from the internet every 5 minutes and posts to Discord when one is down, and again when it's back. It notices what monitoring on the server can't: the whole server off, frozen or offline, or the tunnel broken ([When the server itself is down](../../docs/monitoring.md#when-the-server-itself-is-down)). Run with **OpenTofu** (`tofu`), usually as a module from a folder that has the values. Background: [Terraform and OpenTofu](../../docs/terraform.md).

- manages: one Discord alert channel, one HTTP monitor per site
- doesn't manage: the UptimeRobot account and its API key, status pages
- cost: free plan, up to 50 monitors at 5-minute checks; Discord alerts included

## Files

```text
tofu/uptimerobot/
├── main.tf        the provider, the Discord channel, one monitor per entry in sites
├── variables.tf   which values main.tf needs; no values themselves
└── README.md      this file
```

## Use as a module

```hcl
module "uptimerobot" {
  source = "../../../homelab/tofu/uptimerobot"

  api_key             = var.uptimerobot_api_key
  discord_webhook_url = var.discord_webhook_url
  sites = {
    app = "https://app.<domain>"
    api = "https://api.<domain>"
  }
}
```

- the key in `sites` is the monitor's name in UptimeRobot and in the alerts
- leave out addresses whose front page isn't meant to answer, e.g. a route limited to a webhook path (answers 404 on purpose and would always count as down)
- certificate expiry isn't checked here; the server's own monitoring alerts on that

## Set it up

1. **account**: a free account at uptimerobot.com
2. **API key**: My Settings > API Settings > **Main API Key**; it goes into the calling folder's `secrets.auto.tfvars` as `uptimerobot_api_key`
3. **Discord webhook**: in the alerts channel, Edit Channel > Integrations > Webhooks > New Webhook, named UptimeRobot (one webhook per tool, so each can be replaced on its own); its URL goes in as `discord_webhook_url`
4. `init`, `plan` (one channel plus one monitor per site to add), `apply`
5. **test**: stop one site's container (e.g. `docker stop <container>`); within about 10 minutes Discord gets a DOWN message, and an UP message within 5 minutes after `docker start <container>`

## Things to know

- **provider version below 2.0**: a `2.0.0` was published briefly and withdrawn, but registries still list it; `main.tf` allows only `>= 1.11.0, < 2.0.0`
- **slow apply**: the free plan allows about 10 API requests per minute; with several monitors, `apply` waits and retries ("Still creating…" for minutes) — normal
- **"Error creating monitor … status 500"**: often a monitor with the same address already exists (e.g. made by hand in the dashboard); take it over instead of creating a second one, with an `import` block in the calling folder: `import { to = module.uptimerobot.uptimerobot_monitor.site["<key>"]  id = "<monitor id from the dashboard's address bar>" }`; the calling folder then also needs `uptimerobot/uptimerobot` in its own `required_providers`, or tofu looks for `hashicorp/uptimerobot`
- **"Provider produced inconsistent result after apply"**: UptimeRobot applied the change but answered with the old value; run `plan`: "No changes" means it's fine
- **detection time**: a check every 5 minutes, so an outage shows up after up to 5–10 minutes

## State

The API key and the webhook are stored in the state. Keep the state private, like the other tofu folders'. Run on its own, it stays local; the owner's setup keeps it in an S3 bucket ([State in S3](../../docs/terraform.md#state-in-s3)).
