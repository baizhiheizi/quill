# Quill Testing Guide

Maintained by [Test Improver](../.github/workflows/test-improver.md).

---

## Commands

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI | `bin/ci` | setup, rubocop, lint-check, tests, db:seed:replant |
| All tests | `bin/rails test` | Minitest |
| Coverage | `COVERAGE=1 bin/rails test` | SimpleCov report in `coverage/index.html` |
| Model tests | `bin/rails test test/models/` | Targets model tests; the test command does not build CSS. |
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
- **`Order.completed` baseline is 0**: `test/fixtures/orders.yml` has two unnamed orders (`one`, `two`) with `state: nil`. AASM initial state is `:paid`, **not** `completed`. Assert absolute counts, not deltas.

### User
- **`User` requires `uid`**: set `uid: SecureRandom.hex(8)` when creating users in tests — the validation blocks save otherwise.

### Articles
- **Heavy validations**: `validate_rich_text_content_presence?` fires when `state != "drafted"`; `cannot_edit_frozen_attributes_once_published` fires when `published_at` is present (even on new records — `asset_id_changed?` returns true).
- **Creating published articles**: don't use `Article.create!(state: "published", ...)` — validators block it. Instead:
  ```ruby
  article = Article.create!(state: :drafted, ...)
  article.content = "<p>test content</p>"
  article.publish!  # AASM event runs ensure_content_valid
  ```
- **Bypassing article validators**: `Article.new(...).save(validate: false)` skips `before_validation` callbacks and validators — useful for fixture-like records.

---

## Database Constraints

### Unique Constraints
- **`idx_orders_buyer_item_type_unique`**: DB-level unique constraint on `(order_type, buyer_id, item_type, item_id)`. `save(validate: false)` skips Ruby validators but **not the DB constraint** — use a fresh `Article` (each `build_article` gets a new UUID) per order when the same buyer needs multiple orders.

### Table Name Mismatch
- **`Bonus` table_name bug**: `Bonus.table_name` resolves to `"bonus"` (Rails class-name inference) but `db/schema.rb` defines `"bonuses"`. `Bonus.create!` raises `PG::UndefinedTable`. Fix: add `self.table_name = "bonuses"` to `app/models/bonus.rb`.

### Encryption
- **`encrypts :pin` not configured in test**: `active_record_encryption.primary_key` is missing from `config/credentials/test.yml.enc`, so reading `pin` raises a config error. Workaround: set `encrypted_pin` via `update_column` or stub `update!` on the instance.

---

## Callback Behavior

### `before_validation on: :create`
- **Fires on every `valid?` call**, not just `save!`. Any test that calls `.valid?` on a new record triggers these callbacks. Stub them (`define_singleton_method(:setup_attributes) {}` per-instance) if they reach external dependencies — `save(validate: false)` is the cleanest bypass for callback-heavy models:
  ```ruby
  Order.new(attr1: val1, attr2: val2).save(validate: false)
  ```

### `after_initialize :set_defaults`
- Runs AFTER the constructor on new records and overrides constructor-supplied attributes — `NotificationSetting.new(user: u, webhook_url: "x")` ends up with `webhook_url == nil`. Use `update!` (not `.new(attrs)`) when testing update-only paths.

### `after_commit`
- **`after_commit :<job>, on: :create` adds to `enqueued_jobs.size`**. When a test both triggers a callback-based enqueue and directly enqueues a job, assert `size == 2` instead of `size == 1`.

### AASM
- **`Payment#create!` auto-transitions to `completed`**: `after_create :generate_order!` → `place_article_order!` → `complete!`. A freshly created Payment's state is `"completed"`, **not** the AASM initial `"paid"`.
- **Setting non-default Payment states**: either stub `generate_order!` on the instance before `save!` and `update_columns(state:)`, or use a memo type that doesn't match `memo_correct?` (e.g., empty `t` key) so `generate_order!` early-returns.

---

## Stubbing & Mocking

### Mocha is NOT available
Use `define_singleton_method` with a closure instead of Mocha's `.stubs`:
```ruby
define_singleton_method(:method_name) { |*args| desired_return_value }
```

