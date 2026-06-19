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
1. **[DONE] `has_unread_notification?` / `unread_notifications_count` hot path** — SQL `exists?` / `count` on `notifications.unread.for_web`. Removes per-page-render Ruby scan that loaded every unread row for `select(&:visible_in_web?)`. Trade-off: badge no longer reproduces the per-recipient `visible_in_web?` predicate (notification_setting mutes and block_user guards) — overcounts slightly. PR opened 2026-06-19 on `perf-assist/has-unread-notification-exists-d00934bea7028f34`.
2. **[POTENTIAL] Admin::UsersController `bought_articles_count` / `author_revenue_total_usd` / `payment_total_usd`** - These still hit the DB per user (joins + sum). ~3 queries per user × 24 per page ≈ 72 queries/page. Counter-cache won't help (through-associations and sums). Could be a `User.with_aggregates` scope or batched query. The same methods are also used by `app/views/dashboard/home/index.html.erb` (current_user).
3. **[LOW] `author_revenue_usd` / `reader_revenue_usd` (single-article, dashboard)** - Ruby-side sum with `includes(:currency)`. Memoized with `@author_revenue_usd ||= ...`. Used in `app/views/dashboard/articles/show.html.erb`. Single-article, very low impact.

## Work in Progress
- (none — `has_unread_notification?` SQL refactor PR is the current open item; user counter caches WIP from 2026-06-18 was never pushed because the branch was committed locally but `safeoutputs create_pull_request` push step was skipped. Re-checking on a future run is optional.)

