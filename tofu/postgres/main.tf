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

# -----------------------------------------------------------------------------------------
#   app users: full use of their own database, without owning it
# -----------------------------------------------------------------------------------------
# The objects keep their owner (e.g. the admin, who created them); the app user gets every
# right it needs to use them, also on objects the owner creates later. Limit: it can't ALTER or
# DROP objects it doesn't own; schema changes on those are done as their owner.

locals {
  app_users = { for name, u in var.users : name => u if u.database != null }

  # one entry per app user and schema, e.g. "karel/public"
  app_schemas = merge([
    for name, u in local.app_users : {
      for s in u.schemas : "${name}/${s}" => { user = name, database = u.database, schema = s }
    }
  ]...)

  # what the app user may do, per kind of object
  object_privileges = {
    table    = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES", "TRIGGER"]
    sequence = ["USAGE", "SELECT", "UPDATE"]
    function = ["EXECUTE"]
  }

  # one entry per app user, schema and kind of object, e.g. "karel/public/table"
  app_objects = merge([
    for key, s in local.app_schemas : {
      for kind, privileges in local.object_privileges : "${key}/${kind}" => merge(s, { kind = kind, privileges = privileges })
    }
  ]...)
}

# connect to its database
resource "postgresql_grant" "database" {
  for_each = local.app_users

  role        = postgresql_role.user[each.key].name
  database    = each.value.database
  object_type = "database"
  privileges  = ["CONNECT", "TEMPORARY"]
}

# use its schemas and create new tables there
resource "postgresql_grant" "schema" {
  for_each = local.app_schemas

  role        = postgresql_role.user[each.value.user].name
  database    = each.value.database
  schema      = each.value.schema
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

# the tables, sequences and functions that exist now
resource "postgresql_grant" "objects" {
  for_each = local.app_objects

  role        = postgresql_role.user[each.value.user].name
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.kind
  privileges  = each.value.privileges

  depends_on = [postgresql_grant.schema]
}

# and the ones the admin creates later (e.g. a table added by hand in pgAdmin)
resource "postgresql_default_privileges" "objects" {
  for_each = local.app_objects

  role        = postgresql_role.user[each.value.user].name
  database    = each.value.database
  schema      = each.value.schema
  owner       = var.admin_username
  object_type = each.value.kind
  privileges  = each.value.privileges
}
