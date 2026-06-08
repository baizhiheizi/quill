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

### Test (NOTE: `unset CI` in this workflow env, see Performance Notes)
- `bin/rails test` - Run all tests
- `bin/rails zeitwerk:check` - Check Zeitwerk autoload
- `CI= bin/rails test` - Triggers eager load (DO NOT use — see Performance Notes)

### Lint
- `bin/rubocop` - Ruby lint
- `bun run lint-check` - Prettier check on JS/TS
- `bun run lint` - Prettier write

### CI
- `bin/ci` - Full CI pipeline (setup, rubocop, lint-check, tests, seeds)

### Benchmarks
- `bin/benchmark` - All scenarios
- `bin/benchmark article_search.popularity` - Popularity feed
- `bin/benchmark article_search.subscribed` - Subscribed filter
- **Env note**: in this gh-aw workflow env, must `unset CI` first (see notes)

## Performance Opportunities Backlog
1. **[LOW] `author_revenue_usd` and `reader_revenue_usd`** - Uses `includes(:currency).sum()` with calculation in Ruby, could be optimized to SQL. Memoized with `@author_revenue_usd ||= ...` so only runs once per request. Used in `app/views/dashboard/articles/show.html.erb`.

## Work in Progress
- **Branch**: `perf-assist/subscribed-filter-subqueries` (commit `f3b74af3`) — fix ready locally, awaiting human push. Patch at `/tmp/gh-aw/aw-perf-assist-subscribed-filter-subqueries.patch`.

## Completed Work
- Initial repository analysis (2026-06-01)
- Monthly Activity issue #1513 last updated 2026-06-08
- PR #1518 (random_readers SQL sampling) — merged
- PR #1521 (bought subquery) — merged
- PR #1523 (DailyStatistic payer counts) — merged
- **PR #1539 (order_by_popularity LEFT JOIN + COALESCE) — merged 2026-06-07** (closed [HIGH] empty default feed correctness bug)
- **Local commit `f3b74af3`**: `ArticleSearchService#subscribed` filter refactored to use SQL subqueries (9 → 5 queries, O(n) Ruby arrays eliminated)

## Run History (last 2)
- **2026-06-08 12:50 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27138209827)
  - Refactored `ArticleSearchService#subscribed` filter to use SQL subqueries
  - 9 → 5 queries per call; O(n) Ruby arrays eliminated
  - Branch `perf-assist/subscribed-filter-subqueries` committed locally (commit `f3b74af3`); could not push via safeoutputs
  - Tests: 7 runs, 21 assertions, 0 failures; Rubocop clean
  - Confirmed PR #1539 is merged; closed the [HIGH] backlog item
  - Confirmed `subscribe_user_ids` is gem-generated (not missing from User)
  - Monthly Activity issue #1513 updated

- **2026-06-07 00:24 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27059506134)
  - Re-applied `order_by_popularity` LEFT JOIN + COALESCE fix on fresh branch
  - Discovered the INNER JOIN causes an empty default feed when no orders exist (correctness bug)
  - Discovered `unset CI` workaround for the Arweave firewall issue
  - PR #1539 created and merged by an-lee later
