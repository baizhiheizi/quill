# Feature Specification: Dashboard UI/UX Redesign — From Zero

**Feature Branch**: `005-dashboard-ux-redesign` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "Let's redesign the dashboard UI from zero, make it pro, modern and beautiful. Aligned to the new editorial UI pattern. We don't need lock on the `left-sidebar` layout. Just reconsider the dashboard views systematically, redesign the UI/UX from zero as a senior UI designer and product manager."

*(`specs/002-editorial-ui-redesign/` established the editorial visual system (colors, typography, `-soft` component styling, `i-tabler-*` icons) for public pages. `specs/003-editorial-redesign-rollout/` then extended that visual system to the dashboard, but explicitly constrained the work to a visual-only restyle: "the dashboard MUST keep its existing left-sidebar navigation shell... this redesign restyles that shell's visuals only; it does not replace it" (003 FR-016). This spec supersedes that constraint for the dashboard specifically: it treats the dashboard's information architecture, navigation shell, and page layouts as fully open for redesign, not just their color/type/icon treatment. Public pages, the article editor (`specs/004-*`), the wallet-connect/login modal, and the admin panel are unaffected and out of scope here.)*

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
-->

### User Story 1 - A Navigation Structure That Matches How People Actually Use the Dashboard (Priority: P1)

As a logged-in reader or author, I can find any dashboard feature — from my drafts to my earnings to my API access tokens — through a clear, consistent navigation structure, without having to already know it's buried inside an unrelated tab.

**Why this priority**: Today's dashboard groups ~20 distinct features (readings, authoring, notifications, orders, payments, transfers, subscriptions, blocked users, access tokens, profile/notification settings) behind a 4-item sidebar plus nested horizontal tab strips, several levels deep. At least one feature (API access tokens) currently has no discoverable entry point anywhere in the UI at all. A new information architecture is the foundation every other story in this redesign builds on top of, so it must be decided first.

**Independent Test**: As a logged-in user, attempt to locate and open every distinct dashboard feature (my drafts, published articles, hidden articles, collections, comments, bought articles, subscriptions to authors/tags/comments, blocked users, orders, payments, transfers/earnings for both reader and author roles, notifications, notification settings, profile settings, access tokens) starting only from the dashboard's landing view; confirm every one is reachable and that the navigation structure used to reach them is consistent and predictable across the whole dashboard.

**Acceptance Scenarios**:

1. **Given** I am logged in and open my dashboard, **When** I look at the primary navigation, **Then** I see a clear, labeled structure that groups related features together (e.g., writing/authoring, reading/library, earnings/finances, notifications, account) rather than a flat, unlabeled list or deeply nested tabs.
2. **Given** I am anywhere in the dashboard, **When** I want to switch to a different dashboard section, **Then** I can do so through the same, single, consistent navigation mechanism — not a mix of sidebar links, tab strips, and buried buttons depending on which page I happen to be on.
3. **Given** a dashboard feature exists but previously had no visible entry point (e.g., managing API access tokens), **When** I browse the redesigned navigation, **Then** I can find and open it.
4. **Given** I am using the dashboard on a mobile-width screen, **When** I navigate between sections, **Then** the mobile navigation follows the same information architecture as desktop (same groupings, same reachability), adapted for a smaller screen rather than being a separate, inconsistent structure.
5. **Given** I am on any dashboard page, **When** I look for an indicator of where I currently am, **Then** the navigation clearly shows my current location within the structure.

---

### User Story 2 - A Real Dashboard Home That Shows Me What Matters (Priority: P2)

As a logged-in reader or author, when I open my dashboard, I land on an overview that actually tells me something useful — recent activity, earnings/reward status, unread notifications, and quick access to what I'd likely want to do next — instead of being silently redirected into one specific tab (my reading list) with no overview at all.

**Why this priority**: Today, opening the dashboard immediately redirects to "My Reading" — there is no actual home/overview screen, even though the underlying route and view for one already exist. A meaningful landing view is the highest-leverage single page in the dashboard, since every logged-in session touches it, and it depends on the navigation structure from User Story 1 being in place.

**Independent Test**: Log in and open the dashboard's root URL; confirm it renders a distinct overview (not a redirect into another section) surfacing at-a-glance information and shortcuts, and confirm the information shown is accurate for both a reader-only account and an author account.

**Acceptance Scenarios**:

1. **Given** I log in and open my dashboard, **When** the page loads, **Then** I land on a distinct overview screen, not an automatic redirect into another section.
2. **Given** I have unread notifications, **When** I view the dashboard overview, **Then** I see an indication of how many, with a way to jump directly into them.
3. **Given** I am an author with published articles, **When** I view the dashboard overview, **Then** I see a snapshot of my recent earnings/reward activity and my recent article activity (e.g., latest published or most active piece).
4. **Given** I am a reader who has not yet published anything, **When** I view the dashboard overview, **Then** I see relevant reader-focused information (e.g., recent reads, reward activity as an early reader) and an invitation to start writing, rather than an empty or author-only-oriented screen.
5. **Given** I am a brand-new user with no activity yet in any category, **When** I view the dashboard overview, **Then** it renders a complete, welcoming layout with sensible empty states rather than blank gaps.
6. **Given** I want to jump to a specific task (write a new article, check earnings, view notifications), **When** I view the dashboard overview, **Then** I see clear shortcuts to those common next actions.

---

### User Story 3 - An Author Workspace That Feels Like a Writer's Control Center (Priority: P3)

As an author, I can review and manage all of my writing (drafts, published articles, hidden articles, collections) and see my author earnings in one coherent, purpose-built workspace, instead of a flat row of five text tabs sharing one generic list layout.

**Why this priority**: Authoring is the platform's core producer-side activity and the one most directly tied to revenue; a purpose-built workspace (status at a glance, clear per-article actions, earnings visible alongside the work that generates them) is a significant, high-value upgrade over today's undifferentiated tab strip, and can be built and shipped independently once the navigation shell (US1) exists.

**Independent Test**: As an author with a mix of drafted, published, and hidden articles plus at least one collection, open the redesigned authoring workspace and confirm each article status group is clearly distinguished, per-article actions (edit, publish, hide, delete) are available, collections are manageable, and author earnings/revenue are visible within the same workspace.

**Acceptance Scenarios**:

1. **Given** I have articles in different states (drafted, published, hidden), **When** I open my authoring workspace, **Then** I can clearly distinguish each group and see relevant per-article information (status, price, reader/revenue activity) at a glance.
2. **Given** I am viewing any of my articles in this workspace, **When** I want to act on it (edit, publish, hide, unhide, delete), **Then** the relevant action is available directly from the workspace without an unrelated detour.
3. **Given** I manage collections of my articles, **When** I open the authoring workspace, **Then** I can view, create, and edit my collections from within the same workspace.
4. **Given** I want to check how my writing is earning, **When** I am in the authoring workspace, **Then** I can see my author revenue/earnings activity without leaving the workspace for an unrelated section.
5. **Given** I have no articles yet in a given status (e.g., no hidden articles), **When** I view that group, **Then** I see a clear, friendly empty state.

---

### User Story 4 - A Reading Library That Feels Personal (Priority: P4)

As a reader, I can review everything I've engaged with — articles I've bought, my comments, my subscriptions to authors/tags/discussions, and my early-reader reward activity — in one coherent personal library, instead of a flat row of five text tabs.

**Why this priority**: Reading/subscribing is the platform's primary consumer-side activity; a well-organized personal library increases the odds a reader returns and re-engages, but it is lower business-value than the authoring workspace (P3) since it doesn't directly touch revenue creation, and it depends on the navigation shell (US1).

**Independent Test**: As a reader with purchased articles, comments, and subscriptions, open the redesigned reading library and confirm bought articles, comments, subscriptions (to authors, tags, and comment threads), and reader reward/earnings activity are each clearly organized and browsable.

**Acceptance Scenarios**:

1. **Given** I have purchased articles, **When** I open my reading library, **Then** I can browse them with clear indication of when I purchased/read each one.
2. **Given** I have left comments on articles, **When** I view my library, **Then** I can review my own comments and jump back to their articles.
3. **Given** I subscribe to authors, tags, or comment threads, **When** I view my library, **Then** each subscription type is clearly organized and I can manage (unsubscribe from) them.
4. **Given** I have received early-reader reward activity, **When** I view my library, **Then** I can see that reward/earnings activity without leaving the library for an unrelated section.
5. **Given** I have no activity yet in a given category (e.g., no purchases), **When** I view that category, **Then** I see a clear, friendly empty state that invites me to explore articles.

---

### User Story 5 - A Single, Trustworthy Place to Understand My Money (Priority: P5)

As a reader or author, I can see and understand all of my financial activity on the platform — what I've paid for, what I've earned as an early reader, what I've earned as an author, and my transfer/payout history — presented clearly and consistently, instead of scattered across separate order/payment/transfer tabs with duplicated "revenue" concepts split by role.

**Why this priority**: Quill's core differentiator is Web3 early-reader revenue sharing; trust and clarity around money is disproportionately important to user confidence on a paid-content platform, but this is a deeper structural change (unifying data that's currently split by role into orders/payments/transfers) than the surface-level workspace groupings in P3/P4, so it comes after those.