### `QuillBot` stubs
- `QuillBot.api.client_id` returns `nil` in tests unless wrapped in `with_quill_bot_stub` (`test/support/quill_bot_stub.rb`):
  ```ruby
  with_quill_bot_stub do
    # code that reaches QuillBot.api.client_id
  end
  ```
- `QuillBot.define_singleton_method(:api) { ... }` evaluates under `QuillBot` (the closure's `self`), so `@ivar` reads `QuillBot`'s ivars. Capture in a local:
  ```ruby
  previous_api = @previous_api
  QuillBot.define_singleton_method(:api) { previous_api }
  ```

### `MixinBot::API` stubs
- `MixinBot::API.singleton_class.define_method(:new)` evaluates `self` as `MixinBot::API`, so `assert_equal` raises inside the override. Capture kwargs in a closure and assert after the call. Restore with `MixinBot::API.define_singleton_method(:new, original_method)` — NOT `remove_method`.

### `belongs_to` associations
- **Association instances are fresh** — stubbing on a fixture instance (`msg.user`) does **not** propagate to the association. Stub the association instance directly, not the fixture.
- **`belongs_to` with custom key**: same issue — class-level `define_method` on the model is needed when the association uses a non-standard `primary_key`. Restore in `ensure`.

### Class-level stubbing and teardown
Class-level `remove_method` can leave the class without the method when cleanup is omitted or interrupted (e.g., `test/models/concerns/orders/distributable_test.rb:85-96`). Use `stub_class_method` from `JobTestCase` (in `test/test_helper.rb`) for class methods — it restores the original via `ensure`:
```ruby
stub_class_method(MixinNetworkSnapshot, :find_by, ->(**) { nil }) do
  MixinNetworkSnapshot.find_by(id: 1)
end
```
For instance methods such as `UserAuthorization#has_safe?`, stub the specific object instead of changing the model class.

---

## Model-Specific Notes

### Article
- `content_as_html` / `content_body` / `plain_text` branch on `migrated_content?` (`content.body.present?`): migrated content uses `RichTextRenderService` / `content.body.to_html` / `content.to_plain_text`; legacy content uses `MarkdownRenderService` (or the raw markdown string for `plain_text`). See "Fixtures & Test Data" above for creation patterns.

### ArticleSnapshot
- `store_accessor :raw, %w[title intro content digest]` — conveniences, not a schema; `raw["extra_field"]` round-trips fine.
- `before_validation :set_defaults, on: :create` populates raw from `article.as_json` and **unconditionally overwrites** a pre-supplied `raw:` value.
- `fresh?` re-queries — destroying a later snapshot correctly flips stale → fresh.
- `#previous_signed_snapshot` calls `article.snapshots.signed`, but no `signed` scope or column exists (dead code or missing scope).

### Collection
- `#tradable?`: Fennec-tradable check. Requires `fennec_trade_url` to be present.

### MixinMessage
- `setup_attributes` reads `raw["data"]` — stub per-instance when `raw` is nil.
- `belongs_to :user, primary_key: :mixin_uuid` (custom key association).
- `touch_proccessed_at` is misspelled in production (it should be `touch_processed_at`).
- `process_user_message` returns unless a user exists and the conversation ID matches `QuillBot.api.unique_uuid(user_id)`; no error rescue.

### MixinNetworkUser
- `before_validation :setup_attributes, on: :create` calls `QuillBot.api.create_user`.
- `avatar` reads `raw["avatar_url"]` without a nil-guard — `raw: nil` raises `NoMethodError`.
- UUID uniqueness is DB-level, not model-level. `mixin_api` memoizes `MixinBot::API.new(...)`.

### NotificationSetting
- `DEFAULT_SETTING` is frozen — 19 keys: 6 categories × 3 channels + `webhook_url`. `set_defaults` overrides constructor attributes (see Callback Behavior).
- `article_bought_daily_times` is an exposed store accessor with no default value.

### Order
- `setup_attributes` requires a real `Payment.amount` — bypass with `save(validate: false)`.

### Splitter
- `collect_assets` wraps in `with_advisory_lock("splitter:#{id}:collect")` and short-circuits when the lock is not acquired. Zero-balance assets (`"0"`, `"0.0"`, `"0.00000000"`) are skipped, and existing unprocessed transfers for the same `(wallet_id, asset_id)` block creation. `QuillBot.api.client_id` returns nil without `with_quill_bot_stub`, so missing the stub silently produces zero transfers.
- **`collect_assets` has zero callers in the codebase** — either dead code or the dispatcher is missing.

### Tagging
- `notify_subscribers` is on `after_create_commit` — save the tagging before invoking manually (notifier serialises params).
- `#notify_subscribers` selects subscribers with `Action.where(target_type: "Tag", target_id: tag.id, action_type: "subscribe")` and excludes IDs in `article.author.blocked_user_ids_relation`.

### Transfer
- `process!` dispatches by source: `Payment` → `source.refund_with_observability!`; `Bonus` → `source.complete! if source.may_complete?`. `Transfer#unprocessed` excludes stale rows (`where(processed_at: nil).where(stale_at: nil)`).

### User
- `User#blocked_user_ids_relation` returns users the receiver has blocked — `User.where.not(id: author.blocked_user_ids_relation)` filters out users the author has blocked, not users who blocked them.

### UserAuthorization
- `has_safe?` short-circuits on truthy `raw["has_safe"]`; falls through to `refresh!` when absent/false. `refresh!` early-returns for `:twitter` (no API call, no DB write). `uid` uniqueness is scoped to `provider` — same uid under different providers is valid.

### DailyStatistic
- `paid_users_count` uses an open-start range (`created_at: ...date.end_of_day`) — counts every buyer who's ever had a completed order up to the day. `new_payers_count` uses bounded `date.beginning_of_day...date.end_of_day`. They diverge when a buyer has orders older than today.

---

## Noticed / Notifications

- **`Noticed::Event.type` is an STI column** — use a real notifier class name (e.g., `TransferProcessedNotifier`) in tests. Fake names raise `ActiveRecord::SubclassNotFound`.
- **`noticed_notifications` does NOT denormalise `record`** — to count notifications:
  ```ruby
  Noticed::Notification.joins(:event)
    .where(noticed_events: { record_type: "Tagging", record_id: id })
  ```

## Controller/Integration Tests

- **`IntegrationTestCase`** is the right base class.
- **API controller pattern**: `get :filter, as: :json` + `assert_equal(expected, response.parsed_body)`. No auth header needed for test; `APIController` already handles JSON rendering.

---

## Untested Areas (for Future Runs)

### Model Concerns
- **`AdvisoryLockable`** (`app/models/concerns/advisory_lockable.rb`) — PostgreSQL `pg_try_advisory_lock` / `pg_advisory_unlock` pattern with SHA256-based lock IDs.
- **`RichTextContent`** (`app/models/concerns/rich_text_content.rb`) — `content_as_html`, `content_body`, `plain_text`, `migrated_content?` branching logic.

### Controller Concerns
- **`Localizable`** (`app/controllers/concerns/localizable.rb`) — Accept-Language header parsing with quality-value sorting.
- **`RenderingHelper`** (`app/controllers/concerns/rendering_helper.rb`) — 404 page renderer (trivial, 3 LOC).
- **`UserFieldPreloads`** (`app/controllers/concerns/user_field_preloads.rb`) — preload helper.
- **`API::RenderingHelper`** (`app/controllers/concerns/api/rendering_helper.rb`) — API rendering.

### Dashboard Controllers (17 untested of 25)
Larger controllers with no tests:
- `dashboard/payments_controller.rb` (20 LOC)
- `dashboard/transfers_controller.rb` (40 LOC)
- `dashboard/collections_controller.rb` (64 LOC)
- `dashboard/articles_controller.rb` (33 LOC)
- `dashboard/profile_settings_controller.rb` (41 LOC)
- `dashboard/block_users_controller.rb` (31 LOC)
- `dashboard/notification_settings_controller.rb` (29 LOC)
