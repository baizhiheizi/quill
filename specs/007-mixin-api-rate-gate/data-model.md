# Phase 1 Data Model: Global Mixin API Rate Gating

No database schema changes. All entities are runtime/cache state and thin wrappers around existing `MixinBot::API` instances.

## Credential Scope

Identifies an independent rate budget on the Mixin side.

| Attribute | Type | Description |
| --- | --- | --- |
| `key` | String | Stable scope id: `quill_bot`, `revenue_bot`, or `user:<uuid>` |
| `client_id` | UUID | Mixin app/session id for the scope (from `api.client_id`) |
| `min_interval_ms` | Integer | Minimum ms between outbound requests (proactive throttle) |
| `mode` | Symbol | `:background` (retry until success) or `:interactive` (bounded wait, then re-raise) |

**Relationships**: One scope → many deferred requests (serialized through the gate). Scopes are independent — `revenue_bot` backoff does not block `quill_bot`.

## Gate State (per scope, in `Rails.cache`)

Ephemeral coordination state; not persisted to PostgreSQL.

| Cache key suffix | Type | Description |
| --- | --- | --- |
| `backoff_until` | Time (ISO8601) | No requests until this instant after a `RateLimitError` |
| `last_request_at` | Time (ISO8601) | Timestamp of last admitted request (proactive spacing) |
| `backoff_attempt` | Integer | Consecutive throttle count for exponential backoff (resets on success) |

**TTL**: Keys expire after `max_backoff_seconds + 60` to avoid stale cache entries.

**Validation**: `backoff_until` MUST be monotonic non-decreasing while throttled (later 429 extends, never shortens). `backoff_attempt` resets to 0 on any successful request.

## Rate-Limited Client

Wraps `MixinBot::Client`; same public interface (`get`, `post`, `fetch_get`, `fetch_post`, `fetch_post_array`).

| Attribute | Description |
| --- | --- |
| `inner` | Original `MixinBot::Client` |
| `scope` | Credential Scope key |
| `mode` | `:background` or `:interactive` |

**Behavior**: Every HTTP method calls `MixinApi::Gate#acquire(scope)` → execute → `Gate#release_success(scope)`; on `RateLimitError`, `Gate#record_throttle(scope, error)` and retry per mode rules.

## Rate-Limited API

Thin factory output: `MixinBot::API` instance with `@client` replaced by Rate-Limited Client. All other methods (`utils`, `client_id`, `encode_raw_transaction`, Blaze helpers) unchanged.

## Rate-Limit Event (log record, not persisted)

Emitted on each throttle; satisfies observability requirements.

| Field | Source |
| --- | --- |
| `scope` | Credential Scope `key` |
| `verb` | `error.verb` |
| `path` | `error.path` (query stripped for logs) |
| `backoff_seconds` | Applied delay |
| `retry_after` | `error.retry_after` if present |
| `occurred_at` | `Time.current` |

## Error Pass-Through Matrix

Gate MUST NOT swallow or transform these — callers keep existing rescue logic:

| Error class | `retryable?` / `throttle?` | Gate action |
| --- | --- | --- |
| `MixinBot::RateLimitError` | `throttle?` | Backoff + retry |
| `MixinBot::ServerError` | `retryable?` | Pass through |
| `MixinBot::TransientError` | `retryable?` | Pass through |
| `MixinBot::ResponseError` (5xx) | `retryable?` | Pass through |
| `MixinBot::NotFoundError` | — | Pass through |
| `MixinBot::UserNotFoundError` | — | Pass through |
| `MixinBot::InsufficientBalanceError` | — | Pass through |
| `MixinBot::ValidationError`, `ConflictError`, `TransferError`, `PinError`, etc. | — | Pass through |
| `MixinBot::HttpError`, `RequestError` | — | Pass through |
| `Faraday::TimeoutError`, `Faraday::ConnectionFailed` | via `MixinBot.retryable?` | Pass through (Faraday retry in gem) |

## Configuration Entity (`Settings.mixin_api_gate`)

Defined in `config/settings.yml`; see `research.md` §6 for fields. `enabled: false` bypasses gate (wrap returns raw API) for emergency disable.
