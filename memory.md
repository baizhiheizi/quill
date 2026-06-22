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

- **Stimulus `disconnect()` listener leak pattern** (now confirmed across 7 controllers): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element — so `document.querySelector("#modal").addEventListener(...)` is equivalent to `document.addEventListener(...)` from a leak standpoint.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is present in every layout. Sweep `document.querySelector("#modal").addEventListener` calls in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries to one or two short bullet lines. Keep the most recent 1–2 runs in full prose.
- `safeoutputs create_pull_request` actually creates the PR (intent is real, maintainer reviews/merges later). Patch file persists at `/tmp/gh-aw/aw-efficiency-*.patch`; query GitHub for the actual PR number.
- `safeoutputs update_issue` rewrites the full monthly activity issue body in one call (`operation: "replace"`). Issue number + body work; everything else preserved.
- **`safeoutputs push_repo_memory` total file size limit is 12 KB** (10 KB + 20% overhead). Trim older completed PRs into compact one-liners.
- **Lazy-loading sweep pattern**: any `image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true` (Rails emits `loading="lazy" decoding="async"`). Hero/LCP must stay eager. Remaining non-lazy image_tags are all above-the-fold and intentional.
- **`User#available_articles`** (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Could be `Article.published.where(...).union(...)`.
- **`HomeController#hot_tags`**: 50 cached rows then `.sample(5)` in Ruby. Tiny impact; SQL `ORDER BY RANDOM() LIMIT 5` cleaner but small gain.
- **`article_form_controller.js:403`** bug: `setTimeout(this.autosave(), 2000);` — calls debounced autosave immediately, then passes `undefined` to setTimeout. Retry never fires. Not a perf issue per se but a logic bug worth flagging.
- **Edit-tool trailing whitespace pitfall**: `Edit` tool collapses trailing spaces inside `<div ...>` attributes. If you write a multi-line old_string that includes a line ending in `.../80"> ` (with trailing space), the new line gets emitted as `.../80">` (no space). When modifying files via Edit, run `python3` (or sed) to restore any accidentally-stripped trailing whitespace before committing.

## optimization backlog

| Status | Item |
|--------|------|
| DONE (PR #1560, 2026-06-10) | `floating_controller` scroll listener leak |
| DONE (PR #1576, 2026-06-11) | `prefetch_controller.js` mouseover listener leak |
| DONE (PR #1627, 2026-06-14) | `auto_refresh_controller.js` dead code, min −363 B |
| DONE (PR #1632, 2026-06-14) | `infinite_scroll_controller.js` observer leak + dedup |
| DONE (PR #1669, 2026-06-16) | `textarea_autogrow_controller.js` dead code, min −709 B |
| DONE (PR #1683, 2026-06-18) | 7 more dead controllers, min −2,534 B |
| DONE (PR #1693, 2026-06-19) | `auto_hide_controller.js` setTimeout leak |
| DONE (PR #1702, 2026-06-20) | `session_controller.js` wallet listener leak |
| DONE (PR #1710, 2026-06-21) | `#modal` listener leak in 3 controllers |
| DONE (PR #1714, 2026-06-22 by `an-lee`) | 16 list-view images lazy-loaded |
| **PR OPENED 2026-06-22** (branch `efficiency/prefers-reduced-motion`, commit `cbf2b9a`) | No `prefers-reduced-motion` handling anywhere — 35+ GPU-using sites collapse to <1ms; CSS bundle +320 B (+0.062%) |
| LOW | `User#available_articles` Ruby `.uniq` after two `.to_a` (push to SQL `UNION`) |
| LOW | `Article#author_revenue_usd` / `reader_revenue_usd` Ruby sums |
| LOW | `article_form_controller.js:403` `setTimeout(this.autosave(), 2000)` — autosave retry never fires (logic bug) |
| LOW | `HomeController#hot_tags` — `.sample(5)` in Ruby; sample at SQL level |

**Reduced-motion sweep pattern** (now applied via single global rule, commit `cbf2b9a`): add `@media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation-duration: 0.001ms !important; transition-duration: 0.001ms !important; animation-iteration-count: 1 !important; scroll-behavior: auto !important; } }` once at the end of the Tailwind input CSS. Covers all 35+ transition / animation / duration sites in `app/views/` without per-call-site maintenance.

**Dead-code sweep heuristic** (confirmed and exhausted): a Stimulus controller is dead iff all of (a) `grep -rn 'data-controller="<name>"' app/views/ test/`, (b) `grep -rn 'controller: "<name>"' app/views/`, (c) `grep -rn 'data-<name>-target' app/views/`, (d) `grep -rEn '<name>#' app/views/ app/javascript/` return zero hits. All 9 dead controllers across 3 sweep PRs are merged; remaining 42 controllers are all live.

**Listener-leak sweep pattern**: applied across 7 controllers, all merged. No remaining listener-cleanup targets in `app/javascript/controllers/`.

## work in progress

_(none — 2026-06-22 PR `efficiency/prefers-reduced-motion` (commit `cbf2b9a`) is awaiting maintainer review; patch at `/tmp/gh-aw/aw-efficiency-prefers-reduced-motion.patch`, 4,051 B.)_

## completed work

- PR #1560 (2026-06-10): `floating_controller.js` — passive listener + correct debounce + `disconnect()`.
- PR #1576 (2026-06-11): `prefetch_controller.js` — debounce + `disconnect()` + remove dead `load()`.
- PR #1627 (2026-06-14): dead-code `auto_refresh_controller.js`, min −363 B / dev −720 B.
- PR #1632 (2026-06-14): `infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup across 35+ views.
- PR #1669 (2026-06-16): dead-code `textarea_autogrow_controller.js`, min −709 B / dev −1,143 B.
- PR #1683 (2026-06-18): 7 dead controllers, min −2,534 B / dev −6,358 B.
- PR #1693 (2026-06-19): `auto_hide_controller.js` setTimeout leak.
- PR #1702 (2026-06-20): `session_controller.js` wallet listener leak (commit `07f9ad7`).
- PR #1710 (2026-06-21): modal listener cleanup in 3 controllers.
- PR #1714 (2026-06-22 by `an-lee`): list-view lazy loading — 16 `image_tag` calls across 10 partials now `lazy: true`. Patch `/tmp/gh-aw/aw-efficiency-list-image-lazy-loading.patch` (12,258 B).
- PR (2026-06-22, awaiting review): prefers-reduced-motion — single global `@media (prefers-reduced-motion: reduce)` rule in `app/assets/stylesheets/application.tailwind.css`. 1 file, +21/-0. Branch `efficiency/prefers-reduced-motion`, commit `cbf2b9a`. CSS bundle 512,752 B → 513,072 B (+0.062%). Patch `/tmp/gh-aw/aw-efficiency-prefers-reduced-motion.patch` (4,051 B).

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-22 23:45 |
| 2 | 2026-06-22 23:45 |
| 3 | 2026-06-22 23:45 |
| 4 | 2026-06-22 23:45 |
| 5 | 2026-06-22 23:45 |
| 6 | 2026-06-22 23:45 |
| 7 | 2026-06-22 23:45 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off.)_
- 2026-06-11: PR #1560 (merged 2026-06-10).
- 2026-06-12: PR #1576 (merged 2026-06-11).
- 2026-06-14: PR #1632 (merged 2026-06-14).
- 2026-06-14: PR #1627 (merged 2026-06-14).
- 2026-06-18: PR #1669 (merged 2026-06-16 by `an-lee`).
- 2026-06-19: PR #1693 (merged 2026-06-19 by `an-lee`).
- 2026-06-20: PR #1702 (merged 2026-06-20 by `an-lee`).
- 2026-06-21: PR #1710 (merged 2026-06-21 by `an-lee`).
- 2026-06-22: PR #1714 (merged 2026-06-22 00:16:52 UTC by `an-lee`).
