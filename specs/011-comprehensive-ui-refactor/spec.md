# Feature Specification: Comprehensive UI Refactor on the Value-Net Design System

**Feature Branch**: `011-comprehensive-ui-refactor` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-08-27

**Status**: Draft

**Input**: User description: "Review the redesign of Quill in opendesign using MCP, and then implement it. Build up a well-maintained design system, then refactor the UI design for every view."

*The approved visual direction is captured in `docs/superpowers/specs/2026-07-03-ui-redesign-design.md` and the redesign prototype is bound to OpenDesign project `f69be881-fe22-4183-87c7-4cb7179540ff` ("Quill 界面重设计规划") with `brand-spec.md` + `assets/style.css` as the canonical design-system source-of-truth and one HTML prototype per surface (`index.html`, `feed.html`, `search.html`, `author-profile.html`, `collection.html`, `reader.html`, `editor.html`, `dashboard.html`, `components.html`). Prior specs (`002-editorial-ui-redesign`, `003-editorial-redesign-rollout`, `005-dashboard-ux-redesign`, `006-editorial-ui-polish`, `010-editor-progressive-disclosure`) shipped fragments of this system in isolation. This spec supersedes those fragments: it treats the design system as a single, well-maintained layer that every view (public, dashboard, editor, admin, error pages, API-flavored responses) must consume, and it closes the remaining gaps so the product feels like one coherent editorial Web3 product rather than a patchwork of partial rollouts.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One Well-Maintained Design System (Priority: P1)

As a developer or AI agent extending Quill, I open a single, authoritative "design system" entry point and find every token, every primitive component, every pattern I need to build or modify any view — without having to hunt through view-specific partials or guess what styles already exist.

**Why this priority**: Every prior spec stopped at "make this view use the editorial system." None of them gave us a single place to discover tokens, components, and conventions, nor a clear contract that the rest of the app must follow. Without that, the next 12 months of view work will keep reinventing the wheel (new chip styles, new button colors, new card variants) and the "editorial" feel will drift. This story is the foundation; nothing else ships without it.

**Independent Test**: Open the new design-system documentation page (a server-rendered live reference backed by the same components the app uses), confirm it covers tokens (color, type, radius, spacing), primitives (buttons, chips, list row, card, form fields, tabs, modal, dropdown, value-net components, notification cards, states), and patterns (masthead, page shell, dark mode, mobile). Confirm it is generated from real, in-app code — not a separate design-tool mock — so any drift is impossible.

**Acceptance Scenarios**:

1. **Given** I am a new contributor opening the design-system entry point, **When** I read it, **Then** I see every token (color, type, spacing, radius) used in the app, with both light and dark values, organized by role.
2. **Given** I want to build a new view, **When** I look up components, **Then** I find a documented primitive for every UI element used elsewhere in the product (button, chip, card, list row, form field, tab, modal, dropdown, value-net widget, notification card, state treatment, skeleton, avatar).
3. **Given** I want to extend an existing primitive, **When** I look it up, **Then** I see its single source-of-truth partial and the named utility classes that drive it.
4. **Given** I add a new color, type ramp, or component, **When** I do not register it in the design system, **Then** linting (RuboCop + a Tailwind/CSS lint check) flags it as a violation.
5. **Given** the design system changes (token, component variant), **When** I refresh any view, **Then** that change is reflected everywhere automatically — no per-view edits required.

---

### User Story 2 - Public Surfaces All Share One Editorial Voice (Priority: P2)

As a reader or first-time visitor, every public page I land on — home feed, article reader, search results, author profile, collection, "about" / marketing pages, login wall, error pages — feels like the same product: same masthead, same column rhythm, same serif headlines, same monospace meta, same near-grayscale palette with one cobalt accent and one muted-amber reward tint.

**Why this priority**: The five public pages touched by `specs/002/003` are not actually uniform yet — the article reader still uses different proportions, search uses a different masthead treatment, and error/login pages haven't been touched at all. A first-time visitor sees two or three different visual languages depending on the page they hit first, which undermines the editorial positioning the redesign is meant to establish.

**Independent Test**: Visit every public route in sequence (home, feed, search, author profile, collection, article reader, login, 404, 500) and confirm the masthead, palette, typography, spacing scale, and interactive component vocabulary are visually consistent across all of them; verify both light and dark modes.

**Acceptance Scenarios**:

