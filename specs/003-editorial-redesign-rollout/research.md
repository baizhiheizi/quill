# Phase 0 Research: Editorial Redesign Rollout

All items below were unknowns or open technical questions at spec time; each is resolved here before Phase 1 design. No `NEEDS CLARIFICATION` markers remain in `spec.md` — the three scope-defining questions were already resolved interactively with the user (recorded in spec.md's Assumptions). This document resolves the *technical approach* questions needed to plan confidently.

## 1. Is `btn-ghost`/`badge-ghost` really unstyled, or does FlyonUI alias it?

**Decision**: Treat every `btn-ghost`/`badge-ghost` occurrence as a hard bug; replace with `btn-soft`/`badge-soft`.

**Rationale**: Directly inspected the installed FlyonUI package (`node_modules/flyonui`, v2.4.1): `grep -o "\.btn-[a-z]*" components/button.css` and the equivalent for `components/badge.css` list `accent, active, block, circle, disabled, error, gradient, info, lg, md, neutral, outline, primary, secondary, sm, soft, square, success, text, warning, wide, xl, xs` for buttons and `accent, error, info, lg, md, outline, primary, secondary, sm, soft, success, warning, xl, xs` for badges — no `ghost` in either list. FlyonUI (a FlyonUI/DaisyUI-family library) simply doesn't ship this modifier; the classes render as bare, unstyled elements today.

**Current occurrences** (confirmed via repo-wide grep, all within pages already touched by `specs/002-editorial-ui-redesign/`):
- `app/views/shared/_masthead.html.erb`: 4× `btn-ghost` (notification bell, dark-mode toggle ×2, locale switcher/login icon buttons)
- `app/views/articles/_header.html.erb`: 1× `badge-ghost` (locale indicator)
- `app/views/articles/_card.html.erb`: 1× `badge-ghost` (locale indicator)

**Alternatives considered**: Keep `-ghost` and add custom CSS to make it a real modifier — rejected; would create a parallel, undocumented convention that fights the framework and every future FlyonUI upgrade.

## 2. What discovered inconsistency should ride along with the P1 fix?

**Decision**: Fix the leftover `font-serif` usage in `app/views/articles/_comments_card.html.erb` and `app/views/articles/_buyers.html.erb` (both rendered directly on the already-redesigned `articles/show.html.erb`) as part of this feature's cross-cutting consistency work (spec FR-029), replacing with `font-display` to match the rest of the article page.

**Rationale**: These two partials were missed during the original redesign (`specs/002-editorial-ui-redesign/`) and are visibly inconsistent with the rest of the same page today. Small, low-risk, same-file-family fix; bundling it with the P1 story (already touching nearby article-page files) avoids opening a second small PR for an unrelated one-line fix.

**Alternatives considered**: Leave for a separate ad-hoc fix — rejected; it's trivial to include here and the spec's FR-029 already covers "apply consistently, not as one-off fixes."

## 3. How should the "unique default cover" actually be generated and served?

**Decision**: Reuse the exact pattern already proven by `Collection#generate_cover` (`app/models/collection.rb`) and `Articles::PosterGenerator#generate_poster`/`generate_poster_async` (`app/models/concerns/articles/poster_generator.rb`, `app/jobs/articles/generate_poster_job.rb`): a small Grover (headless-Chrome) HTML template rendered server-side to a real PNG, then attached via ActiveStorage to the article's existing `cover` attachment slot. Trigger generation asynchronously the first time `thumb_url` would otherwise resolve to nil (no real cover, and no usable in-content image for free articles), mirroring `generate_poster_async`'s lazy-attach-on-first-access shape rather than `Collection`'s synchronous at-publish generation (articles' "usable content image" status can change after publish as content/price change, so publish-time-only generation isn't sufficient).

**Rationale**:
- This is a zero-new-dependency solution: Grover is already installed and used for exactly this kind of "render HTML to an image server-side" job.
- It automatically satisfies FR-005 (a *real, fetchable* image for share previews/notification cards/OG tags) for free, because the generated file becomes a normal ActiveStorage attachment indistinguishable from an author-uploaded cover to every downstream consumer (`cover_url`, `thumb_url`, `@page_image`, Mixin bot notification cards) — no per-surface special-casing needed.
- It automatically satisfies FR-006 (a later real upload wins): once an author uploads a real cover, `cover.attached?` reflects the new blob and the generator is simply never invoked again for that article; no extra bookkeeping needed to distinguish "generated" vs "real" beyond the attachment itself already being replaced.
- Determinism + uniqueness (FR-004) comes from seeding the Grover template's background (gradient hue/pattern) from a stable per-article value — the article's `uuid` — using the same hash-to-color approach already implemented client-side for user avatars (`app/javascript/utils/avatar.js`'s `colorFromSeed`), ported to a small Ruby equivalent (or an equivalent deterministic CSS gradient driven by the same seed) inside the new Grover template. This keeps "one deterministic-color-from-seed" as a single conceptual pattern reused across the product (avatars today, article covers here) rather than inventing a second, different generative-art approach.

**Current relevant code** (verified by reading, not assumed):
- `Articles::PosterGenerator#thumb_url` (`app/models/concerns/articles/poster_generator.rb:6-17`): today returns `cover_url` if attached, else (only when `free?`) the first absolute image URL found in rendered content, else `nil`. This priority order is preserved — the generated default cover becomes the new final fallback, replacing the current implicit `nil`.
- `ArticlesController#show` (`app/controllers/articles_controller.rb:39`) sets `@page_image = @article.thumb_url`; the layout's `@page_image ||= asset_url(...)` fallback (`app/views/layouts/application.html.erb:5`, `public.html.erb` equivalent) currently substitutes one single, non-unique static asset for every cover-less article whose `thumb_url` is `nil` — this is the concrete "generic icon-only placeholder" the spec's FR-003 refers to for the sharing-surface case, not a broken/blank image.
- `Collection#generate_cover` / `generated_cover_url` (`app/models/collection.rb:100-113`) and `app/views/grover/collections/cover.html.erb`: existing end-to-end precedent for "Grover-rendered template → `URI.parse(...).open` → `.attach`."
- `config/routes/grover.rb`: existing `namespace :grover do resources :articles, only: %i[], param: :uuid do get :poster end end` — adding `get :cover` alongside `get :poster` under the same `resources :articles` block yields a `grover_article_cover_url` following the exact naming convention already used for `grover_collection_cover_url`.

**Alternatives considered**:
- *Pure CSS/Stimulus placeholder (like the avatar placeholder)*: rejected as the sole solution because it cannot produce a real image file for crawlers/notification cards (FR-005) — but its color/seed *algorithm* is still reused inside the Grover template so the visual language and the "deterministic per seed" concept stay consistent product-wide.
- *Third-party identicon/avatar-generation gem or API (e.g., DiceBear)*: rejected — same reasoning already documented in the prior avatar-placeholder work (`openspec/changes/archive/2026-06-17-frontend-default-avatar/design.md`): adds a dependency for marginal benefit when the codebase already has a working in-house pattern.
- *Generate at publish time only (mirroring `Collection`)*: rejected as the sole trigger — an article's `free?`/content can change after publish in ways that affect whether `thumb_url` needs a fallback; lazy/on-demand generation (like the poster) handles this correctly without a re-check-on-every-update hook.

## 4. How should the dashboard shell be restyled without restructuring it?

**Decision**: Edit `app/views/shared/_left_bar.html.erb`, `_navbar.html.erb`, `_tabbar.html.erb`, and `app/views/layouts/application.html.erb` in place — same file names, same navigation structure/links/routes, only Tailwind utility classes, color tokens, typography classes, and icon references change (`inline_svg_tag` → `i-tabler-*` per FR-018, `font-serif`/ad hoc classes → `font-display`/`font-sans` tokens already defined in `application.tailwind.css` from the prior redesign).

**Rationale**: Directly matches the user's explicit decision (keep the left-sidebar shell) and the original design doc's own recommendation (§8: "keep a restyled left-sidebar shell here"). Since the theme tokens (`--color-primary`, `base-100/200/300`, `--font-display`, `--font-sans`) were already added to `application.tailwind.css` for the `quill`/`quill-dark` themes in the prior redesign, the dashboard shell inherits them automatically the moment old ad hoc color/font utility classes are replaced with the token-driven ones — no new theme work needed, only call-site updates.

**Scope check performed**: `find app/views/dashboard -type f | wc -l` → 77 files; `grep -rl "inline_svg_tag" app/views/dashboard | wc -l` → 10 files needing icon migration; `grep -rn "tag-style" app/` → zero remaining hits outside a code comment (already fully migrated in the prior redesign, confirmed nothing left for the dashboard rollout to do here beyond adopting the neutral `tag-chip` utility on any dashboard-side tag displays, e.g. `dashboard/subscribe_tags/_tag.html.erb`, which the prior redesign's T014 already migrated).

**Alternatives considered**: Convert dashboard to the public top-nav masthead shell — explicitly rejected by the user's decision (adds structural risk/scope with no requested benefit; a denser sidebar nav is more appropriate for a studio context per the original design doc).

## 5. How should the article editor be redesigned given its distinct toolbar/writing-surface needs?

**Decision**: Full visual redesign of the editor's own chrome — `layouts/editor.html.erb` (theme token parity, since it currently duplicates rather than shares markup with `layouts/application.html.erb`/`public.html.erb`), the sticky top bar in `articles/_edit_form.html.erb` and `articles/new.html.erb` (icon migration, button style parity with `-soft`/primary conventions established in US1), the `articles/_form.html.erb` title/intro fields (title field moves from generic `font-bold` to `font-display`, matching how the same title renders as a headline on the public article page and in feed cards), and the settings panels in `articles/_option_fields.html.erb` (271 lines — price, revenue split, cover upload, tags, references — restyled to use the same component classes as the rest of the redesigned product). The `article-form` Stimulus controller (autosave, dirty-tracking, tab switching) and all form field names/params are unchanged.

**Rationale**: The editor is structurally simple today (no left sidebar, no right rail — just a centered column under a slim sticky top bar, per `layouts/editor.html.erb`), so "full redesign" here means visual-language parity plus toolbar polish, not a structural rebuild. Matching the title field's typography to `font-display` directly serves FR-022 ("editor's content-writing surface MUST use typography visually consistent with how content is rendered to readers").

**Alternatives considered**: A lighter, tokens-only pass (colors/fonts, no component-level changes) — explicitly rejected by the user's decision in favor of a full redesign of the editor's chrome and panels.

## 6. How should the wallet-connect/login modal be redesigned?

**Decision**: Full visual redesign of `app/views/sessions/new.html.erb` (the modal's content — currently a mix of already-updated (`btn-soft btn-primary` on the Mixin button) and not-yet-updated (plain `btn-primary rounded-full` fallback links) styling). The `shared/_modal.html.erb` wrapper itself was found to already be close to the target system (`btn-text` close-button, `icon-[tabler--x]` Tabler icon) — verify only, adjust if any inconsistency is found during implementation, since it's shared by every modal in the product (not just login) and changing it has a wide blast radius.

**Rationale**: `sessions/new.html.erb` is small (44 lines) and self-contained; a full redesign here is low-risk and matches the user's decision. The shared `_modal.html.erb` wrapper is intentionally treated conservatively (verify-then-adjust, not wholesale rewrite) because it's reused by every other modal in the app (share, locale switcher, publish confirmation, etc.), which are out of this feature's explicit scope — changing its structure could have unintended effects on those unrelated modals.

**Alternatives considered**: Redesign `_modal.html.erb` itself as part of this story — rejected; the wrapper isn't broken today and touching it risks unrelated, out-of-scope modals (locale switcher, share dialog) regressing without being covered by this feature's testing/QA scope.

## 7. What is the home page's curated/featured section built from?

**Decision**: Revive and restyle the already-implemented-but-currently-unused `HomeController#selected_articles` action and `home/selected_articles.html.erb` view (both still present in the codebase and routed at `/selected_articles`, but no longer referenced from `home/index.html.erb` since the prior redesign's T010 explicitly dropped that embed to ship a minimal MVP first). It already calls `ArticleSearchService.call(filter: "revenue", time_range: "month").limit(6)`, which — being built on the shared `ArticleSearchService` — already inherits the same visibility rules as the main feed (blocked authors, drafts) per FR-012.

**Rationale**: Avoids reinventing curation logic; the prior redesign's own plan explicitly flagged this as "a separate follow-up, not part of this redesign" (design doc §7) and left working code in place for exactly this moment. Reusing it also means FR-012 (same visibility rules as the main feed) is satisfied by construction, not by new logic.

**Alternatives considered**: Build a new curation query — rejected as unnecessary duplication when a working, already-tested query exists; can be revisited later if "revenue this month" turns out not to be the desired curation rule, but that's an independent follow-up, not a blocker for this feature.

## 8. Testing approach for surfaces with little or no existing automated coverage

**Decision**: No new system/Capybara test suite is introduced wholesale. Extend `test/models/concerns/articles/poster_generator_test.rb` with new cases for the default-cover fallback behavior (deterministic, distinct, upload-overrides-generated). Run the full existing suite (`bin/rails test`, `bin/rubocop`, `bun run lint-check`) after each user story, matching `specs/002-editorial-ui-redesign/tasks.md`'s own QA approach, since Capybara/Selenium system tests can't launch a browser in this sandbox environment (documented limitation already noted in the prior feature's `T018`). Manual QA checklists per story are captured in `quickstart.md`.

**Rationale**: Matches the testing depth and rationale already established and accepted for `specs/002-editorial-ui-redesign/`; this is a presentation-layer rollout, not new business logic, so the highest-value automated coverage is the model-level default-cover contract (a genuinely new behavior) plus regression-running the existing suite.

**Alternatives considered**: Write new Capybara system tests per redesigned page — rejected for this environment (documented sandbox limitation), deferred to manual QA before merge, same as the prior feature.
