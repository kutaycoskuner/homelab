# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-19
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Cloudflare Tunnel routes and their DNS records, as code (see README.md).
# Takes over an existing tunnel's routes: every route that should exist must be in var.routes,
# because apply replaces the whole route list (the dashboard's published application routes).

terraform {
  required_version = ">= 1.6"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  routes = { for r in var.routes : r.subdomain => r }
}

# the tunnel's routes: subdomain -> service on the server, then a catch-all for everything else
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = var.account_id
  tunnel_id  = var.tunnel_id

  config = {
    ingress = concat(
      [for r in var.routes : {
        hostname = "${r.subdomain}.${var.domain}"
        service  = "http://${var.server_ip}:${r.port}"
      }],
      [{ service = "http_status:404" }]
    )
  }
}

# one DNS record per route, pointing the subdomain at the tunnel
resource "cloudflare_dns_record" "route" {
  for_each = local.routes

  zone_id = var.zone_id
  name    = "${each.key}.${var.domain}"
  type    = "CNAME"
  content = "${var.tunnel_id}.cfargotunnel.com"
  proxied = true
  ttl     = 1 # automatic; required for proxied records
}
