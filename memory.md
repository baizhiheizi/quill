# Efficiency Improver memory

> Persistent state for efficiency-improver runs.
> Verify against `gh` and the repo before acting on stale entries.

## build/test/perf commands

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI | `bin/ci` | setup + rubocop + `bun run lint-check` + `bin/rails test` + `db:seed:replant` |
| Tests | `bin/rails test` | Requires PostgreSQL, `RAILS_ENV=test` |
| Zeitwerk | `bin/rails zeitwerk:check` | Also run in CI |
| Ruby lint | `bin/rubocop` | rails-omakase |
| JS lint | `bun run lint-check` | Prettier check on `app/javascript` |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` | esbuild + tailwind |
| Benchmarks | `bin/benchmark` (filter: `bin/benchmark article_search.subscribed`) | stdlib harness; see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this run container; bench/tests not run locally, CI exercises them. `bun` not on PATH locally; `node_modules/.bin/prettier` works for JS lint locally.

## efficiency notes

- `app/javascript/controllers/floating_controller.js`: scroll listener attached on `document` was never removed, and `connect()` did not exist. Stimulus reconnect on every Turbo navigation accumulated listeners. Fix uses a stored `boundOnScroll` and `disconnect()` cleanup, plus `{ passive: true }`.
- The previous `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- `app/javascript/controllers/auto_refresh_controller.js`: `setInterval(3000)` always re-fetches the same URL via Turbo stream; no ETag/Last-Modified check, so unchanged pages still trigger network + DOM work every3 s.
- `app/javascript/controllers/prefetch_controller.js`: `mouseover` listener has no debounce — every hover (even brief) can append a `<link rel="prefetch">` to `document.head`.

## optimization backlog

| Priority | Focus Area | Item |
|----------|------------|------|
| HIGH | Frontend / UI | ~~`floating_controller` scroll listener leak + broken debounce~~ Done (PR #1560,2026-06-09) |
| MEDIUM | Frontend / UI | `auto_refresh_controller.js` unconditional3 s polling — add ETag/conditional GET or only refresh when content changed |
| MEDIUM | Frontend / UI | `prefetch_controller.js` `mouseover` debouncing / dedupe across links |
| LOW | Frontend / UI | `textarea_autogrow_controller.js` `input` event without debounce on long pastes |
| LOW | Code-Level | `User#available_articles` Ruby-side `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — load up to50 cached rows then `.sample(5)` in Ruby; sample at SQL level |

## work in progress

_(none)_

## completed work

- **PR #1560** (2026-06-09): `app/javascript/controllers/floating_controller.js` — passive listener, correct debounce, `disconnect()` cleanup. Prettier clean; esbuild build clean.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
|1 |2026-06-0923:30 |
|2 |2026-06-0923:30 |
|3 |2026-06-0923:30 |
|4 |2026-06-0923:30 |
|5 |2026-06-0923:30 |
|6 |2026-06-0923:30 |
|7 |2026-06-0923:30 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
