# tofu/github

GitHub Actions secrets as code: a repo's CI secret is set by `tofu apply` from a value OpenTofu already knows, instead of being copied by hand into GitHub's settings. Run with **OpenTofu** (`tofu`), usually as a module from a folder that has the values. Background: [Terraform and OpenTofu](../../docs/terraform.md).

- manages: Actions secrets (repository, name, value)
- doesn't manage: the repositories themselves, workflows, other settings
- typical use: a Portainer webhook URL (`webhook_urls` from [tofu/portainer](../portainer/README.md)) as the secret an app's CI calls after pushing its image

## Files

```text
tofu/github/
├── main.tf        one Actions secret per entry in actions_secrets
├── variables.tf   which values main.tf needs; no values themselves
└── README.md      this file
```

## Use as a module

```hcl
module "github" {
  source = "../../../homelab/tofu/github"

  github_owner    = "<owner>"
  github_token    = var.github_token
  actions_secrets = { app_webhook = { repository = "<repo>", name = "PORTAINER_WEBHOOK" } }
  secret_values   = { app_webhook = local.webhook_url }
}
```

- names and values are separate: OpenTofu can't loop over secret values
- an empty value stops the apply with an error, so a missing source (e.g. an output that was empty) never overwrites a working secret

## The token

A **fine-grained** token, limited to the repositories in `actions_secrets`, with only **Secrets: Read and write**: steps in [Portainer webhook](../../docs/integrations/portainer-webhook.md#set-up), step 3. It goes into the calling folder's `secrets.auto.tfvars`.

## State

The secret values are stored in the state, because the provider has no write-only field for them. Keep the state private, like the other tofu folders'. Run on its own, it stays local; the owner's setup keeps it in an S3 bucket ([State in S3](../../docs/terraform.md#state-in-s3)).
