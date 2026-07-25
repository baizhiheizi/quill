# Notifiers reference

> **30-second summary:** [Noticed](https://github.com/excid3/noticed) event classes under `app/notifiers/`. Each fans an event out to delivery methods (ActionCable + flash, Mixin bot) gated by `NotificationSetting`. All 18 notifiers inherit from `ApplicationNotifier` and declare their params, delivery methods, and payload helpers.

## Base class

### `ApplicationNotifier` — [`app/notifiers/application_notifier.rb`](../../app/notifiers/application_notifier.rb)

Inherits from `Noticed::Event` and sets the defaults for every concrete notifier:

- `class_attribute :persist_web_notification, default: true` — persists to the `notifications` table; set `false` for real-time-only notifiers (e.g. `UserConnectedNotifier`, `UserSafeRegistrationNotifier`).
- `deliver_by :action_cable` — broadcasts the formatted message over Solid Cable so the navbar bell updates live; gated by `visible_in_web? && message.present?`.
- `deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast"` — surfaces a one-time Rails flash banner under the same gate.
- `QUILL_ICON_URL` — the asset-path-resolved brand icon, reused when a notifier has no natural icon (e.g. `TaggingCreatedNotifier`).
- `notification_methods` — helpers: `format_for_action_cable`, `message`, `url`, `icon_url`, `recipient_messenger?` (guard for linked Mixin accounts).

Concrete notifiers add `required_param`, a `deliver_by :mixin_bot` block, and override `notification_methods` for event-specific data.

## Delivery methods

| Method | Path | Purpose |
|--------|------|---------|
| `:action_cable` (built-in) | — | Pushes the formatted message to the live UI. Always-on unless `message` is blank. |
| `:flash_broadcast` | [`app/notifiers/delivery_methods/flash_broadcast.rb`](../../app/notifiers/delivery_methods/flash_broadcast.rb) | `notification.broadcast_as_flash` for one-time Rails flash messages. |
| `:mixin_bot` | [`app/notifiers/delivery_methods/mixin_bot.rb`](../../app/notifiers/delivery_methods/mixin_bot.rb) | Sends a Mixin Messenger message via `MixinMessages::SendJob`. Resolves the bot to `RevenueBot` (when `config[:bot] == "RevenueBot"` and `RevenueBot.api` is configured) or `QuillBot` otherwise. Sets the conversation id from `recipient.mixin_uuid`, the category from `config[:category] || "PLAIN_TEXT"`, and the data from `config[:data] || notification.data`. |

`APP_CARD` payloads are rich cards (`icon_url`, `title`, `description`, `action` URL); `PLAIN_TEXT` payloads are short free-text notices. Keep the four card keys in `notification_methods#data` in sync with the bot client.

## Notifier catalog

| Group | Notifier | Required param | Category | Fires when |
|-------|----------|----------------|----------|-----------|
| Articles | `ArticlePublishedNotifier` | `:article` | `APP_CARD` | Author publishes a draft (`notify_for_first_published`). Notifies readers with `article_published_web` / `article_published_mixin_bot` enabled. |
| Articles | `ArticleBoughtNotifier` | `:order` | `APP_CARD` | Reader buys an article. Notifies the **author** with buyer's name and article title. |
| Articles | `ArticleRewardedNotifier` | `:order` | `APP_CARD` | Reader tips an article. Notifies the **author** with tipper's name and article title. |
| Collections | `CollectionListedNotifier` | `:collection` | `APP_CARD` | New collection published. Notifies readers opted in to `article_published_*` (same toggle drives collection listings). |
| Collections | `CollectionBoughtNotifier` | `:order` | `APP_CARD` | Reader buys a collection. Notifies the **author** with buyer's name and collection name. |
| Comments | `CommentCreatedNotifier` | `:comment` | `APP_CARD` | Reader comments on an article. Notifies the **author** (skips if blocked). URL anchors to `#comment_<id>`. |
| Comments | `CommentDeletedNotifier` | `:comment` | `PLAIN_TEXT` | Admin deletes a comment. Notifies the **commenter**. |
| Tags & subscriptions | `TaggingCreatedNotifier` | `:tagging` | `APP_CARD` | Article tagged. Notifies tag subscribers (`has_new_article` feed). Blocked-author checks apply. |
| Tags & subscriptions | `SubscribeUserActionCreatedNotifier` | `:action` | `PLAIN_TEXT` | New subscriber follows a user. Sends `subscribed` notice to the followed user. |
| Orders & payments | `OrderCreatedNotifier` | `:order` | `PLAIN_TEXT` | Buyer completes a paid order. Confirmation to the **buyer**; verb (`bought`/`rewarded`) picked from `order.order_type`. Fires from `Order#notify_buyer` after author-facing notifiers. |
| Orders & payments | `PaymentCreatedNotifier` | `:payment` | `PLAIN_TEXT` | Payment snapshot created (debugging / Mixin traceability). |
| Orders & payments | `PaymentRefundedNotifier` | `:payment` | `PLAIN_TEXT` | Payment refunded. Message includes `pre_order.item.title` for identification. |
| Transfers & accounts | `TransferProcessedNotifier` | `:transfer` | `APP_CARD` | Confirmed transfer arrives (author revenue, reader revenue, payment refund, or bonus). Skips Mixin delivery if `from_quill_bot?`. |
| Transfers & accounts | `UserConnectedNotifier` | `:user` | `PLAIN_TEXT` | User connects Mixin Messenger bot for the first time. `persist_web_notification = false` (one-time greeting). |
| Transfers & accounts | `UserSafeRegistrationNotifier` | `:user` | `PLAIN_TEXT` | User asked to update Mixin Messenger to receive transfers. `persist_web_notification = false`; Mixin bot only. |

## Patterns to know

### `required_param` and `params`

`required_param :article` is the [Noticed](https://github.com/excid3/noticed) idiom that enforces the named key on `params`. Concrete notifiers expose it via a helper — `def article = params[:article]` or `delegate :article, to: :tagging`. Always reach for `params[:thing]` rather than storing records; the params hash is the boundary that makes `NotifierHelpers#deliver_notifier!` work uniformly.

### Web vs Mixin opt-out

Most notifiers expose predicates that combine in the delivery block:

- `web_notification_enabled?` / `mixin_bot_notification_enabled?` — read the matching `*_web` / `*_mixin_bot` boolean on `recipient.notification_setting`.
- `may_notify_via_mixin_bot?` — `recipient_messenger? && mixin_bot_notification_enabled?`; called by the `if:` lambda on `deliver_by :mixin_bot`.
- `should_notify?` — extra guard for blocking (see `CommentCreatedNotifier`, `TaggingCreatedNotifier`). When defined, also expose `may_notify_via_web?` that ANDs the guard in.

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

`TransferProcessedNotifier` adds `shareable: false` (deep-links to a Mixin snapshot). The `action` URL varies by type: `user_article_url(author, uuid)` for articles, `collection_url(uuid)` for collections, `https://mixin.one/snapshots/<id>` for transfers.

### I18n

User-facing strings live in [`config/locales/notifications.<locale>.yml`](../../config/locales/) under `notifiers.<name>.notification.<key>`. Notifiers call `t(".published")` / `t(".bought")` — locale resolves per-recipient (see `format_for_action_cable` and `I18n.with_locale` in `DeliveryMethods::MixinBot#deliver`).

### OrderCreatedNotifier shape

`OrderCreatedNotifier` is the buyer-facing complement to the author-facing notifiers. `Order#notify` runs `notify_subscribers` first, then `notify_buyer`, so authors see the sale before buyers see the receipt. Four behaviours set it apart:

- **Verb is computed, not stored.** Switches on `order.order_type` — `buy_article` / `buy_collection` → `t(".bought")`, `reward_article` → `t(".rewarded")`. Body is the verb joined with `item.title` (Article) or `item.name` (Collection).
- **URL is item-typed.** `Article` orders anchor on `user_article_url(item.author, item.uuid)`; `Collection` orders on `collection_url(item.uuid)` — same split as author-facing notifiers.
- **`data` mirrors `message`.** No card payload — `data` is set to `message` directly. The URL is informational on the notification record; no icon or tappable action.
- **Mixin predicate has no opt-out toggle.** `may_notify_via_mixin_bot?` is `recipient_messenger?` alone — it does **not** check `notification_setting`. Every buyer with a linked Mixin account gets the receipt.

## Testing

Shared helpers in [`test/support/notifier_helpers.rb`](../../test/support/notifier_helpers.rb):

- `deliver_notifier!(notifier_class, record:, recipient:, **params)` — wraps `notifier_class.with(record: record, **params).deliver(recipient)`.
- `notification_for(recipient)` — the most recently persisted notification; use it to assert message / url / data shape.
- `ensure_notification_setting!(user)` — creates a `NotificationSetting` on demand to avoid `nil` from `belongs_to`.
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

For Mixin enqueueing: `assert_enqueued_jobs 1, only: Noticed::EventJob`, `perform_enqueued_jobs only: Noticed::EventJob`, then `assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot`. The article-purchased / rewarded / collection-bought path follows the same pattern.

## Adding a new notifier

Create `app/notifiers/<verb>_<subject>_notifier.rb` inheriting from `ApplicationNotifier`. Declare `required_param :thing` and a `deliver_by :mixin_bot` block, choosing `APP_CARD` for rich cards or `PLAIN_TEXT` for short notices. Override `notification_methods` to fill in `data`, `message`, `description` (cards only), `url`, and `*_enabled?` predicates — reuse the `truncate(36)` / `truncate(72)` envelope for cards, or set `data = message` for plain-text.

Add i18n keys under `config/locales/notifications.<locale>.yml` → `notifiers.<your_notifier>.notification.*`. For delivery skip logic, add `should_notify?` and route both `may_notify_via_web?` and `may_notify_via_mixin_bot?` through it (see patterns above). Add a catalog row and a test under `test/notifiers/` using the helpers in `test/support/notifier_helpers.rb`.
