# Notifiers reference

> **30-second summary:** Notifiers are [Noticed](https://github.com/excid3/noticed) event classes under `app/notifiers/`. Each notifier fans an event out to one or more delivery methods — web (ActionCable + flash), and the Mixin Messenger bot — gated by the recipient's `NotificationSetting`. There are 18 notifiers; every concrete notifier inherits from `ApplicationNotifier` and declares its required params, its delivery methods, and the helpers that build the message/data payload.

## Base class

### `ApplicationNotifier` — [`app/notifiers/application_notifier.rb`](../../app/notifiers/application_notifier.rb)

Inherits from `Noticed::Event` and sets the defaults for every concrete notifier:

- `class_attribute :persist_web_notification, default: true` — persist to the `notifications` table; set `false` for real-time-only notifiers (e.g. `UserConnectedNotifier`, `UserSafeRegistrationNotifier`).
- `deliver_by :action_cable` — always pushes the formatted message over Solid Cable so the navbar bell updates live; gated by `visible_in_web? && message.present?`.
- `deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast"` — surfaces a one-time flash banner with the same gate.
- `QUILL_ICON_URL` — brand icon for notifiers without a natural one (e.g. `TaggingCreatedNotifier`).
- `notification_methods` — shared helpers: `format_for_action_cable`, `message`, `url`, `icon_url`, and `recipient_messenger?` (the standard "recipient has a Mixin Messenger account linked" guard).

Concrete notifiers add their own `required_param`, a `deliver_by :mixin_bot` block, and `notification_methods` overrides for event-specific data.

## Delivery methods

| Method | Path | Purpose |
|--------|------|---------|
| `:action_cable` (built-in) | — | Pushes the formatted message to the live UI. Always-on unless `message` is blank. |
| `:flash_broadcast` | [`app/notifiers/delivery_methods/flash_broadcast.rb`](../../app/notifiers/delivery_methods/flash_broadcast.rb) | `notification.broadcast_as_flash` for one-time Rails flash messages. |
| `:mixin_bot` | [`app/notifiers/delivery_methods/mixin_bot.rb`](../../app/notifiers/delivery_methods/mixin_bot.rb) | Sends a Mixin Messenger message via `MixinMessages::SendJob`. Resolves the bot to `RevenueBot` (when `config[:bot] == "RevenueBot"` and `RevenueBot.api` is configured) or `QuillBot` otherwise. Conversation id comes from `recipient.mixin_uuid`; category from `config[:category] \|\| "PLAIN_TEXT"`; data from `config[:data] \|\| notification.data`. |

Payload shape is contractually defined by the bot client: `APP_CARD` is a rich card (`icon_url`, `title`, `description`, `action`); `PLAIN_TEXT` is a short free-text notice. Keep the four card keys in `notification_methods#data` in sync with the bot.

## Notifier catalog

### Articles

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `ArticlePublishedNotifier` | `:article` | `APP_CARD` | An author publishes a draft (`notify_for_first_published`). Reaches readers with `article_published_web` / `article_published_mixin_bot` enabled. |
| `ArticleBoughtNotifier` | `:order` | `APP_CARD` | A reader buys an article — author gets a card with the buyer's name and title. |
| `ArticleRewardedNotifier` | `:order` | `APP_CARD` | A reader tips an article after the fact — author gets a card with the tipper's name and title. |

### Collections

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `CollectionListedNotifier` | `:collection` | `APP_CARD` | A new collection is published (reuses the `article_published_*` opt-in toggle). |
| `CollectionBoughtNotifier` | `:order` | `APP_CARD` | A reader buys a collection — author gets a card with the buyer's name and collection name. |

### Comments

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `CommentCreatedNotifier` | `:comment` | `APP_CARD` | A reader comments on an article. Author card is skipped if they have blocked the commenter. URL anchors to `#comment_<id>`. |
| `CommentDeletedNotifier` | `:comment` | `PLAIN_TEXT` | An admin deletes a comment — the **commenter** is told it is gone. |

### Tags and subscriptions

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `TaggingCreatedNotifier` | `:tagging` | `APP_CARD` | An article is tagged. Reaches tag-feed subscribers (`has_new_article`); blocked-author checks apply. |
| `SubscribeUserActionCreatedNotifier` | `:action` | `PLAIN_TEXT` | A new subscriber follows a user — the followed user gets a `subscribed` notice. |

### Orders and payments

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `OrderCreatedNotifier` | `:order` | `PLAIN_TEXT` | A buy/reward completes; confirmation to the buyer. Verb (`bought` vs `rewarded`) comes from `order.order_type`. |
| `PaymentCreatedNotifier` | `:payment` | `PLAIN_TEXT` | A payment snapshot is created (debugging / Mixin traceability). |
| `PaymentRefundedNotifier` | `:payment` | `PLAIN_TEXT` | A payment is refunded; the message interpolates `pre_order.item.title` so the buyer can identify the original purchase. |

### Swap orders

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `SwapOrderSwappingNotifier` | `:swap_order` | `PLAIN_TEXT` | A swap order starts — sends the in-flight `pay_asset -> fill_asset` pair. |
| `SwapOrderFinishedNotifier` | `:swap_order` | `PLAIN_TEXT` | A swap order ends. `completed`/`refunded` produce a swapped summary; `rejected` produces a rejection notice. |

### Transfers and accounts

| Notifier | Required param | Category | Fires when |
|----------|----------------|----------|-----------|
| `TransferProcessedNotifier` | `:transfer` | `APP_CARD` | A confirmed transfer (author revenue, reader revenue, payment refund, bonus, swap change, or swap refund). Skips Mixin delivery when `from_quill_bot?` is true. |
| `UserConnectedNotifier` | `:user` | `PLAIN_TEXT` | A user connects the Mixin Messenger bot for the first time. `persist_web_notification = false` (one-time greeting). |
| `UserSafeRegistrationNotifier` | `:user` | `PLAIN_TEXT` | A user is asked to update Mixin Messenger to receive transfers. `persist_web_notification = false`; Mixin bot only. |

## Patterns to know

### `required_param` and `params`

`required_param :article` (or `:order`, `:comment`, etc.) is the [Noticed](https://github.com/excid3/noticed) idiom that enforces the presence of the named key on the notifier's `params`. Concrete notifiers re-expose it with a `notification_methods` helper — typically `def article = params[:article]` or `delegate :article, to: :tagging`. The params hash is the boundary that makes `NotifierHelpers#deliver_notifier!` work uniformly, so always reach for `params[:article]` rather than storing the record on the notifier directly.

### Web vs Mixin opt-out

Most notifiers expose a few predicates and combine them in the delivery block:

- `web_notification_enabled?` / `mixin_bot_notification_enabled?` — read the matching `*_web` / `*_mixin_bot` boolean on `recipient.notification_setting`.
- `may_notify_via_mixin_bot?` — ANDs `recipient_messenger?` with `mixin_bot_notification_enabled?`; this is what the `if:` lambda on `deliver_by :mixin_bot` calls.
- `should_notify?` — extra guard for blocking-style opt-outs (used by `CommentCreatedNotifier` and `TaggingCreatedNotifier`). When defined, expose a matching `may_notify_via_web?` that ANDs the guard in.

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

All user-facing strings live in [`config/locales/notifications.<locale>.yml`](../../config/locales/) under `notifiers.<notifier_name>.notification.<key>`. Notifiers call `t(".published")` / `t(".bought")` so the locale resolves per-recipient (see `format_for_action_cable` and the `I18n.with_locale` wrapper in `DeliveryMethods::MixinBot#deliver`).

## Testing

Shared helpers live in [`test/support/notifier_helpers.rb`](../../test/support/notifier_helpers.rb):

- `deliver_notifier!(notifier_class, record:, recipient:, **params)` — wraps `notifier_class.with(record: record, **params).deliver(recipient)`.
- `notification_for(recipient)` — returns the most recently persisted notification for that recipient; assert message/url/data shape against it.
- `ensure_notification_setting!(user)` — creates a `NotificationSetting` on demand; most tests call this in `setup` to avoid the implicit `nil` from `belongs_to`.
- `with_mixin_bot_delivery_stub` — stubs `QuillBot.api.base_message_params` so Mixin delivery tests run offline.

Notifier tests live under [`test/notifiers/`](../../test/notifiers/), one file per notifier, plus `application_notifier_test.rb` (base predicates) and `delivery_methods/mixin_bot_test.rb` (bot resolution + payload shape). To assert Mixin enqueueing: `assert_enqueued_jobs 1, only: Noticed::EventJob`, then `perform_enqueued_jobs only: Noticed::EventJob`, then `assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot`. The article-purchased / rewarded / collection-bought path uses the same pattern.

## Adding a new notifier

1. Place the file at `app/notifiers/<verb>_<subject>_notifier.rb`, inheriting from `ApplicationNotifier`.
2. Declare `required_param :thing` and the standard `deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot"` block. Pick `APP_CARD` for rich cards (article / collection / tagging), `PLAIN_TEXT` for short notices.
3. Override `notification_methods` to fill in `data`, `message`, `description` (cards only), `url`, and the `*_enabled?` predicates. Cards re-use the `truncate(36)` / `truncate(72)` envelope; plain-text notifiers can set `data` to `message` directly.
4. Add i18n keys under `config/locales/notifications.<locale>.yml` → `notifiers.<your_notifier>.notification.*` (English is the source of truth; the other locales mirror the shape).
5. If the recipient should not see the event when they have blocked the source user, add `def should_notify? = !recipient.block_user? <source>` and route both `may_notify_via_web?` and `may_notify_via_mixin_bot?` through it (see `CommentCreatedNotifier` and `TaggingCreatedNotifier`).
6. Add a row to the catalog above and a test file under `test/notifiers/`, using the helpers in `test/support/notifier_helpers.rb` to avoid the boilerplate.
