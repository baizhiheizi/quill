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

- **Stimulus `disconnect()` listener leak pattern** (now confirmed across 7 controllers: `floating`, `prefetch`, `auto_hide`, `session`, and 3 modal-listener controllers — `article-form`, `mvm-deposit`, `pre-orders-payment-component`): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element — so `document.querySelector("#modal").addEventListener(...)` is equivalent to `document.addEventListener(...)` from a leak standpoint.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is present in every layout (`application`, `editor`, `homepage`, `admin`). Sweep `document.querySelector("#modal").addEventListener` calls in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries to one or two short bullet lines. Keep the most recent 1–2 runs in full prose.
- `safeoutputs create_pull_request` actually creates the PR (intent is real, maintainer reviews/merges later). Patch file persists at `/tmp/gh-aw/aw-efficiency-*.patch`; query GitHub for the actual PR number.
- `safeoutputs update_issue` rewrites the full monthly activity issue body in one call (`operation: "replace"`). Issue number + body work; everything else preserved.
- No `prefers-reduced-motion` handling in `app/javascript/` — Tailwind `motion-safe:` / `motion-reduce:` available but unused.
- `User#available_articles` (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- `HomeController#hot_tags`: 50 cached rows then `.sample(5)` in Ruby. Tiny impact; SQL `ORDER BY RANDOM() LIMIT 5` cleaner but small gain.

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
| LOW | Frontend / UI | ~~`session_controller.js` wallet listener leak~~ **DONE** (PR #1702, merged 2026-06-20 00:17:33 UTC by `an-lee`) |
| LOW | Frontend / UI | `#modal` listener leak in 3 controllers (`article-form`, `mvm-deposit`, `pre-orders-payment-component`) — **PR opened 2026-06-20** (branch `efficiency/modal-listener-cleanup`, commit `c37eb372`). Simulated 20 reconnects: 20 stale listeners each before, 0 after. Bundle dev +1,230 B / min +732 B. |
| LOW | Frontend / UI | No `prefers-reduced-motion` handling anywhere — cross-cutting win (mobile battery + accessibility) |
| LOW | Code-Level | `User#available_articles` Ruby `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Data | `HomeController#hot_tags` — `.sample(5)` in Ruby; sample at SQL level |

**Dead-code sweep heuristic** (confirmed and exhausted): a Stimulus controller is dead iff **all** of (a) `grep -rn 'data-controller="<name>"' app/views/ test/`, (b) `grep -rn 'controller: "<name>"' app/views/`, (c) `grep -rn 'data-<name>-target' app/views/`, (d) `grep -rEn '<name>#' app/views/ app/javascript/` return zero hits. **All 9 dead controllers across 3 sweep PRs (#1627, #1669, #1683) are now merged; remaining 42 controllers are all live.**

**Listener-leak sweep pattern** (now confirmed across 7 controllers: `floating`, `prefetch`, `auto_hide`, `session`, and the 3 modal-listener controllers): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` or `*ValueChanged` callback whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. **No remaining listener-cleanup targets in `app/javascript/controllers/`** — every other controller's effects are local to `this.element`.

## work in progress

_(none — 2026-06-20 PR `efficiency/modal-listener-cleanup` (commit `c37eb372`) is awaiting maintainer review; patch at `/tmp/gh-aw/aw-efficiency-modal-listener-cleanup.patch`, 8,359 B.)_

## completed work

- **PR #1560** (merged 2026-06-10): `floating_controller.js` — passive listener, correct debounce, `disconnect()`.
- **PR #1576** (merged 2026-06-11): `prefetch_controller.js` — debounce + `disconnect()` + remove dead `load()`.
- **PR #1627** (merged 2026-06-14): dead-code removal of `auto_refresh_controller.js` — 33 lines / 3 files. Minified −363 B; dev −720 B.
- **PR #1632** (merged 2026-06-14): `infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup. Minified +281 B (+0.005%) — repaid many times over by avoided duplicate fetches per scroll-tick. 35+ views.
- **PR #1669** (merged 2026-06-16): dead-code removal of `textarea_autogrow_controller.js` — 42 lines / 3 files. Minified −709 B; dev −1,143 B.
- **PR #1683** (merged 2026-06-18 by `an-lee`): dead-code removal of 7 Stimulus controllers — 231 lines / 9 files. Minified −2,534 B; dev −6,358 B.
- **PR #1691 → #1693** (merged 2026-06-19 10:16:25 UTC by `an-lee`, commit `875f03c`): `auto_hide_controller.js` setTimeout leak. Min +79 B / dev +155 B.
- **PR #1702** (merged 2026-06-20 00:17:33 UTC by `an-lee`, commit `07f9ad7`): `session_controller.js` wallet listener leak. Min +549 B / dev +873 B. Simulated 20 reconnects: 60 stale handlers before, 0 after.
- **PR (2026-06-20 run)**: modal listener cleanup in 3 controllers (`article-form`, `mvm-deposit`, `pre-orders-payment-component`) — store bound handler as `this.boundModalOk`, guard `addEventListener`, add `disconnect()`. Branch `efficiency/modal-listener-cleanup`, commit `c37eb372`. Simulated 20 reconnects: 20 stale listeners each before, 0 after. Bundle dev +1,230 B / min +732 B. PR opened via `safeoutputs create_pull_request`; awaiting maintainer review.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-20 23:26 |
| 2 | 2026-06-20 23:26 |
| 3 | 2026-06-20 23:26 |
| 4 | 2026-06-20 23:26 |
| 5 | 2026-06-20 23:26 |
| 6 | 2026-06-20 23:26 |
| 7 | 2026-06-20 23:26 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off.)_
- 2026-06-11: PR #1560 (merged 2026-06-10).
- 2026-06-12: PR #1576 (merged 2026-06-11).
- 2026-06-14: PR #1632 (merged 2026-06-14).
- 2026-06-14: PR #1627 (merged 2026-06-14).
- 2026-06-18: PR #1669 (merged 2026-06-16 by `an-lee`).
- 2026-06-19: auto_hide entry removed (PR #1691 → #1693 merged 2026-06-19 10:16:25 UTC by `an-lee`, commit `875f03c`).