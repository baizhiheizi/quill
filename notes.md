# Perf Improver Memory

## Repository
- **Name**: baizhiheizi/quill
- **Type**: Rails 8.1 monolith (Web3 paid-publishing platform)
- **Stack**: Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild

## Validated Commands
- `bundle install --jobs4 --retry3` — Install Ruby gems
- `bun install --frozen-lockfile` — Install Node modules
- `bin/dev` — Run full development stack
- `bin/rails test` — Run all tests (NOTE: `unset CI` in this workflow env)
- `bin/rails zeitwerk:check` — Check Zeitwerk autoload
- `bin/rubocop` — Ruby lint
- `bun run lint-check` — Prettier check on JS/TS
- `bin/ci` — Full CI pipeline
- `bin/benchmark` — All scenarios; per-scenario via `bin/benchmark article_search.subscribed`

## Performance Opportunities Backlog
1. **[DONE] `has_unread_notification?` / `unread_notifications_count`** — SQL `exists?` / `count` on `notifications.unread.for_web`. PR #1695 — **MERGED 2026-06-19**.
2. **[DONE] Admin user-list aggregate preloader** — `preload_user_aggregates(users)` runs 3 batched GROUP BY queries. 72 → 3 queries per page. PR #1708 — **MERGED 2026-06-21**.
3. **[DONE] `active_authors` block subquery** — PR #1735 — **MERGED 2026-06-26**.
4. **[DONE] `author_revenue_usd` / `reader_revenue_usd`** — `includes` → `joins(:currency)` cleanup. PR #1731 (repo-assist) — **MERGED 2026-06-25**.
5. **[DONE by repo-assist] `notify_subscribers` (Article/Collection/Tagging)** — PR #1749 — **MERGED 2026-06-26**. Adds `User#subscribed_user_ids_relation` / `User#blocked_user_ids_relation` helpers.
6. **[DONE by efficiency-improver] `active_authors` SQL sampling** — PR #1759 — **MERGED 2026-06-28**.
7. **[DONE by efficiency-improver] `hot_tags` SQL sampling + cache** — PR #1752 — **MERGED 2026-06-27**.
8. **[DONE] `Order#notify_subscribers` SQL subquery refactor** — Branch `perf-assist/order-notify-subscribers-sql-subquery-20260628`. PR #1760 — **MERGED 2026-06-28**. Reuses PR #1749 helper. 1 fewer round-trip per buy/reward/collection purchase. Fires on EVERY order. Follow-up PR #1767 (code-simplifier comment trim) MERGED 2026-06-29.
9. **[LOW] `Admin::UsersController#show` single-user aggregates** — 3 queries, single round-trip each. Not worth batching.
10. **[POTENTIAL — DEFERRED] `Dashboard::NotificationsController#index`** — `current_user.notifications.for_web.newest_first.select(&:visible_in_web?)` materialises ALL web notifications before pagy filters. `visible_in_web?` calls `recipient.notification_setting.<event>_web` (no SQL when association is loaded) and, for `CommentCreatedNotifier` / `TaggingCreatedNotifier`, `should_notify?` which calls `recipient.block_user? author` → `ActionStore::Mixin::ClassMethods#find_action` → 1 SELECT per row. A SQL-side `web_visible` boolean column (set at delivery time, default true) would let the controller become a single `where(web_visible: true)` query. Requires migration + populating the column in the delivery pipeline + backfill. Scope too large for one run; pivot to dedicated measurement + migration in a future run.

## Work in Progress
- Nothing open. All in-scope backlog items are MERGED.

