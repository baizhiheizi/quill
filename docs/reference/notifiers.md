# Notifiers reference

> **30-second summary:** Notifiers are [Noticed](https://github.com/excid3/noticed) event classes under `app/notifiers/`. Each notifier fans an event out to one or more delivery methods — web (ActionCable + flash), and the Mixin Messenger bot — gated by the recipient's `NotificationSetting`. There are 18 notifiers; every concrete notifier inherits from `ApplicationNotifier` and declares its required params, its delivery methods, and the helpers that build the message/data payload.

## How to read this page

Each notifier is listed with its source path, the event that fires it, the required params, the channel it ships through (`APP_CARD` for rich cards, `PLAIN_TEXT` for short notices), and any recipient-side opt-outs. Where the behaviour is more nuanced than a single sentence, a dedicated subsection spells out the structure.

## Base class

### `ApplicationNotifier` — [`app/notifiers/application_notifier.rb`](../../app/notifiers/application_notifier.rb)

Inherits from `Noticed::Event` and sets the defaults for every concrete notifier:

- `class_attribute :persist_web_notification, default: true` — controls whether the notification is saved to the `notifications` table. Flip to `false` on notifiers that should only fire in real time (for example, `UserConnectedNotifier` and `UserSafeRegistrationNotifier`).
- `deliver_by :action_cable` — always sends the formatted message over Solid Cable so the navbar bell updates live. The `if:` predicate keeps the broadcast silent when `visible_in_web?` is false or `message` is blank.
- `deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast"` — surfaces a one-time flash banner. The same `visible_in_web? && message.present?` gate applies.
- `QUILL_ICON_URL` — the asset-path-resolved brand icon. Reused by notifiers that have no natural icon (for example, `TaggingCreatedNotifier`).
- `notification_methods` — defines the shared helpers `format_for_action_cable`, `message`, `url`, `icon_url`, and `recipient_messenger?`. The last one is the standard guard for "the recipient has a Mixin Messenger account linked".

Concrete notifiers typically add their own `required_param`, an additional `deliver_by :mixin_bot` block, and override the relevant `notification_methods` to fill in their event-specific data.

## Delivery methods

| Method | Path | Purpose |
|--------|------|---------|
| `:action_cable` (built-in) | — | Pushes the formatted message to the live UI. Always-on unless `message` is blank. |
| `:flash_broadcast` | [`app/notifiers/delivery_methods/flash_broadcast.rb`](../../app/notifiers/delivery_methods/flash_broadcast.rb) | `notification.broadcast_as_flash` for one-time Rails flash messages. |
| `:mixin_bot` | [`app/notifiers/delivery_methods/mixin_bot.rb`](../../app/notifiers/delivery_methods/mixin_bot.rb) | Sends a Mixin Messenger message via `MixinMessages::SendJob`. Resolves the bot to `RevenueBot` (when `config[:bot] == "RevenueBot"` and `RevenueBot.api` is configured) or `QuillBot` otherwise. Sets the conversation id from `recipient.mixin_uuid`, the category from `config[:category] || "PLAIN_TEXT"`, and the data from `config[:data] || notification.data`. |

The category matters: `APP_CARD` payloads are rich cards with `icon_url`, `title`, `description`, and an `action` URL; `PLAIN_TEXT` payloads are short free-text notices. The card shape is contractually defined by Quill's Mixin bot integration — keep the four keys in `notification_methods#data` in sync with the bot client.

## Notifier catalog

### Articles

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `ArticlePublishedNotifier` | `:article` | `APP_CARD` | An author publishes a draft (`notify_for_first_published`). Notifies all readers with `article_published_web` / `article_published_mixin_bot` enabled. |
| `ArticleBoughtNotifier` | `:order` | `APP_CARD` | A reader buys an article. Sends a card to the **author** with the buyer's name and the article title. |
| `ArticleRewardedNotifier` | `:order` | `APP_CARD` | A reader tips an article after the fact. Sends a card to the **author** with the tipper's name and the article title. |

### Collections

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `CollectionListedNotifier` | `:collection` | `APP_CARD` | A new collection is published. Sends a card to readers opted in to `article_published_*` (the same toggle drives collection listings). |
| `CollectionBoughtNotifier` | `:order` | `APP_CARD` | A reader buys a collection. Sends a card to the **author** with the buyer's name and the collection name. |

### Comments

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `CommentCreatedNotifier` | `:comment` | `APP_CARD` | A reader comments on an article. Sends a card to the **author**, skipping the notification if the recipient has blocked the commenter. The URL anchors to `#comment_<id>`. |
| `CommentDeletedNotifier` | `:comment` | `PLAIN_TEXT` | An admin deletes a comment. Notifies the **commenter** that the comment is gone. |

### Tags and subscriptions

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `TaggingCreatedNotifier` | `:tagging` | `APP_CARD` | An article is tagged. Sends a card to anyone who has subscribed to that tag's `has_new_article` feed, blocked-author checks apply. |
| `SubscribeUserActionCreatedNotifier` | `:action` | `PLAIN_TEXT` | A new subscriber follows a user's activity. Sends a short `subscribed` notice to the followed user. |

### Orders and payments

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `OrderCreatedNotifier` | `:order` | `PLAIN_TEXT` | The buyer completes a buy or reward. Sends a confirmation back to the buyer; the verb (`bought` vs `rewarded`) is picked from `order.order_type`. |
| `PaymentCreatedNotifier` | `:payment` | `PLAIN_TEXT` | A payment snapshot is created (mostly for debugging / Mixin traceability). |
| `PaymentRefundedNotifier` | `:payment` | `PLAIN_TEXT` | A payment is refunded. The message interpolates the related `pre_order.item.title` so the buyer can identify the original purchase. |

### Swap orders

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `SwapOrderSwappingNotifier` | `:swap_order` | `PLAIN_TEXT` | A swap order starts. Sends the in-flight `pay_asset -> fill_asset` pair to the user. |
| `SwapOrderFinishedNotifier` | `:swap_order` | `PLAIN_TEXT` | A swap order ends. The message switches on `swap_order.state` — `completed`/`refunded` produces a swapped summary, `rejected` produces a rejection notice. |

### Transfers and accounts

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `TransferProcessedNotifier` | `:transfer` | `APP_CARD` | A confirmed transfer (author revenue, reader revenue, payment refund, bonus, swap change, or swap refund) arrives. Skips Mixin delivery when the transfer came from the Quill bot wallet itself (`from_quill_bot?` returns true). |
| `UserConnectedNotifier` | `:user` | `PLAIN_TEXT` | A user connects the Mixin Messenger bot for the first time. `persist_web_notification = false` because it is a one-time greeting. |
| `UserSafeRegistrationNotifier` | `:user` | `PLAIN_TEXT` | A user is asked to update Mixin Messenger to receive transfers. `persist_web_notification = false`; only fans out over Mixin bot. |

## Patterns to know

### `required_param` and `params`

`required_param :article` (or `:order`, `:comment`, etc.) is the [Noticed](https://github.com/excid3/noticed) idiom that enforces the presence of the named key on the notifier's `params`. Concrete notifiers then re-expose the value with a `notification_methods` helper — typically a `def article = params[:article]` reader or a `delegate :article, to: :tagging` shortcut. Always reach for `params[:article]` rather than storing the record on the notifier directly; the params hash is the boundary that makes test helpers like `NotifierHelpers#deliver_notifier!` work uniformly.

### Web vs Mixin opt-out

Most notifiers expose three predicates and combine them in the delivery block:

- `web_notification_enabled?` — reads the matching `*_web` boolean on `recipient.notification_setting`.
- `mixin_bot_notification_enabled?` — same, for the `*_mixin_bot` boolean.
- `may_notify_via_mixin_bot?` — combines `recipient_messenger?` with the previous predicate; this is what the `if:` lambda on the `deliver_by :mixin_bot` block calls.
- `should_notify?` — used by notifiers that need an extra guard, e.g. blocking. `CommentCreatedNotifier` and `TaggingCreatedNotifier` use it to skip recipients who have blocked the source user. When `should_notify?` is defined, expose a matching `may_notify_via_web?` that ANDs the guard into the predicate.

### `data` shape

`APP_CARD` notifiers follow the same hash contract:

```ruby
{
  icon_url:,
  title: <subject>.truncate(36),
  description: description.truncate(72),
  action: url
}
```

`TransferProcessedNotifier` adds `shareable: false` because the card deep-links to a Mixin snapshot the user owns. The `action` URL is what the bot renders as a tappable button — for articles it is `user_article_url(author, uuid)`, for collections it is `collection_url(uuid)`, and for transfers it is `https://mixin.one/snapshots/<id>`.

### I18n

All user-facing strings live in [`config/locales/notifications.<locale>.yml`](../../config/locales/) under `notifiers.<notifier_name>.notification.<key>`. Concrete notifiers call `t(".published")` / `t(".bought")` / etc. so that the locale is resolved per-recipient (see `format_for_action_cable` and the `I18n.with_locale` wrapper inside `DeliveryMethods::MixinBot#deliver`).

## Testing

The shared helpers live in [`test/support/notifier_helpers.rb`](../../test/support/notifier_helpers.rb):

- `deliver_notifier!(notifier_class, record:, recipient:, **params)` — wraps `notifier_class.with(record: record, **params).deliver(recipient)`.
- `notification_for(recipient)` — returns the most recently persisted notification for that recipient, used to assert message/url/data shape.
- `ensure_notification_setting!(user)` — creates a `NotificationSetting` on demand; most notifier tests call this in `setup` to avoid the implicit `nil` from `belongs_to`.
- `with_mixin_bot_delivery_stub` — stubs `QuillBot.api.base_message_params` so Mixin delivery tests run without the network.

Notifier tests live under [`test/notifiers/`](../../test/notifiers/). The full coverage matrix is:

| Test file | Subject |
|-----------|---------|
| `application_notifier_test.rb` | Base predicates on `ApplicationNotifier` |
| `article_published_notifier_test.rb` | `ArticlePublishedNotifier` (web visibility, URL anchor, APP_CARD payload, mixin enqueue + opt-out) |
| `article_bought_notifier_test.rb` | `ArticleBoughtNotifier` |
| `article_rewarded_notifier_test.rb` | `ArticleRewardedNotifier` |
| `comment_created_notifier_test.rb` | `CommentCreatedNotifier` |
| `comment_deleted_notifier_test.rb` | `CommentDeletedNotifier` |
| `tagging_created_notifier_test.rb` | `TaggingCreatedNotifier` |
| `user_connected_notifier_test.rb` | `UserConnectedNotifier` |
| `user_safe_registration_notifier_test.rb` | `UserSafeRegistrationNotifier` |
| `delivery_methods/mixin_bot_test.rb` | Bot resolution + payload shape |

To assert Mixin enqueueing, use `assert_enqueued_jobs 1, only: Noticed::EventJob` followed by `perform_enqueued_jobs only: Noticed::EventJob` and `assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot`. The article-purchased/rewarded/collection-bought path uses the same pattern.

## Adding a new notifier

1. Place the file at `app/notifiers/<verb>_<subject>_notifier.rb`. Inherit from `ApplicationNotifier` unless you genuinely need a different base.
2. Declare the required param with `required_param :thing` and the Mixin delivery with the standard `deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot"` block. Pick `APP_CARD` for rich cards (article / collection / tagging) and `PLAIN_TEXT` for short notices.
3. Override `notification_methods` to fill in `data`, `message`, `description` (cards only), `url`, and the `*_enabled?` predicates. Cards should re-use the `truncate(36)` / `truncate(72)` envelope; plain-text notifiers can set `data` to `message` directly.
4. Add the i18n keys under `config/locales/notifications.<locale>.yml` → `notifiers.<your_notifier>.notification.*`. The English copy is the source of truth; the other locales mirror the same shape.
5. If the recipient should not see the event when they have blocked the source user, add `def should_notify? = !recipient.block_user? <source>` and route both `may_notify_via_web?` and `may_notify_via_mixin_bot?` through it. (`CommentCreatedNotifier` and `TaggingCreatedNotifier` are the existing examples.)
6. Add a row to the catalog above and a test file under `test/notifiers/`. Use the helpers in `test/support/notifier_helpers.rb` to avoid re-implementing the boilerplate.
