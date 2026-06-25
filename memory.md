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
- **Lazy-loading sweep pattern**: any `image_tag` / `remote_image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true` (Rails emits `loading="lazy" decoding="async"`). Hero/LCP must stay eager. Remaining non-lazy image_tags are all above-the-fold and intentional.
- **`remote_image_tag` helper** (`app/helpers/application_helper.rb:8`): accepts both `loading:` (Rails standard) and `lazy: true` (mapped to `loading="lazy"`). Confirmed via standalone Ruby test (see Run 2026-06-25).
- **`User#available_articles`** (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Covered by PR #1729 (repo-assist) as SQL `UNION` + `distinct`.
- **`HomeController#hot_tags`**: 50 cached rows then `.sample(5)` in Ruby. Tiny impact; SQL `ORDER BY RANDOM() LIMIT 5` cleaner but small gain.
- **Edit-tool trailing whitespace pitfall**: `Edit` tool collapses trailing spaces inside `<div ...>` attributes. When modifying files via Edit, run `python3` (or sed) to restore any accidentally-stripped trailing whitespace before committing.

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
| DONE (PR #1719, merged 2026-06-24 by `an-lee`) | prefers-reduced-motion — single global `@media` rule covering 35+ transition sites |
| DONE (PR #1733, merged 2026-06-25) | `article_form_controller.js` autosave retry fix — 60% fewer XHRs on flaky network |
| DONE (PR draft 2026-06-25, awaiting push) | `efficiency/admin-row-icons-lazy-loading` — 11 admin list-row icons lazy-loaded (commit `6c278753`, patch 8,884 B) |
| COVERED ELSEWHERE (PR #1729 repo-assist 2026-06-24) | `User#available_articles` SQL `UNION` + `distinct` |
| COVERED ELSEWHERE (PR #1731 repo-assist 2026-06-24) | `Article#author_revenue_usd` / `reader_revenue_usd` `joins(:currency)` |
| LOW | `HomeController#hot_tags` — `.sample(5)` in Ruby; sample at SQL level |

**Reduced-motion sweep pattern** (applied via PR #1719, merged 2026-06-24): a single global `@media (prefers-reduced-motion: reduce)` rule at the end of the Tailwind input CSS covers all 35+ transition / animation / duration sites without per-call-site maintenance.

**Listener-leak sweep pattern** (applied across 7 controllers, all merged): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, or the long-lived `#modal` turbo frame) must store the handle and clear it in `disconnect()`. No remaining listener-cleanup targets.

**Lazy-loading sweep pattern** (PR #1714 merged 2026-06-22 + PR draft 2026-06-25): `image_tag` / `remote_image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true`. Admin row icons + currency icons + asset icons all sweep-able.

## work in progress

_(none — 2026-06-25 PR draft `efficiency/admin-row-icons-lazy-loading` (head commit `6c278753`) is awaiting maintainer review; PR opened via `safeoutputs create_pull_request`.)_

## completed work

- PR #1560 (2026-06-10): `floating_controller.js` — passive listener + correct debounce + `disconnect()`.
- PR #1576 (2026-06-11): `prefetch_controller.js` — debounce + `disconnect()` + remove dead `load()`.
- PR #1627 (2026-06-14): dead-code `auto_refresh_controller.js`, min −363 B / dev −720 B.
- PR #1632 (2026-06-14): `infinite_scroll_controller.js` IntersectionObserver cleanup + fetch dedup across 35+ views.
- PR #1669 (2026-06-16): dead-code `textarea_autogrow_controller.js`, min −709 B / dev −1,143 B.
- PR #1683 (2026-06-18): 7 dead controllers, min −2,534 B / dev −6,358 B.
- PR #1693 (2026-06-19): `auto_hide_controller.js` setTimeout leak.
- PR #1702 (2026-06-20): `session_controller.js` wallet listener leak.
- PR #1710 (2026-06-21): modal listener cleanup in 3 controllers.
- PR #1714 (2026-06-22 by `an-lee`): list-view lazy loading — 16 `image_tag` calls across 10 partials now `lazy: true`.
- PR #1719 (2026-06-22, merged 2026-06-24 by `an-lee`): prefers-reduced-motion — single global `@media (prefers-reduced-motion: reduce)` rule.
- PR #1733 (2026-06-24, merged 2026-06-25): autosave-retry-debounce — `article_form_controller.js:406` `setTimeout(this.autosave(), 2000)` → `setTimeout(this.autosave, 2000)`.
- PR (2026-06-25, awaiting push): admin-row-icons-lazy-loading — `lazy: true` on 11 currency/asset icons across 10 admin row partials.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-25 23:29 |
| 2 | 2026-06-25 23:29 |
| 3 | 2026-06-25 23:29 |
| 4 | 2026-06-25 23:29 |
| 5 | 2026-06-25 23:29 |
| 6 | 2026-06-25 23:29 |
| 7 | 2026-06-25 23:29 |

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
- 2026-06-24: PR #1719 (merged 2026-06-24 01:54:29 UTC by `an-lee`).
- 2026-06-25: PR #1733 (autosave retry fix) MERGED.