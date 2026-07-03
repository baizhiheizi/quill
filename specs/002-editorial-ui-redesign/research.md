# Phase 0 Research: Editorial Web3 UI Redesign

No `[NEEDS CLARIFICATION]` markers were present in `spec.md` — the interactive brainstorming session (see `docs/superpowers/specs/2026-07-03-ui-redesign-design.md`) already resolved every open product/design question with the user, including live visual comparisons for palette, CJK typography, and feed-card layout. This document instead captures the **implementation-approach decisions** needed to translate that approved design into this codebase's actual Rails/Hotwire/Tailwind conventions.

## Decision: Shared article row via the existing `articles/_card` partial

**Decision**: Redesign `app/views/articles/_card.html.erb` in place rather than introducing a new partial name.

**Rationale**: Investigation of the current codebase found this single partial is already rendered by four of the five in-scope surfaces (`articles/_list` → home feed, `users/articles/index` → profile, `collections/articles/index` → collection page, and the same feed action handles the `query` param for search). Redesigning it in place automatically propagates the new "Minimal List" row everywhere it's needed (spec FR-003/FR-009/FR-010), with zero duplication and zero risk of the four surfaces drifting out of sync.

**Alternatives considered**: Creating a new `articles/_row.html.erb` partial and migrating call sites one at a time. Rejected — adds a migration/cleanup step and a window where two competing row styles coexist, with no benefit since all four call sites need the identical new markup.

## Decision: Search has no dedicated results page to redesign

**Decision**: No new "search results" view is needed. `SearchController#index` (route `/search`) only powers a live user/tag autocomplete dropdown (`search_result_list`, via the `search` Stimulus controller + `search/index.turbo_stream.erb`). Actual article search is a GET to `articles_path(query: ...)`, handled entirely by `ArticlesController#index` → `ArticleSearchService`, rendering the exact same `articles/index.html.erb` + `articles/_card.html.erb` as the home feed.

**Rationale**: Confirms spec User Story 4 is satisfied automatically once `articles/_card` and `articles/index` are redesigned — there is no separate template to touch for "search results" beyond what Story 1 already covers. Flagging this explicitly so the tasks phase doesn't create speculative work for a non-existent page.

**Alternatives considered**: N/A — this is a discovery, not a design choice.

## Decision: Early-reader reward indicator is an aggregate figure, not personalized

**Decision**: The reward/revenue indicator shown inline on each row (spec FR-004) surfaces `article.revenue_usd` — an aggregate, platform-wide figure already computed for every viewer — not a per-visitor personalized percentage.

**Rationale**: The current `_card` partial already renders this (`icons/income-solid.svg` + `article.revenue_usd`, tooltip "Early Reader Rewards"). Early-reader payout percentage is inherently prospective (it depends on how many readers buy *after* you), so it can't be meaningfully personalized in a feed row before purchase. `spec.md` FR-004 and its acceptance scenario were corrected during planning to reflect this (see spec.md Assumptions).

**Alternatives considered**: Compute a per-viewer "if you buy now, you'd be reader #N" estimate. Rejected as a scope increase requiring new business logic — not requested by the user and outside this presentation-layer feature.

## Decision: Masthead replaces left-sidebar composition at the layout level, scoped to 5 pages

**Decision**: Introduce `shared/_masthead.html.erb` and swap it in for `shared/_left_bar` + `shared/_navbar` only on the routes backing the 5 in-scope pages, via the existing `@active_page`/layout mechanism already used in `application.html.erb` (e.g. `browser.device.mobile?` and `@active_page` conditionals already exist there). Dashboard/studio routes keep the current left-sidebar include entirely unchanged.

**Rationale**: `app/views/layouts/application.html.erb` is shared by both in-scope and out-of-scope (dashboard) pages today. Rather than forking the whole layout file, the smallest-diff approach is a conditional inside the existing layout (mirroring the existing `browser.device.mobile?` conditional pattern already there), so dashboard views keep working with zero changes to their own templates.

**Alternatives considered**: A dedicated `layouts/public.html.erb` for the 5 pages. Considered viable and lower-risk for regressions (fully isolates new markup from dashboard rendering path) — **recommended as the actual implementation choice** over a conditional inside the shared layout, since Rails layout-per-controller (`layout "..."`) is an idiomatic, well-trodden pattern already used in this codebase (`layout "homepage"`, `layout "editor"`). Tasks phase should implement this as a new `layouts/public.html.erb`, applied via `layout "public"` on `UsersController`, `SearchController`, and `CollectionsController` directly. `ArticlesController` already has a conditional layout override (`layout "editor", only: %i[new edit]`); since Rails' `layout` macro doesn't merge across multiple calls, that line should become a single conditional (e.g. `layout :public_or_editor_layout` backed by a private method returning `"editor"` for `new`/`edit` and `"public"` otherwise) rather than adding a second competing `layout` call.

## Decision: Paywall fade uses CSS gradient mask + a small Stimulus controller, not new JS libraries

**Decision**: Implement the fade-to-blur paywall boundary with a CSS `mask-image: linear-gradient(...)` (or `-webkit-mask-image` fallback) applied to the last visible content block, plus a `paywall_fade_controller.js` Stimulus controller only for positioning the inline unlock card at the correct scroll offset (no new JS dependency).

**Rationale**: Matches "Stimulus, not vanilla JS/new frameworks" convention; CSS mask-image is broadly supported and avoids a heavier blur-via-canvas/JS approach. The unlock card itself is server-rendered (already exists as `articles/_buy_article_button.html.erb` content), so no new client-side data fetching is needed.

**Alternatives considered**: `backdrop-filter: blur()` over an absolutely-positioned duplicate of the last paragraph. Rejected — requires duplicating markup/content, more fragile with variable-length CJK text wrapping.

## Decision: Icon migration is incremental, file-by-file

**Decision**: Adopt `i-tabler-*` classes (via already-installed `@iconify/tailwind4`) only in files touched by this feature. `inline_svg_tag` usages in untouched files (dashboard, admin, editor) are left as-is.

**Rationale**: Matches spec/design-doc guidance (§4.3) and avoids a large, risky, unrelated-to-this-feature icon sweep across the whole app. Confirmed no RuboCop/lint rule forces a single icon system today.

**Alternatives considered**: Big-bang icon migration across the whole app in this PR. Rejected — far larger diff than the feature requires, higher regression risk, no user request for it.

## Decision: No visual regression tooling added; validation is manual + existing system tests

**Decision**: Rely on the existing Minitest/Capybara system test suite (`test/system/article_paywall_test.rb` etc.) for behavioral regressions, and a manual QA pass (documented in `quickstart.md`) for visual/typographic review across light/dark and desktop/mobile.

**Rationale**: No visual-regression/screenshot-diff tool exists in this stack today; introducing one is a testing-infrastructure decision out of scope for a UI redesign feature and not requested by the user.

**Alternatives considered**: Adding Percy/Chromatic-style tooling. Rejected — new paid/infra dependency, disproportionate to this feature's scope.
