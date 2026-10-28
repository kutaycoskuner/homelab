# Terraform and OpenTofu

How outside accounts (Cloudflare, later Tailscale and GitHub) and Portainer's stacks are set up as code instead of by clicking in dashboards.

## What it is and why we use it

- **Terraform**: you describe how an account should look ("the tunnel has these routes"), Terraform compares that with the account and makes the changes through the provider's API
    - why: settings are in git like the stacks, every change is previewed (`plan`) before it happens, and a lost account setup can be rebuilt
    - each folder is one account or service, e.g. tunnel routes and DNS for Cloudflare; its README has the first run step by step
- **OpenTofu**: the open-source fork of Terraform (Linux Foundation, since 2023); same files and providers, command `tofu` instead of `terraform`
    - why: truly open source, and it supports write-only values (a token sent to a provider but never stored in the state)

## Which folder

| Folder | Tool | Status |
|---|---|---|
| [tofu/cloudflare](../tofu/cloudflare/README.md) | OpenTofu | **in use**: tunnel routes and DNS |
| [tofu/portainer](../tofu/portainer/README.md) | OpenTofu | **in use**: Portainer stacks and their automatic updates |
| [terraform/cloudflare](../terraform/cloudflare/README.md) | Terraform | reference only: same code as `tofu/cloudflare`; don't `apply` here |

Apply each account from **one** folder only: two folders with two state files would overwrite each other's changes.

## Where it runs: your PC

Terraform talks to the providers' APIs over the internet; it doesn't need to run on the server. Run it on your PC, where you edit the repo:

- the state file (Terraform's record of what it manages) stays on that one machine
- the API tokens never have to be on the server

Running it on the server works too, but pick one place: two machines with two state files don't know about each other's changes.

## Install

OpenTofu (used here):

```bash
# Windows (PowerShell)
winget install OpenTofu.Tofu

# macOS
brew install opentofu

# Debian / Ubuntu / Raspberry Pi OS: see https://opentofu.org/docs/intro/install/

# check (new terminal); 1.11 or newer
tofu -version
```

Terraform (only for the reference folder):

```bash
# Windows (PowerShell)
winget install Hashicorp.Terraform

# macOS
brew tap hashicorp/tap && brew install hashicorp/tap/terraform

# Debian / Ubuntu / Raspberry Pi OS: see https://developer.hashicorp.com/terraform/install#linux

# check (new terminal)
terraform -version
```

## Secrets and state

| File | Holds | In git |
|---|---|---|
| `*.tf` | what should exist | yes |
| `terraform.tfvars.example` | the variables with placeholders | yes |
| `terraform.tfvars` | your values: API tokens, account IDs | no (gitignored) |
| `.terraform.lock.hcl` | exact provider versions | yes |
| `terraform.tfstate`, `.terraform/` | state and downloaded providers | no (gitignored) |

- create `terraform.tfvars` by copying the example in the same folder (`main.py` only handles `.env` files)
- API tokens with only the permissions the folder needs; the README of each folder lists them

## Daily use

| Command | Does | Changes the account |
|---|---|---|
| `tofu init` | downloads the providers (once per folder, again after a version change) | no |
| `tofu plan` | compares the files with the account and lists what would change | no |
| `tofu apply` | shows the plan and, after `yes`, makes the changes | yes |
| `tofu import <address> <id>` | takes over something that already exists in the account | no (only the state) |

```powershell
cd tofu\<folder>
tofu plan
tofu apply
```

The CI check for these folders is turned off for now ([CI](ci.md)).

## Changes
- 2026-10-28 — OpenTofu added: tofu/ folders in use (cloudflare copied, portainer new), terraform/ kept as reference; install, commands with tofu; CI check off
- 2026-10-19 — daily use as a table of the four commands; link to the cloudflare first run
- 2026-10-19 — first version: what Terraform is and why, running it on the PC, install, secrets and state, daily use
