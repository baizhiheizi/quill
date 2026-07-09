# Background jobs reference

> **30-second summary:** ActiveJob classes live under `app/jobs/<domain>/` and run on Solid Queue (separate database) with three priority lanes — `critical`, `default`, and `low`. Jobs are grouped by the model they primarily touch; cron-style polling jobs live under `monitor_*` / `sync_*` / `cache_*` and are intended to be triggered by a recurring schedule.

## Queues

| Queue | Used by | Notes |
|-------|---------|-------|
| `critical` | Order processing, Mixin polling jobs | Touch user-visible money or settlement; small backlogs only |
| `default` | One-shot user-facing work (notifications, wallet provisioning) | Default for ad-hoc enqueues |
| `low` | Batch / cron work (rollups, batch uploads) | Safe to run during quiet periods |

Adjust lane assignments in `config/queue.yml` (Solid Queue config). The runner is `bin/jobs`, which `bin/dev` starts for you.

## Job catalog

| Domain | Job | Queue | Purpose |
|--------|-----|-------|---------|
| `articles/` | `DetectLocaleJob` | `default` | Auto-detects an article's locale from its content |
| `articles/` | `GeneratePosterJob` | `low` | Renders the social-share poster image for an article |
| `articles/` | `NotifyForFirstPublishedJob` | `default` | Fires the "first publication" notification to subscribers |
| `orders/` | `DistributeJob` | `critical` | Runs `Orders::DistributeService` for a single paid order (by trace id) — entry point into the value-net pipeline; see [Explanation → Value net](../explanation/value-net.md) |
| `orders/` | `BatchDistributeJob` | `low` | Sweeps `Order.paid` and enqueues per-order workers |
| `orders/` | `NotifyJob` | `default` | Sends the post-purchase notification |
| `orders/` | `UpdateCacheJob` | `low` | Refreshes per-author / per-article cached counters |
| `orders/` | `CacheHistoryTickerJob` | `low` | Maintains the historical ticker shown on article pages |
| `collections/` | `NotifySubscribersJob` | `default` | Notifies subscribers when an article is added to a collection |
| `daily_statistics/` | `GenerateJob` | `low` | Rolls up `DailyStatistic` rows for the previous day |
| `mixin_messages/` | `ProcessJob` | `critical` | Processes inbound Mixin bot messages |
| `mixin_messages/` | `SendJob` | `default` | Sends an outbound Mixin message |
| `mixin_network_snapshots/` | `MonitorJob` | `low` | Polls for new network snapshots |
| `mixin_network_snapshots/` | `ProcessJob` | `critical` | Reconciles a snapshot against pending transfers |
| `mixin_network_users/` | `InitializePinJob` | `default` | Initialises the Mixin PIN for a user |
| `mixin_network_users/` | `UpdateAvatarJob` | `default` | Refreshes the user's avatar from the Mixin profile |
| `users/` | `PrepareJob` | `default` | One-time preparation work after a user signs up |
| `transfers/` | `ProcessJob` | `critical` | Processes a single unprocessed transfer by `trace_id` (enqueued on create) |
| `transfers/` | `ProcessPendingJob` | `critical` | Minute-cadence sweep of eligible unprocessed transfers |
| `transfers/` | `MonitorJob` | `low` | Alerts when transfers remain unprocessed longer than 12 hours |
| `transfers/` | `CacheStatsJob` | `low` | Refreshes per-transfer statistics used by the author dashboard |

## Adding a new job

1. Place the file under `app/jobs/<domain>/<verb>_job.rb`; inherit from `ApplicationJob` and call `queue_as :default` (or `:critical` / `:low` as appropriate).
2. Implement `#perform(*args)` and keep side effects there.
3. Schedule from a service or model callback with `perform_later` — never `perform_now`.
4. Add or extend a test under `test/jobs/<domain>/`.
5. Add a row to the catalog above so it is discoverable.