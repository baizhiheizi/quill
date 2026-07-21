# Test Improver Memory

- [Run notes 2026-07-21](2026-07-21-notes.md) — Testing guide created (PR) + new opportunities identified
- [Run notes 2026-07-20](2026-07-20-notes.md) — Infra proposal + Monthly Activity update

## Discovered Commands

- Tests: `bin/rails test` (Minitest 6.0.6). CSS bypass: `SKIP_CSS_BUILD=1 bin/rails test:models`.
- Lint: `bin/rubocop`, `bun run lint-check`. Zeitwerk: `bin/rails zeitwerk:check`.
- DB: `bin/rails db:prepare` (main + cable + queue). CI: `bin/ci`.

## Testing Gotchas

- **QuillBot stubs**: Use `with_quill_bot_stub` (`test/support/quill_bot_stub.rb`). `QuillBot.api.client_id` is nil in tests without it.
- **belongs_to instances are fresh**: Stub on the actual association instance (`msg.user`), not the fixture.
- **`Bonus` AASM blocked**: `self.table_name = "bonus"` vs migration `"bonuses"` → PG::UndefinedTable on create.
- **`before_validation` + `save(validate: false)`**: `before_validation on: :create` does NOT fire with `validate: false`. Use this to bypass heavy callback chains (Order#setup_attributes, Article validators).
- **`before_validation on: :create` fires on every `valid?` call**: Tests checking validations on new records need `setup_attributes` stubbed.
- **`idx_orders_buyer_item_type_unique`**: DB-level unique constraint on `(order_type, buyer_id, item_type, item_id)`. Fresh Article per order to bypass.
- **Fixture `Order.completed` baseline is 0**: orders.yml `one`/`two` have `state: nil` → AASM initial = `:paid`, not `completed`.
- **`MixinMessage#setup_attributes` `before_validation on: :create`**: reads `raw["data"]`. Stub per-instance when `raw` is nil.
- **Mocha NOT available**: Use `define_singleton_method` + closure.
- **`define_singleton_method` + `remove_method` is unsafe**: Use `stub_class_method` (`JobTestCase` in test_helper.rb) which restores original UnboundMethod via `ensure`.
- **`encrypts :pin`**: No encryption key in test → reading `pin` raises config error. Set via `update_column(:encrypted_pin, ...)`.
- **`Noticed::Event.type` is STI**: Fake class names raise `SubclassNotFound`. Use existing notifier classes.
- **`Payment#create!` auto-transitions to `completed`**: AASM initial = `:paid` but a successful `Payment.create!` always ends at `:completed`. Stub `generate_order!` for other states.
- **Published articles need content**: `validate_rich_text_content_presence?` fires when `state != "drafted"`. Pattern: create drafted, set content, then `publish!`.
- **`User` validation requires `uid`**: Set `uid: SecureRandom.hex(8)` for in-test user creation.
- **`User#blocked_user_ids_relation`**: Returns users the receiver BLOCKED, not who blocked them.
- **`MixinBot::API.singleton_class.define_method(:new)` evaluates self as `MixinBot::API`**: Capture kwargs in a closure.
- **`enqueued_jobs.size` includes after_commit**: `after_commit :<job>, on: :create` adds to enqueued count. Assert `size == 2` when both callback and direct call enqueue.
- **safeoutputs body limit**: 10 KB for PR descriptions and issue bodies.

## Backlog

**Model coverage substantially complete** (22 non-trivial models). **Testing guide created** (PR open). Pivot to controller/infrastructure.

Pending items:
- **Bonus AASM** — blocked by table-name bug
- **ArticleSnapshot#previous_signed_snapshot** — broken code (undefined `signed` scope)
- **Splitter#collect_assets** — zero callers (dead or missing dispatcher)
- **NftCollection / mixin_pre_order / administrator / session** — thin surfaces, LOW
- **SimpleCov proposal** (issue #1934) — awaiting maintainer feedback
- **Dashboard controller coverage** — 17 untested controllers (collections, transfers, payments, articles+)
- **Concern coverage** — AdvisoryLockable, RichTextContent, Localizable (all untested)
- **Controller concern coverage** — UserFieldPreloads, RenderingHelper

## Last Run

2026-07-21 — Testing guide created (PR), new controller/concern opportunities identified. Monthly Activity updated.
