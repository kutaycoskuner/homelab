# tofu/aws

Offsite storage for the server's backups, as code: an S3 bucket, a login for the server that may only use that bucket, and a monthly budget with email alerts. Run with OpenTofu (`tofu`) on your PC ([Terraform and OpenTofu](../../docs/terraform.md)).

## Files

| File | Holds | In git |
|---|---|---|
| `main.tf` | the bucket, its protection, the server's login, the budget | yes |
| `variables.tf` | the inputs, with descriptions | yes |
| `outputs.tf` | bucket name, region and the server's login, for the backup on the server | yes |
| `terraform.tfvars.example` | the inputs with placeholders | yes |
| `terraform.tfvars` | your values (no secrets) | no (gitignored) |
| `terraform.tfstate` | what tofu created, **including the server login's secret** | no (gitignored) |

## How it works

- **bucket**: never public (public access block), encrypted at rest, with versioning: a deleted or overwritten file stays recoverable for `keep_old_versions_days` (default 30), so a compromised server can't wipe the backups at once; broken uploads are removed after 7 days
- **storage class**: S3 Standard; for a few hundred MB that's fractions of a cent per month, and cold classes would break restic, which reads its index regularly
- **the server's login** (`homelab-backup`): an IAM user allowed only to list, read, write and delete files in this one bucket; its key is created here and shown with `tofu output`
- **your login**: tofu signs in through an AWS CLI profile (`aws_profile`), e.g. from `aws login`, with temporary credentials; no key is stored on the PC
- **budget**: an email when the month's costs pass 80% of `budget_limit_usd`, and when AWS forecasts the month to end above it; a warning, not a hard stop

## First run

From the repo root, in PowerShell:

```powershell
# 1. sign in (opens the browser; the credentials expire after some hours)
aws login --profile <profile-name>

# 2. your values: copy the example, then fill it in
Copy-Item tofu/aws/terraform.tfvars.example tofu/aws/terraform.tfvars

# 3. download the provider, preview (about 9 to add), create
tofu -chdir=tofu/aws init
tofu -chdir=tofu/aws plan
tofu -chdir=tofu/aws apply
```

If `plan` fails with a credentials error although `aws sts get-caller-identity --profile <profile-name>` works, the provider doesn't know the login type yet. Add a second profile that hands the CLI's credentials over, in `~/.aws/config`, and use it as `aws_profile`:

```ini
[profile <profile-name>-tofu]
credential_process = aws configure export-credentials --profile <profile-name> --format process
region = eu-central-1
```

## Costs

A few hundred MB of backups: well under $0.10 per month. Budgets are free for the first two. Check the AWS account's plan: an account on the Free plan closes when its free period ends, and the backups with it.

## State

The state holds the server login's secret: keep it local and private, like the other tofu folders.
