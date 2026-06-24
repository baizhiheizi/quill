# Perf Improver Memory

## Repository
- **Name**: baizhiheizi/quill
- **Type**: Rails 8.1 monolith (Web3 paid-publishing platform)
- **Stack**: Ruby 4.0.5, PostgreSQL, Solid Cache/Queue/Cable, Hotwire, esbuild

## Validated Commands

### Build/Setup
- `bundle install --jobs4 --retry3` - Install Ruby gems
- `bun install --frozen-lockfile` - Install Node modules
- `bin/dev` - Run full development stack
- `bun run build` / `bun run build:css` - Build frontend assets

### Test (NOTE: `unset CI` in this workflow env)
- `bin/rails test` - Run all tests
- `bin/rails zeitwerk:check` - Check Zeitwerk autoload
- `CI= bin/rails test` - Triggers eager load (DO NOT use — see Performance Notes)

### Lint
- `bin/rubocop` - Ruby lint
- `bun run lint-check` - Prettier check on JS/TS
- `bun run lint` - Prettier write

### CI
- `bin/ci` - Full CI pipeline

### Benchmarks
- `bin/benchmark` - All scenarios; per-scenario via `bin/benchmark article_search.subscribed`
- **Env note**: must `unset CI` first (see Performance Notes)

## Performance Opportunities Backlog
1. **[DONE] `has_unread_notification?` / `unread_notifications_count` hot path** — SQL `exists?` / `count` on `notifications.unread.for_web`. PR #1695 — **MERGED 2026-06-19**.
2. **[DONE] Admin::UsersController `bought_articles_count` / `author_revenue_total_usd` / `payment_total_usd`** — Added `preload_user_aggregates(users)` private helper that runs 3 batched GROUP BY queries and primes the per-user memoization ivars. 72 → 3 queries per admin user list page (96% reduction). PR #1708 — **MERGED 2026-06-21**.
3. **[DONE] HomeController#active_authors blocked-users exclusion** — Draft PR opened 2026-06-24 (`perf-assist/active-authors-block-subquery-20260624`). Replaces `where.not(id: current_user&.block_user_ids)` with a `NOT IN (SELECT actions.user_id FROM actions WHERE ...)` subquery. Eliminates 1 round-trip + O(N) Ruby array allocation per render. Guest render no longer touches the actions table at all. Same pattern as PR #1598.
4. **[LOW] `author_revenue_usd` / `reader_revenue_usd` (single-article, dashboard)** - Ruby-side sum with `includes(:currency)`. Memoized with `@author_revenue_usd ||= ...`. Used in `app/views/dashboard/articles/show.html.erb`. Single-article, very low impact.
5. **[LOW] `Admin::UsersController#show` single-user aggregates** — same three methods called once on `@user` (3 queries, single round-trip each). Not worth batching; admin show page is low-traffic.
6. **[NEW] `Admin::UsersController` paging over large user counts** — current page size is implicit (`pagy(:countless, users)`); verify default and consider whether a `pagy(:offset, users)` (vs `:countless`) is needed for very large `users` tables. (Observation only, no action planned.)
7. **[POTENTIAL] `notify_subscribers` callbacks (`Article` / `Tagging` / `Collection`)** — Three `after_create_commit` callbacks all build `(author.subscribe_by_user_ids - author.block_user_ids)` Ruby array set-difference then pass to `User.where(id: ...)`. Cold path (runs once per record create). Could be a single SQL: `WHERE id IN (SELECT target_id FROM actions WHERE …) AND id NOT IN (SELECT user_id FROM actions WHERE …)`. Symmetric follow-up to PRs #1546/#1598/active_authors, but absolute wall-time impact is small.

## Work in Progress
- Draft PR open on `perf-assist/active-authors-block-subquery-20260624` — waiting for maintainer review

## Completed Work
- PR #1708 (admin user-list aggregate preloader) on `perf-assist/admin-user-aggregates-batch-20260620-104507` — **MERGED 2026-06-21**
- PR #1695 (unread notification SQL EXISTS) — **MERGED 2026-06-19**
- PR #1688 (users.articles_count / comments_count counter caches) — **MERGED 2026-06-19**
- PR #1678 (Tag.hot count fix) — **MERGED 2026-06-17**
- PR #1634 (Users::Scopable LEFT JOINs) — **MERGED 2026-06-14**
- Monthly Activity issue #1513 `[perf-improver] Monthly Activity 2026-06` last updated 2026-06-14
- PR #1518 (random_readers SQL sampling) — merged
- PR #1521 (bought subquery) — merged
- PR #1523 (DailyStatistic payer counts) — merged
- PR #1539 (order_by_popularity LEFT JOIN + COALESCE) — merged 2026-06-07
- PR #1546 (subscribed filter SQL subqueries) — merged 2026-06-09
- PR #1598 (block filters SQL subqueries) — merged 2026-06-12

