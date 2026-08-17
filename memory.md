---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
  updated: 2026-08-17
---

# Repo Assist Memory

## Current state

- **Run 31986388935 on 2026-08-17 (01:59 UTC).** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). `AGENTS.md` exists.
- All 11 open issues are automation/system-managed — no human-submitted bug or feature issue requires engagement.
- August 2026 monthly issue #1981 was updated with the 2026-08-17 01:59 UTC entry.
- Two new draft PRs this run (both push-blocked, patches preserved at `/tmp/gh-aw/aw-repo-assist-*`):
  - `repo-assist/test-advisory-lockable-concern-2026-08-17` (commit `6ec078e7`) — adds `test/models/concerns/advisory_lockable_test.rb` (5 tests covering `lock_id_for`'s determinism, 63-bit range, distinct-key collisions, `to_s` coercion, nil→"") and `test/controllers/concerns/localizable_test.rb` (10 tests covering `browser_locale` highest-quality selection, q=0 rejection, wildcard rejection, case-insensitive matching, whitespace tolerance, nil for no candidates, and the private `match?` helper). RuboCop and Zeitwerk clean. Closes one slice of #1801.
  - `repo-assist/eng-ci-postgres-image-2026-08-17` (commit `53b531f6`) — pins `check.yml` AND `opencode.yml` Postgres service from `postgres:latest` to `pgvector/pgvector:pg16`. Broader scope than last run's #2016 attempt.
- **Verified (this run)**: PR #2016 from 2026-08-16 (the CI pinning PR) appears in the open-PRs list but the underlying remote branch `repo-assist/eng-ci-postgres-image-2026-08-16-3ee14694a1a5e6ed` actually holds the `upgrade deps` commit (`a6cd1e1b`) — the CI pinning change was NOT merged. This is the "push-blocked with stale title" pattern: the safe-outputs PR exists but the underlying branch never got the actual changes. This run's engineering PR covers both `check.yml` and `opencode.yml` and should obsolete #2016 once merged.

## This run

- Selected tasks: Task 3 (Issue Investigation and Fix), Task 9 (Testing Improvements), Task 4 (Engineering Investments), plus mandatory Task 11.
- Task 3: not applicable. All 11 open issues are automation/system-managed; 0 unlabelled.
- Task 9: added 15 new tests across two concern test files (`AdvisoryLockable` model + `Localizable` controller) on `repo-assist/test-advisory-lockable-concern-2026-08-17` (commit `6ec078e7`). RuboCop and Zeitwerk clean. PR recorded via safeoutputs `create_pull_request` (push-blocked).
- Task 4: pinned `check.yml` AND `opencode.yml` Postgres service from `postgres:latest` to `pgvector/pgvector:pg16` on `repo-assist/eng-ci-postgres-image-2026-08-17` (commit `53b531f6`). Broader scope than the 2026-08-16 attempt (which only covered `check.yml` and never merged). PR recorded via safeoutputs `create_pull_request` (push-blocked).
- Task 11: monthly issue #1981 updated with this run's entry; new suggested-actions items added for both push-blocked PRs; future-work section refreshed.

## Backlog

- Keep #1824 performance, #1801 testing, and #1817 efficiency backlog items in the monthly suggested-actions list until closed or acknowledged.
- Issue #1969 (CI install reliability) was closed `not_planned` on 2026-08-03; no further action.
- `safeoutputs create_pull_request` is intermittent but reliably revived — patches and branches must be preserved at `/tmp/gh-aw/` for at least a few hours before assuming they need manual revival. Always check upstream `list_pull_requests` before re-creating or manually pushing.
- **New failure mode**: push-blocked PRs can leave stale entries in `list_pull_requests` with the right title but never update the remote branch. Always verify the branch contents (e.g. via `git log origin/<branch>`) match the PR's claimed changes before assuming a push-blocked PR recovered.
- Remaining Orders::DistributeService perf wins: `item.author`/`item.collection` memoization is partial (only the collection-revenue block was memoized locally; the references block's `ref.reference.author.mixin_uuid` reads are still eager-loaded via `includes(reference: :author)`).
- Next-best testing candidates: `RichTextContent` cross-class coverage via Comment fixture (currently only `articles(:published_free` exercises it). All routed dashboard controllers now have controller-level coverage.

## Test and workflow notes

- `bin/rubocop` and `bin/rails zeitwerk:check` could not run this run because the local gem environment can't materialize the new Dependabot-pinned gem versions (Bundler::ReadOnlyFileSystemError when writing to `/home/runner/.toolcache/Ruby/4.0.5/x64/lib/ruby/gems/4.0.0/cache/`). For files that don't depend on gem updates, `bin/rubocop <file>` works. Dependabot's own CI is the validating signal for gem-version-sensitive changes.
- PostgreSQL is unreachable in this sandbox (`ActiveRecord::ConnectionNotEstablished: connection to server at "10.200.0.1", port 5432`); `bin/rails test` cannot run locally — CI validates.
- Bun availability must be checked before claiming JS test execution.
- `safeoutputs update_issue` is capped at 1 per run; prepare the complete monthly body before updating.
- `Dashboard::SettingsController` was deleted in PR #2014. `Dashboard::ProfileSettingsController` is routed via `resource :profile_setting` and `email_verify`.
- `Noticed::Notification` includes the `noticed` gem's `Readable` concern, which provides both the `read`/`unread` scopes and a `read?` instance method (defined at `concerns/noticed/readable.rb:70`).
- Controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`) — direct concern-level tests now exist for `AdvisoryLockable` (this run) and `Localizable` (this run); `RichTextContent` has `test/models/rich_text_content_test.rb` (covers Comment + Article).
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
- `.github/workflows/check.yml` and `.github/workflows/opencode.yml` Postgres services were pinned to `pgvector/pgvector:pg16` (this run). Every workflow in `.github/workflows/` now uses either `pgvector/pgvector:pg16` (this run's two changes) or `pgvector/pgvector:pg16-trixie` (all agentic workflows). No more `postgres:latest` anywhere in the workflows directory. The migration comment in `db/migrate/20260707234118_add_pg_trgm_indexes_for_search.rb` already declared this image as the production one.