# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-28
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Inputs for main.tf. Values go in terraform.tfvars (gitignored); see terraform.tfvars.example.

variable "portainer_url" {
  description = "Portainer address as seen from this PC, e.g. https://192.168.x.x:9443"
  type        = string
}

variable "portainer_api_key" {
  description = "Portainer access token (secret)"
  type        = string
  sensitive   = true
}

variable "portainer_skip_ssl_verify" {
  description = "Accept Portainer's self-signed certificate"
  type        = bool
  default     = true
}

variable "endpoint_id" {
  description = "ID of the Docker environment in Portainer (the number in its URL, usually 1)"
  type        = number
  default     = 1
}

variable "repository_url" {
  description = "This repo's HTTPS URL"
  type        = string
}

variable "repository_branch" {
  description = "Branch the stacks are deployed from"
  type        = string
  default     = "refs/heads/dev"
}

variable "github_username" {
  description = "GitHub user name for the repo login"
  type        = string
}

variable "github_token" {
  description = "GitHub read-only token for the repo (secret); write-only, never stored in the state"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "github_token_version" {
  description = "Raise by one whenever github_token changes, so OpenTofu sends the new token"
  type        = number
  default     = 1
}

variable "update_interval" {
  description = "How often Portainer checks the branch for changes, e.g. 5m"
  type        = string
  default     = "5m"
}

variable "stacks" {
  description = "Stacks to deploy: stack name -> path of its compose file in the repo"
  type = map(object({
    path = string
  }))
}

variable "stack_env" {
  description = "Per stack: variable name -> value (the keys of the stack's .env.example). Stored in the state."
  type        = map(map(string))
  sensitive   = true
  default     = {}
}
