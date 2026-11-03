# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-11-01
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Inputs for main.tf. The secret names and the values are separate, because OpenTofu can't
# loop over secret (sensitive) values.

variable "github_owner" {
  description = "GitHub user or organization that owns the repositories"
  type        = string
}

variable "github_token" {
  description = "Fine-grained GitHub token, only the repositories below, permission Secrets: Read and write (secret)"
  type        = string
  sensitive   = true
}

variable "actions_secrets" {
  description = "Secrets to set: key -> repository (name only, no owner) and secret name; the value is secret_values[key]"
  type = map(object({
    repository = string
    name       = string
  }))
}

variable "secret_values" {
  description = "Per key of actions_secrets: the secret's value (secret; stored in the state)"
  type        = map(string)
  sensitive   = true

  validation {
    condition     = alltrue([for v in values(var.secret_values) : v != ""])
    error_message = "A secret value is empty; check where it comes from (e.g. an output that was empty at apply time)."
  }
}
