# copy_tfvars_values

Copies the values from one OpenTofu `.tfvars` file into others, key by key, without showing them.

- **what for**: moving your values to new files, e.g. from `tofu/<folder>/terraform.tfvars` here into a private repo's `terraform.tfvars` and `secrets.auto.tfvars` ([Your own values in a private repo](../../docs/terraform.md#your-own-values-in-a-private-repo))
- **why a script**: the values are tokens and IDs; copied by the script, they never pass through the clipboard or the screen
- **what it changes**: only simple assignments in the targets (`key = "..."`, numbers, true/false) whose key exists once in the source; comments, `stack_env = {` openers and unknown keys stay as they are
- **what it prints**: key names and what happened (filled / already the same / not in the source), never a value
- requires Python 3.10+, standard library only

## Use

1. copy each target from its `.example` (the script fills existing files, it doesn't create them)
2. preview, from this repo's root:
    ```powershell
    python scripts/copy_tfvars_values/copy_tfvars_values.py --copy tofu/portainer/terraform.tfvars ../my-homelab/tofu/portainer/terraform.tfvars ../my-homelab/tofu/portainer/secrets.auto.tfvars --dry-run
    ```
    - first path: the source; the others: the targets
    - expected: per target, one line per key and `0 <placeholder>(s) left after filling`
3. the same without `--dry-run`: it asks per file before writing (`--yes` skips the question)

A bare run prints the help.

## Changes
- 2026-10-28 — first version: fills target .tfvars from a source, per key, asks per file, --dry-run