## Completed Work
- PR (unread notification badge) on `perf-assist/has-unread-notification-exists-d00934bea7028f34` — PR opened 2026-06-19
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
- **Env quirk**: this gh-aw workflow sets `CI=true`, making `config.eager_load = true` in `config/environments/test.rb`. Eager load hits `app/libs/arweave_bot/graphql.rb` (HTTP 403 to `arweave.net`). Workaround: **`unset CI` before any `bin/rails test` / `bin/benchmark`.
- **Bug discovered & merged**: `Article.order_by_popularity` used `joins(:orders)` (INNER JOIN); articles with no orders were excluded from default feed. Fixed in PR #1539.
- **Bug discovered & merged**: `Users::Scopable` order_by_revenue_total / orders_total / articles_count / comments_count used `joins(...)` (INNER JOIN); users with no matching rows were excluded from the admin user list. Fixed in PR #1634.
- **Bug discovered & merged**: `Tag.hot` scope `select("COUNT(articles.id) AS lately_article_count")` was unused outside the scope but broke `Tag.hot.count` (PG::SyntaxError). Fixed in PR #1678.
- **Counter cache pattern**: Quill already uses `counter_cache: true` extensively (Tagging→Tag.articles_count, Tagging→Article.tags_count, Comment→Commentable, action_store counters on User, etc.). When adding new counter cache columns, follow the established pattern: migration adds the column, `belongs_to ..., counter_cache: true` on the child model, no need to override anything in the parent.
- **Counter cache + soft delete**: `Comment` is `SoftDeletable`; `counter_cache: true` only fires on create/destroy, not on `soft_delete!`. The column therefore reflects total ever-made comments, not currently-active ones.
- **Action store**: `action_store` gem dynamically generates `subscribe_user_ids`, `block_user_ids`, `block_by_user_ids`, etc. from `action_store :verb, :target` declarations. No need to define in User model.
- **PR creation in this env**: `safeoutputs create_pull_request` returns `{"result":"success", "patch": {...}, "bundle": {...}}` — workflow orchestrator pushes the bundle and opens the actual PR after the agent run completes.
- **Monthly issue update_issue in this env**: `safeoutputs update_issue` returns `{"result":"success"}` but does NOT actually update the body when the workflow target is `triggering` (push-triggered run has no triggering issue). Workaround: use `safeoutputs add_comment` with `item_number: <issue>` to append a new comment with the latest run summary.
- **Benchmarks**: `bin/benchmark` works with `unset CI`. Fixture-scale only; relative before/after useful.
- **Test DB pollution**: `bin/rails runner` outside test transactions persists writes. Always clean up after debug.
- **Pre-existing test failures**: `markdown_render_service_test.rb` / `rich_text_render_service_test.rb` fail with HTTP 403 to external image hosts; firewall-blocked, not caused by perf-improver changes.
- **Copilot PR review false positives**: Copilot reviews on PR #1546 produced 2 comments that were resolved without code changes — both flagged issues were already addressed in the original diff.
- **Tag.hot count bug**: Any `relation.select("foo AS bar")` that aliases a bare aggregate will break `relation.count` — ActiveRecord generates `SELECT COUNT(<select-clause>)` and PG rejects it. Fix: drop the alias if unused, or use `select("foo AS bar").count(:id)` style.
- **`Tag.hot` is the homepage "hot tags" feed**: 5-min Rails cache via `HomeController#hot_tags`. Only caller chains `.where(locale: ...).limit(50).sample(5)`. No `lately_article_count` reads; ordering is via `Arel.sql` since PR #1678.
- **Fixtures and counter caches**: YAML fixtures set the row directly, so `users.articles_count` defaults to 0 in tests even when the author has articles via fixture rows. The original test for `order_by_articles_count` (PR #1634) passed because the test ran the JOIN + COUNT, not because the column was set. When refactoring order_by_* to use a column, tests need to `update_column` the counter explicitly.
- **Query counter helper**: no `assert_queries_count` in this repo's test_helper; use `ActiveSupport::Notifications.subscribed(->(*, p) { ... }, "sql.active_record")` with a counter. Skip `payload[:name] == "SCHEMA"`.
- **`has_unread_notification?` trade-off decision**: SQL `exists?` on `for_web` overcounts when the user has muted the notification type via `notification_setting` or has blocked the source. The exact visible-only set is still computed on the notifications index page where one-shot Ruby work is appropriate. Rejected alternatives: (a) counter cache on `users.unread_web_notifications_count` maintained by callbacks — staleness on setting toggles, complex backfill; (b) denormalized `noticed_notifications.web_visible` boolean — same staleness on setting toggles; (c) SQL-push the `visible_in_web?` predicate — predicates are Ruby methods reading `notification_setting` and `block_user?`, would need a large new join/case expression and the predicate doesn't belong on the notification record.

## Run History (recent)
- **2026-06-19 12:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27825037181) - Replaced `has_unread_notification?` and `unread_notifications_count` Ruby scan with SQL `exists?` / `count` on `notifications.unread.for_web`. PR opened on `perf-assist/has-unread-notification-exists-d00934bea7028f34`. Tests 5/5 new in statable_test.rb; 237/237 model+notifier, 0 regressions. Rubocop/zeitwerk clean.
- **2026-06-18 18:30 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27757618658) - Added `users.articles_count` / `users.comments_count` counter-cache columns with backfill. `Article#belongs_to :author, counter_cache: true` and `Comment#belongs_to :author, counter_cache: true` maintain them. `Users::Scopable#order_by_articles_count` / `#order_by_comments_count` reduced from `LEFT JOIN + GROUP BY + COUNT` to `ORDER BY column DESC, id ASC`. `Users::Statable#articles_count` / `#comments_count` read the column (O(1)). Tests 159/323, 0 failures. PR open on `perf-assist/user-counter-caches-d00934bea7028f34`.
- **2026-06-17 14:21 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27688558877) - Fixed `Tag.hot.count` PG::SyntaxError by dropping unused select alias. PR #1678 (merged 2026-06-17). Tests 12/23, 0 failures.
- **2026-06-14 03:39 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27464306984) - `Users::Scopable` to LEFT JOIN + COALESCE for SUM. PR #1634 (merged 2026-06-14). Tests 15/43, 0 failures.
- **2026-06-11 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27346010833) - `ArticleSearchService` block filters → SQL subqueries. PR #1598 (merged 2026-06-12). Tests 10/35, 0 failures.
- **2026-06-09 12:00 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27202813938) - Confirmed PR #1546 open/clean; no new code this run.
- **2026-06-08 12:50 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27138209827) - `subscribed` filter → SQL subqueries (9 → 5 queries). PR #1546 (merged 2026-06-09). Tests 7/21, 0 failures.
- **2026-06-07 00:24 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/27059506134) - `unset CI` workaround discovered; INNER JOIN default-feed bug fixed. PR #1539 (merged 2026-06-07). Tests 16/30, 0 failures.
- **2026-06-01 12:00 UTC** - Created PR #1518 (random_readers SQL sampling) — merged
- **2026-06-01 08:31 UTC** - [Run](https://github.com/baizhiheizi/quill/actions/runs/26739902209) - Created Monthly Activity issue

## Backlog Cursor
- `has_unread_notification?` / `unread_notifications_count` — ✅ PR OPEN (SQL exists?/count refactor)
- `users.articles_count` / `users.comments_count` counter cache — WIP local commit, never pushed (was on a stale `perf-assist/user-counter-caches-d00934bea7028f34` branch that didn't make it to a PR)
- `author_revenue_usd` / `reader_revenue_usd` / `payment_total_usd` denormalization for admin user list (72 queries/page) — NEXT
- **Next**: denormalize `users.payment_total_usd_cents` / `author_revenue_total_usd_cents` (denormalized counter) to eliminate the per-user sum in `app/views/admin/users/_user.html.erb` (24 × 3 = 72 queries/page).
