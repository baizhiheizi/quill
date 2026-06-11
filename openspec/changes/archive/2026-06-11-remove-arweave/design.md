## Context

Quill currently integrates Arweave in two places: (1) outbound uploads on publish via `Articles::Arweavable` and background jobs, tracked in `arweave_transactions`; (2) inbound Mirror.xyz imports via `ArweaveBot` GraphQL. Neither path has active users. The integration depends on a forked `arweave` gem, platform wallet credentials, encryption keys for paid-content uploads, and two recurring Solid Queue jobs.

Article content already lives in PostgreSQL and ActiveStorage. `ArticleSnapshot` provides version history independently of Arweave.

## Goals / Non-Goals

**Goals:**

- Remove all Arweave-related code, jobs, UI, gems, and database tables in one change.
- Preserve article publishing, payments, snapshots, and dashboard authoring flows.
- Follow existing Rails conventions: concerns for model behavior, namespaced jobs/controllers, route draws, frozen string literals, `restrict_with_error` patterns elsewhere unchanged.
- Ship a reversible migration (`drop_table` with `up`/`down` if feasible) for the schema change.

**Non-Goals:**

- Replacing Arweave with another permanence layer (IPFS, on-chain hash, etc.).
- Removing `ArticleSnapshot` or the `sha3` gem (still used by snapshots).
- Removing `public_key` from `user_authorizations` (still set during wallet login; harmless when unused).
- Manual credential rotation in encrypted credentials (document only; ops task post-deploy).

## Decisions

### 1. Hard delete, single PR — no feature flag or sunset period

**Rationale**: Product decision is that nobody uses or cares about Arweave. A flag adds complexity with no benefit.

**Alternative considered**: Soft deprecation (stop uploads, keep UI). Rejected per stakeholder input.

### 2. Drop `arweave_transactions` table via new migration

**Rationale**: Standard Rails approach. Use `bin/rails generate migration DropArweaveTransactions` and `drop_table :arweave_transactions` in `up`. Optional `create_table` in `down` mirroring current schema for reversibility.

**Alternative considered**: Leave table as archive. Rejected — dead data with no readers.

### 3. Delete whole files rather than stub no-op methods

**Rationale**: Matches "remove them" intent; avoids leaving dead entry points.

Files to delete entirely:

- `app/models/arweave_transaction.rb`
- `app/models/concerns/articles/arweavable.rb`
- `app/models/concerns/users/importable.rb`
- `app/libs/arweave_bot.rb` and `app/libs/arweave_bot/*`
- `app/jobs/articles/upload_to_arweave_job.rb`
- `app/jobs/articles/batch_upload_to_arweave_job.rb`
- `app/jobs/arweave_transactions/batch_accept_job.rb`
- `app/jobs/users/import_articles_from_mirror_job.rb`
- `app/controllers/admin/arweave_transactions_controller.rb`
- `app/controllers/dashboard/imported_articles_controller.rb`
- `app/notifiers/article_imported_notifier.rb`
- `app/views/articles/_blockchain_info.html.erb`
- `app/views/admin/arweave_transactions/*`
- `app/views/dashboard/imported_articles/*`
- Related tests and fixtures

### 4. Unwire models before dropping table

Remove associations and includes first so the app boots without referencing `ArweaveTransaction`:

| Model | Remove |
|-------|--------|
| `Article` | `include Articles::Arweavable`, `has_many :arweave_transactions`, `upload_to_arweave_async` in `do_first_publish` |
| `User` | `has_many :arweave_transactions`, `include Users::Importable` |
| `ArticleSnapshot` | `has_one :arweave_transaction` |

### 5. Remove gems: `arweave`, `graphql-client`

**Rationale**: `graphql-client` is only used by `ArweaveBot`. `sha3` stays for `ArticleSnapshot`.

Run `bundle install` after Gemfile edit.

### 6. Remove recurring jobs from `config/recurring.yml`

Delete `articles_batch_upload_to_arweave_job` and `arweave_transactions_batch_accept_job` entries from the shared `default` anchor.

### 7. Route and admin UI cleanup

- Remove `resources :arweave_transactions` from `config/routes/admin.rb`
- Remove `resources :imported_articles` from `config/routes/dashboard.rb`
- Remove admin sidebar "AR Tx" link and article show AR tab
- Remove dashboard "Import from mirror" link and modal

### 8. Locale cleanup

Remove `import_from_mirror`, `confirm_to_import_from_mirror`, `importing_tips` from view locales and `article_imported_notifier` from notification locales (en, zh-CN, ja).

### 9. Documentation updates

Update `AGENTS.md`, `docs/explanation/architecture.md`, `docs/reference/background-jobs.md`, and `.cursor/rules/project-overview.mdc` to remove Arweave references.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Pending Solid Queue jobs reference deleted job classes | Jobs will fail once deployed; acceptable for unused feature. Optionally clear queue rows pre-deploy in ops runbook. |
| Production `arweave_transactions` data lost | Accepted — no user-facing dependency. |
| Article delete previously blocked by `restrict_with_exception` on txs | Resolved when association removed. |
| Notifier test references `ArticleImportedNotifier` | Update or remove that test case. |
| CI previously flaky around Arweave network | Removal improves test reliability. |

## Migration Plan

1. Merge PR with code + migration.
2. Deploy via existing Kamal workflow.
3. Run `bin/rails db:migrate` on production (drops table).
4. Optionally edit credentials to remove unused `arweave` and `encryption` keys (non-blocking).

**Rollback**: Revert deploy and run migration `down` if table recreation is needed; would also require reverting code.

## Open Questions

None — scope is fully defined by exploration and product decision.
