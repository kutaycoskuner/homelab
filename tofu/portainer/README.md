# tofu/portainer

Portainer's stacks as code: every stack deployed from this repo, its variables and its automatic updates are in `terraform.tfvars`; `tofu apply` sets them up in Portainer. Run with **OpenTofu** (`tofu`). Background: [Terraform and OpenTofu](../../docs/terraform.md), [Updates](../../docs/updates.md).

- manages: Git stacks (repo, branch, compose path), their variables, automatic updates (polling, re-pull image)
    - from this repo by default; a stack can come from another repo (`repository_url`, `branch` in `stacks`), e.g. an app that keeps its own compose file; the GitHub token then needs read access to that repo too
- doesn't manage: Portainer itself and Docker (installed and updated by [scripts/server_base](../../scripts/server_base/README.md), because Portainer can't redeploy itself) and the containers' data (volumes and folders stay as they are)
- secrets: Portainer token, GitHub token and the stacks' passwords in `terraform.tfvars` (gitignored)

## Files

```text
tofu/portainer/
├── main.tf                    one Portainer stack per entry in stacks, from the repo, with automatic updates
├── variables.tf               which values main.tf needs; no values themselves
├── terraform.tfvars.example   those values with placeholders: every stack and the keys of its .env.example
├── .terraform.lock.hcl        exact provider version (created by tofu init; commit it)
├── README.md                  this file
│
│   local only, gitignored:
├── terraform.tfvars           your values: tokens, stack list, passwords
├── terraform.tfstate          OpenTofu's record of the stacks, including their variables (keep it private)
└── .terraform/                the downloaded provider
```

## How it works

```text
terraform.tfvars ──tofu apply──> Portainer API: create / update the stack, set its variables, turn on polling
Portainer ──every update_interval──> the repo's branch ──changed?──> pull and redeploy that stack
```

- the GitHub token is **write-only**: sent to Portainer, never stored in the state
- **re-pull image** (`pull_image`, per stack, default on) downloads every image before a redeploy, so a new version is used; switch it **off** for stacks that build their image on the server (`build: .`, e.g. `hello`, `temp_control`): their image name is on no registry, and the download fails with "pull access denied … may require 'docker login'" (not a token problem); their compose files also set `pull_policy: build`
- OpenTofu doesn't start or stop stacks (`active` is ignored): Portainer 2.45 reports some running Git stacks with a status the provider reads as stopped, and "starting" them again redeployed and removed their containers
- the stacks' variables (`stack_env`) **are** stored in the state, because Portainer needs them as values; the state stays local and private
- **private images** (`registries`, `registry_passwords`): a registry login in Portainer, created from here; a stack pulls with it only if it names it (`registries = ["ghcr"]`), otherwise the pull fails with `denied` even though the login exists in Portainer
    - for ghcr.io: a **classic** GitHub token with only `read:packages` (fine-grained tokens don't work for packages); stored in the state, the provider has no write-only field for it
    - an existing login made in Portainer's UI is taken over with an `import` block (`to = portainer_registry.registry["<name>"]`, `id = "<number in its address, #!/registries/<n>>"`)

## First run

All on your PC, in PowerShell, in this folder (`tofu\portainer`); code blocks are typed into the terminal. Portainer must be reachable from the PC (home network or Tailscale).

1. **Portainer access token** (browser)
    - click **your user name at the top right** (with the `˅` arrow), not Settings in the left menu: Settings → General is the administration page and has no tokens
    - in the menu: **My account** → scroll to **Access tokens** → **+ Add access token**
    - description `opentofu`; Portainer asks for your password once
    - copy the token, it's shown only once; paste it straight into `terraform.tfvars` as `portainer_api_key`
    - to revoke it later: the same list, select the token → **Remove**
2. **environment ID**: open your Docker environment in Portainer; the number after `#!/` in the address is the ID (usually `1`)
3. **fill in the values**
    ```powershell
    copy terraform.tfvars.example terraform.tfvars
    git check-ignore -v terraform.tfvars      # must print a line with *.tfvars
    ```
    - `stacks`: keep only the stacks you run
    - `stack_env`: the same values the stacks use today (Portainer → stack → **Environment variables**); for postgres and nextcloud the **existing volume names**, or they start empty ([postgres](../../stacks/postgres/README.md#switching-from-an-existing-stack-without-losing-data), [nextcloud](../../stacks/nextcloud/README.md#switching-from-an-existing-stack-without-losing-data))
    - `github_token`: the read-only token ([GitHub read-only token](../../docs/integrations/github-read-token.md))
4. **download the provider** (changes nothing in Portainer)
    ```powershell
    tofu init
    ```
    → `OpenTofu has been successfully initialized!`
5. **take over the stacks that already exist** (next section), so they aren't created twice
6. **dry run, then apply**
    ```powershell
    tofu plan
    tofu apply
    ```
    → check the plan first; at `Enter a value:` type `yes`

## Taking over existing stacks

A stack that already exists in Portainer under the same name makes `apply` fail. Per stack, one of:

- **deployed from Git** (Portainer → stack shows a repository): hand it over with `tofu import`; nothing changes in Portainer
    ```powershell
    # ID format: <environment>-<stack>-standalone-repository
    #   environment: the number after #!/ in Portainer's address (e.g. 3)
    #   stack: open the stack in Portainer, the address contains id=<number> (e.g. 34)
    tofu import 'portainer_stack.stack["test-hello-stack"]' 3-34-standalone-repository
    ```
    → `Import successful!`
    - the next `tofu plan` shows the stack as **must be replaced** (`repository_wo_version ... forces replacement`): the GitHub token's version counter isn't set on imported stacks, and setting it recreates the stack once. Portainer deletes and recreates it from the repo; named volumes and folders stay, the service is down for a few seconds
- **pasted into Portainer's editor** (no repository): delete that stack in Portainer (Stacks → stack → **Delete**, without removing volumes), then `tofu apply` creates it from the repo
    - its data survives, because the volumes and folders have fixed names; check the volume names in `stack_env` first
    - the service is down between delete and apply; do one stack at a time

Quotes in `tofu import`: single quotes outside, plain double quotes inside (PowerShell 7).

## Daily use

- add a stack: one line in `stacks`, its variables in `stack_env`, then `tofu plan` and `tofu apply`
- change a variable: edit `stack_env`, `tofu apply`; Portainer redeploys that stack
- new GitHub token: put it in `github_token`, raise `github_token_version` by one, `tofu apply`
- remove a stack: delete its line, `tofu apply` (removes the stack; volumes stay)

## State

`terraform.tfstate` holds the stacks and their variables, passwords included. It stays on this PC, is gitignored, and should have a private copy (e.g. in Nextcloud). Lose it and OpenTofu no longer knows the stacks: import them again as above.
