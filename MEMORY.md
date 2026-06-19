# Test Improver Memory

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
- **PLAIN_TEXT notifiers**: `data == message`. SwapOrderFinishedNotifier, SubscribeUserActionCreatedNotifier, SwapOrderSwappingNotifier, PaymentRefundedNotifier.
- **Setting keys by notifier**: `CollectionListedNotifier` → `article_published_web`/`article_published_mixin_bot`. `CollectionBoughtNotifier` → `article_bought_web`/`article_bought_mixin_bot`. `ArticlePublishedNotifier` → `article_published_web`/`article_published_mixin_bot`.
- **User#messenger?**: `authorization.provider == "mixin"`. To make a fixture user NOT a messenger, swap `user_authorizations(:<user>_auth).provider` to `"fennec"`.
- **PreOrder**: AASM `drafted → paid`/`drafted → expired`. `pay!` fires `broadcast_to_views` as after_commit (stub via `define_singleton_method(:broadcast_to_views) { }`). `setup_attributes` auto-fills follow_id, trace_id, memo (urlsafe base64), payee_id (= QuillBot.client_id), asset_id. Decoded memo keys: `t`, `a`, `l`, `f`.
- **Orders::DistributeService#distribute_article_order!**: Creates quill_revenue (conditional on payment.wallet_id != QuillBot.api.client_id), reader_revenue, reference_revenue (CITEREFERENCE), collection reader_revenue, author_revenue. Reference uses `find_or_create_by` for idempotency. Memo formats: reader=`"Reader revenue from {title}".truncate(70)`, author=`"{buyer} {bought|rewarded} {title}"` or `"Reference revenue from {title}"`.
- **Orders::DistributeService#distribute_collection_order!**: Only quill_revenue (conditional) + author_revenue. NO reader_revenue, NO reference_revenue.
- **MixinNetworkSnapshot.create!**: Requires `transferred_at` field. To test the wallet-equals-bot skip branch, create a real snapshot with `user_id: bot_client_id` and re-bind payment's snapshot_id.
- **Order type enum**: `buy_article: 0, reward_article: 1, cite_article: 2, buy_collection: 3`. cite_article orders have `citer` set to the citing article.
- **PandoLake**: `app/libs/pando_lake.rb`. `SwapOrder#after_create` calls `PandoLake.api.actions(...)`. To test code that creates a SwapOrder, stub `PandoLake.api` (no shared helper; inline in tests).
- **`safeoutputs create_pull_request`**: Returns patch/bundle path when bridge is in patch mode; PRs may not appear in `list_pull_requests` until the bridge pushes. The 2026-06-08 run's PR #1545 was merged. All other 2026-06-* runs returned patch mode.

## Backlog

All 8 tracked items complete. 3 untested notifiers remain (`payment_refunded`, `subscribe_user_action_created`, `swap_order_swapping`) — all PLAIN_TEXT, simpler shape. See `2026-06-19-notes.md` for next-run candidates.

## Last Run

- 2026-06-19 — CollectionListedNotifier coverage added (17 new tests, branch `test-assist/collection-listed-notifier`, commit `7e48232`); PR via safeoutputs patch mode; Monthly Activity issue #1517 updated; backlog item marked done.
