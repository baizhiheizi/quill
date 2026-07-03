# Research: Cross-Locale Article Visibility

**Feature**: Cross-Locale Article Visibility
**Spec**: `specs/001-unified-article-translations/spec.md`
**Date**: 2026-07-03

## Decisions

### D1: No schema change required

**Decision**: The change is entirely contained in the controller/service/view layers. No Active Record migrations, no column adds, no model changes.

**Rationale**: The existing `articles.locale` column is CLD-detected on save (via `Articles::DetectLocaleJob`) and consumed today by: (a) admin filter, (b) `article.locale` display in admin row. Both consumers stay. The `localize` filter on `ArticleSearchService` is the only consumer we are removing — and that is service-layer code, not a column. The `tags.locale` and `users.locale` columns are also retained; only their consumer (the home-page filter) is removed.

**Alternatives considered**:
- Drop `articles.locale` entirely — rejected. Admin still uses it for the `EN / ZH / JA / Others` filter (FR-008). Dropping it would force admin moderators to lose an important back-office tool.
- Migrate `articles.locale` to a more accurate source (e.g., author-declared) — rejected. The user clarified that the column stays as-is (clarification Q2, Option A).

### D2: Remove `#localize` entirely rather than no-op it

**Decision**: Delete the `#localize` method, the `@locale` ivar, and the `.localize` call inside `#call`. Do not keep a no-op method.

**Rationale**: A no-op method would be dead code with no consumer — it would invite future readers to re-introduce a locale filter by analogy. Removing it makes the intent clear and removes the surface for a regression.

**Alternatives considered**:
- Keep `#localize` as a no-op method that returns `self` — rejected. Dead code invites the wrong pattern.
- Refactor `#localize` into a different name (e.g., `#skip_locale_filter`) — rejected. The method has no purpose after the change.

### D3: Drop `locale:` from service callers in `articles#index`, `home#selected_articles`

**Decision**: Stop passing `locale:` to `ArticleSearchService.call(...)` from these two callers.

**Rationale**: The service no longer reads `locale:` (D2). Continuing to pass it would be dead code. Stop the spread at the boundary.

**Alternatives considered**:
- Keep `locale:` as documentation of intent — rejected. The intent is now the opposite; a future reader would be misled.

### D4: Cache key change in `home#hot_tags`

**Decision**: Change the cache key from `"#{current_locale}_hot_tags"` to a process-wide `"hot_tags"`.

**Rationale**: Once the locale filter is removed, the same hot-tags set is returned to every visitor. A per-locale key would write the same payload N times (once per locale) and waste cache slots. One shared key, one shared payload.

**Alternatives considered**:
- Keep the per-locale key for cache isolation (avoid contention) — rejected. The set is small (5 records) and reads are cheap. A single key is simpler and matches the new global behavior.

### D5: Add a language chip to article cards and the article header

**Decision**: Add a small language indicator (badge/chip) to `app/views/articles/_card.html.erb` and `app/views/articles/_header.html.erb`. Render `article.locale` (e.g., `ZH`, `EN`, `JA`) with a tooltip showing the human-readable language name.

**Rationale**: Per FR-010, visitors need to know what language an article is in before clicking into it. Today the catalogue is implicitly partitioned by locale, so visitors never see a card in a language they don't read. After the change, they will — so the indicator is essential to set expectations.

**Alternatives considered**:
- Use a flag emoji (e.g., 🇨🇳 🇺🇸 🇯🇵) — rejected. The Quill UI is text-and-chrome; emoji flags are inconsistent and not always accessible.
- Show the full language name (`中文`, `English`, `日本語`) — partial. Two-letter codes are denser and visually consistent across locales.
- Show only when the article's locale differs from the visitor's locale — rejected. Visitors should always see what language they will read, regardless of overlap.

### D6: No new test fixtures for existing tests; new fixtures for new tests

**Decision**: Do **not** modify existing fixtures. Add new fixtures (`published_zh`, `published_ja` articles; `author_zh`, `author_ja` users; `tech_zh`, `tech_ja` tags) for the new multi-locale tests.

**Rationale**: Existing tests reference `published_paid`, `published_free`, `draft`, `high_revenue` by name across many test files (e.g., `articles_controller_test.rb:7`). Changing their `locale` field would risk breaking unrelated assertions. New tests need new fixtures with explicit locales to assert cross-locale visibility.

**Alternatives considered**:
- Change the `locale` of one existing fixture to `zh` — rejected. The fixture is referenced as `published_paid` and changing its locale could break unrelated tests.
- Use factory_bot — rejected. The codebase uses fixtures (`test/fixtures/*.yml`), not factories. Stay consistent.

### D7: New tests cover FR-001 through FR-005 + SC-007

**Decision**: Add new tests in `test/services/article_search_service_test.rb` (FR-001/002/003), `test/controllers/home_controller_test.rb` (FR-004/005), and (optionally) `test/controllers/articles_controller_test.rb` (FR-007/008). Visual language chip rendering (FR-010) is asserted via system / Capybara test if available, or a simple view-render assertion.

**Rationale**: The spec's success criteria are measurable; the only way to keep them green over time is automated assertions. Existing tests do not cover the locale filter at all — that is a coverage gap, not a regression risk.

**Alternatives considered**:
- Skip tests for SC-001/SC-002/SC-003 and rely on manual QA — rejected. These are critical behaviors; manual QA does not catch regressions in CI.

## Resolved unknowns

- **Q: Does `ArticleSearchService` have any other locale-dependent behavior beyond `#localize`?**  
  A: No. The `ransack` queries target title/intro/author/tags by content (`title_i_cont` etc.), not by locale. The `filter_block_authors` and `select_in_time_range` steps are locale-agnostic.

- **Q: Does `Tag.hot` (scope definition) filter by locale?**  
  A: No. `Tag.hot` (`app/models/tag.rb:32-41`) joins on `articles.state = :published` and orders by article count + tag created_at. The locale filter was added by the **consumer** in `home_controller.rb:26`, not by the scope. Removing the consumer's filter is sufficient.

- **Q: Does `User.active` (scope definition) filter by locale?**  
  A: No. `User.active` (`app/models/concerns/users/scopable.rb:12-21`) restricts to authors with published articles in the last 3 months and at least one order. The locale filter was added by the **consumer** in `home_controller.rb:37`. Same pattern as `Tag.hot`.

- **Q: Are there mobile-specific or API-specific locale filters we missed?**  
  A: No. `app/controllers/api/articles_controller.rb` has no locale filter; the API base controller pins `:en` for I18n (chrome only). Mobile views use the same partials as desktop and do not add locale filtering on top.

- **Q: Do notifiers/broadcasts need changes?**  
  A: No. They wrap message rendering in `I18n.with_locale(recipient.locale)` — chrome, not article content. Article body / title are referenced as `article.title`, `article.uuid`, etc. without locale branching.

- **Q: Do routes change?**  
  A: No. All routes preserved (FR-007). Confirmed: `config/routes.rb` lines 37-40 (home endpoints), 42-47 (locale), 57-61 (articles), 100-113 (`/:uid`, `/:uid/:uuid`).

## References

- Feature spec: `specs/001-unified-article-translations/spec.md`
- Prior exploration report: see `specify` agent context.
- Confirmed re-confirmation pass: see `plan` agent context.