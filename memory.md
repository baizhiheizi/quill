# Efficiency Improver memory

> Persistent state for efficiency-improver runs. Verify against GitHub before acting on stale entries.

## build/test/perf commands

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI | `bin/ci` | setup + rubocop + `bun run lint-check` + `bin/rails test` + `db:seed:replant` |
| Tests | `bin/rails test` | Needs Postgres |
| Zeitwerk | `bin/rails zeitwerk:check` | Also in CI |
| Ruby lint | `bin/rubocop` | rails-omakase |
| JS lint | `bun run lint-check` / `node_modules/.bin/prettier --check 'app/javascript/**/*.js'` | Local fallback when `bun` not on PATH |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` / `node esbuild.config.js` | esbuild + tailwind |
| Assets (min) | `node esbuild.config.js --minify` | Use for size measurements |
| Benchmarks | `bin/benchmark article_search.subscribed` / `hot_tags` / `home.active_authors` / `home.active_authors.legacy` / `article.random_readers` | stdlib harness, see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this container. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js` work as fallbacks. `bin/rubocop` cannot inspect `.erb` files directly; validate .erb changes via build + visual inspection.

**Test cache:** `config/environments/test.rb` uses `:null_store`, so `Rails.cache.fetch` always misses in tests.

## efficiency notes