**Independent Test**: As a user who has both bought articles and earned early-reader/author rewards, open the redesigned financial view and confirm spending (orders/payments) and earnings (transfers, split by reader-reward and author-revenue roles where applicable) are each clearly presented, understandable, and traceable to the specific articles involved.

**Acceptance Scenarios**:

1. **Given** I have purchased articles, **When** I view my financial activity, **Then** I can see each payment with the article it was for and its status.
2. **Given** I have earned early-reader rewards, **When** I view my financial activity, **Then** I can see each reward transfer, the article it came from, and a running or period sense of how much I've earned.
3. **Given** I am an author who has earned revenue from my articles, **When** I view my financial activity, **Then** my author earnings are presented clearly and are distinguishable from any early-reader rewards I've separately earned as a reader.
4. **Given** I want to understand a specific transfer or payment, **When** I select it, **Then** I can see enough detail (article, amount, date, counterpart role) to understand what it was for.
5. **Given** I have no financial activity yet, **When** I view this section, **Then** I see a clear, friendly empty state rather than a confusing blank set of tables.

---

### User Story 6 - A Notifications Center I Can Actually Manage (Priority: P6)

As a logged-in user, I can view, filter, and manage my notifications (comments, replies, rewards, system messages) and adjust what I get notified about, in a clear, well-organized notifications center.

