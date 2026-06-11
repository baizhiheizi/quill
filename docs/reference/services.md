# Services reference

> **30-second summary:** Service objects live under `app/services/`. They are stateless command/query classes invoked as `Foo::Bar.call(*args)` (returning the result) or `instance.call` (mutating state). They wire together ActiveRecord models, Mixin integrations, and background jobs so controllers stay thin.

## How to read this page

Each service is listed with its path, what it owns, and what calls it. Where a service is the public entry point for a subsystem, link out to the [Explanation](../explanation/) page that describes the subsystem in plain English.

## Order pipeline

### `Orders::DistributeService` — [`app/services/orders/distribute_service.rb`](../../app/services/orders/distribute_service.rb)

Owns the value-net split (10 / 50 / 40) for an individual `Order`. Idempotent: returns early if the order is already `completed?`, and is itself only invoked once per paid order. Branches on `order.item` to handle both `Article` and `Collection` orders. For `Collection` purchases the split is just platform-fee + author-revenue; the early-reader pool is an article-only concept.

For `Article` orders the service does, in order:

1. **Pick the weighting basis.** `early_orders_with_the_same_currency` returns truthy only when every prior `buy_article` / `reward_article` on the article uses the same `asset_id` as the incoming order. When that holds, every per-reader share is weighted by `Order#total`; when it doesn't, the service falls back to `Order#value_btc` so the pro-rata split stays fair across currencies.
2. **Collect early readers.** `collect_early_readers` groups prior orders by `buyer.mixin_uuid` and returns `{ mixin_uuid => [trace_id, ...] }`. The same reader who both bought and rewarded the article ends up with **one** entry; the service emits exactly one reader-revenue transfer per reader, not one per order.
3. **Pay the platform fee** (`total * platform_revenue_ratio`, floored to 8 dp) when the buyer's wallet is not already the Quill bot wallet.
4. **Pay reference revenue.** Each `ArticleReference` linked to the article gets `total * reference.revenue_ratio`, floored, then dropped if it falls below `MINIMUM_AMOUNT`.
5. **Pay collection revenue.** When the article belongs to a `Collection` with a positive `collection_revenue_ratio`, the article's collection share is split evenly across every prior `buy_collection` order on that collection.
6. **Pay the author.** The author receives whatever is left of `total` after the four deductions above, again floored and dropped if it would be below `MINIMUM_AMOUNT`.

Key methods and constants:

- `Orders::DistributeService::MINIMUM_AMOUNT = 0.00000001` — floor for every emitted transfer. Sub-floor amounts are not refunded; they stay with the order's author.
- `#early_orders` — memoised scope: prior `buy_article` / `reward_article` orders on the same item with `id` and `created_at` strictly before the current order.
- `#early_orders_with_the_same_currency` — predicate that decides between the `total` and `value_btc` weighting bases.
- `#collect_early_readers` — the folding step described above.
- `#revenue_asset_id` — `payment.swap_order&.fill_asset_id || payment.asset_id`. The service always pays out in this asset, even when the historical weights are denominated in BTC.
- `#quill_amount`, `#distributor_wallet_id` — derived from `item.platform_revenue_ratio` and `QuillBot.api.client_id` respectively.

Invoked from:

- [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) — per-order worker on the `critical` queue.
- `Order#distribute!` / `Order#distribute_async` — fired when an order is marked paid.

See [Explanation → Value net](../explanation/value-net.md) for the rules this service implements.

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

Single-call query object that assembles an article scope from optional parameters:

| Param | Effect |
|-------|--------|
| `query` | Ransack search across title, intro, author name, and tag names |
| `tag` | Tag name (substring match on `tags.name`) |
| `filter` | Arbitrary Ransack filter hash |
| `time_range` | Filters by article creation time |
| `current_user` | Used for locale and to exclude blocked authors |
| `locale` | Defaults to the user's locale when no query is present |

Used by `ArticlesController#index` and the dashboard search.

## Tag management

### `CreateTagService` — [`app/services/create_tag_service.rb`](../../app/services/create_tag_service.rb)

Reconciles the tag list on an article with the supplied tag names:

1. Creates any missing `Tag` records.
2. Adds new taggings for tags that are not yet attached.
3. Removes taggings for tags no longer present (unless called with `with_remove: false`).

Idempotent and safe to call on every article save.

## Notifications

### `AdminNotificationService` — [`app/services/admin_notification_service.rb`](../../app/services/admin_notification_service.rb)

Sends plain-text or post messages to the admin Mixin group conversation. No-ops when `Rails.application.credentials.dig(:admin, :group_conversation_id)` is blank, so it is safe to call in development without secrets.

### `TextNotificationService` — [`app/services/text_notification_service.rb`](../../app/services/text_notification_service.rb)

Lightweight wrapper around `AdminNotificationService#text`. Used by notifiers and admin actions that only need to send a short text payload.

## Service conventions

- **Frozen string literals** are enabled at the top of every service file.
- **Class-method entry points** are preferred for one-shot work: `Foo::Bar.call(args)` returns the result.
- **Instance methods** (`#call`, `#initialize`) are used when the call site needs to chain transformations or hold intermediate state.
- **Side effects** (network calls, job enqueues) are always inside the public `#call`, not in the constructor. This makes the constructor cheap to invoke in tests.
- **No `Rails.logger.info` by default** — services that touch money log at the model layer (`Order` callbacks).

## Adding a new service

1. Place the file under `app/services/<domain>/<name>_service.rb`.
2. Define a frozen-string-literal header and a single public `#call`.
3. Expose a class-level convenience: `def self.call(...) = new(...).call`.
4. Add or extend the relevant test under `test/services/`.
5. Reference the new service from the page above so it is discoverable.