# Perf Improver Memory

## Repository
baizhiheizi/quill — Rails 8.1 monolith (Web3 paid-publishing). Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild.

## Validated Commands
- `bundle install --jobs4 --retry3`, `bun install --frozen-lockfile`
- `bin/dev`, `bin/ci`
- `bin/rails test` — `unset CI` first; **Postgres NOT available locally** (CI is authoritative)
- `bin/rails zeitwerk:check`, `bin/rubocop`, `bun run lint-check`
- `bin/benchmark` — `dashboard.orders`, `dashboard.transfers`, `home.active_authors`, `article_search.subscribed`, `article.random_readers`

## Performance Backlog
1. **DONE Notifications SQL** — PR #1695 + #1749 + #1760 + #1767 (merged 2026-06-19 → 06-29). `User#subscribed_user_ids_relation` / `User#blocked_user_ids_relation` helpers.
2. **DONE Admin user-list aggregates** — `preload_user_aggregates(users)` 72→3 queries. PR #1708 (merged 2026-06-21).
3. **DONE `active_authors` block subquery** — PR #1735 (merged 06-26). SQL sampling PR #1759 (06-28).
4. **DONE `hot_tags` SQL sampling + cache** — PR #1752 (merged 2026-07-27).
5. **DONE `author_revenue_usd` / `reader_revenue_usd`** — PR #1731 (merged 06-25).
6. **DONE Dashboard N+1 family** — PRs #1802 (Collections), #1815 (Articles), #1829 (Transfers, repo-assist), #1830 (Payments), #1833 (Subscribe/Comment). All merged 07-01 → 07-06.
7. **DONE Admin N+1 family** — PR #1834 (Orders/Payments/Transfers/Bonuses, merged 07-06). PR #1837 (Comments/PreOrders/MixinNetworkUsers, draft) — body explicitly notes `Admin::ArticlesController#index` still uses bare `:author` from `Article.with_associations` instead of `admin_user_field_preloads` — smaller follow-up.
8. **DRAFTED this run** `Dashboard::OrdersController#index` — Branch `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` (commits `e59dafa` + `a53356e`). Adds `citer: :author` + `buyer: user_field_preloads` + extracts shared `UserFieldPreloads` concern. 6 files, +206/-14. Tests: `test/controllers/dashboard/orders_controller_test.rb` (2 tests; 30-SELECT budget regression guard + cite_article path test). Bench: `dashboard.orders.eager_load` / `dashboard.orders.legacy`. Patch: `/tmp/gh-aw/aw-perf-assist-dashboard-orders-citer-author-buyer-avatar-preloads-20260706.{patch,bundle}` (14 838 bytes). Local fallback: `/tmp/gh-aw/agent/aw-perf-assist-dashboard-orders-citer-author-buyer-avatar-preloads-20260706.patch`.
9. **DONE on local branch, awaiting revival** `Dashboard::NotificationsController#index` event N+1 — Branch `perf-assist/dashboard-notifications-includes-event-20260630` (commit `c0cfd96`).
10. **SUPERSEDED by repo-assist** `Dashboard::TransfersController#index` N+1 — Branch `perf-assist/dashboard-transfers-eager-load-20260703` superseded by PR #1829 (merged 07-03 22:26:49).
11. **DEFERRED** `Dashboard::NotificationsController#index` action_store N+1 — `recipient.block_user?` from `should_notify?` for `CommentCreatedNotifier` / `TaggingCreatedNotifier` fires 1 SELECT per row. Fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery time, `where(web_visible: true)` in controller. Migration + backfill + tests. After fix: 153 ms → ~64 ms / iter.
12. **DEFERRED** `Admin::ArticlesController#index` `:author → admin_user_field_preloads` — PR #1837 noted this gap. Natural next step: replace `:author` with `author: user_field_preloads` at the controller or `Article.with_associations` scope level.
13. **DEFERRED batch** Dashboard `subscribe_users` / `block_users` / `subscribe_by_users` avatars — all render `shared/avatar` with no `.includes(...)`. Each row fires ~3 SELECTs (authorization + attachment + blob). Same `user_field_preloads` fix; ~3 controllers touched.

