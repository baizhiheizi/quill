# Phase 1 Contracts: Editorial Redesign Rollout

This project has no external API to version. Its "interfaces" are the Rails models/methods, partials, jobs, and routes that other code depends on. This document is the contract those call sites must keep honoring so the rollout doesn't silently break a caller.

## Model concern: `Articles::PosterGenerator#thumb_url` / `#cover_url`

**Callers**: `app/views/articles/_card.html.erb`, `ArticlesController#show` (`@page_image`), any Mixin bot notification card builder that reads `article.thumb_url`/`cover_url`, `test/models/concerns/articles/poster_generator_test.rb`.

**Contract**:
- `thumb_url` MUST continue to return a real cover URL when `cover.attached?` is true, and MUST continue to prefer an in-content image for free articles when no cover is attached (existing priority order — see `research.md` §3) — this feature only changes what happens in the case that previously returned `nil`.
- `thumb_url` MUST NOT return `nil` for a published article once the new fallback is in place — every published article resolves to *some* real, fetchable image URL (real cover → in-content image → generated default).
- The generated-default path MUST be idempotent: calling `thumb_url` repeatedly (or concurrently, e.g. two requests racing on a cold cache) MUST NOT create duplicate attachments or duplicate enqueued jobs in a way that causes errors; a second trigger while generation is already in flight is a no-op.
- Once a real cover is uploaded (`article.update(cover: ...)`), `thumb_url`/`cover_url` MUST immediately reflect the real cover on the very next call — no caching layer may keep serving the generated default after a real upload (mirrors the existing `@thumb_url ||=` memoization being **per-instance/per-request**, not persisted, so this is naturally satisfied as long as the generated cover is attached to the same `cover` slot the real upload also targets).

## New Grover route/template: `grover_article_cover`

**Callers**: `Articles::GenerateDefaultCoverJob` (new), following the exact calling convention of the existing `grover_article_poster_url` (`Articles::PosterGenerator#generated_poster_url`) and `grover_collection_cover_url` (`Collection#generated_cover_url`).

**Contract**:
- MUST be added under the existing `namespace :grover do resources :articles, ... do ... end end` block in `config/routes/grover.rb`, alongside the existing `get :poster`, producing `grover_article_cover_url(uuid, token:, format: :png)`.
- MUST be authenticated the same way every other Grover route is (`Grover::BaseController#authenticate!`, comparing `params[:token]` against `Rails.application.credentials.dig(:grover, :token)`) — no new auth mechanism.
- The rendered template (`app/views/grover/articles/cover.html.erb`) MUST be deterministic given the same `article.uuid` — no `Time.current`, `SecureRandom`, or other non-deterministic input may influence its visual output, since determinism (FR-004) depends on it.
- MUST NOT read or display the article's paid/locked content — only public metadata already safe to expose (title, author name/avatar — same fields the existing poster template already exposes), consistent with the existing `grover/articles/poster.html.erb` and `grover/collections/cover.html.erb` templates' scope.

## Job: `Articles::GenerateDefaultCoverJob` (new)

**Callers**: `Articles::PosterGenerator#thumb_url` (enqueues lazily), modeled directly on `Articles::GeneratePosterJob`.

**Contract**:
- MUST inherit `ApplicationJob`, namespaced under `Articles::`, matching `.cursor/rules/ruby-rails.mdc`'s job-naming convention.
- MUST be safe to enqueue multiple times for the same article without error (idempotent attach-if-absent check at the top of `#perform`).
- MUST NOT be enqueued for an article that already has `cover.attached?` — checked both before enqueueing (in `thumb_url`) and again inside `#perform` (defends against a race where a real cover was uploaded between enqueue and execution, per FR-006).
- MUST NOT block the request that triggers it — invoked via `perform_later`, exactly like `generate_poster_async`.

## Partial: `articles/_card` (thumbnail block)

**Callers**: `app/views/articles/_list.html.erb` (unchanged caller contract from `specs/002-editorial-ui-redesign/`).

