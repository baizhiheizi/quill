# Data Model: Cross-Locale Article Visibility

**Feature**: Cross-Locale Article Visibility
**Spec**: `specs/001-unified-article-translations/spec.md`
**Date**: 2026-07-03

## Schema Impact

**No schema changes.** This feature is contained to controller, service, and view layers. The `articles`, `users`, and `tags` tables are untouched. No new tables, columns, indexes, or constraints.

## Unchanged Entities

### Article (unchanged)

```
articles (db/schema.rb:108-141)
├── id                  :bigint, PK
├── uuid                :string, unique
├── title               :string              [still here; not used for locale branching]
├── intro               :string
├── content             :Action Text         [unchanged; rendered the same regardless of viewer locale]
├── legacy_markdown_content :text
├── author_id           :bigint, FK -> users
├── collection_id       :string, nullable
├── asset_id            :string
├── price               :decimal
├── state               :string (drafted/published/hidden/blocked)
├── published_at        :datetime
├── readers_revenue_ratio   :decimal
├── platform_revenue_ratio  :decimal
├── author_revenue_ratio    :decimal
├── collection_revenue_ratio: decimal
├── references_revenue_ratio: decimal
├── free_content_ratio      :decimal
├── revenue_usd         :decimal
├── revenue_btc         :decimal
├── source              :string
├── locale              :string              [KEPT — used by admin filter and card display]
├── orders_count        :integer (counter cache)
├── comments_count      :integer (counter cache)
├── upvotes_count       :integer (counter cache)
├── downvotes_count     :integer (counter cache)
├── tags_count          :integer (counter cache)
├── commenting_subscribers_count :integer (counter cache)
└── created_at / updated_at
```

`articles.locale` retains its current behavior: populated by `Article#detected_locale` (CLD-based, lines 315-336) on save, refreshed asynchronously by `Articles::DetectLocaleJob` when content changes. The column is **not** used as a visitor-facing filter after this change; it remains available for admin filtering, card/header display, and back-office analytics.

### User (unchanged)

`users.locale` retains its current behavior: editable by the user via `enumerize :locale` (`app/models/user.rb:88`), used by `current_locale` resolution (`app/controllers/application_controller.rb:60-72`) for I18n chrome only. Not used as a visitor-facing article-visibility filter.

### Tag (unchanged)

`tags.locale` retains its current behavior: populated by `Tag#detect_locale` (`app/models/tag.rb:43-57`) via CLD on tag-name. Not used as a visitor-facing article-visibility filter after this change. Admin still sees it; consumer-side locale filter on `Tag.hot` is removed.

## Locale Preference Resolution (visitor-side, unchanged)

The visitor's preferred locale is resolved by `ApplicationController#current_locale` (`app/controllers/application_controller.rb:60-72`) in this priority order:

1. `session[:current_locale]` — set via `LocalesController#show` after the visitor clicks a language link (`/en`, `/zh-CN`, `/ja`).
2. `current_user.locale` — set on the user record via the user's profile (enumerized in `I18n.available_locales`).
3. `browser_locale` — parsed by `Localizable#browser_locale` (`app/controllers/concerns/localizable.rb:8-36`) from `Accept-Language`.
4. `I18n.default_locale` — `:en`.

This preference is wrapped around the request by `ApplicationController#with_locale` (line 17 around_action, lines 60-64 method). After this change, the preference drives only **UI chrome** (button labels, navigation, `<html lang>`, notification message bodies). It no longer drives article visibility.

## Behavior Changes (data-side, by entity)

### Article

- **Read path**: unchanged. The same `Article` row is returned to any visitor regardless of their `current_locale`. No locale-based `WHERE` clause is added at the service layer.
- **Write path**: unchanged. `Article#detected_locale` runs as today; `Articles::DetectLocaleJob` runs as today; `articles.locale` continues to be populated.
- **Display path**: NEW — the article's `locale` is rendered as a small chip on `_card.html.erb` and on `_header.html.erb`. The existing admin display at `app/views/admin/articles/_article.html.erb:12` is unchanged.

### User

- **Read path**: unchanged. `User#locale` is read by `ApplicationController#current_locale` exactly as today.
- **Write path**: unchanged.
- **Display path**: unchanged on visitor surfaces. `app/views/admin/users/_user.html.erb:9` continues to display `user.locale.presence || '-'`.

### Tag

- **Read path on home page**: changed. `Tag.hot` is no longer constrained by `tags.locale`; it returns the platform-wide hot tags regardless of visitor locale.
- **Read path on admin**: unchanged. `tags.locale` is still visible in admin and used for sorting/filtering.
- **Write path**: unchanged.

## Validation Rules (unchanged)

- `articles.locale` is a free-form string (CLD output, up to ~5 chars; today typically `en` / `zh` / `ja`). No `NOT NULL` constraint; existing nulls are tolerated (admin filter surfaces them under `Others`).
- `users.locale` is `enumerize`-constrained to `I18n.available_locales` (`en`, `zh-CN`, `ja`).
- `tags.locale` is a free-form string (CLD output).

## Lifecycle / State Transitions (unchanged)

- `Article` state machine: `drafted → published → hidden → blocked` (with `unblock :blocked → :hidden`). No new states.
- `User` and `Tag` have no state machines.
- `ArticleTranslation` does not exist; nothing to maintain.

## Caching Impact

- `Rails.cache.fetch "#{current_locale}_hot_tags", ...` (`app/controllers/home_controller.rb:23`) — key changes to `"hot_tags"`. Cache payload is the same shape (5 records); cache duration unchanged at 5 minutes.
- No other cache keys change. `Rails.cache.fetch` for `current_user.locale` and I18n locale resolution are untouched.

## Index / Constraint Changes

None.

## Migration Plan

None. Deploy = `git pull && bin/rails restart`.