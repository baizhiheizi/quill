---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
  updated: 2026-08-19
---

# Repo Assist Memory

## Current state

- **Run 32206551242 on 2026-08-19 (02:00 UTC).** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). `AGENTS.md` exists.
- 8 open issues — all automation/system-managed (Failed jobs #2022, monthly summaries #2012 / #2005, prior-run tracking #2019 / #1998 / #1997 / #1981, stale CI pinning #2016). No human-submitted bug or feature issue requires engagement.
- August 2026 monthly issue #1981 was updated with the 2026-08-19 02:00 UTC entry.
- One new draft PR this run (push-blocked, patches preserved at `/tmp/gh-aw/aw-repo-assist-perf-distribute-fold-sum-into-grouped-2026-08-19.*`):
  - `repo-assist/perf-distribute-fold-sum-into-grouped-2026-08-19` (commit `a6ea9f7b`) — folds `sum = early_orders.sum(readers_share_column)` into `sum = share_by_trace_id.values.sum`, eliminating one duplicate aggregate per paid article order. Behavioural identity preserved (both queries aggregate the same column over the same rows). RuboCop and Zeitwerk not run locally (read-only gem cache) but `ruby -c` Syntax OK. Closes one slice of #1824.

## This run

- Selected tasks: Task 3 (Issue Investigation and Fix), Task 4 (Engineering Investments), Task 2 (Issue Investigation and Comment), plus mandatory Task 11.
- Task 3: not applicable. All 8 open issues are automation/system-managed; 0 unlabelled.
- Task 2: not applicable. No human-submitted bug or feature issue requires engagement; backlog cursor reset.
- Task 4: no fresh engineering gap beyond the existing pending PRs #2016 / #2019 (CI image pinning, push-blocked) and Dependabot PR #2021 (postcss-import 16.2.0 → 17.0.0, BREAKING — requires Node 22+). Deferred — bundling a Node 22 toolchain change into a Dependabot batch needs maintainer review.
- Task 8 (added by selection-side weighting): folded the duplicate `early_orders.sum(...)` aggregate into `share_by_trace_id.values.sum` on `repo-assist/perf-distribute-fold-sum-into-grouped-2026-08-19` (commit `a6ea9f7b`). PR recorded via safeoutputs `create_pull_request` (push-blocked).
- Task 11: monthly issue #1981 updated with this run's entry; previous edition's suggested-actions list refreshed.

## Backlog

- Keep #1824 performance, #1801 testing, and #1817 efficiency backlog items in the monthly suggested-actions list until closed or acknowledged.
- Issue #1969 (CI install reliability) was closed `not_planned` on 2026-08-03; no further action.
- `safeoutputs create_pull_request` continues to be intermittent but reliably revived — patches and branches must be preserved at `/tmp/gh-aw/` for at least a few hours before assuming they need manual revival. Always check upstream `list_pull_requests` before re-creating or manually pushing.
- **New failure mode**: push-blocked PRs can leave stale entries in `list_pull_requests` with the right title but never update the remote branch. Always verify the branch contents (e.g. via `git log origin/<branch>`) match the PR's claimed changes before assuming a push-blocked PR recovered. Confirmed twice: 2026-08-16's `repo-assist/eng-ci-postgres-image-2026-08-16-...` and 2026-08-11's `repo-assist/eng-bundle-dependabot-updates-2026-08-11-...` both have only the single-commit "upgrade deps" / "aw: upgrade" drift commit on the remote branch.
- Remaining Orders::DistributeService perf wins: broader `item.author`/`item.collection` memoization across the whole method (only the collection-revenue block was memoized locally; the references block's `ref.reference.author.mixin_uuid` reads are still eager-loaded via `includes(reference: :author)`).
- Next-best testing candidates: `RichTextContent` cross-class coverage via Comment fixture (currently only `articles(:published_free` exercises it). All routed dashboard controllers now have controller-level coverage.

## Test and workflow notes

- `bin/rubocop` and `bin/rails zeitwerk:check` could not run this run because the local gem environment can't materialize the new Dependabot-pinned gem versions (Bundler::ReadOnlyFileSystemError when writing to `/home/runner/.toolcache/Ruby/4.0.5/x64/lib/ruby/gems/4.0.0/cache/`). For files that don't depend on gem updates, `bin/rubocop <file>` works. Dependabot's own CI is the validating signal for gem-version-sensitive changes.
- PostgreSQL is unreachable in this sandbox (`ActiveRecord::ConnectionNotEstablished: connection to server at "10.200.0.1", port 5432`); `bin/rails test` cannot run locally — CI validates.
- Bun availability must be checked before claiming JS test execution.
- `safeoutputs update_issue` is capped at 1 per run; prepare the complete monthly body before updating.
- `Dashboard::SettingsController` was deleted in PR #2014. `Dashboard::ProfileSettingsController` is routed via `resource :profile_setting` and `email_verify`.
- `Noticed::Notification` includes the `noticed` gem's `Readable` concern, which provides both the `read`/`unread` scopes and a `read?` instance method (defined at `concerns/noticed/readable.rb:70`).
- Controller concerns (`AdvisoryLockable`, `RichTextContent`, `Localizable`) — direct concern-level tests now exist for `AdvisoryLockable` (this run's PR #2018) and `Localizable` (this run's PR #2018); `RichTextContent` has `test/models/rich_text_content_test.rb` (covers Comment + Article).
- `Dashboard::DeletedArticlesController#update` has only a turbo_stream template; controller tests must send `format: :turbo_stream` for the destroy path to render successfully. Same applies to `Dashboard::ReadNotificationsController#update` (also turbo_stream only).
- `Noticed::Event.create!` requires `record_type`, `record_id`, `type`, `params: {}`, `created_at`, `updated_at`. `Noticed::Notification.create!` requires `event`, `recipient`, `type`. No notifications fixture file exists; tests must create transient event/notification records scoped to existing fixtures.
- `I18n.t("clear_all")` and `I18n.t("read_all")` exist in `config/locales/views.{en,zh-CN,ja}.yml` for use in the deleted/read-notifications `new` views.
- `action_store` auto-generates `subscribe_users`, `subscribe_by_users`, and `subscribe_tags` collections on `User`. `subscribe_by_users` returns users that subscribe TO `current_user` (inverse direction of `subscribe_users`).
- `_subscribe_button.html.erb` already supports `@preloaded_subscribe_user_ids` via `Array(@preloaded_subscribe_user_ids).include?(user.id) || current_user.subscribe_user?(user)`, so adding preloading on a new controller requires only the controller change — no view edit.
- `UserFieldPreloads#user_field_preloads` is the canonical avatar chain for any partial that renders `shared/_avatar` (authorization + avatar_attachment + blob + variant_records + preview_image_attachment).
- The `Dashboard::SubscribeUsersController` / `Dashboard::SubscribeByUsersController` preload pair is symmetrical on the read direction. `Dashboard::SubscribeTagsController#index` does NOT need this treatment — its partial (`_tag.html.erb` + `subscribe_tags/_subscribe_button`) walks no avatar chain and no per-row `subscribe_tag?` call.
- `Dashboard::BlockUsersController` is the precedent for the same pattern (`@preloaded_block_user_ids` from `current_user.block_user_actions.pluck(:target_id).to_set`).
- The per-reader share batching pattern (`early_orders.group(:trace_id).sum(...)`) is now in `Orders::DistributeService#distribute_article_order!`. `collect_early_readers` is delegated from `Orders::Distributable` and returns a `{mixin_uuid => [trace_ids]}` hash.
- **NEW (2026-08-19)**: `sum = share_by_trace_id.values.sum` is now used as the per-row total in `Orders::DistributeService#distribute_article_order!` — folded into the existing grouped query, eliminating the prior separate `early_orders.sum(readers_share_column)` aggregate. Saves one SQL round trip per paid article order.
- `ActiveSupport::Notifications.subscribed(callback, "sql.active_record")` works for SQL-count regression tests even without a DB connection at compile time — but the test still needs a real DB to actually run.
- `.github/workflows/check.yml` and `.github/workflows/opencode.yml` Postgres services are pending pinning (PR #2019, push-blocked). All other workflows in `.github/workflows/` use either `pgvector/pgvector:pg16-trixie` (agentic workflows) or `pgvector/pgvector:pg16`. The migration comment in `db/migrate/20260707234118_add_pg_trgm_indexes_for_search.rb` already declared `pgvector/pgvector:pg16` as the production image.
