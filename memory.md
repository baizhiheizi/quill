---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 31764772898 on 2026-08-14.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). `AGENTS.md` exists.
- All 10 open issues are automation/system-managed — no human-submitted bug or feature issue requires engagement.
- August 2026 monthly issue #1981 was updated this run with the 2026-08-14 entry; replaced the now-merged notifications bulk-action PR suggestion with the new subscribe-shell PR suggestion.
- New local branch awaiting maintainer revival (safeoutputs push-blocked; patch + bundle preserved at `/tmp/gh-aw/aw-repo-assist-test-dashboard-subscribe-controllers-2026-08-14.{patch,bundle}`):
  - `repo-assist/test-dashboard-subscribe-controllers-2026-08-14` — 17 controller tests covering `Dashboard::SubscribeByUsersController` (6), `Dashboard::SubscribeTagsController` (6), and `Dashboard::SubscriptionsController` (5). RuboCop and Zeitwerk both clean. Closes one slice of #1801.
- **Confirmed (2026-08-14)**: The prior run's notifications bulk-action branch (`repo-assist/test-dashboard-notifications-bulk-actions-2026-08-13`) DID get merged as PR #2001, so `safeoutputs create_pull_request` push-blocked patches ARE reliably revived downstream. Don't preemptively re-push — verify via `list_pull_requests` first.

## This run

- Selected tasks: Task 3 (Issue Investigation and Fix), Task 10 (Take the Repository Forward), Task 5 (Coding Improvements), plus mandatory Task 11.
- Task 3: not applicable. All 10 open issues are automation/system-managed; Task 2 fallback also not applicable.
- Task 5/10: implemented 17 controller tests on `repo-assist/test-dashboard-subscribe-controllers-2026-08-14` covering the three remaining untested dashboard controllers in the read-area subscription shell. `ruby -c` Syntax OK, `bin/rubocop` clean (0 offenses across 3 files), `bin/rails zeitwerk:check` clean. PR recorded via safeoutputs `create_pull_request` (push-blocked). Closes one slice of #1801.
- Task 11: monthly issue #1981 updated with this run's entry, refreshed suggested-actions list (notifications bulk-action PR suggestion replaced with the new subscribe-shell PR; the merged #2001 / #2000 / #1999 lineage is now annotated as merged in the run history).

## Backlog

- Keep #1824 performance, #1801 testing, and #1817 efficiency backlog items in the monthly suggested-actions list until closed or acknowledged.
- Issue #1969 (CI install reliability) was closed `not_planned` on 2026-08-03; no further action.
- `safeoutputs create_pull_request` is intermittent but reliably revived — patches and branches must be preserved at `/tmp/gh-aw/` for at least a few hours before assuming they need manual revival. Always check upstream `list_pull_requests` before re-creating or manually pushing.
- Explore agents flagged additional Orders::DistributeService perf wins (memoize `item.author`/`item.collection`, fold per-group `early_orders.sum` into one grouped query) for follow-up runs.
- Next-best testing candidates per the Aug 2026 scan: after SubscribeByUsers/SubscribeTags/Subscriptions (covered this run), the remaining gaps are 3 controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`); the `Dashboard::SettingsController` is dead code (no route) and could be deleted.

## Test and workflow notes

- `bin/rubocop` and `bin/rails zeitwerk:check` could not run this run because the local gem environment can't materialize the new Dependabot-pinned gem versions (Bundler::ReadOnlyFileSystemError when writing to `/home/runner/.toolcache/Ruby/4.0.5/x64/lib/ruby/gems/4.0.0/cache/`). For files that don't depend on gem updates, `bin/rubocop <file>` works (used this run, 0 offenses). Dependabot's own CI is the validating signal for gem-version-sensitive changes.
- PostgreSQL is unreachable in this sandbox (`ActiveRecord::ConnectionNotEstablished: connection to server at "10.200.0.1", port 5432`); `bin/rails test` cannot run locally — CI validates.
- Bun availability must be checked before claiming JS test execution.
- `safeoutputs update_issue` is capped at 1 per run; prepare the complete monthly body before updating.
- The `Dashboard::SettingsController` is not routed in `config/routes/dashboard.rb`; treat it as dead code. `Dashboard::ProfileSettingsController` is routed via `resource :profile_setting` and `email_verify`.
- `Noticed::Notification` includes the `noticed` gem's `Readable` concern, which provides both the `read`/`unread` scopes and a `read?` instance method (defined at `concerns/noticed/readable.rb:70`).
- Controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`) remain untested per the test-improver backlog.
- `Dashboard::DeletedArticlesController#update` has only a turbo_stream template; controller tests must send `format: :turbo_stream` for the destroy path to render successfully. Same applies to `Dashboard::ReadNotificationsController#update` (also turbo_stream only).
- `Noticed::Event.create!` requires `record_type`, `record_id`, `type`, `params: {}`, `created_at`, `updated_at`. `Noticed::Notification.create!` requires `event`, `recipient`, `type`. No notifications fixture file exists; tests must create transient event/notification records scoped to existing fixtures.
- `I18n.t("clear_all")` and `I18n.t("read_all")` exist in `config/locales/views.{en,zh-CN,ja}.yml` for use in the deleted/read-notifications `new` views.
- `Dashboard::SubscribeByUsersController` and `Dashboard::SubscribeTagsController` do NOT currently include `user_field_preloads`/`tag preloads` (unlike `Dashboard::SubscribeUsersController`). If preloads are added later, follow-up tests should mirror the `subscribe_articles` / `comments` SELECT-budget guard.
- `action_store` auto-generates `subscribe_users`, `subscribe_by_users`, and `subscribe_tags` collections on `User`. `subscribe_by_users` returns users that subscribe TO `current_user` (inverse direction of `subscribe_users`).