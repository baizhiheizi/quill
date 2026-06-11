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
| JS lint (local fallback) | `node_modules/.bin/prettier --check 'app/javascript/**/*.js'` | Use when `bun` is not on PATH |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` | esbuild + tailwind |
| Assets (local fallback) | `node esbuild.config.js` | Use when `bun` is not on PATH |
| Benchmarks | `bin/benchmark` (filter: `bin/benchmark article_search.subscribed`) | stdlib harness; see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this run container; bench/tests not run locally, CI exercises them. `bun` not on PATH locally; `node_modules/.bin/prettier` works for JS lint locally; `node esbuild.config.js` works for build locally.

## efficiency notes

- `app/javascript/controllers/floating_controller.js` (PR #1560, merged 2026-06-10): scroll listener attached on `document` was never removed, and `connect()` did not exist. Stimulus reconnect on every Turbo navigation accumulated listeners. Fix uses a stored `boundOnScroll` and `disconnect()` cleanup, plus `{ passive: true }`.
- The previous `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- `app/javascript/controllers/auto_refresh_controller.js`: `setInterval(3000)` always re-fetches the same URL via Turbo stream; no ETag/Last-Modified check. ALSO: as of 2026-06-11, registered in `index.js` but NOT used in any view (`grep` confirmed no `data-controller="auto-refresh"` in `app/views/`). Dead code, not just inefficient.
- `app/javascript/controllers/prefetch_controller.js` (PR opened 2026-06-11): `mouseover` listener was inline arrow function with no debounce, fired per mouse movement, and could not be removed in `disconnect()`. The controller also had a dead `load()` method (IntersectionObserver path) that was defined but never wired up — neither called from `connect()` nor invoked by any `data-action` in views.
- `app/javascript/controllers/textarea_autogrow_controller.js`: `input` event triggers `autogrow()` without debounce. Controller has `resizeDebounceDelay` value but only uses it for window resize. Each call does `style.height = "auto"` + reads `scrollHeight` + sets `style.height` (forces reflow).
- `User#available_articles` (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(Article.only_free.only_published).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- `HomeController#hot_tags`: 50 cached rows, then `.sample(5)` in Ruby. Tiny impact (50 rows); a SQL `ORDER BY RANDOM() LIMIT 5` would be cleaner but the gain is small.
- `safeoutputs create_pull_request` returns success with a `.patch` and `.bundle` on disk, but the actual PR is created when the workflow exits. The PR is not queryable from GitHub during the agent's lifetime. Document the PR by branch name + commit SHA + patch path; the run-history block in the monthly issue will be picked up by the next run.

## optimization backlog

| Priority | Focus Area | Item |
|----------|------------|------|
| HIGH | Frontend / UI | ~~`floating_controller` scroll listener leak + broken debounce~~ Done (PR #1560, merged 2026-06-10) |
| MEDIUM | Frontend / UI | `prefetch_controller.js` mouseover — DONE in this run (PR submitted via safeoutputs 2026-06-11) |
| MEDIUM | Frontend / UI | `auto_refresh_controller.js` — registered but unused; remove or wire up. If used, add ETag/Last-Modified. |
| LOW | Frontend / UI | `textarea_autogrow_controller.js` — debounce `input` handler with the existing `resizeDebounceDelay` value |
| LOW | Code-Level | `User#available_articles` Ruby-side `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — load up to 50 cached rows then `.sample(5)` in Ruby; sample at SQL level |

## work in progress

_(none — PR for `prefetch_controller` is awaiting maintainer review via safeoutputs intent)_

## completed work

- **PR #1560** (2026-06-09, merged 2026-06-10): `app/javascript/controllers/floating_controller.js` — passive listener, correct debounce, `disconnect()` cleanup. Prettier clean; esbuild build clean.
- **PR (this run, 2026-06-11)**: `app/javascript/controllers/prefetch_controller.js` — debounce + `disconnect()` cleanup + remove dead `load()` method. Branch `efficiency/prefetch-controller-debounce-and-cleanup`, commit `d0334af`. Patch at `/tmp/gh-aw/aw-efficiency-prefetch-controller-debounce-and-cleanup.patch`. Prettier clean; esbuild clean.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
|1 |2026-06-1102:30 |
|2 |2026-06-1102:30 |
|3 |2026-06-1102:30 |
|4 |2026-06-1102:30 |
|5 |2026-06-1102:30 |
|6 |2026-06-1102:30 |
|7 |2026-06-1102:30 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
- 2026-06-11: PR #1560 removed from Suggested Actions (merged 2026-06-10).
