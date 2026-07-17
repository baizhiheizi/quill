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
7. **DONE 2026-07-17** `Admin::CollectionsController#index` avatar chain — branch `perf-assist/admin-collections-author-avatar-preload-20260717` (commit `5df85ec`). `Collection.includes(:currency, author: admin_user_field_preloads)`. Closes the LAST admin-index gap. 3 files, +87/-1. Patch + bundle at `/tmp/gh-aw/agent/aw-perf-assist-admin-collections-author-avatar-preload-20260717.{patch,bundle}`.
8. **DEFERRED** `Dashboard::NotificationsController#index` action_store N+1 — `recipient.block_user?` from `should_notify?` for Comment/Tagging notifiers fires 1 SELECT/row. Fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery, `where(web_visible: true)` in controller. Migration + backfill + 10+ notifier updates + tests. 153ms → ~64ms/iter.

## Work in Progress
- None active. 2026-07-17 `Admin::CollectionsController#index` avatar preload branch committed (`5df85ec`); awaiting maintainer revival (6th consecutive `safeoutputs create_pull_request` non-materialization).

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true` → `eager_load=true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **No Postgres in this runner** — DB-backed controller tests cannot run locally. CI is the authoritative signal.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is `has_many through: :subscribe_by_user_actions, source: :user` — 2 SELECTs (actions + users via auto-include).
- **`safeoutputs create_pull_request` reports success but does NOT materialize the PR** (git credentials removed after checkout). Branch + commit exist locally; `/tmp/gh-aw/agent/aw-*.patch` is the persisted patch. Maintainer applies via `git am`. **Confirmed in 6 consecutive runs.**
- **`safeoutputs update_issue` doesn't update body** in push-triggered runs. Workaround: `safeoutputs add_comment` is reliable.
- **`ActiveSupport::Notifications.subscribed` regression-guard pattern** for `ActionController::TestCase`: subscribe to `sql.active_record`, skip `payload[:name] == "SCHEMA"`, count SELECTs against regex on `payload[:sql]`. `assert_operator count, :<=, N` (budget absorbs future SCHEMA noise).
- **Per-row regression detection requires UNIQUE authors per row** — Rails' identity-map cache hides the avatar N+1 when all rows share an author. Use `create_unique_author!` per row.
- **`Article.only_published`** scope exists — `where(state: :published)`. Cleaner than inline `Article.where(state: :published)` for fixture seeding.
- **`Article.create!(state: :published, ...)`** bypasses AASM event guards; `do_first_publish` callbacks also don't fire — set `published_at: Time.current` explicitly.
- **`Comment.create!(author:, commentable:, legacy_markdown_content:)`** is the working pattern; `RichTextContent#content_cannot_be_blank` skips validation when `legacy_markdown_content.present?`.
- **`Comment#notify_subscribers_async`** after_commit fires 1 SELECT on `commentable.commenting_subscribe_by_users.where.not(mixin_uuid: author.mixin_uuid)`. `stub_notifications!` only stubs Payment/Order notifiers, NOT comment notifiers.
- **Maintainer revival pattern (confirmed)**: `git am /tmp/gh-aw/agent/aw-*.patch`, force-push branch, `gh pr create`. PRs #1815, #1829, #1848, #1846 merged this way.
- **`assigns` is unavailable** without `rails-controller-testing`. Use `@controller.instance_variable_get(:@ivar)`.
- **Polymorphic preload `source: { item: :author }` works** for `Transfer.has_many :transfers, as: :source` on `Order` (`belongs_to :item, polymorphic: true`). Rails fires one SELECT per `item_type`.
- **`User::AVATAR_PRELOADS`** (PR #1874) is the canonical constant in `app/models/user.rb`. `app/controllers/concerns/user_field_preloads.rb` exposes `user_field_preloads` (controller-side). `admin_user_field_preloads` is the admin-side alias (in `Admin::BaseController`).
- **`active_authors`** is the homepage's "active authors" Turbo Frame — highest-traffic page in the app.
- **`visible_in_web?`** (`config/initializers/noticed.rb`) — per-row Ruby predicate. For `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row).
- **`Dashboard::SubscribeByUsersController`** exists in `app/controllers/dashboard/` but has NO route. Dead controller — actual `/users/:uid/subscribe_by_users` lives under `users/`. Skip.
- **`Admin::StatisticsController#index`** — no N+1 (partial reads `store_accessor` JSON fields only via `statistic.new_users_count` etc., which read from the in-memory `data` JSONB column). Note: Ransack searches on `title_i_cont_all`, `intro_i_cont_all`, `content_i_cont_all`, `uuid_eq`, `id_eq` but `Statistic` model has NONE of those columns. Dead Ransack config, not a perf issue.
- **`Admin::OverviewController#index`** — empty action, no perf concern.
- **`Admin::WalletsController`** — proxies external Mixin Network API, no DB reads.
- **`preload_user_aggregates` order matters** — must be called AFTER `pagy(:countless, users)`. The collection must be an Array (not Relation).
- **All 8 admin indexes** (Users, Articles, Orders, Payments, Transfers, Bonuses, Comments, PreOrders, Collections) now use the canonical `admin_user_field_preloads` chain. Sweep complete.

## Run History (recent)
- **2026-07-17 20:11 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29572212724)
  - Audited ALL Admin controllers — only gap remained: `CollectionsController#index`.
  - Drafted `perf-assist/admin-collections-author-avatar-preload-20260717` (commit `5df85ec`): `Collection.includes(:currency, author: admin_user_field_preloads)`. Closes the last admin-index gap in the avatar-chain N+1 sweep. 3 files, +87/-1.
  - Added regression-guard test mirroring `Admin::UsersController#index` guard.
  - Added bench scenarios: `admin.collections.eager_load` / `.legacy`.
  - `bin/rubocop` clean on 3 changed files; `bin/rails zeitwerk:check` `all is good!`.
  - `safeoutputs create_pull_request` did not materialize (6th consecutive run).
- **2026-07-14 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29324027228)
  - `Admin::UsersController#index` avatar chain — `includes(*user_field_preloads)`. Landed on main via `f41cec1` chain.
  - 3 files, +75/-0; rubocop + zeitwerk clean.
- **2026-07-09 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/29014044946) - `Dashboard::CommentsController` + `Dashboard::SubscribeArticlesController` avatar chain. Landed as PR #1876.
- **2026-07-03 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28655443787) - `Dashboard::TransfersController#index` `.includes(:currency, source: { item: :author })`. Bench: ~17.5× speedup. Superseded by PR #1829.

## Backlog Cursor
- Dashboard + Admin + Public user + Homepage feed N+1 families — fully DONE (all 8 admin indexes + dashboard home).
- `Dashboard::NotificationsController#index` action_store N+1 — DEFERRED for a dedicated migration run.
- **Next**: Notifications migration OR look outside N+1 family (`Order.distribute_service`, `Comment.notify_subscribers_async` SELECTs, build-time optimizations, frontend bundle analysis via `bin/measure-frontend-efficiency`).
