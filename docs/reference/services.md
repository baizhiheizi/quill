# Services reference

> **30-second summary:** Service objects live under `app/services/`. They are stateless command/query classes invoked as `Foo::Bar.call(*args)` (returning the result) or `instance.call` (mutating state). They wire together ActiveRecord models, Mixin integrations, and background jobs so controllers stay thin.

## Order pipeline

### `Orders::DistributeService` — [`app/services/orders/distribute_service.rb`](../../app/services/orders/distribute_service.rb)

Implements the value-net split (10/50/40) for a paid `Order`. Idempotent (short-circuits on `Order#completed?`); `Collection` orders skip the early-reader pool and only pay platform + author.

For `Article` orders the service does, in order:

1. **Pick the weighting basis.** `#early_orders_with_the_same_currency` chooses `Order#total` when all priors share `asset_id` with the incoming order, else `Order#value_btc`.
2. **Collect early readers.** `#collect_early_readers` groups prior orders by `buyer.mixin_uuid` and returns `{ mixin_uuid => [trace_id, ...] }` so a reader who both bought and rewarded gets one transfer.
3. **Pay the platform fee** (`total * platform_revenue_ratio`, floored to 8 dp) when the buyer's wallet is not the Quill bot wallet.
4. **Pay reference revenue.** Each `ArticleReference` gets `total * reference.revenue_ratio`, floored, dropped below `MINIMUM_AMOUNT`.
5. **Pay collection revenue.** When the article belongs to a `Collection` with positive `collection_revenue_ratio`, its share splits evenly across every prior `buy_collection` order on that collection.
6. **Pay the author** whatever is left after steps 3-5, floored, dropped if sub-floor (the remainder rolls into the author's line; if that is also sub-floor the transfer is skipped).

`MINIMUM_AMOUNT = 0.00000001` floors every emitted transfer (sub-floor amounts stay with the order's author). `#early_orders` is the memoised prior-orders scope. `#revenue_asset_id` is `payment.swap_order&.fill_asset_id || payment.asset_id` — payout is always in this asset, even when historical weights are denominated in BTC. `#quill_amount` and `#distributor_wallet_id` derive from `item.platform_revenue_ratio` and `QuillBot.api.client_id`.

Invoked per-order from [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) (critical queue) and `Order#distribute!` / `Order#distribute_async`. See [Value net](../explanation/value-net.md) for the rules.
- `Orders::DistributeService::MINIMUM_AMOUNT = 0.00000001` — floor for every emitted transfer. Sub-floor amounts stay with the order's author.
- `#early_orders` — memoised scope: prior `buy_article` / `reward_article` orders on the same item with `id` and `created_at` strictly before the current order.
- `#early_orders_with_the_same_currency` — predicate that decides between the `total` and `value_btc` weighting bases.
- `#collect_early_readers` — folds prior orders by `buyer.mixin_uuid` so a reader who both bought and rewarded counts as a single early reader.
- `#revenue_asset_id` — `payment.asset_id`. Payout is always in this asset, even when historical weights are denominated in BTC.
- `#quill_amount`, `#distributor_wallet_id` — derived from `item.platform_revenue_ratio` and `QuillBot.api.client_id`.

Invoked from [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) (per-order worker on the `critical` queue) and from `Order#distribute!` / `Order#distribute_async` when an order is marked paid. See [Explanation → Value net](../explanation/value-net.md) for the rules this service implements.

## Article rendering

### `MarkdownRenderService` — [`app/services/markdown_render_service.rb`](../../app/services/markdown_render_service.rb)

Renders Markdown article bodies. Uses Kramdown in GFM mode. Two render modes:

- `:default` — output for inline previews; escapes non-whitelisted iframes.
- `:full` — full article view: parses paragraphs, links, tables, mentions, and adds scroll-anchor attributes for deep links.

Whitelisted iframe hosts live in `IFRAME_SRC_WHITE_LIST_REGEX` at the top of the file.

### `RichTextRenderService` — [`app/services/rich_text_render_service.rb`](../../app/services/rich_text_render_service.rb)

Same two render modes as the Markdown service but for ActionText content. Reuses the iframe whitelist from `MarkdownRenderService`.

## Article search

### `ArticleSearchService` — [`app/services/article_search_service.rb`](../../app/services/article_search_service.rb)

Single-call query object that assembles an article scope from optional parameters: `query` (Ransack across title, intro, author name, tag names), `tag` (substring on `tags.name`), `filter` (arbitrary Ransack hash), `time_range` (article creation time), `current_user` (locale + exclude blocked authors), and `locale` (defaults to the user's locale when no query is present). Used by `ArticlesController#index` and the dashboard search.

## Tag management

### `CreateTagService` — [`app/services/create_tag_service.rb`](../../app/services/create_tag_service.rb)

Reconciles the tag list on an article with the supplied tag names: creates missing `Tag` records, adds new taggings, and removes taggings for tags no longer present (unless called with `with_remove: false`). Idempotent and safe to call on every article save.

## Notifications

### `AdminNotificationService` — [`app/services/admin_notification_service.rb`](../../app/services/admin_notification_service.rb)

Sends plain-text or post messages to the admin Mixin group conversation. No-ops when `Rails.application.credentials.dig(:admin, :group_conversation_id)` is blank, so it is safe to call in development without secrets.

### `TextNotificationService` — [`app/services/text_notification_service.rb`](../../app/services/text_notification_service.rb)

Lightweight wrapper around `AdminNotificationService#text`. Used by notifiers and admin actions that only need to send a short text payload.

## Service conventions

- **Entry points.** Prefer class methods (`Foo::Bar.call(args)`) for one-shot work; use instance `#call` only when the call site needs to chain transformations or hold intermediate state.
- **Side effects in `#call`.** Network calls and job enqueues live in the public method, not the constructor, so the constructor stays cheap to invoke in tests.
- **Money logs at the model layer.** `Order` callbacks own the financial logging — services don't reach for `Rails.logger.info` by default.
- **Frozen string literals** at the top of every service file.

## Adding a new service

Drop a new file at `app/services/<domain>/<name>_service.rb` with a `# frozen_string_literal: true` header, a single public `#call`, a `def self.call(...) = new(...).call` shortcut, a test under `test/services/`, and a row in the catalog above.