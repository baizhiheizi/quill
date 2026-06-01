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
1. **[HIGH] `order_by_popularity` scope** - Complex join with orders table, calculates SQL expression per row including POW/EXTRACT. Articles without orders are excluded (INNER JOIN behavior). Missing index on `orders.value_usd`. Consider adding cached popularity score or LEFT JOIN.
2. **[MEDIUM] `ArticleSearchService#subscribed` filter** - Potential N+1 with `subscribe_user_ids` and `owning_collection_ids` that may execute additional queries
3. **[MEDIUM] `Article#author_revenue_usd` and `Article#reader_revenue_usd`** - Uses `includes(:currency).sum()` with calculation in Ruby, could be optimized to SQL
4. **[LOW] `random_readers(limit)`** - `readers.ids.sample(limit)` loads all reader IDs into memory before sampling

## Work in Progress
- None

## Completed Work
- Initial repository analysis completed (2026-06-01)
- Monthly Activity issue created: `[perf-improver] Monthly Activity 2026-06`
- Validated build/test commands documentation

## Run History
- **2026-06-01 00:15 UTC** - Initial analysis run
  - Identified `order_by_popularity` as highest priority optimization target
  - Ruby/Bun not available in runner - code analysis only

## Backlog Cursor
- Completed initial discovery phase
- Ready to implement optimizations when Ruby/Bun available
