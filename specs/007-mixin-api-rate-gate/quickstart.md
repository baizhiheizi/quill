# Quickstart: Validating Global Mixin API Rate Gating

Manual and automated validation for the rate gate. Assumes local dev with `bin/dev` (Rails + `mixin_blaze` + jobs).

## Prerequisites

```bash
bundle install
bin/rails db:prepare
```

Ensure Mixin bot credentials are configured (development credentials + `config/settings.local.yml`).

## Automated checks (run after implementation)

```bash
bin/rubocop app/libs/mixin_api/ test/libs/mixin_api/
bin/rails test test/libs/mixin_api/
bin/rails test test/models/mixin_network_snapshot_test.rb test/models/transfer_test.rb
bin/rails zeitwerk:check
```

All gate tests MUST pass without network access (stubbed client).

## Unit validation — gate behavior

Run gate tests and confirm output covers:

```bash
bin/rails test test/libs/mixin_api/gate_test.rb -v
bin/rails test test/libs/mixin_api/rate_limited_client_test.rb -v
```

Expected: proactive spacing, `retry_after` honor, exponential backoff cap, interactive re-raise, background retry success, non-throttle pass-through.

## Story 1 — Payment ingestion survives 429 (P1)

**Simulate in console** (development only):

```ruby
# Temporarily tighten limit to force throttling
Settings.mixin_api_gate.scopes.quill_bot.min_interval_ms = 5000

# In another terminal, watch mixin_blaze logs while snapshot poll runs
# Expect: [MixinApi::Gate] warn lines, worker stays alive, no unhandled RateLimitError stack trace
```

**Restore** sensible `min_interval_ms` after test.

**Production-like check**: If staging hits real 429, confirm `mixin_blaze` process does not exit and snapshots resume within 5 minutes (SC-002).

## Story 2 — Global gate across callers (P2)

1. Start `bin/dev` with active pending transfers and snapshot polling.
2. Set aggressive `min_interval_ms` (e.g. 1000) for `quill_bot` in `settings.local.yml`; restart dev.
3. Observe logs: snapshot polls and transfer API calls interleave without burst of raw 429 errors from Mixin.
4. Confirm notification jobs (enqueue a test notifier with Mixin delivery) complete after deferral, not permanent failure.

## Story 3 — Transfers retry after 429 (P2)

1. Create an unprocessed transfer fixture in test DB.
2. Run gate unit test proving transfer path uses wrapped client (integration via `Transfer#process_safe_transfer!` with stubbed 429 then success).
3. Confirm transfer remains `processed_at: nil` after 429 and completes after limit clears.

## Story 4 — Operator visibility (P3)

1. Trigger a throttle (tight `min_interval_ms` or stubbed 429 in dev console).
2. Grep logs: `grep 'MixinApi::Gate' log/development.log`
3. Confirm each line includes `scope=`, `verb=`, `path=`, `backoff=` and no tokens/secrets.

## Story 5 — Interactive OAuth path (FR-009)

1. Attempt Mixin login while gate is under heavy throttle (`interactive_max_wait_seconds: 1` in local settings).
2. Confirm user sees a retryable error (flash or redirect), not 500 or hung request.

## Disable gate (emergency)

Set in `config/settings.local.yml`:

```yaml
mixin_api_gate:
  enabled: false
```

Restart processes. Confirm API calls bypass gate (no `[MixinApi::Gate]` log lines). Re-enable after incident.

## Success criteria spot-check

| Criterion | How to verify |
| --- | --- |
| SC-001 | `mixin_blaze` runs 24h+ without restart from RateLimitError (production/staging observation) |
| SC-002 | Compare snapshot count before/after simulated throttle window — no permanent gap |
| SC-003 | Gate tests: 429 then success within bounded retries |
| SC-005 | Transfer tests: duplicate `create_safe_transfer` not called after successful check |
| SC-006 | Log grep finds incident start/end within 2 minutes |

See [contracts/mixin-api-gate.md](./contracts/mixin-api-gate.md) and [data-model.md](./data-model.md) for interface details.
