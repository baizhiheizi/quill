## Why

Arweave integration (article uploads, acceptance polling, Mirror.xyz import, and related UI) is unused and unmaintained. It adds operational cost (platform wallet, cron jobs, forked gem), complicates tests and CI, and does not align with Quill's core value (paid publishing and early-reader revenue sharing). Removing it reduces dead code and infrastructure with no user-facing loss.

## What Changes

- **BREAKING**: Stop uploading article content to Arweave on publish and via hourly batch jobs.
- **BREAKING**: Remove the "Web3 Proof of Publishing" panel (Arweave TX, content digest, author address block) from article pages.
- **BREAKING**: Remove Mirror.xyz article import from the author dashboard.
- **BREAKING**: Drop the `arweave_transactions` table and `ArweaveTransaction` model.
- Remove all Arweave-related jobs, recurring schedules, admin UI, and `ArweaveBot` client code.
- Remove `arweave` and `graphql-client` gems from the Gemfile.
- Remove `Articles::Arweavable` and `Users::Importable` concerns; unwind associations on `Article`, `User`, and `ArticleSnapshot`.
- Remove `ArticleImportedNotifier` and related locale strings.
- Update project documentation (`AGENTS.md`, architecture and background-jobs docs, cursor rules).

**Unchanged**: Article publishing, payments, revenue distribution, `ArticleSnapshot` history in PostgreSQL, and ActiveStorage content storage.

## Capabilities

### New Capabilities

- `content-storage`: Defines how published article content is persisted after Arweave removal (PostgreSQL + ActiveStorage only; no external permanence layer).

### Modified Capabilities

<!-- No existing specs in openspec/specs/ -->

## Impact

- **Models**: `Article`, `User`, `ArticleSnapshot` — association and concern cleanup.
- **Jobs**: Delete `Articles::UploadToArweaveJob`, `Articles::BatchUploadToArweaveJob`, `ArweaveTransactions::BatchAcceptJob`, `Users::ImportArticlesFromMirrorJob`.
- **Config**: `config/recurring.yml`, `config/routes/admin.rb`, `config/routes/dashboard.rb`.
- **Views**: Article content partials, admin sidebar and article tabs, dashboard import UI.
- **Credentials**: `arweave` and `encryption` keys become unused (manual cleanup post-deploy).
- **Database**: New migration to drop `arweave_transactions`.
- **Tests**: Remove Arweave and Mirror import job/model tests and fixtures; adjust notifier test if needed.
