# Notifiers reference

> **30-second summary:** Notifiers are [Noticed](https://github.com/excid3/noticed) event classes under `app/notifiers/`. Each notifier fans an event out to one or more delivery methods — web (ActionCable + flash), and the Mixin Messenger bot — gated by the recipient's `NotificationSetting`. There are 18 notifiers; every concrete notifier inherits from `ApplicationNotifier` and declares its required params, its delivery methods, and the helpers that build the message/data payload.

## Base class

### `ApplicationNotifier` — [`app/notifiers/application_notifier.rb`](../../app/notifiers/application_notifier.rb)

Inherits from `Noticed::Event` and sets the defaults for every concrete notifier:

- `class_attribute :persist_web_notification, default: true` — persists to the `notifications` table; set `false` for real-time-only notifiers (e.g. `UserConnectedNotifier`, `UserSafeRegistrationNotifier`).
- `deliver_by :action_cable` — broadcasts the formatted message over Solid Cable so the navbar bell updates live; gated by `visible_in_web? && message.present?`.
- `deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast"` — surfaces a one-time Rails flash banner under the same gate.
- `QUILL_ICON_URL` — the asset-path-resolved brand icon, reused when a notifier has no natural icon (e.g. `TaggingCreatedNotifier`).
- `notification_methods` — shared helpers: `format_for_action_cable`, `message`, `url`, `icon_url`, and `recipient_messenger?` (the standard guard for "the recipient has a Mixin Messenger account linked").

Concrete notifiers add their own `required_param`, a `deliver_by :mixin_bot` block, and override `notification_methods` to fill in event-specific data.

## Delivery methods

| Method | Path | Purpose |
|--------|------|---------|
| `:action_cable` (built-in) | — | Pushes the formatted message to the live UI. Always-on unless `message` is blank. |
| `:flash_broadcast` | [`app/notifiers/delivery_methods/flash_broadcast.rb`](../../app/notifiers/delivery_methods/flash_broadcast.rb) | `notification.broadcast_as_flash` for one-time Rails flash messages. |
| `:mixin_bot` | [`app/notifiers/delivery_methods/mixin_bot.rb`](../../app/notifiers/delivery_methods/mixin_bot.rb) | Sends a Mixin Messenger message via `MixinMessages::SendJob`. Resolves the bot to `RevenueBot` (when `config[:bot] == "RevenueBot"` and `RevenueBot.api` is configured) or `QuillBot` otherwise. Sets the conversation id from `recipient.mixin_uuid`, the category from `config[:category] || "PLAIN_TEXT"`, and the data from `config[:data] || notification.data`. |

`APP_CARD` payloads are rich cards with `icon_url`, `title`, `description`, and an `action` URL; `PLAIN_TEXT` payloads are short free-text notices. The card shape is contractually defined by Quill's Mixin bot integration — keep the four keys in `notification_methods#data` in sync with the bot client.

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
| `OrderCreatedNotifier` | `:order` | `PLAIN_TEXT` | The buyer completes a paid order (`buy_article`, `reward_article`, or `buy_collection`). Sends a confirmation back to the **buyer**; the verb (`bought` for `buy_article`/`buy_collection`, `rewarded` for `reward_article`) is picked from `order.order_type`. Fired from `Order#notify_buyer` (after `notify_subscribers` succeeds) so the author-facing notifiers — `ArticleBoughtNotifier` / `ArticleRewardedNotifier` / `CollectionBoughtNotifier` — always run first. |
| `PaymentCreatedNotifier` | `:payment` | `PLAIN_TEXT` | A payment snapshot is created (mostly for debugging / Mixin traceability). |
| `PaymentRefundedNotifier` | `:payment` | `PLAIN_TEXT` | A payment is refunded. The message interpolates the related `pre_order.item.title` so the buyer can identify the original purchase. |

### Transfers and accounts

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `TransferProcessedNotifier` | `:transfer` | `APP_CARD` | A confirmed transfer (author revenue, reader revenue, payment refund, or bonus) arrives. Skips Mixin delivery when the transfer came from the Quill bot wallet itself (`from_quill_bot?` returns true). |
| `UserConnectedNotifier` | `:user` | `PLAIN_TEXT` | A user connects the Mixin Messenger bot for the first time. `persist_web_notification = false` because it is a one-time greeting. |
| `UserSafeRegistrationNotifier` | `:user` | `PLAIN_TEXT` | A user is asked to update Mixin Messenger to receive transfers. `persist_web_notification = false`; only fans out over Mixin bot. |

## Patterns to know

### `required_param` and `params`

`required_param :article` (or `:order`, `:comment`, etc.) is the [Noticed](https://github.com/excid3/noticed) idiom that enforces the named key on the notifier's `params`. Concrete notifiers re-expose it via a `notification_methods` helper — typically `def article = params[:article]` or `delegate :article, to: :tagging`. Always reach for `params[:article]` rather than storing the record on the notifier; the params hash is the boundary that makes `NotifierHelpers#deliver_notifier!` work uniformly.

### Web vs Mixin opt-out

Most notifiers expose three predicates and combine them in the delivery block:

- `web_notification_enabled?` — reads the matching `*_web` boolean on `recipient.notification_setting`.
- `mixin_bot_notification_enabled?` — same, for the `*_mixin_bot` boolean.
- `may_notify_via_mixin_bot?` — `recipient_messenger? && mixin_bot_notification_enabled?`; the `if:` lambda on `deliver_by :mixin_bot` calls this.
- `should_notify?` — extra guard for blocking; `CommentCreatedNotifier` and `TaggingCreatedNotifier` use it to skip recipients who blocked the source user. When defined, expose a matching `may_notify_via_web?` that ANDs the guard in.

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

`TransferProcessedNotifier` adds `shareable: false` because the card deep-links to a Mixin snapshot the user owns. The `action` URL is what the bot renders as a tappable button — `user_article_url(author, uuid)` for articles, `collection_url(uuid)` for collections, `https://mixin.one/snapshots/<id>` for transfers.

### I18n

All user-facing strings live in [`config/locales/notifications.<locale>.yml`](../../config/locales/) under `notifiers.<notifier_name>.notification.<key>`. Concrete notifiers call `t(".published")` / `t(".bought")` / etc. so the locale resolves per-recipient (see `format_for_action_cable` and the `I18n.with_locale` wrapper in `DeliveryMethods::MixinBot#deliver`).

### OrderCreatedNotifier shape

`OrderCreatedNotifier` is the buyer-facing complement to `ArticleBoughtNotifier` / `ArticleRewardedNotifier` / `CollectionBoughtNotifier`. `Order#notify` calls `notify_subscribers` first and `notify_buyer` second so the author always sees the sale before the buyer sees the receipt. Four behaviours set it apart from the rest of the catalog:

- **Verb is computed, not stored.** The notifier switches on `order.order_type` — `buy_article` / `buy_collection` resolve to `t(".bought")`, `reward_article` to `t(".rewarded")`. The body is the verb joined with `item.title` (for `Article`) or `item.name` (for `Collection`).
- **URL is item-typed.** `Article` orders anchor on `user_article_url(item.author, item.uuid)`; `Collection` orders anchor on `collection_url(item.uuid)` — the same split as the author-facing notifiers, so both parties deep-link to the same surface.
- **`data` mirrors `message`.** No `{ icon_url, title, description, action }` payload — `data` is set to `message` directly so the `PLAIN_TEXT` Mixin body is what the buyer sees. No icon, no tappable action; the URL is informational and lives on the notification record for the navbar bell.
- **Mixin predicate has no opt-out toggle.** `may_notify_via_mixin_bot?` is `recipient_messenger?` alone — it does **not** consult `recipient.notification_setting`. Every buyer with a linked Mixin Messenger account gets the receipt.

## Testing

The shared helpers live in [`test/support/notifier_helpers.rb`](../../test/support/notifier_helpers.rb):

- `deliver_notifier!(notifier_class, record:, recipient:, **params)` — wraps `notifier_class.with(record: record, **params).deliver(recipient)`.
- `notification_for(recipient)` — the most recently persisted notification; use it to assert message / url / data shape.
- `ensure_notification_setting!(user)` — creates a `NotificationSetting` on demand; most tests call it in `setup` to avoid the implicit `nil` from `belongs_to`.
- `with_mixin_bot_delivery_stub` — stubs `QuillBot.api.base_message_params` so Mixin delivery tests run without the network.

Notifier tests live under [`test/notifiers/`](../../test/notifiers/):

| Test file | Subject |
|-----------|---------|
| `application_notifier_test.rb` | Base predicates on `ApplicationNotifier` |
| `article_published_notifier_test.rb` | `ArticlePublishedNotifier` (web visibility, URL anchor, APP_CARD payload, mixin enqueue + opt-out) |
| `article_bought_notifier_test.rb` | `ArticleBoughtNotifier` |
| `article_rewarded_notifier_test.rb` | `ArticleRewardedNotifier` |
| `order_created_notifier_test.rb` | `OrderCreatedNotifier` (buy / reward / buy_collection message + URL anchoring, data mirrors message, mixin enqueue) |
| `comment_created_notifier_test.rb` | `CommentCreatedNotifier` |
| `comment_deleted_notifier_test.rb` | `CommentDeletedNotifier` |
| `tagging_created_notifier_test.rb` | `TaggingCreatedNotifier` |
| `user_connected_notifier_test.rb` | `UserConnectedNotifier` |
| `user_safe_registration_notifier_test.rb` | `UserSafeRegistrationNotifier` |
| `delivery_methods/mixin_bot_test.rb` | Bot resolution + payload shape |

For Mixin enqueueing, assert `assert_enqueued_jobs 1, only: Noticed::EventJob`, `perform_enqueued_jobs only: Noticed::EventJob`, then `assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot`. The article-purchased / rewarded / collection-bought path follows the same pattern.

## Adding a new notifier

Create `app/notifiers/<verb>_<subject>_notifier.rb` inheriting from `ApplicationNotifier`. Declare `required_param :thing` and the standard `deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot"` block, choosing `APP_CARD` for rich cards (article / collection / tagging) and `PLAIN_TEXT` for short notices. Override `notification_methods` to fill in `data`, `message`, `description` (cards only), `url`, and the `*_enabled?` predicates — reuse the `truncate(36)` / `truncate(72)` envelope for cards, or set `data = message` for plain-text.

Add i18n keys under `config/locales/notifications.<locale>.yml` → `notifiers.<your_notifier>.notification.*` (English copy is the source of truth). If a block should skip delivery, add `def should_notify? = !recipient.block_user? <source>` and route both `may_notify_via_web?` and `may_notify_via_mixin_bot?` through it (see `CommentCreatedNotifier`, `TaggingCreatedNotifier`). Finally, add a catalog row above and a test under `test/notifiers/` using the helpers in `test/support/notifier_helpers.rb`.
