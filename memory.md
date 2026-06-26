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
| Benchmarks | `bin/benchmark article_search.subscribed` / `bin/benchmark hot_tags` | stdlib harness, see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this container; CI exercises Rails tests. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js` work as fallbacks. Pre-existing Prettier warning in `app/javascript/application.js` (not in our touched files). `fs.Stats` deprecation warning from esbuild itself is unrelated. `bin/rubocop` cannot inspect `.erb` files directly (reports "unexpected token <" on every HTML tag); validate .erb changes via build + visual inspection, not rubocop.

**Test cache:** `config/environments/test.rb` uses `:null_store`, so `Rails.cache.fetch` always misses in tests. Tests that need to exercise cache behavior must stub or use a different strategy.

## efficiency notes

- **Stimulus `disconnect()` listener leak pattern** (now confirmed across 7 controllers): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element — so `document.querySelector("#modal").addEventListener(...)` is equivalent to `document.addEventListener(...)` from a leak standpoint.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is present in every layout. Sweep `document.querySelector("#modal").addEventListener` calls in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries to one or two short bullet lines. Keep the most recent 1–2 runs in full prose.
- `safeoutputs create_pull_request` returned `success` + saved a local patch/bundle on 2026-06-26 (run 28270555934), but the PR was NOT created on GitHub and the branch was NOT pushed. Patch: `/tmp/gh-aw/aw-efficiency-hot-tags-sql-sample.patch` (5,238 B / 127 lines). Branch: `efficiency/hot-tags-sql-sample` at commit `384200e`. Likely a gh-aw tool limitation, not a workflow error. Will need a follow-up run (or a maintainer push) to land the PR.
- `safeoutputs update_issue` rewrites the full monthly activity issue body in one call (`operation: "replace"`). Issue number + body work; everything else preserved.
- **`safeoutputs push_repo_memory` total file size limit is 12 KB** (10 KB + 20% overhead). Trim older completed PRs into compact one-liners.
- **Lazy-loading sweep pattern**: any `image_tag` / `remote_image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true` (Rails emits `loading="lazy" decoding="async"`). Hero/LCP must stay eager. Remaining non-lazy image_tags are all above-the-fold and intentional.
- **`remote_image_tag` helper** (`app/helpers/application_helper.rb:8`): accepts both `loading:` (Rails standard) and `lazy: true` (mapped to `loading="lazy"`). Confirmed via standalone Ruby test.
- **`User#available_articles`** (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq` materializes two AR relations to Ruby arrays before dedup. Covered by PR #1729 (repo-assist) as SQL `UNION` + `distinct`.
- **`HomeController#active_authors`** (`app/controllers/home_controller.rb:32`): still has `.limit(20).sample(5)` Ruby sample after SQL. Same pattern as `hot_tags` (now fixed). Reasonable next PR; not started.
- **AR `Relation#sample` and `Enumerable#sample` distinction**: `Enumerable#sample` is the only one available on AR Relations in Rails 8 (no AR override). It calls `to_a` first (one SQL), then `Array#sample` in Ruby. So `.limit(50).sample(5)` is always 1 SQL + 1 Ruby sample, not 2 SQLs as some older Rails versions did.
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
| DONE (PR #1719, merged 2026-06-24 by `an-lee`) | prefers-reduced-motion — single global `@media` rule |
| DONE (PR #1733, merged 2026-06-25) | `article_form_controller.js` autosave retry fix |
| DONE (admin row partials already had `lazy: true` in main at 2026-06-25; no PR needed) | admin row icons lazy-loading — 11 icons across 10 row partials |
| DONE (PR draft 2026-06-26 awaiting push) | `efficiency/hot-tags-sql-sample` (commit `384200e`) — `HomeController#hot_tags` SQL `RANDOM()` + cache 5-row Array + benchmark scenario |
| COVERED ELSEWHERE (PR #1729 repo-assist 2026-06-24) | `User#available_articles` SQL `UNION` + `distinct` |
| COVERED ELSEWHERE (PR #1731 repo-assist 2026-06-24) | `Article#author_revenue_usd` / `reader_revenue_usd` `joins(:currency)` |
| COVERED ELSEWHERE (PR #1749 repo-assist 2026-06-26) | `notify_subscribers` SQL subqueries (Article, Collection, Tagging) |
| LOW | `HomeController#active_authors` — `.limit(20).sample(5)` same pattern as fixed `hot_tags` |
| LOW | `Dashboard::NotificationsController#index` — `.select(&:visible_in_web?)` post-load Ruby filter; can only be Ruby because `visible_in_web?` checks per-recipient `notification_setting` |
| LOW | `pre_orders/_payment.html.erb` + `dashboard/destinations/deposit.html.erb` — `pay_asset.icon_url` rendered twice in adjacent divs (main + chain overlay, different sizes); not a duplicate, intentional layered design |

**Sweep patterns** (all applied):
- **Listener-leak sweep** (7 controllers, all merged): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, or the long-lived `#modal` turbo frame) must store the handle and clear it in `disconnect()`. No remaining listener-cleanup targets.
- **Reduced-motion sweep** (PR #1719 merged 2026-06-24): a single global `@media (prefers-reduced-motion: reduce)` rule at the end of the Tailwind input CSS covers all 35+ transition / animation / duration sites without per-call-site maintenance.
- **Lazy-loading sweep** (PR #1714 merged 2026-06-22; admin rows already covered): `image_tag` / `remote_image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true`. Remaining non-lazy `image_tag` calls are all above-the-fold (hero, LCP, brand logos, payment provider buttons) and intentional.
- **SQL-sample sweep** (PR draft 2026-06-26 `hot-tags-sql-sample`): any `.limit(N).sample(K)` where K < N is wasteful — `N` rows are fetched when `K` would do. Move sampling to `order(Arel.sql("RANDOM()")).limit(K)` and cache the already-narrowed K-row Array.
- **Autosave-retry pattern** (PR #1733 merged 2026-06-25): when scheduling a debounced method via `setTimeout`, pass the method reference (`setTimeout(this.autosave, ms)`), not its return value.
- **Dead-code sweep heuristic** (exhausted): a Stimulus controller is dead iff **all** of (a) `grep -rn 'data-controller="<name>"' app/views/ test/`, (b) `grep -rn 'controller: "<name>"' app/views/`, (c) `grep -rn 'data-<name>-target' app/views/`, (d) `grep -rEn '<name>#' app/views/ app/javascript/` return zero hits. All 9 dead controllers across 3 sweep PRs are now merged.

## work in progress

- **PR draft 2026-06-26**: branch `efficiency/hot-tags-sql-sample` (commit `384200e`). `safeoutputs create_pull_request` returned success + saved patch (`/tmp/gh-aw/aw-efficiency-hot-tags-sql-sample.patch`, 5,238 B) but the branch was NOT pushed to `origin` and the PR is NOT visible on GitHub. Per safe-outputs instructions, no second `create_pull_request` call. Maintainer (or a follow-up efficiency-improver run with the same branch intact) can push and create the PR.

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
- PR #1719 (2026-06-22, merged 2026-06-24 by `an-lee`): prefers-reduced-motion — single global `@media` rule.
- PR #1733 (2026-06-24, merged 2026-06-25): autosave-retry-debounce fix.
- Admin row icons (2026-06-25 in main, no PR by me): 11 `lazy: true` added to admin row partials by an unknown contributor.
- PR draft (2026-06-26, awaiting push): `efficiency/hot-tags-sql-sample` (commit `384200e`) — SQL `RANDOM()` + LIMIT 5 + cache 5-row Array + `home.hot_tags` benchmark scenario.

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-26 23:23 |
| 2 | 2026-06-26 23:23 |
| 3 | 2026-06-26 23:23 |
| 4 | 2026-06-26 23:23 |
| 5 | 2026-06-26 23:23 |
| 6 | 2026-06-26 23:23 |
| 7 | 2026-06-26 23:23 |

## monthly summary — checked off by maintainer

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
