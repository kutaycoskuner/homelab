# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-11-02
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Inputs for main.tf: the two secrets and the sites to check.

variable "api_key" {
  description = "UptimeRobot Main API Key: My Settings > API Settings (secret)"
  type        = string
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "Discord webhook the alerts are posted to (secret; anyone with it can post)"
  type        = string
  sensitive   = true
}

variable "sites" {
  description = "Sites to check from outside: name shown in alerts -> public URL, e.g. { hello = \"https://hello.example.net\" }"
  type        = map(string)

  validation {
    condition     = alltrue([for url in values(var.sites) : can(regex("^https?://", url))])
    error_message = "Every site needs a full URL starting with https:// (or http://)."
  }
}

variable "interval" {
  description = "Seconds between checks; the free plan allows 300 (5 minutes) at the shortest"
  type        = number
  default     = 300
}
