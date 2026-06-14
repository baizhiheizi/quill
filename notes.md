# Perf Improver Memory

## Repository
- **Name**: baizhiheizi/quill
- **Type**: Rails 8.1 monolith (Web3 paid-publishing platform)
- **Stack**: Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild

## Validated Commands

### Build/Setup
- `bundle install --jobs4 --retry3` - Install Ruby gems
- `bun install --frozen-lockfile` - Install Node modules
- `bin/dev` - Run full development stack
- `bun run build` / `bun run build:css` - Build frontend assets

### Test (NOTE: `unset CI` in this workflow env)
- `bin/rails test` - Run all tests
- `bin/rails zeitwerk:check` - Check Zeitwerk autoload
- `CI= bin/rails test` - Triggers eager load (DO NOT use — see Performance Notes)

### Lint
- `bin/rubocop` - Ruby lint
- `bun run lint-check` - Prettier check on JS/TS
- `bun run lint` - Prettier write

### CI
- `bin/ci` - Full CI pipeline

### Benchmarks
- `bin/benchmark` - All scenarios; per-scenario via `bin/benchmark article_search.subscribed`
- **Env note**: must `unset CI` first (see Performance Notes)

## Performance Opportunities Backlog
1. **[LOW] `author_revenue_usd` / `reader_revenue_usd`** - Ruby-side sum with `includes(:currency)`. Memoized with `@author_revenue_usd ||= ...`. Used in `app/views/dashboard/articles/show.html.erb`. Single-article, very low impact.
2. **[POTENTIAL] Admin::UsersController sort N+1** - Each row calls `user.articles_count` / `user.bought_articles_count` / `user.author_revenue_total_usd` / `user.payment_total_usd`. All memoized, so ~4 queries per user × 24 per page ≈ 100 queries/page. Acceptable for now; would benefit from `User.with_aggregates` style pre-aggregation if user base grows.

## Work in Progress
- **PR (user scope LEFT JOINs)** (`perf-assist/user-scope-left-joins-d00934bea7028f34`) OPEN — committed 2026-06-14, draft PR opened via `safeoutputs create_pull_request` (bundle on disk: `/tmp/gh-aw/aw-perf-assist-user-scope-left-joins-d00934bea7028f34.bundle`).

## Completed Work
- Monthly Activity issue #1513 `[perf-improver] Monthly Activity 2026-06` last updated 2026-06-14
- PR #1518 (random_readers SQL sampling) — merged
- PR #1521 (bought subquery) — merged
- PR #1523 (DailyStatistic payer counts) — merged
- PR #1539 (order_by_popularity LEFT JOIN + COALESCE) — merged 2026-06-07
- PR #1546 (subscribed filter SQL subqueries) — merged 2026-06-09
- PR #1598 (block filters SQL subqueries) — merged 2026-06-12
- **PR (user scope LEFT JOINs)** — OPEN 2026-06-14: `Users::Scopable` order_by_revenue_total / orders_total / articles_count / comments_count → LEFT JOIN + COALESCE for SUM, COUNT unchanged. Same pattern as PR #1539; eliminates silent exclusion of users with no matching rows from the admin user list.

## Performance Notes
- **Env quirk**: this gh-aw workflow sets `CI=true`, making `config.eager_load = true` in `config/environments/test.rb`. Eager load hits `app/libs/arweave_bot/graphql.rb` (HTTP 403 to `arweave.net`). Workaround: **`unset CI` before any `bin/rails test` / `bin/benchmark`.
- **Bug discovered & merged**: `Article.order_by_popularity` used `joins(:orders)` (INNER JOIN); articles with no orders were excluded from default feed. Fixed and merged in PR #1539.
- **Bug discovered & filed (PR open)**: `Users::Scopable` order_by_revenue_total / orders_total / articles_count / comments_count used `joins(...)` (INNER JOIN); users with no matching rows were excluded from the admin user list. Same correctness bug, four more scopes. Fixed in draft PR 2026-06-14.
- **Action store**: `action_store` gem dynamically generates `subscribe_user_ids`, `block_user_ids`, `block_by_user_ids`, etc. from `action_store :verb, :target` declarations. No need to define in User model.
- **PR creation in this env**: `safeoutputs create_pull_request` returns `{"result":"success", "patch": {...}, "bundle": {...}}` — workflow orchestrator pushes the bundle and opens the actual PR after the agent run completes.
- **Monthly issue update_issue in this env**: `safeoutputs update_issue` returns `{"result":"success"}` but does NOT actually update the body when the workflow target is `triggering` (push-triggered run has no triggering issue). Workaround: use `safeoutputs add_comment` with `item_number: <issue>` to append a new comment with the latest run summary.
- **Benchmarks**: `bin/benchmark` works with `unset CI`. Fixture-scale only; relative before/after useful.
- **Test DB pollution**: `bin/rails runner` outside test transactions persists writes. Always clean up after debug.
- **Pre-existing test failures**: `markdown_render_service_test.rb` / `rich_text_render_service_test.rb` fail with HTTP 403 to external image hosts; firewall-blocked, not caused by perf-improver changes.
- **Copilot PR review false positives**: Copilot reviews on PR #1546 produced 2 comments that were resolved without code changes — both flagged issues were already addressed in the original diff.
- **Admin::UsersController sort bug**: `Users::Scopable` `order_by_*` scopes used `joins(...)` (INNER JOIN). The same pattern as the `order_by_popularity` bug from PR #1539, but in 4 user-scope variants. Files: `app/models/concerns/users/scopable.rb`.