**Contract**:
- The existing `<% if article.thumb_url.present? %> ... <% else %> ... <% end %>` branch (lines 42–50 today) MAY be simplified to a single unconditional `remote_image_tag article.thumb_url, ...` now that `thumb_url` always resolves to a real URL for published articles — but MUST still defend against a blank `thumb_url` for the edge case of an unpublished/drafted article being rendered somewhere thumb_url's fallback chain doesn't apply (e.g. any preview context that renders a not-yet-published `Article`), so a defensive blank-check placeholder MAY be kept as a last-resort fallback even after this change.
- MUST NOT introduce new required locals — same constraint carried over from `specs/002-editorial-ui-redesign/contracts/component-contracts.md`.

## Dashboard shell partials: `shared/_left_bar`, `shared/_navbar`, `shared/_tabbar`

**Callers**: `app/views/layouts/application.html.erb` (renders `_left_bar` on non-mobile, `_navbar`/`_tabbar` on mobile, per `browser.device.mobile?`), used by every `Dashboard::*` controller and every other controller still on the `application` layout (e.g. `comments`, `subscribe_*`, `block_users` — out of this feature's page-level scope, but they inherit whatever shell markup is present).

**Contract**:
- MUST preserve every existing route helper, `data-controller`, and `data-action` currently wired into these partials (nav links, write/login CTA, dropdown menu items, dark-mode toggle, locale switcher) — restyling MUST NOT remove or rename any of these hooks, since other, currently out-of-this-feature's-explicit-page-list views also render through this same shell.
- MUST NOT change `@active_page` matching logic (`@active_page == 'home'`, etc.) — active-state highlighting continues to be driven by controller-set instance variables, unchanged.
- Icon migration (`inline_svg_tag` → `i-tabler-*`) MUST preserve the same semantic icon (e.g. `icons/bell-solid.svg` → an equivalent solid bell Tabler icon), not swap to an unrelated glyph.

## Layout: `layouts/editor`

**Callers**: `ArticlesController#new`/`#edit` (via `public_or_editor_layout`, unchanged).

**Contract**:
- MUST continue to render `turbo_frame_tag 'modal'`, `#flashes`, `#toast-slot`, the dark-mode bootstrap script, and `turbo_stream_from` for the current user — same cross-cutting infrastructure carried over from the prior redesign's `layouts/public.html.erb` contract, applied here too so real-time features (notifications, live updates) keep working inside the editor.
- MUST NOT introduce the masthead or dashboard sidebar into the editor shell — the editor intentionally remains a distraction-free, chrome-minimal layout (only its color/typography tokens and the sticky top bar's own button styles change).

## Partial: `sessions/new` (login/connect-wallet modal content)

**Callers**: Rendered inside `shared/_modal.html.erb` via `turbo_frame_tag 'modal'`, triggered from many places (`_masthead.html.erb`, `_left_bar.html.erb`, any `login_path` link with `data: { turbo_frame: :modal }`).

**Contract**:
- MUST NOT change `auth_mixin_path`'s `return_to` param handling (`params[:return_to] || request.referer`) — restyling only.
- MUST preserve both branches (`from_mixin_messenger?` vs. not) and their respective link targets (`auth_mixin_path` direct vs. `login_path` modal-triggering) exactly as today — only their visual presentation changes.

## Tailwind theme tokens (`application.tailwind.css`)

**Callers**: every view in the app (global stylesheet) — unchanged token *names* from the prior redesign; this feature is a consumer of those tokens, not a modifier of their values, unless a genuine gap is found (e.g., a dashboard-specific color not covered by the existing `quill`/`quill-dark` `@plugin 'flyonui/theme'` blocks).

**Contract**:
- Any new utility class introduced for this feature (e.g., a dashboard-specific spacing/sizing helper) MUST be defined for both the `quill` and `quill-dark` themes if it's color-related — no view may reference an undefined token, carrying over the exact constraint from `specs/002-editorial-ui-redesign/contracts/component-contracts.md`.
- `btn-ghost`/`badge-ghost` MUST NOT be reintroduced anywhere in the app going forward — `btn-soft`/`badge-soft` are the only supported low-emphasis modifiers (FR-001).