**Why this priority**: Notifications drive re-engagement and are checked frequently (hence the existing unread badge in the current sidebar), but the underlying feature set (list, mark read, delete, per-type settings) is already complete and mostly self-contained, making this a contained, lower-risk story to redesign after the higher-value workspaces above.

**Independent Test**: As a user with a mix of read and unread notifications, open the redesigned notifications center and confirm I can browse, distinguish read from unread, mark as read, delete, and adjust notification-type preferences.

**Acceptance Scenarios**:

1. **Given** I have unread notifications, **When** I open my notifications center, **Then** unread items are clearly visually distinguished from read ones.
2. **Given** I am viewing a notification, **When** I interact with it, **Then** I can mark it read, delete it, or follow it to the related content (e.g., the commented article).
3. **Given** I want to change what I'm notified about, **When** I open notification preferences, **Then** I can adjust settings per notification type from within the same notifications center.
4. **Given** I have no notifications yet, **When** I open the notifications center, **Then** I see a clear, friendly empty state.

---

### User Story 7 - Account, Security & Preferences in One Predictable Place (Priority: P7)

As a logged-in user, I can manage my profile, notification preferences, blocked users, API access tokens, and language/theme preferences from one predictable "account" area, instead of some being on a settings tab and others (like access tokens) having no visible entry point at all.

**Why this priority**: These are lower-frequency, "set it and forget it" tasks compared to the daily-use workspaces above, but they include a real, currently-unresolved gap (unreachable access-token management), so this rounds out the redesign's coverage last, after the high-traffic sections are done.

**Independent Test**: As a logged-in user, locate and successfully use each of: profile editing, notification preferences, blocked-user management, API access token creation/revocation, and language/theme switching, confirming every one is reachable from the account area.

