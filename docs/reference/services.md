# Services reference

> **30-second summary:** Service objects live under `app/services/`. They are stateless command/query classes invoked as `Foo::Bar.call(*args)` (returning the result) or `instance.call` (mutating state). They wire together ActiveRecord models, Mixin integrations, and background jobs so controllers stay thin.

## Order pipeline

### `Orders::DistributeService` — [`app/services/orders/distribute_service.rb`](../../app/services/orders/distribute_service.rb)

Implements the value-net split (10/50/40) for a paid `Order`. Idempotent (short-circuits on `Order#completed?`); `Collection` orders skip early readers and only pay platform + author.

For `Article` orders it does, in order:

1. **Pick the weighting basis.** `#early_orders_with_the_same_currency` chooses `Order#total` when all priors share `asset_id`, else `Order#value_btc`.
2. **Collect early readers.** `#collect_early_readers` groups prior orders by `buyer.mixin_uuid` so one reader who both bought and rewarded gets one transfer.
3. **Pay the platform fee** (`total * platform_revenue_ratio`, floored to 8 dp) when the buyer's wallet is not the Quill bot wallet.
4. **Pay reference revenue.** Each `ArticleReference` gets `total * reference.revenue_ratio`, floored, dropped below `MINIMUM_AMOUNT`.
5. **Pay collection revenue.** When the article belongs to a `Collection` with positive `collection_revenue_ratio`, the share splits evenly across prior `buy_collection` orders on that collection.
6. **Pay the author** what's left after steps 3–5; sub-floor remainders roll into the author line, and sub-floor author transfers are skipped.

Invoked from [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) on the `critical` queue and from `Order#distribute!` / `Order#distribute_async`. See [Value net](../explanation/value-net.md) for the rules.

Key methods:

- `MINIMUM_AMOUNT = 0.00000001` — floor for every transfer; sub-floor amounts stay with the order's author.
- `#early_orders` — memoised prior-orders scope.
- `#early_orders_with_the_same_currency` / `#collect_early_readers` — power steps 1–2 above.
- `#revenue_asset_id` — `payment.asset_id`; payout asset matches the order even when weights are in BTC.
- `#quill_amount`, `#distributor_wallet_id` — derive from `item.platform_revenue_ratio` and `QuillBot.api.client_id`.

## Article rendering

### `MarkdownRenderService` — [`app/services/markdown_render_service.rb`](../../app/services/markdown_render_service.rb)

Renders Markdown article bodies via Kramdown (GFM) with two modes:

- `:default` — inline previews; escapes non-whitelisted iframes.
- `:full` — full view: paragraphs, links, tables, mentions, and scroll anchors for deep links.

Whitelisted iframe hosts live in `IFRAME_SRC_WHITE_LIST_REGEX` at the top of the file.

### `RichTextRenderService` — [`app/services/rich_text_render_service.rb`](../../app/services/rich_text_render_service.rb)

Same two modes as `MarkdownRenderService`, but for ActionText content. Reuses the same iframe whitelist.

## Article search

### `ArticleSearchService` — [`app/services/article_search_service.rb`](../../app/services/article_search_service.rb)

Single-call query object that assembles an article scope from optional parameters:

- `query` — Ransack across title, intro, author name, tag names
- `tag` — substring on `tags.name`
- `filter` — arbitrary Ransack hash
- `time_range` — article creation time
- `current_user` — locale + exclude blocked authors
- `locale` — defaults to the user's locale when no query is present

Used by `ArticlesController#index` and the dashboard search.

## Tag management

### `CreateTagService` — [`app/services/create_tag_service.rb`](../../app/services/create_tag_service.rb)

Reconciles an article's tag list with the supplied tag names — creates missing `Tag` records, adds new taggings, removes stale ones (unless called with `with_remove: false`). Idempotent and safe to call on every save.

## Notifications

### `AdminNotificationService` — [`app/services/admin_notification_service.rb`](../../app/services/admin_notification_service.rb)

Sends plain-text or post messages to the admin Mixin group conversation. No-ops when `Rails.application.credentials.dig(:admin, :group_conversation_id)` is blank, so it's safe in development without secrets.

### `TextNotificationService` — [`app/services/text_notification_service.rb`](../../app/services/text_notification_service.rb)

Thin wrapper around `AdminNotificationService#text` for short payloads. Used by notifiers and admin actions.

## Service conventions

- Prefer `Foo::Bar.call(args)` for one-shot work; use `instance.call` to chain or hold state.
- Put network calls and enqueues in the public `#call`, not the constructor, so construction stays cheap in tests.
- `Order` callbacks own financial logging; services don't reach for `Rails.logger.info`.
- Every file starts with `# frozen_string_literal: true`.

## Adding a new service

Drop `app/services/<domain>/<name>_service.rb`: `# frozen_string_literal: true` header, a single public `#call`, `def self.call(...) = new(...).call` shortcut, a test under `test/services/`, and a row in the catalog above.