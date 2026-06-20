# Test Improver Memory

- [Run notes 2026-06-20](2026-06-20-notes.md) — SwapOrderSwappingNotifier coverage (9 tests, commit `1704bf6`)
- [Run notes 2026-06-19](2026-06-19-notes.md) — CollectionListedNotifier coverage (17 tests, commit `7e48232`)

## Discovered Commands

- Tests: `bin/rails test` (Minitest), `bin/rails test:system` (Capybara)
- Lint: `bin/rubocop`, `bun run lint-check` (Prettier)
- Zeitwerk: `bin/rails zeitwerk:check`
- DB: `bin/rails db:prepare` (main + cable + queue)
- Full CI: `bin/ci` (setup, rubocop, lint-check, tests, db:seed:replant)
- Build: `bun run build`, `bun run build:css`
- Coverage: no SimpleCov/Codecov in CI; measure via targeted `bin/rails test` runs

## Testing Notes

- **Framework**: Minitest (~> 6.0, locked to 6.0.6) + Capybara. Test location mirrors `app/`; `*_test.rb` naming.
- **Helpers**: `CommerceHelpers` (create_payment!/create_buy_order!/distribute_order!), `NotifierHelpers` (ensure_notification_setting!/with_mixin_bot_delivery_stub/deliver_notifier!/notification_for), `QuillBotStub`. `perform_enqueued_jobs` and `assert_enqueued_jobs` available.
- **Notified notifier shape**: `notification.url` set by `url` method; `notification.data` is a Hash; `web_notification_enabled?` and `mixin_bot_notification_enabled?` are notification instance methods backed by `recipient.notification_setting.<key>`.
- **APP_CARD notifiers** (`CollectionBoughtNotifier`, `CollectionListedNotifier`, `ArticlePublishedNotifier`): icon_url = author/buyer avatar, title truncated to 36, description truncated to 72, action = url. `description` and `message` may differ — CollectionListedNotifier's `description` deliberately omits the colon and collection name to fit the 72-char APP_CARD budget.
- **PLAIN_TEXT notifiers**: `data == message`. SwapOrderFinishedNotifier, SwapOrderSwappingNotifier, SubscribeUserActionCreatedNotifier, PaymentRefundedNotifier.
- **Setting keys by notifier**: `CollectionListedNotifier` → `article_published_web`/`article_published_mixin_bot`. `CollectionBoughtNotifier` → `article_bought_web`/`article_bought_mixin_bot`. `ArticlePublishedNotifier` → `article_published_web`/`article_published_mixin_bot`. **Notifiers without `web_notification_enabled?` override** (PLAIN_TEXT) inherit `visible_in_web? == true` from `NoticedNotificationExtensions` — only need to test `may_notify_via_mixin_bot?` and the messenger gate.
- **User#messenger?**: `authorization.provider == "mixin"`. To make a fixture user NOT a messenger, swap `user_authorizations(:<user>_auth).provider` to `"fennec"`.
- **PreOrder**: AASM `drafted → paid`/`drafted → expired`. `pay!` fires `broadcast_to_views` as after_commit (stub via `define_singleton_method(:broadcast_to_views) { }`). `setup_attributes` auto-fills follow_id, trace_id, memo (urlsafe base64), payee_id (= QuillBot.client_id), asset_id. Decoded memo keys: `t`, `a`, `l`, `f`.
- **Orders::DistributeService#distribute_article_order!**: Creates quill_revenue (conditional on payment.wallet_id != QuillBot.api.client_id), reader_revenue, reference_revenue (CITEREFERENCE), collection reader_revenue, author_revenue. Reference uses `find_or_create_by` for idempotency. Memo formats: reader=`"Reader revenue from {title}".truncate(70)`, author=`"{buyer} {bought|rewarded} {title}"` or `"Reference revenue from {title}"`.
- **Orders::DistributeService#distribute_collection_order!**: Only quill_revenue (conditional) + author_revenue. NO reader_revenue, NO reference_revenue.
- **MixinNetworkSnapshot.create!**: Requires `transferred_at` field. To test the wallet-equals-bot skip branch, create a real snapshot with `user_id: bot_client_id` and re-bind payment's snapshot_id.
- **Order type enum**: `buy_article: 0, reward_article: 1, cite_article: 2, buy_collection: 3`. cite_article orders have `citer` set to the citing article.
- **PandoLake**: `app/libs/pando_lake.rb`. `SwapOrder#after_create` calls `PandoLake.api.actions(...)`. To test code that creates a SwapOrder, stub `PandoLake.api` (no shared helper; inline in tests).
- **Currency creation in tests**: `Currency#before_validation :set_defaults` overwrites `raw` and several attributes from `QuillBot.api.asset(asset_id)`. To create a second currency in tests, stub `QuillBot.api.asset` to return a `{"data" => {...}}` payload (the existing `with_quill_bot_stub` does not stub `asset`).
- **SwapOrder model**: `user_id` references `User#mixin_uuid` (NOT `User#uuid` — User has no `uuid` attribute). `pay_asset_id` and `fill_asset_id` reference `Currency#asset_id`.
- **`safeoutputs create_pull_request`**: Returns patch/bundle path when bridge is in patch mode; PRs may not appear in `list_pull_requests` until the bridge pushes. The 2026-06-08 run's PR #1545 was merged. All other 2026-06-* runs returned patch mode.

## Backlog

3 of 3 PLAIN_TEXT notifiers that previously lacked coverage now done (CollectionListedNotifier, CollectionBoughtNotifier, SwapOrderSwappingNotifier). 2 notifiers remain untested: `payment_refunded_notifier` and `swap_order_finished_notifier`. See `2026-06-20-notes.md` for next-run candidates.

## Last Run

- 2026-06-20 — SwapOrderSwappingNotifier coverage added (9 new tests, branch `test-assist/swap-order-swapping-notifier`, commit `1704bf6`); PR via safeoutputs patch mode; Monthly Activity issue #1517 to be updated; backlog item marked done.
