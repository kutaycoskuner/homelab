# Terraform

How outside accounts (Cloudflare, later Tailscale and GitHub) are set up as code instead of by clicking in dashboards.

## What it is and why we use it

- **Terraform**: you describe how an account should look ("the tunnel has these routes"), Terraform compares that with the account and makes the changes through the provider's API
    - why: settings are in git like the stacks, every change is previewed (`plan`) before it happens, and a lost account setup can be rebuilt
    - each folder under [terraform/](../terraform/) is one account or service, e.g. [terraform/cloudflare](../terraform/cloudflare/README.md) (tunnel routes and DNS; its README has the first run step by step)

## Where it runs: your PC

Terraform talks to the providers' APIs over the internet; it doesn't need to run on the server. Run it on your PC, where you edit the repo:

- the state file (Terraform's record of what it manages) stays on that one machine
- the API tokens never have to be on the server

Running it on the server works too, but pick one place: two machines with two state files don't know about each other's changes.

## Install

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
| `terraform init` | downloads the providers (once per folder, again after a version change) | no |
| `terraform plan` | compares the files with the account and lists what would change | no |
| `terraform apply` | shows the plan and, after `yes`, makes the changes | yes |
| `terraform import <address> <id>` | takes over something that already exists in the account | no (only Terraform's state) |

```powershell
cd terraform\<folder>
terraform plan
terraform apply
```

CI checks formatting and validity of every folder on each push, without account access ([CI](ci.md)).

## Changes
- 2026-10-19 — daily use as a table of the four commands; link to the cloudflare first run
- 2026-10-19 — first version: what Terraform is and why, running it on the PC, install, secrets and state, daily use
