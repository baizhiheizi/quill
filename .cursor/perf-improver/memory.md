# Perf Improver memory

> Persistent state for local `/perf-assist` and `/perf-improver` runs.
> Do not store secrets. Verify against `gh` and the repo before acting on stale entries.

## build/test/perf commands

Validated against `AGENTS.md`, `config/ci.rb`, and `.github/workflows/check.yml` (2026-06-01 local run).

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI locally | `bin/ci` | setup, rubocop, `bun run lint-check`, `bin/rails test`, `db:seed:replant` |
| Tests | `bin/rails test` | Requires PostgreSQL, `RAILS_ENV=test` |
| Zeitwerk | `bin/rails zeitwerk:check` | Also run in CI |
| Ruby lint | `bin/rubocop` | 485 files, no offenses (2026-06-01) |
| JS lint | `bun run lint-check` | Prettier check on `app/javascript` |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` | |
| Dev server | `bin/dev` | Rails + jobs + asset watch |

**Benchmarks:** None detected (`bench/`, `benchmarks/`, criterion, etc.).

**Quirks:** PostgreSQL required for tests; `bin/rails db:prepare` for multi-DB (main, cable, queue). `bundle install` needed if gems missing locally.

## performance notes

- `Article#readers` uses `has_many :readers, -> { distinct }` — PostgreSQL rejects `ORDER BY RANDOM()` on DISTINCT selects; sample via `orders.group(:buyer_id).order(RANDOM()).limit(n)` subquery instead.
- `random_readers` previously used `readers.ids.sample(limit)` — O(all readers) memory.

## optimization backlog

1. **[HIGH] `order_by_popularity` scope** — Complex join; INNER JOIN excludes articles without orders.
2. **[MEDIUM] `ArticleSearchService#subscribed`** — Extra queries for subscribe/owning collection IDs.
3. **[MEDIUM] `ArticleSearchService#bought`** — `bought_articles.ids` → subquery.
4. **[MEDIUM] `DailyStatistic#data_attributes`** — `pluck(:buyer_id).uniq.count` → `distinct.count(:buyer_id)`.
5. **[LOW] `author_revenue_usd` / `reader_revenue_usd`** — Ruby sum vs SQL.

## backlog cursor

Next investigate: `ArticleSearchService#bought` subquery (has test coverage).

## work in progress

_(none)_

## completed work

- **PR #1518** (2026-06-01): `Article#random_readers` SQL sampling — memory O(readers) → O(limit). Tests pass.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-01 12:00 |
| 2 | 2026-06-01 12:00 |
| 3 | 2026-06-01 12:00 |
| 4 | 2026-06-01 12:00 |
| 5 | — |
| 6 | — |
| 7 | 2026-06-01 12:00 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
