# Notifiers reference

> **30-second summary:** 14 [Noticed](https://github.com/excid3/noticed) event classes under `app/notifiers/`, each fanning an event out to ActionCable + flash and a Mixin bot delivery, gated by `NotificationSetting`. Every kind is declared once in [`NotificationKind`](../../app/notifiers/notification_kind.rb); a notifier inherits from `ApplicationNotifier`, calls `notifies :the_kind`, declares its `required_param`, and supplies `notification_methods`.

## Kind registry

### `NotificationKind` — [`app/notifiers/notification_kind.rb`](../../app/notifiers/notification_kind.rb)

The single declaration of every notification kind. One entry carries the facts that are true for a whole kind:

| Field | Meaning |
|-------|---------|
| `category` | `:card` renders a Mixin `APP_CARD`, `:text` a plain message |
| `settings` | whether the recipient can mute the kind per channel (`web` / `mixin_bot`) |
| `web` | whether the kind ever surfaces in the web inbox |
| `bot` | the Mixin bot carrying the message (defaults to QuillBot) |
| `position` | where the kind sits in the settings form |

Derived from it: the `deliver_by :mixin_bot` config and delivery guards (`ApplicationNotifier`), the `noticed_notifications.web_visible` column, `NotificationSetting`'s store columns / defaults / casts, the settings strong params, and the settings form rows.

## Base class

### `ApplicationNotifier` — [`app/notifiers/application_notifier.rb`](../../app/notifiers/application_notifier.rb)

Inherits from `Noticed::Event` and derives everything shared by concrete notifiers:

- `notifies :the_kind` — looks the kind up in the registry, stores it as `notification_kind`, and installs the `deliver_by :mixin_bot` config (category, bot, `may_notify_via_mixin_bot?` guard).
- `recipient_attributes_for` — writes `web_visible` onto every `noticed_notifications` row from the kind plus the recipient's toggles, so the inbox is an indexed query and no reader re-derives visibility.
- `deliver_by :action_cable` and `deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast"` — broadcast over Solid Cable and surface a one-time flash banner; both gated by `web_visible? && message.present?`.
- `QUILL_ICON_URL` — the asset-path-resolved brand icon, used when a notifier has no natural icon (e.g. `TaggingCreatedNotifier`).
- `notification_methods` — `format_for_action_cable` (per-recipient locale), `message`, `url`, `icon_url`, `recipient_messenger?`, the derived guards (`may_notify_via_web?`, `may_notify_via_mixin_bot?`), and the `data` envelope (cards get the four `APP_CARD` keys from `title` / `description` / `icon_url` / `url`; text kinds send the bare message).

Concrete notifiers add `required_param` and override `notification_methods` for the event-specific content: `title`, `description`, `message`, `url`, `icon_url` and an optional `should_notify?` guard.

## Delivery methods

| Method | Path | Purpose |
|--------|------|---------|
| `:action_cable` (built-in) | — | Pushes the formatted message to the live UI; always-on unless `message` is blank. |
| `:flash_broadcast` | [`app/notifiers/delivery_methods/flash_broadcast.rb`](../../app/notifiers/delivery_methods/flash_broadcast.rb) | `notification.broadcast_as_flash` for one-time Rails flash messages. |
| `:mixin_bot` | [`app/notifiers/delivery_methods/mixin_bot.rb`](../../app/notifiers/delivery_methods/mixin_bot.rb) | Sends a Mixin Messenger message via `MixinMessages::SendJob`. Resolves bot, conversation id, category, and data from `config` and `notification.data`. |

`APP_CARD` payloads are rich cards (`icon_url`, `title`, `description`, `action` URL); `PLAIN_TEXT` payloads are short free-text notices. The card envelope is derived — a card kind supplies `title`, `description`, `icon_url` and `url`.

## Notifier catalog

The "Fires when" column names the trigger and recipient; the notifier class lives in `app/notifiers/<name>.rb`.

| Notifier | Param | Category | Fires when |
|----------|-------|----------|-----------|
| `ArticlePublishedNotifier` | `:article` | `APP_CARD` | Author publishes a draft (`notify_for_first_published`); notifies readers opted in to `article_published_*` |
| `ArticleBoughtNotifier` | `:order` | `APP_CARD` | Reader buys an article; notifies the **author** (buyer + title) |
| `ArticleRewardedNotifier` | `:order` | `APP_CARD` | Reader tips an article; notifies the **author** (tipper + title) |
| `CollectionListedNotifier` | `:collection` | `APP_CARD` | New collection published; notifies readers muted via `collection_listed_*` |
| `CollectionBoughtNotifier` | `:order` | `APP_CARD` | Reader buys a collection; notifies the **author** (buyer + collection name) |
| `CommentCreatedNotifier` | `:comment` | `APP_CARD` | Reader comments; notifies the **author** (skips if blocked). URL anchors to `#comment_<id>` |
| `TaggingCreatedNotifier` | `:tagging` | `APP_CARD` | Article tagged; notifies tag subscribers (`has_new_article` feed). Blocked-author checks apply |
| `SubscribeUserActionCreatedNotifier` | `:action` | `PLAIN_TEXT` | New subscriber follows a user; sends `subscribed` notice to the followed user |
| `OrderCreatedNotifier` | `:order` | `PLAIN_TEXT` | Buyer completes a paid order; `bought`/`rewarded` verb from `order.order_type`. Fires from `Order#notify_buyer` after author-facing notifiers — see [OrderCreatedNotifier shape](#ordercreatednotifier-shape) |
| `PaymentCreatedNotifier` | `:payment` | `PLAIN_TEXT` | Payment snapshot created (debugging / Mixin traceability) |
| `PaymentRefundedNotifier` | `:payment` | `PLAIN_TEXT` | Payment refunded; message includes `pre_order.item.title` for identification |
| `TransferProcessedNotifier` | `:transfer` | `APP_CARD` | Confirmed transfer arrives (author revenue, reader revenue, payment refund, or bonus); skips Mixin delivery if `from_quill_bot?` |
| `UserConnectedNotifier` | `:user` | `PLAIN_TEXT` | User connects Mixin Messenger bot for the first time. `web: false` — Mixin only, never in the web inbox |
| `UserSafeRegistrationNotifier` | `:user` | `PLAIN_TEXT` | User asked to update Mixin Messenger to receive transfers. `web: false` — Mixin bot only |

### `required_param` and `params`

`required_param :article` is the [Noticed](https://github.com/excid3/noticed) idiom that enforces the named key on `params`. Concrete notifiers expose it via `def article = params[:article]` (or `delegate :article, to: :tagging`). Reach for `params[:thing]` rather than storing records — that's the boundary that makes `NotifierHelpers#deliver_notifier!` work uniformly.

### Web vs Mixin opt-out

- `web_notification_enabled?` / `mixin_bot_notification_enabled?` are derived: kinds without settings are always on, kinds with settings read the matching `*_web` / `*_mixin_bot` boolean on `recipient.notification_setting`. A recipient with no preferences row at all has not opted out of anything.
- `may_notify_via_mixin_bot?` combines `recipient_messenger?` with `mixin_bot_notification_enabled?`; used by the `if:` lambda on `deliver_by :mixin_bot`.
- `should_notify?` — extra guard for blocking (see `CommentCreatedNotifier`, `TaggingCreatedNotifier`); both derived predicates AND it in.

### `data` shape

`APP_CARD` notifiers share this hash contract:

```ruby
{
  icon_url:,
  title: <subject>.truncate(36),
  description: description.truncate(72),
  action: url
}
```

`TransferProcessedNotifier` adds `shareable: false` (deep-links to a Mixin snapshot). `action` URL varies by type: `user_article_url(author, uuid)` for articles, `collection_url(uuid)` for collections, `https://mixin.one/snapshots/<id>` for transfers.

### I18n

Strings live in [`config/locales/notifications.<locale>.yml`](../../config/locales/) under `notifiers.<name>.notification.<key>`. Notifiers call `t(".published")` / `t(".bought")` — locale resolves per-recipient (see `format_for_action_cable` and `I18n.with_locale` in `DeliveryMethods::MixinBot#deliver`).

### OrderCreatedNotifier shape

`OrderCreatedNotifier` is the buyer-facing complement to the author-facing notifiers. `Order#notify` runs `notify_subscribers` first, then `notify_buyer`, so authors see the sale before buyers see the receipt. Four behaviours set it apart:

- **Verb is computed, not stored.** `order.order_type` → `t(".bought")` (for `buy_article` / `buy_collection`) or `t(".rewarded")` (for `reward_article`). Body is the verb joined with `item.title` (Article) or `item.name` (Collection).
- **URL is item-typed.** `Article` orders → `user_article_url(item.author, item.uuid)`; `Collection` orders → `collection_url(item.uuid)`.
- **`data` mirrors `message`.** No card payload — `data = message`, so the URL is informational only.
- **Mixin predicate has no opt-out.** `may_notify_via_mixin_bot?` is `recipient_messenger?` alone — every buyer with a linked Mixin account gets the receipt.

## Testing

Shared helpers in [`test/support/notifier_helpers.rb`](../../test/support/notifier_helpers.rb):

- `deliver_notifier!(notifier_class, record:, recipient:, **params)` — wraps `notifier_class.with(record: record, **params).deliver(recipient)`.
- `notification_for(recipient)` — the most recently persisted notification; use it to assert message / url / data shape.
- `ensure_notification_setting!(user)` — creates a `NotificationSetting` on demand to avoid `nil` from `belongs_to`.
- `with_mixin_bot_delivery_stub` — stubs `QuillBot.api.base_message_params` so Mixin delivery tests run without the network.

Notifier tests live under [`test/notifiers/`](../../test/notifiers/), one file per row in the catalog above (e.g. `article_published_notifier_test.rb` covers `ArticlePublishedNotifier`). `test/notifiers/delivery_methods/mixin_bot_test.rb` covers bot resolution and payload shape.

For Mixin enqueueing, the bought / rewarded / collection-bought paths share this assertion sequence: `assert_enqueued_jobs 1, only: Noticed::EventJob`, `perform_enqueued_jobs only: Noticed::EventJob`, then `assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot`.

## Adding a new notifier

Create `app/notifiers/<verb>_<subject>_notifier.rb` inheriting from `ApplicationNotifier` with `required_param :thing` and a `deliver_by :mixin_bot` block. Override `notification_methods` to fill in `data`, `message`, `description` (cards only), `url`, and `*_enabled?` predicates — reuse the `truncate(36)` / `truncate(72)` envelope for `APP_CARD`, or `data = message` for `PLAIN_TEXT`. Also add:

- i18n keys under `config/locales/notifications.<locale>.yml` → `notifiers.<your_notifier>.notification.*`
- A `should_notify?` guard that both `may_notify_via_web?` and `may_notify_via_mixin_bot?` route through, for any delivery-skip logic
- A catalog row above and a test under `test/notifiers/` using the helpers above
