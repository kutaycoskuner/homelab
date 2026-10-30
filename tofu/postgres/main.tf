# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# PostgreSQL users (roles) as code (see README.md). Run with OpenTofu (tofu) on your PC; it
# connects to the database server with the admin login. Each entry in var.users becomes a user
# with a strong password generated here, plus optional built-in roles (e.g. read-only access).

terraform {
  required_version = ">= 1.6"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.27"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

# logs in as the admin: the one login that is set by hand (the server's first start)
provider "postgresql" {
  host     = var.host
  port     = var.port
  username = var.admin_username
  password = var.admin_password
  sslmode  = var.sslmode
}

# one strong password per user; stored in the state, shown with `tofu output`
resource "random_password" "user" {
  for_each = var.users

  length  = 40
  special = false # letters and digits only: safe in connection strings and .env files
}

resource "postgresql_role" "user" {
  for_each = var.users

  name     = each.key
  login    = true
  password = random_password.user[each.key].result
  roles    = each.value.roles # built-in roles granted to it, e.g. pg_read_all_data
}
