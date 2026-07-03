# Test Improver Memory

- [Run notes 2026-07-03](2026-07-03-notes.md) — MixinNetworkUser coverage (32 / 76, commit `f89703f`)
- [Run notes 2026-07-02](2026-07-02-notes.md) — UserAuthorization coverage (11 / 35, commit `6b70069`)
- [Run notes 2026-07-01](2026-07-01-notes.md) — Tagging callbacks + notify_subscribers SQL subquery (16 / 43, commit `728a8a9`)

## Discovered Commands

- Tests: `bin/rails test` (Minitest 6.0.6), `bin/rails test:system` (Capybara)
- Lint: `bin/rubocop`, `bun run lint-check` (Prettier)
- Zeitwerk: `bin/rails zeitwerk:check`
- DB: `bin/rails db:prepare` (main + cable + queue); `RAILS_ENV=test bin/rails db:migrate` if test DB drifts
- Full CI: `bin/ci`
- Coverage: no SimpleCov/Codecov in CI

## Testing Notes (brief)

- **`QuillBot.define_singleton_method(:api) { ... }` block evaluates under `QuillBot`, not the test instance** — capture the previous API into a *local* before re-defining; the restore block otherwise reads `QuillBot.@previous_quill_bot_api` (always nil). Affects any `define_singleton_method` teardown restoration. See user_authorization_test.rb setup/teardown.
- **`test/models/transfer_test.rb` lines 220-229** swap `UserAuthorization#has_safe?` at runtime and `remove_method` it in `ensure` instead of restoring the original — leaves the class without the method for any later test in the same process. Mitigation in user_authorization_test.rb: capture `instance_method(:has_safe?)` at file load and re-define in setup.
- **`belongs_to` instances are fresh** — singleton method overrides on fixture instances don't propagate. Use class-level `define_method(...)` with `ensure` restore.
- **`Bonus` AASM still blocked**: `Bonus.table_name` returns `"bonus"` from Rails class-name inference (no `self.table_name =` override in the model file), but `db/schema.rb` defines `"bonuses"`. Real `Bonus.create!` raises `PG::UndefinedTable`.
- **Transfer.process_safe_transfer!**: `check!` first (Mixin `safe_transaction`); on success returns without `create_safe_transfer`; on `MixinBot::NotFoundError` proceeds to `create_safe_transfer`.
- **Transfer.process! source dispatch**: Payment → `payment.refund! if payment.may_refund?`; Bonus → `bonus.complete! if bonus.may_complete?`.
- **Currency#set_defaults callback**: overwrites `raw` from `QuillBot.api.asset(asset_id)`. Stub for second currency.
- **SwapOrder**: `user_id` → `User#mixin_uuid`. `after_create` → `PandoLake.api.actions(...)` — stub inline.
- **PreOrder**: AASM `drafted → paid/expired`. `pay!` after_commit `broadcast_to_views`. `setup_attributes` auto-fills follow_id/trace_id/memo (base64)/payee_id/asset_id.
- **`safeoutputs create_pull_request` body limit**: 10 KB hard cap. PR descriptions and Monthly Activity bodies must stay under 10 KB.
- **`safeoutputs create_pull_request` patch mode**: returns patch/bundle path; PRs may not appear in `list_pull_requests` until the bridge pushes. Bundle/patch files live at `/tmp/gh-aw/aw-test-assist-<branch>.bundle` / `.patch`.
- **`assert_enqueued_jobs N, only: JobClass`** is canonical. `enqueued_jobs.first[:job]` returns the Job class, not a string.
- **Article `cannot_edit_frozen_attributes_once_published`**: fires on first save when `published_at` is set in the constructor. Build drafted, then `article.publish!` via AASM. Set `article.content = "<p>test</p>"` before `save!` for non-drafted authoring state.
- **`Noticed::Event.type` is an STI column** — fake class names raise `ActiveRecord::SubclassNotFound`. Use existing notifier class names in tests.
- **Notifiers serialise params (incl. AR records)** — invoke `notify_subscribers` only on saved records (`Tagging.create!`, not `Tagging.new`).
- **`User.pluck(:mixin_uuid)` includes nils**. For "no users with mixin_uuid" tests, `User.delete_all` is cleaner than `User.update_all(mixin_uuid: nil)`.
- **`AdminNotificationService`** calls `QuillBot.api.plain_text(conversation_id:, data:)` (no recipient_id). `Announcement#deliver_as_text/post` calls with `(conversation_id:, recipient_id:, data:)`. Stubs must make `recipient_id` optional.
- **`User` validation requires `uid`** (presence). When creating users in-test, set `uid: SecureRandom.hex(8)`.
- **`User#blocked_user_ids_relation`** returns users the receiver has BLOCKED, not users who blocked them. `User.where.not(id: author.blocked_user_ids_relation)` excludes users the AUTHOR has blocked.
- **`before_validation on: :create` callbacks fire on every `valid?`**, not just `save!`. Tests that check validations on new records must stub the callback to a no-op (`define_singleton_method(:setup_attributes) { }`) or stub the API the callback calls.
- **`encrypts :pin` + no `active_record_encryption.primary_key` in test credentials** → reading `pin` raises `ActiveRecord::Encryption::Errors::Configuration`. Workaround: stub `update!` / `update` on the instance to capture args + return true; set `encrypted_pin` directly via `update_column`.
- **`MixinBot::API.singleton_class.define_method(:new)` evaluates `self` as `MixinBot::API`** — `assert_equal` doesn't work inside the override. Capture kwargs in a closure and assert after. Restore with `MixinBot::API.define_singleton_method(:new, original_method)`.

## Backlog

- **LOW**: `NftCollection.icon_url` fallback — single-method model.
- **`Bonus` AASM still blocked by table-name bug** — would be HIGH if unblocked.
- All notifier backlog exhausted. NotificationSetting + Announcement + Tagging callbacks + UserAuthorization + MixinNetworkUser done.

## Last Run

- 2026-07-03 — MixinNetworkUser coverage added (32 / 76 assertions, branch `test-assist/mixin-network-user-coverage`, commit `f89703f`); PR via safeoutputs patch mode.
