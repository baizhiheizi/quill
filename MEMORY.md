# Test Improver Memory

- [Run notes 2026-07-07](2026-07-07-notes.md) — MixinMessage coverage re-run (21 / 52, commit `2043b01`); 2026-07-06 was lost (no PR promoted)
- [Run notes 2026-07-06](2026-07-06-notes.md) — MixinMessage coverage (25 / 49, commit `102ac562`)

## Discovered Commands

- Tests: `bin/rails test` (Minitest 6.0.6), `bin/rails test:system` (Capybara). `SKIP_CSS_BUILD=1 bin/rails test:models` bypasses CSS bundling when Bun unavailable.
- Lint: `bin/rubocop`, `bun run lint-check` (Prettier)
- Zeitwerk: `bin/rails zeitwerk:check`
- DB: `bin/rails db:prepare` (main + cable + queue)
- Full CI: `bin/ci`
- Coverage: no SimpleCov/Codecov in CI

## Testing Notes

- **`QuillBot.define_singleton_method(:api) { ... }` block evaluates under `QuillBot`, not the test instance** — `with_quill_bot_stub` (`test/support/quill_bot_stub.rb`) handles the local-capture teardown correctly. Prefer the helper over inline stubbing.
- **`test/models/transfer_test.rb:220-229` class-pollution bug** — swaps `UserAuthorization#has_safe?` then `remove_method`s it in `ensure` instead of restoring. Mitigation in `user_authorization_test.rb` captures `instance_method(:has_safe?)` at file load.
- **`belongs_to` instances are fresh** — singleton method overrides on fixture instances (e.g. `users(:author).define_singleton_method(:notify_for_login) { ... }`) don't propagate. Stub on the actual association instance (e.g. `msg.user.define_singleton_method(...)`), not the fixture. Per-instance `define_singleton_method` is fine; class-level `define_method` with `ensure` restore is needed when the test wants the override visible across all instances in a test case.
- **`Bonus` AASM still blocked**: `Bonus.table_name` returns `"bonus"` (Rails class-name inference), but `db/schema.rb` defines `"bonuses"`. PG::UndefinedTable on `Bonus.create!`.
- **`MixinMessage#setup_attributes`** (`before_validation on: :create`): reads `raw["data"]`. Tests that intentionally leave `raw` nil (to exercise the `raw` presence validation) must stub `setup_attributes` on the instance via `define_singleton_method`.
- **Mocha is NOT available** in this repo — `.stubs` raises `NoMethodError`. Use `define_singleton_method` + closure/local for state capture.
- **`MixinMessage#belongs_to :user, primary_key: :mixin_uuid`** — `user_id` column is the user's `mixin_uuid`. `msg.user` is nil for unknown UUIDs.
- **`User.pluck(:mixin_uuid)` includes nils**. For "no users with mixin_uuid" tests, `User.delete_all` is cleaner than `User.update_all(mixin_uuid: nil)`.
- **`User` validation requires `uid`**. When creating users in-test, set `uid: SecureRandom.hex(8)`.
- **`User#blocked_user_ids_relation`** returns users the receiver has BLOCKED (not who blocked them).
- **`before_validation on: :create` callbacks fire on every `valid?`** call. Tests that check validations on new records need `setup_attributes` stubbed to a no-op OR the API it calls stubbed (e.g. `QuillBot.api.create_user` for `MixinNetworkUser`).
- **`encrypts :pin` + no `active_record_encryption.primary_key` in test credentials** → reading `pin` raises `ActiveRecord::Encryption::Errors::Configuration`. Workaround: stub `update!`/`update` on the instance; set `encrypted_pin` directly via `update_column`.
- **`MixinBot::API.singleton_class.define_method(:new)` evaluates `self` as `MixinBot::API`** — `assert_equal` inside the override doesn't work. Capture kwargs in a closure and assert after. Restore with `define_singleton_method(:new, original_method)`.
- **`Noticed::Event.type` is an STI column** — fake class names raise `ActiveRecord::SubclassNotFound`. Use existing notifier class names.
- **Notifiers serialise params (incl. AR records)** — invoke `notify_subscribers` only on saved records (`Tagging.create!`, not `Tagging.new`).
- **`AdminNotificationService`** calls `QuillBot.api.plain_text(conversation_id:, data:)` (no `recipient_id`); `Announcement#deliver_as_text/post` passes `(conversation_id:, recipient_id:, data:)`. Stubs must make `recipient_id` optional.
- **Article `cannot_edit_frozen_attributes_once_published`** fires on first save when `published_at` is set in constructor. Build drafted, then `article.publish!` via AASM. Set `article.content = "<p>test</p>"` before `save!` for non-drafted authoring state.
- **`assert_enqueued_jobs N, only: JobClass`** is canonical. `enqueued_jobs.first[:job]` returns the Job class.
- **`safeoutputs create_pull_request` + `update_issue` body limit**: 10 KB hard cap. PR descriptions and Monthly Activity bodies must stay under 10 KB.
- **`safeoutputs create_pull_request` patch mode**: returns patch/bundle path. Files live at `/tmp/gh-aw/aw-test-assist-<branch>.bundle` / `.patch`. The PR itself is created at workflow completion — the response does NOT include a PR number. To reference the new PR in the Monthly Activity issue, use `branch + commit + run URL` (e.g. `[Run](https://github.com/.../actions/runs/<id>)`).
- **`enqueued_jobs.size` after `create!` includes the after_commit enqueue** for any `after_commit :some_job, on: :create` callbacks. Tests that also call the enqueuing method directly must assert `enqueued_jobs.size == 2` (or use `enqueued_jobs.last` to check the most recent), not `== 1`. Adding the after_commit enqueue to the count is expected.

## Backlog

- **LOW**: `NftCollection.icon_url` fallback — single-method model.
- **`Bonus` AASM still blocked by table-name bug** — would be HIGH if unblocked. Requires production-code change to `app/models/bonus.rb`.
- **LOW**: `article_snapshot`, `session`, `statistic`, `administrator` — thin model surfaces.
- All notifier backlog exhausted. NotificationSetting + Announcement + Tagging + UserAuthorization + MixinNetworkUser + MixinMessage done.

## Last Run

- 2026-07-07 — MixinMessage coverage re-done (21 / 52 assertions, branch `test-assist/mixin-message-coverage`, commit `2043b01`); PR via safeoutputs patch mode. The 2026-07-06 run was lost (patch stored, no PR created). Monthly Activity #1801 updated: MixinNetworkUser removed (merged as PR #1820), MixinMessage added.
- 2026-07-03 — MixinNetworkUser coverage PR **merged as #1820** (commit `875284b7`).
