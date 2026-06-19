# Efficiency Improver memory

> Persistent state for efficiency-improver runs. Verify against GitHub before acting on stale entries.

## build/test/perf commands

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI | `bin/ci` | setup + rubocop + `bun run lint-check` + `bin/rails test` + `db:seed:replant` |
| Tests | `bin/rails test` | Needs Postgres, `RAILS_ENV=test` |
| Zeitwerk | `bin/rails zeitwerk:check` | Also in CI |
| Ruby lint | `bin/rubocop` | rails-omakase |
| JS lint | `bun run lint-check` / `node_modules/.bin/prettier --check 'app/javascript/**/*.js'` | Local fallback when `bun` not on PATH |
| JS format | `bun run lint` | Prettier write |
| Assets | `bun run build`, `bun run build:css` / `node esbuild.config.js` | esbuild + tailwind |
| Assets (min) | `node esbuild.config.js --minify` | Use for size measurements |
| Benchmarks | `bin/benchmark article_search.subscribed` | stdlib harness, see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this container; CI exercises Rails tests. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js` work as fallbacks. Pre-existing Prettier warning in `app/javascript/application.js` (not in our touched files). `fs.Stats` deprecation warning from esbuild itself is unrelated.

## efficiency notes

- `floating_controller.js` (PR #1560, merged 2026-06-10): scroll listener attached on `document` was never removed, no `connect()` existed. Stimulus reconnect on every Turbo navigation accumulated listeners. Fix: stored `boundOnScroll` + `disconnect()` cleanup + `{ passive: true }`.
- Old `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- `auto_refresh_controller.js` (PR #1627, merged 2026-06-14): dead code — registered in `index.js` and docs but no view consumed it. Removal: −363 B minified / −720 B dev.
- `infinite_scroll_controller.js` (PR #1632, merged 2026-06-14): IntersectionObserver leak across Turbo navigations (`const observer` was function-local, no `disconnect()`), and per-entry `loadMore()` with no `lastFetchedHref` dedup. Fix: store observer as `this.observer`, `disconnect()`, dedup via `loading` flag + `lastFetchedHref`, collapse `handleIntersect` to `entries.some(...)`. Trade-off: +281 B min. Wired into 35+ views. Follow-up docs PR #1643 documented the pattern.
- `prefetch_controller.js` (PR #1576, merged 2026-06-11): `mouseover` listener was inline arrow with no debounce, fired per mouse movement, could not be removed in `disconnect()`. Also had dead `load()` method (IntersectionObserver path) defined but never wired up.
- `textarea_autogrow_controller.js` (PR #1669, merged 2026-06-16): dead code — `grep -rn 'data-controller="textarea-autogrow"' app/views/ test/` returns zero hits, entire view tree has zero `<textarea>`. Removal: −709 B minified / −1,143 B dev (42 lines / 3 files).
- 7 more dead controllers (`autosave`, `modal`, `reload`, `scroll-to`, `select-menu`, `switch-locale`, `toast`) — PR #1683, merged 2026-06-18 by `an-lee`. 231 lines / 9 files. Bundle minified −2,534 B; dev −6,358 B.
- `auto_hide_controller.js` (PR #1691 → simplification PR #1693 merged 2026-06-19 10:16:25 UTC by `an-lee`, commit `875f03c`): `setTimeout` handle was not stored and not cleared in `disconnect()`. Fix: store as `this.timer`, clear + null in `disconnect()`. Trade-off: +79 B minified / +155 B dev for the new state. Primarily **GC pressure hygiene in long editor sessions**.
- `session_controller.js` (PR opened 2026-06-19, branch `efficiency/session-controller-listener-cleanup`, commit `07f9ad7`): attached `chainChanged` / `disconnect` / `accountsChanged` listeners to `Wallet.web3.currentProvider` and never removed them. Wired into `<body data-controller='session'>` in both `application.html.erb` and `editor.html.erb` — every logged-in page on every navigation. Fix: bind handlers once, store as `this.boundChainChanged` / `this.boundDisconnect` / `this.boundAccountsChanged`, guard each `.on()` with `if (!this.boundXxx)`, and add `disconnect()` that calls `provider.removeListener(event, boundHandler)`. Simulated leak: 20 reconnects → 60 stale handlers before, 0 after. Trade-off: bundle dev +873 B / minified +549 B. Patch at `/tmp/gh-aw/aw-efficiency-session-controller-listener-cleanup.patch`, 4,406 B.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries to one or two short bullet lines (e.g. "🔍 Verified X dead. 🔧 Opened PR (branch Y). 📊 Minified Δ."). Keep the most recent 1–2 runs in full prose.
- No `prefers-reduced-motion` handling in `app/javascript/` — Tailwind `motion-safe:` / `motion-reduce:` available but unused.
- `User#available_articles` (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- `HomeController#hot_tags`: 50 cached rows then `.sample(5)` in Ruby. Tiny impact; SQL `ORDER BY RANDOM() LIMIT 5` cleaner but small gain.
- `safeoutputs create_pull_request` actually creates the PR (PR #1632 from 2026-06-14 was MERGED 2026-06-14 10:37:55 UTC; follow-up #1643 MERGED 2026-06-14 14:19:21 UTC). "Intent only" framing in earlier memory was wrong — PR is real, maintainer reviews/merges later. Patch file persists at `/tmp/gh-aw/aw-efficiency-*.patch`; query GitHub for the actual PR number.
- `safeoutputs update_issue` rewrites the full monthly activity issue body in one call (`operation: "replace"`). Issue number + body work; everything else preserved.

## optimization backlog

| Priority | Focus Area | Item |
|----------|------------|------|
| HIGH | Frontend / UI | ~~`floating_controller` scroll listener leak + broken debounce~~ Done (PR #1560, merged 2026-06-10) |
| MEDIUM | Frontend / UI | ~~`prefetch_controller.js` mouseover listener leak~~ Done (PR #1576, merged 2026-06-11) |
| MEDIUM | Frontend / UI | ~~`auto_refresh_controller.js` dead code~~ Done (PR #1627, merged 2026-06-14) |
| LOW | Frontend / UI | ~~`textarea_autogrow_controller.js` dead code~~ Done (PR #1669, merged 2026-06-16) |
| LOW | Frontend / UI | ~~`infinite_scroll_controller.js` observer leak + dedup~~ Done (PR #1632, merged 2026-06-14) |
| LOW | Frontend / UI | ~~7 more dead controllers~~ Done (PR #1683, merged 2026-06-18) |
| LOW | Frontend / UI | ~~`auto_hide_controller.js` setTimeout leak~~ Done (PR #1691 → #1693, merged 2026-06-19 by `an-lee`) |
| LOW | Frontend / UI | ~~`session_controller.js` wallet listener leak~~ **PR opened 2026-06-19** (branch `efficiency/session-controller-listener-cleanup`, commit `07f9ad7`). Bundle dev +873 B / min +549 B. |
| LOW | Frontend / UI | No `prefers-reduced-motion` handling anywhere — cross-cutting win (mobile battery + accessibility) |
| LOW | Code-Level | `User#available_articles` Ruby `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — `.sample(5)` in Ruby; sample at SQL level |

**Dead-code sweep heuristic** (confirmed and exhausted): a Stimulus controller is dead iff **all** of (a) `grep -rn 'data-controller="<name>"' app/views/ test/`, (b) `grep -rn 'controller: "<name>"' app/views/`, (c) `grep -rn 'data-<name>-target' app/views/`, (d) `grep -rEn '<name>#' app/views/ app/javascript/` return zero hits. **All 9 dead controllers across 3 sweep PRs (#1627, #1669, #1683) are now merged; remaining 42 controllers are all live.**

**Listener-leak sweep pattern** (now confirmed across 4 controllers: `floating`, `prefetch`, `auto_hide`, `session`): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` or `*ValueChanged` callback whose target is global (document, window, singleton wallet, etc.) must store the handle and clear it in `disconnect()`. **No remaining listener-cleanup targets in `app/javascript/controllers/`** — every other controller's effects are local to `this.element`.

## work in progress

_(none — 2026-06-19 PR `efficiency/session-controller-listener-cleanup` (commit `07f9ad7`) is awaiting maintainer review; patch at `/tmp/gh-aw/aw-efficiency-session-controller-listener-cleanup.patch`, 4,406 B. PR # not yet indexed by API at run end.)_

## completed work

- **PR #1560** (merged 2026-06-10): `floating_controller.js` — passive listener, correct debounce, `disconnect()`.
- **PR #1576** (merged 2026-06-11): `prefetch_controller.js` — debounce + `disconnect()` + remove dead `load()`.
- **PR #1627** (merged 2026-06-14): dead-code removal of `auto_refresh_controller.js` — 33 lines / 3 files. Minified −363 B; dev −720 B. Branch `efficiency/remove-dead-auto-refresh-controller`, commit `ef87da2`.
- **PR #1632** (merged 2026-06-14): `infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup. Minified +281 B (+0.005%) — repaid many times over by avoided duplicate fetches per scroll-tick. 35+ views. Follow-up docs PR #1643.
- **PR #1669** (merged 2026-06-16): dead-code removal of `textarea_autogrow_controller.js` — 42 lines / 3 files. Minified −709 B; dev −1,143 B.
- **PR #1683** (merged 2026-06-18 by `an-lee`): dead-code removal of 7 Stimulus controllers — 231 lines / 9 files. Minified −2,534 B; dev −6,358 B. 3.6× prior `textarea_autogrow` win.
- **PR (2026-06-19 first run)**: `auto_hide_controller.js` — store `setTimeout` as `this.timer`, clear in `disconnect()`. Branch `efficiency/auto-hide-controller-cleanup`, commit `617816a`. PR #1691 merged 2026-06-19 02:40:16 UTC; simplification PR #1693 (commit `875f03c`) merged 2026-06-19 10:16:25 UTC by `an-lee`. Min +79 B / dev +155 B.
- **PR (2026-06-19 second run)**: `session_controller.js` — store bound chain/disconnect/accounts handlers and remove in `disconnect()`. Branch `efficiency/session-controller-listener-cleanup`, commit `07f9ad7`. Min +549 B / dev +873 B. Simulated: 20 reconnects → 60 stale handlers before, 0 after.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-19 23:15 |
| 2 | 2026-06-19 23:15 |
| 3 | 2026-06-19 23:15 |
| 4 | 2026-06-19 23:15 |
| 5 | 2026-06-19 23:15 |
| 6 | 2026-06-19 23:15 |
| 7 | 2026-06-19 23:15 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off.)_
- 2026-06-11: PR #1560 (merged 2026-06-10).
- 2026-06-12: PR #1576 (merged 2026-06-11).
- 2026-06-14: PR #1632 (merged 2026-06-14).
- 2026-06-14: PR #1627 (merged 2026-06-14).
- 2026-06-18: PR #1669 (merged 2026-06-16 by `an-lee`).
- 2026-06-19: auto_hide entry removed (PR #1691 → #1693 merged 2026-06-19 10:16:25 UTC by `an-lee`, commit `875f03c`).