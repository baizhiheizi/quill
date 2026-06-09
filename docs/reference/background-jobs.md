# Background jobs reference

> **30-second summary:** ActiveJob classes live under `app/jobs/<domain>/`. They run on Solid Queue (separate database) with three priority lanes — `critical`, `default`, and `low`. Jobs are grouped by the model they primarily touch; cron-style polling jobs live under `monitor_*` / `sync_*` / `cache_*` and are intended to be triggered by a recurring schedule.

## Queues

| Queue | Used by | Notes |
|-------|---------|-------|
| `critical` | Order processing, Mixin and Arweave polling jobs | Touch user-visible money or settlement; small backlogs only |
| `default` | One-shot user-facing work (notifications, wallet provisioning) | Default for ad-hoc enqueues |
| `low` | Batch / cron work (rollups, batch uploads) | Safe to run during quiet periods |

Adjust lane assignments in `config/queue.yml` (Solid Queue config). The runner is `bin/jobs`, which `bin/dev` starts for you.

## Job catalog

### `articles/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `BatchUploadToArweaveJob` | `low` | Hourly batch that re-uploads recently updated published articles to Arweave |
| `CreateWalletJob` | `default` | Provisions a Mixin wallet for a newly connected user |
| `DetectLocaleJob` | `default` | Auto-detects the locale of an article based on its content |
| `GeneratePosterJob` | `low` | Renders the social-share poster image for an article |
| `NotifyForFirstPublishedJob` | `default` | Fires the "first publication" notification to subscribers |
| `UploadToArweaveJob` | `default` | One-shot Arweave upload for a single article |

### `orders/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `DistributeJob` | `critical` | Runs `Orders::DistributeService` for a single paid order (by trace id) |
| `BatchDistributeJob` | `low` | Sweeps `Order.paid` and enqueues per-order workers |
| `NotifyJob` | `default` | Sends the post-purchase notification |
| `UpdateCacheJob` | `default` | Refreshes per-author / per-article cached counters |
| `CacheHistoryTickerJob` | `low` | Maintains the historical ticker shown on article pages |

The `DistributeJob` is the entry point into the value-net pipeline; see [Explanation → Value net](../explanation/value-net.md).

### `collections/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `NotifySubscribersJob` | `default` | Notifies subscribers when an article is added to a collection |

### `currencies/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `SyncJob` | `low` | Polls the Mixin network for updated asset rates |

### `daily_statistics/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `GenerateJob` | `low` | Rolls up `DailyStatistic` rows for the previous day |
| `CacheStatsJob` | `low` | Warms the dashboard stats cache |

### `mixin_messages/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `ProcessJob` | `critical` | Processes inbound Mixin bot messages |
| `SendJob` | `default` | Sends an outbound Mixin message |

### `mixin_network_snapshots/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `MonitorJob` | `low` | Polls for new network snapshots |
| `ProcessJob` | `critical` | Reconciles a snapshot against pending transfers |

### `mixin_network_users/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `InitializePinJob` | `default` | Initialises the Mixin PIN for a user |
| `UpdateAvatarJob` | `default` | Refreshes the user's avatar from the Mixin profile |

### `users/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `ImportArticlesFromMirrorJob` | `default` | Pulls a user's mirrored articles from a configured mirror source |
| `PrepareJob` | `default` | One-time preparation work after a user signs up |

### `arweave_transactions/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `BatchAcceptJob` | `low` | Polls Arweave for accepted transactions and updates `ArweaveTransaction` rows |

### `transfers/`

| Job | Queue | Purpose |
|-----|-------|---------|
| `MonitorJob` | `low` | Polls Mixin for transfer status |
| `ProcessJob` | `critical` | Applies a confirmed transfer (e.g. marks the corresponding `Order` as paid) |

## Adding a new job

1. Place the file under `app/jobs/<domain>/<verb>_job.rb`.
2. Inherit from `ApplicationJob` and call `queue_as :default` (or `:critical` / `:low` as appropriate).
3. Implement `#perform(*args)`; keep side effects in this method.
4. Schedule it from a service or model callback with `perform_later` rather than `perform_now`.
5. Add or extend a test under `test/jobs/<domain>/`.
6. Add a row to the table above so it is discoverable.