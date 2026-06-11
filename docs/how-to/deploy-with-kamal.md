# Deploy Quill with Kamal

> **30-second summary:** Production deploys are kicked off manually from GitHub Actions (`gh workflow run Deploy`). The workflow builds the `anleework/quill` image, pushes it to Docker Hub, then runs `bundle exec kamal deploy --skip-push` against the server at `172.235.197.72`. Persistent storage is mounted at `/rails/storage` from the host via the **top-level** `volumes:` key in `config/deploy.yml` — Kamal 2.x rejects the per-role `volumes:` syntax.

This page is the authoritative description of how Quill ships to production. If a step here drifts, the source of truth is `config/deploy.yml`, `.github/workflows/deploy.yml`, and the Kamal hooks under `.kamal/hooks/`.

## 1. What gets deployed

Quill runs as a single service (`service: quill`) with three roles on one host (`172.235.197.72`):

| Role | Entrypoint | Notes |
|------|-----------|-------|
| `web` | Rails (default `bin/rails server`) | Serves public web, dashboard, admin, API, mvm, grover |
| `job` | `bin/jobs` | Solid Queue worker for ActiveJob processing |
| `blaze` | `bin/mixin_blaze` | Mixin blaze client (Mixin network integration) |

Two **accessories** run alongside the app:

- `db` — `pgvector/pgvector:pg16` on port `5432`, with a `data` directory mounted to `/var/lib/postgresql/data`.
- `db_backup` — `eeshugerman/postgres-backup-s3:16`, scheduled `@daily`, keeping 7 days of backups in S3.

Traefik fronts the `web` role on `quill.im` with TLS (`proxy.ssl: true`).

## 2. Persistent storage

Article uploads and snapshots live under `/rails/storage` inside the container. That path is backed by a **named host volume**:

```yaml
# config/deploy.yml
volumes:
  - /var/lib/quill/storage:/rails/storage
```

### Why the volume sits at the top level

Kamal 2.x **rejects per-role `volumes:` keys**. A previous version of this file declared `servers.web.volumes:` and `servers.job.volumes:`, which Kamal 2.x treats as a schema error and refuses to deploy.

Declaring the bind mount at the top level applies it to every role that needs it (web and job). The host directory `/var/lib/quill/storage` must already exist on the deploy target before the first deploy — create it once with:

```bash
ssh deploy@172.235.197.72 'sudo mkdir -p /var/lib/quill/storage && sudo chown 1000:1000 /var/lib/quill/storage'
```

> **Heads up:** when you change the storage path or add another volume, edit the top-level `volumes:` list. Do **not** reintroduce per-role `volumes:` keys — Kamal 2.x will reject the deploy and the workflow run will fail at the `kamal deploy` step.

## 3. Required secrets

The deploy workflow and Kamal both depend on secrets that are **never** committed to the repository. They must exist as GitHub Actions secrets on this repository:

| Secret | Used by | Where it ends up |
|--------|---------|------------------|
| `RAILS_MASTER_KEY` | Rails boot (decrypts `config/credentials/production.yml.enc`) | Rails env |
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub login + `kamal env push` | Kamal registry config |
| `SSH_PRIVATE_KEY` | Kamal SSHs to `172.235.197.72` to manage containers | Kamal agent |
| `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_BUCKET`, `S3_ENDPOINT` | `db_backup` accessory | Postgres dump uploads |
| `POSTGRES_PASSWORD` | Database containers (app + accessory) | `DATABASE_URL` env |

When you rotate `RAILS_MASTER_KEY` or `KAMAL_REGISTRY_PASSWORD`, update the secret on GitHub **before** the next deploy. Kamal uses its own secrets for `kamal env push`; mirror any env change there with `bin/kamal env push`.

## 4. Run a deploy

Deploys are triggered manually from the GitHub UI or CLI:

```bash
gh workflow run Deploy
```

The workflow (`.github/workflows/deploy.yml`) does the following:

1. Checks out the repo at the run's SHA.
2. Sets up Docker Buildx and logs in to Docker Hub as `anleework`.
3. Tags the image as `anleework/quill:$GITHUB_SHA` and `anleework/quill:latest`.
4. Builds and pushes the image (with GitHub Actions cache).
5. Adds the deploy SSH key to the runner's agent.
6. Runs `bundle exec kamal deploy --skip-push` — Kamal skips the push step because the workflow has already pushed the image.

You can watch the run from the Actions tab. The deploy step usually takes a couple of minutes.

## 5. Operate a running deploy

Once the service is up, use Kamal aliases to interact with the web container without SSH-ing manually:

| Alias | Equivalent |
|-------|-----------|
| `bin/kamal console` | `app exec --interactive --reuse "bin/rails console"` |
| `bin/kamal shell` | `app exec --interactive --reuse "bash"` |
| `bin/kamal logs` | `app logs -f` |
| `bin/kamal logs -r job` | Follow logs from the first host in the `job` role |
| `bin/kamal dbc` | `app exec --interactive --reuse "bin/rails dbconsole"` |

For job-container-specific work (queue inspection, running Solid Queue console, etc.), pass `-r job` to any `app exec` invocation, or SSH directly with `bin/kamal app exec -r job --interactive --reuse "bash"`.

### Rolling back

Kamal does not roll back automatically. If the new image is broken:

```bash
# Re-tag the previous known-good SHA as :latest and redeploy
git checkout <last-good-sha>
gh workflow run Deploy
```

If you need to skip the build (image is fine, env changed):

```bash
bin/kamal deploy --skip-push
```

## 6. Customizing the deploy

The Kamal config is intentionally minimal — most app configuration lives in Rails credentials and `config/settings.yml`. Add new pieces in this order:

1. **Add a new host volume** → extend the top-level `volumes:` list in `config/deploy.yml`.
2. **Add a new accessory** → append to `accessories:` in `config/deploy.yml`. Reference its host with the same IP for now; multi-host topology is not yet supported.
3. **Add a new env var** → add it to `env.clear:` (non-secret) or `env.secret:` (must already exist as a GitHub Actions secret) and run `bin/kamal env push`.
4. **Add a new role** → add a `servers.<name>:` block with `hosts:` and `cmd:`. Update the deploy workflow's `tags:` only if you change the image name.

Keep the deploy file under 200 lines and comment anything non-obvious — this page exists so readers do not need to re-derive the rationale from scratch.

## Troubleshooting

- **`kamal deploy` rejects the config with a schema error mentioning `volumes`** — you reintroduced a per-role `volumes:` key. Move it back to the top level.
- **`KAMAL_REGISTRY_PASSWORD` is undefined** — the GitHub Actions secret is missing or rotated; update it and rerun.
- **Container exits because `Rails can't decrypt credentials`** — `RAILS_MASTER_KEY` no longer matches `config/credentials/production.yml.enc`; re-add the matching key as a secret.
- **`db_backup` fails with S3 errors** — confirm `S3_*` secrets and that `POSTGRES_HOST=172.18.0.1` is reachable from the accessory's Docker network.
- **Image is fresh but old code still runs** — Kamal uses the `:latest` tag, so the workflow's tag step must finish before `kamal deploy`. If you re-ran a deploy manually with `--skip-push`, the `:latest` reference may still point at the previous image; rerun without `--skip-push`.

## Next steps

- [Reference → HTTP API](../reference/api.md) for the routes the deploy exposes.
- [Explanation → Architecture](../explanation/architecture.md) for the subsystems the deploy brings up.
- [README → Development](../../README.md#development) for the local counterpart of this guide.