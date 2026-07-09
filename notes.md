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
1. **DONE** Notifications SQL — PRs #1695/#1749/#1760/#1767. Admin user-list aggregates — PR #1708.
2. **DONE** `active_authors` block subquery — PR #1735. `hot_tags` SQL sampling — PR #1752. `author_revenue_usd` / `reader_revenue_usd` — PR #1731.
3. **DONE Dashboard N+1 base** — PRs #1802/#1815/#1829/#1830/#1833 (Subscribe/Comment bare `:author`). Merged 07-01→07-06.
4. **DONE Admin N+1 family** — PR #1834 (Orders/Payments/Transfers/Bonuses). PR #1837 (Comments/PreOrders/MixinNetworkUsers). PR #1848 (Articles author avatar chain, Perf Improver).
5. **DONE Dashboard block/subscribe users avatars + action_store batch** — PR #1862 (repo-assist, merged 07-08). `Dashboard::BlockUsersController` + `Dashboard::SubscribeUsersController`.
6. **DONE Public users subscribe lists** — PR #1866 (repo-assist, merged 07-09). `Users::SubscribeUsersController` + `Users::SubscribeByUsersController`.
7. **DONE Homepage feed avatar chain** — PR #1874 (repo-assist, merged 07-09). `Article.with_associations` includes `author: User::AVATAR_PRELOADS`.
8. **DRAFTED this run (2026-07-09)** `perf-assist/dashboard-subscribe-articles-comments-avatar-preload-20260709` (commit `8d3954f`): `Dashboard::CommentsController#index` + `Dashboard::SubscribeArticlesController#index` now use `includes(author: dashboard_user_field_preloads)`. Closes avatar-chain gap left by PR #1833 (which only preloaded the bare User row). Patch + bundle at `/tmp/gh-aw/aw-perf-assist-dashboard-subscribe-articles-comments-avatar-preload-20260709.{patch,bundle}`.
9. **SUPERSEDED** `Dashboard::OrdersController#index` — branch `perf-assist/dashboard-orders-citer-author-buyer-avatar-preloads-20260706` lost between runs.
10. **DRAFTED, SUPERSEDED** `Admin::ArticlesController#index` — branch `perf-assist/admin-articles-author-avatar-preload-20260707` (commit `850fbe1`); same fix as PR #1846. Patch + bundle at `/tmp/gh-aw/aw-perf-assist-admin-articles-author-avatar-preload-20260707.{patch,bundle}` for reference.
11. **DEFERRED** `Dashboard::NotificationsController#index` action_store N+1 — `recipient.block_user?` from `should_notify?` for Comment/Tagging notifiers fires 1 SELECT/row. Fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery, `where(web_visible: true)` in controller. Migration + backfill + 10+ notifier updates + tests. 153ms → ~64ms/iter. Defer for dedicated run.

## Work in Progress
- None active. 2026-07-09 avatar-preload branch committed; `safeoutputs create_pull_request` returned success but did not materialize (4th consecutive run). Awaiting maintainer revival.

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true` → `eager_load=true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **No Postgres in this runner** — DB-backed controller tests cannot run locally. CI is the authoritative signal.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is `has_many through: :subscribe_by_user_actions, source: :user` — 2 SELECTs (actions + users via auto-include).
- **`safeoutputs create_pull_request` reports success but does NOT materialize the PR** (git credentials removed after checkout). Branch + commit exist locally; `/tmp/gh-aw/aw-*.patch` is the persisted patch. Maintainer applies via `git am`. **Confirmed in 4+ consecutive runs.** When repo-assist has already opened a competing PR for the same change, consolidate by commenting on theirs (rather than opening a competing PR).
- **`safeoutputs create_issue` ALSO intermittently reports success but does not persist**. Same workaround.
- **`safeoutputs update_issue` doesn't update body** in push-triggered runs. Limit 1/run. Workaround: `safeoutputs add_comment`.
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
- **`User::AVATAR_PRELOADS`** (PR #1874) is the canonical constant in `app/models/user.rb` — single source of truth. Controller helpers can either inline the constant or keep private aliases.
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678).
- **`active_authors`** is the homepage's "active authors" Turbo Frame — highest-traffic page in the app.
- **`visible_in_web?`** (`config/initializers/noticed.rb`) — per-row Ruby predicate. For `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row).
- **`Order#order_type` uniqueness validation** (`app/models/order.rb:53`): for tests, use `source: order` (re-link existing Order) instead of `create_buy_order!` per transfer.
- **`ArticleSearchService`** uses `Article.with_associations` (public hot path, now preloads avatar chain via PR #1874).
- **`Dashboard::SubscribeByUsersController`** exists in `app/controllers/dashboard/` but has NO route (only in `SECTION_BY_CONTROLLER` map for rail/tabbar). Dead controller — actual `/users/:uid/subscribe_by_users` lives under `users/`. Skip.
- **PR #1833 covered `:author` for comments + subscribe_articles**, but NOT the avatar chain. My 2026-07-09 PR adds `dashboard_user_field_preloads` on top of `:author` for both controllers to close that gap.

## Run History (recent)
- **2026-07-09 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29014044946)
  - Drafted `perf-assist/dashboard-subscribe-articles-comments-avatar-preload-20260709` (commit `8d3954f`): both controllers now use `includes(author: dashboard_user_field_preloads)`. 4 files, +202/-9.
  - Added regression-guard tests: `Dashboard::CommentsControllerTest` (2 tests, budget ≤20 with 5 unique-author comments) and `Dashboard::SubscribeArticlesControllerTest` (1 test, budget ≤20 with all 5 published fixture articles). Each comment seeded with unique author via `create_unique_author!` to bypass Rails identity-map cache.
  - `bin/rubocop` clean; `bin/rails zeitwerk:check` `all is good!`.
  - `safeoutputs create_pull_request` did not materialize (4th consecutive run). Patch + bundle at `/tmp/gh-aw/aw-perf-assist-dashboard-subscribe-articles-comments-avatar-preload-20260709.{patch,bundle}`.
- **2026-07-07 11:25 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28861929696) - `Admin::ArticlesController#index` avatar chain. Superseded by repo-assist PR #1846; regression-guard test posted as comment on #1846.
- **2026-07-06 12:29 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28790470244) - `Dashboard::OrdersController#index` `UserFieldPreloads` concern + `citer: :author` + `buyer: user_field_preloads`. Branch lost between runs.
- **2026-07-03 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28655443787) - `Dashboard::TransfersController#index` `.includes(:currency, source: { item: :author })`. Bench: ~17.5× speedup. Superseded by repo-assist PR #1829.

## Backlog Cursor
- Dashboard + Admin + Public user + Homepage feed N+1 families — fully DONE.
- `Dashboard::NotificationsController#index` action_store N+1 — DEFERRED for a dedicated migration run (requires `web_visible` boolean column + delivery-time population + backfill + 10+ notifier updates).
- **Next**: Notifications migration OR find a fresh optimization (e.g., `article_references` JSON endpoint, `taggings` index, `notifications#show` redirect chain, dashboard home overview composition).