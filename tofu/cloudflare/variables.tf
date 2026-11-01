# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-19
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Inputs for main.tf. Values go in terraform.tfvars (gitignored); see terraform.tfvars.example.

variable "cloudflare_api_token" {
  description = "API token with Account > Cloudflare Tunnel: Edit and Zone > DNS: Edit (secret)"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Zone ID of the domain"
  type        = string
}

variable "tunnel_id" {
  description = "ID of the existing tunnel the routes belong to"
  type        = string
}

variable "domain" {
  description = "Domain on Cloudflare, e.g. example.net"
  type        = string
}

variable "server_ip" {
  description = "LAN address of the server the services run on"
  type        = string
}

variable "routes" {
  description = "Every published route: subdomain -> port on the server. Routes missing here are removed on apply."
  type = list(object({
    subdomain = string
    port      = number
  }))

  validation {
    condition     = length(var.routes) == length(distinct([for r in var.routes : r.subdomain]))
    error_message = "Each subdomain may appear only once in routes."
  }
}
