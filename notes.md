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
1. **DONE Notifications SQL** — PRs #1695/#1749/#1760/#1767 (06-19→06-29). `User#subscribed_user_ids_relation` / `User#blocked_user_ids_relation`.
2. **DONE Admin user-list aggregates** — `preload_user_aggregates` 72→3 queries. PR #1708 (06-21).
3. **DONE `active_authors` block subquery** — PR #1735 (06-26). SQL sampling PR #1759 (06-28).
4. **DONE `hot_tags` SQL sampling + cache** — PR #1752 (06-27).
5. **DONE `author_revenue_usd` / `reader_revenue_usd`** — PR #1731 (06-25).
6. **DONE Dashboard N+1 family** — PRs #1802 (Collections), #1815 (Articles), #1829 (Transfers, repo-assist), #1830 (Payments), #1833 (Subscribe/Comment). Merged 07-01→07-06.
7. **DONE Admin N+1 family** — PR #1834 (Orders/Payments/Transfers/Bonuses, merged 07-06). PR #1837 (Comments/PreOrders/MixinNetworkUsers, draft). PR #1846 (Articles author avatar chain, repo-assist, draft 2026-07-07).
8. **SUPERSEDED** `Dashboard::OrdersController#index` — branch `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` lost between runs; patch files removed by worktree cleanup.
9. **DRAFTED, SUPERSEDED by repo-assist** `Admin::ArticlesController#index` — branch `perf-assist/admin-articles-author-avatar-preload-20260707` (commit `850fbe1`); same fix as PR #1846 (commit `538b299`). Patch + bundle at `/tmp/gh-aw/aw-perf-assist-admin-articles-author-avatar-preload-20260707.{patch,bundle}` for reference.
10. **DEFERRED** `Dashboard::NotificationsController#index` action_store N+1 — `recipient.block_user?` from `should_notify?` for Comment/Tagging notifiers fires 1 SELECT per row. Fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery, `where(web_visible: true)` in controller. Migration + backfill + tests. 153ms → ~64ms/iter.
11. **DEFERRED batch** Dashboard `subscribe_users` / `block_users` / `subscribe_by_users` avatars — all render `shared/avatar` with no `.includes(...)`. Same `user_field_preloads` fix; ~3 controllers.

## Work in Progress
- None active. Branch `perf-assist/admin-articles-author-avatar-preload-20260707` superseded by repo-assist PR #1846; regression-guard test posted as comment there.

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true` → `eager_load=true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **No Postgres in this runner** — DB-backed controller tests cannot run locally. CI is the authoritative signal.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is `has_many through: :subscribe_by_user_actions, source: :user` — 2 SELECTs (actions + users via auto-include).
- **`safeoutputs create_pull_request` reports success but does NOT materialize the PR** (git credentials removed after checkout). Branch + commit exist locally; `/tmp/gh-aw/aw-*.patch` is the persisted patch. Maintainer applies via `git am`. **Confirmed in 3 consecutive runs.** When repo-assist has already opened a competing PR for the same change, consolidate by commenting on theirs (rather than opening a competing PR).
- **`safeoutputs create_issue` ALSO intermittently reports success but does not persist**. Same workaround.
- **`safeoutputs update_issue` doesn't update body** in push-triggered runs. Limit 1/run. Workaround: `safeoutputs add_comment`.
- **`ActiveSupport::Notifications.subscribed` regression-guard pattern** for `ActionController::TestCase`: subscribe to `sql.active_record`, skip `payload[:name] == "SCHEMA"`, count SELECTs against regex on `payload[:sql]`. `assert_operator count, :<=, N` (budget absorbs future SCHEMA noise).
- **Maintainer revival pattern (confirmed)**: `git am /tmp/gh-aw/aw-*.patch` (or `git clone /tmp/gh-aw/aw-*.bundle`), force-push branch, `gh pr create`. PRs #1815 and #1829 merged this way.
- **`assigns` is unavailable** without `rails-controller-testing`. Use `@controller.instance_variable_get(:@ivar)`.
- **Polymorphic preload `source: { item: :author }` works** for `Transfer.has_many :transfers, as: :source` on `Order` (`belongs_to :item, polymorphic: true`). Rails fires one SELECT per `item_type`. Same pattern works for `citer: :author` on polymorphic `Order.belongs_to :citer`.
- **`UserFieldPreloads` concern (drafted, lost)**: extract `admin_user_field_preloads` into `app/controllers/concerns/user_field_preloads.rb`. Single source of truth for the avatar preload chain. `Admin::BaseController` keeps `admin_user_field_preloads` as `alias_method :admin_user_field_preloads, :user_field_preloads` for back-compat. `Dashboard::BaseController` includes the concern directly.
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678).
- **`active_authors`** is the homepage's "active authors" Turbo Frame — highest-traffic page in the app.
- **`visible_in_web?`** (`config/initializers/noticed.rb`) — per-row Ruby predicate. For `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row).
- **`Order#order_type` uniqueness validation** (`app/models/order.rb:53`): for tests, use `source: order` (re-link existing Order) instead of `create_buy_order!` per transfer.
- **`ArticleSearchService`** uses `Article.with_associations` (public hot path) — heavier admin preloads shouldn't bleed in.

