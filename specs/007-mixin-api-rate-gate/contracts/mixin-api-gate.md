# Phase 1 Contracts: Global Mixin API Rate Gating

Internal infrastructure contract — no public HTTP API. Defines the gate module interface, client wrapper contract, factory integration points, and error-handling guarantees implementers must preserve.

## 1. `MixinApi::Gate` module contract

**Location**: `app/libs/mixin_api/gate.rb`

```ruby
# Public interface (class methods)
MixinApi::Gate.acquire(scope, mode: :background)  # blocks until request slot available; returns nothing
MixinApi::Gate.record_throttle(scope, error)       # RateLimitError only; sets backoff_until
MixinApi::Gate.release_success(scope)              # resets backoff_attempt, updates last_request_at
MixinApi::Gate.backoff_remaining(scope)            # seconds until scope accepts requests (for logging/tests)
MixinApi::Gate.enabled?                            # reads Settings.mixin_api_gate.enabled
```

**Invariants**:

- MUST only accept `MixinBot::RateLimitError` (or any error where `error.throttle?` is true) in `record_throttle`; raising on other types is a programming error.
- MUST honor `error.retry_after` when present (Integer seconds from gem); otherwise compute exponential backoff from `Settings.mixin_api_gate.backoff`.
- MUST use `Rails.cache` for `backoff_until` and `last_request_at` so `mixin_blaze`, Puma, and Solid Queue workers share state.
- MUST use a per-scope `Mutex` (class-level hash) for thread safety within a process.
- MUST log one warn line per `record_throttle` call (see `data-model.md` Rate-Limit Event).
- MUST NOT log credentials, JWTs, PINs, or request bodies.

**Mode contract**:

| Mode | On sustained 429 | Use case |
| --- | --- | --- |
| `:background` | Retry indefinitely (backoff capped per attempt, no overall cap) | `mixin_blaze` threads, Solid Queue jobs |
| `:interactive` | Wait up to `interactive_max_wait_seconds`, then re-raise `RateLimitError` | OAuth login, synchronous controller actions |

## 2. `MixinApi::RateLimitedClient` contract

**Location**: `app/libs/mixin_api/rate_limited_client.rb`

- MUST delegate `get`, `post`, `fetch_get`, `fetch_post`, `fetch_post_array` to inner client wrapped in acquire/success/throttle cycle.
- MUST re-raise `MixinBot::RateLimitError` after `:interactive` max wait exhausted (unchanged error object).
- MUST NOT rescue or retry non-throttle errors.
- MUST NOT add retries for `MixinBot.retryable?` errors — those remain caller/Faraday responsibility.

## 3. `MixinApi.wrap` factory contract

**Location**: `app/libs/mixin_api.rb`

```ruby
MixinApi.wrap(api, scope:, mode: :background) # => MixinBot::API (same class, swapped client)
```

- When `Gate.enabled?` is false, MUST return `api` unchanged.
- MUST replace `api.client` with `RateLimitedClient` via `api.instance_variable_set(:@client, ...)` or equivalent — no subclass of `MixinBot::API`.
- `scope` MUST be one of: `:quill_bot`, `:revenue_bot`, or `"user:#{uuid}"`.

## 4. Factory integration contract (only three edit sites)

| File | Change | Scope | Default mode |
| --- | --- | --- | --- |
| `app/libs/quill_bot.rb` | Wrap API after `MixinBot::API.new` | `:quill_bot` | `:background` |
| `app/libs/revenue_bot.rb` | Wrap API after `MixinBot::API.new` | `:revenue_bot` | `:background` |
| `app/models/mixin_network_user.rb` | Wrap in `#mixin_api` | `"user:#{uuid}"` | `:background` |

**Out of scope**: Blaze WebSocket (`start_blaze_connect`), direct `MixinBot::Client.new` usage (none in app today).

**Optional mode override**: Controllers that perform synchronous OAuth MAY call `MixinApi.wrap(QuillBot.api, scope: :quill_bot, mode: :interactive)` at the call site — only if the default `:background` on the singleton is inappropriate. Prefer wrapping once in `Authenticatable` concern with `:interactive` for `oauth_token`/`me` only if needed; document in tasks.

## 5. Caller preservation contract

Existing rescue blocks MUST continue to work for non-throttle errors:

- `MixinNetworkSnapshot.poll` — keep rescuing `ResponseError`, `HttpError`, `RequestError`; **add** `RateLimitError` as defense-in-depth (gate should absorb in normal operation).
- `Transfer.process_all!` — `UserNotFoundError`, `InsufficientBalanceError` unchanged.
- `Transfer#check!` — `NotFoundError` unchanged.

Gate MUST NOT convert throttle errors into generic `StandardError` or swallow business errors.

## 6. Configuration contract

**File**: `config/settings.yml` → `mixin_api_gate` (see `research.md` §6)

- `enabled` — boolean, default `true`
- `scopes.<name>.min_interval_ms` — positive integer
- `backoff.initial_seconds`, `max_seconds`, `multiplier` — positive numbers
- `interactive_max_wait_seconds` — positive integer

Missing scope config falls back to `scopes.user` defaults.

## 7. Test contract

**Files**: `test/libs/mixin_api/gate_test.rb`, `test/libs/mixin_api/rate_limited_client_test.rb`

Must cover:

1. Proactive spacing — two rapid calls enforce `min_interval_ms` delay.
2. `RateLimitError` with `retry_after: 2` — waits ≥2s before retry.
3. `RateLimitError` without `retry_after` — exponential backoff increases per attempt, capped at `max_seconds`.
4. `:interactive` mode — re-raises after max wait.
5. `:background` mode — succeeds after transient 429.
6. Non-throttle error (`NotFoundError`) — passes through on first call, no retry.
7. `Gate.enabled? false` — wrap returns unmodified API.

Construct errors via `MixinBot::RateLimitError.new(...)` or `MixinBot::Client::ErrorMapper.build(MixinBot::RateLimitError, ...)` to match gem shape.
