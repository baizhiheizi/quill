# Phase 1 Contracts: Editorial UI Redesign

This project has no external API to version. Its "interfaces" are the Rails view partials and Stimulus controllers that other views/pages depend on. This document is the contract those call sites must keep honoring so the redesign doesn't silently break a caller.

## Partial: `articles/_card` (the "Minimal List" row)

**Callers** (must keep working, unchanged call signature): `app/views/articles/_list.html.erb`, `app/views/users/articles/index.html.erb`, `app/views/collections/articles/index.html.erb`.

**Contract**:
- Rendered via `render partial: "articles/card", collection: articles, as: :article` — the partial MUST continue to accept a single local named `article` (an `Article` instance with its associations available: `author`, `tags`, `currency`).
- MUST render cleanly (no `NoMethodError`) when `article.thumb_url` is blank, `article.tags` is empty, and `article.locale` is nil (Edge Cases in spec.md).
- MUST NOT introduce new required locals — every caller above passes only `article` today (implicitly, via `collection:`/`as:`); do not add a second required local that would require updating three call sites in lockstep with a fourth.
- Root element SHOULD keep a stable, greppable DOM hook (e.g. a `data-article-card` attribute or a predictable class) since `test/system/article_paywall_test.rb` and similar system tests assert on rendered article content by text — avoid relying on the specific Tailwind utility classes being frozen (those are expected to change).

## Layout: `layouts/public` (new)

**Callers**: `ArticlesController` (index/show), `UsersController` (show), `SearchController` (index), `CollectionsController` (index/show).

**Contract**:
- MUST render `yield` for main content and support `content_for :sidebar` / `content_for :topbar` the same way `layouts/application.html.erb` does today, OR the views above must be updated in the same change if those content blocks are dropped (per the design's "no persistent right rail" decision — see spec §5.2/design doc §5.2). Whichever is chosen, it must be applied consistently to all four controllers in the same task, not partially.
- MUST render the shared flash/toast/modal turbo-frame infrastructure currently in `application.html.erb` (`turbo_frame_tag 'modal'`, `#flashes`, `#toast-slot`, `turbo_stream_from` for the current user) — these are cross-cutting and must not be lost when splitting the layout.
- MUST include the dark-mode bootstrap `<script>` (theme-before-paint, avoids flash-of-wrong-theme) identically to the current layouts.

## Partial: `shared/_masthead` (new)

**Contract**:
- MUST expose the same primary actions as today's `shared/_left_bar`/`shared/_navbar` for parity: Home link, Write/Connect-Wallet CTA (`current_user.present?` branch, both target `new_article_path` / `login_path` with `data: { turbo_frame: :modal }` respectively), notifications entry point (unread badge via `current_user.has_unread_notification?`), profile dropdown (`user_path`, `dashboard_settings_path`, `logout_path`), locale switcher, dark-mode toggle.
- MUST NOT change any of the linked route helpers or `data-turbo-frame`/`data-controller` wiring on those actions — only their visual container changes.

## Stimulus: `paywall_fade_controller` (new)

**Contract**:
- Values/targets are internal to this controller; no other controller or view may depend on its internals beyond attaching `data-controller="paywall-fade"` to the locked-content wrapper.
- MUST NOT alter the server-rendered HTML that determines *whether* content is locked (that remains `article.authorized?(current_user)`-driven, server-side) — it only affects presentation/positioning of the fade + unlock card, so it degrades gracefully (unlock card still visible, just unpositioned) with JS disabled.

## Stimulus: `masthead_controller` (new)

**Contract**:
- Purely presentational (mobile menu open/close, scroll-shadow toggle). MUST NOT gate any navigation link's functionality — all links must work with JS disabled (progressive enhancement, consistent with existing controllers like `dropdown_controller`).

## Tailwind theme tokens (`application.tailwind.css`)

**Callers**: every view in the app (global stylesheet).

**Contract**:
- `--color-primary` and other FlyonUI theme variables may change value, but MUST remain defined for both the `quill` and `quill-dark` `@plugin 'flyonui/theme'` blocks — no view anywhere in the app (in scope or not) may be left referencing an undefined token.
- Removing `tag-style-0..5` utilities requires updating every call site first. Confirmed current call sites (as of this plan): `app/views/tags/_tag_card.html.erb`, `app/views/search/_result.html.erb`, `app/views/home/hot_tags.html.erb`, `app/views/articles/_header.html.erb` (all in-scope for this feature), plus `app/views/dashboard/subscribe_tags/_tag.html.erb` (out of scope). The out-of-scope dashboard file MUST be migrated to the new neutral chip utility too, or given its own equivalent inline style, in the same task that deletes `tag-style-0..5` — otherwise it breaks even though the dashboard redesign itself is out of scope.
