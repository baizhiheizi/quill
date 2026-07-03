# Feature Specification: Cross-Locale Article Visibility

*(Originally titled "Unified Article Translations"; scope was redirected during clarification — the redesign is about cross-locale visibility, not per-article translations.)*

**Feature Branch**: `[001-unified-article-translations]`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "The project used to split the users by locale, render specifici locale of articles based on user's locale. Like English users only see the english articles. Chinese users only see the zh-CN articles. But we need redesign this. We make all articles accessible for all locales users."

## Summary

Today the platform filters articles by the visitor's locale in the home feed, tag pages, and active-author lists — an English visitor only sees English articles, a Chinese visitor only sees Chinese articles. This makes the same piece of writing invisible to readers in any other language, even though every article already has a `uuid`, a single body, and a single language.

This feature removes locale-based filtering on article visibility so **every visitor, regardless of locale preference, sees the full catalogue of articles**. Each article remains a single-locale record (no translations, no per-locale content). The visitor's language preference continues to drive only UI chrome (buttons, labels, notification copy) — never which articles they are allowed to see.

## Clarifications

### Session 2026-07-03

- Q: What does the redesign actually change? → A: Articles stay single-locale (one body per article); the redesign removes locale-based filtering on visibility so every locale user can see every published article. The visitor's language preference still controls UI chrome but never article visibility.
- Q: Should visitors have an opt-in "show only my language" toggle on top of the new global feed? → A: No. Ship the global feed only; no opt-in toggle. The change matches the stated intent exactly. If a future audit shows readers want filtering, that is a separate follow-up.
- Q: What should happen to the existing `articles.locale` column? → A: Keep as-is. CLD detection continues to populate it on save; admin filter and card display continue to consume it; no schema change.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visitor sees every article regardless of their locale (Priority: P1)

As a **reader** who prefers Chinese, when I open the home feed I want to discover articles written in any language — Chinese, English, Japanese — ordered by recency, revenue, or popularity, without the platform silently hiding every non-Chinese article from me. The catalogue is global, not partitioned.

**Why this priority**: This is the core change the user asked for. If this story is not implemented, nothing else in the feature matters.

**Independent Test**: Seed articles in three languages, visit the home feed as a Chinese-locale user, verify articles from all three languages appear in the result set.

**Acceptance Scenarios**:

1. **Given** the catalogue contains articles in `zh`, `en`, and `ja`, **When** a visitor whose preferred locale is `zh` opens the home feed, **Then** the feed contains articles in all three languages, ordered by the active sort, with each card labeled with its language so the reader knows what they will read.
2. **Given** the visitor switches their UI language preference to `en` (via the language picker), **When** they reload the home feed, **Then** the same articles appear — only the chrome (buttons, labels, headings) changes; the article set is identical.
3. **Given** a visitor clicks an article written in `ja` from a Chinese-locale session, **When** the article page opens, **Then** the article renders in Japanese (its only language), and the visitor's UI chrome is still in their preferred locale.

---

### User Story 2 - Search returns matches across all languages (Priority: P1)

As a **reader** running a text search, I want to find articles whose content matches my query regardless of which language they are written in. Today text search already crosses locales; this feature preserves that and removes any quiet locale filter that would narrow results.

**Why this priority**: Search is the second most visible "separation by language" surface and the user's intent applies equally to it.

**Independent Test**: Search for a keyword that appears in articles written in two different languages; verify both are returned with no locale parameter.

**Acceptance Scenarios**:

1. **Given** an English article and a Chinese article both contain the searched keyword, **When** the visitor submits the query, **Then** both articles appear in the result set.
2. **Given** the visitor filters by tag or by time range in addition to the query, **When** they submit, **Then** results still include matches in every language.
3. **Given** a visitor filters by `subscribed` (authors they follow) or `bought` (articles they purchased), **When** the filter is applied, **Then** results include items in every language those authors have published — locale does not narrow them.

---

### User Story 3 - Tag pages and active-author lists are global (Priority: P2)

As a **reader** browsing a tag page or the "active authors" sidebar, I want to see every tag and author whose content is interesting to the platform, not just the ones tagged in my preferred language. The locale-tag filter on `Tag.hot` and `User.active` is removed so discovery is global.

**Why this priority**: Same intent as the home feed; lower priority only because these surfaces are secondary entry points.

**Independent Test**: Seed tags and authors with mixed locales; visit a tag page as a Chinese-locale user and verify tags/authors from all locales appear.

**Acceptance Scenarios**:

1. **Given** tags exist with `locale` in `zh`, `en`, and `ja`, **When** a Chinese-locale visitor opens the home page and views the hot-tags section, **Then** hot tags from all three locales appear in the sidebar.
2. **Given** authors exist with `locale` in `zh`, `en`, and `ja` and have published articles, **When** a Chinese-locale visitor opens the active-authors section, **Then** authors from all three locales appear.
3. **Given** a tag page lists articles with that tag, **When** a Chinese-locale visitor opens it, **Then** every tagged article in every language is listed — no locale narrowing.

