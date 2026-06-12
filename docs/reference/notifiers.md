# Notifiers reference

> **30-second summary:** Notifiers live under `app/notifiers/` and inherit from [`ApplicationNotifier`](../../app/notifiers/application_notifier.rb), which wraps the [Noticed](https://github.com/excid3/noticed) gem. Every notifier declares a `required_param` (the AR record the notification is about), a `deliver_by :mixin_bot` block, and a `notification_methods do ... end` block that defines `message`, `description`, `data`, `url`, `icon_url`, and the per-channel enablement predicates. The base class always also delivers via `:action_cable` (web real-time) and `:flash_broadcast` (browser flash messages).

## How the base class works

`ApplicationNotifier < Noticed::Event` already wires two delivery methods that every subclass inherits:

- `:action_cable` — pushes `format_for_action_cable` (the localized `message`) to the recipient over Solid Cable. Gated by `visible_in_web? && message.present?`.
- `:flash_broadcast` — calls `notification.broadcast_as_flash` so the page shows a one-time flash on next request. Gated by `visible_in_web? && message.present?`.

`ApplicationNotifier::QUILL_ICON_URL` exposes the resolved `Settings.icon_file` asset URL and is used by `APP_CARD` notifiers that have no author/buyer to take an avatar from (e.g. `TaggingCreatedNotifier`).

`self.persist_web_notification` defaults to `true`. Notifiers that should never appear in the user's inbox (welcome pings, connection events) override it to `false`; see `UserConnectedNotifier` and `UserSafeRegistrationNotifier`.

## Channel enablement

Each user has a `notification_setting` row that drives three independent channels:

| Channel | Predicate | Driver |
|---------|-----------|--------|
| Web (inbox + cable + flash) | `may_notify_via_web?` | `should_notify? && web_notification_enabled?` |
| Mixin bot (messenger `APP_CARD` / `PLAIN_TEXT`) | `may_notify_via_mixin_bot?` | `should_notify?` (if used) AND `recipient_messenger?` AND `mixin_bot_notification_enabled?` |

`should_notify?` is **not** defined on the base class. Only the notifiers that need it (`TaggingCreatedNotifier`, `CommentCreatedNotifier`) implement it to honour `recipient.block_user?(author)`. Other notifiers trust the per-channel settings alone.

The `recipient_messenger?` predicate returns `true` only for users that have a linked Mixin messenger; non-messenger users are silently skipped by the bot delivery.

## Mixin bot category

Every subclass sets `config.category` on its `deliver_by :mixin_bot` block. Two values appear in the catalog:

| Category | Shape | Used by |
|----------|-------|---------|
| `APP_CARD` | `{ icon_url, title, description, action }` | Article- and comment-shaped notifications |
| `PLAIN_TEXT` | free-form string | Transactional notifications (orders, payments, swaps, follow events) |

`TransferProcessedNotifier` also sets `config.bot = "RevenueBot"` so revenue notifications route through a separate bot client when `RevenueBot.api` is configured; otherwise `DeliveryMethods::MixinBot` falls back to `QuillBot`.

## Catalog

Notifiers are listed in alphabetical order. "Recipient" is the user the notification is delivered to.

### `ArticleBoughtNotifier` — [`app/notifiers/article_bought_notifier.rb`](../../app/notifiers/article_bought_notifier.rb)

Sent to the **article author** when someone pays for one of their articles.

- Param: `:order`
- Channel settings: `article_bought_web`, `article_bought_mixin_bot`
- Icon: the buyer's avatar; title: article title; url: `user_article_url(author, article.uuid)`

### `ArticlePublishedNotifier` — [`app/notifiers/article_published_notifier.rb`](../../app/notifiers/article_published_notifier.rb)

Sent to **subscribers** when an article they follow is published.

- Param: `:article`
- Channel settings: `article_published_web`, `article_published_mixin_bot`
- Icon: the author's avatar; title: article title; url: `user_article_url(author, article.uuid)`

### `ArticleRewardedNotifier` — [`app/notifiers/article_rewarded_notifier.rb`](../../app/notifiers/article_rewarded_notifier.rb)

Sent to the **article author** when a reader rewards their article.

- Param: `:order`
- Channel settings: `article_rewarded_web`, `article_rewarded_mixin_bot`
- Same shape as `ArticleBoughtNotifier` with the `.rewarded` translation key

### `CollectionBoughtNotifier` — [`app/notifiers/collection_bought_notifier.rb`](../../app/notifiers/collection_bought_notifier.rb)

Sent to the **collection author** when someone buys the collection.

- Param: `:order`
- Channel settings: `article_bought_web`, `article_bought_mixin_bot` (shared with `ArticleBoughtNotifier`)
- Icon: buyer's avatar; title: collection name; url: `collection_url(collection.uuid)`

### `CollectionListedNotifier` — [`app/notifiers/collection_listed_notifier.rb`](../../app/notifiers/collection_listed_notifier.rb)

Sent to **subscribers** when a new collection they follow is listed.

- Param: `:collection`
- Channel settings: `article_published_web`, `article_published_mixin_bot` (shared with `ArticlePublishedNotifier`)
- Icon: collection author's avatar; title: collection name; url: `collection_url(collection.uuid)`

### `CommentCreatedNotifier` — [`app/notifiers/comment_created_notifier.rb`](../../app/notifiers/comment_created_notifier.rb)

Sent to the **commentable author** when someone comments on their article or collection.

- Param: `:comment`
- Channel settings: `comment_created_web`, `comment_created_mixin_bot`
- Implements `should_notify?` to skip when the recipient has blocked the comment's author
- Title: the comment text (truncated to 36 chars); url: anchored to `#comment_<id>` on the commentable

### `CommentDeletedNotifier` — [`app/notifiers/comment_deleted_notifier.rb`](../../app/notifiers/comment_deleted_notifier.rb)

Sent to the **comment author** when their comment is removed by the commentable author.

- Param: `:comment`
- Channel: Mixin bot only (no web channel); gated by `recipient_messenger?`
- `PLAIN_TEXT` category

### `OrderCreatedNotifier` — [`app/notifiers/order_created_notifier.rb`](../../app/notifiers/order_created_notifier.rb)

Sent to the **order buyer** to confirm a `buy_article`, `buy_collection`, or `reward_article` order was recorded.

- Param: `:order`
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`; branches on `order.item` for Article vs Collection wording and url

### `PaymentCreatedNotifier` — [`app/notifiers/payment_created_notifier.rb`](../../app/notifiers/payment_created_notifier.rb)

Sent to the **payer** when their payment snapshot is observed.

- Param: `:payment`
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`; links to the Mixin snapshot URL

### `PaymentRefundedNotifier` — [`app/notifiers/payment_refunded_notifier.rb`](../../app/notifiers/payment_refunded_notifier.rb)

Sent to the **payer** when their payment is refunded.

- Param: `:payment`
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`; requires `payment.refund_transfer` to build the snapshot url

### `SubscribeUserActionCreatedNotifier` — [`app/notifiers/subscribe_user_action_created_notifier.rb`](../../app/notifiers/subscribe_user_action_created_notifier.rb)

Sent to the **subscribed-to user** when another user follows them.

- Param: `:action` (a `users.subscribe_users` action record)
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`

### `SwapOrderFinishedNotifier` — [`app/notifiers/swap_order_finished_notifier.rb`](../../app/notifiers/swap_order_finished_notifier.rb)

Sent to the **swap initiator** when a swap completes, refunds, or is rejected.

- Param: `:swap_order`
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`; branches on `swap_order.state` (`:completed`/`:refunded` vs `:rejected`)

### `SwapOrderSwappingNotifier` — [`app/notifiers/swap_order_swapping_notifier.rb`](../../app/notifiers/swap_order_swapping_notifier.rb)

Sent to the **swap initiator** while the swap is in flight.

- Param: `:swap_order`
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`

### `TaggingCreatedNotifier` — [`app/notifiers/tagging_created_notifier.rb`](../../app/notifiers/tagging_created_notifier.rb)

Sent to **tag subscribers** when an article is tagged with a tag they follow.

- Param: `:tagging`
- Channel settings: `tagging_created_web`, `tagging_created_mixin_bot`
- Implements `should_notify?` to skip when the recipient has blocked the article's author
- Uses `QUILL_ICON_URL` (no per-author avatar available); description embeds the tag name with a leading `#`; url anchors to the article on the author's article page

### `TransferProcessedNotifier` — [`app/notifiers/transfer_processed_notifier.rb`](../../app/notifiers/transfer_processed_notifier.rb)

Sent to the **transfer recipient** when a transfer settles.

- Param: `:transfer`
- Channel settings: `transfer_processed_web`, `transfer_processed_mixin_bot`
- Routes via `RevenueBot` when configured, otherwise `QuillBot`
- Mixin bot delivery skips transfers from the Quill bot wallet (`from_quill_bot?`)
- Title: amount to 8 dp; description: currency symbol; action: `mixin://snapshots?trace=<trace_id>` with `shareable: false`

### `UserConnectedNotifier` — [`app/notifiers/user_connected_notifier.rb`](../../app/notifiers/user_connected_notifier.rb)

One-time Mixin ping when a user connects a wallet.

- Param: `:user`
- `self.persist_web_notification = false` — never appears in the inbox
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`

### `UserSafeRegistrationNotifier` — [`app/notifiers/user_safe_registration_notifier.rb`](../../app/notifiers/user_safe_registration_notifier.rb)

One-time Mixin ping when a user registers a safe (Mixin multisig).

- Param: `:user`
- `self.persist_web_notification = false` — never appears in the inbox
- Channel: Mixin bot only; gated by `recipient_messenger?`
- `PLAIN_TEXT`

## Delivery methods

### `DeliveryMethods::MixinBot` — [`app/notifiers/delivery_methods/mixin_bot.rb`](../../app/notifiers/delivery_methods/mixin_bot.rb)

Builds the `base_message_params` envelope and enqueues `MixinMessages::SendJob`. Picks the bot client by `config[:bot]` (`RevenueBot` if configured, else `QuillBot`) and resolves the `conversation_id` from `bot_api.unique_conversation_id(recipient.mixin_uuid)`. Localises the message via `I18n.with_locale(recipient&.locale || I18n.default_locale)`.

### `DeliveryMethods::FlashBroadcast` — [`app/notifiers/delivery_methods/flash_broadcast.rb`](../../app/notifiers/delivery_methods/flash_broadcast.rb)

Calls `notification.broadcast_as_flash` so the next page load shows the message as a flash banner.

## Adding a new notifier

1. Create `app/notifiers/<domain>/<name>_notifier.rb` (top-level notifiers sit directly in `app/notifiers/`). Inherit from `ApplicationNotifier`.
2. Set `self.persist_web_notification = false` if the event should never appear in the inbox.
3. Declare the parameter the notification is about with `required_param :foo`.
4. Wire the Mixin bot channel: `deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config| ... end`. Pick `APP_CARD` for rich article-shaped cards, `PLAIN_TEXT` for transactional text. Gate with `config.if = -> { may_notify_via_mixin_bot? }`.
5. Inside `notification_methods do ... end` implement `message`, `description`, `data`, `url`, `icon_url`, plus `web_notification_enabled?`, `mixin_bot_notification_enabled?`, `may_notify_via_web?`, and `may_notify_via_mixin_bot?`. Add `should_notify?` only if the event needs to honour `recipient.block_user?(author)`.
6. Add translations under `config/locales/notifications.*.yml` at `notifiers.<notifier_name>.notification.*`.
7. Add a test under `test/notifiers/<name>_notifier_test.rb`. Mirror the `TaggingCreatedNotifierTest` pattern: one test per behaviour (deliver shape, `url`, `data` payload, `visible_in_web?` when blocked, `visible_in_web?` when disabled, mixin bot enqueue, mixin bot suppression).
8. Add a row to the catalog above so it is discoverable.

## See also

- [Reference → Services](./services.md) — `AdminNotificationService` and `TextNotificationService` route admin alerts.
- [Reference → Background jobs](./background-jobs.md) — `MixinMessages::SendJob` is what the bot delivery ultimately enqueues.
- [Explanation → Architecture](../explanation/architecture.md) — high-level subsystem overview.
