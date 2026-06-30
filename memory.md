# Efficiency Improver memory

> Persistent state for efficiency-improver runs. Verify against GitHub before acting on stale entries.

## build/test/perf commands

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI | `bin/ci` | setup + rubocop + `bun run lint-check` + `bin/rails test` + `db:seed:replant` |
| Tests | `bin/rails test` | Needs Postgres, `RAILS_ENV=test` |
| Zeitwerk | `bin/rails zeitwerk:check` | Also in CI |
| Ruby lint | `bin/rubocop` | rails-omakase |
| JS lint | `bun run lint-check` / `node_modules/.bin/prettier --check 'app/javascript/**/*.js'` | Local fallback when `bun` not on PATH |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` / `node esbuild.config.js` | esbuild + tailwind |
| Assets (min) | `node esbuild.config.js --minify` | Use for size measurements |
| Benchmarks | `bin/benchmark article_search.subscribed` / `bin/benchmark hot_tags` / `bin/benchmark home.active_authors` / `bin/benchmark home.active_authors.legacy` / `bin/benchmark article.random_readers` | stdlib harness, see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this container. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js` work as fallbacks. `bin/rubocop` cannot inspect `.erb` files directly; validate .erb changes via build + visual inspection.

**Test cache:** `config/environments/test.rb` uses `:null_store`, so `Rails.cache.fetch` always misses in tests. Tests that need to exercise cache behavior must stub or use a different strategy.

## efficiency notes

- **Stimulus `disconnect()` listener leak pattern** (7 controllers swept): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is in every layout. Sweep `document.querySelector("#modal").addEventListener` in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op. Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries.
- **`safeoutputs create_pull_request` limitation is INTERMITTENT** (4 fails + 1 success across last 5 runs). **Counter-example**: PR #1775 (draft from 2026-06-29) WAS pushed + merged at 2026-06-30T01:17:46Z by `an-lee`. The "never pushes" claim in earlier memory is wrong. Always check whether a draft PR was actually created before "abandoning" a branch.
- `safeoutputs push_repo_memory` total file size limit is 12 KB. Trim older completed PRs into compact one-liners.
- **Lazy-loading sweep pattern**: any `image_tag` / `remote_image_tag` inside a repeating list row should pass `lazy: true`. Hero/LCP must stay eager.
- **`remote_image_tag` helper** (`app/helpers/application_helper.rb:8`): accepts both `loading:` and `lazy: true`.
- **AR `Relation#sample` and `Enumerable#sample` distinction**: `Enumerable#sample` is the only one available on AR Relations in Rails 8. It calls `to_a` first (one SQL), then `Array#sample` in Ruby. So `.limit(50).sample(5)` is 1 SQL + 1 Ruby sample.
- **`active_authors` cache vs no-cache decision**: `hot_tags` is cached (locale-only); `active_authors` is NOT cached (per-visitor blocked-user filters). Both use `ORDER BY RANDOM() LIMIT K`.
- **`Payment#article` / `Payment#collection` are memoized model methods backed by `find_by uuid:`** (NOT AR associations). `.includes(:article)` does NOT preload them. Fix pattern: controller-side `preload_payment_references(payments)` private method bulk-fetches UUIDs and seeds `@article` / `@collection` ivars via `instance_variable_set`. For 100-row slice: ~201 SELECTs → ~3 SELECTs. Implementation: `app/controllers/dashboard/payments_controller.rb`, tests in `test/controllers/dashboard/payments_controller_test.rb` (3 tests, 7 assertions, 0 failures).
- **Dashboard N+1 sweep — 5 sites confirmed 2026-06-30**:
  - `Dashboard::PaymentsController#index` — fixed (PR draft `efficiency/dashboard-payments-preload`, `b31a4b47`)
  - `Dashboard::TransfersController#index` — `transfer.currency` + polymorphic `transfer.source.item`. 3+ SELECTs/row. Needs larger refactor (`Transfer#item` AR assoc).
  - `Dashboard::SwapOrdersController#index` — `pay_asset` + `fill_asset`. Trivial fix. Next-run candidate.
  - `Dashboard::ArticlesController#index` (`published` + `hidden` tabs) — `article.currency` + `article.cover` (ActiveStorage) + `article.author`.
  - `Dashboard::CollectionsController#index` — `collection.currency` + `collection.cover`.
- **N+1 detection heuristic**: view reaches for a `belongs_to` association on a record from a relation that did NOT call `.includes(:that_assoc)`. `grep -n "X\.\(icon_url\|title\|name\|uuid\|asset_id\)" app/views/<view>.html.erb` + check controller's `pagy ... .order` line catches 80% of cases.
- **`ActiveSupport::TestCase` for unit-level controller preloader tests**: when eager-load claim is implementation-detail (private method mutating ivars), use `ActiveSupport::TestCase` + `controller_class.new.send(:private_method, args)`. Full `ActionController::TestCase` stack needs working DB → fragile. Used in `test/controllers/dashboard/payments_controller_test.rb`.

## optimization backlog

