---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
  updated: 2026-08-15
---

# Repo Assist Memory

## Current state

- **Run 31857567331 on 2026-08-15 (01:59 UTC).** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). `AGENTS.md` exists.
- All 11 open issues are automation/system-managed — no human-submitted bug or feature issue requires engagement.
- August 2026 monthly issue #1981 was updated with the 2026-08-15 01:59 UTC entry; the merged PR #2006 line was replaced by the two new push-blocked PRs from this run.
- Two new local branches awaiting maintainer revival (safeoutputs push-blocked; patches + bundles preserved at `/tmp/gh-aw/aw-repo-assist-*.{patch,bundle}` and copied to `/tmp/gh-aw/agent/`):
  - `repo-assist/perf-distribute-service-batch-early-readers-2026-08-15` (commit `f5972d57`) — `Orders::DistributeService#distribute_article_order!` per-reader share batching: replaces per-group `early_orders.where(trace_id: order_ids).sum(...)` with one `early_orders.group(:trace_id).sum(...)` lookup. Saves R-1 SQL round trips per article order. Adds regression test asserting SUM query count bounded ≤2 via `ActiveSupport::Notifications.subscribed`. Closes one slice of #1824.
  - `repo-assist/remove-dead-settings-controller-2026-08-15` (commit `d99a868f`) — deletes orphaned `Dashboard::SettingsController` (no route, no callers, no tests). The two partials under `app/views/dashboard/settings/` stay because they're rendered from `dashboard/notifications/index` and `notification_settings/update.turbo_stream`. Closes one slice of #1801.
- **Confirmed**: PR #2006 (subscribe-shell test PR from earlier run) merged into `main` earlier on 2026-08-14. Pattern: push-blocked patches reliably revive downstream.

## This run

- Selected tasks: Task 2 (Issue Investigation and Comment), Task 8 (Performance Improvements), Task 5 (Coding Improvements), plus mandatory Task 11.
- Task 2: not applicable. All 11 open issues are automation/system-managed and labelled.
- Task 8: implemented `Orders::DistributeService#distribute_article_order!` per-reader share batching on `repo-assist/perf-distribute-service-batch-early-readers-2026-08-15` (commit `f5972d57`). Mirror of existing `group(:trace_id)` pattern. `bin/rubocop` clean. `ruby -c` Syntax OK on both files. PR recorded via safeoutputs `create_pull_request` (push-blocked). Closes one slice of #1824.
- Task 5: removed orphaned `Dashboard::SettingsController` on `repo-assist/remove-dead-settings-controller-2026-08-15` (commit `d99a868f`). Verified no route, no callers, no tests reference it. The two settings partials stay (still rendered). PR recorded via safeoutputs `create_pull_request` (push-blocked). Closes one slice of #1801.
- Task 11: monthly issue #1981 updated; the merged PR #2006 line was replaced by the two new push-blocked PRs from this run.

## Backlog

- Keep #1824 performance, #1801 testing, and #1817 efficiency backlog items in the monthly suggested-actions list until closed or acknowledged.
- Issue #1969 (CI install reliability) was closed `not_planned` on 2026-08-03; no further action.
- `safeoutputs create_pull_request` is intermittent but reliably revived — patches and branches must be preserved at `/tmp/gh-aw/` for at least a few hours before assuming they need manual revival. Always check upstream `list_pull_requests` before re-creating or manually pushing.
- Remaining Orders::DistributeService perf wins: `item.author`/`item.collection` memoization is partial in this run (only the collection-revenue block was memoized locally; the references block's `ref.reference.author.mixin_uuid` reads are still eager-loaded via `includes(reference: :author)`).
- Next-best testing candidates: the three remaining controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`). All routed dashboard controllers now have controller-level coverage.

## Test and workflow notes

- `bin/rubocop` and `bin/rails zeitwerk:check` could not run this run because the local gem environment can't materialize the new Dependabot-pinned gem versions (Bundler::ReadOnlyFileSystemError when writing to `/home/runner/.toolcache/Ruby/4.0.5/x64/lib/ruby/gems/4.0.0/cache/`). For files that don't depend on gem updates, `bin/rubocop <file>` works. Dependabot's own CI is the validating signal for gem-version-sensitive changes.
- PostgreSQL is unreachable in this sandbox (`ActiveRecord::ConnectionNotEstablished: connection to server at "10.200.0.1", port 5432`); `bin/rails test` cannot run locally — CI validates.
- Bun availability must be checked before claiming JS test execution.
- `safeoutputs update_issue` is capped at 1 per run; prepare the complete monthly body before updating.
- `Dashboard::SettingsController` was deleted in this run. `Dashboard::ProfileSettingsController` is routed via `resource :profile_setting` and `email_verify`.
- `Noticed::Notification` includes the `noticed` gem's `Readable` concern, which provides both the `read`/`unread` scopes and a `read?` instance method (defined at `concerns/noticed/readable.rb:70`).
- Controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`) remain untested per the test-improver backlog.
- `Dashboard::DeletedArticlesController#update` has only a turbo_stream template; controller tests must send `format: :turbo_stream` for the destroy path to render successfully. Same applies to `Dashboard::ReadNotificationsController#update` (also turbo_stream only).
- `Noticed::Event.create!` requires `record_type`, `record_id`, `type`, `params: {}`, `created_at`, `updated_at`. `Noticed::Notification.create!` requires `event`, `recipient`, `type`. No notifications fixture file exists; tests must create transient event/notification records scoped to existing fixtures.
- `I18n.t("clear_all")` and `I18n.t("read_all")` exist in `config/locales/views.{en,zh-CN,ja}.yml` for use in the deleted/read-notifications `new` views.
- `action_store` auto-generates `subscribe_users`, `subscribe_by_users`, and `subscribe_tags` collections on `User`. `subscribe_by_users` returns users that subscribe TO `current_user` (inverse direction of `subscribe_users`).
- `_subscribe_button.html.erb` already supports `@preloaded_subscribe_user_ids` via `Array(@preloaded_subscribe_user_ids).include?(user.id) || current_user.subscribe_user?(user)`, so adding preloading on a new controller requires only the controller change — no view edit.
- `UserFieldPreloads#user_field_preloads` is the canonical avatar chain for any partial that renders `shared/_avatar` (authorization + avatar_attachment + blob + variant_records + preview_image_attachment).
- The `Dashboard::SubscribeUsersController` / `Dashboard::SubscribeByUsersController` preload pair is symmetrical on the read direction. `Dashboard::SubscribeTagsController#index` does NOT need this treatment — its partial (`_tag.html.erb` + `subscribe_tags/_subscribe_button`) walks no avatar chain and no per-row `subscribe_tag?` call.
- `Dashboard::BlockUsersController` is the precedent for the same pattern (`@preloaded_block_user_ids` from `current_user.block_user_actions.pluck(:target_id).to_set`).
- The per-reader share batching pattern (`early_orders.group(:trace_id).sum(...)`) is now in `Orders::DistributeService#distribute_article_order!`. `collect_early_readers` is delegated from `Orders::Distributable` and returns a `{mixin_uuid => [trace_ids]}` hash.
- `ActiveSupport::Notifications.subscribed(callback, "sql.active_record")` works for SQL-count regression tests even without a DB connection at compile time — but the test still needs a real DB to actually run.