---

### User Story 4 - Admin and back-office filtering stays available (Priority: P2)

As an **admin** moderating the catalogue, I still need to be able to filter the article list by language — but as a back-office tool, not as the default for visitors. The admin locale filter continues to work; only the visitor-facing surfaces change.

**Why this priority**: Operations depends on it; without it the feature cannot ship.

**Independent Test**: An admin can still filter the admin articles index by language; the visitor-facing surfaces ignore the filter.

**Acceptance Scenarios**:

1. **Given** an admin opens the admin articles index, **When** they select the `EN` / `ZH` / `JA` / `Others` locale filter, **Then** the result set is restricted to articles whose `locale` column matches — behavior unchanged from today.
2. **Given** an admin filters by `subscribed` or runs a Ransack search, **When** they look at results, **Then** locale remains an available filter they can apply.

---

### User Story 5 - Visitor UI language preference is preserved (Priority: P2)

As a **reader**, the language picker on the home page and sidebar continues to switch the UI chrome (button labels, navigation, notification copy) into my preferred language. The change only affects article visibility, never the chrome.

**Why this priority**: Users rely on the language picker for UI comprehension; if we accidentally remove it, the feature breaks a familiar surface.

**Independent Test**: Switch the UI language preference from `en` to `zh-CN` and verify that the home feed, navigation, and button labels switch to Chinese, while the article set is unchanged.

**Acceptance Scenarios**:

1. **Given** a visitor is on the home page, **When** they click the language picker and choose `日本語`, **Then** the page re-renders with Japanese UI strings, the `<html lang>` attribute updates, and the article set is identical to the previous render.
2. **Given** a visitor has selected a non-default language, **When** they navigate to any page on the site, **Then** the same UI locale persists (existing behavior — unchanged).

---

### User Story 6 - Existing data is unchanged (Priority: P1)

As a **platform operator**, this feature is a behavior change, not a data migration. No article rows, orders, comments, snapshots, or transfers are touched. The `articles.locale` column stays exactly where it is today, and CLD-based locale detection continues to run on content changes.

**Why this priority**: This is the rollout gate — the change must ship without any data migration to avoid risk.

**Independent Test**: Take a pre-deploy dump of every article row, deploy the change, take a post-deploy dump, diff — there must be zero differences in article data.

**Acceptance Scenarios**:

1. **Given** the platform has existing articles in `zh`, `en`, and `ja`, **When** the change is deployed, **Then** every article row's `title`, `intro`, `content`, `locale`, `state`, `published_at`, prices, and counters are byte-identical to before.
2. **Given** existing orders, comments, snapshots, and transfers exist, **When** the change is deployed, **Then** every row is preserved untouched.
3. **Given** `Articles::DetectLocaleJob` continues to run on content changes, **When** the change is deployed, **Then** the job still runs and updates `articles.locale` exactly as today.

### Edge Cases

- **Article with no `locale` value**: surfaces in the catalogue like any other article; admin filter shows it under `Others` (existing behavior preserved).
- **Visitor preferred locale matches the article's language**: the visitor sees no special indicator beyond the standard card; the article is treated identically to all others.
- **Visitor preferred locale does not match the article's language**: the visitor sees the article normally — it is not hidden. The article card shows its language so the visitor knows what they will read.
- **CLD detection running on a Chinese article whose content is later translated by another tool to English**: `DetectLocaleJob` runs, detects English, and updates `articles.locale` — but the article is still visible to Chinese visitors, because no locale filter is applied. This is the correct behavior post-change.
- **API locale hard-pinning (`API::BaseController#with_locale` forces `:en`)**: unchanged. API callers continue to receive English-formatted I18n strings regardless of header; this feature does not touch API chrome.
- **Notifiers and broadcasts** (`ApplicationNotifier`, `Order#broadcast_to_article_views`): unchanged. They continue to render to the recipient's preferred locale. Article content stays as authored.
- **Admin locale filter still functional**: the admin can still narrow by language for moderation purposes; this is not a behavior change for admins.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST NOT filter the home feed by the visitor's preferred locale — articles in every language appear in the result set, ordered by the active sort.
- **FR-002**: System MUST NOT filter text search results by the visitor's preferred locale when a text query is present — matches across all languages are returned, as today.
- **FR-003**: System MUST NOT narrow `subscribed` or `bought` filter results by the visitor's locale — articles in every language from followed authors or past purchases are returned.
- **FR-004**: System MUST NOT apply a locale filter to the `Tag.hot` list on the home page — hot tags from every language are surfaced.
- **FR-005**: System MUST NOT apply a locale filter to the `User.active` list on the home page — active authors from every locale are surfaced.
- **FR-006**: System MUST preserve the visitor's preferred locale for UI chrome — buttons, labels, navigation, `<html lang>`, and notification copy continue to render in the visitor's preferred language.
- **FR-007**: System MUST preserve the existing public URL shape — `/articles/:uuid`, `/:uid/:uuid`, `/<locale>` (the visitor-side language picker), and all other routes continue to work.
- **FR-008**: System MUST preserve admin locale filtering on the admin articles index unchanged — admins can still narrow by `EN / ZH / JA / Others` as today.
- **FR-009**: System MUST preserve `Articles::DetectLocaleJob` and CLD-based locale detection on the article body — `articles.locale` continues to be auto-populated on save.
- **FR-010**: System MUST surface each article's language on its card (and on the article header) so visitors know what language they will read, regardless of the visitor's own locale.
- **FR-011**: System MUST preserve `User#locale`, `session[:current_locale]`, and `Accept-Language` resolution order — only the consumer of that locale (article visibility filter) is removed; the locale is still used for UI chrome.
- **FR-012**: System MUST preserve all existing commerce flows — orders, payments, revenue splits, snapshots, transfers, and early-reader rewards continue to operate against the parent `Article` with no change.
- **FR-013**: System MUST keep API behavior unchanged — `API::BaseController#with_locale` still pins to `:en`, the API `show`/`index` still returns the same fields for the same article uuid, and the API locale filter (none today) stays as it is.
- **FR-014**: System MUST keep the notifier (`ApplicationNotifier`) and broadcast (`Order#broadcast_to_article_views`) locale handling unchanged — messages continue to render in the recipient's preferred locale.

