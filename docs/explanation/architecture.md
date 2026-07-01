# Architecture

> **30-second summary:** Quill is a Rails 8 monolith that serves five surfaces (public web, **dashboard**, **admin**, **API**, **Grover**) from one set of models. Long-running work (payment settlement, Mixin bot messages) runs on ActiveJob via **Solid Queue**; real-time updates flow over **Solid Cable**. The payment hot path is `Article → Order → Orders::DistributeService → Transfer`, with each `Transfer` linked back to its `Order` through a polymorphic `source`.

## Surfaces

| Surface | Mount point | Purpose |
|---------|-------------|---------|
| Public web | `/` | Reading, tags, OAuth, public collections |
| Dashboard | `/dashboard` | Author authoring and earnings UI |
| Admin | `/admin` | Moderation, payments, stats, KYC reviews |
| API | `/api` (JSON) | Programmatic article create/read, files |
| Grover | `/grover` | Server-rendered Open Graph cards |

All five share the same models (`Article`, `Order`, `User`, `Currency`, …) and policies (`app/policies/`), but live in separate `app/controllers/<surface>/` directories and route draws (`config/routes/<surface>.rb`).

## Subsystems

### Article lifecycle

Drafts stay on the author's dashboard. Publishing fires `notify_for_first_published` and enqueues poster generation (`Articles::GeneratePosterJob`):

```
   draft ────────▶ publish ──▶ published
```

### Payment flow

`DistributeService` is the only place that knows the 10/50/40 split. Each emitted `Transfer` is linked back to its `Order` through the polymorphic `source` association (`Order has_many :transfers, as: :source`):

```
Order (paid) ──▶ Orders::DistributeJob ──▶ Orders::DistributeService
                                                    │
                                ┌───────────────────┼───────────────────┐
                                ▼                   ▼                   ▼
                             Transfer            Transfer            Transfer
                            (platform)           (author)         (early readers)
```

See [Value net](./value-net.md) for the rules.

### Background work

ActiveJob classes live under `app/jobs/`, grouped by domain: `articles/` (poster, locale, wallet — `Articles::CreateWalletJob`), `orders/` (per-order and batch distribution), `mixin_messages/` (outbound Mixin bot), `mixin_network_snapshots/` and `mixin_network_users/` (Mixin API polling), `currencies/` and `daily_statistics/` (rates and rollups), `users/` (`PrepareJob` setup), and `transfers/` (state polling, `Transfers::CacheStatsJob`). Workers run on **Solid Queue**, backed by a separate database. See [Reference → Background jobs](../reference/background-jobs.md).

### Persistence

PostgreSQL holds the application schema; Solid Queue/Cable/Cache each use their own SQLite database under `storage/` (e.g. `storage/production_queue.sqlite3`), all created and migrated by `bin/rails db:prepare`. Article bodies live in ActionText (`action_text_rich_texts`) with a `legacy_markdown_content` fallback for pre-migration rows; per-article `images`, `poster`, and `cover` live in `active_storage_blobs`; `ArticleSnapshot` records content history in PostgreSQL JSON.

The application is the **sole source of truth** for published article content — no external permanence-network upload runs on `Article#publish!` (the previous Arweave / Mirror.xyz integration has been removed). See [Explanation → Content storage](./content-storage.md) for the full contract.

### Frontend

**Hotwire** (Turbo + Stimulus) drives navigation and partial updates; **Tailwind CSS** handles styling; **esbuild** bundles JS through `esbuild.config.js` (entries under `app/javascript/`); **Bun** is the JS package manager.

## Cross-cutting concerns

**Authentication** runs through `SessionsController` (Mixin OAuth, Fennec, Twitter); API access tokens live on `AccessToken`. **Authorization** uses Pundit (`app/policies/`). **Internationalization** keys live in `config/locales/`, with the user-facing locale selectable via `LocaleController`. **Notifications** use the [Noticed](https://github.com/excid3/noticed) gem (delivery methods in `app/notifiers/delivery_methods/`); admin alerts route through `AdminNotificationService`. See [Reference → Notifiers](../reference/notifiers.md) for the full catalog.

## Configuration surface

| Concern | Where it lives |
|---------|----------------|
| Supported currencies and asset UUIDs | `config/settings.yml` → `supported_assets` |
| Whitelist (gated launch) | `config/settings.yml` → `whitelist` |
| Mixin OAuth URL | `config/settings.yml` → `mixin_oauth_path` |
| Mixin bot credentials | `config/credentials/*.yml.enc` under `quill_bot.*` |
| ActiveRecord encryption keys | `config/credentials/...` under `active_record_encryption.*` |
| Local overrides | Copy `config/settings.yml` to `config/settings.local.yml` |

Local development typically only needs `config/settings.local.yml` plus credentials.

## Where to look next

- [Value net](./value-net.md) — rules that drive `DistributeService`
- [Content storage](./content-storage.md) — where published content lives
- [Reference → Services](../reference/services.md) — command/query objects wiring the request flow
- [Reference → Background jobs](../reference/background-jobs.md) — every ActiveJob class and queue
- [AGENTS.md](../../AGENTS.md) — agent-oriented context