# Efficiency Improver memory

> Persistent state. Verify against GitHub before acting on stale entries.

## commands

| Purpose | Command |
|---------|---------|
| CI | `bin/ci` |
| Tests | `bin/rails test` (full task currently requires Bun); targeted fallback: `bin/rails test <paths>` after CSS build |
| Zeitwerk | `bin/rails zeitwerk:check` |
| Ruby lint | `bin/rubocop` |
| JS lint | `bun run lint-check`; fallback `node_modules/.bin/prettier --check 'app/javascript/**/*.js'` |
| Assets | `bun run build`; fallbacks `node esbuild.config.js` and `node_modules/.bin/tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css` |
| Benchmarks | `bin/benchmark <filter>` (stdlib harness) |
| Frontend efficiency | `bin/measure-frontend-efficiency [--json] [--minify]` |
| Dev server / DB | `bin/dev`; `bin/rails db:prepare` |

**Quirks (verified 2026-07-20):** PostgreSQL is available. Bun is not on PATH although `package.json` pins Bun; `bin/rails test` without paths aborts in `test:prepare` because cssbundling cannot install dependencies. Building CSS with the local Tailwind CLI lets targeted Rails tests run. `node_modules/.bin/prettier --check` currently reports a pre-existing warning in `app/javascript/application.js`. `bin/rubocop` skips `.erb`/`.md`; inspect view diffs explicitly. Test cache is `:null_store`.

## efficiency notes

- **Counter caches:** `articles.comments_count` is maintained by `Comment.belongs_to :commentable, counter_cache: true`; views should read the column, not `article.comments.count`.
- **Stimulus cleanup:** global listeners/timers and third-party widgets need `disconnect`; `#modal` turbo frame is long-lived.
- Old `debounce(classList.add(...), 1000)` was a no-op — wrap a function, not a return value.
- **Per-row aggregates:** batch with one grouped query and hash lookup; do not change financial distribution paths without strong tests/maintainer signal.
- **Avatar preload:** use `User::AVATAR_PRELOADS` / `UserFieldPreloads.preloads`; polymorphic Rails preload groups by owner type.
- `articles.content` is on `article_references`; `articles.collection_id` stores a Collection UUID.
- Safe-output monthly issue body should stay under 10 KB; repo-memory should stay under 12 KB.
- **2026-07-20:** PhotoSwipeLightbox.destroy() properly cleans up click handlers from gallery elements, clears internal listeners, and destroys any open PhotoSwipe instance. Verified in `node_modules/photoswipe/dist/photoswipe-lightbox.esm.js:1946`.

## optimization backlog

| Priority | Focus area | Opportunity / status | Measurement strategy |
|----------|------------|----------------------|----------------------|
| DONE | Code-Level | PRs #1919 and #1920 merged 2026-07-17: API articles author avatar preload. | SELECT budget at API limit 5; up to ~400 SELECTs avoided at limit 100. |
| DONE | Code-Level | Replace two `Article#comments.count` view calls with `comments_count`. | Static query sites 2 → 0; verified on main (all views use `comments_count`). |
| DRAFT PR (this run) | Frontend/UI | Destroy PhotoSwipe on Stimulus disconnect — branch `efficiency/photoswipe-disconnect-20260720`, commit `eac6e0a`. | Listener-leak tool shows 0 for `addEventListener` pairs; PhotoSwipe internal listeners (below tool visibility) now cleaned up via `destroy()`. |
| HIGH | Network/I/O | Pause `pre_orders_state_component_controller.js` polling while `document.hidden`; consider measured backoff separately. | Hidden-tab requests: 40/min → 0; foreground behavior must remain unchanged. |
| HIGH / maintainer signal | Data | `Orders::DistributeService` walks article references/authors and collection-order buyers without batching. Financial path; do not change casually. | SQL notifications around representative distributions; compare SELECT count by N. |
| MEDIUM | Frontend/UI | Clear clipboard success timeout on disconnect (clipboard_controller.js). | Timer handle survives Turbo navigation if `copied()` was recently triggered. |
| MEDIUM | Data | Cache home platform stats (3 aggregate queries) with explicit freshness/invalidation policy. | Aggregate SQL count on cold vs warm requests; document staleness trade-off. |
| LOW | Frontend/UI | Avoid re-highlighting already processed code blocks. | Browser scripting time on a code-heavy article. |
| DONE | Broad sweep | Listener leaks ×7, reduced motion, lazy loading, dead code, SQL sampling, autosave retry, Dashboard/Admin/public/API N+1 families, frontend measurement helper. | See merged PR history below. |

**Backlog cursor:** next run should verify the pre-order polling hidden-tab opportunity, then consider clipboard timeout cleanup or home stats caching.

## work in progress

- **2026-07-20 draft PR (this run):** branch `efficiency/photoswipe-disconnect-20260720`, commit `eac6e0a`, 1 file +7/-0. Adds `disconnect()` → `this.lightbox.destroy()`. JS build passes, Prettier clean.

## completed work

Key Efficiency Improver merges by `an-lee`: #1560, #1576, #1627, #1632, #1669, #1683, #1693, #1702, #1710, #1714, #1719, #1733, #1759, #1765, #1775, #1815, #1834, #1863, #1868, #1886, #1919, #1920. Related merges by Repo Assist / Perf Improver include #1802, #1811, #1826, #1828, #1829, #1830, #1833, #1837, #1848, #1862, #1880, #1902.

## last task runs

- 2026-07-20 22:18 UTC: Tasks 3, 7. Created draft PR for PhotoSwipe disconnect cleanup (branch `efficiency/photoswipe-disconnect-20260720`). Updated monthly activity issue #1817.
- 2026-07-20 04:15 UTC: selected Tasks 4, 2, 3 + mandatory 7. No open Efficiency Improver PRs; #1919/#1920 verified merged. Four-area scan completed. Implemented article comments counter-cache view reads (`635b102`).
- 2026-07-16 23:35 UTC: all tasks; API articles author avatar preload drafted (`09cebcc`), later merged as #1919/#1920.
- 2026-07-14 23:15 UTC: all tasks; Mixin Network Users owner/avatar preload drafted, later merged as #1902.
- 2026-07-09 23:35 UTC: all tasks; Mixin snapshots preload drafted, later merged as #1886.

## monthly summary — checked off / actioned

- 2026-06-10 → 2026-07-15: previously recorded PRs through #1902 were checked off or merged; do not re-add them.
- 2026-07-17: #1919 and #1920 merged by `an-lee`; remove the prior API-avatar review action.
- 2026-07-17: issue #1911 closed; remove the prior comment-review action.
- 2026-07-20 22:18: counter-cache item removed from suggested actions (code already applied to main); PhotoSwipe draft PR added.