| Status | Item |
|--------|------|
| DONE | 18 PRs across 2026-06-09 → 2026-06-30 (listener-leak × 7, dead-code × 9 controllers / 3 PRs, lazy-loading × 29 rows, reduced-motion, autosave-retry, 3 SQL-sample PRs, currencies-list-lazy-loading, dashboard-payments-preload). See "completed work". |
| DONE (PR #1775 merged 2026-06-30) | `currencies-list-lazy-loading` — `currencies/_list.html.erb` lines 22-23: `lazy: true` on currency icon + chain icon |
| DONE (PR draft `b31a4b47` awaiting push) | `dashboard-payments-preload` — `Dashboard::PaymentsController#index` breaks N+1 on `payment.currency` (`.includes(:currency)`), `payment.article` (preloader seeds `@article` ivar), `payment.collection` (preloader seeds `@collection` ivar). 100-row slice: ~201 → ~3 SELECTs. |
| DONE (PR #1759 merged 2026-06-28) | `active-authors-sql-sample` — `HomeController#active_authors` SQL `RANDOM()` + LIMIT 5, no cache (per-visitor block-filter); 2 benchmark scenarios |
| DONE (PR #1765 merged 2026-06-29) | `buyers-view-sql-sample` — `articles/_buyers.html.erb` `article.readers.sample(24)` → `article.random_readers(24)`; also `any?` → `exists?` |
| DONE (applied 2026-06-26) | `hot-tags-sql-sample` — `HomeController#hot_tags` SQL `RANDOM()` + LIMIT 5 + cache 5-row Array |
| DONE (PR draft awaiting push, issue #1776) | `benchmarks-readme-update` — `test/benchmarks/README.md` Scenarios table lists `home.active_authors` entries |
| COVERED ELSEWHERE (PR #1729, 1731, 1749 repo-assist) | `User#available_articles`, `Article#author_revenue_usd`/`reader_revenue_usd`, `notify_subscribers` SQL subqueries |
| COVERED ELSEWHERE (PR #1783, #1784 perf-improver) | `Dashboard::NotificationsController#index` N+1 on `noticed_events` — fix uses `.includes(:event)` |
| NEW (next-run candidates) | `Dashboard::TransfersController#index` (currency + polymorphic source.item), `Dashboard::SwapOrdersController#index` (pay_asset + fill_asset), `Dashboard::ArticlesController#index` (currency + cover), `Dashboard::CollectionsController#index` (currency + cover) — same fix pattern as payments |
| LOW | `pre_orders/_payment.html.erb` + `dashboard/destinations/deposit.html.erb` — `pay_asset.icon_url` rendered twice (main + chain overlay); intentional layered design |
| EXHAUSTED | Listener-leak, reduced-motion, lazy-loading, dead-code, `.limit(N).sample(K)` — all known anti-patterns addressed. SQL-sample sweep closed. Lazy-loading sweep closed (29 rows total). Dashboard-payments-preload closes payments N+1 site. |

**Sweep patterns** (all applied): Listener-leak (7 controllers) · Reduced-motion (PR #1719) · Lazy-loading (PR #1714 + admin rows + currencies list) · SQL-sample (3 PRs) · Autosave-retry (PR #1733) · Dead-code (9 controllers) · Dashboard N+1 sweep (in progress; payments done, 4 sites pending).

## work in progress

- **PR draft 2026-06-29**: `efficiency/benchmarks-readme-update` (commit `7f6f3a3`). Patch at `/tmp/gh-aw/aw-efficiency-benchmarks-readme-update.patch` (3,973 B). safeoutputs push failed → open as fallback issue #1776.
- **PR draft 2026-06-30**: `efficiency/dashboard-payments-preload` (commit `b31a4b47`). Patch at `/tmp/gh-aw/aw-efficiency-dashboard-payments-preload.patch`. 5th safeoutputs push failure.

## completed work

- 18 PRs total. Merged by `an-lee`: #1560, #1576, #1627, #1632, #1669, #1683, #1693, #1702, #1710, #1714, #1719, #1733, #1759 (2026-06-28), #1765 (2026-06-29), #1775 (2026-06-30)
- Admin row icons (2026-06-25): 11 `lazy: true` in admin row partials (no PR by me)
- hot-tags-sql-sample (2026-06-26, applied by `an-lee` without GitHub PR)
- benchmarks-readme-update (2026-06-29, awaiting manual push via #1776)
- dashboard-payments-preload (2026-06-30, awaiting manual push)

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-30 11:24 |
| 2 | 2026-06-30 11:24 |
| 3 | 2026-06-30 11:24 |
| 4 | 2026-06-30 11:24 |
| 5 | 2026-06-30 11:24 |
| 6 | 2026-06-30 11:24 |
| 7 | 2026-06-30 11:24 |

## monthly summary — checked off by maintainer

- 2026-06-10 → 2026-06-25: PRs #1560, #1576, #1627, #1632, #1669, #1693, #1702, #1710, #1719, #1733 merged by `an-lee`.
- 2026-06-26: hot-tags-sql-sample applied to main by `an-lee`.
- 2026-06-28: PR #1759 merged by `an-lee`.
- 2026-06-29: PR #1765 merged by `an-lee`.
- 2026-06-30: PR #1775 merged by `an-lee`.
