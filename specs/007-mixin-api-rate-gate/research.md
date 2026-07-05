# Phase 0 Research: Global Mixin API Rate Gating

No `NEEDS CLARIFICATION` markers in `spec.md`. This document resolves technical approach questions, with emphasis on **honoring `mixin_bot` gem error types** and keeping the design minimal.

## 1. What does `mixin_bot` expose for errors, and which matter for a gate?

**Decision**: The gate handles only **`MixinBot::RateLimitError`** (HTTP 429 / errcode 429). It uses the gem's structured API:

| Method / flag | Meaning | Gate use |
| --- | --- | --- |
| `RateLimitError#throttle?` | `true` for 429 | Primary detection (prefer over `is_a?` alone for forward-compat) |
| `RateLimitError#retry_after` | Parsed from `Retry-After` header when present | Backoff duration (seconds) |
| `RateLimitError#verb`, `#path` | Request metadata | Structured logging (no secrets) |
| `MixinBot.retryable?(error)` | `true` for Faraday timeout/connection + `#retryable?` subclasses | **Not used by gate** — covers `ServerError`, `TransientError`, `ResponseError` (5xx), not `RateLimitError` |

All other `MixinBot::APIError` subclasses (`NotFoundError`, `InsufficientBalanceError`, `ValidationError`, `UserNotFoundError`, etc.) and non-API errors (`HttpError`, `RequestError`, `ArgumentError`) **pass through unchanged**.

**Rationale**: Inspected `mixin_bot-2.3.0/lib/mixin_bot/errors.rb` and `client/error_mapper.rb`. `RateLimitError` is the only error with `throttle? => true`. `MixinBot.retryable?` explicitly excludes rate limits — retry policy for 429 belongs in our gate, not in generic retry helpers. Business errors must reach existing caller rescue blocks (`Transfer#check!` rescues `NotFoundError`, etc.).

**Alternatives considered**:
- *Central retry for all `MixinBot.retryable?` errors*: rejected — duplicates Faraday retry in `Client` and blurs responsibility; transfer/snapshot callers already handle domain errors.
- *Rescue `RateLimitError` only in `MixinNetworkSnapshot.poll`*: rejected — symptom fix; transfer loop, jobs, and OAuth would still compete and hit 429.

## 2. Why did snapshot polling crash on 429?

**Decision**: `MixinNetworkSnapshot.poll` rescues `MixinBot::ResponseError`, `HttpError`, `RequestError` but **not** `RateLimitError`. `RateLimitError < APIError`, not `ResponseError`. Unhandled 429 falls into the generic `StandardError` branch, which **re-raises in production** (`raise e if Rails.env.production?`).

**Rationale**: Direct read of `app/models/mixin_network_snapshot.rb:98–114`. The global gate prevents 429 from reaching callers in background mode; poll's rescue list should still add `RateLimitError` as defense-in-depth.

## 3. Where to intercept — one wrapper, three entry points

**Decision**: Wrap **`MixinBot::Client`** (HTTP layer), not individual API methods. Replace `@client` on wrapped `MixinBot::API` instances at three factories only:

| Entry point | Scope key | Callers |
| --- | --- | --- |
| `QuillBot.api` | `quill_bot` (`client_id`) | Snapshots, transfers, OAuth, notifications, orders, admin |
| `RevenueBot.api` | `revenue_bot` | Revenue-bot notifiers |
| `MixinNetworkUser#mixin_api` | `user:<uuid>` | PIN, profile sync, per-wallet ops |

`start_blaze_connect` (WebSocket) bypasses `Client` — out of scope; Blaze traffic is separate from REST rate limits.

**Rationale**: `MixinBot::API` exposes `attr_reader :client`; all REST endpoints delegate to `client.get/post/fetch_*`. Wrapping client covers every REST call with ~3 factory edits vs. dozens of call sites.

**Alternatives considered**:
- *`MixinApi::Gate.call(scope) { ... }` at every call site*: rejected — high churn, easy to miss a path.
- *Monkey-patch `MixinBot::Client` globally*: rejected — harder to test and scope per credential.

## 4. Cross-process coordination (mixin_blaze + jobs + web)

**Decision**: Store per-scope **`backoff_until`** and **`last_request_at`** in **`Rails.cache`** (Solid Cache). In-process `Mutex` per scope for thread safety within `mixin_blaze` (snapshot poll + transfer threads).

**Rationale**: `bin/mixin_blaze` runs snapshot polling and transfer processing in parallel threads; Solid Queue and Puma are separate processes. In-memory state alone cannot global-gate across processes. Cache keys like `mixin_api_gate:quill_bot:backoff_until` are sufficient for reactive backoff; `last_request_at` enforces proactive minimum interval.

**Alternatives considered**:
- *In-process only*: rejected — web + blaze + jobs would each maintain independent budgets, still exceeding Mixin quota.
- *New DB table*: rejected — no persistence requirement; cache TTL matches backoff windows.

## 5. Proactive vs reactive strategy (concise)

**Decision**: Two mechanisms, one class:

1. **Proactive**: Before each request, sleep until `now >= last_request_at + min_interval` for the scope (configurable per scope, default ~8 req/s for `quill_bot`).
2. **Reactive**: On `RateLimitError`, set `backoff_until = now + delay` where `delay = retry_after || exponential_backoff(attempt)` capped at `max_backoff_seconds`; all threads/processes wait before next request on that scope.

Background callers (`:background` mode): retry inside gate until success. Interactive callers (`:interactive` mode): wait at most `interactive_max_wait_seconds`, then re-raise `RateLimitError` for controller to show retryable message.

**Rationale**: Matches spec FR-003–FR-005. Honors `retry_after` when Mixin sends it (gem already parses header into `RateLimitError#retry_after`).

**Alternatives considered**:
- *Reactive-only (429 then backoff)*: rejected in spec assumptions — snapshot poll at 10 req/s guarantees 429 under load.
- *External rate-limit gem (e.g. Sidekiq limiter)*: rejected — adds dependency; ~80 lines of gate logic fits Quill conventions.

## 6. Configuration surface

**Decision**: Add `config/settings.yml` section `mixin_api_gate` (overridable in `settings.local.yml`):

```yaml
mixin_api_gate:
  enabled: true
  scopes:
    quill_bot:
      min_interval_ms: 125
    revenue_bot:
      min_interval_ms: 200
    user:
      min_interval_ms: 250
  backoff:
    initial_seconds: 1
    max_seconds: 60
    multiplier: 2
  interactive_max_wait_seconds: 5
```

**Rationale**: Spec FR-011; no credentials in settings; tune without deploy.

## 7. Logging & observability

**Decision**: One `Rails.logger.warn` line per rate-limit event:

```
[MixinApi::Gate] scope=quill_bot throttle verb=GET path=/safe/snapshots backoff=2.0s retry_after=nil
```

No request bodies, tokens, or PIN data.

**Rationale**: Spec FR-010 / SC-006; minimal structured text, no new gems.

## 8. Testing approach

**Decision**: Unit tests in `test/libs/mixin_api/` with a fake `MixinBot::Client` that raises `MixinBot::RateLimitError.build(...)` on Nth call. Stub `Rails.cache` where cross-process behavior matters. Extend `MixinNetworkSnapshot` test only if defense-in-depth rescue is added. No live Mixin calls.

**Rationale**: Constitution II; matches `test/support/quill_bot_stub.rb` patterns.

**Alternatives considered**: Integration test against real Mixin — rejected per project testing rules.
