# Feature Specification: Editorial Redesign Rollout — Dashboard, Editor, Modal & Remaining Polish

**Feature Branch**: `003-editorial-redesign-rollout` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "continue the redesign the editorial new UI. The main pages are implemented. Let's continue the polish it. Implement it all through the pages and components. Some issues I find: 1. We use FlyonUI, we use `-soft` instead of `-ghost`, like `btn-soft`, not `btn-ghost`; 2. The articles are not required to have a cover, the cards should handle that. Maybe we generate a default(but unique) cover for those who don't have covers. 3. The home page and the `/articles` are mostly the same. Shouldn't we make the home page a fancy landing page?" — followed by: "Not enough. I mean redesign all the other views for the new editorial designs. The previous spec implemented the public pages. We have a lot of pages and components pending to redesign. We need to finish up. Not just the issues I mention."

*(`specs/002-editorial-ui-redesign/` (merged as PR #1822) redesigned five public-facing pages — home feed, article reader, author profile, search, and collections — and established the visual system (colors, typography, `-soft` component styling, `i-tabler-*` icons) in `docs/superpowers/specs/2026-07-03-ui-redesign-design.md`. That design doc explicitly deferred three surfaces as follow-up phases: the author dashboard/studio, the article editor, and the wallet-connect/login modal internals — plus it flagged the admin panel as an internal tool not addressed by the redesign at all. This spec is that follow-up: it finishes rolling the editorial design system out to every remaining authenticated surface, and folds in three smaller correctness/consistency issues found after the first pass shipped.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Correct Button & Badge Styling (Priority: P1)

As a visitor using any already-redesigned page (masthead, article header, article card), I see every button and badge rendered with its intended subtle, low-emphasis style — not an unstyled or visually broken control.

**Why this priority**: The design system is built on FlyonUI, which does not ship a `-ghost` modifier for buttons or badges (only `-soft` — confirmed against the installed FlyonUI package, which defines `.btn-soft`/`.badge-soft` but no `-ghost` equivalent for either). Every `btn-ghost`/`badge-ghost` class currently in the codebase has no matching CSS and renders unstyled, which is a visible correctness bug on already-shipped, high-traffic surfaces. This is the smallest, most self-contained fix and should land first.

**Independent Test**: Load any page that renders the masthead (icon buttons for notifications, dark-mode toggle, locale switcher, login) and any article card/header showing a locale badge; confirm every one of these controls has a visible low-emphasis background/hover treatment instead of appearing unstyled.

**Acceptance Scenarios**:

1. **Given** I am on any page with the masthead visible, **When** I look at the notification, dark-mode toggle, locale switcher, and login icon buttons, **Then** each shows a subtle background on hover/focus consistent with the platform's low-emphasis button treatment.
2. **Given** an article has a non-default locale, **When** its locale indicator is shown (in the article header or in a feed card), **Then** the indicator renders with a visible subtle pill background, not bare unstyled text.
3. **Given** I toggle between light and dark mode, **When** I view these same controls, **Then** the low-emphasis styling remains visibly correct in both themes.

---

### User Story 2 - Unique Default Cover for Articles Without One (Priority: P2)

As a reader browsing the feed, search results, an author's profile, or a collection, I see a distinct, visually pleasing thumbnail for every article — even ones the author never uploaded a cover image for — instead of a generic empty-box placeholder or a missing image.

**Why this priority**: A cover image is optional when publishing, so a large share of articles have none. This is a visible, everyday polish gap across every listing surface delivered in the prior redesign, but it doesn't block or depend on the other stories.

**Independent Test**: Find or create several published articles with no cover image and confirm each shows its own distinct generated cover (not the same placeholder repeated, and not a blank/broken image) everywhere article thumbnails appear.

**Acceptance Scenarios**:

1. **Given** an article has no cover image and no usable image in its content, **When** it is shown in the feed, search results, an author profile, or a collection, **Then** it displays a generated default cover instead of a blank placeholder icon.
2. **Given** two different articles both lack a cover image, **When** their thumbnails are shown side by side, **Then** the two generated covers are visually distinct from each other.
3. **Given** the same cover-less article is viewed again later (same session or a different one), **When** its generated cover is displayed, **Then** it looks identical every time (stable, not randomized per view).
4. **Given** an article without a cover image is shared externally (e.g., a social preview link or notification card) or has its poster image generated, **When** the sharing surface needs an actual image file, **Then** a real generated cover image is used rather than leaving the preview image blank.
5. **Given** the generated default cover is displayed, **When** viewed in either light or dark mode, **Then** it remains visually coherent with the platform's design system in both.

---

### User Story 3 - Home Page as a Distinct Landing Experience (Priority: P3)

As a first-time or logged-out visitor arriving at the site's home page, I see a page that introduces Quill and its early-reader revenue-sharing model and invites me to explore or start writing — not a page that looks and behaves like a smaller, less complete copy of the `/articles` feed.

**Why this priority**: This is the most visible remaining gap on the public side (explicitly deferred as a follow-up in the original design doc) and is independent of the authenticated-surface work in later stories, so it rounds out the public-facing polish before moving on to logged-in surfaces.

**Independent Test**: Visit the home page as a logged-out desktop visitor and confirm it presents distinct introductory/value-proposition content and a curated set of articles, clearly different in composition from simply opening `/articles`; confirm the primary calls to action (explore articles, start writing) are present and functional.

**Acceptance Scenarios**:

1. **Given** I am a logged-out desktop visitor, **When** I open the home page, **Then** I see an introduction to Quill's value proposition (editorial publishing plus early-reader revenue sharing) that is not simply a smaller version of the `/articles` listing.
2. **Given** I am on the home page, **When** I look for a way to start reading, **Then** I see a clear call to action that takes me into the full article feed (`/articles`).
3. **Given** I am on the home page, **When** I look for a way to get started as an author, **Then** I see a clear call to action to write/connect a wallet, consistent with the masthead's existing primary action.
4. **Given** the home page shows a curated/featured set of articles, **When** I view it, **Then** those articles are presented distinctly from (not as an identical copy of) the default `/articles` feed list, and the page does not duplicate the full infinite-scrolling feed.
5. **Given** the platform has meaningful activity to show (published articles, authors, revenue shared with early readers), **When** I view the home page, **Then** that activity is reflected on the page in some illustrative form (e.g., a highlight or figure), reinforcing the platform's value proposition.
6. **Given** the platform has little or no data yet (e.g., no articles qualify for the curated section), **When** I view the home page, **Then** it still renders a complete, non-broken page rather than an empty gap where the curated section would be.
7. **Given** I am on the home page, **When** I toggle light/dark mode or view it on a range of desktop widths, **Then** the new landing content remains legible and well-laid-out in both themes and at those widths.

---

### User Story 4 - Author Dashboard/Studio Redesign (Priority: P4)

As a logged-in author or reader using my dashboard (stats, my readings, my authored articles, notifications, orders, payments, transfers, subscriptions, settings, and every other dashboard section), I see the same editorial visual language — colors, typography, icons, and component styles — used on the public pages, instead of the old pre-redesign look.

**Why this priority**: The dashboard is the single largest remaining surface (over twenty distinct sections) and the one every logged-in user interacts with constantly, making it the highest-value remaining piece of the rollout after the smaller public-side fixes above.

**Independent Test**: Log in and visit every top-level dashboard section (home/stats, my readings, my authoring, notifications and their settings, orders, payments, transfers, subscriptions and their sub-tabs, block list, access tokens, collections management, profile settings); confirm the navigation shell, typography, colors, icons, and interactive components (buttons, badges, tags, tabs, empty states) all match the editorial system rather than the prior visual style.

**Acceptance Scenarios**:

1. **Given** I am logged in on a desktop-width screen, **When** I open any dashboard page, **Then** I see the existing left-sidebar navigation shell, restyled to the editorial system's colors, typography, and icon set — the sidebar's navigational structure and links are unchanged, only its visual treatment is updated.
2. **Given** I am on any dashboard page, **When** I read headings, labels, and body text, **Then** they use the same typography roles (serif headline / sans body) established for public pages.
3. **Given** I am on any dashboard page, **When** I view buttons, badges, tags, tabs, and empty states, **Then** they use the same component styles (including the `-soft` low-emphasis treatment from User Story 1) as the redesigned public pages, not the prior styling.
4. **Given** I am on a dashboard page that previously used the old per-category tag colors or hand-rolled icons, **When** I view it now, **Then** tags use the neutral chip style and icons use the platform's icon system, consistent with the rest of the product.
5. **Given** I switch between light and dark mode on any dashboard page, **When** the theme changes, **Then** all dashboard content remains legible and visually correct in both themes.
6. **Given** I use the dashboard on a mobile-width screen, **When** I navigate using the existing mobile top bar and bottom tab bar, **Then** those mobile navigation elements are restyled to match the editorial system as well, with their existing structure/behavior unchanged.
7. **Given** a dashboard page has no data yet (e.g., no notifications, no orders, no transfers), **When** I view it, **Then** it shows a clear, friendly empty state consistent with the one used on public pages.

---

### User Story 5 - Article Editor Redesign (Priority: P5)

As an author writing or editing an article, I use an editor whose visual design (typography, colors, toolbar, and surrounding chrome) matches the rest of the redesigned product, so the writing experience feels like part of the same product as reading and publishing.

**Why this priority**: The editor is a distinct, self-contained surface (its own layout, not shared with the dashboard or public pages) reached only when actively writing, so it's lower-frequency than the dashboard but still an important, fully redesigned experience per this rollout's scope.

**Independent Test**: Create a new article and edit an existing one; confirm the editor's chrome (title/intro fields, toolbar, settings panels for price/revenue split/cover/tags/references, action buttons) is visually redesigned to match the editorial system, and confirm the written content itself still previews using the same typography as the public article reader.

**Acceptance Scenarios**:

1. **Given** I open the "new article" or "edit article" screen, **When** the page loads, **Then** its overall chrome (header, field labels, toolbar, buttons) uses the editorial system's colors and typography rather than the prior visual style.
2. **Given** I am writing article content, **When** I view the editing surface, **Then** its typography is visually consistent with how the same content will appear to readers on the article page.
3. **Given** I open editor panels for settings (price, revenue split, cover upload, tags, references), **When** I interact with them, **Then** their controls (buttons, inputs, tabs, badges) use the redesigned component styles.
4. **Given** I switch between light and dark mode while writing, **When** the theme changes, **Then** the editor remains legible and visually correct in both themes.
5. **Given** I am on a mobile-width screen, **When** I use the editor, **Then** it remains fully usable without horizontal scrolling or overlapping controls.

---

### User Story 6 - Wallet-Connect / Login Modal Redesign (Priority: P6)

As a visitor or logged-in user opening the "connect wallet" / login modal (from any trigger point across the product), I see a modal whose visual design matches the rest of the redesigned product.

**Why this priority**: The modal is a small, self-contained surface reached only momentarily (at login), making it the lowest-effort and lowest-frequency piece of this rollout, appropriate to finish last.

**Independent Test**: Trigger the login/connect-wallet modal from a logged-out state on both a public page and a dashboard-adjacent entry point; confirm its visual design (colors, typography, button styles, spacing) matches the editorial system, and confirm it still successfully starts the wallet connection flow.

**Acceptance Scenarios**:

1. **Given** I am logged out and I click any "Connect Wallet" / "Write" trigger, **When** the modal opens, **Then** its visual design (colors, typography, buttons, links) matches the editorial system used elsewhere.
2. **Given** the modal is open, **When** I complete the connection flow, **Then** the underlying wallet-connection behavior is unchanged from before this redesign.
3. **Given** I open the modal in either light or dark mode, **When** I view it, **Then** it remains legible and visually correct in both themes.

---

### Edge Cases

- What happens when an article's locale badge or a masthead icon button is focused via keyboard (not just hovered)? The corrected low-emphasis styling MUST remain visible and distinguishable in the focus state as well.
- What happens when an article's title is unusually short, empty, or contains only emoji/symbols? Generated default cover text/graphics (if any) MUST still render cleanly without overflow or a blank result.
- What happens when an article that previously had a generated default cover has a real cover image uploaded later? The real cover MUST take over immediately and the generated cover MUST no longer appear for that article.
- What happens when the home page's curated/featured section would otherwise include an article the current context shouldn't show (e.g., a blocked author, an unpublished draft)? The same visibility rules already applied to the main feed MUST apply to the home page's curated selection.
- What happens when a visitor lands on the home page on a narrow/tablet-width desktop browser (not mobile, so not redirected)? The landing content MUST remain usable without horizontal scrolling or overlapping elements.
- What happens on a dashboard page that has a right-hand widget rail today (mirroring the old public-page layout)? It MUST either be restyled consistently with the sidebar/content shell or, where the sidebar shell makes it redundant, removed — but a dashboard page MUST NOT be left showing a visually inconsistent mix of old- and new-style chrome.
- What happens to dashboard sections with heavy tabular/list data (orders, transfers, payments)? Tables/lists MUST remain fully readable and correctly styled under the new typography and color tokens, not just the surrounding chrome.
- What happens when an author has an in-progress draft open in the editor and their session's theme (light/dark) changes mid-session? The editor MUST update immediately without losing unsaved content.
- What happens when the wallet-connect modal is opened from within an already-authenticated dashboard context (e.g., a re-auth prompt) versus from a logged-out public page? Its redesigned appearance MUST be identical regardless of the trigger point.

## Requirements *(mandatory)*

### Functional Requirements

**Buttons & badges (User Story 1)**

- **FR-001**: Every button and badge on the redesigned pages that currently uses a `-ghost` style modifier MUST instead use the platform's supported low-emphasis (`-soft`) style modifier, since the design system in use does not provide a `-ghost` variant.
- **FR-002**: The corrected low-emphasis button/badge styling MUST be visibly correct (background/hover/focus states all present) in both light and dark appearance.

**Default article covers (User Story 2)**

- **FR-003**: Any article preview or thumbnail shown anywhere in the product (feed, search results, author profile, collection, and any share/preview surface) for an article that has no uploaded cover image and no usable image in its own content MUST display a generated default cover instead of a blank or generic icon-only placeholder.
- **FR-004**: The generated default cover for an article MUST be deterministic per article — the same article always produces the same-looking default cover — and MUST be visually distinct between different articles so that two cover-less articles do not appear identical.
- **FR-005**: When a surface requires an actual fetchable image file for an article that has no real cover (e.g., a social share preview, a notification card, or a generated article poster), the system MUST supply a real generated cover image rather than omitting the image.
- **FR-006**: If an article gains a real uploaded cover image after previously having none, every surface MUST show the real cover from then on, not the previously generated default.
- **FR-007**: The generated default cover MUST remain visually coherent with the platform's existing design system (colors/typography) in both light and dark appearance.

**Home landing page (User Story 3)**

- **FR-008**: The home page MUST present introductory/value-proposition content about the platform (editorial publishing and its early-reader revenue-sharing model) that is not simply a smaller copy of the `/articles` feed page.
- **FR-009**: The home page MUST include a clear, functioning call to action that leads a visitor into the full article feed (`/articles`).
- **FR-010**: The home page MUST include a clear, functioning call to action for starting to write/publish, consistent with the primary action already used elsewhere in the product (write / connect wallet).
- **FR-011**: The home page MUST present a curated or featured selection of articles distinct in composition and presentation from the default, unfiltered, infinite-scrolling `/articles` feed — it MUST NOT re-embed that same feed as its primary content.
- **FR-012**: The home page's curated/featured article selection MUST respect the same visibility rules as the main feed (e.g., excluding blocked authors and unpublished drafts).
- **FR-013**: The home page MUST render a complete, non-broken layout even when there is insufficient data for the curated/featured section (e.g., a new platform with very few published articles).
- **FR-014**: The home page MUST remain legible and fully usable (no horizontal scrolling, no overlapping elements) across supported desktop widths and in both light and dark appearance.

**Author dashboard/studio (User Story 4)**

- **FR-015**: Every dashboard section (home/stats, readings, authoring, notifications and their settings, orders, payments, transfers, subscriptions and their sub-tabs, block list, access tokens, dashboard-side collection management, and profile/account settings) MUST be visually updated to the editorial design system (colors, typography, icons, component styles), while preserving its existing navigation structure, routes, and functional behavior.
- **FR-016**: The dashboard MUST keep its existing left-sidebar navigation shell on desktop widths, and its existing mobile top-bar/bottom-tab-bar navigation on mobile widths — this redesign restyles that shell's visuals only; it does not replace it with the public pages' top-nav masthead.
- **FR-017**: All dashboard buttons, badges, tags, tabs, and empty states MUST use the same component treatments established for public pages (including the `-soft` correction from FR-001 and the neutral tag-chip style), not the prior per-page or per-category styling.
- **FR-018**: All hand-rolled icons still in use on dashboard pages MUST be migrated to the platform's icon system already adopted on public pages, consistent with how public-page icon migration was done in the prior redesign.
- **FR-019**: Dashboard pages MUST support both light and dark appearance with the same fidelity as the redesigned public pages.
- **FR-020**: Dashboard pages remain accessible only to authenticated users exactly as they are today; this feature does not change authentication, authorization, or data behavior for any dashboard section.

**Article editor (User Story 5)**

- **FR-021**: The article creation and editing screens (including their settings panels for price, revenue split, cover, tags, and references) MUST be visually updated to the editorial design system's colors, typography, and component styles.
- **FR-022**: The editor's content-writing surface MUST use typography visually consistent with how that content is rendered to readers on the public article page.
- **FR-023**: The editor MUST support both light and dark appearance with the same fidelity as the redesigned public pages.
- **FR-024**: The editor MUST remain fully usable on mobile widths (no horizontal scrolling, no overlapping controls).
- **FR-025**: This redesign of the editor MUST NOT change what an author can do (available fields, settings, validations, or the publishing/saving flow) — only its visual presentation.

**Wallet-connect / login modal (User Story 6)**

- **FR-026**: The wallet-connect/login modal MUST be visually updated to the editorial design system (colors, typography, button and link styles), regardless of which page or trigger opened it.
- **FR-027**: The modal MUST support both light and dark appearance with the same fidelity as the rest of the redesigned product.
- **FR-028**: This redesign of the modal MUST NOT change the underlying wallet-connection/authentication behavior — only its visual presentation.

**Cross-cutting**

- **FR-029**: All changes in this feature MUST be applied consistently across every page and component where the affected pattern appears, not as one-off fixes on a single page.
- **FR-030**: The admin panel is explicitly out of scope for this feature and MUST NOT be modified; it retains its current presentation.

### Key Entities

- **Generated Default Cover**: A deterministically-derived visual (not an uploaded file) shown in place of an article's cover/thumbnail when the article has none; varies per article so that different cover-less articles are visually distinguishable from one another, and is stable across repeated views of the same article.
- **Home Landing Content**: The introductory, value-proposition, and call-to-action content unique to the home page, distinct from the plain article-feed content shown on `/articles`.
- **Curated/Featured Article Selection**: The subset of published articles highlighted on the home page, chosen and presented differently from the full, unfiltered `/articles` feed listing.
- **Dashboard Shell**: The existing left-sidebar (desktop) / top-bar-and-tab-bar (mobile) navigation structure used across all authenticated dashboard sections; its structure is preserved by this feature, only its visual styling changes.
- **Editor Shell**: The distraction-focused layout and toolbar surrounding the article-writing surface, separate from both the dashboard shell and the public-page masthead shell.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero instances of unstyled/broken-looking `-ghost` buttons or badges remain anywhere in the product (public pages, dashboard, editor, modal) in either light or dark mode.
- **SC-002**: 100% of article previews for cover-less articles display a generated default cover rather than a blank or generic placeholder, across every listing surface (feed, search, profile, collection).
- **SC-003**: Given the same cover-less article, its generated default cover looks identical on repeat views (0% visual drift across repeated loads).
- **SC-004**: Given two different cover-less articles, their generated default covers are visually distinguishable from one another in a side-by-side comparison.
- **SC-005**: A visitor can distinguish the home page from the `/articles` feed within the first screen of content, based on presence of introductory/value-proposition content not found on `/articles`.
- **SC-006**: The home page offers at least two clear calls to action (explore articles, start writing) that are reachable and functional without scrolling past a large, non-actionable area.
- **SC-007**: 100% of dashboard sections (all sections listed in FR-015) visually match the editorial design system (colors, typography, icons, component styles) when reviewed page by page — zero sections retain the prior pre-redesign visual style.
- **SC-008**: The article editor and the wallet-connect/login modal visually match the editorial design system with the same fidelity as the redesigned public pages.
- **SC-009**: All updated pages/components (public, dashboard, editor, modal) continue to meet WCAG AA contrast for text and interactive-control states in both light and dark appearance.
- **SC-010**: No functional regressions: every dashboard action, editor capability, and the wallet-connection flow behave identically to before this feature, verified by the existing automated test suite continuing to pass.

## Assumptions

- This feature builds on top of `specs/002-editorial-ui-redesign/` (already implemented and merged) and inherits its design system (colors, typography, monochrome + one accent, `-soft`/neutral component treatments, `i-tabler-*` icons) rather than introducing a new visual language.
- **Admin panel is excluded** from this feature's scope, per explicit user decision — it remains an internal tool addressed in a future, separate effort if ever needed.
- **The author dashboard/studio keeps its existing left-sidebar (desktop) and top-bar/tab-bar (mobile) navigation shell**, per explicit user decision — this feature restyles that shell to the editorial system's visual language but does not restructure it into the public pages' top-nav masthead pattern.
- **The article editor and the wallet-connect/login modal receive a full visual redesign** (not just a lighter token/color pass), per explicit user decision — their layout, chrome, and component presentation are redesigned to match the editorial system, while their underlying functionality (fields, validations, save/publish flow, authentication) is unchanged.
- "Generated default cover" means a platform-generated visual (e.g., a deterministic gradient/pattern derived from the article, in the spirit of the existing deterministic-color initials placeholder already used for user avatars without a photo) — not a stock photo library, not AI-generated imagery, and not requiring the author to pick one manually. The exact visual treatment is a design/implementation decision for the planning phase; this spec only requires that it be deterministic, distinct per article, and visually coherent with the design system.
- Existing routing behavior — where logged-in users and mobile-device visitors are redirected from the home page straight to `/articles` — is unchanged by this feature. This feature only redesigns what a logged-out desktop visitor sees at the home page itself.
- The home page's curated/featured article selection may reuse existing platform logic for identifying notable articles (e.g., recent high-performing articles, potentially the already-implemented but currently unused `selected_articles` endpoint from the prior redesign); the precise curation rule is an implementation detail left to planning, as long as FR-011/FR-012 (distinct from the plain feed, same visibility rules) are satisfied.
- No new user-facing settings, author controls, permission changes, or database schema changes are implied by this feature — it is a presentation-layer rollout, consistent with `specs/002-editorial-ui-redesign/`'s own assumptions. Every dashboard route, editor capability, and authentication behavior is preserved exactly as-is; only visual presentation changes.
- Given the scope (public polish + dashboard + editor + modal), this feature is expected to be delivered incrementally by user-story priority (P1–P6), matching the pattern used in `specs/002-editorial-ui-redesign/tasks.md`, rather than as a single atomic change.
