# Perf Improver Memory

## Repository
- **Name**: baizhiheizi/quill
- **Type**: Rails8.1 monolith (Web3 paid-publishing platform)
- **Stack**: Ruby4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild

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
1. **[LOW] `author_revenue_usd` / `reader_revenue_usd`** - Uses `includes(:currency).sum()` with calculation in Ruby. Memoized with `@author_revenue_usd ||= ...`. Used in `app/views/dashboard/articles/show.html.erb`.
2. **[LOW] `filter_block_authors` / `filter_block_by_authors`** - These also call `block_user_ids` / `block_by_user_ids` which materialize ID arrays. Could be subqueries too. (Only fires when a user has blocked people.)

## Work in Progress
- **None.** All high-impact items either merged or open as PR awaiting human review.
- **PR #1546** (`perf-assist/subscribed-filter-subqueries-d00934bea7028f34`) is OPEN, CI passing, both Copilot review threads RESOLVED, awaiting maintainer review/merge.

## Completed Work
- Monthly Activity issue #1513 `[perf-improver] Monthly Activity2026-06` last updated2026-06-09
- PR #1518 (random_readers SQL sampling) — merged
- PR #1521 (bought subquery) — merged
- PR #1523 (DailyStatistic payer counts) — merged
- **PR #1539** (order_by_popularity LEFT JOIN + COALESCE) — merged2026-06-07 (closed [HIGH] empty default feed correctness bug)
- **PR #1546** (subscribed filter SQL subqueries) — OPEN2026-06-08:9 →5 queries per call, O(n) Ruby arrays eliminated, guard clause for nil user

## Performance Notes
- **Env quirk**: this gh-aw workflow sets `CI=true`, making `config.eager_load = true` in `config/environments/test.rb`. Eager load hits `app/libs/arweave_bot/graphql.rb` (HTTP403 to `arweave.net`). Workaround: **`unset CI` before any `bin/rails test` / `bin/benchmark`**.
- **Bug discovered & merged**: `Article.order_by_popularity` used `joins(:orders)` (INNER JOIN); articles with no orders were excluded from default feed. Fixed and merged in PR #1539.
- **Action store**: `action_store` gem dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. from `action_store :verb, :target` declarations. No need to define in User model.
- **PR creation in this env**: `safeoutputs create_pull_request` DOES create real PRs — PR #1546 was opened successfully2026-06-08. Earlier memory note claiming it didn't push was based on incomplete observation.
- **Benchmarks**: `bin/benchmark` works with `unset CI`. Fixture-scale only; relative before/after useful.
- **Test DB pollution**: `bin/rails runner` outside test transactions persists writes. Always clean up after debug.
- **Pre-existing test failures**: `markdown_render_service_test.rb` / `rich_text_render_service_test.rb` fail with HTTP403 to external image hosts; firewall-blocked, not caused by perf-improver changes.
- **Copilot PR review false positives**: Copilot reviews on PR #1546 produced2 comments that were resolved without code changes — both flagged issues were already addressed in the original diff (guard clause `return @articles.none if @current_user.blank?`; test asserts on `IN (SELECT...)` pattern count, not alias).

## Run History (recent)
- **2026-06-0912:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27202813938)
 - Confirmed PR #1546 is open, CI passing, review threads resolved (no code changes needed)
 - Updated Monthly Activity issue #1513 with corrected suggestions (PR #1546 vs stale local-branch ref)
 - No new code changes; backlog clear of high-impact items
- **2026-06-0812:50 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27138209827)
 - Refactored `ArticleSearchService#subscribed` to SQL subqueries:9 →5 queries, O(n) Ruby arrays eliminated
 - Branch `perf-assist/subscribed-filter-subqueries-d00934bea7028f34` pushed as PR #1546
 - Tests:7 runs,21 assertions,0 failures; Rubocop clean
 - Confirmed PR #1539 merged; closed [HIGH] backlog item
- **2026-06-0700:24 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27059506134)
 - Discovered `unset CI` workaround for Arweave firewall issue
 - Discovered INNER JOIN causes empty default feed (correctness bug)
 - `safeoutputs create_pull_request` "no push" observation — later corrected
- **2026-06-0112:00 UTC** - Created PR #1518 (random_readers SQL sampling) — merged
- **2026-06-0108:31 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26739902209) - Created Monthly Activity issue

## Backlog Cursor
- `order_by_popularity` fix — ✅ MERGED (PR #1539)
- `ArticleSearchService#subscribed` filter — ✅ OPEN (PR #1546, CI passing, awaiting review)
- `author_revenue_usd` / `reader_revenue_usd` — Low impact; deferred
- `filter_block_authors` / `filter_block_by_authors` — Low priority; similar pattern to PR #1546
- **Next**: explore other ArticleSearchService hot paths; look for `.ids` / `.pluck(:id)` materialization patterns elsewhere
