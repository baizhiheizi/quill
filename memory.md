---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 31806130097 on 2026-08-14.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). `AGENTS.md` exists.
- All 10 open issues are automation/system-managed — no human-submitted bug or feature issue requires engagement.
- August 2026 monthly issue #1981 was updated this run with the 2026-08-14 13:51 UTC entry; the previous "subscribe-shell test PR" line in suggested actions was removed because PR #2006 (the same slice) merged into `main` earlier this morning, and the new inverse-subscribe preload PR was added in its place.
- New local branch awaiting maintainer revival (safeoutputs push-blocked; patch + bundle preserved at `/tmp/gh-aw/aw-repo-assist-perf-dashboard-subscribe-by-users-preload-2026-08-14.{patch,bundle}` and copied to `/tmp/gh-aw/agent/`):
  - `repo-assist/perf-dashboard-subscribe-by-users-preload-2026-08-14` (commit `1a218e7f`) — mirrors `Dashboard::SubscribeUsersController#index` preload pattern on the inverse `subscribe_by_users` direction: `includes(user_field_preloads)` + `@preloaded_subscribe_user_ids`. Reduces ~125 SELECTs/25-row page to ~3. Adds 1 controller test asserting the preloaded set is populated. Closes one slice of #1824.
- **Confirmed (2026-08-14)**: PR #2006 (subscribe-shell test PR from earlier run) merged into `main`. Pattern: push-blocked patches reliably revive downstream.

## This run

- Selected tasks: Task 8 (Performance Improvements), Task 2 (Issue Investigation and Comment), Task 1 (Issue Labelling), plus mandatory Task 11.
- Task 1: not applicable. All open issues are automation/system-managed and labelled.
- Task 2: not applicable. All open issues already have a Repo Assist comment from prior runs; no new human activity on automation issues.
- Task 8: implemented `Dashboard::SubscribeByUsersController#index` N+1 fix on `repo-assist/perf-dashboard-subscribe-by-users-preload-2026-08-14` (commit `1a218e7f`). Mirror of `Dashboard::SubscribeUsersController#index`: `includes(user_field_preloads)` + `@preloaded_subscribe_user_ids = current_user.subscribe_user_actions.pluck(:target_id).to_set`. Added 1 controller test. `ruby -c` Syntax OK on both files. PR recorded via safeoutputs `create_pull_request` (push-blocked). Closes one slice of #1824.
- Task 11: monthly issue #1981 updated; removed the merged PR #2006 line and added the new inverse-subscribe preload PR suggestion.

## Backlog

- Keep #1824 performance, #1801 testing, and #1817 efficiency backlog items in the monthly suggested-actions list until closed or acknowledged.
- Issue #1969 (CI install reliability) was closed `not_planned` on 2026-08-03; no further action.
- `safeoutputs create_pull_request` is intermittent but reliably revived — patches and branches must be preserved at `/tmp/gh-aw/` for at least a few hours before assuming they need manual revival. Always check upstream `list_pull_requests` before re-creating or manually pushing.
- Remaining Orders::DistributeService perf wins (`item.author`/`item.collection` memoization, fold per-group `early_orders.sum` into one grouped query) are still unaddressed.
- Next-best testing candidates: the three remaining controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`); the `Dashboard::SettingsController` is dead code (no route) and could be deleted.

## Test and workflow notes

- `bin/rubocop` and `bin/rails zeitwerk:check` could not run this run because the local gem environment can't materialize the new Dependabot-pinned gem versions (Bundler::ReadOnlyFileSystemError when writing to `/home/runner/.toolcache/Ruby/4.0.5/x64/lib/ruby/gems/4.0.0/cache/`). For files that don't depend on gem updates, `bin/rubocop <file>` works. Dependabot's own CI is the validating signal for gem-version-sensitive changes.
- PostgreSQL is unreachable in this sandbox (`ActiveRecord::ConnectionNotEstablished: connection to server at "10.200.0.1", port 5432`); `bin/rails test` cannot run locally — CI validates.
- Bun availability must be checked before claiming JS test execution.
- `safeoutputs update_issue` is capped at 1 per run; prepare the complete monthly body before updating.
- The `Dashboard::SettingsController` is not routed in `config/routes/dashboard.rb`; treat it as dead code. `Dashboard::ProfileSettingsController` is routed via `resource :profile_setting` and `email_verify`.
- `Noticed::Notification` includes the `noticed` gem's `Readable` concern, which provides both the `read`/`unread` scopes and a `read?` instance method (defined at `concerns/noticed/readable.rb:70`).
- Controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`) remain untested per the test-improver backlog.
- `Dashboard::DeletedArticlesController#update` has only a turbo_stream template; controller tests must send `format: :turbo_stream` for the destroy path to render successfully. Same applies to `Dashboard::ReadNotificationsController#update` (also turbo_stream only).
- `Noticed::Event.create!` requires `record_type`, `record_id`, `type`, `params: {}`, `created_at`, `updated_at`. `Noticed::Notification.create!` requires `event`, `recipient`, `type`. No notifications fixture file exists; tests must create transient event/notification records scoped to existing fixtures.
- `I18n.t("clear_all")` and `I18n.t("read_all")` exist in `config/locales/views.{en,zh-CN,ja}.yml` for use in the deleted/read-notifications `new` views.
- `action_store` auto-generates `subscribe_users`, `subscribe_by_users`, and `subscribe_tags` collections on `User`. `subscribe_by_users` returns users that subscribe TO `current_user` (inverse direction of `subscribe_users`).
- `_subscribe_button.html.erb` already supports `@preloaded_subscribe_user_ids` via `Array(@preloaded_subscribe_user_ids).include?(user.id) || current_user.subscribe_user?(user)`, so adding preloading on a new controller requires only the controller change — no view edit.
- `UserFieldPreloads#user_field_preloads` is the canonical avatar chain for any partial that renders `shared/_avatar` (authorization + avatar_attachment + blob + variant_records + preview_image_attachment).
- The `Dashboard::SubscribeUsersController` / `Dashboard::SubscribeByUsersController` preload pair is now symmetrical on the read direction. `Dashboard::SubscribeTagsController#index` does NOT need this treatment — its partial (`_tag.html.erb` + `subscribe_tags/_subscribe_button`) walks no avatar chain and no per-row `subscribe_tag?` call.
- `Dashboard::BlockUsersController` is the precedent for the same pattern (`@preloaded_block_user_ids` from `current_user.block_user_actions.pluck(:target_id).to_set`).