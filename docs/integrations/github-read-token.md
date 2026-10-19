# GitHub read-only token

Lets Portainer clone this repo while it is private, without giving it access to anything else.

## What it is and why we use it

- **Fine-grained personal access token**: a password-like key limited to chosen repositories and permissions
    - why: Portainer clones repos over HTTPS and needs a login for a private repo; GitHub has no service accounts for personal accounts, so a token that can only read one repo plays that role
    - if it leaks, it can read this one repo, nothing else
- not needed once the repo is public
- not the same as Portainer's **ghcr.io registry** login: that one pulls images (`read:packages`), this one clones the repo

## Create the token

1. GitHub → profile picture → **Settings → Credentials → Fine-grained tokens → Generate new token**
2. fill in:
    - name: `portainer-homelab-read`
    - expiration: a date you'll notice (e.g. 1 year); put a reminder in your calendar
    - resource owner: your account
    - repository access: **Only select repositories** → `homelab`
    - permissions → repository permissions → **Contents: Read-only** (Metadata: Read-only is added automatically); nothing else
3. **Generate token** and copy it: GitHub shows it only once
    - paste it straight into Portainer (next step), never into a file, chat or the repo

## Use it in Portainer

- stack page → **Repository** → **Authentication** on
    - username: your GitHub user name
    - token: the token
- if your Portainer can save Git credentials (**My account → Git credentials**), save it as `homelab-read` and pick it from the list in later stacks

## Renew or replace it

- expired or leaked: GitHub → the token → **Regenerate token** (or delete it and create a new one as above)
- update the saved credential (or each stack's Authentication) in Portainer
- symptom of an expired token: **Pull and redeploy** fails with an authentication error

## Used by

- Portainer stacks deployed from this repo, e.g. [temp_control](../../scripts/temp_control/README.md)

## Changes
- 2026-10-19 — menu path corrected to Settings → Credentials → Fine-grained tokens
- 2026-10-19 — first version: what the token is and why, creating it (homelab only, Contents read-only), using it in Portainer, renewing it