1. **Given** I open the home feed, **When** I navigate to the article reader, **Then** the masthead, palette, typography, and interactive controls all match without seams.
2. **Given** I open any public page, **When** I toggle dark mode, **Then** the entire page (including previously-untouched error and login walls) flips consistently and stays legible.
3. **Given** I land on a 404 or 500 page from any of these surfaces, **When** it renders, **Then** it uses the editorial system (serif headline, neutral palette, accent CTAs) instead of the default Rails error styling.
4. **Given** I open the login / connect-wallet modal from any public page, **When** it appears, **Then** it uses the editorial modal shell from the design system (header typography, body spacing, focus rings, dark-mode correctness).
5. **Given** I open search from the masthead, **When** results render, **Then** they use the same Minimal List row used by the feed and author profile — no bespoke search-result markup.

---

### User Story 3 - Authoring Surfaces (Dashboard + Editor) Match the System (Priority: P3)

As an author working in the dashboard (financial overview, articles table, settings, notifications) or in the article editor, every screen I touch uses the same tokens, typography, and components as the public surfaces — with a denser left-rail information architecture for the studio, as the design system already prescribes — so the product feels like one coherent tool rather than two half-redesigned products.

**Why this priority**: Dashboard restyling shipped under `specs/003` and `005`, but the editor (`specs/004`, `010`) is a separate code path with its own partials and markup conventions. Any author who reads an article (public visual) and then opens the editor (separate visual) feels a jarring seam. Closing that seam is the second-largest trust signal for the editorial Web3 positioning.

**Independent Test**: Open an article reader and the article editor side-by-side; confirm the typography ramp, palette, button styles, chip styles, and modal shells all match. Then open every dashboard surface (overview, articles list, article settings, comments, payments, transfers, notifications, account settings) and confirm each one uses the system's components, not bespoke styling.

**Acceptance Scenarios**:

1. **Given** I open the article editor, **When** I look at the toolbar, cover picker, tags input, pricing controls, and reward split calculator, **Then** they use the same input, chip, button, and card primitives used everywhere else in the app.
2. **Given** I open the dashboard "Author studio," **When** I look at the left rail, top bar, stat cards, articles table, and split calculator, **Then** they use the same typography, palette, and component vocabulary as the public surfaces.
3. **Given** I open the dashboard on a mobile-width screen, **When** the left rail collapses, **Then** it collapses to the same mobile pattern (top bar + bottom tabbar) the public surfaces already use.
4. **Given** I open a destructive confirmation in the dashboard (delete article, cancel transfer, revoke token), **When** it appears, **Then** it uses the system modal shell, not a bespoke Rails confirmation.
5. **Given** I view any chart, table, or numeric display in the dashboard, **When** I look at the numbers, **Then** they use the mono font ramp from the design system, not the body font.

---

### User Story 4 - Admin, API Error Pages, and Notifications Also Speak the System (Priority: P4)

As an administrator, an API consumer, or a reader checking notifications, every screen I land on uses the same editorial system — so even the "internal" surfaces feel like part of the same product rather than a leftover from before the redesign.

**Why this priority**: Admin (`specs/003` touched visuals, but admin has its own admin layout), API error payloads, and notifications are the long tail of surfaces that quietly say "this is a different product" to anyone who hits them. The user-visible damage is small per surface, but cumulatively it keeps the product from feeling finished.

**Independent Test**: Open the admin panel (any index, any form), trigger an API error from the JSON endpoint, and open the notification inbox; confirm each surface uses the system's tokens, components, and shells in both light and dark mode.

**Acceptance Scenarios**:

1. **Given** I open the admin panel, **When** I navigate any index or form, **Then** it uses the editorial system (palette, typography, button styles, table styles, modal shells) — not the previous admin-only styling.
2. **Given** an API request fails, **When** the JSON error response is rendered for a browser hit, **Then** the human-readable HTML error page uses the editorial system.
3. **Given** I open my notification inbox, **When** I view each notification card, **Then** the card uses the system notification component (icon, title, body, timestamp, unread state), in both light and dark mode.
4. **Given** I receive a real-time broadcast notification, **When** it appears in the toast/banner, **Then** it uses the same shell as the inbox card.

---

### Edge Cases

