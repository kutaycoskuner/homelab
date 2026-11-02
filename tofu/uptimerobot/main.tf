# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-11-02
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Outside check as code: UptimeRobot opens the public sites from the internet every few
# minutes and posts to Discord when one is down. It catches what monitoring on the server
# can't: the whole server off, frozen or offline, or the tunnel broken (docs/monitoring.md,
# "When the server itself is down"). Run with OpenTofu (tofu), usually as a module from
# another folder that knows the sites and secrets.

terraform {
  required_version = ">= 1.6"
  required_providers {
    uptimerobot = {
      source = "uptimerobot/uptimerobot"
      # below 2.0: a 2.0.0 was published briefly and withdrawn, but registries still list it
      version = ">= 1.11.0, < 2.0.0"
    }
  }
}

provider "uptimerobot" {
  api_key = var.api_key
}

# where alerts go: a Discord channel, on down and on back up
resource "uptimerobot_integration" "discord" {
  name                     = "Discord"
  type                     = "discord"
  value                    = var.discord_webhook_url
  enable_notifications_for = 1 # 1 = down and up
  ssl_expiration_reminder  = false
}

# one check per site, from outside; certificate expiry is left to the server's own monitoring
resource "uptimerobot_monitor" "site" {
  for_each = var.sites

  name                = each.key
  type                = "HTTP"
  url                 = each.value
  interval            = var.interval
  timeout             = 30
  follow_redirections = true

  assigned_alert_contacts = [
    {
      alert_contact_id = uptimerobot_integration.discord.id
      threshold        = 0 # minutes after DOWN before the first message
      recurrence       = 0 # no repeats while it stays down
    },
  ]
}
