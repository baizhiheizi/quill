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

## Work in Progress
- **PR (block filters subqueries)** (`perf-assist/block-filters-subqueries-d00934bea7028f34`) is OPEN — CI pending. Draft PR opened 2026-06-11 via `safeoutputs create_pull_request`.

## Completed Work
- Monthly Activity issue #1513 `[perf-improver] Monthly Activity 2026-06` last updated 2026-06-11
- PR #1518 (random_readers SQL sampling) — merged
- PR #1521 (bought subquery) — merged
- PR #1523 (DailyStatistic payer counts) — merged
- **PR #1539** (order_by_popularity LEFT JOIN + COALESCE) — merged 2026-06-07
- **PR #1546** (subscribed filter SQL subqueries) — MERGED 2026-06-09
- **Block filters subqueries PR** — OPEN 2026-06-11: filter_block_authors + filter_block_by_authors → SQL subqueries; 2 fewer round-trips per call when @current_user has blocked/blocked-by anyone; guard clause for nil user

## Performance Notes
- **Env quirk**: this gh-aw workflow sets `CI=true`, making `config.eager_load = true` in `config/environments/test.rb`. Eager load hits `app/libs/arweave_bot/graphql.rb` (HTTP 403 to `arweave.net`). Workaround: **`unset CI` before any `bin/rails test` / `bin/benchmark`.
- **Bug discovered & merged**: `Article.order_by_popularity` used `joins(:orders)` (INNER JOIN); articles with no orders were excluded from default feed. Fixed and merged in PR #1539.
- **Action store**: `action_store` gem dynamically generates `subscribe_user_ids`, `block_user_ids`, `block_by_user_ids`, etc. from `action_store :verb, :target` declarations. No need to define in User model.
- **PR creation in this env**: `safeoutputs create_pull_request` returns `{"result":"success", "patch": {...}, "bundle": {...}}` — workflow orchestrator pushes the bundle and opens the actual PR after the agent run completes.
- **Benchmarks**: `bin/benchmark` works with `unset CI`. Fixture-scale only; relative before/after useful.
- **Test DB pollution**: `bin/rails runner` outside test transactions persists writes. Always clean up after debug.
- **Pre-existing test failures**: `markdown_render_service_test.rb` / `rich_text_render_service_test.rb` fail with HTTP 403 to external image hosts; firewall-blocked, not caused by perf-improver changes.
- **Copilot PR review false positives**: Copilot reviews on PR #1546 produced 2 comments that were resolved without code changes — both flagged issues were already addressed in the original diff.

## Run History (recent)
- **2026-06-11 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27346010833)
  - Refactored `ArticleSearchService#filter_block_authors` and `#filter_block_by_authors` to use SQL subqueries (`Action.where(...).select(:target_id)` / `.select(:user_id)`) instead of materializing Ruby ID arrays via `block_user_ids` / `block_by_user_ids`
  - Branch `perf-assist/block-filters-subqueries-d00934bea7028f34` committed; draft PR opened via `safeoutputs create_pull_request`
  - Eliminates 2 round-trips per call when @current_user has blocked/blocked-by anyone; O(n) Ruby arrays eliminated
  - Tests: 10 runs, 35 assertions, 0 failures; Rubocop clean
  - Verified PR #1546 is now MERGED; removed stale "Review PR #1546" from Monthly Activity suggestions
  - Only `author_revenue_usd` / `reader_revenue_usd` remains in LOW-priority backlog

- **2026-06-09 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27202813938)
  - Confirmed PR #1546 is open, CI passing, review threads resolved (no code changes needed)
  - Updated Monthly Activity issue #1513 with corrected suggestions (PR #1546 vs stale local-branch ref)
  - No new code changes; backlog clear of high-impact items

- **2026-06-08 12:50 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27138209827)
  - Refactored `ArticleSearchService#subscribed` to SQL subqueries: 9 → 5 queries, O(n) Ruby arrays eliminated
  - Branch `perf-assist/subscribed-filter-subqueries-d00934bea7028f34` pushed as PR #1546
  - Tests: 7 runs, 21 assertions, 0 failures; Rubocop clean
  - Confirmed PR #1539 merged; closed [HIGH] backlog item

- **2026-06-07 00:24 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27059506134)
  - Discovered `unset CI` workaround for Arweave firewall issue
  - Discovered INNER JOIN causes empty default feed (correctness bug)
  - `safeoutputs create_pull_request` "no push" observation — later corrected

- **2026-06-01 12:00 UTC** - Created PR #1518 (random_readers SQL sampling) — merged
- **2026-06-01 08:31 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26739902209) - Created Monthly Activity issue

## Backlog Cursor
- `order_by_popularity` fix — ✅ MERGED (PR #1539)
- `ArticleSearchService#subscribed` filter — ✅ MERGED (PR #1546)
- `ArticleSearchService#filter_block_authors` / `#filter_block_by_authors` — PR OPEN (CI pending)
- `author_revenue_usd` / `reader_revenue_usd` — Low impact; deferred
- **Next**: explore other ArticleSearchService hot paths or wider controllers; look for `.ids` / `.pluck(:id)` materialization patterns elsewhere (e.g. dashboard home, admin views)