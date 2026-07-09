# Test Improver Memory

- [Run notes 2026-07-09](2026-07-09-notes.md) — API::ValidUsersController#filter coverage (15 / 41, commit `74bc86c`); Payment auto-completes gotcha
- [Run notes 2026-07-07](2026-07-07-notes.md) — MixinMessage coverage re-run (21 / 52, commit `2043b01`)

## Discovered Commands

- Tests: `bin/rails test` (Minitest 6.0.6), `bin/rails test:system` (Capybara). `SKIP_CSS_BUILD=1 bin/rails test:models` bypasses CSS bundling when Bun unavailable.
- Lint: `bin/rubocop`, `bun run lint-check` (Prettier). Zeitwerk: `bin/rails zeitwerk:check`.
- DB: `bin/rails db:prepare` (main + cable + queue). Full CI: `bin/ci`. Coverage: no SimpleCov/Codecov in CI.

## Testing Notes

- **`QuillBot.define_singleton_method(:api) { ... }` block evaluates under `QuillBot`, not the test instance.** Use `with_quill_bot_stub` (`test/support/quill_bot_stub.rb`).
- **`belongs_to` instances are fresh** — singleton method overrides on fixture instances (e.g. `users(:author).define_singleton_method(:notify_for_login) { ... }`) don't propagate. Stub on the actual association instance (e.g. `msg.user.define_singleton_method(...)`).
- **`Bonus` AASM still blocked**: `Bonus.table_name` returns `"bonus"` (Rails class-name inference), but `db/schema.rb` defines `"bonuses"`. PG::UndefinedTable on `Bonus.create!`.
- **`MixinMessage#setup_attributes`** (`before_validation on: :create`): reads `raw["data"]`. Tests that intentionally leave `raw` nil must stub `setup_attributes` on the instance via `define_singleton_method`.
- **Mocha is NOT available** — `.stubs` raises `NoMethodError`. Use `define_singleton_method` + closure/local for state capture.
- **`User` validation requires `uid`**. When creating users in-test, set `uid: SecureRandom.hex(8)`.
- **`User#blocked_user_ids_relation`** returns users the receiver has BLOCKED (not who blocked them).
- **`before_validation on: :create` callbacks fire on every `valid?`** call. Tests that check validations on new records need `setup_attributes` stubbed to a no-op.
- **`encrypts :pin` + no `active_record_encryption.primary_key` in test credentials** → reading `pin` raises `ActiveRecord::Encryption::Errors::Configuration`. Workaround: stub `update!`/`update` on the instance; set `encrypted_pin` directly via `update_column`.
- **`MixinBot::API.singleton_class.define_method(:new)` evaluates `self` as `MixinBot::API`** — `assert_equal` inside the override doesn't work. Capture kwargs in a closure.
- **`Noticed::Event.type` is an STI column** — fake class names raise `ActiveRecord::SubclassNotFound`. Use existing notifier class names.
- **Article `cannot_edit_frozen_attributes_once_published`** fires on first save when `published_at` is set in constructor. Build drafted, then `article.publish!` via AASM. Set `article.content = "<p>test</p>"` before `save!`.
- **`assert_enqueued_jobs N, only: JobClass`** is canonical. `enqueued_jobs.first[:job]` returns the Job class.
- **`safeoutputs create_pull_request` + `update_issue` body limit**: 10 KB hard cap. PR descriptions and Monthly Activity bodies must stay under 10 KB.
- **`safeoutputs create_pull_request` patch mode**: returns patch/bundle path. The PR itself is created at workflow completion — to reference a new PR in the Monthly Activity issue, use `branch + commit + run URL`.
- **`enqueued_jobs.size` after `create!` includes the after_commit enqueue** for any `after_commit :<job>, on: :create` callbacks. Tests that also call the enqueuing method directly must assert `enqueued_jobs.size == 2`.
- **`Payment#create!` auto-transitions to `completed`** via `after_create :generate_order!` → `place_article_order!` → `complete!` (for `BUY` memos on real articles). The AASM initial state is `:paid` but a successful `Payment.create!` always ends at `:completed`. To create a payment in another state, stub `generate_order!` on the instance before `save!`, then `update_columns(state:)` to set the desired AASM value.
- **Published articles need a content body**: `validate_rich_text_content_presence?` returns true when `state != "drafted"`. Pattern: `Article.create!(state: "drafted", ...)` then `article.content = "..."` + `article.published_at = ...` + `article.publish!`.

## Backlog

- **LOW**: `NftCollection.icon_url` fallback — single-method model.
- **`Bonus` AASM still blocked by table-name bug** — would be HIGH if unblocked. Requires production-code change to `app/models/bonus.rb`.
- **LOW**: `article_snapshot`, `session`, `statistic`, `administrator` — thin model surfaces.
- All notifier backlog exhausted. NotificationSetting + Announcement + Tagging + UserAuthorization + MixinNetworkUser + MixinMessage done.

## Last Run

- 2026-07-09 — API::ValidUsersController#filter coverage (15 / 41, branch `test-assist/api-valid-users-controller`, commit `74bc86c`); PR via safeoutputs patch mode. Monthly Activity #1801 updated.
- 2026-07-07 — MixinMessage coverage re-done (21 / 52, branch `test-assist/mixin-message-coverage`, commit `2043b01`); PR via safeoutputs patch mode. Monthly Activity #1801 updated.
- 2026-07-03 — MixinNetworkUser coverage PR **merged as #1820** (commit `875284b7`).
