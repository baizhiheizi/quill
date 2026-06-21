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

**Quirks:** No Postgres in this container; CI exercises Rails tests. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js` work as fallbacks. Pre-existing Prettier warning in `app/javascript/application.js` (not in our touched files). `fs.Stats` deprecation warning from esbuild itself is unrelated. `bin/rubocop` cannot inspect `.erb` files directly (reports "unexpected token <" on every HTML tag); validate .erb changes via build + visual inspection, not rubocop.

## efficiency notes

- **Stimulus `disconnect()` listener leak pattern** (now confirmed across 7 controllers: `floating`, `prefetch`, `auto_hide`, `session`, and 3 modal-listener controllers — `article-form`, `mvm-deposit`, `pre-orders-payment-component`): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element — so `document.querySelector("#modal").addEventListener(...)` is equivalent to `document.addEventListener(...)` from a leak standpoint.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is present in every layout (`application`, `editor`, `homepage`, `admin`). Sweep `document.querySelector("#modal").addEventListener` calls in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries to one or two short bullet lines. Keep the most recent 1–2 runs in full prose.
- `safeoutputs create_pull_request` actually creates the PR (intent is real, maintainer reviews/merges later). Patch file persists at `/tmp/gh-aw/aw-efficiency-*.patch`; query GitHub for the actual PR number.
- `safeoutputs update_issue` rewrites the full monthly activity issue body in one call (`operation: "replace"`). Issue number + body work; everything else preserved.
- **Lazy-loading sweep pattern** (now confirmed across 10 list/table partials): any `image_tag` that renders inside a repeating list row, table row, or notification stream should pass `lazy: true` (which Rails expands to `loading="lazy" decoding="async"`). Hero/LCP images (article cover_url in show view, brand logos in header) must stay eager. **Remaining non-lazy image_tags are all above-the-fold and intentional.**
- **`User#available_articles`** (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- **`HomeController#hot_tags`**: 50 cached rows then `.sample(5)` in Ruby. Tiny impact; SQL `ORDER BY RANDOM() LIMIT 5` cleaner but small gain.
- **`article_form_controller.js:403`** bug: `setTimeout(this.autosave(), 2000);` — calls debounced autosave immediately, then passes `undefined` to setTimeout. Retry never fires. Not a perf issue per se but a logic bug worth flagging.
- **Edit-tool trailing whitespace pitfall**: `Edit` tool collapses trailing spaces inside `<div ...>` attributes. If you write a multi-line old_string that includes a line ending in `.../80"> ` (with trailing space), the new line gets emitted as `.../80">` (no space). When modifying files via Edit, run `python3` (or sed) to restore any accidentally-stripped trailing whitespace before committing.

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
| LOW | Frontend / UI | ~~`#modal` listener leak in 3 controllers~~ **DONE** (PR #1710, merged 2026-06-21 by `an-lee`) |
| MEDIUM | Frontend / UI | List-view `image_tag` calls without `loading="lazy"` — **PR opened 2026-06-21** (branch `efficiency/list-image-lazy-loading`, commit `a874b3d`). 16 images lazy-loaded across 10 partials. Patch at `/tmp/gh-aw/aw-efficiency-list-image-lazy-loading.patch` (12,258 B). |
| LOW | Frontend / UI | No `prefers-reduced-motion` handling anywhere — cross-cutting win (mobile battery + accessibility) |
| LOW | Code-Level | `User#available_articles` Ruby `.uniq` after two `.to_a` — push to SQL `UNION` |
| LOW | Code-Level | `Article#author_revenue_usd` / `reader_revenue_usd` — overlaps with perf-improver backlog |
| LOW | Code-Level | `article_form_controller.js:403` `setTimeout(this.autosave(), 2000)` — autosave retry never fires (logic bug, not perf) |
| LOW | Data | `HomeController#hot_tags` — `.sample(5)` in Ruby; sample at SQL level |

**Dead-code sweep heuristic** (confirmed and exhausted): a Stimulus controller is dead iff **all** of (a) `grep -rn 'data-controller="<name>"' app/views/ test/`, (b) `grep -rn 'controller: "<name>"' app/views/`, (c) `grep -rn 'data-<name>-target' app/views/`, (d) `grep -rEn '<name>#' app/views/ app/javascript/` return zero hits. **All 9 dead controllers across 3 sweep PRs (#1627, #1669, #1683) are now merged; remaining 42 controllers are all live.**

**Listener-leak sweep pattern** (now confirmed across 7 controllers): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` or `*ValueChanged` callback whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. **No remaining listener-cleanup targets in `app/javascript/controllers/`.**

**Lazy-loading sweep pattern** (now confirmed across 10 list-view partials): any `image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true` (Rails emits `loading="lazy" decoding="async"`). **Remaining non-lazy image_tags are all above-the-fold (hero, LCP, brand logos) and intentional.**

## work in progress

_(none — 2026-06-21 PR `efficiency/list-image-lazy-loading` (commit `a874b3d`) is awaiting maintainer review; patch at `/tmp/gh-aw/aw-efficiency-list-image-lazy-loading.patch`, 12,258 B.)_

## completed work

- **PR #1560** (merged 2026-06-10): `floating_controller.js` — passive listener, correct debounce, `disconnect()`.
- **PR #1576** (merged 2026-06-11): `prefetch_controller.js` — debounce + `disconnect()` + remove dead `load()`.
- **PR #1627** (merged 2026-06-14): dead-code removal of `auto_refresh_controller.js` — 33 lines / 3 files. Minified −363 B; dev −720 B.
- **PR #1632** (merged 2026-06-14): `infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup. Minified +281 B (+0.005%) — repaid many times over by avoided duplicate fetches per scroll-tick. 35+ views.
- **PR #1669** (merged 2026-06-16): dead-code removal of `textarea_autogrow_controller.js` — 42 lines / 3 files. Minified −709 B; dev −1,143 B.
- **PR #1683** (merged 2026-06-18 by `an-lee`): dead-code removal of 7 Stimulus controllers — 231 lines / 9 files. Minified −2,534 B; dev −6,358 B.
- **PR #1691 → #1693** (merged 2026-06-19 10:16:25 UTC by `an-lee`, commit `875f03c`): `auto_hide_controller.js` setTimeout leak. Min +79 B / dev +155 B.
- **PR #1702** (merged 2026-06-20 00:17:33 UTC by `an-lee`, commit `07f9ad7`): `session_controller.js` wallet listener leak. Min +549 B / dev +873 B. Simulated 20 reconnects: 60 stale handlers before, 0 after.
- **PR #1710** (merged 2026-06-21 by `an-lee`, commit `c37eb372` → `603cdb64`): modal listener cleanup in 3 controllers (`article-form`, `mvm-deposit`, `pre-orders-payment-component`). Min +732 B / dev +1,230 B. Simulated 20 reconnects: 20 stale listeners each before, 0 after.
- **PR (2026-06-21 run)**: list-view lazy loading — added `lazy: true` to 16 `image_tag` calls across 10 partials (`articles/_card`, `dashboard/articles/_published_article`, `dashboard/articles/_hidden_article`, `dashboard/collections/_collection`, `dashboard/assets/_token`, `dashboard/swap_orders/_swap_order`, `dashboard/transfers/_transfer`, `transfers/_transfer`, `dashboard/notifications/_notification`, `dashboard/payments/_payment`). Branch `efficiency/list-image-lazy-loading`, commit `a874b3d`. 10 files, +16/−16. Patch at `/tmp/gh-aw/aw-efficiency-list-image-lazy-loading.patch` (12,258 B). PR opened via `safeoutputs create_pull_request`; awaiting maintainer review.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-21 23:26 |
| 2 | 2026-06-21 23:26 |
| 3 | 2026-06-21 23:26 |
| 4 | 2026-06-21 23:26 |
| 5 | 2026-06-21 23:26 |
| 6 | 2026-06-21 23:26 |
| 7 | 2026-06-21 23:26 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off.)_
- 2026-06-11: PR #1560 (merged 2026-06-10).
- 2026-06-12: PR #1576 (merged 2026-06-11).
- 2026-06-14: PR #1632 (merged 2026-06-14).
- 2026-06-14: PR #1627 (merged 2026-06-14).
- 2026-06-18: PR #1669 (merged 2026-06-16 by `an-lee`).
- 2026-06-19: auto_hide entry removed (PR #1691 → #1693 merged 2026-06-19 10:16:25 UTC by `an-lee`, commit `875f03c`).
- 2026-06-20: session entry removed (PR #1702 merged 2026-06-20 00:17:33 UTC by `an-lee`, commit `07f9ad7`).
- 2026-06-21: modal-listener entry removed (PR #1710 merged 2026-06-21 by `an-lee`).