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
- `bin/benchmark` — All scenarios; per-scenario via `bin/benchmark article_search.subscribed` or `bin/benchmark dashboard.transfers`

## Performance Opportunities Backlog
1. **[DONE] `has_unread_notification?` / `unread_notifications_count`** — SQL `exists?` / `count` on `notifications.unread.for_web`. PR #1695 — **MERGED 2026-06-19**.
2. **[DONE] Admin user-list aggregate preloader** — `preload_user_aggregates(users)` runs 3 batched GROUP BY queries. 72 → 3 queries per page. PR #1708 — **MERGED 2026-06-21**.
3. **[DONE] `active_authors` block subquery** — PR #1735 — **MERGED 2026-06-26**.
4. **[DONE] `author_revenue_usd` / `reader_revenue_usd`** — `includes` → `joins(:currency)` cleanup. PR #1731 (repo-assist) — **MERGED 2026-06-25**.
5. **[DONE by repo-assist] `notify_subscribers` (Article/Collection/Tagging)** — PR #1749 — **MERGED 2026-06-26**. Adds `User#subscribed_user_ids_relation` / `User#blocked_user_ids_relation` helpers.
6. **[DONE by efficiency-improver] `active_authors` SQL sampling** — PR #1759 — **MERGED 2026-06-28**.
7. **[DONE by efficiency-improver] `hot_tags` SQL sampling + cache** — PR #1752 — **MERGED 2026-06-27**.
8. **[DONE] `Order#notify_subscribers` SQL subquery refactor** — Branch `perf-assist/order-notify-subscribers-sql-subquery-20260628`. PR #1760 — **MERGED 2026-06-28**. Reuses PR #1749 helper. 1 fewer round-trip per buy/reward/collection purchase. Fires on EVERY order. Follow-up PR #1767 (code-simplifier comment trim) MERGED 2026-06-29.
9. **[DONE] `Dashboard::CollectionsController#index` N+1** — PR #1802 (repo-assist) — **MERGED 2026-07-01**. `.includes(:currency, cover_attachment: :blob)`.
10. **[DONE] `Dashboard::ArticlesController#index` N+1** — PR #1815 (efficiency-improver, revived from push-blocked) — **MERGED 2026-07-03 02:32:20**. `.includes(:author, :currency, :tags, cover_attachment: :blob)`.
11. **[DONE on local branch] `Dashboard::NotificationsController#index` event N+1 fix** — Branch `perf-assist/dashboard-notifications-includes-event-20260630`. Awaiting maintainer revival (same pattern as PR #1815).
12. **[DRAFTED on local branch this run] `Dashboard::TransfersController#index` N+1** — Branch `perf-assist/dashboard-transfers-eager-load-20260703` (commit `26882f2`). `.includes(:currency, source: { item: :author })`. 4 files (+205/-1). Tests: `test/controllers/dashboard/transfers_controller_test.rb` (2 runs, 9 assertions, 0 failures; regression-guard fails at 20 currencies SELECTs without fix, passes with 1). Bench: `dashboard.transfers.eager_load 1.8 ms` vs `dashboard.transfers.legacy 31.5 ms` on 25-row fixtures (~17.5×). Patch at `/tmp/gh-aw/aw-perf-assist-dashboard-transfers-eager-load-20260703.{patch,bundle}`. **Different approach from repo-assist's `f6ea29cf` branch on the same controller** — Rails polymorphic preloading (`source: { item: :author }`) IS a one-line fix.
13. **[POTENTIAL — DEFERRED] `Dashboard::NotificationsController#index` action_store N+1** — `recipient.block_user?` from `should_notify?` for `CommentCreatedNotifier` / `TaggingCreatedNotifier` fires 1 SELECT per row via `ActionStore::Mixin#find_action`. Full fix: add `web_visible` boolean column to `Noticed::Notification`, populate at delivery time, `where(web_visible: true)` in the controller. Migration + backfill + tests. Bench shows: where(.in(`[Comment, Tagging]`)...) we'd reach 64 ms / iter (vs 153 ms post-eager-load). Significant remaining headroom for power users.

## Work in Progress
- **Branch `perf-assist/dashboard-transfers-eager-load-20260703` (commit `26882f2`)** ready for maintainer revival. Patch at `/tmp/gh-aw/aw-perf-assist-dashboard-transfers-eager-load-20260703.patch`. Maintainer can `git am` the file. Maintainer-revival pattern confirmed working via PR #1815 (merged 2026-07-03 02:32:20).

## Completed Work (recent)
- Branch `perf-assist/dashboard-transfers-eager-load-20260703` — `Dashboard::TransfersController#index` `.includes(:currency, source: { item: :author })`. Locally: 31.5ms → 1.8ms / iter (~17.5×), 100 SELECTs → 4 per 25-row page.
- Branch `perf-assist/dashboard-notifications-includes-event-20260630` (PRIOR run, still awaiting maintainer revival).
- PR #1767 (code-simplifier comment trim on Order#notify_subscribers) — **MERGED 2026-06-29**
- PR #1760 (order follower filter subqueries) — **MERGED 2026-06-28**
- PR #1759 (active_authors SQL sampling, efficiency-improver) — **MERGED 2026-06-28**
- PR (home active_authors block subquery) — **MERGED 2026-06-26** as PR #1735
- PR #1749 (notify_subscribers Article/Collection/Tagging, repo-assist) — **MERGED 2026-06-26**
- PR #1752 (hot_tags SQL sampling, efficiency-improver) — **MERGED 2026-06-27**
- PR #1815 (articles dashboard eager-load, efficiency-improver, revived) — **MERGED 2026-07-03**
- PR #1802 (collections dashboard eager-load, repo-assist) — **MERGED 2026-07-01**
- PR #1708 (admin user-list aggregate preloader) — **MERGED 2026-06-21**
- PR #1695 (unread notification SQL EXISTS) — **MERGED 2026-06-19**

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true`, triggering `config.eager_load = true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **Memoization measurement**: `||=` ivars persist across loop iterations in `bin/rails runner`. Reload user instances per simulated request to measure properly.
- **Order test fixtures**: `Order#setup_attributes` needs a Payment; use `Order.insert_all!` for benchmark tests that don't exercise the lifecycle.
- **`blocked_reader` fixture has no `authorization`**: rendering admin user list raises `undefined method 'provider' for nil` via `messenger?`. Use direct controller tests or filter `@users` to authorized-only.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. `subscribe_by_users` is a `has_many through: :subscribe_by_user_actions, source: :user` — issues 2 SELECTs (actions + users via auto-include).
- **`safeoutputs update_issue` doesn't actually update body** in push-triggered runs. Workaround: `safeoutputs add_comment` with `item_number:`.
- **`safeoutputs create_pull_request` reports success but does not materialize the PR** in this workflow env (git credentials removed after checkout). Branch + commit exist locally; `/tmp/gh-aw/aw-perf-*.patch` is the persisted patch. **Workaround**: maintainer applies patch via `git am` from `/tmp/gh-aw/aw-perf-*.patch`. **Confirmed twice this run (2026-06-30) — both safeoutputs calls returned `{success:true, patch:{...}, bundle:{...}}` but no PR appeared in `list_pull_requests`.**
- **`safeoutputs create_issue` ALSO intermittently reports success but does not persist** — Efficiency Improver 2026-07-02 23:25 UTC run flagged this. Same workaround: maintainer revival pattern works (PR #1815 merged 2026-07-03 02:32:20 from push-blocked branch via `git am`). For the monthly activity issue, fall back to `safeoutputs noop` + memory persistence.
- **Maintainer revival pattern (confirmed 2026-07-03)**: maintainer pulls patch from `/tmp/gh-aw/aw-*.patch`, applies via `git am`, force-pushes the branch (or revives from `/tmp/gh-aw/aw-*.bundle`), opens PR with `gh pr create`. PR #1815 (articles eager-load) merged this way after Efficiency Improver's push was blocked. So the "create local branch + commit + add patch + bundle" pattern still produces merged PRs — just not via `safeoutputs create_pull_request`.
- **Query counter**: no `assert_queries_count` helper. Use `ActiveSupport::Notifications.subscribed(->(*, p) { ... }, "sql.active_record")` and skip `payload[:name] == "SCHEMA"`.
- **`Tag.hot.count` bug**: `relation.select("COUNT(...) AS foo")` (unused alias) breaks `relation.count` — PG rejects. Drop the alias or use `count(:id)`.
- **`assigns` is unavailable** without `rails-controller-testing`. Use `@controller.instance_variable_get(:@ivar)` instead.
- **Polymorphic preload `source: { item: :author }` works** for `Transfer.has_many :transfers, as: :source` on `Order` (`belongs_to :item, polymorphic: true`). Rails fires one SELECT per `item_type`. Confirmed in this run.
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678).
- **`active_authors` is the homepage's "active authors" Turbo Frame** — highest-traffic page in the app.
- **Notifier helpers** (in `test/support/notifier_helpers.rb`): `ensure_notification_setting!(user)` creates the row; `deliver_notifier!(klass, record:, recipient:)` wraps the `.with(...).deliver(...)` chain; `notification_for(recipient)` returns the most recent `Noticed::Notification`.
- **Noticed `deliver(relation)`**: calls `Array.wrap(recipients)` which calls `.to_a` on the relation — so even a Relation becomes a Ruby Array before the bulk insert, but the SQL path to *populate* the relation is now a single `IN (SELECT ...)` instead of the action_store materialize step.
- **`Noticed::Notification.where(recipient: user)`** works via polymorphic `recipient_id` + `recipient_type` columns.
- **`visible_in_web?` (`config/initializers/noticed.rb`)** — per-row Ruby predicate:
  - `event.type.constantize.persist_web_notification` (class attr, cheap but `event` must be loaded)
  - `may_notify_via_web?` if defined, else `web_notification_enabled?` — the latter reads `recipient.notification_setting.<event>_web` JSONB (no SQL when assoc loaded)
  - `may_notify_via_web?` for `CommentCreatedNotifier` / `TaggingCreatedNotifier` chains `should_notify?` → `recipient.block_user? author` → `ActionStore::Mixin#find_action` (1 SELECT per row)
- **`Noticed::Event` `type` column** stores the NOTIFIER class name (e.g., `"CommentCreatedNotifier"`), not the AR model class. Required for `visible_in_web?`'s `event.type.constantize`.
- **Noticed `params` storage**: serialised via `ActiveJob::Arguments` Coder; empty `{}` is safe if `comment.author` etc. is never dereferenced. Use `params: {}` in synthetic-event INSERTs.
- **`Noticed::Notification.recipient`** is polymorphic `recipient_id + recipient_type`; AR preloads as a User when the type matches.
- **`Order#order_type` uniqueness validation** (`app/models/order.rb:53`): `validates :order_type, uniqueness: { scope: %i[order_type buyer_id item_id item_type], if: -> { buy_article? || buy_collection? } }` — when synthesising multiple Orders for the same buyer/item in a test, use `source: order` (re-link existing Order) instead of `create_buy_order!` per transfer.

## Run History (recent)
- **2026-07-03 11:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28655443787)
  - 🔍 Audited `Dashboard::TransfersController#index`. Partial walks `transfer.currency` + polymorphic `transfer.source` (Order) + polymorphic `transfer.source.item` (Article/Collection) + `transfer.source.item.author` (Article branch). ~3-4 SELECTs/row.
  - 🔧 Implemented `perf-assist/dashboard-transfers-eager-load-20260703` (commit `26882f2`): `transfers.includes(:currency, source: { item: :author })`. 1-line controller fix + 14-line comment.
  - 🧪 `test/controllers/dashboard/transfers_controller_test.rb` (new, 2 tests, 9 assertions). Regression-guard test synthesises 25 transfers, drives the partial chain, asserts ≤1 currencies/orders/articles SELECT each. Confirmed fail-then-pass: 20 currencies SELECTs without fix, 1 with it.
  - 📊 `bin/benchmark dashboard.transfers` — `eager_load 1.8 ms (min 1.8, max 1.9) / legacy 31.5 ms (min 23.0, max 54.2)` on 25-row test fixtures (~17.5× speedup).
  - ✅ Tests green (2 runs, 9 assertions, 0 failures); `bin/rubocop` clean on 3 files; `bin/rails zeitwerk:check` `all is good!`.
  - ⚠️ `safeoutputs create_pull_request` returned success but no PR opened (same push-blocked pattern as Efficiency Improver's articles branch; maintainer revival pattern from PR #1815 confirmed working). `safeoutputs create_issue` ALSO returned success but no issue persisted in this run (Efficiency Improver noted the same intermittent issue). Branch `perf-assist/dashboard-transfers-eager-load-20260703` + commit `26882f2` survive locally; patch + bundle at `/tmp/gh-aw/aw-perf-assist-dashboard-transfers-eager-load-20260703.{patch,bundle}`. Local fallback patch at `/tmp/gh-aw/agent/aw-perf-assist-dashboard-transfers-eager-load-20260703.patch`. Maintainer can apply via `git am` or revival flow.
- **2026-06-30 11:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28440184787) - `Dashboard::NotificationsController#index` event N+1 fix (branch `perf-assist/dashboard-notifications-includes-event-20260630`, commit `c0cfd96`). Awaiting maintainer revival.
- **2026-06-29 13:02 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28372647768) - Verified PR #1760 MERGED 2026-06-28; PR #1767 MERGED 2026-06-29. No open perf-improver PRs.
- **2026-06-28** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28319357046) - `Order#notify_subscribers` SQL subquery refactor. PR #1760.
- **2026-06-25** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28164802463) - `HomeController#active_authors` block subquery. PR #1735.

## Backlog Cursor
- Dashboard N+1 family — ✅ **Collections + Articles MERGED** (PR #1802 + PR #1815). **Transfers draft branch** (`perf-assist/dashboard-transfers-eager-load-20260703`) awaiting maintainer revival. **Payments draft branch** (`efficiency/dashboard-payments-preload` commit `b31a4b47`) also awaiting revival. Once revived, the dashboard N+1 sweep is done.
- `Dashboard::NotificationsController#index` event N+1 — ✅ **1-line fix shipped on local branch** (`perf-assist/dashboard-notifications-includes-event-20260630`). Awaiting maintainer to push (same revival flow).
- `Dashboard::NotificationsController#index` action_store N+1 — 🔍 **DEFERRED for a dedicated migration run**. Requires `web_visible` boolean column + delivery-time population + backfill. After fix: 153ms → 64ms / iter (4.7x speedup from current baseline).
- **Next**: if transfers revival lands, pivot to the action_store N+1 (`web_visible` migration) or another `.limit(N).sample(K)` audit beyond `app/`.
