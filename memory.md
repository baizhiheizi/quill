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

**Quirks:** No Postgres in this container. `bun` not on PATH; use `node_modules/.bin/prettier` + `node esbuild.config.js`. `rubocop` skips `.erb`. Test cache is `:null_store` — cache tests need stubs.

## efficiency notes

- **Stimulus disconnect** (7 swept): addEventListener/setTimeout on global targets needs cleanup. `#modal` turbo frame is long-lived.
- Old `debounce(classList.add(...) ,1000)` was a no-op — wrap function, not return.
- **`safeoutputs update_issue` body cap 10 KB.** Trim Run History.
- **`safeoutputs create_pull_request/create_issue` are INTERMITTENT** (8+ hits). Verify with `search_*` after each call.
- **Push-blocked is a CYCLE**: keep committing locally; maintainer revives (PR #1815, #1834 examples).
- **`push_repo_memory` cap 12 KB total**; trim aggressively.
- **Per-row `.count`/`.sum` N+1**: `X.children.count` paginated → 1 SELECT/row. Batched fix: prime `Y.where(parent_id_in: xs.map(&:fk)).group(:fk).count` as ivar; partial reads ivar with `|| x.children.count` fallback.
- **`articles.content` is on `article_references`**, not `Article`. `Article.insert_all!` takes only AR-side columns.
- **UUID FK columns**: `articles.collection_id` is a `uuid` storing the Collection's UUID (not bigint id) because `Collection#articles` uses `primary_key: :uuid`. Group-by queries must use the UUID string.

## optimization backlog

| Status | Item |
|--------|------|
| DONE | ~30 PRs across 2026-06-09 → 2026-07-08: listener-leak × 7, dead-code (9 + #1867), lazy-loading (29 rows + currencies list), reduced-motion, autosave-retry, SQL-sample × 3, dashboard N+1 (#1802/#1815/#1829/#1830/#1833), admin N+1 (#1834/#1837/#1848/#1862), article-show (#1865), subscribe-lists (#1866), frontend efficiency (#1863). |
| DRAFT (commit `d0742fb`, push-blocked 2026-07-08) | `Admin::CollectionsController#index` batched article count prime. Patch + bundle at `/tmp/gh-aw/aw-efficiency-admin-collections-articles-count-prime.{patch,bundle}`. |
| NEW (next-run candidate) | `Admin::WalletsController#index` — smallest admin index gap. |
| OPEN (no action) | #1776 — `benchmarks-readme-update`. |

**Sweep patterns**: Listener-leak · Reduced-motion · Lazy-loading · SQL-sample · Autosave-retry · Dead-code · Dashboard N+1 · Admin N+1 · Article show N+1 · Subscribe-lists · Frontend efficiency helper.

## work in progress

- **PR draft 2026-07-08**: `efficiency/admin-collections-articles-count-prime` (commit `d0742fb`, 3 files +150/-1). 8th intermittent `create_pull_request` success/no-PR.
- (Merged as #1834) **PR draft 2026-07-05**: `efficiency/admin-indexes-eager-load` (commit `4717fd0`). 4 controllers.
- (Merged as #1815) **PR draft 2026-07-02**: `efficiency/dashboard-articles-eager-load`.
- (Closed) **PR drafts**: `benchmarks-readme-update` → #1776; `dashboard-payments-preload` pre-empted by #1830.

## completed work

~30 PRs. Key merges: `an-lee`: #1560, #1576, #1627, #1632, #1669, #1683, #1693, #1702, #1710, #1714, #1719, #1733, #1759, #1765, #1775, #1815, #1834, #1863. Repo Assist: #1802, #1811, #1826, #1828, #1829, #1830, #1833, #1837, #1862. Perf Improver: #1848. Test Improver: #1845.

## last task runs

All 7 tasks: 2026-07-08 23:35 UTC.

## monthly summary — checked off by maintainer

- 2026-06-10 → 2026-06-25: PRs #1560, #1576, #1627, #1632, #1669, #1693, #1702, #1710, #1719, #1733 (an-lee).
- 2026-06-26 → 2026-07-04: #1759, #1765, #1775 (an-lee); #1802 (repo-assist); #1815 (efficiency-improver); #1829/#1830 (repo-assist).
- 2026-07-06: #1833 (repo-assist), #1834 (efficiency-improver revival) — `an-lee`.
- 2026-07-07: #1837 (repo-assist), #1848 (perf-improver) — `an-lee`.
- 2026-07-08: #1862 (repo-assist), #1863 (closes #1720) — `an-lee`.