**Acceptance Scenarios**:

1. **Given** I want to update my profile (name, avatar, bio, email), **When** I open the account area, **Then** I can do so and see the change reflected.
2. **Given** I want to change what triggers a notification, **When** I open the account area, **Then** I can adjust those preferences.
3. **Given** I have blocked one or more users, **When** I open the account area, **Then** I can view and unblock them.
4. **Given** I want to use the platform's API, **When** I open the account area, **Then** I can create and revoke access tokens — a capability that previously had no visible way to reach it.
5. **Given** I want to change my language or light/dark appearance, **When** I open the account area, **Then** I can do so, consistent with how those controls work elsewhere in the product.

---

### Edge Cases

- What happens to existing bookmarked or shared dashboard URLs (e.g., a specific tab like "my orders") if the information architecture changes? Users following an old link MUST land on a working, sensible equivalent view in the new structure, not a broken page.
- What happens when a user has an unusually large amount of data in one area (hundreds of drafts, thousands of transfers)? The redesigned views MUST remain performant and navigable (e.g., via pagination/infinite scroll), not degrade or break.
- What happens when a user is both an active author and an active reader with significant activity in both roles? The redesigned navigation and overview MUST represent both roles clearly without one crowding out the other.
- What happens when a dashboard page has a right-hand widget rail today (mirroring the old public-page layout, e.g., "join Quill" prompt, active authors, hot tags)? Each such widget MUST be deliberately kept (if still relevant to a logged-in dashboard context), removed, or replaced with something dashboard-relevant — not left as an inconsistent leftover from the public-page layout.
- What happens on a narrow/tablet-width desktop browser (not mobile, so not routed to the mobile navigation)? The redesigned dashboard MUST remain usable without horizontal scrolling or overlapping elements.
- What happens when a user switches between light and dark mode mid-session on any redesigned dashboard page? The page MUST update immediately and remain legible in both.
- What happens when a user's role changes mid-session (e.g., they publish their first article and become an author)? Author-specific navigation and overview content MUST appear without requiring a full logout/login cycle.
- What happens to the existing unread-notification indicator when the navigation structure changes? It MUST still be visible from wherever the notifications entry point lives in the new structure.

## Requirements *(mandatory)*

### Functional Requirements

**Navigation & information architecture (User Story 1)**

- **FR-001**: The dashboard's navigation structure MUST be redesigned from its current shape (a 4-item sidebar plus per-page nested horizontal tab strips) into a coherent structure that groups related features together; the dashboard is explicitly **not required** to retain a left-sidebar layout, unlike the visual-only restyle delivered in `specs/003-editorial-redesign-rollout/`.
- **FR-002**: Every existing dashboard feature (drafted/published/hidden articles, collections, comments, bought articles, subscriptions to authors/tags/comment-threads, blocked users, orders, payments, transfers for both reader and author roles, notifications, notification settings, profile settings, and API access tokens) MUST remain reachable in the redesigned navigation, with no feature becoming harder to find than it is today.
- **FR-003**: API access token management, which currently has no discoverable entry point in the UI, MUST have a visible, reachable entry point in the redesigned navigation.
- **FR-004**: The same navigation structure and mechanism MUST be used consistently across every dashboard page — a user MUST NOT need to learn a different navigation pattern depending on which section they're in.
- **FR-005**: The dashboard navigation MUST clearly indicate the user's current location within the structure at all times.
- **FR-006**: The redesigned navigation MUST work equivalently on both desktop and mobile widths, using the same underlying groupings adapted for each form factor (not two divergent structures).

**Dashboard home/overview (User Story 2)**