### Key Entities *(include if feature involves data)*

- **Article** (unchanged): `id`, `uuid`, `locale` (string, CLD-detected, retained), `title`, `intro`, `content` (Action Text), `legacy_markdown_content`, `author_id`, `collection_id`, `asset_id`, `price`, `state` (`drafted` / `published` / `hidden` / `blocked`), `published_at`, revenue ratios, `free_content_ratio`, `revenue_usd`, `revenue_btc`, `source`, counter caches, snapshot/transfer/comment/tag/order associations. **No schema change.**
- **User** (unchanged): retains `locale` (enumerized), used only for UI chrome resolution; not used for article visibility.
- **Tag** (unchanged): retains `locale`, used only by admin and for back-office reference; the home page no longer filters by it.
- **Locale preference (visitor-side, unchanged resolution)**: `session[:current_locale]` → `User#locale` → `Accept-Language` → `I18n.default_locale`. Same as today; only the downstream consumer changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The home feed returned to a Chinese-locale visitor contains articles in at least three different languages on a seeded benchmark dataset (proving the locale filter is no longer applied), measured against a fixed test fixture.
- **SC-002**: Text search for a keyword that appears in articles in two different languages returns matches in both languages in one response, with no locale parameter required — measurable on any seeded dataset where such cross-language matches exist.
- **SC-003**: The `subscribed` and `bought` filters on the article index return items from every language the filtered author has published (or the visitor has bought), measurable on a seeded fixture.
- **SC-004**: The admin locale filter on the admin articles index still returns the same result set it returns today for the same filter selection — measurable as zero drift on the same input.
- **SC-005**: 100% of pre-existing article URLs (`/articles/<uuid>` and `/:uid/<uuid>`) continue to resolve to the same article body after the change, with zero 404s attributable to the change.
- **SC-006**: Visitor UI language switching continues to change only chrome: the same article set is returned before and after the visitor changes their preferred locale — measurable by snapshotting the article set across two locale switches.
- **SC-007**: The language indicator (chip / label) appears on every article card and on the article header, so visitors can tell what language an article is in before clicking — verifiable by an automated visual assertion.
- **SC-008**: The existing revenue distribution test suite passes unchanged after the change — proving no commerce flow was disturbed.

## Assumptions

- Articles remain single-locale records. There is no per-article translation model introduced in v1. If the platform later wants per-article translations, that is a separate feature.
- The visitor's preferred locale is preserved for UI chrome only; this feature does not remove or weaken the language picker.
- Admin and back-office locale filtering on the article index is preserved — only visitor-facing surfaces change.
- The `articles.locale` column is preserved exactly as it is today: CLD-detected on save, displayed in admin and on the article header, used by admin filtering.
- CLD auto-detection continues to run via `Articles::DetectLocaleJob`; no changes to the detection pipeline.
- No schema migration is required. The change is contained to view/controller/service layers.
- All commerce flows (orders, payments, revenue splits, snapshots, transfers, early-reader rewards) operate against the parent `Article` exactly as today.
- The home page UI surfaces the article's detected language on each card so visitors can scan a mixed-language catalogue. Existing card layouts are extended with a language chip; no cards are removed or hidden by language.
- The "active authors" and "hot tags" home-page modules drop their locale filter so the discovery experience matches the catalogue experience.
- No per-visitor "show only my language" toggle is introduced in v1. The global feed is the only behavior; reintroducing locale filtering (as a toggle, persisted preference, or follow-up feature) is explicitly out of scope.
- The API is untouched. API consumers continue to see whatever locale their token profile uses (`API::BaseController#with_locale` still pins to `:en`).
- The existing locale preference resolution chain (`session[:current_locale]` → `User#locale` → `Accept-Language` → `I18n.default_locale`) is unchanged; only its consumer changes (chrome only, not visibility).