# Perf Improver Memory

## Repository
- **Name**: baizhiheizi/quill
- **Type**: Rails8.1 monolith (Web3 paid-publishing platform)
- **Stack**: Ruby4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild

## Validated Commands

### Build/Setup
- `bundle install --jobs4 --retry3` - Install Ruby gems
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
2. **[LOW] `filter_block_authors` / `filter_block_by_authors`** - These also call `block_user_ids` / `block_by_user_ids` which materialize ID arrays. Could be subqueries too. (Not yet measured; only fires when a user has blocked people.)

## Work in Progress
- **None.** All high-impact items either merged or open as PR awaiting human review.
- **PR #1546** (`perf-assist/subscribed-filter-subqueries-d00934bea7028f34`) is OPEN, CI passing, both Copilot review threads RESOLVED, awaiting maintainer review/merge.

## Completed Work
- Initial repository analysis (2026-06-01)
- Monthly Activity issue #1513 last updated2026-06-09
- PR #1518 (random_readers SQL sampling) — merged
- PR #1521 (bought subquery) — merged
- PR #1523 (DailyStatistic payer counts) — merged
- **PR #1539 (order_by_popularity LEFT JOIN + COALESCE) — merged2026-06-07** (closed [HIGH] empty default feed correctness bug)
- **PR #1546 (subscribed filter SQL subqueries) — OPEN2026-06-08** (9 →5 queries per call, O(n) Ruby arrays eliminated, guard clause for nil user)

## Run History (last3)
- **2026-06-0912:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27202813938)
 - Confirmed PR #1546 is open, CI passing, review threads resolved
 - Confirmed guard clause `return @articles.none if @current_user.blank?` already handles nil-user concern flagged by Copilot
 - Confirmed test asserts on `IN (SELECT...)` pattern count, not table aliases
 - Updated Monthly Activity issue #1513 with corrected suggestions (PR #1546 instead of stale local-branch reference)
 - No new code changes; backlog clear of high-impact items

- **2026-06-0812:50 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27138209827)
 - Refactored `ArticleSearchService#subscribed` filter to use SQL subqueries
 -9 →5 queries per call; O(n) Ruby arrays eliminated
 - Branch `perf-assist/subscribed-filter-subqueries-d00934bea7028f34` pushed via `safeoutputs create_pull_request` as PR #1546
 - Tests:7 runs,21 assertions,0 failures; Rubocop clean
 - Confirmed PR #1539 is merged; closed the [HIGH] backlog item
 - Confirmed `subscribe_user_ids` is gem-generated (not missing from User)
 - Monthly Activity issue #1513 updated

- **2026-06-0700:24 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27059506134)
 - Re-applied `order_by_popularity` LEFT JOIN + COALESCE fix on fresh branch
 - Discovered the INNER JOIN causes an empty default feed when no orders exist (correctness bug)
 - Discovered `unset CI` workaround for the Arweave firewall issue
 - PR #1539 created and merged by an-lee later
