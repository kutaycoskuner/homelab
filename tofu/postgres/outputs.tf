# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-30
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# The generated passwords, for the stacks that log in with these users.
# Hidden in `tofu output`; one user's: tofu output -json passwords, then pick it by name.

output "passwords" {
  description = "User name -> generated password"
  value       = { for name, p in random_password.user : name => p.result }
  sensitive   = true
}
