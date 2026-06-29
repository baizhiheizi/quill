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
| Benchmarks | `bin/benchmark article_search.subscribed` / `bin/benchmark hot_tags` / `bin/benchmark home.active_authors` / `bin/benchmark home.active_authors.legacy` / `bin/benchmark article.random_readers` | stdlib harness, see `test/benchmarks/README.md` |
| Dev server | `bin/dev` | Rails + jobs + asset watch |
| DB setup | `bin/rails db:prepare` | main + cable + queue |

**Quirks:** No Postgres in this container; CI exercises Rails tests. `bun` not on PATH locally; `node_modules/.bin/prettier`, `node esbuild.config.js` work as fallbacks. Pre-existing Prettier warning in `app/javascript/application.js` (not in our touched files). `fs.Stats` deprecation warning from esbuild itself is unrelated. `bin/rubocop` cannot inspect `.erb` files directly (reports "unexpected token <" on every HTML tag); validate .erb changes via build + visual inspection, not rubocop.

**Test cache:** `config/environments/test.rb` uses `:null_store`, so `Rails.cache.fetch` always misses in tests. Tests that need to exercise cache behavior must stub or use a different strategy.

## efficiency notes

- **Stimulus `disconnect()` listener leak pattern** (now confirmed across 7 controllers): any `addEventListener` / `setTimeout` / `.on(...)` in `connect()` whose target is global (document, window, singleton wallet, **or the long-lived `#modal` turbo frame**) must store the handle and clear it in `disconnect()`. Turbo frames are long-lived — only contents swap, not the element — so `document.querySelector("#modal").addEventListener(...)` is equivalent to `document.addEventListener(...)` from a leak standpoint.
- **`#modal` singleton**: `turbo_frame_tag 'modal'` is present in every layout. Sweep `document.querySelector("#modal").addEventListener` calls in any controller's `connect()` for missing `disconnect()` cleanup.
- Old `debounce(classList.add(...),1000)` pattern was a no-op (`classList.add` returns undefined). Always wrap the function in `debounce(fn, ms)`, not its return value.
- **`safeoutputs update_issue` body limit is 10 KB per call.** Trim by collapsing older Run History entries to one or two short bullet lines.
- **`safeoutputs create_pull_request` limitation — 4/4 occurrences (2026-06-26, 27, 28, 29)**: returns `success` + saves a local patch (`/tmp/gh-aw/aw-<branch>.patch`) but does NOT push the branch or create the PR on GitHub. Maintainer has been manually applying patches. **Do not retry.**
- `safeoutputs update_issue` rewrites the full monthly activity issue body in one call (`operation: "replace"`).
- **`safeoutputs push_repo_memory` total file size limit is 12 KB** (10 KB + 20% overhead). Trim older completed PRs into compact one-liners.
- **Lazy-loading sweep pattern**: any `image_tag` / `remote_image_tag` inside a repeating list row, table row, or notification stream should pass `lazy: true` (Rails emits `loading="lazy" decoding="async"`). Hero/LCP must stay eager.
- **`remote_image_tag` helper** (`app/helpers/application_helper.rb:8`): accepts both `loading:` (Rails standard) and `lazy: true`.
- **`User#available_articles`** (`app/models/user.rb:168`): Ruby-side `(bought_articles.only_published.to_a + articles.only_published.or(...).to_a).uniq`. Covered by PR #1729 (repo-assist) as SQL `UNION` + `distinct`.
- **AR `Relation#sample` and `Enumerable#sample` distinction**: `Enumerable#sample` is the only one available on AR Relations in Rails 8 (no AR override). It calls `to_a` first (one SQL), then `Array#sample` in Ruby. So `.limit(50).sample(5)` is always 1 SQL + 1 Ruby sample, not 2 SQLs.
- **Edit-tool trailing whitespace pitfall**: `Edit` tool collapses trailing spaces inside `<div ...>` attributes.
- **`active_authors` cache vs no-cache decision**: `hot_tags` is cached because it's locale-only; `active_authors` is NOT cached because the sample depends on per-visitor blocked-user filters — caching would return identical authors to every signed-in user regardless of their blocks. Both share the SQL-sample pattern (`ORDER BY RANDOM() LIMIT K`).
- **`remote_image_tag` in `currencies/_list.html.erb`**: this is the modal search-results grid; it now has `lazy: true` (PR `currencies-list-lazy-loading`). All other `remote_image_tag` calls without `lazy: true` are in singleton detail headers (`admin/*/show.html.erb`, `articles/_header.html.erb`, `articles/_option_fields.html.erb`, `collections/show.html.erb`, `dashboard/destinations/deposit.html.erb`) — intentional, as eager loading is correct for hero/LCP/interactive UI.

## optimization backlog

