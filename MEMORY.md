# Test Improver Memory

- [Run notes 2026-07-17](2026-07-17-notes.md) — DailyStatistic model (22 / 63, commit `d1f7c8f`); flagged `paid_users_count` uses open-start range that diverges from `new_payers_count`
- [Run notes 2026-07-16](2026-07-16-notes.md) — Splitter model (10 / 24, commit `b3d4aba`); flagged `collect_assets` has zero callers in app/lib/jobs; QuillBot.api.client_id silently nil in tests without `with_quill_bot_stub`. **Merged as PR #1916 by an-lee 2026-07-16 10:06:48 UTC.**
- [Run notes 2026-07-15](2026-07-15-notes.md) — ArticleSnapshot model (17 / 39, commit `851ab77`); flagged `previous_signed_snapshot` undefined `signed` scope. **Merged as PR #1910 by an-lee 2026-07-16 10:07:03 UTC.**
- [Run notes 2026-07-14](2026-07-14-notes.md) — MixinNetworkSnapshots::ProcessJob + MonitorJob (commit `e44b4a1`); fixed `remove_method` class-pollution bug. **Merged as PR #1893 by an-lee 2026-07-15.**
- [Run notes 2026-07-09](2026-07-09-notes.md) — API::ValidUsersController#filter coverage (15 / 41, commit `74bc86c`); Payment auto-completes gotcha. **Merged as PR #1873 by an-lee 2026-07-09.**
- [Run notes 2026-07-07](2026-07-07-notes.md) — MixinMessage coverage re-run (21 / 52, commit `2043b01`). **Merged as PR #1845 by an-lee 2026-07-07.**

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
- **`Order#setup_attributes` requires a real `Payment.amount`**. Bypass cleanly with `Order.new(...).save(validate: false)` — `before_validation` callbacks DO NOT fire when `validate: false`. Use this pattern when constructing orders for non-distribute path tests.
- **`Article` validations are heavyweight**: `validate_rich_text_content_presence?` (only skipped if `state == "drafted"`), `intro` presence, and `cannot_edit_frozen_attributes_once_published` (fires when `published_at` is present, even on new records — `asset_id_changed?` returns true on new rows). `Article.new(...).save(validate: false)` bypasses all.
- **`idx_orders_buyer_item_type_unique` is a DB-level unique constraint on `(order_type, buyer_id, item_type, item_id)`**. `save(validate: false)` skips the Ruby uniqueness validator but the DB still enforces it. To create multiple orders for the same buyer+item_type+order_type tuple, give each order a freshly-created Article (each gets a fresh UUID).
- **`before_validation` does NOT fire under `save(validate: false)`** — confirmed by direct testing. Use this to construct records whose `before_validation on: :create` callbacks would otherwise raise.
- **Fixture `Order.completed` baseline is 0**: `test/fixtures/orders.yml` `one`/`two` have `state: nil` → AASM initial = `:paid`, NOT in `Order.completed`. Assert absolute counts in tests that build completed orders, not delta-from-fixtures.
- **`User#blocked_user_ids_relation`** returns users the receiver has BLOCKED (not who blocked them).
- **`before_validation on: :create` callbacks fire on every `valid?`** call. Tests that check validations on new records need `setup_attributes` stubbed to a no-op.
- **`encrypts :pin` + no `active_record_encryption.primary_key` in test credentials** → reading `pin` raises `ActiveRecord::Encryption::Errors::Configuration`. Workaround: stub `update!`/`update` on the instance; set `encrypted_pin` directly via `update_column`.
- **`MixinBot::API.singleton_class.define_method(:new)` evaluates `self` as `MixinBot::API`** — `assert_equal` inside the override doesn't work. Capture kwargs in a closure.
- **`Noticed::Event.type` is an STI column** — fake class names raise `ActiveRecord::SubclassNotFound`. Use existing notifier class names.
- **Article `cannot_edit_frozen_attributes_once_published`** fires on first save when `published_at` is set in constructor. Build drafted, then `article.publish!` via AASM. Set `article.content = "<p>test</p>"` before `save!`.
- **`assert_enqueued_jobs N, only: JobClass`** is canonical. `enqueued_jobs.first[:job]` returns the Job class.
- **`safeoutputs create_pull_request` + `update_issue` body limit**: 10 KB hard cap. PR descriptions and Monthly Activity bodies must stay under 10 KB.
- **`safeoutputs create_pull_request` patch mode**: returns patch/bundle path. The PR itself is created at workflow completion — to reference a new PR in the Monthly Activity issue, use `branch + commit + run URL`.
- **`define_singleton_method` + `remove_method` teardown is unsafe** — a raise inside the test body leaves the class with the method uninstalled. Prefer `stub_class_method` (`test/test_helper.rb` → `JobTestCase`) which restores the original `UnboundMethod`. Applies to *any* class-method stub, not just jobs. Found in the wild: `test/jobs/mixin_network_snapshots/process_job_test.rb` (fixed 2026-07-14, this run) and `test/models/transfer_test.rb` lines 220-229 (`UserAuthorization#has_safe?`, noted 2026-07-02).
- **`enqueued_jobs.size` after `create!` includes the after_commit enqueue** for any `after_commit :<job>, on: :create` callbacks. Tests that also call the enqueuing method directly must assert `enqueued_jobs.size == 2`.
- **`Payment#create!` auto-transitions to `completed`** via `after_create :generate_order!` → `place_article_order!` → `complete!` (for `BUY` memos on real articles). The AASM initial state is `:paid` but a successful `Payment.create!` always ends at `:completed`. To create a payment in another state, stub `generate_order!` on the instance before `save!`, then `update_columns(state:)` to set the desired AASM value.
- **Published articles need a content body**: `validate_rich_text_content_presence?` returns true when `state != "drafted"`. Pattern: `Article.create!(state: "drafted", ...)` then `article.content = "..."` + `article.published_at = ...` + `article.publish!`.

