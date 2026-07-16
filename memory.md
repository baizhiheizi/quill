# Efficiency Improver memory

> Persistent state. Verify against GitHub before acting on stale entries.

## commands

| Purpose | Command |
|---------|---------|
| CI | `bin/ci` |
| Tests | `bin/rails test` (needs Postgres) |
| Zeitwerk | `bin/rails zeitwerk:check` |
| Ruby lint | `bin/rubocop` |
| JS lint | `bun run lint-check` / `node_modules/.bin/prettier --check 'app/javascript/**/*.js'` (fallback) |
| Assets | `bun run build` / `node esbuild.config.js`; `--minify` for size measurements |
| Benchmarks | `bin/benchmark <filter>` (stdlib harness) |
| Dev server | `bin/dev` |
| DB | `bin/rails db:prepare` |
| Frontend efficiency | `bin/measure-frontend-efficiency [--json] [--minify]` (PR #1863) |

**Quirks:** No Postgres in this container. `bun` not on PATH; use `node_modules/.bin/prettier` + `node esbuild.config.js`. `rubocop` skips `.erb`/`.md` — inspect Ruby files explicitly. Test cache is `:null_store` — cache tests need stubs. Rails 8.1 — `.includes(...)` is fine; `AssociationPreloader.new(records: …).call(...)` is the lower-level API.

## efficiency notes

- **Stimulus disconnect** (7 swept): addEventListener/setTimeout on global targets needs cleanup. `#modal` turbo frame is long-lived.
- Old `debounce(classList.add(...) ,1000)` was a no-op — wrap function, not return.
- **`safeoutputs update_issue` body cap 10 KB.** Trim Run History.
- **`safeoutputs create_pull_request/create_issue` are INTERMITTENT** (8+ hits). Verify with `search_*` after each call.
- **Push-blocked is a CYCLE**: keep committing locally; maintainer revives (PR #1815, #1834, #1868, #1886 examples).
- **`push_repo_memory` cap 12 KB total**; trim aggressively.
- **Per-row `.count`/`.sum` N+1**: `X.children.count` paginated → 1 SELECT/row. Batched fix: prime `Y.where(parent_id_in: xs.map(&:fk)).group(:fk).count` as ivar; partial reads ivar with `|| x.children.count` fallback.
- **`articles.content` is on `article_references`**, not `Article`. `Article.insert_all!` takes only AR-side columns.
- **UUID FK columns**: `articles.collection_id` is a `uuid` storing the Collection's UUID (not bigint id) because `Collection#articles` uses `primary_key: :uuid`. Group-by queries must use the UUID string.
- **`shared/_avatar` triggers 4-5 SELECTs** per row when not preloaded: `authorization`, `avatar_attachment`, blob, variant_records, image_attachment. Use `admin_user_field_preloads` (or `User::AVATAR_PRELOADS` / `UserFieldPreloads.preloads`) helper.
- **`UserFieldPreloads`** concern at `app/controllers/concerns/user_field_preloads.rb` exposes `user_field_preloads`; `Admin::BaseController` aliases it as `admin_user_field_preloads` (back-compat for all 5+ admin controllers).
- **Polymorphic preload + avatar chain**: `owner: admin_user_field_preloads` works for both Article-owner and User-owner branches. Article-owner rows don't use the chain (no extra SELECTs fire because Rails 7+ polymorphic preload groups by `owner_type` and only follows nested keys present in each target model).
- **`Admin::MixinNetworkUsersController#index`** polymorphic `owner` partial dispatch (`mixin_network_user.owner.is_a? Article|User`): User-owner branch needs `admin_user_field_preloads` for `admin/users/_field.html.erb` → `shared/_avatar`.

## optimization backlog

| Status | Item |
|--------|------|
| DONE | ~30 PRs across 2026-06-09 → 2026-07-13: listener-leak × 7, dead-code (9 + #1867), lazy-loading (29 rows + currencies list), reduced-motion, autosave-retry, SQL-sample × 3, dashboard N+1 (#1802/#1815/#1829/#1830/#1833), admin N+1 (#1834/#1837/#1848/#1862), article-show (#1865), subscribe-lists (#1866), frontend efficiency (#1863). |
| DONE (PR #1868 merged 2026-07-09) | `Admin::CollectionsController#index` batched article count prime (commit `d0742fb`). |
| DONE (PR #1880 merged 2026-07-09) | `Article.with_associations` extended with cover_attachment + author avatar chain (Repo Assist). |
| DONE (PR #1886 merged 2026-07-11 by an-lee, revived from local commit `680d74e`) | `Admin::MixinNetworkSnapshotsController#index` + `#show` eager-load (~450 → ~7 SELECTs/page). |
| DRAFT (this run, commit `09cebcc`, push-blocked?) | `API::ArticlesController#index` author avatar chain (~58 → ~38 SELECTs/page at `limit: 5`; up to ~400 saved at `limit: 100`). Patch + bundle at `/tmp/gh-aw/aw-efficiency-api-articles-author-avatar-preload.{patch,bundle}` (7.4 KB + 4.5 KB). |
| DONE (PR #1902 merged 2026-07-15 by repo-assist, commit `8c246b5`, revived from local `5dd98fc`) | `Admin::MixinNetworkUsersController#index` polymorphic owner + avatar chain (~252 → ~7 SELECTs/page for User-owner rows). |

**Sweep patterns**: Listener-leak · Reduced-motion · Lazy-loading · SQL-sample · Autosave-retry · Dead-code · Dashboard N+1 · Admin N+1 · Article show N+1 · Subscribe-lists · Frontend efficiency helper · Mixin Network Users avatar chain.

## work in progress

- **PR draft 2026-07-16**: `efficiency/api-articles-author-avatar-preload` (commit `09cebcc`, 3 files +93/-1). `.includes(:author, :tags, :currency)` → `.includes(:tags, :currency, author: User::AVATAR_PRELOADS)`. New regression-guard test pins `SELECT_BUDGET = 50` at `limit: 5`. Benchmark scenarios `api.articles.eager_load` + `api.articles.legacy` added. Patch + bundle preserved at `/tmp/gh-aw/aw-efficiency-api-articles-author-avatar-preload.{patch,bundle}`. Github MCP was 503 across all reads during the run; tool response was success but cannot verify the PR appeared — verify on next run with `search_pull_requests`. NOTE: mid-run a linter/user reverted the test + benchmark additions on the main working tree (only the controller change remains there); the branch + commit + patch still contain all 3 files.
- (Merged as #1902) **PR draft 2026-07-14**: `efficiency/admin-mixin-network-users-owner-avatar-preload` (commit `5dd98fc`).
- (Merged as #1868) **PR draft 2026-07-08**: `efficiency/admin-collections-articles-count-prime` (commit `d0742fb`).
- (Merged as #1834) **PR draft 2026-07-05**: `efficiency/admin-indexes-eager-load` (commit `4717fd0`).
- (Merged as #1815) **PR draft 2026-07-02**: `efficiency/dashboard-articles-eager-load`.
- (Closed) **PR drafts**: `benchmarks-readme-update` → #1776; `dashboard-payments-preload` pre-empted by #1830.

## completed work

~31 PRs. Key merges: `an-lee`: #1560, #1576, #1627, #1632, #1669, #1683, #1693, #1702, #1710, #1714, #1719, #1733, #1759, #1765, #1775, #1815, #1834, #1863, #1868, #1886. Repo Assist: #1802, #1811, #1826, #1828, #1829, #1830, #1833, #1837, #1862, #1880. Perf Improver: #1848. Test Improver: #1845.

## last task runs

- 2026-07-16 23:35 UTC (this run): all 7 tasks done. New efficiency PR draft (commit `09cebcc`, push-blocked but patch + bundle on disk for maintainer revival). GitHub MCP returned 503 across all reads during this run.
- 2026-07-14 23:15 UTC: all 7 tasks done + new efficiency PR draft (commit `5dd98fc`, revived as PR #1902 by repo-assist on 2026-07-15).
- 2026-07-13 23:35 UTC: all 7 tasks done + new efficiency PR draft (commit `1b6260a`, also push-blocked but replaced by this run's commit `5dd98fc`).
- 2026-07-09 23:35 UTC: all 7 tasks done + PR #1886 draft (later merged).

## monthly summary — checked off by maintainer

- 2026-06-10 → 2026-06-25: PRs #1560, #1576, #1627, #1632, #1669, #1693, #1702, #1710, #1719, #1733 (an-lee).
- 2026-06-26 → 2026-07-04: #1759, #1765, #1775 (an-lee); #1802 (repo-assist); #1815 (efficiency-improver); #1829/#1830 (repo-assist).
- 2026-07-06: #1833 (repo-assist), #1834 (efficiency-improver revival) — `an-lee`.
- 2026-07-07: #1837 (repo-assist), #1848 (perf-improver) — `an-lee`.
- 2026-07-08: #1862 (repo-assist), #1863 (closes #1720) — `an-lee`.
- 2026-07-09: #1868 (efficiency-improver revival, commit `d0742fb`) — `an-lee`.
- 2026-07-11: #1886 (efficiency-improver revival, commit `680d74e`) — `an-lee`.
- 2026-07-15: #1902 (efficiency-improver revival of local commit `5dd98fc`) — repo-assist.