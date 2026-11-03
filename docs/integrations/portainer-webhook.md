# Portainer webhook

How an app's CI redeploys its stack on the server right after it pushes a new image, without polling and without opening Portainer to the internet.

## What it is and why we use it

- **Portainer webhook**: a secret URL per stack; a `POST` to it makes Portainer pull the stack's images again and redeploy it
    - why: an app in its own repo (e.g. a website) builds its image in CI; the webhook lets that CI deploy it within seconds, and a failed deploy shows up as a failed CI step
    - instead of **polling** ([Updates](../updates.md)): polling only notices changes in the stack's files, not a new image under the same tag (e.g. `:latest`), and waits up to its interval
    - the URL contains its own ID: anyone who has it can trigger a redeploy (not change the stack), so it's a secret
- **all as code**: the webhook ([tofu/portainer](../../tofu/portainer/README.md)), its public route ([tofu/cloudflare](../../tofu/cloudflare/README.md)) and the CI secret ([tofu/github](../../tofu/github/README.md)); the URL is never copied by hand

```text
push to the app repo → CI builds and pushes <image>:latest → CI: POST https://deploy.<domain>/api/stacks/webhooks/<id>
  → Cloudflare Tunnel (only /api/stacks/webhooks/) → Portainer → pull <image>:latest, redeploy the stack
```

## Placeholders used on this page

| Placeholder | Meaning | Example |
|---|---|---|
| `<stack>` | the stack's name in `tofu/portainer`'s `stacks` | `my-app` |
| `<domain>` | your domain on Cloudflare | `example.net` |
| `<owner>/<repo>` | the app's GitHub repository | `alice/my-app` |
| `<id>` | the webhook's ID, the end of its URL | `3f2a…` (36 characters) |

## Set up

All on your PC, in PowerShell, in the folder that runs the tofu folders; each `apply` shows its plan first, check it, then type `yes`.

1. **the stack**: in `tofu/portainer`'s `stacks`, give the stack `webhook = true` and an image tag that moves, e.g. `<image>:latest` in its compose file (`pull_image` stays on, the default)
    ```powershell
    tofu -chdir=tofu/portainer apply
    tofu -chdir=tofu/portainer apply -refresh-only
    ```
    → the first plan: `1 to change` (the stack: webhook on, polling off); the second reads the URL Portainer created, which the first apply saves empty
2. **the public route**: in `tofu/cloudflare`'s `routes`, a route to Portainer's HTTP port limited to the webhook path; every other path gets 404, so Portainer's login stays private
    ```hcl
    { subdomain = "deploy", port = 9000, path = "^/api/stacks/webhooks/" },
    ```
    ```powershell
    tofu -chdir=tofu/cloudflare apply
    curl.exe -s -o NUL -w "%{http_code}" https://deploy.<domain>/
    ```
    → `1 to add, 1 to change` (DNS record and route list); the check prints `404`
3. **the GitHub token** (browser), for setting the CI secret from tofu:
    1. github.com → your picture (top right) → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**
    2. name e.g. `tofu-actions-secrets`; an expiration date you'll notice
    3. **Repository access** → **Only select repositories** → the app repos whose CI calls a webhook
    4. **Permissions** → **Repository permissions** → **Secrets**: **Read and write** (Metadata: Read-only is added by itself); nothing else
    5. **Generate token**, copy it (shown only once) into `tofu/github`'s `secrets.auto.tfvars`
4. **the CI secret**: `tofu/github` reads the URL from `tofu/portainer`'s state, swaps Portainer's local address for `https://deploy.<domain>` and sets it as the app repo's Actions secret, e.g. `PORTAINER_WEBHOOK` (example: [tofu/github](../../tofu/github/README.md#use-as-a-module))
    ```powershell
    tofu -chdir=tofu/github init
    tofu -chdir=tofu/github apply
    ```
    → `1 to add`; an empty URL stops the apply with "A secret value is empty" (step 1's `-refresh-only` is missing)
5. **the CI step**: in the app's workflow, after the image push
    ```yaml
          - name: Redeploy on Portainer
            env:
              PORTAINER_WEBHOOK: ${{ secrets.PORTAINER_WEBHOOK }}
            run: |
              if [ -z "$PORTAINER_WEBHOOK" ]; then echo "no PORTAINER_WEBHOOK secret: redeploy skipped"; exit 0; fi
              curl -fsS -X POST "$PORTAINER_WEBHOOK"
    ```
    - without the secret (e.g. in a fork) the step is skipped instead of failing

## Test it

- push a change to the app; its workflow's last step "Redeploy on Portainer" is green, and the stack's **Updated** time in Portainer changes
- by hand, without a push (the URL from `tofu -chdir=tofu/portainer output -json webhook_urls`, with `https://deploy.<domain>` in front of `/api/stacks/webhooks/`):
    ```powershell
    curl.exe -s -o NUL -w "%{http_code}" -X POST https://deploy.<domain>/api/stacks/webhooks/<id>
    ```
    → `204` or `200`

## Replace a leaked webhook, renew the token

- **leaked URL**: recreate the stack, which gives it a new ID, then set the secret again
    ```powershell
    tofu -chdir=tofu/portainer apply '-replace=module.portainer.portainer_stack.stack["<stack>"]'
    tofu -chdir=tofu/portainer apply -refresh-only
    tofu -chdir=tofu/github apply
    ```
    - the stack is down for a few seconds; named volumes stay
- **after any apply that recreated the stack** (plan said `must be replaced`): the URL changed too; run the last two lines above
- **expired token**: GitHub → the token → **Regenerate token**, put it in `secrets.auto.tfvars`; nothing else changes (the token isn't stored in the state)

## Used by

- app repos with their own image, deployed as a stack from a private configuration (see [tofu/portainer](../../tofu/portainer/README.md), stacks from another repo)

## Changes
- 2026-11-01 — first version: webhook per stack, webhook-only tunnel route, CI secret set by tofu/github, the CI step, testing, replacing a leaked URL
