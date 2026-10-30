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
| [tofu/aws](../tofu/aws/README.md) | OpenTofu | **new**: S3 bucket for offsite backups, the server's backup login, a budget alarm |
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

OpenTofu only reads the `.tf` files of the folder it runs in; in any other folder it stops with **"No configuration files"** (nothing is changed). Two ways:

```powershell
# from the repo root: -chdir tells tofu which folder to use (relative to the current folder;
# check with Get-Location, or give the full path: -chdir=C:\...\homelab	ofu\portainer)
tofu -chdir=tofu/portainer plan
tofu -chdir=tofu/portainer apply

# PowerShell splits an argument that starts with - and contains a dot (e.g. -chdir=../other-repo/...):
# tofu then reports 'no command named "../..."'; quote the whole argument
tofu '-chdir=../my-homelab/tofu/portainer' plan

# or change into the folder first
cd tofu\portainer
tofu plan
tofu apply
```

The CI check for these folders is turned off for now ([CI](ci.md)).

## Your own values in a private repo

Running a folder here with its `terraform.tfvars` works, but then your setup (which stacks, your domain) exists only in gitignored files on one PC. To keep it in git without making this repo personal, use the folders here as **modules** from a private repo of your own. The owner's server runs this way, from a private repo `homelab-private`; that's what keeps this repo free of personal values.

```text
GitHub/
├── homelab/tofu/portainer/        this repo: how stacks are deployed
└── my-homelab/tofu/portainer/     your private repo: which stacks, your values
    ├── main.tf                    module "portainer" { source = "../../../homelab/tofu/portainer" ... }
    ├── variables.tf               only the secrets
    └── secrets.auto.tfvars        secret values, gitignored (loaded automatically)
```

- **module**: any folder of `.tf` files can be called by another folder like a function; its variables become the module's inputs
- **why**: the logic stays in one place (here), your private repo only says what to deploy; values that aren't secret are committed there, secrets and state stay local and gitignored
- **source**: `../../../homelab/...` needs both repos cloned side by side; once this repo is public, a pinned address works without a clone: `git::https://github.com/<owner>/homelab.git//tofu/portainer?ref=<tag>`
- **moving existing state**: copy `terraform.tfstate` into the private folder and add a `moved` block per resource, e.g. `moved { from = portainer_stack.stack  to = module.portainer.portainer_stack.stack }`; `plan` then shows "has moved" and recreates nothing
- **moving your values**: copy the private folder's `.example` files, then fill them from your old `terraform.tfvars` with [copy_tfvars_values](../scripts/copy_tfvars_values/README.md), which never shows a value

## Changes
- 2026-10-30 — tofu/aws: bucket for offsite backups, the server's backup login, budget alarm
- 2026-10-29 — PowerShell: quote -chdir when the path contains a dot; copy_tfvars_values for moving values
- 2026-10-28 — using the tofu folders as modules from a private repo, with your values there
- 2026-10-28 — running tofu from the repo root with -chdir; the "No configuration files" error explained
- 2026-10-28 — OpenTofu added: tofu/ folders in use (cloudflare copied, portainer new), terraform/ kept as reference; install, commands with tofu; CI check off
- 2026-10-19 — daily use as a table of the four commands; link to the cloudflare first run
- 2026-10-19 — first version: what Terraform is and why, running it on the PC, install, secrets and state, daily use
