# Perf Improver Memory

## Repository
baizhiheizi/quill — Rails 8.1 monolith (Web3 paid-publishing). Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild.

## Validated Commands
- `bundle install --jobs4 --retry3`, `bun install --frozen-lockfile`
- `bin/dev`, `bin/ci`
- `bin/rails test` — `unset CI` first; **Postgres NOT available locally** (CI is authoritative)
- `bin/rails zeitwerk:check`, `bin/rubocop`, `bun run lint-check`
- `bin/benchmark` — scenarios: `dashboard.orders`, `dashboard.transfers`, `home.active_authors`, `article_search.subscribed`, `article.random_readers`, `admin.users`, `admin.collections`, `api.articles`

## Performance Backlog
1. **DONE** Notifications SQL — PRs #1695/#1749/#1760/#1767. Admin user-list aggregates — PR #1708.
2. **DONE** `active_authors` block subquery — PR #1735. `hot_tags` SQL sampling — PR #1752. `author_revenue_usd` / `reader_revenue_usd` — PR #1731.
3. **DONE Dashboard N+1 base** — PRs #1802/#1815/#1829/#1830/#1833. Merged 07-01→07-06.
4. **DONE Admin N+1 family** — PR #1834 (Orders/Payments/Transfers/Bonuses). PR #1837 (Comments/PreOrders/MixinNetworkUsers). PR #1848 (Articles author avatar chain).
5. **DONE** Dashboard block/subscribe users avatars + action_store batch — PR #1862 (07-08). Public users subscribe lists — PR #1866 (07-09). Homepage feed avatar chain — PR #1874 (07-09). Dashboard comments/subscribe_articles avatar chain — PR #1876 (07-09).
6. **DONE 2026-07-14** `Admin::UsersController#index` avatar chain — branch `perf-assist/admin-users-avatar-preload-20260714` (commit `0e04b45`). Landed on main (verified in `f41cec1` chain).
7. **DONE 2026-07-17** `Admin::CollectionsController#index` avatar chain — branch `perf-assist/admin-collections-author-avatar-preload-20260717` (commit `5df85ec`). `Collection.includes(:currency, author: admin_user_field_preloads)`. Closes the LAST admin-index gap.
8. **DONE 2026-07-22 → MERGED as PR #1948** `Collections::ArticlesController#index` card-preload. Branch `perf-assist/collections-articles-card-preload-20260722`. Controller adds `.includes(:currency, :tags, cover_attachment: :blob, author: User::AVATAR_PRELOADS)`. MERGED by maintainer (commit `a886ef1e`).
9. **ON MAIN** `Dashboard::TransfersController#index` preload — `.includes(:currency, source: { item: :author })` confirmed on main (patch from 2026-07-03 run).
10. **DEFERRED** `Dashboard::NotificationsController#index` action_store N+1 — `recipient.block_user?` from `should_notify?` for Comment/Tagging notifiers fires 1 SELECT/row. Fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery, `where(web_visible: true)` in controller. Migration + backfill + 10+ notifier updates + tests. 153ms → ~64ms/iter.
11. **IDENTIFIED 2026-07-23** `Orders::DistributeService` — `collect_early_readers` iterates `early_orders.each` calling `_order.buyer.mixin_uuid` without `includes(:buyer)`. Each iteration fires 1 buyer SELECT + 1 reader-share SUM per unique reader. ~156 queries for 100 orders/50 readers. Fix: add `.includes(:buyer)` to `early_orders` scope in `Orders::Distributable` concern. Background job (lower urgency).