## Work in Progress
- **Branch `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` (commits `e59dafa` + `a53356e`)** ready for maintainer revival. Patch + bundle at `/tmp/gh-aw/aw-perf-assist-dashboard-orders-citer-author-buyer-avatar-preloads-20260706.{patch,bundle}`. Local fallback at `/tmp/gh-aw/agent/aw-perf-assist-dashboard-orders-citer-author-buyer-avatar-preloads-20260706.patch`. Maintainer can `git am` any of these files.

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true` → `eager_load=true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **No Postgres in this runner** — DB-backed controller tests cannot run locally. CI is the authoritative signal.
- **Memoization measurement**: `||=` ivars persist across loop iterations in `bin/rails runner`. Reload user instances per simulated request.
- **Order fixtures**: `Order#setup_attributes` needs a Payment; use `Order.insert_all!` for benchmark tests. `Order.create!` with `order_type: :cite_article` works directly.
- **`blocked_reader` fixture has no `authorization`**: rendering admin user list raises `undefined method 'provider' for nil` via `messenger?`. Use direct controller tests or filter to authorized-only.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is `has_many through: :subscribe_by_user_actions, source: :user` — 2 SELECTs (actions + users via auto-include).
- **`safeoutputs update_issue` doesn't update body** in push-triggered runs. Limit 1/run. Workaround: `safeoutputs add_comment` with `item_number:`.
- **`safeoutputs create_pull_request` reports success but does NOT materialize the PR** (git credentials removed after checkout). Branch + commit exist locally; `/tmp/gh-aw/aw-*.patch` is the persisted patch. Maintainer applies via `git am`. Confirmed again 2026-07-06.
- **`safeoutputs create_issue` ALSO intermittently reports success but does not persist**. Same workaround.
- **Maintainer revival pattern (confirmed)**: `git am /tmp/gh-aw/aw-*.patch` (or `git clone /tmp/gh-aw/aw-*.bundle`), force-push branch, `gh pr create`. PRs #1815 and #1829 merged this way.
- **Query counter**: no `assert_queries_count`. Use `ActiveSupport::Notifications.subscribed(->(*, p) { ... }, "sql.active_record")` and skip `payload[:name] == "SCHEMA"`.
- **`Tag.hot.count` bug**: unused alias on `COUNT(...)` breaks `relation.count`. Drop alias or use `count(:id)`.
- **`assigns` is unavailable** without `rails-controller-testing`. Use `@controller.instance_variable_get(:@ivar)`.
- **Polymorphic preload `source: { item: :author }` works** for `Transfer.has_many :transfers, as: :source` on `Order` (`belongs_to :item, polymorphic: true`). Rails fires one SELECT per `item_type`.
- **Polymorphic preload `citer: :author` works** for `Order.belongs_to :citer, polymorphic: true` (Article/Comment). Both have `belongs_to :author`, so the same chain works for both. Confirmed this run.
- **`UserFieldPreloads` concern**: extract `admin_user_field_preloads` into `app/controllers/concerns/user_field_preloads.rb`. Single source of truth for the avatar preload chain. `Admin::BaseController` keeps `admin_user_field_preloads` as `alias_method :admin_user_field_preloads, :user_field_preloads` for backwards compatibility. `Dashboard::BaseController` includes the concern directly.
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678).
- **`active_authors` is the homepage's "active authors" Turbo Frame** — highest-traffic page in the app.
- **`visible_in_web?`** (`config/initializers/noticed.rb`) — per-row Ruby predicate. For `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row).
- **`Noticed::Event` `type` column** stores the NOTIFIER class name, not the AR model class.
- **`Noticed::Notification.recipient`** is polymorphic `recipient_id + recipient_type`.
- **`Order#order_type` uniqueness validation** (`app/models/order.rb:53`): `validates :order_type, uniqueness: { scope: %i[order_type buyer_id item_id item_type], if: -> { buy_article? || buy_collection? } }` — for tests, use `source: order` (re-link existing Order) instead of `create_buy_order!` per transfer.

## Run History (recent)
- **2026-07-06 12:29 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28790470244)
  - Audited `Dashboard::OrdersController#index`. Identified two un-preloaded chains: `order.citer.title + order.citer.author` (cite_article branch, polymorphic citer) and `order.buyer.avatar_image_thumb` via `shared/_avatar` (loads `:authorization` + ActiveStorage chain).
  - Implemented `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` (commits `e59dafa` + `a53356e`): new `UserFieldPreloads` concern, both `Admin::BaseController` and `Dashboard::BaseController` include it (admin keeps `admin_user_field_preloads` as back-compat alias), `Dashboard::OrdersController#index` → `includes(:item, :currency, citer: :author, buyer: user_field_preloads)`. 6 files, +206/-14.
  - `test/controllers/dashboard/orders_controller_test.rb` (new, 2 tests): regression-guard with a 30-SELECT budget on 50 seeded orders; cite_article path test asserts `order.citer.author` resolves without extra SELECT.
  - `dashboard.orders.eager_load` + `dashboard.orders.legacy` scenarios; updated `test/benchmarks/README.md`.
  - `bin/rubocop` clean (515 files, no offenses); `bin/rails zeitwerk:check` `all is good!`.
  - `safeoutputs create_pull_request` returned success but no PR opened (push-blocked pattern). Branch + commits survive locally. Patch + bundle at `/tmp/gh-aw/aw-perf-assist-dashboard-orders-citer-author-buyer-avatar-preloads-20260706.{patch,bundle}`.
  - Closed duplicate Monthly Activity issue #1825; updated canonical #1824 with comment (update_issue body limit reached — used add_comment instead).
- **2026-07-03 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28655443787) - `Dashboard::TransfersController#index` `.includes(:currency, source: { item: :author })`. Bench: `eager_load 1.8 ms / legacy 31.5 ms` (~17.5×). Branch later superseded by repo-assist PR #1829 (merged 07-03).
- **2026-06-30 11:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28440184787) - `Dashboard::NotificationsController#index` event N+1 fix. Awaiting maintainer revival.

## Backlog Cursor
- Dashboard N+1 family — fully DONE (PRs #1802, #1815, #1829, #1830, #1833).
- Admin N+1 family — mostly DONE. PR #1834 merged. PR #1837 open as draft.
- `Dashboard::OrdersController#index` — DRAFTED on local branch this run. Patch preserved. Awaiting maintainer revival.
- `Dashboard::NotificationsController#index` action_store N+1 — DEFERRED for a dedicated migration run (requires `web_visible` boolean column + delivery-time population + backfill).
- `Admin::ArticlesController#index` `:author → admin_user_field_preloads` — SHORT follow-up. PR #1837 noted this gap. After landing the orders PR, single-line fix at the controller or `Article.with_associations` scope.
- Dashboard `subscribe_users` / `block_users` / `subscribe_by_users` avatar preloads — DEFERRED batch. All render `shared/avatar` with no `.includes(...)`. Same `user_field_preloads` fix; ~3 controllers touched.
- **Next**: if the orders PR is revived, pivot to `Admin::ArticlesController#index` `:author → admin_user_field_preloads` (smallest scope) or start the Dashboard subscribe/block users avatar batch.