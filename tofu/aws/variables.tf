# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Inputs for main.tf. Values go in terraform.tfvars (gitignored); see terraform.tfvars.example.
# No secrets here: tofu signs in through an AWS CLI profile.

variable "region" {
  description = "AWS region for the bucket, e.g. eu-central-1 (Frankfurt)"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile tofu signs in with (e.g. the one from `aws login --profile <name>`); null uses the default credentials"
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Name of the backup bucket; unique across all of AWS, lowercase letters, digits and hyphens, e.g. <you>-homelab-backup"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Use 3-63 lowercase letters, digits and hyphens, starting and ending with a letter or digit."
  }
}

variable "backup_user_name" {
  description = "Name of the IAM user the server backs up with"
  type        = string
  default     = "homelab-backup"
}

variable "keep_old_versions_days" {
  description = "Days a deleted or overwritten file stays recoverable in the bucket"
  type        = number
  default     = 30
}

variable "budget_limit_usd" {
  description = "Monthly cost limit in USD the alerts refer to (not a hard stop)"
  type        = number
  default     = 5
}

variable "budget_email" {
  description = "Email address for the budget alerts"
  type        = string
}