## Work in Progress
- None active.

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true` → `eager_load=true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **No Postgres in this runner** — DB-backed controller tests cannot run locally. CI is the authoritative signal.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is `has_many through: :subscribe_by_user_actions, source: :user` — 2 SELECTs (actions + users via auto-include).
- **`safeoutputs create_pull_request`** — may or may not materialize. PR #1948 (from wrapped run) DID materialize and was merged. Branch + commit exist locally as fallback.
- **`safeoutputs update_issue`** — limited to 1 call per run. May not update body. `add_comment` is the reliable fallback.
- **`ActiveSupport::Notifications.subscribed` regression-guard pattern** for `ActionController::TestCase`: subscribe to `sql.active_record`, skip `payload[:name] == "SCHEMA"`, count SELECTs against regex on `payload[:sql]`. `assert_operator count, :<=, N` (budget absorbs future SCHEMA noise).
- **Per-row regression detection requires UNIQUE authors per row** — Rails' identity-map cache hides the avatar N+1 when all rows share an author. Use `create_unique_author!` per row.
- **`Article.only_published`** scope exists — `where(state: :published)`. Cleaner than inline `Article.where(state: :published)` for fixture seeding.
- **`Article.create!(state: :published, ...)`** bypasses AASM event guards; `do_first_publish` callbacks also don't fire — set `published_at: Time.current` explicitly.
- **`Comment.create!(author:, commentable:, legacy_markdown_content:)`** is the working pattern; `RichTextContent#content_cannot_be_blank` skips validation when `legacy_markdown_content.present?`.
- **`User::AVATAR_PRELOADS`** (PR #1874) is the canonical constant in `app/models/user.rb`. `app/controllers/concerns/user_field_preloads.rb` exposes `user_field_preloads` (controller-side). `admin_user_field_preloads` is the admin-side alias (in `Admin::BaseController`).
- **`Orders::DistributeService`** — `early_orders` scope is defined separately in `Orders::Distributable` concern AND in `Orders::DistributeService` (service has its own `early_orders` method at line 43-50). Both access `_order.buyer` without preloading. Fix applies to both locations. **UPDATED 2026-07-30**: PR #1972 (repo-assist) collapsed the service's copies into a single `delegate :early_orders, :early_orders_with_the_same_currency, :collect_early_readers, to: :order` line. Service-side `.includes(:buyer)` is now gone; the concern-side `.includes(:buyer)` is the SOLE source-of-truth and survives unchanged.

## Run History (recent)
- **2026-07-30 16:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/30577709614)
  - ✅ Verified `Orders::Distributable` buyer preload preserved post-PR #1972 (repo-assist refactor). `.includes(:buyer)` intact on line 18 of concern.
  - 📝 Posted update comment to #1824 — removed stale "Review Orders::DistributeService buyer preload PR" line; PR #1972 supersedes.
  - 🔍 Re-scanned Search/Tags/Home/Articles/Collections/API::Articles — all preloaded/cached/bounded. No new HTTP-surface N+1 families.
- **2026-07-24 13:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/30119452786)
  - 🔧 Implemented `Orders::DistributeService` buyer preload — 3x `.includes(:buyer)` across service early_orders, service collection orders, and concern early_orders.
  - 📝 Draft PR submitted: branch `perf-assist/orders-distribute-buyer-preload-20260724`.
- **2026-07-23 19:08 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/30035585475)
  - ✅ Confirmed PR #1948 MERGED by maintainer.
  - ✅ Confirmed `Dashboard::TransfersController#index` preload on main.
  - 🔍 Investigated `Orders::DistributeService` — found N+1 on `early_orders.each`. ~156 queries per article distribution.
  - 🔍 Investigated `Comment#notify_subscribers_async` — single query, acceptable.
  - 📝 Commented on monthly issue #1824 with run summary.
- **2026-07-22 17:55 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29948379479)
  - 🔍 Audited `Collections::ArticlesController#index` — found N+1 in `articles/_card` partial.
  - 🔧 Branch `perf-assist/collections-articles-card-preload-20260722`. MERGED as PR #1948.
- **2026-07-14 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29324027228) — `Admin::UsersController#index` avatar chain. Landed on main.

## Backlog Cursor
- Dashboard + Admin + Public user + Homepage feed N+1 families — ALL DONE and most merged.
- `Collections::ArticlesController#index` — DONE, MERGED as PR #1948.
- `Dashboard::NotificationsController#index` action_store N+1 — DEFERRED (needs migration run, maintainer signal).
- `Orders::DistributeService` `early_orders` buyer N+1 — **DONE 2026-07-24**. PR submitted (branch `perf-assist/orders-distribute-buyer-preload-20260724`). 3x `.includes(:buyer)` in service + concern + collection orders query.
- **Next**: Either revisit the deferred notifications migration when the maintainer signals readiness, or investigate new performance opportunities.
