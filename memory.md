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
| Assets (minified, production) | `node esbuild.config.js --minify` | Use for size measurements |
| Benchmarks | `bin/benchmark` (filter: `bin/benchmark article_search.subscribed`) | stdlib harness; see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this run container; bench/tests not run locally, CI exercises them. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js`, and `node esbuild.config.js --minify` work for JS lint/build/minify locally.

## efficiency notes

- `app/javascript/controllers/floating_controller.js` (PR #1560, merged 2026-06-10): scroll listener attached on `document` was never removed, and `connect()` did not exist. Stimulus reconnect on every Turbo navigation accumulated listeners. Fix uses a stored `boundOnScroll` and `disconnect()` cleanup, plus `{ passive: true }`.
- The previous `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- `app/javascript/controllers/auto_refresh_controller.js`: `setInterval(3000)` always re-fetches the same URL via Turbo stream; no ETag/Last-Modified check. ALSO: registered in `index.js` and listed in `docs/reference/stimulus-controllers.md` but NOT used in any view (`grep -rn 'data-controller="auto-refresh"' app/views/ test/` returns zero hits). **Removed 2026-06-12 in this run.**
- `app/javascript/controllers/prefetch_controller.js` (PR #1576, merged 2026-06-11): `mouseover` listener was inline arrow function with no debounce, fired per mouse movement, and could not be removed in `disconnect()`. Controller also had a dead `load()` method (IntersectionObserver path) that was defined but never wired up — neither called from `connect()` nor invoked by any `data-action` in views.
- `app/javascript/controllers/textarea_autogrow_controller.js`: `input` event triggers `autogrow()` without debounce. Controller has `resizeDebounceDelay` value but only uses it for window resize. Each call does `style.height = "auto"` + reads `scrollHeight` + sets `style.height` (forces reflow). Also: `disconnect()` only removes `resize` listener, not the `input` listener it attached.
- `app/javascript/controllers/infinite_scroll_controller.js`: `createObserver()` stores the new `IntersectionObserver` as a local variable `observer`, never `this.observer`, so `disconnect()` (none exists) cannot call `observer.disconnect()`. Each Turbo navigation accumulates one observer per infinite-scroll container.
- `app/javascript/controllers/infinite_scroll_controller.js#handleIntersect`: calls `loadMore()` per entry with no debounce; on the same callback tick with multiple intersecting entries, multiple fetches fire. `loadMore()` also doesn't memoize the last-fetched URL, so after a stream append the same `next` link can fire repeatedly while still in the viewport.
- `app/javascript/controllers/auto_hide_controller.js`: `setTimeout` handle is not stored as `this.timer` and not cleared in `disconnect()`. If the controller disconnects before the timeout fires, the callback still runs against a detached element.
- `app/javascript/controllers/session_controller.js`: attaches `chainChanged`, `disconnect`, `accountsChanged` listeners to the global `Wallet.web3.currentProvider` and never removes them. If Turbo reconnects the controller, listeners accumulate on the provider.
- No `prefers-reduced-motion` handling anywhere in `app/javascript/` — Tailwind `motion-safe:` / `motion-reduce:` variants are available but unused on this code path.
- `User#available_articles` (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(Article.only_free.only_published).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- `HomeController#hot_tags`: 50 cached rows, then `.sample(5)` in Ruby. Tiny impact (50 rows); a SQL `ORDER BY RANDOM() LIMIT 5` would be cleaner but the gain is small.
- `safeoutputs create_pull_request` returns success with a `.patch` and `.bundle` on disk, but the actual PR is created when the workflow exits. The PR is not queryable from GitHub during the agent's lifetime. Document the PR by branch name + commit SHA + patch path; the run-history block in the monthly issue will be picked up by the next run.
- `safeoutputs update_issue` can rewrite the full monthly activity issue body in one call (use `operation: "replace"` with the full body string). Issue number + body work; everything else is preserved.

## optimization backlog

| Priority | Focus Area | Item |
|----------|------------|------|
| HIGH | Frontend / UI | ~~`floating_controller` scroll listener leak + broken debounce~~ Done (PR #1560, merged 2026-06-10) |
| MEDIUM | Frontend / UI | ~~`prefetch_controller.js` mouseover — DONE (PR #1576, merged 2026-06-11)~~ |
| MEDIUM | Frontend / UI | ~~`auto_refresh_controller.js` — registered but unused; removed 2026-06-12~~ |
| LOW | Frontend / UI | `textarea_autogrow_controller.js` — debounce `input` handler with the existing `resizeDebounceDelay` value; also remove the `input` listener in `disconnect()` |
| LOW | Frontend / UI | `infinite_scroll_controller.js` — store observer as `this.observer`, add `disconnect()` that calls `this.observer.disconnect()` |
| LOW | Frontend / UI | `infinite_scroll_controller.js#handleIntersect` — debounce / dedupe `loadMore()` calls and track last-fetched URL |
| LOW | Frontend / UI | `auto_hide_controller.js` — store `setTimeout` handle as `this.timer`, clear in `disconnect()` |
| LOW | Frontend / UI | `session_controller.js` — store bound `chainChanged` / `disconnect` / `accountsChanged` handlers and remove them in `disconnect()` |
| LOW | Frontend / UI | No `prefers-reduced-motion` handling anywhere — cross-cutting win (mobile battery + accessibility) |
| LOW | Code-Level | `User#available_articles` Ruby-side `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — load up to 50 cached rows then `.sample(5)` in Ruby; sample at SQL level |

## work in progress

_(none — PR for `auto_refresh_controller.js` removal is awaiting maintainer review via safeoutputs intent; patch at `/tmp/gh-aw/aw-efficiency-remove-dead-auto-refresh-controller.patch`, branch `efficiency/remove-dead-auto-refresh-controller`, commit `ef87da2`)_

## completed work

- **PR #1560** (2026-06-09, merged 2026-06-10): `app/javascript/controllers/floating_controller.js` — passive listener, correct debounce, `disconnect()` cleanup. Prettier clean; esbuild build clean.
- **PR #1576** (2026-06-11, merged 2026-06-11): `app/javascript/controllers/prefetch_controller.js` — debounce + `disconnect()` cleanup + remove dead `load()` method. Branch `efficiency/prefetch-controller-debounce-and-cleanup`. Prettier clean; esbuild clean.
- **PR (this run, 2026-06-12)**: dead-code removal of `app/javascript/controllers/auto_refresh_controller.js` — 33 lines across 3 files. Branch `efficiency/remove-dead-auto-refresh-controller`, commit `ef87da2`. Patch at `/tmp/gh-aw/aw-efficiency-remove-dead-auto-refresh-controller.patch`. Bundle minified 5,235,973 B → 5,235,610 B (−363 B per page load); unminified 10,569,786 B → 10,569,066 B (−720 B). Prettier clean; esbuild build + minify both clean.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
|1 |2026-06-1223:30 |
|2 |2026-06-1223:30 |
|3 |2026-06-1223:30 |
|4 |2026-06-1223:30 |
|5 |2026-06-1223:30 |
|6 |2026-06-1223:30 |
|7 |2026-06-1223:30 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
- 2026-06-11: PR #1560 removed from Suggested Actions (merged 2026-06-10).
- 2026-06-12: PR #1576 removed from Suggested Actions (merged 2026-06-11).