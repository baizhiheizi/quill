# Test Improver Memory

- [Run notes 2026-06-29](2026-06-29-notes.md) — Announcement coverage (17 tests / 50 assertions, commit `5ed39f2`)

## Discovered Commands

- Tests: `bin/rails test` (Minitest), `bin/rails test:system` (Capybara)
- Lint: `bin/rubocop`, `bun run lint-check` (Prettier)
- Zeitwerk: `bin/rails zeitwerk:check`
- DB: `bin/rails db:prepare` (main + cable + queue); `RAILS_ENV=test bin/rails db:migrate` if test DB drifts
- Full CI: `bin/ci`
- Coverage: no SimpleCov/Codecov in CI

## Testing Notes (brief)

- **Framework**: Minitest (~> 6.0, locked to 6.0.6). `*_test.rb` naming, fixtures in `test/fixtures/`.
- **Helpers**: `CommerceHelpers`, `NotifierHelpers`, `QuillBotStub`. `perform_enqueued_jobs` available.
- **All PLAIN_TEXT notifiers** (`data == message`) now have direct coverage.
- **`belongs_to` instances are fresh** — singleton method overrides on fixture instances don't propagate. Use `UserAuthorization.define_method(...) { ... }` class-level with `ensure` restore.
- **`UserAuthorization#has_safe?`**: `raw["has_safe"].present?` returns false for BOTH nil AND false → falls through to `refresh!` (real API). Cannot test "false" branch via raw updates alone.
- **Transfer.process_safe_transfer!**: calls `check!` first (Mixin `safe_transaction`); on success returns without `create_safe_transfer`; on `MixinBot::NotFoundError` proceeds to `create_safe_transfer`.
- **Transfer.process! source dispatch**: Payment → `payment.refund! if payment.may_refund?`; Bonus → `bonus.complete! if bonus.may_complete?`.
- **Currency#set_defaults callback**: overwrites `raw` from `QuillBot.api.asset(asset_id)`. Stub for second currency.
- **SwapOrder**: `user_id` → `User#mixin_uuid`. `after_create` → `PandoLake.api.actions(...)` — stub inline.
- **PreOrder**: AASM `drafted → paid/expired`. `pay!` after_commit `broadcast_to_views`. `setup_attributes` auto-fills follow_id/trace_id/memo (base64)/payee_id/asset_id.
- **`safeoutputs create_pull_request` body limit**: 10 KB hard cap. Monthly Activity issue body must stay under 10 KB.
- **`safeoutputs create_pull_request`**: Returns patch/bundle path when bridge is in patch mode; PRs may not appear in `list_pull_requests` until bridge pushes.
- **`NotificationSetting.set_defaults` overrides constructor attrs on `.new()`** — `after_initialize` runs after constructor. Use `update!` (not `.new(attrs)`) to test `cast_string_value_to_boolean` callback behavior on a fresh record.
- **`NotificationSetting::DEFAULT_SETTING`**: frozen, 19 keys, `webhook_url: nil`, `web + mixin_bot: true`, `webhook: false`.
- **`Announcement#preview` returns `perform_later` result**, not the message hash. Capture API call payload in a closure; assert on what was passed to `QuillBot.api.plain_text/plain_post`.
- **`Announcement#deliver_as_text`** batches via `in_groups_of(100, false)`. **`deliver_as_post`** is one job per message (no batching). Pin both separately.
- **`User.pluck(:mixin_uuid)` includes nils**. For "no users with mixin_uuid" tests, `User.delete_all` is cleaner than `User.update_all(mixin_uuid: nil)`.
- **`AdminNotificationService`** calls `QuillBot.api.plain_text(conversation_id:, data:)` (no recipient_id). `Announcement#deliver_as_text/post` calls with `(conversation_id:, recipient_id:, data:)`. Stubs must make recipient_id optional.
- **`User` validation requires `uid`** (presence). When creating users in-test, set `uid: SecureRandom.hex(8)`.
- **`assert_enqueued_jobs N, only: JobClass`** is canonical. `enqueued_jobs.first[:job]` returns the Job class, not a string.

## Backlog

- **HIGH**: `Bonus` model AASM — blocked by `self.table_name = "bonus"` vs migration `"bonuses"` mismatch (pre-existing repo bug).
- **MEDIUM**: `Tagging` model — `notify_subscribers` callback with `ActionStore` query + `destroy_notifications` AASM-less callbacks.
- **MEDIUM**: `MixinNetworkUser` model — zero coverage, heavy stubs needed.
- **LOW**: `NftCollection.icon_url` fallback — tiny.
- **LOW**: `UserAuthorization` non-`has_safe?` methods (`mixin_api`).
- All notifier backlog exhausted. NotificationSetting + Announcement done.

## Last Run

- 2026-06-29 — Announcement coverage added (17 new tests / 50 assertions, branch `test-assist/announcement-coverage`, commit `5ed39f2`); PR via safeoutputs patch mode.