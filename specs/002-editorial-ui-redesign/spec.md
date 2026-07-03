# Feature Specification: Editorial Web3 UI Redesign — Public Pages

**Feature Branch**: `002-editorial-ui-redesign` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "Let's start to implement the new design based on our discussions."

*(This description refers to the interactive brainstorming session that produced the approved design direction, recorded at `docs/superpowers/specs/2026-07-03-ui-redesign-design.md`. That document is the source of visual-design truth; this spec translates it into implementation-ready, testable product requirements for the affected pages.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Editorial Home Feed (Priority: P1)

As a reader (logged in or not), I land on the home page and see a clean, minimal masthead with the article feed starting immediately — not a large promotional banner I have to scroll past.

**Why this priority**: The home page is the highest-traffic entry point and introduces the shared list-row presentation that every other story in this spec reuses. Shipping it first validates the new visual language before rolling it out elsewhere.

**Independent Test**: Visit the home page as both a logged-out visitor and a logged-in reader; confirm the feed is visible without scrolling past a full-height banner, and confirm the feed rows display consistently.

**Acceptance Scenarios**:

1. **Given** I am a logged-out visitor, **When** I open the home page, **Then** I see a compact masthead with a brief value-proposition message, followed immediately by the article feed.
2. **Given** I am a logged-in reader, **When** I open the home page, **Then** I see the compact masthead (without the value-proposition message) followed immediately by the article feed.
3. **Given** the feed is displayed, **When** I scan it, **Then** each article row shows its title, a short excerpt, author, relative publish date, a thumbnail, and whether it is paid (with price) or free.
4. **Given** an article in the feed carries an early-reader reward for me personally, **When** I view the feed, **Then** that reward status is visible inline on the row without needing to open the article.

---

### User Story 2 - Focused Article Reading & Paywall (Priority: P2)

As a reader, when I open an article, I get a single, focused reading column with clear typography, and if the article is locked, I see a natural fade into an unlock prompt rather than an abrupt wall.

**Why this priority**: The reading page is the core value-delivery surface and the primary monetization touchpoint (paywall). It's the second most-visited surface after the feed.

**Independent Test**: Open a free article and a paid (locked) article; confirm the reading layout is single-column, and confirm the locked article fades into a clear unlock prompt at the paid boundary.

**Acceptance Scenarios**:

1. **Given** I open any article, **When** the page loads, **Then** the content is presented in one focused column with no persistent side panel competing for attention.
2. **Given** I am reading a locked article and reach the paid boundary, **When** I scroll to that point, **Then** the visible content fades out gradually and an inline prompt shows the unlock price and action.
3. **Given** I am reading any article, **When** I want to unlock/support it, **Then** a compact, non-intrusive control for that action remains reachable without leaving the reading view.
4. **Given** I have already purchased/unlocked the article, **When** I view it, **Then** no paywall fade or unlock prompt is shown.

---

### User Story 3 - Author Public Profile (Priority: P3)

As a visitor, I can view an author's public profile and see their bio, modest public activity stats, and their published articles — without seeing their private earnings.

**Why this priority**: Profiles are a discovery and trust surface, reused by links from articles and the feed, but see less standalone traffic than the feed or reading page.

**Independent Test**: Open any author's profile page and confirm bio, article count, reader count, and join date are visible, no earnings/financial figures are shown, and their articles render using the same list-row presentation as the feed.

**Acceptance Scenarios**:

1. **Given** I visit an author's profile, **When** the page loads, **Then** I see their avatar, name, bio, article count, total reader count, and join date.
2. **Given** I visit any author's profile, **When** I look for financial information, **Then** no earnings or on-chain financial figures are displayed.
3. **Given** an author has published articles, **When** I view their profile, **Then** their articles are listed using the same row presentation used on the home feed.

---

### User Story 4 - Search Results (Priority: P4)

As a visitor, when I search, I see results presented the same way as the home feed, so scanning results feels familiar.

**Why this priority**: Search is a lower-traffic, task-specific surface; reusing the already-built list-row component makes this a small, low-risk increment once P1 ships.

**Independent Test**: Run a search query and confirm results render using the same list-row presentation as the home feed, including price/free status.

**Acceptance Scenarios**:

1. **Given** I run a search, **When** results are returned, **Then** each result is shown using the same list-row presentation as the home feed (title, excerpt, author, date, thumbnail, price/free status).
2. **Given** a search returns no results, **When** I view the results page, **Then** I see a clear, friendly empty-state message instead of a blank area.

---

### User Story 5 - Collection Pages (Priority: P5)

As a visitor, when I view a curated collection, I see the collection's context (title, description, curator) and its articles in the familiar list-row presentation.

**Why this priority**: Collections have the smallest audience among the five surfaces and depend on the same shared row component, making it the safest to ship last.

**Independent Test**: Open a collection page and confirm the collection header (title, description, curator) is shown, followed by its articles in the shared row presentation.

**Acceptance Scenarios**:

1. **Given** I open a collection page, **When** it loads, **Then** I see the collection's title, description, and curator.
2. **Given** the collection has articles, **When** I view the page, **Then** they are listed using the same row presentation as the home feed.
3. **Given** a collection has no articles yet, **When** I view the page, **Then** I see a clear empty-state message.

---

### Edge Cases

- What happens when an article has no cover image? The row MUST still render cleanly with a neutral placeholder thumbnail, not a broken image or empty gap.
- What happens when an article title or author bio is very long (common with Chinese text wrapping differently than Latin text)? Text MUST wrap/truncate gracefully without breaking the row layout or overlapping the thumbnail.
- What happens when a locked article has very little or no free preview text before the paid boundary? The fade/unlock prompt MUST still present cleanly without visually empty space.
- What happens when a reader is on a small (mobile) screen? All redesigned pages MUST remain fully usable and legible without horizontal scrolling.
- What happens when a user toggles between light and dark mode mid-session? All redesigned pages MUST update immediately and consistently, with no readability regressions in either mode.
- What happens when an author has zero published articles, zero readers, or a missing/empty bio? The profile MUST show sensible defaults/empty states rather than blank or broken sections.
- What happens when a tag list on an article is long? Tags MUST wrap or truncate without breaking the row layout.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The home page MUST present a compact masthead (not a full-height promotional banner) with the article feed visible immediately below it.
- **FR-002**: The home page MUST show a single, brief value-proposition message near the masthead only to logged-out visitors; logged-in readers MUST NOT see this message.
- **FR-003**: Every article preview surfaced in the feed, search results, author profile, and collection pages MUST use one consistent list-row presentation showing: title, short excerpt, author, relative publish date, thumbnail, and price status (amount or free).
- **FR-004**: An article's early-reader reward status, when applicable to the current viewer, MUST be visible inline within its list row without requiring the article to be opened.
- **FR-005**: Topic tags on articles MUST use one consistent neutral visual style, not per-category color coding.
- **FR-006**: When a reader reaches the paid boundary of a locked article, the visible content MUST fade out gradually and present an inline unlock prompt with price and action, rather than an abrupt cutoff or full-page interstitial.
- **FR-007**: The article reading page MUST present content in a single focused column without a persistent side panel; the unlock/support action MUST remain reachable via a compact, non-intrusive control while reading.
- **FR-008**: Author public profile pages MUST display only modest public activity information (article count, total reader count, join date) and MUST NOT publicly display the author's earnings or on-chain financial details.
- **FR-009**: Search results MUST be presented using the same list-row presentation defined in FR-003.
- **FR-010**: Collection pages MUST display the collection's title, description, and curator, followed by its articles using the presentation defined in FR-003.
- **FR-011**: All five redesigned pages (home feed, article reading, author profile, search, collection) MUST support both a light and a dark appearance, each reviewed independently for readability rather than treated as a simple color inversion.
- **FR-012**: All five redesigned pages MUST render Chinese-language titles, excerpts, and bios legibly at all supported text sizes, given that most published content is in Chinese.
- **FR-013**: Primary actions (write/publish, connect wallet, unlock article) MUST be visually distinguished from secondary/inline actions on every redesigned page.
- **FR-014**: Empty states (no search results, no articles in a collection or profile) MUST show a clear, friendly message rather than a blank area.

### Key Entities

- **Article Preview**: The summarized representation of an article shown in list rows — title, excerpt, author reference, publish date, thumbnail, tags, price/free status, and optional early-reader reward indicator.
- **Author Profile**: Public-facing representation of a user as a writer — avatar, name, bio, article count, reader count, join date; explicitly excludes earnings/financial data.
- **Collection**: A curated grouping of articles with its own title, description, curator, and member articles.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A visitor can see the start of the article feed on the home page without scrolling past a full-height promotional banner (zero full-height banners present).
- **SC-002**: A reader can identify whether an article is paid or free directly from its list row, without opening it, in every surface it appears (feed, search, profile, collection).
- **SC-003**: When a reader hits a paywall, the transition from readable content to the unlock prompt is visually gradual (fade), not an abrupt cutoff, on 100% of locked articles.
- **SC-004**: The same article list-row presentation is used consistently across all four listing surfaces (home feed, search, author profile, collection) — zero bespoke/one-off row layouts remain.
- **SC-005**: Body text on all five redesigned pages meets WCAG AA contrast in both light and dark appearance.
- **SC-006**: No missing-glyph ("tofu") characters appear when rendering Chinese titles, excerpts, or bios on any redesigned page.
- **SC-007**: No author earnings or on-chain financial figures appear anywhere on the public author profile page (zero instances across all profiles).
- **SC-008**: All five redesigned pages remain fully usable (no horizontal scrolling, no overlapping elements) at common mobile widths.

## Assumptions

- The visual design system (colors, typography, layout patterns, and component treatments) approved in `docs/superpowers/specs/2026-07-03-ui-redesign-design.md` is the source of design truth for this feature; this spec defines the product-facing requirements that implementation must satisfy, not the visual system itself.
- Author dashboard/studio, the article editor, the admin panel, and the wallet-connect/login modal internals are explicitly out of scope for this feature and retain their current presentation; only the trigger buttons that open the login modal are affected (visual restyling to match the new primary-action treatment).
- This is a presentation-layer redesign: existing routes, underlying data models (Article, User, Collection, Order, Transfer, etc.), revenue-split logic, authentication, and infinite-scroll/pagination behavior are unchanged.
- "Early-reader reward status" in FR-004/User Story 1 refers to the existing reward mechanic already computed by the platform; this feature only changes how/where that status is displayed, not how it is calculated.
- No new performance budget was specified; standard expectations for a content-heavy web page (fast-perceived load, no layout shift from font loading) apply.
