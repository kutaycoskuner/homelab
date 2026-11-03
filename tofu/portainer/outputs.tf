# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-11-01
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Values main.tf hands back after apply.
# webhook_urls: per stack with webhook = true, the URL that redeploys it (secret: anyone who
# has it can trigger a redeploy). Read with: tofu output -json webhook_urls

output "webhook_urls" {
  description = "Stack name -> its Portainer webhook URL, for stacks with webhook = true"
  value       = { for name, s in portainer_stack.stack : name => s.webhook_url if var.stacks[name].webhook }
  sensitive   = true
}
