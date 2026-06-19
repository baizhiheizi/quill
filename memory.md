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
- `app/javascript/controllers/auto_hide_controller.js` (PR opened 2026-06-19, branch `efficiency/auto-hide-controller-cleanup`, commit `617816a`): `setTimeout` handle was not stored and not cleared in `disconnect()`. Fix: store as `this.timer`, clear + null in `disconnect()`. Trade-off: +79 B minified / +155 B dev for the new state and method. The change was made primarily for **GC pressure hygiene** in long editor sessions, not raw bundle size.
- `app/javascript/controllers/session_controller.js`: attaches `chainChanged`, `disconnect`, `accountsChanged` listeners to the global `Wallet.web3.currentProvider` and never removes them. Stimulus fires `*ValueChanged` on initial connect (when value is non-empty), so every Turbo navigation creates a new session_controller instance and re-registers a fresh set of listeners — N navigations → N listeners firing on each chain/accounts change.
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
| LOW | Frontend / UI | ~~`textarea_autogrow_controller.js` — registered but unused; removed (PR #1669, merged 2026-06-16)~~ |
| LOW | Frontend / UI | ~~`infinite_scroll_controller.js` — observer leak + per-entry loadMore~~ Done (PR #1632, merged 2026-06-14) |
| LOW | Frontend / UI | ~~7 more dead controllers (`autosave`, `modal`, `reload`, `scroll-to`, `select-menu`, `switch-locale`, `toast`) — registered but unused; removed (PR opened 2026-06-18)~~ |
| LOW | Frontend / UI | ~~`auto_hide_controller.js` — store `setTimeout` handle as `this.timer`, clear in `disconnect()`~~ **PR opened 2026-06-19** | +79 B minified (correctness + GC hygiene, not bundle win) |
| LOW | Frontend / UI | `session_controller.js` — store bound `chainChanged` / `disconnect` / `accountsChanged` handlers and remove them in `disconnect()` |
| LOW | Frontend / UI | No `prefers-reduced-motion` handling anywhere — cross-cutting win (mobile battery + accessibility) |
| LOW | Code-Level | `User#available_articles` Ruby-side `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — load up to 50 cached rows then `.sample(5)` in Ruby; sample at SQL level |

**Dead-code sweep heuristic** (now quadruple-confirmed, with 9 controllers removed across 3 runs): a Stimulus controller is dead iff **all** of the following return zero hits: (a) `grep -rn 'data-controller="<name>"' app/views/ test/`, (b) `grep -rn 'controller: "<name>"' app/views/`, (c) `grep -rn 'data-<name>-target' app/views/`, (d) `grep -rEn '<name>#' app/views/ app/javascript/`. The `<wrapped-element>` test from prior runs remains a useful fifth check for element-bound controllers. Common false positives to watch for: `belongs_to ... autosave: true` (Rails), `@article.reload` (Rails), `location.reload()` (inside the dead file itself), `data-turbo-track: "reload"` (HTML asset helper), `document.querySelector("#modal")` (DOM id, not controller), `#toast-slot` (DOM id), `app/javascript/utils/toast.js` (separate utility module, not the Stimulus controller).

**Sweep methodology (now batch-friendly)**: a Python script that parses `index.js` for both single-line and multi-line `register("…", ClassName)` pairs, then runs the 4-query pattern for each. Yields the full candidate list in seconds. Verify by-hand for each candidate to rule out false positives. The 2026-06-12 run found 1 dead controller (`auto_refresh`), 2026-06-16 found 1 (`textarea_autogrow`), 2026-06-18 found 7 in a single batch.

## work in progress

_(none — 2026-06-19 PR `efficiency/auto-hide-controller-cleanup` (commit `617816a`) is awaiting maintainer review; patch at `/tmp/gh-aw/aw-efficiency-auto-hide-controller-cleanup.patch`, 2,115 B)_

## completed work

- **PR #1560** (merged 2026-06-10): `floating_controller.js` — passive listener, correct debounce, `disconnect()` cleanup.
- **PR #1576** (merged 2026-06-11): `prefetch_controller.js` — debounce + `disconnect()` cleanup + remove dead `load()` method.
- **PR #1627** (merged 2026-06-14): dead-code removal of `auto_refresh_controller.js` — 33 lines / 3 files. Bundle minified 5,235,973 B → 5,235,610 B (**−363 B / page**); dev −720 B. Branch `efficiency/remove-dead-auto-refresh-controller`, commit `ef87da2`.
- **PR #1632** (merged 2026-06-14): `infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup. Bundle minified +281 B (+0.005%) — repaid many times over by avoided duplicate fetches per scroll-tick. Branch `efficiency/infinite-scroll-observer-cleanup`, commit `949a005`. Wired into 35+ views. Follow-up docs PR #1643 documented the `this.observer = ...` + `this.observer.disconnect()` pattern.
- **PR #1669** (merged 2026-06-16): dead-code removal of `textarea_autogrow_controller.js` — 42 lines / 3 files. Bundle minified 5,235,891 B → 5,235,182 B (**−709 B / page**); dev −1,143 B. Branch `efficiency/remove-dead-textarea-autogrow-controller`, commit `f86b933`.
- **PR #1683** (merged 2026-06-18 by `an-lee`): dead-code removal of **7 Stimulus controllers** (`autosave`, `modal`, `reload`, `scroll-to`, `select-menu`, `switch-locale`, `toast`) — 231 lines / 9 files. Branch `efficiency/remove-dead-stimulus-controllers-batch`, commit `fd5bcee`. Bundle minified 5,236,359 B → 5,233,825 B (**−2,534 B / page**); dev 10,570,645 B → 10,564,287 B (**−6,358 B**). Roughly 3.6× the prior `textarea_autogrow` win. **All 9 dead controllers across 3 sweep PRs are now merged; remaining 42 are live.**
- **PR (2026-06-19 run)**: `auto_hide_controller.js` — store `setTimeout` handle as `this.timer`, clear in new `disconnect()`. Branch `efficiency/auto-hide-controller-cleanup`, commit `617816a`. Bundle minified 5,233,825 B → 5,233,904 B (+79 B); dev 10,564,287 B → 10,564,442 B (+155 B). Trade-off: +79 B paid in bundle to fix timer leak in long editing sessions. Patch at `/tmp/gh-aw/aw-efficiency-auto-hide-controller-cleanup.patch`.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-19 00:00 |
| 2 | 2026-06-19 00:00 |
| 3 | 2026-06-19 00:00 |
| 4 | 2026-06-19 00:00 |
| 5 | 2026-06-19 00:00 |
| 6 | 2026-06-19 00:00 |
| 7 | 2026-06-19 00:00 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
- 2026-06-11: PR #1560 removed from Suggested Actions (merged 2026-06-10).
- 2026-06-12: PR #1576 removed from Suggested Actions (merged 2026-06-11).
- 2026-06-14: PR #1632 removed from Suggested Actions (merged 2026-06-14).
- 2026-06-14: PR #1627 removed from Suggested Actions (merged 2026-06-14).
- 2026-06-18: PR #1669 removed from Suggested Actions (merged 2026-06-16 by `an-lee`).
