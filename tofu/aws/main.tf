# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# Offsite storage for the server's backups, as code (see README.md). Run with OpenTofu (tofu).
# An S3 bucket that can never be public, keeps deleted files for a while, and a login for the
# server that may only use this one bucket; plus a monthly budget with email alerts.

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# signs in with an AWS CLI profile (e.g. from `aws login`), so no key is stored on the PC
provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      managed-by = "opentofu"
      project    = "homelab"
    }
  }
}

# -----------------------------------------------------------------------------------------
#   bucket
# -----------------------------------------------------------------------------------------

resource "aws_s3_bucket" "backup" {
  bucket = var.bucket_name
}

# never public, not even by mistake
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# encrypted on AWS's disks too (restic already encrypts before uploading)
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# deleted or overwritten files stay as old versions, so a compromised server can't wipe the
# backups at once; the lifecycle rule below removes old versions after a while
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "remove-old-versions-and-broken-uploads"
    status = "Enabled"
    filter {} # every file in the bucket

    noncurrent_version_expiration {
      noncurrent_days = var.keep_old_versions_days
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.backup]
}

# -----------------------------------------------------------------------------------------
#   the server's login: only this bucket
# -----------------------------------------------------------------------------------------

resource "aws_iam_user" "backup" {
  name = var.backup_user_name
}

resource "aws_iam_user_policy" "backup" {
  name = "only-the-backup-bucket"
  user = aws_iam_user.backup.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListTheBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.backup.arn
      },
      {
        # restic also deletes: lock files, and old snapshots when pruning
        Sid      = "ReadWriteItsFiles"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.backup.arn}/*"
      },
    ]
  })
}

# the server can't sign in through a browser, so it gets a key; the secret is stored in the
# state (local, gitignored) and shown only with `tofu output -raw backup_secret_access_key`
resource "aws_iam_access_key" "backup" {
  user = aws_iam_user.backup.name
}

# -----------------------------------------------------------------------------------------
#   cost alarm
# -----------------------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly" {
  name         = "homelab-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # this month's costs passed 80% of the limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  # AWS expects the month to end above the limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}
