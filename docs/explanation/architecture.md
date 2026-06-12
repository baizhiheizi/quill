# Architecture

> **30-second summary:** Quill is a Rails 8 monolith that serves four surfaces — public web, author **dashboard**, **admin**, and a JSON **API** — from one set of models. Long-running work (payment settlement, Mixin bot messages) is delegated to ActiveJob workers backed by **Solid Queue**. Real-time updates flow over **Solid Cable**. The hot path is `Article → Order → Orders::DistributeService → Transfer` (one `Transfer` per recipient, linked back to the `Order` through a polymorphic `source` association).

## Surfaces

| Surface | Mount point | Purpose |
|---------|-------------|---------|
| Public web | `/` | Reading articles, browsing tags, OAuth login, public collections |
| Dashboard | `/dashboard` (subdomain or route) | Author-facing authoring and earnings UI |
| Admin | `/admin` | Internal moderation, payments, statistics, KYC reviews |
| API | `/api` (JSON-only) | Programmatic article create/read, file access |
| MVM | `/mvm` | MVM-specific routing (Mixin Virtual Machine) |
| Grover | `/grover` | Server-rendered social cards (Open Graph images) |

All five share the same models (`Article`, `Order`, `User`, `Currency`, …) and policies (`app/policies/`) but are kept in separate `app/controllers/<surface>/` directories and route draws (`config/routes/<surface>.rb`).

## Subsystems

### Article lifecycle

```
                  ┌──────────────┐
   draft ────────▶│   publish    │──▶ published
                  └──────────────┘
```

- **Drafts** stay on the author's dashboard.
- **Publishing** fires `notify_for_first_published` and triggers poster generation (`Articles::GeneratePosterJob`).

### Payment flow

The hot path that real money follows:

```
Order (paid)  ──▶  Orders::DistributeJob  ──▶  Orders::DistributeService
                                                       │
                                       ┌───────────────┼───────────────┐
                                       ▼               ▼               ▼
                                  Transfer        Transfer         Transfer
                                 (platform)       (author)         (early readers)
```

`DistributeService` is the only place that knows the 10/50/40 split. See [Value net](./value-net.md) for the rules.

### Background work

ActiveJob classes live under `app/jobs/`, grouped by domain:

- `articles/` — poster generation, locale detection, and article wallet provisioning (`Articles::CreateWalletJob`).
- `orders/` — per-order and batch distribution.
- `mixin_messages/` — outbound Mixin bot messages.
- `mixin_network_snapshots/`, `mixin_network_users/` — Mixin API polling.
- `currencies/`, `daily_statistics/` — rate snapshots and rollups.
- `users/` — one-time setup (`PrepareJob`).
- `transfers/` — transfer-state polling and stats caching (`Transfers::CacheStatsJob`).

Workers run via **Solid Queue**, which is backed by a separate database. See [Reference → Background jobs](../reference/background-jobs.md).

### Persistence

- PostgreSQL holds the application schema.
- A second PostgreSQL database holds Solid Queue, Solid Cable, and Solid Cache data — see `config/database.yml` for connection names.
- Article bodies live in ActiveStorage (`active_storage_blobs`, `active_storage_attachments`).
- `ArticleSnapshot` records capture content history in PostgreSQL JSON.

### Frontend

- **Hotwire** (Turbo + Stimulus) drives navigation and partial updates without a heavy JS framework.
- **Tailwind CSS** handles styling.
- **esbuild** bundles JS through `esbuild.config.js`. Entry points live under `app/javascript/`.
- **Bun** is the JS package manager.

## Cross-cutting concerns

- **Authentication** flows through `SessionsController` and supports Mixin OAuth, Fennec, MVM wallet, and Twitter. Access tokens for the API are stored on `AccessToken`.
- **Authorization** uses Pundit (`app/policies/`).
- **Internationalization** keys live in `config/locales/`. The user-facing locale is selectable via `LocaleController` and per-request routing.
- **Notifications** use the [Noticed](https://github.com/excid3/noticed) gem, with delivery methods in `app/notifiers/delivery_methods/`. Admin alerts route through `AdminNotificationService`.

## Configuration surface

| Concern | Where it lives |
|---------|----------------|
| Supported currencies and asset UUIDs | `config/settings.yml` → `supported_assets` |
| Whitelist (gated launch) | `config/settings.yml` → `whitelist` |
| Mixin OAuth URL | `config/settings.yml` → `mixin_oauth_path` |
| Mixin bot credentials | `config/credentials/development.yml.enc` (and equivalents) under `quill_bot.*` |
| ActiveRecord encryption keys | `config/credentials/...` under `active_record_encryption.*` |
| Local overrides | Copy `config/settings.yml` to `config/settings.local.yml` and edit |

Local development typically only needs `config/settings.local.yml` plus credentials.

## Where to look next

- [Value net](./value-net.md) — the rules that drive `DistributeService`.
- [Reference → Services](../reference/services.md) — the command/query objects that wire subsystems together.
- [Reference → Background jobs](../reference/background-jobs.md) — every ActiveJob class and its queue.
- [AGENTS.md](../../AGENTS.md) — agent-oriented context that complements this page.