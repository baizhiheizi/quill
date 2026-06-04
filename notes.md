# Perf Improver Memory

## Repository
- **Name**: baizhiheizi/quill
- **Type**: Rails 8.1 monolith (Web3 paid-publishing platform)
- **Stack**: Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild

## Validated Commands

### Build/Setup
- `bundle install --jobs 4 --retry 3` - Install Ruby gems
- `bun install --frozen-lockfile` - Install Node modules
- `bin/dev` - Run full development stack (Rails, Solid Queue, CSS/JS watch)
- `bun run build` - Build frontend assets
- `bun run build:css` - Build CSS

### Test
- `bin/rails test` - Run all tests
- `bin/rails zeitwerk:check` - Check Zeitwerk autoload
- `CI= bin/rails test` - Run without eager loading (avoids Arweave API 403)

### Lint
- `bin/rubocop` - Ruby lint
- `bun run lint-check` - Prettier check on JS/TS
- `bun run lint` - Prettier write

### CI
- `bin/ci` - Full CI pipeline (setup, rubocop, lint-check, tests, seeds)

### Benchmarks
- `bin/benchmark` - All scenarios (requires Arweave API access)
- `bin/benchmark article_search.popularity` - Popularity feed (requires Arweave API access)

## Performance Opportunities Backlog
1. **[HIGH] `order_by_popularity` scope** - Fix committed locally: LEFT JOIN + COALESCE. See branch `perf-assist/order-by-popularity-left-join`.
2. **[MEDIUM] `ArticleSearchService#subscribed` filter** - Potential N+1 with `subscribe_user_ids` and `owning_collection_ids`. `subscribe_user_ids` method appears to be missing from User model.
3. **[LOW] `author_revenue_usd` and `reader_revenue_usd`** - Uses `includes(:currency).sum()` with calculation in Ruby, could be optimized to SQL

## Work in Progress
- `order_by_popularity` LEFT JOIN fix committed on branch `perf-assist/order-by-popularity-left-join`. Could not push or create PR (safeoutputs create-pull-request tool unavailable in this environment).

## Completed Work
- Initial repository analysis completed (2026-06-01)
- Monthly Activity issue created: `[perf-improver] Monthly Activity 2026-06` (issue #1513)
- Validated build/test commands documentation
- `random_readers` identified as a clear inefficiency with straightforward fix
- PR #1518: SQL sampling for `Article#random_readers` — merged
- PR #1521: `ArticleSearchService#bought` subquery — merged
- PR #1523: `DailyStatistic` distinct payer counts — awaiting review
- `order_by_popularity` LEFT JOIN + COALESCE fix committed (branch created, cannot push)

## Run History
- **2026-06-04 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26926616504)
  - Fixed `order_by_popularity`: INNER JOIN → LEFT JOIN, COALESCE wrappers
  - Branch `perf-assist/order-by-popularity-left-join` created but push/PR failed (tool unavailable)
  - Tests pass: 10 runs, 14 assertions, 0 failures
  - Rubocop clean

- **2026-06-02 12:00 UTC** - Local Cursor run
  - Created PR #1523: `DailyStatistic` payer counts via SQL
  - Validated `bin/benchmark` harness on main

- **2026-06-01 14:00 UTC** - Local Cursor run
  - Created PR #1521: `ArticleSearchService#bought` subquery
  - Created issue #1520: benchmark harness proposal

- **2026-06-01 12:00 UTC** - Local Cursor run
  - Validated build/test/lint commands
  - Created PR #1518: SQL sampling for `Article#random_readers` — merged

- **2026-06-01 08:31 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26739902209)
  - Created Monthly Activity issue #1513
  - Identified `random_readers` as easy win

## Backlog Cursor
- `order_by_popularity` fix committed locally (branch cannot be pushed)
- `ArticleSearchService#subscribed` - investigate missing `subscribe_user_ids` method
- `author_revenue_usd` / `reader_revenue_usd` optimization