- What happens when the user has a custom OS font scale, a screen-reader, or high-contrast mode enabled? — All primitives must use semantic tokens, never hardcoded hex values, and must respect system font-size preferences up to 200%.
- What happens when a view was previously migrated by `specs/002/003/005/006/010` to use fragments of the editorial system but still has a hand-rolled SVG icon or a stray indigo color? — The refactor pass must absorb those leftovers, not leave them as exceptions.
- What happens when a developer adds a new view without using the design-system primitives? — Linting (RuboCop + a Tailwind/CSS check) must flag it.
- What happens when a third-party component (Lexxy editor, Solid Queue admin, Mission Control) ships its own styles? — Those surfaces are explicitly out of scope unless the design system already covers them; the refactor must not fork those third-party styles.
- What happens when dark mode is toggled mid-session? — The entire app must re-render without a flash of unstyled content or color drift across previously-untouched surfaces.
- What happens when CJK content (Chinese, Japanese, Korean) is rendered? — The type stack must use the CJK fallback chains from the design system, not browser defaults.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose a single, in-app design-system entry point (a route + page) generated from the same tokens and components the rest of the app consumes, listing every token (color, type, spacing, radius) and every primitive (button, chip, card, list row, form field, tab, modal, dropdown, value-net widget, notification card, state treatment, skeleton, avatar).
- **FR-002**: System MUST enforce that no view introduces a new color, type ramp, or component without registering it in the design system first; this is enforced by RuboCop + a Tailwind/CSS lint check that fails CI on violations.
- **FR-003**: System MUST apply the editorial system to every public surface: home feed, article reader, search results, author profile, collection, login / connect-wallet modal, 404, 500, marketing / "about" pages.
- **FR-004**: System MUST apply the editorial system to every authoring surface: dashboard (left-rail shell, stat cards, articles table, split calculator, settings, notifications, account), article editor (toolbar, cover picker, tags input, pricing, reward split, publish flow).
- **FR-005**: System MUST apply the editorial system to the admin panel, API error HTML responses, and the notification inbox + real-time toast.
- **FR-006**: System MUST support first-class dark mode on every surface listed in FR-003, FR-004, and FR-005, with no flash of unstyled content on toggle.
- **FR-007**: System MUST preserve accessibility baseline (semantic HTML, keyboard-operable controls, visible focus states, sufficient contrast) on every surface listed above.
- **FR-008**: System MUST preserve all existing i18n keys and add any new user-visible strings to the locale files (`config/locales/`); no hardcoded English.
- **FR-009**: System MUST preserve existing functionality (every button still performs the same action, every route still serves the same data, every payment flow still works) on every surface listed above.
- **FR-010**: System MUST consolidate duplicated partials (`_modal.html.erb`, `_dropdown.html.erb`, `_masthead.html.erb`, `_navbar.html.erb`, `_tabbar.html.erb`, `_ui_card.html.erb`, `_ui_input.html.erb`, etc.) into a single source of truth per pattern, so subsequent changes touch one file.
- **FR-011**: System MUST migrate every hand-rolled inline SVG icon on a touched surface to the `i-tabler-*` icon utility class.
- **FR-012**: System MUST remove the `tag-style-0..5` utility classes and replace them with a single neutral tag-chip primitive.
- **FR-013**: System MUST keep the existing FlyonUI radius tokens (`--radius-selector`, `--radius-field`, `--radius-box`) intact; no wholesale token rewrite.
- **FR-014**: System MUST preserve all existing routes, controllers, and models; this refactor is presentation-only.
- **FR-015**: System MUST ensure all CSS values come from the token layer (Tailwind theme tokens, CSS custom properties) — no hardcoded hex values, no hardcoded pixel sizes outside the spacing scale, no hand-rolled `@apply` chains.
- **FR-016**: System MUST use the brand-spec typography stack (Newsreader / Noto Serif SC for display, Inter / Noto Sans SC for body + UI, Roboto Mono / JetBrains Mono for mono) consistently.
- **FR-017**: System MUST use the brand-spec color palette (near-grayscale + one cobalt accent + one muted-amber reward tint) consistently.
- **FR-018**: System MUST enforce that the cobalt accent appears at most twice per screen (eyebrow + primary CTA as the default budget), per the brand spec.
- **FR-019**: System MUST enforce that the reward / early-reader tint is text-only, never a filled badge.
- **FR-020**: System MUST preserve all existing behavior tests; add new system tests that assert visual primitives are reachable from the design-system entry point and that lint checks pass.

