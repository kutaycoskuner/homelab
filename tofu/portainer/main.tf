# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-28
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Portainer stacks deployed from this repo, as code (see README.md). Run with OpenTofu (tofu).
# Each entry in var.stacks becomes a Git stack with automatic updates: Portainer polls the
# branch and redeploys when the stack's files change. Portainer itself is not managed here.

terraform {
  required_version = ">= 1.11" # write-only and ephemeral values (the GitHub token never reaches the state)
  required_providers {
    portainer = {
      source  = "portainer/portainer"
      version = "~> 1.35"
    }
  }
}

provider "portainer" {
  endpoint        = var.portainer_url
  api_key         = var.portainer_api_key
  skip_ssl_verify = var.portainer_skip_ssl_verify
}

resource "portainer_stack" "stack" {
  for_each = var.stacks

  name            = each.key
  deployment_type = "standalone"
  method          = "repository"
  endpoint_id     = var.endpoint_id

  repository_url                = var.repository_url
  repository_reference_name     = var.repository_branch
  file_path_in_repository       = each.value.path
  git_repository_authentication = true
  repository_username           = var.github_username
  repository_password_wo        = var.github_token         # write-only: not stored in the state
  repository_wo_version         = var.github_token_version # raise by one after changing the token, so it's sent again

  update_interval = var.update_interval   # automatic updates: poll the branch at this interval
  pull_image      = each.value.pull_image # re-pull images on redeploy; false for stacks built on the server (their image is on no registry)

  # Portainer 2.45 reports some running Git stacks with a status the provider reads as "not active";
  # without this, every apply would "start" them again, which redeploys and can take them down
  lifecycle {
    ignore_changes = [active]
  }

  # the stack's variables (the keys of its .env.example); values are stored in the state
  dynamic "env" {
    for_each = lookup(var.stack_env, each.key, {})
    content {
      name  = env.key
      value = env.value
    }
  }
}
