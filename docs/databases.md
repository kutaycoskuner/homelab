# Databases

How the databases of the own apps are built and changed: who does what, and why it was set up this way.

## The line

| Part | Done by | Where |
|---|---|---|
| the PostgreSQL server | the [postgres stack](stack-postgres.md) | `stacks/postgres` |
| databases, users, grants, generated passwords | OpenTofu, [tofu/postgres](../tofu/postgres/README.md) | one list of databases and users in the private configuration (e.g. `databases.yml`) |
| each app's connection setting (`DATABASE_URL`) | OpenTofu, [tofu/portainer](../tofu/portainer/README.md) | built from tofu/postgres' state, passed as a stack variable |
| tables, columns, fixed lists | the app itself | a schema file in the app's own repository, applied by its own tool |
| the server itself (packages, Docker, Portainer), not the databases | Ansible, with Ansible Vault | [ansible/](../ansible/README.md) (written, not run yet) |

```text
databases.yml ─▶ tofu/postgres ─▶ databases + users + passwords (state in S3)
                                          │
                                          ▼
                 tofu/portainer ─▶ DATABASE_URL per stack ─▶ app ─▶ applies its own schema
```

- **one tool per layer**: everything about the database server (which databases, who may log in, with which rights) is OpenTofu; nothing there is typed by hand or done in pgAdmin
- **one list**: the databases and users are written once, in a YAML file; tofu reads it with `yamldecode(file(...))`

## Why this way

- **passwords flow without copying**: tofu generates each app user's password, keeps it in its state and builds the app's `DATABASE_URL` from it; nobody types or pastes a database password
- **tables belong to the app**: the app's code and its tables change together, in one repository and one commit; OpenTofu's postgres provider has no table or SQL resource anyway
- **Ansible was considered for the databases** (Nov 2026: databases as YAML, passwords in Ansible Vault) and dropped for them:
    - the generated passwords would have to be copied into a vault by hand, and kept in sync with the stacks
    - two tools for the same layer means two places to look; one is enough
    - Ansible configures the server itself instead (packages, Docker, Portainer, folders: [ansible/](../ansible/README.md)), where a vault fits
- **SQL scripts run by tofu** (through `psql` on the PC) were considered and dropped: a workaround for what the provider can't do, and a local install on every PC that runs tofu

## Safety

- **existing databases are taken over, not created**: an `import` block per database; the first `plan` must show only imports
- **`prevent_destroy`** on every database: tofu refuses a plan that would delete or replace one (replacing deletes the data)
- **`plan` before every `apply`**, read before typing `yes`
- **backup first**: the nightly [backup](backup.md) dumps every database; before a schema change, run one by hand (`docker exec backup backup.sh` on the server)

## Known limits

- **app users don't own the original tables** (made by the admin): they can read and write them, but not `ALTER` or `DROP` them. An app that changes its own tables needs to own them, a one-time change of owner
- **the database port** is published on every interface of the server; it should only be reachable from the home network and Tailscale ([Keep it private](stack-postgres.md#keep-it-private))

## Changes
- 2026-11-28 — Ansible row: the server itself, in ansible/
- 2026-11-28 — first version: tofu for databases, users and passwords; tables owned by each app; Ansible only for server configuration; why, safety, limits
