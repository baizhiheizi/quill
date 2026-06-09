# Services reference

> **30-second summary:** Service objects live under `app/services/`. They are stateless command/query classes invoked as `Foo::Bar.call(*args)` (returning the result) or `instance.call` (mutating state). They wire together ActiveRecord models, Mixin/Arweave integrations, and background jobs so controllers stay thin.

## How to read this page

Each service is listed with its path, what it owns, and what calls it. Where a service is the public entry point for a subsystem, link out to the [Explanation](../explanation/) page that describes the subsystem in plain English.

## Order pipeline

### `Orders::DistributeService` — [`app/services/orders/distribute_service.rb`](../../app/services/orders/distribute_service.rb)

Owns the value-net split (10 / 50 / 40) for an individual `Order`. Idempotent: returns early if the order is already `completed?`. Branches on `order.item` to handle both `Article` and `Collection` orders.

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