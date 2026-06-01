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

### Lint
- `bin/rubocop` - Ruby lint
- `bun run lint-check` - Prettier check on JS/TS
- `bun run lint` - Prettier write

### CI
- `bin/ci` - Full CI pipeline (setup, rubocop, lint-check, tests, seeds)

## Performance Opportunities Backlog
1. **[HIGH] `order_by_popularity` scope** - Complex join with orders table, calculates SQL expression per row including POW/EXTRACT. Articles without orders are excluded (INNER JOIN behavior). Missing index on `orders.value_usd`. Consider LEFT JOIN with COALESCE.
2. **[MEDIUM] `random_readers(limit)` inefficiency** - `readers.where(id: readers.ids.sample(limit))` loads ALL reader IDs into memory before sampling. Should use database-level random sampling via `ORDER BY RANDOM()`.
3. **[MEDIUM] `ArticleSearchService#subscribed` filter** - Potential N+1 with `subscribe_user_ids` and `owning_collection_ids`
4. **[LOW] `author_revenue_usd` and `reader_revenue_usd`** - Uses `includes(:currency).sum()` with calculation in Ruby, could be optimized to SQL

## Work in Progress
- None

## Completed Work
- Initial repository analysis completed (2026-06-01)
- Monthly Activity issue created: `[perf-improver] Monthly Activity 2026-06` (issue #1512)
- Validated build/test commands documentation
- `random_readers` identified as a clear inefficiency with straightforward fix

## Run History
- **2026-06-01 08:31 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26739902209)
  - Created Monthly Activity issue #1512 for June 2026
  - Identified `random_readers` as an easy win (loads all IDs into memory before sampling)
  - Previous workflow runs failing (issues #1510, #1511) - investigating

## Backlog Cursor
- Monthly Activity issue created
- `random_readers` fix is low-hanging fruit but method appears unused in codebase
- `order_by_popularity` is highest impact but requires careful measurement