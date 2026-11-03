# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-11-01
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# GitHub Actions secrets as code (see README.md). Run with OpenTofu (tofu), usually as a module
# from another folder that knows the values, e.g. a Portainer webhook URL read from that
# folder's state, so the secret is never copied by hand.

terraform {
  required_version = ">= 1.6"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

# one secret per entry; the value is stored in the state (the provider has no write-only field for it)
resource "github_actions_secret" "secret" {
  for_each = var.actions_secrets

  repository  = each.value.repository
  secret_name = each.value.name
  value       = var.secret_values[each.key] # was plaintext_value, deprecated in provider 6.x
}
