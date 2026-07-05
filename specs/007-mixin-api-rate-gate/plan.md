# Implementation Plan: Global Mixin API Rate Gating

**Branch**: `007-mixin-api-rate-gate` | **Date**: 2026-07-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-mixin-api-rate-gate/spec.md`  
**User constraint**: Honor `mixin_bot` gem error types; keep design concise.

## Summary

Quill's Mixin REST traffic (`QuillBot`, `RevenueBot`, per-user wallets) competes across `mixin_blaze` threads, Solid Queue jobs, and web requests. Unhandled `MixinBot::RateLimitError` (429) crashes snapshot polling in production because `RateLimitError` is not in the poll loop's rescue list.

**Approach**: Add two small classes under `app/libs/mixin_api/` — `Gate` (cache-backed per-scope throttle + backoff) and `RateLimitedClient` (wraps `MixinBot::Client`). Wire at **three factories only** via `MixinApi.wrap`. The gate handles **only** `error.throttle?` (`RateLimitError`); all other gem error types pass through unchanged so existing caller rescue logic remains valid.

## Technical Context

**Language/Version**: Ruby 4.0.5, Rails 8.1.x  
**Primary Dependencies**: `mixin_bot` 2.3.0 (Faraday client, structured `APIError` hierarchy)  
**Storage**: `Rails.cache` (Solid Cache) for cross-process gate state; no DB migration  
**Testing**: Minitest — `test/libs/mixin_api/` with stubbed client raising gem error classes  
**Target Platform**: Linux server (`bin/mixin_blaze`, Puma, Solid Queue workers)  
**Project Type**: Rails monolith — infrastructure library in `app/libs/`  
**Performance Goals**: Stay under Mixin 429 threshold proactively; ≤125ms average spacing default for `quill_bot` (~8 req/s)  
**Constraints**: No new gems; no changes to revenue math or payment idempotency keys; Blaze WebSocket out of scope  
**Scale/Scope**: ~3 factory edits, ~2 new lib files, ~2 test files, 1 settings block, 1 defensive rescue line

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Reference: `.specify/memory/constitution.md` (Quill v1.0.0)

- [x] **I. Code Quality**: Extends `app/libs/` pattern (`QuillBot`, `RevenueBot`); frozen string literal; no parallel HTTP stack; RuboCop on touched Ruby
- [x] **II. Testing**: Unit tests for gate + client wrapper; stub `MixinBot::RateLimitError` via gem constructors; no live Mixin calls
- [x] **III. UX Consistency**: `:interactive` mode re-raises `RateLimitError` for OAuth — add i18n flash string only if controller lacks retryable message
- [x] **IV. Performance**: Gate adds intentional sleep on hot payment path — acceptable tradeoff vs. 429 crash; no `bin/benchmark` required (infrastructure throttle, not query change)

> No violations — **Complexity Tracking** table empty.

**Post-design re-check (Phase 1)**: All gates still pass. Design stays within three factory integration points; no new jobs or UI surfaces.

## Project Structure

### Documentation (this feature)

```text
specs/007-mixin-api-rate-gate/
├── plan.md              # This file
├── research.md          # Phase 0 — mixin_bot error analysis, wrapper placement
├── data-model.md        # Phase 1 — scope, cache keys, error matrix
├── quickstart.md        # Phase 1 — validation guide
├── contracts/
│   └── mixin-api-gate.md
└── tasks.md             # Phase 2 (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
app/libs/
├── mixin_api.rb                    # MixinApi.wrap factory
└── mixin_api/
    ├── gate.rb                     # acquire / record_throttle / release_success
    └── rate_limited_client.rb      # Client wrapper

app/libs/quill_bot.rb               # wrap on build
app/libs/revenue_bot.rb             # wrap on build
app/models/mixin_network_user.rb    # wrap in #mixin_api
app/models/mixin_network_snapshot.rb # add RateLimitError to rescue (defense-in-depth)

config/settings.yml                 # mixin_api_gate section

test/libs/mixin_api/
├── gate_test.rb
└── rate_limited_client_test.rb
```

**Structure Decision**: Single-project Rails layout. Gate lives in `app/libs/mixin_api/` alongside existing bot modules — no service-object ceremony beyond `.call`-style class methods on `Gate`.

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| — | — | — |

## Phase 0: Research

Complete — see [research.md](./research.md).

**Key decisions**:
1. Only `RateLimitError` / `#throttle?` handled by gate; `MixinBot.retryable?` errors pass through.
2. Wrap `MixinBot::Client` at three API factories.
3. Cross-process state via `Rails.cache`.
4. Root cause of production crash: `RateLimitError` not rescued in `MixinNetworkSnapshot.poll`.

## Phase 1: Design

Complete — see [data-model.md](./data-model.md), [contracts/mixin-api-gate.md](./contracts/mixin-api-gate.md), [quickstart.md](./quickstart.md).

### Implementation sketch (for `/speckit-tasks`)

```ruby
# app/libs/mixin_api/rate_limited_client.rb — core loop (~25 lines)
def get(...)
  loop do
    MixinApi::Gate.acquire(@scope, mode: @mode)
    return @inner.get(...)
  rescue MixinBot::RateLimitError => e
    MixinApi::Gate.record_throttle(@scope, e)
    raise e if @mode == :interactive && MixinApi::Gate.interactive_exhausted?(@scope)
  else
    MixinApi::Gate.release_success(@scope)
  end
end
```

(`interactive_exhausted?` tracks wait budget — detail for tasks phase.)

### Error-type contract (gem-aligned)

| Gem class | Gate |
| --- | --- |
| `MixinBot::RateLimitError` | Backoff + retry |
| Everything else | Pass through immediately |

Use `error.throttle?` when recording; accept `RateLimitError` explicitly in tests.

## Phase 2

Not in scope for `/speckit-plan`. Run **`/speckit-tasks`** next to generate `tasks.md`.

## Agent Context

No `.specify` agent-context update script present in this repo — skipped.
