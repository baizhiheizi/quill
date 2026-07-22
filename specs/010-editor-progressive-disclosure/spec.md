# Feature Specification: Article Editor Progressive Disclosure

**Feature Branch**: `010-editor-progressive-disclosure`

**Created**: 2026-07-22

**Status**: Draft

**Input**: User description: "help me refactor these." (triggered from the article creation flow audit in issue #1942 — progressive disclosure, hide advanced config, fix editor bugs, make Quill a pro platform for creating)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Distraction-Free Writing Surface (Priority: P1)

When an author clicks "Write," they land in a clean editor showing only the essentials: a title field, a short-intro field, and the rich-text content area taking the full width. No pricing, revenue, currency, references, or collection controls are visible. The author can start writing immediately, with zero configuration decisions required before the first keystroke.

A single, unobtrusive "Settings" affordance (gear icon) is available for when the author wants to configure cover image, tags, price, or advanced options. On mobile, the settings are accessible via the same affordance; on desktop they slide in as an optional panel.

**Why this priority**: The current editor front-loads 12 inputs across 5 sections the moment the author opens the page. This overwhelms new authors, slows the path to first content, and signals a complicated tool rather than a pro writing surface. Removing this friction is the single highest-impact change for conversion and perceived quality.

**Independent Test**: Can be fully tested by opening a new article and verifying that only title, intro, and content fields are visible by default — and that all configuration remains reachable via the Settings affordance. Delivers a focused writing experience immediately.

**Acceptance Scenarios**:

1. **Given** an authenticated author, **When** they click "Write" to start a new article, **Then** the editor shows only title, intro, and content fields, with no pricing/revenue/currency/references/collection sections visible.
2. **Given** the author is in the default writing view, **When** they click the Settings affordance, **Then** a settings panel becomes visible containing cover, tags, pricing, and advanced configuration.
3. **Given** the author has opened settings, **When** they dismiss the panel, **Then** the editor returns to the clean writing surface without losing any settings they entered.
4. **Given** an author editing an existing draft, **When** they open the editor, **Then** the same clean writing surface is shown, with Settings available on demand.

---

### User Story 2 - Intuitive, USD-First Pricing (Priority: P2)

When an author sets a price for their article, they enter it in a currency they intuitively understand (USD) as the primary input, with the crypto equivalent shown as a secondary, read-only detail. Common price points are offered as quick-select presets (e.g., $0.50, $1, $2, $5) alongside a custom entry option. The currency selection (BTC default) is presented as a lightweight inline control rather than a full-screen modal grid, since most authors keep the default.

The price estimate (USD value) is always consistent in formatting — it does not jump between 2 and 4 decimal places as the author edits.

**Why this priority**: Pricing is the only configuration step nearly every author must complete before publishing. The current crypto-native input (7 decimal places, e.g. `0.00005 BTC`) is intimidating and error-prone. Making pricing intuitive directly improves the publish-to-write conversion ratio and reduces mispriced articles.

**Independent Test**: Can be tested by opening settings, entering a USD price, and verifying the crypto equivalent updates consistently and presets work — without touching any other feature.

**Acceptance Scenarios**:

1. **Given** the author is in the pricing section of settings, **When** they view the price field, **Then** the primary input is denominated in USD with preset quick-select options visible.
2. **Given** the author enters a custom USD amount, **When** the price updates, **Then** the crypto equivalent is displayed as a secondary read-only value.
3. **Given** the author changes the price multiple times, **When** they observe the USD estimate, **Then** the decimal formatting remains consistent (no jumps between 2 and 4 decimals).
4. **Given** the author wishes to change the accepted currency, **When** they interact with the currency control, **Then** an inline selector is presented (not a full modal grid) and the crypto equivalent updates accordingly.

---

### User Story 3 - Reliable Editing with No Silent Data Loss (Priority: P2)

An author's work is never silently lost. The autosave system reliably persists drafts, and when a conflict arises (e.g., the same article edited in two tabs), the author is presented with a clear, actionable resolution path — not a silent status pill that discards their in-flight changes. The author can choose to reload the latest version or keep their current version.

Additionally, the short-intro text area grows naturally as the author types (auto-resize), so longer intros are fully visible without an internal scrollbar.

**Why this priority**: Silent data loss during autosave conflicts directly destroys author trust in a writing platform. The non-resizing intro field is a daily-visible quality defect. Together these undermine the "pro platform" promise at the most fundamental level.

**Independent Test**: Can be tested by editing an article in two browser tabs simultaneously, triggering a save conflict, and verifying the resolution affordance appears. The intro auto-resize can be tested by typing a long intro and confirming the field grows.

**Acceptance Scenarios**:

1. **Given** an author editing an article, **When** a save conflict occurs (another session saved first), **Then** a clear resolution affordance is presented offering "Reload latest" and "Keep my version" options.
2. **Given** the author selects "Keep my version" on a conflict, **When** they save again, **Then** their in-flight edits are submitted (not silently discarded).
3. **Given** the author types a multi-line intro, **When** the text exceeds the initial field height, **Then** the intro field grows to show all content without an internal scrollbar.

---

### User Story 4 - Power Features Behind Explicit Gates (Priority: P3)

Authors who want advanced configuration — custom revenue splits, revenue-sharing references/citations, and collection binding — can still access every option that exists today. These features are simply hidden behind explicit, clearly-labeled disclosure controls (e.g., "Customize revenue split" or "Cite articles & share revenue (advanced)"). Nothing is removed; everything is reachable.

When the author opens an advanced section, the controls work exactly as they do today: revenue ratios auto-calculate and validate (must sum to 100%), references can be added/removed, collections can be bound. The revenue summary ("50% you · 40% early readers · 10% platform") is shown contextually within the advanced panel, not on the default surface.

**Why this priority**: Power features matter to a minority of authors but must not clutter the default experience for the majority. Progressive disclosure serves both audiences. This is lower priority than the core writing and pricing experience because it affects fewer users.

**Independent Test**: Can be tested by opening the advanced revenue section and verifying all existing controls (readers/author/references ratios, summary, references add/remove, collection binding) are present and functional.

**Acceptance Scenarios**:

1. **Given** the author in the settings panel, **When** they look at the revenue area, **Then** no revenue fields are visible by default — only a "Customize revenue split" affordance (since defaults are sensible).
2. **Given** the author clicks "Customize revenue split", **When** the advanced panel opens, **Then** the readers/author/references ratio fields, the live summary, and the platform ratio are visible and functional.
3. **Given** the advanced revenue panel is open, **When** the author adjusts the readers ratio, **Then** the author ratio auto-recalculates and the summary updates, and the split validates to 100%.
4. **Given** the author wants to cite another article for revenue sharing, **When** they open the references disclosure, **Then** the citation picker and per-reference ratio controls are available.
5. **Given** a published article whose revenue splits are frozen, **When** the author opens advanced settings, **Then** the frozen fields are visibly disabled with an explanatory note.

---

### User Story 5 - Confident Publishing with Inline Readiness (Priority: P3)

When an author is ready to publish, they receive clear, inline feedback about what still needs attention (e.g., missing title, missing content, invalid price) before they even click "Publish." The publish action itself is a guided, low-friction confirmation — not a jarring modal round-trip that may reveal blockers only after the author has mentally committed.

The author can preview their article as readers will see it (with the paywall in effect) before publishing.

**Why this priority**: A smooth publish flow converts completed drafts into published articles. Discovering blockers only inside a publish modal creates frustration and abandoned publish attempts. This is lower priority than the writing and pricing core because it affects the final step, not the daily experience.

**Independent Test**: Can be tested by starting with an incomplete draft and verifying inline readiness hints appear, then completing the draft and verifying publish succeeds.

**Acceptance Scenarios**:

1. **Given** an author editing a draft with a missing title, **When** they view the editor chrome, **Then** a subtle readiness indicator surfaces (e.g., "1 thing to fix before publishing").
2. **Given** the author completes all required fields, **When** they view the readiness indicator, **Then** it confirms the article is ready to publish.
3. **Given** a complete draft, **When** the author initiates publish, **Then** a lightweight confirmation step shows the article title and price for final review before going live.
4. **Given** the author wants to check the reader experience, **When** they open preview, **Then** the article renders as a reader would see it, including where free content ends and the paywall begins.

---

### Edge Cases

- What happens when an author has previously customized revenue splits and reopens the editor — are their non-default values preserved and the advanced section auto-expanded?
- How does the system handle an author who opens settings, makes changes, then closes settings without saving — are unsaved setting changes lost or preserved via autosave?
- What happens when the currency's USD price is unavailable or stale — does the USD estimate gracefully degrade rather than showing "NaN" or "0"?
- How does the conflict resolution behave if the author chooses "Keep my version" but the other session's changes included frozen-attribute changes (post-publish)?
- What happens when an author on a slow connection triggers multiple rapid price changes — does the estimate debounce correctly?
- How are tag suggestions scoped when an author has never used any tags (new account)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present only title, intro, and content fields when a new or existing draft article editor is opened, hiding all pricing, revenue, currency, reference, and collection controls by default.
- **FR-002**: System MUST provide a single Settings affordance that reveals all configuration sections (cover, tags, pricing, revenue, references, collection) on demand, and dismissible to return to the clean writing surface.
- **FR-003**: System MUST preserve sensible defaults for all hidden configuration (currency = BTC, price = platform minimum, revenue split = 50% author / 40% early readers / 10% platform, free content = 10%, no collection, no references) so the author can publish without ever opening Settings.
- **FR-004**: System MUST present price entry with USD as the primary denomination and the crypto equivalent as a secondary, read-only value.
- **FR-005**: System MUST offer quick-select price presets alongside custom USD entry.
- **FR-006**: System MUST present currency selection as a lightweight inline control, defaulting to BTC, rather than a full-screen modal grid.
- **FR-007**: System MUST display the USD price estimate with consistent decimal formatting at all times (server-rendered and client-updated values must match).
- **FR-008**: System MUST auto-resize the intro text field as the author types so all content is visible without an internal scrollbar.
- **FR-009**: System MUST present a clear, actionable resolution affordance when a save conflict is detected, offering the author a choice between reloading the latest version and keeping their current version.
- **FR-010**: System MUST NOT silently discard the author's in-flight edits during a save conflict.
- **FR-011**: System MUST hide revenue split controls by default, revealing them only when the author explicitly chooses to customize.
- **FR-012**: System MUST preserve all existing revenue split, reference, and collection functionality when advanced sections are opened — no feature is removed, only hidden by default.
- **FR-013**: System MUST keep revenue split defaults mathematically consistent (author + readers + platform + collection + references = 100%) and validate on change.
- **FR-014**: System MUST visibly disable and annotate revenue/currency/reference fields that are frozen after an article is published.
- **FR-015**: System MUST surface publish-readiness feedback inline in the editor (not only inside the publish modal), indicating what still needs attention.
- **FR-016**: System MUST provide a preview of the article as readers will experience it, including the paywall position based on the free-content ratio.
- **FR-017**: System MUST scope tag suggestions to relevant tags (popular or the author's own previously-used tags), not unscoped global tags.
- **FR-018**: System MUST reflect the expanded/collapsed state of any disclosure control (e.g., "Customize revenue split") with a visible indicator (e.g., icon rotation, label change, aria-expanded).
- **FR-019**: System MUST not regress existing autosave, optimistic-locking, draft-recovery, or publish-notification behavior beyond the explicit improvements above.
- **FR-020**: All new user-visible strings MUST be internationalized via locale files.

### Key Entities *(include if feature involves data)*

- **Article**: The core entity being created/edited. Key attributes relevant to this feature: title, intro, content, price, currency, free-content ratio, revenue split ratios (author/readers/platform/collection/references), published state. The data model and storage are unchanged; only the editing presentation changes.
- **Article Reference (Citation)**: An optional link from one article to another that shares a portion of revenue. Remains available behind an advanced disclosure.
- **Collection**: An optional grouping an article can belong to, which may claim a revenue share. Remains available behind configuration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new author can open the editor and begin typing within 2 seconds, seeing only title, intro, and content — zero configuration decisions required before the first keystroke.
- **SC-002**: An author can set a price and publish using only the default settings (without opening any advanced section) — 100% of default-configured articles publish successfully.
- **SC-003**: An author experiencing a save conflict is presented with a resolution path within 1 second of the conflict, with zero instances of silent edit loss.
- **SC-004**: The number of form fields visible by default on the editor is reduced from 12 to 3 (title, intro, content), with all 12 remaining reachable via progressive disclosure.
- **SC-005**: The intro text field grows dynamically to fit all typed content with no internal scrollbar in 100% of cases.
- **SC-006**: USD price formatting is consistent (no decimal-place jumps) across 100% of price edits.
- **SC-007**: All existing advanced features (custom revenue splits, references, collections, currency change) remain fully functional — zero feature regressions measured by existing test coverage.
- **SC-008**: Publish-readiness issues are surfaced inline before the author clicks "Publish," reducing publish-modal-abandoned attempts.

## Assumptions

- The existing data model, revenue-split math, payment integrations, and publish-notification pipeline remain unchanged — this feature is a presentation and interaction-layer refactoring.
- Revenue split defaults (50% author / 40% early readers / 10% platform) and the minimum price logic are correct and will not be changed by this work.
- The existing rich-text editor, autosave mechanism, and optimistic-locking infrastructure are retained and extended, not replaced.
- Authors who have previously set non-default revenue splits or references will have their custom values preserved (not reset to defaults) when reopening the editor.
- Mobile and desktop both need the clean writing surface; the Settings affordance adapts to each form factor.
- The currency's USD price feed remains available for estimates; graceful degradation is needed for stale/unavailable rates.
- Tag suggestion scoping can reuse existing tag/popularity data without new backend infrastructure.
- This work builds on prior editor-related specs (notably 002-editorial-ui-redesign, 004-article-editor-ux-overhaul, 006-editorial-ui-polish) and focuses specifically on progressive disclosure and bug resolution rather than visual restyling.
