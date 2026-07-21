# Quill Testing Guide

> **Purpose**: Consolidated reference for Quill-specific testing patterns, gotchas, and workarounds.
> **Maintained by**: [Test Improver](https://github.com/baizhiheizi/quill/actions/workflows/test-improver.yml)
> **Last updated**: 2026-07-21

---

## Commands

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI | `bin/ci` | setup, rubocop, lint-check, tests, db:seed:replant |
| All tests | `bin/rails test` | Minitest |
| Model tests | `SKIP_CSS_BUILD=1 bin/rails test test/models/` | Skips CSS build (~10s) |
| Single test | `bin/rails test test/models/foo_test.rb` | |
| Zeitwerk check | `bin/rails zeitwerk:check` | Must pass before PR |
| Ruby lint | `bin/rubocop` | |
| JS lint | `bun run lint-check` | Prettier on `app/javascript` |
| DB setup | `bin/rails db:prepare` | main + cable + queue databases |
| Benchmarks | `bin/benchmark` | See `test/benchmarks/README.md` |

---

## Test Support Utilities

| File | Purpose |
|------|---------|
| `test/support/quill_bot_stub.rb` | `with_quill_bot_stub` block helper — stubs `QuillBot.api` and restores automatically |
| `test/support/commerce_helpers.rb` | Shared helpers for payment/order tests |
| `test/support/notifier_helpers.rb` | Helpers for Noticed notifier tests |
| `test/support/integration_test_case.rb` | Base class for controller/integration tests |
| `test/test_helper.rb` `JobTestCase` | `stub_class_method` for safe class-method stubbing |

---

## Fixtures & Test Data

### Orders
- **Baseline `Order.completed` is 0**: `test/fixtures/orders.yml` has two unnamed orders (`one`, `two`) with `state: nil`. AASM initial state is `:paid`, **not** `completed`. Assert absolute counts, not deltas.

### User
- **`User` requires `uid`**: Set `uid: SecureRandom.hex(8)` for in-test user creation. The validation requires it; without it the record won't save.

### Articles
- **Heavy validations**: `validate_rich_text_content_presence?` fires when `state != "drafted"`. `cannot_edit_frozen_attributes_once_published` fires when `published_at` is present (even on new records — `asset_id_changed?` returns true).
- **Creating published articles**: Don't use `Article.create!(state: "published", ...)` — validators block it. Use:
  ```ruby
  article = Article.create!(state: :drafted, ...)
  article.content = "<p>test content</p>"
  article.publish!  # AASM event runs ensure_content_valid
  ```
- **Bypassing article validators**: `Article.new(...).save(validate: false)` skips all `before_validation` callbacks and validators. Useful for creating fixture-like records quickly.

---

## Database Constraints

### Unique Constraints
- **`idx_orders_buyer_item_type_unique`**: DB-level unique constraint on `(order_type, buyer_id, item_type, item_id)`. `save(validate: false)` skips Ruby uniqueness validators but **not the DB constraint**. Use a fresh `Article` (each `build_article` gets a new UUID) per order when the same buyer needs multiple orders.

### Table Name Mismatch
- **`Bonus` table_name bug**: `Bonus.table_name` resolves to `"bonus"` (Rails class-name inference) but `db/schema.rb` defines `"bonuses"`. `Bonus.create!` raises `PG::UndefinedTable`. Fix: add `self.table_name = "bonuses"` to `app/models/bonus.rb`.

### Encryption
- **`encrypts :pin` not configured in test**: `active_record_encryption.primary_key` is missing from `config/credentials/test.yml.enc`. Reading `pin` on a record raises a config error. Workaround: set `encrypted_pin` via `update_column` or stub `update!` on the instance.

---

## Callback Behavior

### `before_validation on: :create`
- **Fires on every `valid?` call**, not just `save!`. Any test that calls `.valid?` on a new record triggers these callbacks. Stub them (`define_singleton_method(:setup_attributes) {}` per-instance) if they reach external dependencies.
- **Does NOT fire under `save(validate: false)`**. This is the cleanest bypass for callback-heavy models:
  ```ruby
  Order.new(attr1: val1, attr2: val2).save(validate: false)
  ```
  The record persists without triggering `setup_attributes`, `generate_order!`, etc.

### `after_initialize :set_defaults`
- **Overrides constructor-supplied attributes**: `after_initialize set_defaults if: :new_record?` runs AFTER the constructor, so `NotificationSetting.new(user: u, webhook_url: "x")` gets `webhook_url == nil`.
- **Does NOT re-fire on update**: Only runs for new records. Use `update!` (not `.new(attrs)`) when testing update-only callbacks.

### `after_commit`
- **`after_commit :<job>, on: :create` adds to `enqueued_jobs.size`**. When a test both triggers a callback-based enqueue and directly enqueues a job, assert `size == 2` instead of `size == 1`.

### AASM
- **`Payment#create!` auto-transitions to `completed`**: `after_create :generate_order!` → `place_article_order!` → `complete!`. The default state for a freshly created Payment is `"completed"`, **not** the AASM initial `"paid"`.
- **Setting non-default Payment states**:
  1. Stub `generate_order!` on the instance before `save!`, then `update_columns(state:)`.
  2. Use a memo type that doesn't match `memo_correct?` (e.g., empty `t` key) so `generate_order!` early-returns.

---

## Stubbing & Mocking

### Mocha is NOT available
Use `define_singleton_method` with a closure instead of Mocha's `.stubs`:
```ruby
define_singleton_method(:method_name) { |*args| desired_return_value }
```

### `define_singleton_method` + `remove_method` is unsafe
Class-level `remove_method` leaves the class without the method if the test raises before the `ensure` block. **Always use `stub_class_method`** (from `JobTestCase` in `test/test_helper.rb`):
```ruby
stub_class_method(MixinNetworkSnapshot, :find_by) { |id: MockSnapshot.new(id) }
```
This restores the original `UnboundMethod` via `ensure`.

### `QuillBot` stubs
- **`QuillBot.api.client_id` returns `nil` in tests** unless wrapped in `with_quill_bot_stub`. Use the helper from `test/support/quill_bot_stub.rb`:
  ```ruby
  with_quill_bot_stub do
    # code that reaches QuillBot.api.client_id
  end
  ```
- **`QuillBot.define_singleton_method(:api) { ... }` evaluates under `QuillBot`**, not the test instance. The closure's `self` is `QuillBot`, so `@ivar` access reads `QuillBot`'s ivars. Capture in a local:
  ```ruby
  previous_api = @previous_api
  QuillBot.define_singleton_method(:api) { previous_api }
  ```

### `MixinBot::API` stubs
- **`MixinBot::API.singleton_class.define_method(:new)` evaluates `self` as `MixinBot::API`**. `assert_equal` raises inside the override. Capture kwargs in a closure (array/hash) and assert after the call.
- Restore with `MixinBot::API.define_singleton_method(:new, original_method)` — NOT `remove_method`.

### `belongs_to` associations
- **Association instances are fresh**: Stubbing on a fixture instance (`msg.user`) does **not** propagate to the association. The `belongs_to` association loads its own fresh instance. Stub on the association instance directly, not on the fixture.
- **`belongs_to` with custom key**: Same issue — class-level `define_method` on the model class is needed when the association uses a non-standard `primary_key`. Restore in `ensure`.

### `UserAuthorization#has_safe?` class-pollution bug in `transfer_test.rb`
`test/models/transfer_test.rb` lines 220–229 swaps `UserAuthorization#has_safe?` then uses `remove_method` in teardown. If the test raises before `ensure`, `UserAuthorization` is left without `has_safe?` for every later test in the process. Mitigated by `ORIGINAL_HAS_SAFE = UserAuthorization.instance_method(:has_safe?)` at file load. Don't replicate this pattern; use `stub_class_method` instead.

---

## Model-Specific Notes

### Article
- See "Fixtures & Test Data" above for creation patterns.
- `content_as_html` / `content_body` / `plain_text` / `migrated_content?` in `RichTextContent` concern delegate to `RichTextRenderService` or `MarkdownRenderService` depending on `migrated_content?`.

### ArticleSnapshot
- `store_accessor :raw, %w[title intro content digest]` — the four declared accessors are conveniences, not a schema. `raw["extra_field"]` round-trips fine.
- `before_validation :set_defaults, on: :create` populates raw from `article.as_json`. **Unconditionally overwrites** a pre-supplied `raw:` value.
- `fresh?` uses a fresh query, not a cached count — destroying a later snapshot correctly flips stale → fresh.
- `ArticleSnapshot#previous_signed_snapshot` calls `article.snapshots.signed`, but no `signed` scope or column exists. Either dead code or a missing scope.

### Collection
- `#tradable?`: Fennec-tradable check. Requires `fennec_trade_url` to be present.

### MixinMessage
- `setup_attributes` reads `raw["data"]` — stub per-instance when `raw` is nil.
- `belongs_to :user, primary_key: :mixin_uuid` — custom key association.
- `touch_proccessed_at` — misspelled in production (should be `processed`).
- `process_user_message` calls `QuillBot.api.unique_uuid` with no rescue.

### MixinNetworkUser
- `before_validation :setup_attributes, on: :create` calls `QuillBot.api.create_user`.
- `avatar` does `raw["avatar_url"]` without a nil-guard on `raw`. `raw: nil` raises `NoMethodError`.
- UUID uniqueness is DB-level, not model-level.
- `mixin_api` memoizes `MixinBot::API.new(...)`.

### NotificationSetting
- `DEFAULT_SETTING` is frozen. 19 keys: 6 categories × 3 channels + `webhook_url`.
- `set_defaults` overrides constructor attributes (see Callback Behavior).
- `article_bought_daily_times` is an exposed store accessor with no default value.

### Order
- `setup_attributes` requires a real `Payment.amount`. Bypass with `save(validate: false)`.

### Splitter
- `collect_assets` wraps in `with_advisory_lock("splitter:#{id}:collect")`. Short-circuits when lock is not acquired.
- Zero-balance assets (`"0"`, `"0.0"`, `"0.00000000"`) are skipped.
- Existing unprocessed transfer for same `(wallet_id, asset_id)` blocks creation.
- `QuillBot.api.client_id` returns nil without `with_quill_bot_stub` → silently produces zero transfers.
- **`collect_assets` has zero callers in the codebase** — either dead code or the dispatcher is missing.

### Tagging
- `notify_subscribers` is on `after_create_commit`. The tagging must be saved before invoking manually (notifier serialises params).
- `Tagging#notify_subscribers` uses `admin_notification_inboxes` join + `blocked_by` filter via `User#blocked_user_ids_relation` (users the tagger has blocked).

### Transfer
- `process!` source dispatch: `Payment` → `payment.refund! if payment.may_refund?` (needs `:paid`); `Bonus` → `bonus.complete! if bonus.may_complete?`.
- `Transfer#unprocessed` scope excludes stale transfers (`where(processed_at: nil).where(stale_at: nil)`).

### User
- `User#blocked_user_ids_relation` returns users **the receiver has blocked**, not who blocked them.
  `User.where.not(id: author.blocked_user_ids_relation)` → filters out users the author has blocked.

### UserAuthorization
- `has_safe?` short-circuits on truthy `raw["has_safe"]` (no refresh). Falls through to `refresh!` when absent/false.
- `refresh!` early-returns for `:twitter` provider (no API call, no DB write).
- `uid` uniqueness is scoped to `provider` (same uid under different provider is valid).

### DailyStatistic
- `paid_users_count` uses `created_at: ...date.end_of_day` (open-start range). Counts every buyer who's ever had a completed order up to the day. `new_payers_count` uses bounded `date.beginning_of_day...date.end_of_day`. They diverge when a buyer has orders older than today.

---

## Noticed / Notifications

- **`Noticed::Event.type` is an STI column**. Use a real notifier class name (e.g., `TransferProcessedNotifier`) in tests. Fake names raise `ActiveRecord::SubclassNotFound`.
- **`noticed_notifications` does NOT denormalise `record`**. To count notifications:
  ```ruby
  Noticed::Notification.joins(:event)
    .where(noticed_events: { record_type: "Tagging", record_id: id })
  ```

## Controller/Integration Tests

- **`IntegrationTestCase`** is the right base class.
- **API controller pattern**: `get :filter, as: :json` + `assert_equal(expected, response.parsed_body)`. No auth header needed for test.
- **`APIController` already handles JSON rendering** — `as: :json` in the request, `response.parsed_body` in the assertion.

---

## Untested Areas (for Future Runs)

These areas have been identified as candidates but not yet addressed:

### Model Concerns
- **`AdvisoryLockable`** (`app/models/concerns/advisory_lockable.rb`) — PostgreSQL `pg_try_advisory_lock` / `pg_advisory_unlock` pattern with SHA256-based lock IDs.
- **`RichTextContent`** (`app/models/concerns/rich_text_content.rb`) — `content_as_html`, `content_body`, `plain_text`, `migrated_content?` branching logic.

### Controller Concerns
- **`Localizable`** (`app/controllers/concerns/localizable.rb`) — Accept-Language header parsing with quality-value sorting.
- **`RenderingHelper`** (`app/controllers/concerns/rendering_helper.rb`) — 404 page renderer (trivial, 3 LOC).
- **`UserFieldPreloads`** (`app/controllers/concerns/user_field_preloads.rb`) — preload helper.
- **`API::RenderingHelper`** (`app/controllers/concerns/api/rendering_helper.rb`) — API rendering.

### Dashboard Controllers (17 untested of 25)
Larger/more critical controllers with no tests:
- `dashboard/payments_controller.rb` (20 LOC)
- `dashboard/transfers_controller.rb` (40 LOC)
- `dashboard/collections_controller.rb` (64 LOC)
- `dashboard/articles_controller.rb` (33 LOC)
- `dashboard/profile_settings_controller.rb` (41 LOC)
- `dashboard/block_users_controller.rb` (31 LOC)
- `dashboard/notification_settings_controller.rb` (29 LOC)
