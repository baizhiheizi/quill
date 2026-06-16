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

**Quirks:** No Postgres in this run container; bench/tests not run locally, CI exercises them. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js`, and `node esbuild.config.js --minify` work for JS lint/build/minify locally. Pre-existing Prettier warning in `app/javascript/application.js` (not in our touched files). Pre-existing `fs.Stats` deprecation warning from esbuild itself (unrelated to our work).

## efficiency notes

- `app/javascript/controllers/floating_controller.js` (PR #1560, merged 2026-06-10): scroll listener attached on `document` was never removed, and `connect()` did not exist. Stimulus reconnect on every Turbo navigation accumulated listeners. Fix uses a stored `boundOnScroll` and `disconnect()` cleanup, plus `{ passive: true }`.
- The previous `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- `app/javascript/controllers/auto_refresh_controller.js` (PR #1627, merged 2026-06-14): dead code — registered in `index.js` and listed in docs, but no view consumed it. Removal: −363 B minified / −720 B unminified.
- `app/javascript/controllers/infinite_scroll_controller.js` (PR #1632, merged 2026-06-14): IntersectionObserver leak across Turbo navigations (`const observer` was function-local, no `disconnect()`), and per-entry `loadMore()` fires with no `lastFetchedHref` dedup. Fix: store observer as `this.observer`, add `disconnect()`, dedup via `loading` flag + `lastFetchedHref`, collapse `handleIntersect` to `entries.some(...)`. Trade-off: +281 B minified for the new state. Follow-up docs PR #1643 (Update Docs agent) documented the `this.observer = ...` + `this.observer.disconnect()` pattern.
- `app/javascript/controllers/prefetch_controller.js` (PR #1576, merged 2026-06-11): `mouseover` listener was inline arrow function with no debounce, fired per mouse movement, and could not be removed in `disconnect()`. Controller also had a dead `load()` method (IntersectionObserver path) that was defined but never wired up — neither called from `connect()` nor invoked by any `data-action` in views.
- `app/javascript/controllers/textarea_autogrow_controller.js` (PR opened this run, branch `efficiency/remove-dead-textarea-autogrow-controller`, commit `f86b933`): same dead-code pattern as `auto_refresh_controller` — registered in `index.js` and listed in docs, but `grep -rn 'data-controller="textarea-autogrow"' app/views/ test/` returns zero hits, no `autosize`/`autogrow` reference in any view, and the entire view tree contains zero `<textarea>` elements. Removal: −709 B minified / −1,143 B unminified (3 files / 42 lines removed).
- `app/javascript/controllers/auto_hide_controller.js`: `setTimeout` handle is not stored as `this.timer` and not cleared in `disconnect()`. If the controller disconnects before the timeout fires, the callback still runs against a detached element.
- `app/javascript/controllers/session_controller.js`: attaches `chainChanged`, `disconnect`, `accountsChanged` listeners to the global `Wallet.web3.currentProvider` and never removes them. If Turbo reconnects the controller, listeners accumulate on the provider.
- No `prefers-reduced-motion` handling anywhere in `app/javascript/` — Tailwind `motion-safe:` / `motion-reduce:` variants are available but unused on this code path.
- `User#available_articles` (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(Article.only_free.only_published).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- `HomeController#hot_tags`: 50 cached rows, then `.sample(5)` in Ruby. Tiny impact (50 rows); a SQL `ORDER BY RANDOM() LIMIT 5` would be cleaner but the gain is small.
- `safeoutputs create_pull_request` actually creates the PR (PR #1632 from the 2026-06-14 run was MERGED 2026-06-14 10:37:55 UTC, and the follow-up PR #1643 was MERGED 2026-06-14 14:19:21 UTC). The "intent only" framing in earlier memory was wrong — the PR is real, the maintainer reviews and merges it later. The patch file persists at `/tmp/gh-aw/aw-efficiency-*.patch` for run history; query GitHub for the actual PR number.
- `safeoutputs update_issue` can rewrite the full monthly activity issue body in one call (use `operation: "replace"` with the full body string). Issue number + body work; everything else is preserved.

## optimization backlog

| Priority | Focus Area | Item |
|----------|------------|------|
| HIGH | Frontend / UI | ~~`floating_controller` scroll listener leak + broken debounce~~ Done (PR #1560, merged 2026-06-10) |
| MEDIUM | Frontend / UI | ~~`prefetch_controller.js` mouseover — DONE (PR #1576, merged 2026-06-11)~~ |
| MEDIUM | Frontend / UI | ~~`auto_refresh_controller.js` — registered but unused; removed (PR #1627, merged 2026-06-14)~~ |
| LOW | Frontend / UI | ~~`textarea_autogrow_controller.js` — registered but unused; removed (PR opened 2026-06-16)~~ |
| LOW | Frontend / UI | ~~`infinite_scroll_controller.js` — observer leak + per-entry loadMore~~ Done (PR #1632, merged 2026-06-14) |
| LOW | Frontend / UI | `auto_hide_controller.js` — store `setTimeout` handle as `this.timer`, clear in `disconnect()` |
| LOW | Frontend / UI | `session_controller.js` — store bound `chainChanged` / `disconnect` / `accountsChanged` handlers and remove them in `disconnect()` |
| LOW | Frontend / UI | No `prefers-reduced-motion` handling anywhere — cross-cutting win (mobile battery + accessibility) |
| LOW | Code-Level | `User#available_articles` Ruby-side `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — load up to 50 cached rows then `.sample(5)` in Ruby; sample at SQL level |

**Dead-code sweep heuristic** (now twice-confirmed): a controller is dead iff `grep -rn 'data-controller="<name>"' app/views/ test/` returns zero hits AND the view tree contains no relevant markup element. For Stimulus controllers, also check `grep -rn '<controller-keyword>' app/views/` for the element/component name. The 2026-06-12 run found `auto_refresh_controller` this way (the `setInterval(3000)` was a latent energy cost too), and the 2026-06-16 run found `textarea_autogrow_controller` the same way.

**Hidden dead code check**: also `grep -rln '<element-name>' app/views/` to detect controllers that auto-grow or wrap a DOM element when the view tree no longer contains any such element. For Quill's article-centric view tree, the absence of `<textarea>` is the smoking gun for `textarea-autogrow`.

## work in progress

_(none — `textarea_autogrow_controller.js` removal PR is awaiting maintainer review; branch `efficiency/remove-dead-textarea-autogrow-controller`, commit `f86b933`, patch at `/tmp/gh-aw/aw-efficiency-remove-dead-textarea-autogrow-controller.patch`, 4893 B)_

## completed work

- **PR #1560** (2026-06-09, merged 2026-06-10): `app/javascript/controllers/floating_controller.js` — passive listener, correct debounce, `disconnect()` cleanup. Prettier clean; esbuild build clean.
- **PR #1576** (2026-06-11, merged 2026-06-11): `app/javascript/controllers/prefetch_controller.js` — debounce + `disconnect()` cleanup + remove dead `load()` method. Branch `efficiency/prefetch-controller-debounce-and-cleanup`. Prettier clean; esbuild clean.
- **PR #1627** (2026-06-12, merged 2026-06-14): dead-code removal of `app/javascript/controllers/auto_refresh_controller.js` — 33 lines across 3 files. Branch `efficiency/remove-dead-auto-refresh-controller`, commit `ef87da2`. Bundle minified 5,235,973 B → 5,235,610 B (−363 B per page load, every user, every page); unminified dev build −720 B. Prettier clean; esbuild build + minify both clean.
- **PR #1632** (2026-06-14, merged 2026-06-14): `app/javascript/controllers/infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup. Branch `efficiency/infinite-scroll-observer-cleanup`, commit `949a005`. Bundle minified 5,235,973 B → 5,236,254 B (+281 B; the +281 B buys dedup state, a `try/finally`, and a `disconnect()` that prevents the observer leak across Turbo navigations — the avoided duplicate fetches per scroll-tick more than repay the byte cost). Prettier clean; esbuild + minify both clean. Wired into 35+ views. Follow-up docs PR #1643 (Update Docs agent) documented the `this.observer = ...` + `this.observer.disconnect()` pattern.
- **PR (2026-06-16 run)**: dead-code removal of `app/javascript/controllers/textarea_autogrow_controller.js` — 42 lines across 3 files. Branch `efficiency/remove-dead-textarea-autogrow-controller`, commit `f86b933`. Bundle minified 5,235,891 B → 5,235,182 B (−709 B per page load, every user, every page); unminified dev build −1,143 B. Prettier clean; esbuild build + minify both clean. Same pattern as PR #1627.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-16 01:16 |
| 2 | 2026-06-16 01:16 |
| 3 | 2026-06-16 01:16 |
| 4 | 2026-06-16 01:16 |
| 5 | 2026-06-16 01:16 |
| 6 | 2026-06-16 01:16 |
| 7 | 2026-06-16 01:16 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
- 2026-06-11: PR #1560 removed from Suggested Actions (merged 2026-06-10).
- 2026-06-12: PR #1576 removed from Suggested Actions (merged 2026-06-11).
- 2026-06-14: PR #1632 removed from Suggested Actions (merged 2026-06-14).
- 2026-06-14: PR #1627 removed from Suggested Actions (merged 2026-06-14).
