# Perf Improver Memory

## Repository
baizhiheizi/quill — Rails 8.1 monolith (Web3 paid-publishing). Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild.

## Validated Commands
- `bundle install --jobs4 --retry3`, `bun install --frozen-lockfile`
- `bin/dev`, `bin/ci`
- `bin/rails test` — `unset CI` first; **Postgres NOT available locally** (CI is authoritative)
- `bin/rails zeitwerk:check`, `bin/rubocop`, `bun run lint-check`
- `bin/benchmark` — `dashboard.orders`, `dashboard.transfers`, `home.active_authors`, `article_search.subscribed`, `article.random_readers`, `admin.users`

## Performance Backlog
1. **DONE** Notifications SQL — PRs #1695/#1749/#1760/#1767. Admin user-list aggregates — PR #1708.
2. **DONE** `active_authors` block subquery — PR #1735. `hot_tags` SQL sampling — PR #1752. `author_revenue_usd` / `reader_revenue_usd` — PR #1731.
3. **DONE Dashboard N+1 base** — PRs #1802/#1815/#1829/#1830/#1833 (Subscribe/Comment bare `:author`). Merged 07-01→07-06.
4. **DONE Admin N+1 family** — PR #1834 (Orders/Payments/Transfers/Bonuses). PR #1837 (Comments/PreOrders/MixinNetworkUsers). PR #1848 (Articles author avatar chain, Perf Improver).
5. **DONE Dashboard block/subscribe users avatars + action_store batch** — PR #1862 (repo-assist, merged 07-08). `Dashboard::BlockUsersController` + `Dashboard::SubscribeUsersController`.
6. **DONE Public users subscribe lists** — PR #1866 (repo-assist, merged 07-09). `Users::SubscribeUsersController` + `Users::SubscribeByUsersController`.
7. **DONE Homepage feed avatar chain** — PR #1874 (repo-assist, merged 07-09). `Article.with_associations` includes `author: User::AVATAR_PRELOADS`.
8. **DRAFTED 2026-07-09, MERGED** `Dashboard::CommentsController` + `Dashboard::SubscribeArticlesController` avatar chain — PR #1876 (repo-assist).
9. **DONE 2026-07-14** `Admin::UsersController#index` avatar chain — branch `perf-assist/admin-users-avatar-preload-20260714` (commit `0e04b45`). 1-line controller fix: `.includes(*user_field_preloads)`. Patch + bundle at `/tmp/gh-aw/agent/aw-perf-assist-admin-users-avatar-preload-20260714.{patch,bundle}`.
10. **SUPERSEDED** `Dashboard::OrdersController#index` — branch `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` lost between runs; landed via PR #1829 family (commit 4b5ea3f, 2026-07-09).
11. **SUPERSEDED** `Admin::ArticlesController#index` — branch `perf-assist/admin-articles-author-avatar-preload-20260707` (commit `850fbe1`); same fix as PR #1846.
12. **DEFERRED** `Dashboard::NotificationsController#index` action_store N+1 — `recipient.block_user?` from `should_notify?` for Comment/Tagging notifiers fires 1 SELECT/row. Fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery, `where(web_visible: true)` in controller. Migration + backfill + 10+ notifier updates + tests. 153ms → ~64ms/iter. Defer for dedicated run.

