# Deploy Quill with Kamal

> **30-second summary:** Production deploys run via `gh workflow run Deploy`, which builds/pushes the image and runs `bundle exec kamal deploy --skip-push` against `172.235.197.72`.

## 1. What gets deployed

Quill runs as a single service (`service: quill`) with three roles on one host (`172.235.197.72`):

| Role | Entrypoint | Notes |
|------|-----------|-------|
| `web` | Rails (default `bin/rails server`) | Serves public web, dashboard, admin, API, mvm, grover |
| `job` | `bin/jobs` | Solid Queue worker for ActiveJob processing |
| `blaze` | `bin/mixin_blaze` | Mixin blaze client (Mixin network integration) |

Two **accessories** run alongside the app: `db` (`pgvector/pgvector:pg16` on port `5432`, data mounted to `/var/lib/postgresql/data`) and `db_backup` (`eeshugerman/postgres-backup-s3:16`, `@daily`, 7 days of S3 backups). Traefik fronts the `web` role on `quill.im` with TLS.

## 2. Persistent storage

Article uploads and snapshots live under `/rails/storage`, backed by a host volume. Declare the bind mount at the **top level** of `config/deploy.yml` (Kamal 2.x rejects per-role `volumes:` keys — never reintroduce them or the deploy fails):

```yaml
# config/deploy.yml
volumes:
  - /var/lib/quill/storage:/rails/storage
```

Create the host directory once before the first deploy:

```bash
ssh deploy@172.235.197.72 'sudo mkdir -p /var/lib/quill/storage && sudo chown 1000:1000 /var/lib/quill/storage'
```

## 3. Required secrets

These secrets are never committed and must exist as GitHub Actions secrets on this repository:

| Secret | Used by | Where it ends up |
|--------|---------|------------------|
| `RAILS_MASTER_KEY` | Rails boot (decrypts `config/credentials/production.yml.enc`) | Rails env |
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub login + `kamal env push` | Kamal registry config |
| `SSH_PRIVATE_KEY` | Kamal SSHs to `172.235.197.72` to manage containers | Kamal agent |
| `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_BUCKET`, `S3_ENDPOINT` | `db_backup` accessory | Postgres dump uploads |
| `POSTGRES_PASSWORD` | Database containers (app + accessory) | `DATABASE_URL` env |

Rotate `RAILS_MASTER_KEY` or `KAMAL_REGISTRY_PASSWORD` on GitHub **before** the next deploy, and mirror env changes via `bin/kamal env push`.

## 4. Run a deploy

Deploys are triggered manually from the GitHub UI or CLI:

```bash
gh workflow run Deploy
```

The workflow (`.github/workflows/deploy.yml`) builds/pushes the image and runs `bundle exec kamal deploy --skip-push` so Kamal skips its own push step. Watch the run in the Actions tab.

## 5. Operate a running deploy

Once the service is up, use Kamal aliases to interact with the web container without SSH-ing manually:

| Alias | Equivalent |
|-------|-----------|
| `bin/kamal console` | `app exec --interactive --reuse "bin/rails console"` |
| `bin/kamal shell` | `app exec --interactive --reuse "bash"` |
| `bin/kamal logs` | `app logs -f` |
| `bin/kamal logs -r job` | Follow logs from the first host in the `job` role |
| `bin/kamal dbc` | `app exec --interactive --reuse "bin/rails dbconsole"` |

For job-container work (queue inspection, Solid Queue console), pass `-r job` to any `app exec` invocation.

### Rolling back

Kamal does not roll back automatically. If the new image is broken, re-tag a known-good SHA as `:latest` and rerun `gh workflow run Deploy`:

```bash
git checkout <last-good-sha>
gh workflow run Deploy
```

If only the env changed, run `bin/kamal deploy --skip-push` directly.

## 6. Customizing the deploy

The Kamal config is intentionally minimal — most app configuration lives in Rails credentials and `config/settings.yml`. When extending it: **host volumes** belong at the top level (see [Persistent storage](#2-persistent-storage)); **accessories** append to `accessories:` (single-host topology only); **env vars** go in `env.clear:` or `env.secret:`, then `bin/kamal env push`; **roles** add a `servers.<name>:` block with `hosts:` and `cmd:`.

Keep the deploy file under 200 lines and comment anything non-obvious.

## Troubleshooting

- **`kamal deploy` rejects the config with a schema error mentioning `volumes`** — a per-role `volumes:` key crept back in. Move it to the top level (see [Persistent storage](#2-persistent-storage)).
- **`KAMAL_REGISTRY_PASSWORD` is undefined** — the GitHub Actions secret is missing or rotated; update it and rerun.
- **Container exits because `Rails can't decrypt credentials`** — `RAILS_MASTER_KEY` no longer matches `config/credentials/production.yml.enc`; re-add the matching key as a secret.
- **`db_backup` fails with S3 errors** — confirm `S3_*` secrets and that `POSTGRES_HOST=172.18.0.1` is reachable from the accessory's Docker network.
- **Image is fresh but old code still runs** — Kamal uses the `:latest` tag, so the workflow's tag step must finish before `kamal deploy`. A manual `--skip-push` rerun may still reference the previous image; rerun without `--skip-push` to refresh it.

## Next steps

- [Reference → HTTP API](../reference/api.md) for the routes the deploy exposes.
- [Explanation → Architecture](../explanation/architecture.md) for the subsystems the deploy brings up.
- [README → Development](../../README.md#development) for the local counterpart of this guide.