## Completed Work (recent)
- PR #1767 (code-simplifier comment trim on Order#notify_subscribers) — **MERGED 2026-06-29**
- PR #1760 (order follower filter subqueries) — **MERGED 2026-06-28**
- PR #1759 (active_authors SQL sampling, efficiency-improver) — **MERGED 2026-06-28**
- PR (home active_authors block subquery) — **MERGED 2026-06-26** as PR #1735
- PR #1749 (notify_subscribers Article/Collection/Tagging, repo-assist) — **MERGED 2026-06-26**
- PR #1752 (hot_tags SQL sampling, efficiency-improver) — **MERGED 2026-06-27**
- PR #1708 (admin user-list aggregate preloader) — **MERGED 2026-06-21**
- PR #1695 (unread notification SQL EXISTS) — **MERGED 2026-06-19**
- PR #1688 (users.articles_count / comments_count counter caches) — **MERGED 2026-06-19**
- PR #1678 (Tag.hot count fix) — **MERGED 2026-06-17**
- PR #1634 (Users::Scopable LEFT JOINs) — **MERGED 2026-06-14**
- PR #1598 (block filters SQL subqueries) — **MERGED 2026-06-12**
- PR #1546 (subscribed filter SQL subqueries) — **MERGED 2026-06-09**
- PR #1539 (order_by_popularity LEFT JOIN + COALESCE) — **MERGED 2026-06-07**
- Monthly Activity issue #1513 `[perf-improver] Monthly Activity 2026-06` last updated 2026-06-29 (this run)

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true`, triggering `config.eager_load = true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **Memoization measurement**: `||=` ivars persist across loop iterations in `bin/rails runner`. Reload user instances per simulated request to measure properly.
- **Order test fixtures**: `Order#setup_attributes` needs a Payment; use `Order.insert_all!` for benchmark tests that don't exercise the lifecycle.
- **`blocked_reader` fixture has no `authorization`**: rendering admin user list raises `undefined method 'provider' for nil` via `messenger?`. Use direct controller tests or filter `@users` to authorized-only.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is a `has_many through: :subscribe_by_user_actions, source: :user` — issues 2 SELECTs (actions + users via auto-include).
- **`safeoutputs update_issue` doesn't actually update body** in push-triggered runs. Workaround: `safeoutputs add_comment` with `item_number:`.
- **Query counter**: no `assert_queries_count` helper. Use `ActiveSupport::Notifications.subscribed(->(*, p) { ... }, "sql.active_record")` and skip `payload[:name] == "SCHEMA"`.
- **`Tag.hot.count` bug**: `relation.select("COUNT(...) AS foo")` (unused alias) breaks `relation.count` — PG rejects. Drop the alias or use `count(:id)`.
- **`assigns` is unavailable** without `rails-controller-testing`. Use `@controller.instance_variable_get(:@ivar)` instead.
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678).
- **`active_authors` is the homepage's "active authors" Turbo Frame** — highest-traffic page in the app.
- **Notifier helpers** (in `test/support/notifier_helpers.rb`): `ensure_notification_setting!(user)` creates the row; `deliver_notifier!(klass, record:, recipient:)` wraps the `.with(...).deliver(...)` chain; `notification_for(recipient)` returns the most recent `Noticed::Notification`.
- **Noticed `deliver(relation)`**: calls `Array.wrap(recipients)` which calls `.to_a` on the relation — so even a Relation becomes a Ruby Array before the bulk insert, but the SQL path to *populate* the relation is now a single `IN (SELECT ...)` instead of the action_store materialize step.
- **`Noticed::Notification.where(recipient: user)`** works via polymorphic `recipient_id` + `recipient_type` columns.
- **`visible_in_web?` (`config/initializers/noticed.rb`)** — per-row Ruby predicate: (1) `event.type.constantize.persist_web_notification` (class attr, cheap); (2) `may_notify_via_web?` if defined, else `web_notification_enabled?` — the latter reads `recipient.notification_setting.<event>_web` JSONB (no SQL when assoc loaded); (3) `may_notify_via_web?` for `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row). So for power users with many notifications, the `select(&:visible_in_web?)` in `Dashboard::NotificationsController#index` is O(N) Ruby + O(N) action_store SELECTs (for comment/tagging rows).

## Run History (recent)
- **2026-06-29 13:02 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28372647768) - Verified PR #1760 (Order#notify_subscribers SQL subquery) MERGED 2026-06-28; PR #1767 (code-simplifier comment trim) MERGED 2026-06-29. No open perf-improver PRs. Investigated `Dashboard::NotificationsController#index` `select(&:visible_in_web?)` cost (O(N) Ruby rows + O(N) action_store SELECTs for Comment/Tagging notifiers via `should_notify?`). Documented as POTENTIAL — DEFERRED for a dedicated measurement + migration run.
- **2026-06-28** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28319357046) - `Order#notify_subscribers` SQL subquery refactor. Draft PR on `perf-assist/order-notify-subscribers-sql-subquery-20260628`. Verified PR #1759 (efficiency-improver active_authors SQL sampling) MERGED 2026-06-28, PR #1749 (repo-assist notify_subscribers subqueries) MERGED 2026-06-26, PR #1752 (efficiency-improver hot_tags SQL sampling) MERGED 2026-06-27. Homepage hot-path trilogy now closed.
- **2026-06-25** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28164802463) - `HomeController#active_authors` block subquery. Draft PR. Verified PR #1708 MERGED.
- **2026-06-24** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28093588419) - `HomeController#active_authors` block subquery (FIRST ATTEMPT, branch never pushed).
- **2026-06-20 10:45 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27868593597) - Admin user-list preloader. PR #1708 MERGED 2026-06-21.
- **2026-06-19 12:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27825037181) - `has_unread_notification?` SQL EXISTS. PR #1695 MERGED.

## Backlog Cursor
- `Order#notify_subscribers` SQL subquery refactor — ✅ **MERGED 2026-06-28** as PR #1760
- Homepage hot-path trilogy (active_authors block + active_authors sampling + hot_tags) — ✅ **ALL MERGED** (PR #1735, PR #1759, PR #1752)
- `notify_subscribers` callbacks — ✅ **DONE** (PR #1749 by repo-assist + PR #1760 Order call site)
- `Dashboard::NotificationsController#index` — 🔍 **DEFERRED for dedicated run**. The `select(&:visible_in_web?)` materializes ALL web notifications + runs per-row action_store SELECTs for Comment/Tagging rows. Fix requires migration (boolean `web_visible` column) + delivery-time population + backfill + tests. Need to measure with realistic fixture scale before/after.
- **Next**: measure `Dashboard::NotificationsController#index` baseline cost (synthesize ~500 notifications for a fixture user, run a controller test with `ActiveSupport::Notifications.subscribed`, count `FROM "actions"` SELECTs and total Ruby allocations). If the measured cost is significant, open the migration + delivery-time hook as a single PR. Otherwise pivot to (a) measurement-infrastructure work; (b) another `.limit(N).sample(K)` audit beyond `app/`.