## Backlog

- **LOW**: `NftCollection.icon_url` fallback — single-method model.
- **`Bonus` AASM still blocked by table-name bug** — would be HIGH if unblocked. Requires production-code change to `app/models/bonus.rb`.
- **LOW**: `mixin_pre_order.rb` (single validator), `administrator` (has_secure_password), `session` (uuid generator). `statistic` parent model — empty, NO value to test (DailyStatistic done, so STI child fully covered).
- **`ArticleSnapshot#previous_signed_snapshot`** is broken code (calls undefined `signed` scope). Flagged in 2026-07-15 PR description; needs a maintainer decision (add scope or remove method).
- **`Splitter#collect_assets` has zero callers in `app/`, `lib/`, or jobs** — flagged in 2026-07-16 PR description. Dead code or missing dispatcher.
- **`DailyStatistic#paid_users_count`** uses open-start range that diverges from `new_payers_count` — flagged in 2026-07-17 PR description; maintainer decision needed.
- **`app/libs/mixpay/client.rb`** — only 2 cases in `test/libs/mixpay/client_test.rb`. Mostly covered transitively via `mixpay_pre_order_test.rb`; only worth expanding if new gap emerges.
- All notifier backlog exhausted. NotificationSetting + Announcement + Tagging + UserAuthorization + MixinNetworkUser + MixinMessage done.
- All targeted model backlog exhausted: Splitter, ArticleSnapshot, MixinNetworkUser, MixinMessage, UserAuthorization, MixinNetworkSnapshot, Announcement, NotificationSetting, Tagging, Transfer, DailyStatistic.

## Last Run

- 2026-07-17 — DailyStatistic model (22 / 63, branch `test-assist/daily-statistic-model-coverage`, commit `d1f7c8f`); STI + 7-field store_accessor + default_scope + generate + regenerate + setup_attributes + 7-aggregate data_attributes. PR via safeoutputs. Monthly Activity #1801 updated.
- 2026-07-15 — ArticleSnapshot model (17 / 39, branch `test-assist/article-snapshot-coverage`, commit `851ab77`); `store_accessor` + `set_defaults` + `fresh?` + `delegate :author` + association chain. PR via safeoutputs patch mode.
- 2026-07-14 — MixinNetworkSnapshots::ProcessJob + MonitorJob (9 / 9, branch `test-assist/mixin-network-snapshots-jobs`, commit `e44b4a1`); fixed `remove_method` class-pollution bug in existing ProcessJob test. PR via safeoutputs patch mode. Monthly Activity #1801 updated.
- 2026-07-09 — API::ValidUsersController#filter coverage (15 / 41, branch `test-assist/api-valid-users-controller`, commit `74bc86c`); PR via safeoutputs patch mode. Monthly Activity #1801 updated.
- 2026-07-07 — MixinMessage coverage re-done (21 / 52, branch `test-assist/mixin-message-coverage`, commit `2043b01`); PR via safeoutputs patch mode. Monthly Activity #1801 updated.
- 2026-07-03 — MixinNetworkUser coverage PR **merged as #1820** (commit `875284b7`).
