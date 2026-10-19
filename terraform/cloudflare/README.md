# terraform/cloudflare

The Cloudflare Tunnel's routes and DNS records as code: add a line to `routes`, run `terraform apply`, and `https://<subdomain>.<domain>` points at that port on the server. Background on Terraform: [Terraform](../../docs/terraform.md).

- manages: the tunnel's published routes and one DNS record per route
- doesn't manage: the tunnel itself (created in the dashboard) and the `cloudflared` container ([stacks/cloudflared](../../stacks/cloudflared/README.md))
- secrets: API token and IDs in `terraform.tfvars` (gitignored), see [terraform.tfvars.example](terraform.tfvars.example)

## Files

```text
terraform/cloudflare/
├── main.tf                    what should exist: the tunnel's route list and one DNS record per route
├── variables.tf               which values main.tf needs (name, type, description); no values themselves
├── terraform.tfvars.example   those values with placeholders and where to find each; copy to terraform.tfvars
├── .terraform.lock.hcl        exact version and checksums of the Cloudflare provider, so every machine and CI use the same
├── README.md                  this file
│
│   local only, gitignored:
├── terraform.tfvars           your values: API token, account, zone and tunnel ID, domain, server address, routes
├── terraform.tfstate          Terraform's record of what it manages (can contain secrets; keep a private copy)
├── terraform.tfstate.backup   the previous state, written on every apply
└── .terraform/                the downloaded provider; recreated by terraform init
```

## How it works

For each line in `routes`, Terraform creates a DNS record and a tunnel route:

```text
browser → DNS: <subdomain>.<domain> = the tunnel → Cloudflare → tunnel → cloudflared on the server → <server-ip>:<port> → the stack
           └──── DNS record (Terraform) ────┘                  └──── tunnel route (Terraform) ────┘
```

## First run

All steps on your PC, in PowerShell, in this folder (`terraform\cloudflare`); code blocks are typed into the terminal.

1. **create a Cloudflare API token** (browser): profile icon → **My Profile → API Tokens → Create Token → Create Custom Token**
    - permissions, two rows: **Account → Cloudflare Tunnel → Edit**, **Zone → DNS → Edit**
    - resources: your account; **Specific zone** → your domain
    - client IP filtering: empty (a home IP changes, and behind CGNAT it's shared)
    - TTL: an end date, e.g. one year; put a reminder in your calendar
    - copy the token: it's shown only once
2. **fill in the values**: copy the example, then replace every placeholder; the comments say where each value is found
    ```powershell
    copy terraform.tfvars.example terraform.tfvars
    git check-ignore -v terraform.tfvars      # must print a line with *.tfvars: git ignores the file
    ```
    - `server_ip` is the server's **home network** address (`hostname -I` on the server), not your public one
    - every route that exists in the dashboard must be listed, or step 6 removes it
3. **download the provider** (the plugin that talks to Cloudflare; changes nothing in your account)
    ```powershell
    terraform init
    ```
    → `Terraform has been successfully initialized!`; creates `.terraform/` (gitignored) and `.terraform.lock.hcl` (commit it)
4. **dry run**: compares the files with your account and lists what would change; changes nothing
    ```powershell
    terraform plan
    ```
    → `Plan: N to add, 0 to change, 0 to destroy.` (N = 1 route list + 1 DNS record per route)
    - the warning "Resource Destruction Considerations" is a notice, not an error: `terraform destroy` can't remove the route list, it stays in Cloudflare
5. **hand existing DNS records over** (only when the dashboard already has routes): their records exist, so apply would fail with "record already exists". `terraform import` tells Terraform "this existing record is yours"; nothing changes in Cloudflare. Per existing route, here `media`:
    ```powershell
    # token, zone ID and domain for this window only; -MaskInput hides the token, it isn't kept in the history
    $token  = Read-Host "API token" -MaskInput
    $zone   = Read-Host "Zone ID"
    $domain = Read-Host "Domain"
    $h = @{ Authorization = "Bearer $token" }    # the login header Cloudflare's API expects

    # ask the API for the record's ID (the dashboard doesn't show it), then hand it over
    $id = (Invoke-RestMethod "https://api.cloudflare.com/client/v4/zones/$zone/dns_records?name=media.$domain" -Headers $h).result[0].id
    terraform import 'cloudflare_dns_record.route["media"]' "$zone/$id"
    ```
    → `Import successful!`; repeat the last two lines with the next route's name
    - quotes: single outside, plain double inside; `\"` is passed on literally by PowerShell 7 and Terraform rejects it
    - `terraform plan` again: the imported records no longer appear as "to add"
    - simpler alternative without the token: delete those CNAME records in the dashboard (DNS → Records) right before step 6; they're down for about a minute
6. **apply**: shows the plan once more and asks before changing anything
    ```powershell
    terraform apply
    ```
    → type `yes`; → `Apply complete! Resources: N added, 0 changed, 0 destroyed.`
7. **clean up and check**
    ```powershell
    Remove-Variable token    # or close the window
    ```
    - open `https://<subdomain>.<domain>` for each route, e.g. `https://hello.<domain>` (allow a minute for DNS)

## Add or remove a route

1. add or delete a line in `routes` in `terraform.tfvars`, e.g. `{ subdomain = "test", port = 8099 },`
2. `terraform plan`, check that only that route changes
3. `terraform apply`, type `yes`

From now on change routes only here: a route added in the dashboard is removed at the next apply.

## When a subdomain doesn't work

| Browser shows | Means | Check |
|---|---|---|
| "can't be reached" / DNS error | no DNS record for it | spelling of the address and of `domain` in `terraform.tfvars`; wait a minute; DNS → Records lists it |
| Cloudflare **Error 1033** | the tunnel isn't connected | Networking → Tunnels shows it **Healthy**; the `cloudflared` container runs on the server |
| Cloudflare **502 Bad Gateway** | tunnel fine, service unreachable | `http://<server-ip>:<port>` works at home; the stack runs; `server_ip` is right |

## State

`terraform.tfstate` (and `.backup`) is Terraform's record of what it manages. It stays on the machine you run Terraform on and is gitignored: it can contain secrets. Lose it and Terraform no longer knows its resources (import them again as in step 5). Keep a copy somewhere private, e.g. your Nextcloud.