## Performance Notes
- **Env quirk**: gh-aw sets `CI=true`, triggering `config.eager_load = true` in test.rb → HTTP 403 from arweave.net. **`unset CI`** before any `bin/rails test` / `bin/benchmark`.
- **Memoization measurement**: `||=` ivars persist across loop iterations in `bin/rails runner`. Reload user instances per simulated request to measure properly.
- **Order test fixtures**: `Order#setup_attributes` needs a Payment; use `Order.insert_all!` for benchmark tests that don't exercise the lifecycle.
- **`blocked_reader` fixture has no `authorization`**: rendering admin user list raises `undefined method 'provider' for nil` via `messenger?`. Use direct controller tests or filter `@users` to authorized-only.
- **Admin auth bypass**: `@request.session[:current_admin_id] = administrators(:one).id` — `Admin::BaseController` only checks `current_admin.blank?`.
- **User session bypass for `ActionController::TestCase`**: set `@request.session[:current_session_id] = test_session.uuid` (where `test_session` is the return of `sign_in(user)`). `current_user` is `Session.find_by(uuid: session[:current_session_id])&.user`.
- **Counter cache pattern**: migration adds column + `belongs_to ..., counter_cache: true` on child. Already used extensively (Tagging→Tag, Comment→Commentable, action_store, etc.). SoftDeletable caveat: only fires on create/destroy, not `soft_delete!`.
- **Action store**: `action_store :verb, :target` dynamically generates `subscribe_user_ids`, `block_user_ids`, etc. Don't define manually in User model.
- **`safeoutputs update_issue` doesn't actually update body** in push-triggered runs (no triggering issue). Workaround: use `safeoutputs add_comment` with `item_number:` to append a new comment to the Monthly Activity issue.
- **`safeoutputs create_pull_request`** returns success with patch + bundle on disk — workflow orchestrator pushes and opens PR after agent run.
- **Query counter**: no `assert_queries_count` helper. Use `ActiveSupport::Notifications.subscribed(->(*, p) { ... }, "sql.active_record")` and skip `payload[:name] == "SCHEMA"`.
- **`Tag.hot.count` bug**: `relation.select("COUNT(...) AS foo")` (unused alias) breaks `relation.count` — PG rejects. Drop the alias or use `count(:id)`.
- **Test view rendering**: tests that hit `get :foo` may try to render the layout (which loads `application.css` — not present in test env). Stub `render` on the controller class to inspect `@users` / SQL via `ActiveSupport::Notifications.subscribed` instead.
- **Bug history**: INNER JOIN → LEFT JOIN + COALESCE for `order_by_popularity` (PR #1539), `Users::Scopable` order_by_* (PR #1634), `Tag.hot` count alias (PR #1678). All discovered and fixed by perf-improver.

## Run History (recent)
- **2026-06-24** - [Run](https://github.com/baizhiheizi/quill/actions/runs/28093588419) - `HomeController#active_authors` block subquery. Draft PR on `perf-assist/active-authors-block-subquery-20260624`. Verified PR #1708 + #1688 MERGED.
- **2026-06-20 10:45 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27868593597) - Admin user-list preloader. PR #1708 MERGED 2026-06-21.
- **2026-06-19 12:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27825037181) - `has_unread_notification?` SQL EXISTS. PR #1695 MERGED.
- **2026-06-18 18:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27757618658) - User counter caches. PR #1688 MERGED 2026-06-19.
- **2026-06-17 14:21 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27688558877) - `Tag.hot` count fix. PR #1678 MERGED 2026-06-17.
- **2026-06-14 03:39 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27464306984) - `Users::Scopable` LEFT JOINs. PR #1634 MERGED 2026-06-14.
- **2026-06-11 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27346010833) - Block filters subqueries. PR #1598 MERGED 2026-06-12.

## Backlog Cursor
- `has_unread_notification?` / `unread_notifications_count` — ✅ **MERGED** as PR #1695
- `Admin::UsersController#preload_user_aggregates` — ✅ **MERGED** as PR #1708 on 2026-06-21
- `users.articles_count` / `users.comments_count` counter caches — ✅ **MERGED** as PR #1688 on 2026-06-19
- `HomeController#active_authors` block subquery — ✅ **DRAFT PR** on `perf-assist/active-authors-block-subquery-20260624` (1 round-trip + O(N) Ruby array eliminated per render)
- `notify_subscribers` callbacks (Article/Tagging/Collection) — POTENTIAL follow-up to PR #1598/active_authors; cold path
- **Next**: monitor the open active_authors PR; if no review feedback by next run, pivot to (a) `notify_subscribers` callback refactor for symmetry, or (b) measurement infrastructure work (a backend complement to the efficiency-improver's `bin/measure-frontend-efficiency` proposal #1720).