- **FR-007**: Opening the dashboard MUST present a distinct overview screen; it MUST NOT silently redirect the user into an unrelated single section (e.g., today's redirect into "My Reading") as its landing behavior.
- **FR-008**: The dashboard overview MUST surface, at a glance: unread notification count (with a path into notifications), a snapshot of recent earnings/reward activity relevant to the user's role(s), and recent activity (e.g., recently read or recently published/active articles).
- **FR-009**: The dashboard overview MUST adapt its content to the user's role — showing author-relevant information (recent articles, author earnings) for authors and reader-relevant information (recent reads, reward activity, an invitation to write) for reader-only accounts — without requiring separate pages per role.
- **FR-010**: The dashboard overview MUST provide clear shortcuts to common next actions (write a new article, view earnings, view notifications).
- **FR-011**: The dashboard overview MUST render a complete, non-broken layout with sensible empty states when the user has no activity yet in one or more categories.

**Author workspace (User Story 3)**

- **FR-012**: Drafted, published, and hidden articles MUST each be clearly distinguished within the redesigned authoring workspace, showing per-article status-relevant information (e.g., price, reader activity, revenue where applicable) at a glance.
- **FR-013**: The authoring workspace MUST support the existing per-article actions (edit, publish, hide/unhide, delete) directly, without requiring navigation away from the workspace.
- **FR-014**: The authoring workspace MUST include collection management (view, create, edit existing collections) within the same workspace.
- **FR-015**: The authoring workspace MUST surface the author's revenue/earnings activity within the same workspace, without requiring the user to leave for an unrelated section.

**Reading library (User Story 4)**

- **FR-016**: Bought articles, the user's own comments, and their subscriptions (to authors, tags, and comment threads) MUST each be clearly organized within the redesigned reading library.
- **FR-017**: The reading library MUST allow managing (unsubscribing from) each subscription type directly.
- **FR-018**: The reading library MUST surface the reader's early-reader reward/earnings activity within the same library, without requiring the user to leave for an unrelated section.

**Financial / earnings clarity (User Story 5)**

- **FR-019**: The redesigned financial view MUST present spending (orders/payments) and earnings (reader-reward transfers and, separately, author-revenue transfers) in a way that clearly distinguishes each category rather than presenting all monetary activity as one undifferentiated concept.
- **FR-020**: Every payment or transfer shown MUST be traceable to the specific article it relates to.
- **FR-021**: A user with both reader and author financial activity MUST be able to view both, with each clearly attributed to the correct role.

**Notifications center (User Story 6)**

- **FR-022**: The notifications center MUST visually distinguish read from unread notifications and support marking notifications as read and deleting them.
- **FR-023**: The notifications center MUST allow the user to follow a notification to its related content (e.g., the commented-on article).
- **FR-024**: Notification-type preferences MUST be adjustable from within the notifications center.

**Account, security & preferences (User Story 7)**

- **FR-025**: Profile editing (name, avatar, bio, email), notification preferences, blocked-user management, API access token management, and language/theme switching MUST all be reachable from one predictable account area.

**Cross-cutting**

- **FR-026**: All redesigned dashboard pages MUST use the editorial design system already established for public pages (colors, typography, `-soft` component styling, icon set) as their visual foundation — this feature changes *structure and layout*, not the underlying visual tokens established in `specs/002-editorial-ui-redesign/`.
- **FR-027**: All redesigned dashboard pages MUST support both light and dark appearance with the same fidelity as the redesigned public pages.
- **FR-028**: All redesigned dashboard pages MUST remain fully usable (no horizontal scrolling, no overlapping elements) at common mobile, tablet, and desktop widths.
- **FR-029**: This redesign MUST NOT change the underlying functional behavior of any dashboard action (publishing, hiding, deleting, subscribing, blocking, token generation/revocation, notification delivery, revenue calculation) — only how these actions are organized, navigated to, and visually presented.
- **FR-030**: If existing dashboard URLs change as a result of the information-architecture redesign, visiting an old URL MUST still land the user on a working, sensible equivalent view rather than an error or a dead end.
- **FR-031**: This feature is scoped to the authenticated dashboard/studio only; the public-facing pages (home, articles, profiles, search, collections), the article editor, the wallet-connect/login modal, and the admin panel are unaffected and out of scope.

### Key Entities

- **Dashboard Navigation Structure**: The redesigned information architecture grouping the dashboard's ~20 features into a coherent set of top-level sections; replaces today's 4-item sidebar plus nested per-page tab strips. Its exact shape (sidebar, top-nav, or another pattern) is a design decision for the planning phase — this spec only requires that it be coherent, consistent, and complete.
- **Dashboard Overview**: The redesigned landing view shown when a user opens their dashboard; surfaces role-aware, at-a-glance information (notifications, earnings snapshot, recent activity) and quick actions instead of redirecting into a single section.
- **Author Workspace**: The redesigned area consolidating an author's drafted/published/hidden articles, collections, and author-earnings activity.
- **Reading Library**: The redesigned area consolidating a reader's bought articles, comments, subscriptions, and reader-reward activity.
- **Financial View**: The redesigned area presenting a user's spending and earnings (both reader-reward and author-revenue, where applicable), each clearly attributed and traceable to specific articles.
- **Notifications Center**: The redesigned area for browsing, managing, and configuring notifications.
- **Account Area**: The redesigned area consolidating profile, notification preferences, blocked users, API access tokens, and language/theme preferences.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every one of the ~20 existing dashboard features is reachable within two navigation actions (e.g., clicks/taps) from the dashboard's landing view, with zero features lacking any discoverable entry point (closing the current gap where API access tokens have none).
- **SC-002**: A logged-in user can view their unread notification count and a recent earnings/reward snapshot without navigating away from the dashboard's first landing screen.
- **SC-003**: 100% of dashboard pages use one consistent navigation mechanism — zero pages present a different navigation paradigm than the rest of the dashboard.
- **SC-004**: The redesigned dashboard remains fully usable (no horizontal scrolling, no overlapping elements) at common mobile, tablet, and desktop widths, in both light and dark appearance.
- **SC-005**: Body text and interactive controls on all redesigned dashboard pages meet WCAG AA contrast in both light and dark appearance.
- **SC-006**: No missing-glyph ("tofu") characters appear when rendering Chinese-language content anywhere in the redesigned dashboard.
- **SC-007**: Every existing dashboard action (publish, hide, delete, subscribe/unsubscribe, block/unblock, create/revoke access token, adjust notification setting, update profile) continues to function identically after the redesign, verified by the existing automated test suite continuing to pass with zero regressions.
- **SC-008**: Visiting any previously-valid dashboard URL after the redesign lands on a working page (zero broken links / dead ends), even if the information architecture has changed.

## Assumptions

- This feature explicitly supersedes `specs/003-editorial-redesign-rollout/`'s FR-016 ("dashboard MUST keep its existing left-sidebar navigation shell... restyles visuals only") for the dashboard specifically — that constraint no longer applies here, per the user's explicit direction. It inherits that same prior feature's visual design tokens (colors, typography, `-soft` styling, icon set) as its starting point, per FR-026.
- The exact shape of the new navigation structure (e.g., sidebar vs. top-nav vs. another pattern, exact section groupings and labels beyond those implied by the seven workspaces above) is a design decision to be resolved during the planning phase, not fixed by this specification.
- The public-facing pages (home, `/articles`, author profiles, search, collections), the article editor (`specs/004-*`), the wallet-connect/login modal, and the admin panel are unaffected by this feature and are explicitly out of scope, consistent with `specs/002-` and `specs/003-`'s own scope boundaries.
- This is a structural and presentation-layer redesign: existing routes may be reorganized as needed to fit the new information architecture (FR-030 requires old URLs still resolve to a sensible page), but underlying data models (Article, Order, Transfer, Collection, User, etc.), revenue-split logic, and authentication are unchanged.
- The right-hand widget rail currently shared with the public-page layout (join-Quill prompt, active authors, hot tags) is treated as part of this redesign's scope for dashboard pages specifically — each instance will be deliberately kept, removed, or replaced with dashboard-relevant content rather than left as an unstyled leftover from the public layout (per Edge Cases).
- "Reachable within two navigation actions" (SC-001) counts a single click/tap on a top-level navigation entry plus, at most, one click/tap on a sub-section or tab within it.
- Given the scope (navigation shell plus seven workspace areas), this feature is expected to be delivered incrementally by user-story priority (P1–P7), matching the delivery pattern used in `specs/002-editorial-ui-redesign/` and `specs/003-editorial-redesign-rollout/`, rather than as a single atomic change.