| Status | Item |
|--------|------|
| DONE | 16 PRs across 2026-06-09 → 2026-06-29 (listener-leak × 7, dead-code × 9 controllers across 3 PRs, lazy-loading × 29 rows, reduced-motion, autosave-retry, hot-tags-sql-sample, active-authors-sql-sample, buyers-view-sql-sample, currencies-list-lazy-loading, benchmarks-readme-update). See "completed work" for the full list with PR numbers. |
| DONE (PR #1759 merged 2026-06-28) | `active-authors-sql-sample` — `HomeController#active_authors` SQL `RANDOM()` + LIMIT 5, no cache (per-visitor block-filter); 2 benchmark scenarios (new + legacy) |
| DONE (applied to main by `an-lee` 2026-06-26 without GitHub PR — safeoutputs limitation) | `hot-tags-sql-sample` — `HomeController#hot_tags` SQL `RANDOM()` + LIMIT 5 + cache 5-row Array |
| DONE (PR #1765 merged 2026-06-29) | `buyers-view-sql-sample` — `articles/_buyers.html.erb` `article.readers.sample(24)` → `article.random_readers(24)` (SQL `RANDOM() LIMIT 24`); also `any?` → `exists?` |
| DONE (PR draft 2026-06-29 awaiting push) | `currencies-list-lazy-loading` — `currencies/_list.html.erb` lines 22-23: `lazy: true` on currency icon + chain icon |
| DONE (PR draft 2026-06-29 awaiting push) | `benchmarks-readme-update` — `test/benchmarks/README.md` Scenarios table now lists the `home.active_authors` entries (added by PR #1759) |
| COVERED ELSEWHERE (PR #1729, 1731, 1749 repo-assist) | `User#available_articles`, `Article#author_revenue_usd`/`reader_revenue_usd`, `notify_subscribers` SQL subqueries |
| LOW | `Dashboard::NotificationsController#index` — `.select(&:visible_in_web?)` is intentional (per-recipient `notification_setting` only accessible in Ruby) |
| LOW | `pre_orders/_payment.html.erb` + `dashboard/destinations/deposit.html.erb` — `pay_asset.icon_url` rendered twice in adjacent divs (main + chain overlay, different sizes); intentional layered design |
| EXHAUSTED | Listener-leak, reduced-motion, lazy-loading, dead-code, `.limit(N).sample(K)` on hot paths — all known anti-patterns addressed. SQL-sample sweep closed by hot-tags + active-authors + buyers-view PRs. Lazy-loading sweep closed by PR #1714 + admin rows + currencies list (now 29 rows total). |

**Sweep patterns** (all applied):
- **Listener-leak sweep** (7 controllers, all merged)
- **Reduced-motion sweep** (PR #1719): single global `@media (prefers-reduced-motion: reduce)` rule covers all 35+ transition/animation/duration sites
- **Lazy-loading sweep** (PR #1714 + admin row partials + currencies list): `image_tag`/`remote_image_tag` inside repeating list/table/notification rows should pass `lazy: true`
- **SQL-sample sweep** (3 PRs: hot_tags, active_authors, buyers-view): `.limit(N).sample(K)` is wasteful. Move to `order(Arel.sql("RANDOM()")).limit(K)`. Cache only if the sample does not depend on per-visitor data.
- **Autosave-retry pattern** (PR #1733): `setTimeout(this.autosave, ms)`, not `setTimeout(this.autosave(), ms)`
- **Dead-code sweep heuristic** (exhausted): Stimulus controller is dead iff grep for `data-controller="<name>"`, `controller: "<name>"`, `data-<name>-target`, and `<name>#` all return zero hits. All 9 dead controllers merged.

## work in progress

- **PR draft 2026-06-29**: branch `efficiency/currencies-list-lazy-loading` (commit `f1836f8`). Patch at `/tmp/gh-aw/aw-efficiency-currencies-list-lazy-loading.patch` (2,471 B, 53 lines). 4th occurrence of safeoutputs `create_pull_request` returning success but not pushing. Maintainer expected to apply manually as with prior patches.
- **PR draft 2026-06-29**: branch `efficiency/benchmarks-readme-update` (commit `7f6f3a3`). Patch at `/tmp/gh-aw/aw-efficiency-benchmarks-readme-update.patch` (3,973 B, 91 lines). Same safeoutputs limitation; awaiting manual apply.

## completed work

- PRs #1560, #1576, #1627, #1632, #1669, #1683, #1693, #1702, #1710, #1714 (by an-lee), #1719 (by an-lee, merged), #1733 (merged), #1759 (active-authors-sql-sample, merged 2026-06-28), #1765 (buyers-view-sql-sample, merged 2026-06-29) — see "monthly summary — checked off by maintainer" for dates
- Admin row icons (2026-06-25 in main, no PR by me): 11 `lazy: true` added to admin row partials
- hot-tags-sql-sample (2026-06-26, applied to main by `an-lee` without GitHub PR)
- active-authors-sql-sample (PR #1759, merged 2026-06-28 by an-lee)
- buyers-view-sql-sample (PR #1765, merged 2026-06-29 by an-lee)
- currencies-list-lazy-loading (2026-06-29, awaiting manual push)
- benchmarks-readme-update (2026-06-29, awaiting manual push)

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-29 23:36 |
| 2 | 2026-06-29 23:36 |
| 3 | 2026-06-29 23:36 |
| 4 | 2026-06-29 23:36 |
| 5 | 2026-06-29 23:36 |
| 6 | 2026-06-29 23:36 |
| 7 | 2026-06-29 23:36 |

## monthly summary — checked off by maintainer

- 2026-06-10 → 2026-06-25: PRs #1560, #1576, #1627, #1632, #1669, #1693, #1702, #1710, #1719, #1733 all merged by `an-lee`.
- 2026-06-26: hot-tags-sql-sample optimization applied to main by `an-lee` (PR not on GitHub — safeoutputs limitation).
- 2026-06-28: PR #1759 (active-authors-sql-sample) merged by `an-lee`.
- 2026-06-29: PR #1765 (buyers-view-sql-sample) merged by `an-lee`.