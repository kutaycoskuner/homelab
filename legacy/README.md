# legacy

Code that a newer version replaced, kept for reference. Nothing here is run, deployed or checked by CI.

| Folder | Replaced by | What it was | Not carried over |
|---|---|---|---|
| [terraform/cloudflare](terraform/cloudflare/README.md) | [tofu/cloudflare](../tofu/cloudflare/README.md) (OpenTofu), run from a private repo as a module | Cloudflare Tunnel routes and DNS records with Terraform; the first infrastructure-as-code folder of this repo (2026-10-19) | nothing: `tofu/cloudflare` has the same resources; it was kept only as a Terraform example, and was never applied after the switch on 2026-10-28 |

## Changes
- 2026-11-01 — terraform/ moved here from the repo root; its local state and values deleted (they held old tokens)
