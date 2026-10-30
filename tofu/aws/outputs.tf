# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# What the server's backup needs: where to write and with which login.
# Show one value with e.g. `tofu output -raw bucket_name`; the secret is hidden in `tofu output`.

output "bucket_name" {
  description = "The backup bucket"
  value       = aws_s3_bucket.backup.bucket
}

output "region" {
  description = "Region of the bucket"
  value       = var.region
}

output "backup_access_key_id" {
  description = "Key ID of the server's backup login"
  value       = aws_iam_access_key.backup.id
}

output "backup_secret_access_key" {
  description = "Secret of the server's backup login (show with `tofu output -raw backup_secret_access_key`)"
  value       = aws_iam_access_key.backup.secret
  sensitive   = true
}