## Work in Progress
- None active. 2026-07-14 `Admin::UsersController#index` avatar preload branch committed; awaiting maintainer revival (4th+ consecutive `safeoutputs create_pull_request` non-materialization).

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true` → `eager_load=true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **No Postgres in this runner** — DB-backed controller tests cannot run locally. CI is the authoritative signal.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is `has_many through: :subscribe_by_user_actions, source: :user` — 2 SELECTs (actions + users via auto-include).
- **`safeoutputs create_pull_request` reports success but does NOT materialize the PR** (git credentials removed after checkout). Branch + commit exist locally; `/tmp/gh-aw/aw-*.patch` is the persisted patch. Maintainer applies via `git am`. **Confirmed in 4+ consecutive runs.** When repo-assist has already opened a competing PR for the same change, consolidate by commenting on theirs (rather than opening a competing PR).
- **`safeoutputs create_issue` ALSO intermittently reports success but does not persist**. Same workaround.
- **`safeoutputs update_issue` doesn't update body** in push-triggered runs. Limit 1/run. Workaround: `safeoutputs add_comment`.
- **`safeoutputs add_comment` IS reliable** for adding run summary to the monthly activity issue.
- **`ActiveSupport::Notifications.subscribed` regression-guard pattern** for `ActionController::TestCase`: subscribe to `sql.active_record`, skip `payload[:name] == "SCHEMA"`, count SELECTs against regex on `payload[:sql]`. `assert_operator count, :<=, N` (budget absorbs future SCHEMA noise).
- **Per-row regression detection requires UNIQUE authors per row** — Rails' identity-map cache hides the avatar N+1 when all rows share an author. Use `create_unique_author!` per row.
- **`Article.only_published`** scope exists — `where(state: :published)`. Cleaner than inline `Article.where(state: :published)` for fixture seeding.
- **`Article.create!(state: :published, ...)`** bypasses AASM event guards (no `ensure_content_valid` check), but `do_first_publish` callbacks also don't fire — set `published_at: Time.current` explicitly. Established pattern in `test/services/orders/distribute_service_article_test.rb`.
- **`Comment.create!(author:, commentable:, legacy_markdown_content:)`** is the working pattern; `RichTextContent#content_cannot_be_blank` skips validation when `legacy_markdown_content.present?`. Avoid `content:` attr unless wiring `ActionText::RichText` (heavier).
- **`Comment#subscribe_for_author`** after_commit fires `author.create_action :commenting_subscribe, target: commentable` — each seeded Comment creates an extra `Action` row when `commentable.is_a?(Article)`. Side effect, not breaking.
- **`Comment#notify_subscribers_async`** after_commit calls `CommentCreatedNotifier.with(...).deliver(subscribers)` — fires 1 SELECT on `commentable.commenting_subscribe_by_users.where.not(mixin_uuid: author.mixin_uuid)`. `stub_notifications!` only stubs Payment/Order notifiers, NOT comment notifiers.
- **Maintainer revival pattern (confirmed)**: `git am /tmp/gh-aw/aw-*.patch` (or `git clone /tmp/gh-aw/aw-*.bundle`), force-push branch, `gh pr create`. PRs #1815, #1829, #1848 merged this way.
- **`assigns` is unavailable** without `rails-controller-testing`. Use `@controller.instance_variable_get(:@ivar)`.
- **Polymorphic preload `source: { item: :author }` works** for `Transfer.has_many :transfers, as: :source` on `Order` (`belongs_to :item, polymorphic: true`). Rails fires one SELECT per `item_type`. Same pattern works for `citer: :author` on polymorphic `Order.belongs_to :citer`.
- **`User::AVATAR_PRELOADS`** (PR #1874) is the canonical constant in `app/models/user.rb` — single source of truth. `app/controllers/concerns/user_field_preloads.rb` exposes `user_field_preloads` (controller-side). Controller helpers can either inline the constant or keep private aliases. Both surfaces resolve to the same chain — `Admin::UsersController#index` now uses this (2026-07-14).
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678).
- **`active_authors`** is the homepage's "active authors" Turbo Frame — highest-traffic page in the app.
- **`visible_in_web?`** (`config/initializers/noticed.rb`) — per-row Ruby predicate. For `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row).
- **`Order#order_type` uniqueness validation** (`app/models/order.rb:53`): for tests, use `source: order` (re-link existing Order) instead of `create_buy_order!` per transfer.
- **`ArticleSearchService`** uses `Article.with_associations` (public hot path, now preloads avatar chain via PR #1874).
- **`Dashboard::SubscribeByUsersController`** exists in `app/controllers/dashboard/` but has NO route (only in `SECTION_BY_CONTROLLER` map for rail/tabbar). Dead controller — actual `/users/:uid/subscribe_by_users` lives under `users/`. Skip.
- **PR #1833 covered `:author` for comments + subscribe_articles**, but NOT the avatar chain. My 2026-07-09 PR (landed via #1876 repo-assist) added `dashboard_user_field_preloads` on top of `:author` for both controllers to close that gap.
- **`Admin::UsersController#index`** had the avatar-chain gap (preload_user_aggregates batches row aggregates but doesn't touch the avatar chain). Closed in 2026-07-14 run.
- **`preload_user_aggregates` order matters** — must be called AFTER `pagy(:countless, users)`. The collection must be an Array (not Relation) so `users.map(&:id)` and `users.map(&:mixin_uuid)` work; if Relation is passed, `to_a` would be implicit and slow.

## Run History (recent)
- **2026-07-14 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29324027228)
  - Drafted `perf-assist/admin-users-avatar-preload-20260714` (commit `0e04b45`): `Admin::UsersController#index` now uses `includes(*user_field_preloads)`. Closes the avatar-chain gap that the recent Dashboard/Admin N+1 sweep missed because `preload_user_aggregates` (PR #1708) batches aggregates but doesn't touch the avatar chain. 3 files, +75/-0.
  - Added regression-guard test: `Admin::UsersControllerTest#index does not fire per-row SELECTs for the avatar chain` — counts `user_authorizations`, `active_storage_attachments`, `active_storage_blobs`, `active_storage_variant_records` SELECTs without IN-batching.
  - Added bench scenarios: `admin.users.eager_load` / `admin.users.legacy`.
  - `bin/rubocop` clean on 3 changed files; `bin/rails zeitwerk:check` `all is good!`.
  - `safeoutputs create_pull_request` did not materialize (5th consecutive run). Patch + bundle at `/tmp/gh-aw/agent/aw-perf-assist-admin-users-avatar-preload-20260714.{patch,bundle}`.
- **2026-07-09 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29014044946)
  - Drafted `perf-assist/dashboard-subscribe-articles-comments-avatar-preload-20260709` (commit `8d3954f`): both controllers now use `includes(author: dashboard_user_field_preloads)`. Landed as PR #1876 (repo-assist).
- **2026-07-07 11:25 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28861929696) - `Admin::ArticlesController#index` avatar chain. Superseded by repo-assist PR #1846.
- **2026-07-06 12:29 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28790470244) - `Dashboard::OrdersController#index` `UserFieldPreloads` concern + `citer: :author` + `buyer: user_field_preloads`. Branch lost between runs; landed via 4b5ea3f (2026-07-09) PR.
- **2026-07-03 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28655443787) - `Dashboard::TransfersController#index` `.includes(:currency, source: { item: :author })`. Bench: ~17.5× speedup. Superseded by repo-assist PR #1829.

## Backlog Cursor
- Dashboard + Admin + Public user + Homepage feed N+1 families — fully DONE.
- `Dashboard::NotificationsController#index` action_store N+1 — DEFERRED for a dedicated migration run (requires `web_visible` boolean column + delivery-time population + backfill + 10+ notifier updates).
- **Next**: Notifications migration OR another isolated controller (e.g. `Admin::OverviewController`, `Admin::StatisticsController`, `Admin::WalletsController#safe_outputs`, dashboard `home#index`).