## Run History (recent)
- **2026-06-14 03:39 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27464306984)
  - Refactored `Users::Scopable` order_by_revenue_total / orders_total / articles_count / comments_count to LEFT JOIN + COALESCE for SUM
  - Branch `perf-assist/user-scope-left-joins-d00934bea7028f34` committed; draft PR opened via `safeoutputs create_pull_request`
  - Eliminates silent exclusion of users with no matching records from the admin user list (same bug as PR #1539)
  - Tests: 15 runs, 43 assertions, 0 failures; Rubocop clean
  - Verified all 4 stale [aw] Perf Improver failure issues (#1510, #1511, #1538, #1544) are now CLOSED
  - Verified PR #1598 (block filters subqueries) was MERGED on 2026-06-12 — closed that backlog item
  - Monthly Activity issue #1513 comment posted (update_issue tool didn't work; add_comment used instead)
  - Only `author_revenue_usd` / `reader_revenue_usd` remains in the LOW-priority backlog

- **2026-06-11 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27346010833)
  - Refactored `ArticleSearchService#filter_block_authors` and `#filter_block_by_authors` to use SQL subqueries
  - Branch `perf-assist/block-filters-subqueries-d00934bea7028f34` committed; PR #1598 opened via `safeoutputs create_pull_request`
  - Eliminates 2 round-trips per call when @current_user has blocked/blocked-by anyone
  - Tests: 10 runs, 35 assertions, 0 failures; Rubocop clean

- **2026-06-09 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27202813938)
  - Confirmed PR #1546 is open, CI passing, review threads resolved
  - Updated Monthly Activity issue #1513 with corrected suggestions
  - No new code changes; backlog clear of high-impact items

- **2026-06-08 12:50 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27138209827)
  - Refactored `ArticleSearchService#subscribed` to SQL subqueries: 9 → 5 queries
  - Branch `perf-assist/subscribed-filter-subqueries-d00934bea7028f34` pushed as PR #1546
  - Tests: 7 runs, 21 assertions, 0 failures; Rubocop clean

- **2026-06-07 00:24 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27059506134)
  - Discovered `unset CI` workaround for Arweave firewall issue
  - Discovered INNER JOIN causes empty default feed (correctness bug)
  - `safeoutputs create_pull_request` "no push" observation — later corrected

- **2026-06-01 12:00 UTC** - Created PR #1518 (random_readers SQL sampling) — merged
- **2026-06-01 08:31 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26739902209) - Created Monthly Activity issue

## Backlog Cursor
- `order_by_popularity` fix — ✅ MERGED (PR #1539)
- `ArticleSearchService#subscribed` filter — ✅ MERGED (PR #1546)
- `ArticleSearchService#filter_block_authors` / `#filter_block_by_authors` — ✅ MERGED (PR #1598)
- `Users::Scopable` order_by_revenue_total / orders_total / articles_count / comments_count — PR OPEN (CI pending)
- `author_revenue_usd` / `reader_revenue_usd` — Low impact; deferred
- **Next**: explore other admin sort scopes with the same INNER JOIN bug (e.g. `tag.rb:26` `joins(:articles)`); look at the Admin::TransfersController/StatisticsController; check if `active` scope (also in `Users::Scopable`) has any similar issue
