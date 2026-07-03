# Contracts: Cross-Locale Article Visibility

**Feature**: Cross-Locale Article Visibility
**Spec**: `specs/001-unified-article-translations/spec.md`
**Date**: 2026-07-03

This feature is a Rails web application change. The "contracts" are the public interface surfaces that the change touches (controllers, services, view partials). No external API or library is added or modified.

## Contracts

| Contract | File | Status | Notes |
|---|---|---|---|
| `ArticleSearchService.call(...)` | `app/services/article_search_service.rb` | Modified | Drops `locale:` kwarg; `#localize` method removed |
| `ArticlesController#index` | `app/controllers/articles_controller.rb` | Modified | Drops `locale: current_locale` from service call |
| `HomeController#selected_articles` | `app/controllers/home_controller.rb` | Modified | Drops `locale: current_locale` from service call |
| `HomeController#hot_tags` | `app/controllers/home_controller.rb` | Modified | Drops `where(locale:)`; cache key changes |
| `HomeController#active_authors` | `app/controllers/home_controller.rb` | Modified | Drops `where(locale:)` |
| `ArticlesController#show` | `app/controllers/articles_controller.rb` | Unchanged | No locale filter today |
| `LocalesController#show / #create` | `app/controllers/locales_controller.rb` | Unchanged | UI chrome only |
| `Admin::ArticlesController#index` | `app/controllers/admin/articles_controller.rb` | Unchanged | Admin filter preserved |
| `API::ArticlesController#index / #show` | `app/controllers/api/articles_controller.rb` | Unchanged | No locale filter today |
| `API::BaseController#with_locale` | `app/controllers/api/base_controller.rb` | Unchanged | Pins `:en` for API chrome |
| `ApplicationController#with_locale / #current_locale` | `app/controllers/application_controller.rb` | Unchanged | Resolution chain preserved |
| `Localizable#browser_locale` | `app/controllers/concerns/localizable.rb` | Unchanged | |
| `Article#to_param` | `app/models/article.rb` | Unchanged | Still returns `uuid` |
| `Article#detected_locale / detect_locale` | `app/models/article.rb` | Unchanged | CLD detection preserved |
| `Articles::DetectLocaleJob` | `app/jobs/articles/detect_locale_job.rb` | Unchanged | Runs on content change |
| `Article#related_articles` | `app/models/article.rb:290-313` | Unchanged | Already locale-unaware |
| `ArticleSnapshot` | `app/models/article_snapshot.rb` | Unchanged | Snapshots `article.as_json` |
| `ApplicationNotifier#format_for_action_cable` | `app/notifiers/application_notifier.rb` | Unchanged | Wraps in `I18n.with_locale(recipient.locale)` |
| `DeliveryMethods::MixinBot#deliver` | `app/notifiers/delivery_methods/mixin_bot.rb` | Unchanged | Wraps in `I18n.with_locale(recipient.locale)` |
| View: `articles/_card.html.erb` | `app/views/articles/_card.html.erb` | Modified | Adds language chip |
| View: `articles/_header.html.erb` | `app/views/articles/_header.html.erb` | Modified | Adds language indicator |
| View: `admin/articles/_article.html.erb` | `app/views/admin/articles/_article.html.erb` | Unchanged | Already shows `article.locale` |
| Routes: `/articles/:uuid`, `/:uid/:uuid`, `/<locale>`, `/hot_tags`, `/active_authors`, `/selected_articles`, `/more` | `config/routes.rb` | Unchanged | All preserved |
| Routes: `/admin/articles` with locale filter | `config/routes.rb` (admin) | Unchanged | Admin filter preserved |

## Detailed Contract: `ArticleSearchService.call`

### Before

```ruby
ArticleSearchService.call(
  filter: params[:filter],          # one of: revenue / lately / subscribed / bought / nil
  query: params[:query],
  tag: params[:tag],
  time_range: params[:time_range],
  locale: current_locale,            # <-- REMOVED
  current_user: current_user
)
```

Internally, the service stored `params[:locale]` as `@locale` and applied `.where(locale: ...)` via the `#localize` method unless the call had a `query:` or `tag:` or `filter` was `subscribed`/`bought`.

### After

```ruby
ArticleSearchService.call(
  filter: params[:filter],
  query: params[:query],
  tag: params[:tag],
  time_range: params[:time_range],
  current_user: current_user
)
```

`params[:locale]` is no longer accepted. The service does not call `#localize`. The `current_locale` of the caller is irrelevant to the result set.

### Compatibility

- **Backwards-incompatible**: callers passing `locale:` will see a Ruby keyword argument warning (since Ruby 3.0). Both production callers (`ArticlesController#index` and `HomeController#selected_articles`) are updated in the same change. No third-party callers — the service is internal to the Rails app.

## Detailed Contract: `HomeController#hot_tags`

### Before

```ruby
def hot_tags
  @hot_tags =
    Rails.cache.fetch "#{current_locale}_hot_tags", expires_in: 5.minutes do
      Tag
        .hot
        .where(locale: current_locale.to_s.split("-").first)   # locale filter
        .order(Arel.sql("RANDOM()"))
        .limit(5)
        .to_a
    end
end
```

Cache key was `"#{current_locale}_hot_tags"` (per-locale). Cache payload was 5 tags from one locale.

### After

```ruby
def hot_tags
  @hot_tags =
    Rails.cache.fetch "hot_tags", expires_in: 5.minutes do
      Tag
        .hot
        .order(Arel.sql("RANDOM()"))
        .limit(5)
        .to_a
    end
end
```

Cache key is `"hot_tags"` (process-wide). Cache payload is 5 tags from the platform-wide hot set.

### Compatibility

- Cache: existing per-locale keys (`en_hot_tags`, `zh-CN_hot_tags`, `ja_hot_tags`) become stale and expire after 5 minutes. No explicit invalidation needed — the new key is fresh. To be safe, `Rails.cache.delete_matched("*_hot_tags")` can be run at deploy time, but it is not required.

## Detailed Contract: View Partial — `app/views/articles/_card.html.erb`

### Before

Card renders `article.title`, `article.author`, `article.intro`, `article.cover`, etc. No locale display.

### After

Same as before plus a small language chip rendered near the title or in a corner of the card:

```erb
<span class="article-card__locale" title="<%= I18n.t('languages.' + article.locale, default: article.locale&.upcase) %>">
  <%= article.locale&.upcase %>
</span>
```

The chip:
- Shows the uppercase 2-letter locale code (e.g., `ZH`, `EN`, `JA`).
- Has a `title` attribute with the human-readable language name (`中文`, `English`, `日本語`).
- Is hidden when `article.locale` is blank (defensive — admin shows them under `Others`).

## Compatibility Summary

- **HTTP routes**: identical. No 301/302 redirects needed; all old URLs continue to work.
- **HTML structure**: additive (chip on card + indicator on header). Existing CSS, JS, and Stimulus controllers remain valid.
- **JSON API**: identical.
- **Database schema**: identical.
- **Cache shape**: minor change to `hot_tags` key only.
- **I18n**: chrome unchanged. No new translations required for the chrome itself (chip uses existing `article.locale`).