## Run History (recent)
- **2026-07-07 11:25 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28861929696)
  - Audited `Admin::ArticlesController#index` — gap PR #1837 noted as out of scope. Drafted `perf-assist/admin-articles-author-avatar-preload-20260707` (commit `850fbe1`): inline `Article.includes(:currency, :tags, author: admin_user_field_preloads)` + regression-guard test (asserts ≤2 auth, ≤4 blob SELECTs per render). 2 files, +69/-1.
  - Repo-assist opened PR #1846 for the same fix a few hours earlier (commit `538b299`). My safeoutputs PR push did not materialize (3rd consecutive run with this issue). Consolidated on #1846 by posting the regression-guard test as a comment.
  - `bin/rubocop` clean; `bin/rails zeitwerk:check` `all is good!`. Updated Monthly Activity #1824.
- **2026-07-06 12:29 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28790470244)
  - Audited `Dashboard::OrdersController#index`. Implemented `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` (commits `e59dafa` + `a53356e`): new `UserFieldPreloads` concern; `Dashboard::OrdersController#index` → `includes(:item, :currency, citer: :author, buyer: user_field_preloads)`. 6 files, +206/-14. New `dashboard.orders.eager_load` / `.legacy` bench scenarios + regression-guard test (30-SELECT budget). `bin/rubocop` clean on 515 files. `safeoutputs create_pull_request` returned success but no PR opened. Closed duplicate Monthly Activity #1825.
- **2026-07-03 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28655443787) - `Dashboard::TransfersController#index` `.includes(:currency, source: { item: :author })`. Bench: `eager_load 1.8 ms / legacy 31.5 ms` (~17.5×). Branch later superseded by repo-assist PR #1829 (merged 07-03).

## Backlog Cursor
- Dashboard N+1 family — fully DONE (PRs #1802, #1815, #1829, #1830, #1833).
- Admin N+1 family — fully COVERED. PR #1834 merged. PR #1837 (draft) covers Comments/PreOrders/MixinNetworkUsers. PR #1846 (draft, repo-assist) covers Articles author avatar chain. My regression-guard test posted as comment on #1846.
- `Dashboard::NotificationsController#index` action_store N+1 — DEFERRED for a dedicated migration run (requires `web_visible` boolean column + delivery-time population + backfill).
- Dashboard `subscribe_users` / `block_users` / `subscribe_by_users` avatar preloads — DEFERRED batch. Same `user_field_preloads` fix; ~3 controllers.
- **`ArticleSearchService`** may also benefit (homepage feed renders `articles/_card.html.erb` → `shared/_avatar` per card). Heavier public preloads — needs measurement first.
- **Next**: (a) Dashboard `subscribe_users` / `block_users` / `subscribe_by_users` avatar preload batch (3 controllers, low-risk, dashboard-only) OR (b) measure the homepage `ArticleSearchService` avatar cost.