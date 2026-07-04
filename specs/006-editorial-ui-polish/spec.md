# Feature Specification: Editorial UI Polish Pass — Components, Icons & Interaction Surfaces

**Feature Branch**: `006-editorial-ui-polish` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "Let's continue to implement the new Editorial web3 UI design. Per docs/superpowers/specs/2026-07-03-ui-redesign-design.md and recently implemented specs. Let's continue to polish the current UI. Review current implementation, provide some improvements, like modal style, hand-written icon svg files, etc. Make everything follow the best practices, And anything pro and beautiful."

*(`specs/002-editorial-ui-redesign/` shipped the editorial visual system on five public pages. `specs/003-editorial-redesign-rollout/` extended that system across the dashboard, article editor, login modal, home landing page, and default article covers — but left several cross-cutting polish gaps: shared modal/dropdown shells still use generic FlyonUI defaults; many article-interaction components (votes, comments, share, subscribe) still rely on hand-rolled SVG icons and hardcoded hex colors; secondary modals (locale picker, block user, comment reply, pre-order) were not visually elevated; and a handful of `-ghost` button classes and inconsistent Tabler icon utility syntax remain. `specs/005-dashboard-ux-redesign/` addresses dashboard information architecture separately and is out of scope here. This spec is a focused polish pass: elevate shared components and remaining interaction surfaces to the same editorial quality bar as the already-redesigned pages, without changing routes, business logic, or navigation structure.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Polished Shared Dialogs (Modals & Dropdowns) (Priority: P1)

As a user opening any modal or dropdown across the product (connect wallet, change language, reply to a comment, confirm blocking a user, share an article, profile menu), I see dialogs that feel intentionally designed — rounded, well-spaced, typographically consistent with the editorial system — rather than generic framework defaults.

**Why this priority**: `_modal.html.erb` and `_dropdown.html.erb` are shared by every modal and menu in the product. Improving them once elevates every dialog surface immediately, including ones already partially redesigned (login modal content) and ones still visually rough (block-user confirmation).

**Independent Test**: Trigger the connect-wallet modal, locale picker, profile dropdown, comment-reply modal, and block-user confirmation from their existing entry points; confirm all share a cohesive visual treatment (header typography, body spacing, close control, backdrop, border/radius) consistent with the editorial design system in both light and dark appearance.

**Acceptance Scenarios**:

1. **Given** I open any modal via the shared modal partial, **When** it appears, **Then** its header, body padding, corner radius, and backdrop feel consistent with the editorial system's monochrome, border-based elevation — not a mismatched generic overlay.
2. **Given** I open the profile dropdown from the masthead, **When** the menu appears, **Then** its panel styling (border, radius, spacing, hover states) matches the editorial treatment used elsewhere, not a visually disconnected default.
3. **Given** I open modals for destructive actions (e.g., block user), **When** I view the confirmation, **Then** the destructive action uses the platform's standard button components and color tokens — not ad-hoc inline color classes.
4. **Given** I use keyboard navigation, **When** a modal is open, **Then** the close control and primary actions remain clearly focusable with visible focus rings consistent with the accent color.
5. **Given** I toggle between light and dark mode, **When** any modal or dropdown is visible, **Then** text, borders, and interactive states remain legible and visually correct in both themes.

---

### User Story 2 - Unified Icon System on Public Interaction Surfaces (Priority: P2)

As a reader interacting with articles (voting, sharing, commenting, subscribing), I see icons that share one consistent stroke weight, size scale, and color treatment — not a mix of hand-maintained SVG files and framework icons with mismatched styles.

**Why this priority**: The approved design direction (`docs/superpowers/specs/2026-07-03-ui-redesign-design.md` §4.3) calls for Tabler icons via the platform's icon utility classes. Public pages and the masthead already migrated, but article-interaction components (`_votes`, `_share_button`, `_actions`, subscribe buttons, `_updated_at`, share options) still use `inline_svg_tag` with 48 hand-rolled SVG files — creating visible inconsistency on high-traffic reading surfaces.

**Independent Test**: Open an article with comments enabled; inspect vote buttons, share control, comment action icons, and subscribe buttons; confirm every icon uses the platform's Tabler icon utilities with consistent sizing and semantic color tokens (not hardcoded hex values like `#B1B6C6`).

**Acceptance Scenarios**:

1. **Given** I view an article's vote controls, **When** I inspect the upvote/downvote icons, **Then** they use the platform's Tabler icon system with consistent size and active/inactive states expressed through design tokens — not hand-rolled SVG files or hardcoded gray hex colors.
2. **Given** I view share and subscribe controls on an article or profile, **When** I inspect their icons, **Then** they use the same Tabler icon system and sizing scale as the masthead.
3. **Given** two different components display the same semantic icon (e.g., "copy link"), **When** I compare them, **Then** they use the same Tabler icon name and equivalent size — not different hand-drawn SVG variants.
4. **Given** I toggle light/dark mode, **When** I view interaction icons, **Then** inactive/active icon colors adapt correctly using design tokens rather than fixed light-theme hex values.

---

### User Story 3 - Article Interaction Components Match Editorial Style (Priority: P3)

As a reader engaging with an article (voting, sharing, commenting, subscribing to the author), every control I touch looks like it belongs to the same editorial product as the article body and masthead — cohesive button styles, spacing, and typography.

**Why this priority**: These components sit directly on the redesigned article reader page but were largely untouched during the initial public-page rollout. They are visible on every article view and currently mix old icon/color patterns with partially updated `-soft` buttons.

**Independent Test**: Open a published article; interact with vote buttons, the share flow, comment actions, and subscribe controls; confirm all use editorial component treatments (pill/soft buttons, neutral or accent colors, consistent spacing) with no leftover pre-redesign visual patterns.

**Acceptance Scenarios**:

1. **Given** I view an article's vote row, **When** I inspect the layout, **Then** buttons, counts, and spacing align with the editorial system's density and component styles.
2. **Given** I open the share flow for an article, **When** the share options appear, **Then** every option (social channels, copy link) uses consistent icon sizing, labels, and hover/focus states matching the editorial system.
3. **Given** I view comments on an article, **When** I inspect upvote/downvote/reply actions on each comment, **Then** they use the same interaction styling as the article-level vote row — not a separate visual dialect.
4. **Given** I view subscribe buttons (author, tag, article), **When** I compare them across contexts, **Then** they share one consistent visual treatment regardless of where they appear on public pages.

---

### User Story 4 - Secondary Modals & Overlays Elevated (Priority: P4)

As a user performing secondary tasks through modals (pick a language, place a pre-order, write a comment, pick a currency), each modal's content layout and controls feel as polished as the connect-wallet modal — not like leftover pre-redesign screens dropped into a new shell.

**Why this priority**: The shared modal shell (User Story 1) provides the frame, but several modal *contents* still use outdated button styles, spacing, or hardcoded colors. These are lower-traffic than the login modal but still part of the editorial experience.

**Independent Test**: Open the locale picker, pre-order form modal, comment form modal, and currency picker; confirm each modal's inner content (form fields, action buttons, helper text) uses editorial typography, button variants, and spacing — with no `-ghost` buttons or ad-hoc color classes.

**Acceptance Scenarios**:

1. **Given** I open the language/locale picker modal, **When** I view the locale options, **Then** the selection buttons use editorial primary/outline pill treatments with clear selected-state distinction.
2. **Given** I open the pre-order or comment modal, **When** I view the form and actions, **Then** inputs, labels, and submit buttons match the editorial component styles used on redesigned pages.
3. **Given** I open the block-user confirmation modal, **When** I view it, **Then** the destructive confirm action uses the platform's standard error/danger button component — not a raw colored block with inline styles.
4. **Given** I open any secondary modal on mobile, **When** I interact with it, **Then** content remains usable without horizontal scrolling and respects safe-area insets at the bottom.

---

### User Story 5 - Remaining Styling Debt & Consistency Cleanup (Priority: P5)

As a user navigating any already-redesigned surface (public pages, editor, dashboard), I never encounter a control that looks broken, unstyled, or visually disconnected because of leftover pre-redesign class names or one-off color values.

**Why this priority**: Small inconsistencies (orphan `btn-ghost` classes that render unstyled in FlyonUI, mixed Tabler utility syntax `i-[tabler--*]` vs `icon-[tabler--*]`, hardcoded hex colors, leftover `font-serif` instead of `font-display`) undermine the polish of otherwise completed work. This story sweeps them systematically.

**Independent Test**: Audit all in-scope view files for `btn-ghost`, `badge-ghost`, `inline_svg_tag`, hardcoded non-token hex colors in class attributes, and inconsistent icon utility prefixes; confirm zero instances remain outside explicitly out-of-scope surfaces (admin panel).

**Acceptance Scenarios**:

1. **Given** I use the article editor on any screen size, **When** I view its toolbar buttons, **Then** no unstyled `-ghost` buttons appear — all low-emphasis controls use the supported `-soft` treatment.
2. **Given** I inspect any in-scope view file, **When** I look for hand-rolled SVG icon references, **Then** none remain on public pages, article interaction components, shared components, editor chrome, or dashboard views — except where an icon has no Tabler equivalent and a documented exception is recorded.
3. **Given** I inspect Tabler icon usage across in-scope files, **When** I compare syntax, **Then** one consistent utility prefix is used project-wide (not a mix of two different class naming conventions for the same icon system).
4. **Given** I view flash/toast notifications, **When** they appear, **Then** their styling (alert container, icon, dismiss button) is consistent with the polished modal/dialog treatment and readable in both themes.

---

### User Story 6 - Cross-Cutting Dark Mode & Accessibility on Polished Surfaces (Priority: P6)

As a user who prefers dark mode or relies on keyboard navigation, every surface touched by this polish pass remains fully legible, contrast-compliant, and operable without a mouse.

**Why this priority**: Polish work often introduces subtle contrast regressions (especially when replacing hardcoded colors with tokens). A final pass ensures the elevated components meet the same WCAG AA bar established in prior specs.

**Independent Test**: Toggle dark mode while exercising every modal, dropdown, vote control, share flow, and flash notification updated in this feature; tab through interactive controls with keyboard only; confirm visible focus rings and sufficient text contrast throughout.

**Acceptance Scenarios**:

1. **Given** I am in dark mode, **When** I open any modal or dropdown updated by this feature, **Then** all text and interactive elements meet WCAG AA contrast against their backgrounds.
2. **Given** I navigate exclusively by keyboard, **When** I open a modal, **Then** I can reach the close button, primary action, and all focusable fields without becoming trapped or losing visible focus indication.
3. **Given** I am in light mode, **When** I perform the same checks, **Then** contrast and focus visibility meet the same standard.
4. **Given** I use a screen reader, **When** a modal opens, **Then** it retains appropriate dialog semantics (role, labelled title, dismiss control with accessible name).

---

### Edge Cases

- What happens when a modal's title is very long (e.g., localized strings in Japanese)? The header MUST wrap or truncate gracefully without overlapping the close button.
- What happens when the share modal is opened on a very narrow mobile screen? Share option icons and labels MUST remain tappable without horizontal scrolling.
- What happens when a comment has zero upvotes/downvotes? Vote controls MUST still render at full size with readable zero counts — not collapse or misalign.
- What happens when an icon's active state color (e.g., upvoted = accent, downvoted = error) is shown in dark mode? Active/inactive colors MUST remain distinguishable and meet contrast requirements in both themes.
- What happens when a modal is opened while another flash notification is visible? Both MUST coexist without z-index conflicts or obscured dismiss controls.
- What happens on static informational pages (`pages/fair`, `pages/rules`) that still use hand-rolled chevron icons? They MUST be updated to the Tabler icon system as part of the icon sweep, or explicitly documented as out of scope if they are rarely visited internal pages — default: include them in the sweep since they are public-facing.

## Requirements *(mandatory)*

### Functional Requirements

**Shared dialogs (User Story 1)**

- **FR-001**: The shared modal partial MUST be visually updated so every modal in the product inherits editorial styling (header typography using the display/body font roles, consistent padding, border-based elevation, rounded corners aligned with design tokens, polished close control) without changing modal open/close behavior or Turbo Frame integration.
- **FR-002**: The shared dropdown partial MUST be visually updated so dropdown panels inherit the same editorial border, radius, spacing, and hover treatments already used in the masthead profile menu.
- **FR-003**: Destructive confirmation modals (e.g., block user) MUST use the platform's standard danger/error button components instead of ad-hoc inline color classes.

**Icon system (User Story 2)**

- **FR-004**: All hand-rolled SVG icon references (`inline_svg_tag` pointing to `icons/*.svg`) on public pages, article interaction components, shared components (excluding admin), editor chrome, and dashboard views MUST be replaced with the platform's Tabler icon utility classes, per the approved design direction.
- **FR-005**: Icon active/inactive states on interaction components MUST use design tokens (`text-primary`, `text-base-content/60`, `text-error`, etc.) — not hardcoded hex color values in class attributes.
- **FR-006**: The project MUST standardize on one Tabler icon utility class naming convention across all in-scope files (eliminating the current mix of `i-[tabler--*]` and `icon-[tabler--*]` syntax for the same icon system).

**Article interactions (User Story 3)**

- **FR-007**: Article vote controls, share button/flow, comment action buttons, and subscribe buttons (author, tag, article) MUST use editorial component styles consistent with the redesigned article reader and masthead.
- **FR-008**: Share option panels MUST present all channels (social links, copy link) with uniform icon sizing, spacing, and hover/focus states.

**Secondary modals (User Story 4)**

- **FR-009**: Modal contents for locale selection, pre-order, comment creation, currency selection, and block-user confirmation MUST use editorial typography, form control styles, and button variants — not pre-redesign patterns.
- **FR-010**: All secondary modals MUST remain fully usable on mobile widths without horizontal scrolling.

**Styling debt cleanup (User Story 5)**

- **FR-011**: Zero instances of `btn-ghost` or `badge-ghost` MUST remain anywhere in in-scope view files (public, shared, editor, dashboard) — all MUST use the supported `-soft` low-emphasis treatment or an appropriate editorial variant via `UiHelper`.
- **FR-012**: Flash/toast notification styling MUST be reviewed and updated for consistency with the polished dialog treatment where visual gaps exist.
- **FR-013**: Any remaining `font-serif` usages on already-redesigned surfaces MUST be corrected to `font-display` for headline typography consistency.

**Cross-cutting (User Story 6)**

- **FR-014**: All surfaces updated by this feature MUST meet WCAG AA contrast for text and interactive controls in both light and dark appearance.
- **FR-015**: All modals and dropdowns updated by this feature MUST remain keyboard-operable with visible focus states on every interactive control.
- **FR-016**: This feature MUST NOT change any route, authentication flow, payment behavior, revenue logic, or data model — presentation layer only.

**Scope boundaries**

- **FR-017**: The admin panel (`/admin`, `app/views/admin/**`, `layouts/admin.html.erb`) is explicitly out of scope and MUST NOT be modified.
- **FR-018**: Dashboard information architecture and navigation restructuring (`specs/005-dashboard-ux-redesign/`) is out of scope — this feature polishes visual presentation of existing components only, not IA changes.
- **FR-019**: Hand-rolled SVG files under `app/assets/images/icons/` that are no longer referenced after migration MAY be removed, but removal is optional — the requirement is that in-scope views no longer depend on them.

### Key Entities

- **Shared Modal Shell**: The reusable dialog wrapper (`shared/_modal`) used by all Turbo Frame modals — title, header, body, close control, backdrop behavior.
- **Shared Dropdown Shell**: The reusable menu wrapper (`shared/_dropdown`) used for profile and action menus.
- **Article Interaction Cluster**: Vote controls, share flow, comment actions, and subscribe buttons rendered on or around the article reader.
- **Secondary Modal Content**: Inner layouts for locale picker, pre-order, comment form, currency picker, and block-user confirmation — distinct from the shared shell but dependent on it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of modals opened via the shared modal partial present editorial-quality styling (consistent header, spacing, radius, backdrop) when reviewed across connect-wallet, locale, comment, block-user, and pre-order entry points.
- **SC-002**: Zero `inline_svg_tag` references remain in in-scope view directories (`app/views/articles`, `app/views/comments`, `app/views/shared`, `app/views/subscribe_*`, `app/views/pre_orders`, `app/views/sessions`, `app/views/locales`, `app/views/block_users`, `app/views/pages`, `app/views/dashboard`, editor views) — admin excluded.
- **SC-003**: Zero instances of `btn-ghost` or `badge-ghost` remain in in-scope view files.
- **SC-004**: Zero hardcoded non-token hex color values (e.g., `#B1B6C6`, `#92661C` except where already defined as design-token aliases) remain in in-scope interaction component class attributes.
- **SC-005**: One consistent Tabler icon utility naming convention is used across all in-scope files — no mixed `i-[tabler--*]` and `icon-[tabler--*]` syntax for the same purpose.
- **SC-006**: A reader can vote, share, comment, and subscribe on an article without encountering any control that visually appears disconnected from the editorial redesign.
- **SC-007**: All updated surfaces pass WCAG AA contrast checks for body text and interactive controls in both light and dark appearance.
- **SC-008**: No functional regressions — wallet connection, commenting, voting, sharing, subscribing, pre-ordering, locale switching, and block-user flows behave identically to before this feature.

## Assumptions

- This feature builds on completed work in `specs/002-editorial-ui-redesign/` and the substantially implemented `specs/003-editorial-redesign-rollout/` (public pages, dashboard restyle, editor restyle, login modal content). It does not introduce a new visual language — it closes the remaining quality gaps.
- Icon migration follows the approved design direction (`docs/superpowers/specs/2026-07-03-ui-redesign-design.md` §4.3): replace hand-rolled SVGs with Tabler icons via utility classes. "Hand-written icon svg files" in the user request is interpreted as *addressing the remaining dependency on hand-maintained SVG icon files*, not introducing new custom SVG artwork.
- Where a Tabler icon lacks an exact semantic match (e.g., a platform-specific solid-fill variant), the closest Tabler equivalent with appropriate size/weight styling is acceptable — no new custom SVG files will be authored unless a documented exception is recorded in the plan.
- The admin panel remains untouched per project convention across all editorial redesign specs.
- `specs/005-dashboard-ux-redesign/` may proceed in parallel; this polish pass does not block or depend on dashboard IA changes and only touches visual presentation of existing dashboard components where styling debt exists (icons, ghost buttons).
- Delivery is expected incrementally by user-story priority (P1–P6), matching the pattern in prior specs — shared shells first, then icons, then interaction components, then secondary modals, then cleanup sweep, then accessibility pass.
- New user-visible copy introduced during polish (if any modal labels or helper text are refined) MUST use i18n locale files per the project constitution.
- No new automated test suite is required for purely presentational changes, but existing tests MUST continue to pass; any icon or class-name changes in shared partials should be verified against system/integration tests that render those partials.