- **Stimulus `disconnect()` listener leak pattern** (7 controllers swept): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, or the long-lived `#modal` turbo frame) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is in every layout. Sweep `document.querySelector("#modal").addEventListener` in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op. Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries.
- **`safeoutputs create_pull_request` AND `safeoutputs create_issue` are BOTH INTERMITTENT** (returned success but no PR/issue opened on run 28627618027, 2026-07-02). PR #1775 (2026-06-29) WAS pushed + merged 2026-06-30 by `an-lee`. **After every call, verify with `mcp__github search_issues` / `search_pull_requests` before assuming success.**
- **Push-blocked pattern is a CYCLE, not permanent**: PR #1811 (auth-name) was previously push-blocked, then manually revived by maintainer from local commit `4c6f2493` and merged 2026-07-02. Repo Assist went ahead and created local branches despite the risk. Recommendation: keep creating local branches + commits on the 4 dashboard sites even when push fails, because the maintainer will revive them when prioritised.
- `safeoutputs push_repo_memory` total file size limit is 12 KB. Trim aggressively.
- **Lazy-loading sweep pattern**: any `image_tag` / `remote_image_tag` inside a repeating list row should pass `lazy: true`. Hero/LCP must stay eager.
- **`remote_image_tag` helper** (`app/helpers/application_helper.rb:8`): accepts both `loading:` and `lazy: true`.
- **AR `Relation#sample` and `Enumerable#sample` distinction**: `Enumerable#sample` is the only one available on AR Relations in Rails 8. It calls `to_a` first (one SQL), then `Array#sample` in Ruby. So `.limit(50).sample(5)` is 1 SQL + 1 Ruby sample.
- **`active_authors` cache vs no-cache decision**: `hot_tags` is cached (locale-only); `active_authors` is NOT cached (per-visitor blocked-user filters). Both use `ORDER BY RANDOM() LIMIT K`.
- **`Payment#article` / `Payment#collection` are memoized model methods backed by `find_by uuid:`** (NOT AR associations). `.includes(:article)` does NOT preload them. Fix pattern: controller-side `preload_payment_references(payments)` private method bulk-fetches UUIDs and seeds `@article` / `@collection` ivars via `instance_variable_set`. For 100-row slice: ~201 SELECTs → ~3 SELECTs.
- **Dashboard N+1 sweep status (2026-07-02)**:
  - `Dashboard::CollectionsController#index` — **FIXED 2026-07-01 by Repo Assist PR #1802** (`.includes(:currency, cover_attachment: :blob)`)
  - `Dashboard::PaymentsController#index` — fixed (PR draft `efficiency/dashboard-payments-preload`, commit `b31a4b47`, awaiting push)
  - `Dashboard::ArticlesController#index` — **DONE 2026-07-02** (`.includes(:author, :currency, :tags, cover_attachment: :blob)`, branch `efficiency/dashboard-articles-eager-load`, commit `ba361af`, awaiting push)
  - `Dashboard::TransfersController#index` — pending (`transfer.currency` + polymorphic `transfer.source.item`, 3+ SELECTs/row). Repo Assist has a local branch (`repo-assist/perf-transfers-dashboard-eager-load-2026-07-01`).
  - `Dashboard::SwapOrdersController#index` — moot (SwapOrder removed in PR #1794)
- **N+1 detection heuristic**: view reaches for a `belongs_to` association on a record from a relation that did NOT call `.includes(:that_assoc)`. `grep -n "X\.\(icon_url\|title\|name\|uuid\|asset_id\)" app/views/<view>.html.erb` + check controller's `pagy ... .order` line catches 80% of cases.
- **`ActiveSupport::TestCase` for unit-level controller preloader tests**: when eager-load claim is implementation-detail (private method mutating ivars), use `ActiveSupport::TestCase` + `controller_class.new.send(:private_method, args)`. Full `ActionController::TestCase` stack needs working DB → fragile.

## optimization backlog

| Status | Item |
|--------|------|
| DONE | 18 PRs across 2026-06-09 → 2026-06-30 (listener-leak × 7, dead-code × 9 controllers / 3 PRs, lazy-loading × 29 rows, reduced-motion, autosave-retry, 3 SQL-sample PRs, currencies-list-lazy-loading, dashboard-payments-preload). See "completed work". |
| DONE (PR #1775 merged 2026-06-30) | `currencies-list-lazy-loading` |
| DONE (PR draft `b31a4b47` awaiting push) | `dashboard-payments-preload` — 100-row slice: ~201 → ~3 SELECTs |
| DONE (PR #1759 merged 2026-06-28) | `active-authors-sql-sample` |
| DONE (PR #1765 merged 2026-06-29) | `buyers-view-sql-sample` |
| DONE (applied 2026-06-26) | `hot-tags-sql-sample` |
| DONE (PR draft awaiting push, issue #1776) | `benchmarks-readme-update` |
| DONE (PR #1802 merged 2026-07-01) | `Dashboard::CollectionsController#index` N+1 (by Repo Assist) |
| DONE (PR draft awaiting push 2026-07-02) | `dashboard-articles-eager-load` — 4-6 SELECTs/row → 6 SELECTs/page |
| COVERED ELSEWHERE (PR #1729, 1731, 1749) | `User#available_articles`, `Article#author_revenue_usd`/`reader_revenue_usd`, `notify_subscribers` SQL subqueries |
| COVERED ELSEWHERE (PR #1783, #1784) | `Dashboard::NotificationsController#index` N+1 on `noticed_events` |
| NEW (next-run candidate) | `Dashboard::TransfersController#index` — Repo Assist branch exists, push-blocked |
| LOW | `pre_orders/_payment.html.erb` + `dashboard/destinations/deposit.html.erb` — `pay_asset.icon_url` rendered twice; intentional layered design |
| EXHAUSTED | Listener-leak, reduced-motion, lazy-loading, dead-code, `.limit(N).sample(K)`, SQL-sample sweep, lazy-loading sweep (29 rows) |
| OPEN ISSUE (no action) | #1720 — `bin/measure-frontend-efficiency` proposal. Maintainer has not responded in 11 days. Do not implement without signal. |
| OPEN ISSUE (no action) | #1776 — `benchmarks-readme-update`. Maintainer has not actioned. |

**Sweep patterns** (all applied): Listener-leak (7 controllers) · Reduced-motion (PR #1719) · Lazy-loading (PR #1714 + admin rows + currencies list) · SQL-sample (3 PRs) · Autosave-retry (PR #1733) · Dead-code (9 controllers) · Dashboard N+1 sweep (collections + payments + articles done, transfers pending).

## work in progress

- **PR draft 2026-06-29**: `efficiency/benchmarks-readme-update` (commit `7f6f3a3`). Issue #1776 fallback.
- **PR draft 2026-06-30**: `efficiency/dashboard-payments-preload` (commit `b31a4b47`). Local branch + patch preserved.
- **PR draft 2026-07-02**: `efficiency/dashboard-articles-eager-load` (commit `ba361af`). Patch at `/tmp/gh-aw/aw-efficiency-dashboard-articles-eager-load.patch` (3,154 B, 57 lines). Bundle at `/tmp/gh-aw/aw-efficiency-dashboard-articles-eager-load.bundle` (1,987 B). 6th safeoutputs push failure. Issue fallback also failed (create_issue returned success but no issue opened).

## completed work

- 18 PRs total. Merged by `an-lee`: #1560, #1576, #1627, #1632, #1669, #1683, #1693, #1702, #1710, #1714, #1719, #1733, #1759 (2026-06-28), #1765 (2026-06-29), #1775 (2026-06-30)
- Admin row icons (2026-06-25): 11 `lazy: true` in admin row partials (no PR by me)
- hot-tags-sql-sample (2026-06-26, applied by `an-lee` without GitHub PR)
- benchmarks-readme-update (2026-06-29, awaiting manual push via #1776)
- dashboard-payments-preload (2026-06-30, awaiting manual push)
- dashboard-articles-eager-load (2026-07-02, awaiting manual push)

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-07-02 23:25 |
| 2 | 2026-07-02 23:25 |
| 3 | 2026-07-02 23:25 |
| 4 | 2026-07-02 23:25 |
| 5 | 2026-07-02 23:25 |
| 6 | 2026-07-02 23:25 |
| 7 | 2026-07-02 23:25 |

## monthly summary — checked off by maintainer

- 2026-06-10 → 2026-06-25: PRs #1560, #1576, #1627, #1632, #1669, #1693, #1702, #1710, #1719, #1733 merged by `an-lee`.
- 2026-06-26: hot-tags-sql-sample applied to main by `an-lee`.
- 2026-06-28: PR #1759 merged by `an-lee`.
- 2026-06-29: PR #1765 merged by `an-lee`.
- 2026-06-30: PR #1775 merged by `an-lee`.
