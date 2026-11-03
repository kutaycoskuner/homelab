# tofu/aws

Offsite storage for the server's backups, as code: an S3 bucket, a login for the server that may only use that bucket, a second bucket for the tofu states, and a monthly budget with email alerts. Run with OpenTofu (`tofu`) on your PC ([Terraform and OpenTofu](../../docs/terraform.md)).

## Files

| File | Holds | In git |
|---|---|---|
| `main.tf` | the backup bucket, its protection, the server's login, the state bucket, the budget | yes |
| `variables.tf` | the inputs, with descriptions | yes |
| `outputs.tf` | bucket name, region and the server's login, for the backup on the server; the state bucket's name | yes |
| `terraform.tfvars.example` | the inputs with placeholders | yes |
| `terraform.tfvars` | your values (no secrets) | no (gitignored) |
| state | what tofu created, **including the server login's secret**; in the state bucket, a local `terraform.tfstate` only during the first run ([State](#state)) | no |

## How it works

- **bucket**: never public (public access block), encrypted at rest, with versioning: a deleted or overwritten file stays recoverable for `keep_old_versions_days` (default 30), so a compromised server can't wipe the backups at once; broken uploads are removed after 7 days
- **storage class**: S3 Standard; for a few hundred MB that's fractions of a cent per month, and cold classes would break restic, which reads its index regularly
- **the server's login** (`homelab-backup`): an IAM user allowed only to list, read, write and delete files in this one bucket; its key is created here and shown with `tofu output`
- **state bucket** (`state_bucket_name`): holds the tofu states of every folder, so they no longer exist only on the PC; never public, encrypted at rest, versioned (an older state stays recoverable for `keep_old_state_versions_days`, default 90); separate from the backup bucket because the states hold every password, so the server's login has no access, only yours
- **your login**: tofu signs in through an AWS CLI profile (`aws_profile`), e.g. from `aws login`, with temporary credentials; no key is stored on the PC
- **budget**: an email when the month's costs pass 80% of `budget_limit_usd`, and when AWS forecasts the month to end above it; a warning, not a hard stop

## First run

From the repo root, in PowerShell:

```powershell
# 1. sign in (opens the browser; the credentials expire after some hours)
aws login --profile <profile-name>

# 2. your values: copy the example, then fill it in
Copy-Item tofu/aws/terraform.tfvars.example tofu/aws/terraform.tfvars

# 3. the state bucket doesn't exist yet: comment out the backend "s3" block in main.tf
#    (select it, Ctrl+/), so this first run keeps its state locally

# 4. download the provider, preview (about 14 to add), create
tofu -chdir=tofu/aws init
tofu -chdir=tofu/aws plan
tofu -chdir=tofu/aws apply

# 5. uncomment the backend block, then move the state into the new bucket (answer yes)
tofu -chdir=tofu/aws init -migrate-state
tofu -chdir=tofu/aws plan     # must say: No changes
```

If `plan` fails with a credentials error although `aws sts get-caller-identity --profile <profile-name>` works, the provider doesn't know the login type yet. Add a second profile that hands the CLI's credentials over, in `~/.aws/config`, and use it as `aws_profile`:

```ini
[profile <profile-name>-tofu]
credential_process = aws configure export-credentials --profile <profile-name> --format process
region = eu-central-1
```

If `apply` fails with **"explicit deny in a service control policy"**, the account is an AWS "project" (accounts created through the newer signup, managed from `settings.aws.com`): it only allows its **home Region** until *advanced features* are activated there. Use that Region (the console's default after signing in, e.g. `eu-north-1`) as `region`, or activate advanced features (it also removes the project's spend limits).

If it fails with **"BucketAlreadyExists"**, someone in the world already has that name: add something of your own to `bucket_name`.

## Costs

A few hundred MB of backups: well under $0.10 per month. Budgets are free for the first two. Check the AWS account's plan: an account on the Free plan closes when its free period ends, and the backups with it.

## State

The state holds the server login's secret. It lives in the state bucket (`aws/terraform.tfstate`), next to the other tofu folders' states, so it no longer exists only on the PC; only your admin login can read it. Moving, reading another folder's state, optional encryption: [State in S3](../../docs/terraform.md#state-in-s3).