### Key Entities *(include if feature involves data)*

- **DesignToken**: A named design-time value (color, font, radius, spacing) referenced by every component; lives in the Tailwind theme and `application.tailwind.css`; the design-system entry page renders its current state.
- **Primitive**: A reusable UI building block (button, chip, card, list row, form field, tab, modal, dropdown, value-net widget, notification card, state treatment, skeleton, avatar) defined as a single ERB partial + Stimulus controller where needed; rendered by every view that uses it.
- **Surface**: A user-visible screen (one per route family: public, dashboard, editor, admin, API, error); each surface lists the primitives it composes from and is verified by the design-system entry page.
- **DesignSystemLintViolation**: A CI-detected occurrence of a hand-rolled color, type ramp, icon, or component outside the design system; the check fails the build.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new contributor can identify the single source-of-truth for every token and every primitive used in the app from one in-app design-system page within 5 minutes of opening the project.
- **SC-002**: 100% of public surfaces (home feed, article reader, search, author profile, collection, login modal, 404, 500, marketing) use the editorial system — verified by an automated visual-primitives test that asserts each surface mounts at least one shared primitive.
- **SC-003**: 100% of authoring surfaces (dashboard overview, articles list, article settings, comments, payments, transfers, notifications, account; article editor toolbar, cover picker, tags input, pricing, reward split, publish flow) use the editorial system — verified by the same automated test.
- **SC-004**: 100% of admin, API error HTML, and notification inbox / toast surfaces use the editorial system — verified by the same automated test.
- **SC-005**: The number of unique button styles, chip styles, card styles, modal shells, and input fields across the app drops to ≤ 3 variants of each primitive (primary + soft + ghost for buttons; topic + price + status for chips; etc.) — measured by a one-off grep audit documented in the design-system page.
- **SC-006**: Zero hand-rolled inline SVG icons remain on touched surfaces; every icon is rendered via `i-tabler-*` (or another documented icon utility) — verified by a lint check.
- **SC-007**: Zero hardcoded hex colors outside the token layer on touched surfaces — verified by a lint check.
- **SC-008**: First-class dark mode is correct on every touched surface (no flash, no contrast violations, no unmapped tokens) — verified by a manual screenshot review + an automated contrast assertion.
- **SC-009**: Every existing controller test, model test, job test, notifier test, and system test continues to pass; the full test suite is green in CI.
- **SC-010**: `bin/rubocop` passes for touched Ruby, `bun run lint-check` passes for touched JavaScript, the new design-system lint check passes, and `bin/rails zeitwerk:check` passes.
- **SC-011**: LCP / INP / CLS on the home feed, article reader, and article editor are no worse than 5% above the pre-refactor baseline — measured with the existing frontend-efficiency measurement before and after, and tracked in the PR description.
- **SC-012**: A reader can complete the "buy an article" flow (open reader → unlock → pay → land back on the article) without visual seams between the public surface and the unlock modal — verified by a manual walkthrough.

## Assumptions

- The OpenDesign project `f69be881-fe22-4183-87c7-4cb7179540ff` is the canonical design reference; we translate its primitives into ERB partials and Tailwind classes rather than rewriting the visual system from scratch.
- The brand spec in `brand-spec.md` (six OKLCh tokens + Newsreader/Inter/Roboto Mono type stack + 8pt spacing scale) is authoritative; we extend the existing FlyonUI `quill` / `quill-dark` themes rather than introducing a new theme layer.
- The previously-shipped fragments (`specs/002/003/005/006/010`) are inputs to be absorbed, not parallel designs to be preserved; this spec supersedes them where they conflict.
- Mission Control / Solid Queue admin and the Lexxy editor's internals are third-party surfaces; we do not fork their styles, only the chrome around them.
- The Rails stack, Hotwire (Turbo + Stimulus), Tailwind v4, FlyonUI, and `@iconify/tailwind4` already in the repo are the implementation substrate; we do not introduce new frontend frameworks.
- Solid Queue jobs and admin (`/admin/jobs`) continue to use their stock UI; any design-system reach there is limited to the link/button chrome, not the embedded job table.
- The refactor is presentation-only; no model changes, no controller route changes, no behavior changes beyond the visual layer.
- The user is willing to accept a small increase in CSS size in exchange for a single, well-maintained design system; we will not micro-optimize every byte during this pass.