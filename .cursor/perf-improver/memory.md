# Perf Improver memory

> Persistent state for local `/perf-assist` and `/perf-improver` runs.
> Do not store secrets. Verify against `gh` and the repo before acting on stale entries.
>
> **Full `/perf-improver` runs:** memory updates must be committed on the run branch and included in the draft PR for that run (including memory-only runs).

## build/test/perf commands

Validated against `AGENTS.md`, `config/ci.rb`, and `.github/workflows/check.yml` (2026-06-02 local run).

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI locally | `bin/ci` | setup, rubocop, `bun run lint-check`, `bin/rails test`, `db:seed:replant` |
| Tests | `bin/rails test` | Requires PostgreSQL, `RAILS_ENV=test` |
| Zeitwerk | `bin/rails zeitwerk:check` | Also run in CI |
| Ruby lint | `bin/rubocop` | daily_statistic.rb clean (2026-06-02) |
| JS lint | `bun run lint-check` | Prettier check on `app/javascript` |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` | |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| **Benchmarks** | `bin/benchmark` | All scenarios; `bin/benchmark article_search.bought` filters |
| Benchmark docs | `test/benchmarks/README.md` | Stdlib harness merged via #1522 / issue #1520 |

**Quirks:** PostgreSQL required for tests; `bin/rails db:prepare` for multi-DB (main, cable, queue). Run `bundle install` after pulling main when Gemfile.lock changes.

**Ad-hoc perf check:**
```bash
RAILS_ENV=test bin/rails runner "require 'benchmark'; ..."
```

## performance notes

- `Article#readers` uses `has_many :readers, -> { distinct }` — PostgreSQL rejects `ORDER BY RANDOM()` on DISTINCT selects; sample via `orders.group(:buyer_id).order(RANDOM()).limit(n)` subquery instead.
- `random_readers` previously used `readers.ids.sample(limit)` — O(all readers) memory.
- `ArticleSearchService#bought`: use `select(:id)` subquery instead of `.ids` — avoids materializing all bought article IDs in Ruby and drops one round-trip query.
- `DailyStatistic#data_attributes`: `pluck(:buyer_id).uniq.count` → `distinct.count(:buyer_id)` for `paid_users_count` and `new_payers_count` — COUNT(DISTINCT) in DB instead of loading all buyer IDs into Ruby (daily job path).

## optimization backlog

1. **[HIGH] `order_by_popularity` scope** — Complex join; INNER JOIN excludes articles without orders.
2. **[MEDIUM] `ArticleSearchService#subscribed`** — Extra queries for subscribe/owning collection IDs.
3. ~~**[MEDIUM] `ArticleSearchService#bought`** — `bought_articles.ids` → subquery.~~ Done (2026-06-01 run).
4. ~~**[MEDIUM] `DailyStatistic#data_attributes`** — distinct count in SQL.~~ Done (2026-06-02 run).
5. **[LOW] `author_revenue_usd` / `reader_revenue_usd`** — Ruby sum vs SQL (DailyStatistic transfer sums already use SQL).

## backlog cursor

Next investigate: `order_by_popularity` scope (item 1) or `ArticleSearchService#subscribed` (item 2).

## work in progress

_(none)_

## completed work

- **PR #1518** (2026-06-01, merged): `Article#random_readers` SQL sampling — memory O(readers) → O(limit).
- **Run 2026-06-01 bought subquery**: `ArticleSearchService#bought` uses `select(:id)` subquery; tests pass; SQL verified in test env.
- **Issue #1520** (2026-06-01): Proposed lightweight benchmark harness (Task 6).
- **#1522 / `bin/benchmark`** (merged 2026-06-02): stdlib hot-path harness on main.
- **Run 2026-06-02 DailyStatistic**: `paid_users_count` / `new_payers_count` use `distinct.count(:buyer_id)`; rubocop + job test pass.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-02 12:00 |
| 2 | 2026-06-02 12:00 |
| 3 | 2026-06-02 12:00 |
| 4 | 2026-06-02 12:00 |
| 5 | 2026-06-01 14:00 |
| 6 | 2026-06-01 14:00 |
| 7 | 2026-06-02 12:00 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
