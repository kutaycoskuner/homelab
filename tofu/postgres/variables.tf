# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Inputs for main.tf. Values go in terraform.tfvars (gitignored); see terraform.tfvars.example.

variable "host" {
  description = "Address of the PostgreSQL server as seen from this PC, e.g. 192.168.x.x or the Tailscale address"
  type        = string
}

variable "port" {
  description = "Port of the PostgreSQL server"
  type        = number
  default     = 5432
}

variable "admin_username" {
  description = "The server's admin user (POSTGRES_USER at its first start); tofu logs in with it"
  type        = string
}

variable "admin_password" {
  description = "The admin's password (secret)"
  type        = string
  sensitive   = true
}

variable "sslmode" {
  description = "TLS to the server: disable for a server reached only over the home network or Tailscale"
  type        = string
  default     = "disable"
}

variable "users" {
  description = "Users to create: name -> built-in roles to grant (e.g. [\"pg_read_all_data\"] for read-only access to every database); each gets a generated password"
  type = map(object({
    roles = optional(list(string), [])
  }))
  default = {}
}
