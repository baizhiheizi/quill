# Feature Specification: Article Editor Redesign — Modern, Unified Writing & Publishing Experience

**Feature Branch**: `004-article-editor-ux-overhaul` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "The article create/edit flow is the core feature of the project, we need to make it super smooth and friendly to users. Help me to review the current implementation, provide the improvements and refactor. Make it modern, pro and user-friendly. I find some issues: 1. user must click save draft to save it, it might be auto save; 2. the settings/config form is super complicated and ugly. Do not limited to my found issues. Audit it yourself as a pro designer and product manager."

*(This spec follows `specs/002-editorial-ui-redesign/` and `specs/003-editorial-redesign-rollout/`, which redesigned the visual system across public pages and the dashboard, and gave the editor a visual-only restyle — explicitly preserving "available fields, settings, validations, or the publishing/saving flow" per `003`'s FR-025. Per the Clarifications below, this feature goes further: it is a full, from-scratch reimagining of the editor's structure, layout, and interaction — not just a behavioral patch — while continuing to build on the same underlying design tokens (colors, typography, components, icons) established by that prior work. It supersedes `003`'s editor visual restyle wherever the two would otherwise conflict.)*

## Clarifications

### Session 2026-07-04

- Q: Should the editor be free to introduce new visual treatments (layout rhythm, chrome, motion) specific to a focused writing tool, while still reusing the core design tokens (colors, typography, `-soft` components, icons) already established in the 002/003 redesign? → A: Yes — reuse the core tokens, but the editor may introduce new editor-specific layout, chrome, and motion; this is not a strict reuse of existing patterns, nor a fully independent visual identity disconnected from the rest of the product.
- Q: Should the redesign be free to replace today's two-tab "Edit / Options" structure with a different layout paradigm entirely (e.g. persistent sidebar, slide-over drawer, single continuous view)? → A: Fully open — there is no obligation to preserve the current tab structure; the redesign should propose whichever layout paradigm best serves a modern, focused editing experience.
- Q: Should this redesign stay limited to reimagining the presentation/interaction of the editor's existing capabilities, or is it open to a few new, complementary capabilities? → A: Open to a few tasteful, complementary additions if they clearly reduce friction or elevate quality — not open-ended feature growth. (Reflected below as User Story 5 — Focus Mode, and User Story 6 — Live Reader Preview, chosen because they directly reinforce the "modern, pro" goal and, for User Story 6, revive an already-scaffolded but currently unused preview mechanism rather than introducing net-new backend logic.)

## Audit Findings (Current State)

Independent audit of `app/controllers/articles_controller.rb`, `app/views/articles/_edit_form.html.erb`, `app/views/articles/_option_fields.html.erb`, and `app/javascript/controllers/article_form_controller.js` surfaced the following, beyond the two issues the user already identified:

1. **Manual, split save model**: The editor has two tabs, "Edit" (title/intro/content) and "Options" (pricing, revenue split, cover, tags, collection, references). Content changes autosave in the background on a 1-second debounce; Options changes do **not** autosave and require an explicit "Save" click on that tab. An author who edits both tabs can reasonably believe everything is saved when only the content was.
2. **New-article settings are hidden and silently defaulted**: On the "new article" screen, the entire Options panel is hidden from view, yet default pricing/currency/revenue-split values are still submitted on first save — an author can unknowingly publish-ready a priced article with platform defaults they never saw.
3. **Tags are dropped on first save**: Tag assignment only runs in the `update` action, not `create`, so tags entered before the first save are silently lost and must be re-entered.
4. **Revenue-split panel is overwhelming and confusing**: Six flat, identically-styled numeric fields (free-content ratio, readers/platform/collection/author/references revenue ratios) appear in a single unbroken list. Some are read-only-but-editable-looking (platform, collection), one is auto-calculated yet still manually editable (author), and the fields must sum to 1.0 with only an opaque server-side error if they don't. There is no plain-language explanation of what the split means for the author's actual earnings.
5. **Misplaced validation message**: A copy/paste bug shows `intro` validation errors underneath the *Collection* field instead of near the actual intro input.
6. **Likely broken autosave endpoint**: The autosave request looks up the article by `params[:article_uuid]`, but the route's member parameter is `:uuid` — meaning content autosave may be silently failing server-side and falling back to the local-only draft copy on every save, without any visible error to the author.
7. **Inconsistent draft-recovery signal**: A local backup copy exists for crash/offline recovery, but there is no persistent, always-visible indicator distinguishing "saved to your account" from "saved only on this device" — an author could close their laptop believing their work is safe when it is not yet on the server.
8. **Asymmetric, disorienting field states**: Currency selection is a modal picker while drafted, but a disabled native dropdown once published; several fields silently flip from editable to disabled after publishing with no explanation shown to the author at that moment.
9. **Mobile layout gaps**: Word count and last-saved status are hidden below the tablet breakpoint, and the three-column label/input grid in the settings panel stacks awkwardly on narrow screens.
10. **Hard-coded, non-localized strings**: Some field placeholders and labels bypass the i18n system used everywhere else in the product.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Never Lose Work: Automatic, Continuous Saving (Priority: P1)

As an author writing or configuring an article (new or existing), my changes are saved automatically as I work, so I never have to remember to click a save button and never risk losing content or settings changes.

**Why this priority**: This is the single most-cited pain point (explicitly reported by the user) and the highest-risk gap — silent data loss on a monetized publishing platform directly damages author trust. It is also foundational: once saving is automatic and reliable, the settings-form redesign (User Story 2) can be built on top of it without reintroducing a separate manual-save step.

**Independent Test**: Create a new article, type a title and some content, and navigate away without clicking any save button; return to the article and confirm the content is present. Repeat for an existing article: change a setting (e.g. price, tags, cover) without clicking any save button, navigate away, and confirm the change persisted.

**Acceptance Scenarios**:

1. **Given** I am writing a new article, **When** I type a title, subtitle, or body content and pause, **Then** my work is saved to my account automatically within a few seconds, without me clicking any button.
2. **Given** I am editing an existing article's settings (price, tags, cover, collection, revenue split, references), **When** I change a value and move to another field or pause, **Then** that change is saved to my account automatically, the same way content changes already are.
3. **Given** my work is being saved, **When** I look at the editor, **Then** I see a clear, unobtrusive status indicator that tells me whether my latest changes are saved, currently saving, or not yet saved.
4. **Given** an automatic save fails (e.g. I lose network connectivity), **When** the failure happens, **Then** I am shown a clear, visible indication that my latest changes have not reached my account yet (not just a silently-updated local copy), and the system keeps retrying without requiring me to take action.
5. **Given** I return to editing an article after closing the tab or losing connectivity mid-edit, **When** the page reloads, **Then** I see my most recent saved work, and if a more recent unsaved local copy exists, I am given the choice to recover it.
6. **Given** I have unsaved-but-not-yet-confirmed changes, **When** I try to navigate away or close the tab, **Then** I am warned only if there is a real risk of data loss (i.e. autosave has not yet caught up) — not as a matter of routine, since routine saving no longer requires my action.
7. **Given** I am the author of a published (already-live) article, **When** I edit its content or its still-editable settings, **Then** those changes also autosave the same way, consistent with how editing a draft behaves.

---

### User Story 2 - A Settings Panel That's Easy to Understand and Trust (Priority: P2)

As an author configuring an article's price, revenue split, cover, tags, collection, and references, I see a clearly organized, plain-language settings experience — not a long flat list of similarly-styled numeric fields — so I understand what I'm setting and trust the numbers are correct before I publish.

**Why this priority**: This is the second issue the user explicitly flagged, and the audit confirms it's the most complex, error-prone surface in the editor (six revenue fields that must sum to 1.0, several of which are read-only-but-editable-looking). It depends on User Story 1 being in place so that reorganizing this panel doesn't reintroduce a manual "Save" requirement.

**Independent Test**: Open the settings panel for a new and an existing article; confirm related settings (e.g. cover/tags/collection, pricing, revenue split, references) are visually grouped into clearly labeled sections rather than one continuous list, confirm read-only values are visually distinguished from editable ones, and confirm the revenue split is presented in a way that shows the author their resulting take-home share in plain language before they publish.

**Acceptance Scenarios**:

1. **Given** I open the article settings, **When** the panel renders, **Then** related fields are grouped into clearly labeled sections (e.g. cover & tags, pricing, revenue split, references, collection) instead of one undifferentiated list.
2. **Given** a setting is fixed by the platform (e.g. the platform's own revenue share) or auto-derived (e.g. a collection's share once one is selected), **When** I view it, **Then** it is visually and unambiguously presented as read-only/informational, not styled like an editable input.
3. **Given** I am configuring the revenue split, **When** I view the split, **Then** I see a plain-language, at-a-glance summary of what share I (the author) keep versus what goes to early readers, the platform, references, and any collection — before I need to interpret raw percentage fields.
4. **Given** I adjust one part of the revenue split, **When** the change would leave the split invalid (not summing correctly, or violating a minimum/maximum), **Then** I see immediate, inline, plain-language feedback at the moment I make the change — not only after attempting to publish or an opaque server error.
5. **Given** most authors do not need to customize the revenue split, **When** I first configure a new article, **Then** I am shown a sensible default split as a plain-language summary, with the detailed, individually-editable ratio fields tucked behind an explicit "Advanced" option I can open if I want manual control.
6. **Given** a field's validation fails, **When** the error is shown, **Then** it appears directly next to the field it belongs to (not next to an unrelated field).
7. **Given** I open the settings for a newly created (not-yet-saved) article, **When** I view it, **Then** the same settings panel used for existing articles is available immediately, not hidden until after a first save.
8. **Given** a field becomes disabled because the article is published (e.g. currency, revenue ratios), **When** I view that field, **Then** I see a brief explanation of why it can no longer be changed, rather than an unexplained disabled control.
9. **Given** I am using the editor on a mobile-width screen, **When** I open the settings panel, **Then** every field, label, and grouping remains fully legible and usable without awkward stacking or overflow.

---

### User Story 3 - One Unified Editing Experience (Priority: P3)

As an author, I experience writing content and configuring settings as one continuous, unified editing session — not two disconnected save flows — so I'm never confused about what has and hasn't been saved.

**Why this priority**: This directly resolves the "split save model" root cause identified in the audit (content and settings currently save through two different mechanisms with two different levels of reliability). It builds on User Story 1 (autosave everywhere) and complements User Story 2 (reorganized settings), rounding out the unification once both are in place.

**Independent Test**: Edit both content and settings on the same article in a single session; confirm both kinds of changes are saved through the same automatic mechanism and reflected by the same save-status indicator, with no separate "Save" action required for one but not the other.

**Acceptance Scenarios**:

1. **Given** I switch between the content view and the settings view while editing the same article, **When** I make changes in either, **Then** both are captured by the same save-status indicator (one source of truth for "is my work saved").
2. **Given** I have never manually saved my work, **When** I choose to publish, **Then** publishing still requires my own explicit, deliberate action (it is not automatic), and it reflects the latest autosaved state.
3. **Given** tags, cover, price, or any other setting is entered on a brand-new article before it has ever been explicitly saved, **When** the article is first persisted, **Then** none of that information is silently dropped (e.g. tags are no longer lost on first save).

---

### User Story 4 - Confident, Error-Free Publishing (Priority: P4)

As an author about to publish, I can see at a glance whether my article is ready to publish and, if not, exactly what's missing or invalid — so publishing failures never come as a surprise.

**Why this priority**: This closes the loop on the redesigned settings/autosave experience by ensuring the final, highest-stakes action (publishing, which is irreversible/monetized) is well-supported, but it's lower priority than the core saving and settings work since publish-readiness issues are currently rare rather than the primary complaint.

**Independent Test**: Attempt to publish an article that is missing required information (e.g. no content) and one that has an invalid revenue split; confirm each case shows a specific, actionable message before or at the point of publishing, rather than a generic failure.

**Acceptance Scenarios**:

1. **Given** an article is missing something required to publish (e.g. no title or no content), **When** I attempt to publish, **Then** I see a specific message telling me exactly what's missing.
2. **Given** an article's revenue split does not currently resolve to a valid configuration, **When** I attempt to publish, **Then** I see a specific message identifying the problem before the publish action is rejected.
3. **Given** an article is fully ready to publish, **When** I open the publish action, **Then** nothing about its current state blocks or warns me unexpectedly.

---

### User Story 5 - Distraction-Free Focus Mode (Priority: P5)

As an author who wants to concentrate on writing, I can enter a focus mode that minimizes visual chrome around the writing surface, so I can write without distraction while still trusting that my work is being saved.

**Why this priority**: A tasteful, purely additive complement to the "modern, pro" goal (per Clarifications), identified as a natural fit for a focused writing tool. It doesn't block or depend on the core reliability and settings work in P1–P4, so it is safe to prioritize last among the primary redesign work.

**Independent Test**: Enter focus mode while writing; confirm surrounding chrome (navigation, settings, secondary controls) recedes or hides, confirm save status remains visible or trivially accessible, and confirm exiting focus mode restores the full editor exactly as it was.

**Acceptance Scenarios**:

1. **Given** I am writing content, **When** I enable focus mode, **Then** non-essential chrome is hidden or minimized so the writing surface is the primary visual element.
2. **Given** I am in focus mode, **When** my work autosaves, **Then** I can still see a minimal save-status indicator without needing to exit focus mode.
3. **Given** I am in focus mode, **When** I need to access settings or publish, **Then** I can do so without a jarring or disorienting transition.
4. **Given** I exit focus mode, **When** the full editor reappears, **Then** it reflects the exact same content, cursor context, and save state as before I entered it.

---

### User Story 6 - See It As Readers Will (Live Reader Preview) (Priority: P6)

As an author preparing to publish, I can preview my article exactly as a reader will see it — including the free-content boundary and paywall presentation for priced articles — without leaving the editor, so I'm confident about how it will actually appear before I publish it.

**Why this priority**: The codebase already has a dormant, scaffolded-but-unused preview mechanism (`articles#preview` / `preview.turbo_stream.erb`); surfacing it is a high-value, comparatively low-effort addition that directly reinforces publishing confidence (User Story 4), making it a natural, low-risk final addition to this redesign.

**Independent Test**: Open the preview for a free article and for a priced article; confirm the free article's preview matches exactly how it renders to readers, and confirm the priced article's preview shows the free-content boundary and paywall presentation exactly as a non-purchasing reader would see it.

**Acceptance Scenarios**:

1. **Given** I am editing an article, **When** I open its preview, **Then** I see my content rendered with the exact same typography and layout readers will see on the public article page.
2. **Given** my article is priced, **When** I open its preview, **Then** I see the free-content boundary and paywall prompt exactly as an unpurchased reader would see them.
3. **Given** I make further edits after previewing, **When** I open the preview again, **Then** it reflects my latest autosaved changes.
4. **Given** I am previewing, **When** I want to return to editing, **Then** I can do so without losing any unsaved state.

---

### Edge Cases

- What happens when autosave requests arrive out of order (e.g. a slow request for an older edit completes after a newer one)? The system MUST ensure the most recent edit always wins and an older save can never overwrite newer content.
- What happens when a user is offline for an extended period while continuing to edit? Local changes MUST continue to be preserved locally and MUST sync automatically once connectivity returns, without data loss or duplication.
- What happens when two browser tabs have the same article open at once? The author MUST NOT silently lose changes made in one tab due to an autosave from the other tab overwriting them without any indication.
- What happens when an author adjusts the revenue split to something invalid and then immediately closes the settings panel without correcting it? The invalid value MUST NOT be silently accepted as saved; the author MUST be made aware it still needs correction before publishing.
- What happens when an article has references whose combined revenue ratio no longer matches the aggregate references field (e.g. after removing a reference)? The displayed split summary MUST update immediately to reflect the current, correct total.
- What happens when a cover image upload is still in progress when an autosave fires? The autosave MUST NOT save a broken/partial cover reference; it should wait for the upload to complete or clearly indicate the upload is still pending.
- What happens when an author is editing a published article and changes a field that becomes read-only once published? The system MUST prevent the change from being submitted and MUST make clear why, rather than silently ignoring the input.
- What happens on very slow or flaky connections where each autosave takes several seconds? The status indicator MUST accurately reflect "saving" for the true duration rather than flickering or showing a false "saved" state prematurely.
- What happens when an author enables focus mode with unsaved-but-risky changes present? The save-status indicator's warning state MUST remain visible/accessible even in focus mode; focus mode MUST NOT hide the fact that something needs attention.
- What happens when an author opens the live preview for an article that has no content yet, or is missing a title? The preview MUST render a clear, non-broken empty/incomplete state rather than an error or blank screen.

## Requirements *(mandatory)*

### Functional Requirements

**Automatic saving (User Story 1)**

- **FR-001**: The system MUST automatically save an author's changes to both content fields (title, subtitle/intro, body) and settings fields (cover, tags, collection, price, currency, revenue split, references) to the author's account, without requiring an explicit "save" action, for both new and existing articles.
- **FR-002**: The system MUST display a persistent, unobtrusive save-status indicator reflecting one of at least three states: changes saved, currently saving, and changes not yet saved (including failure to save).
- **FR-003**: When an automatic save request fails to reach the author's account, the system MUST visibly indicate this to the author (not just retain a local-only copy silently) and MUST automatically retry without requiring manual intervention.
- **FR-004**: The system MUST preserve an author's most recent edits locally as a safety net in case of connectivity loss or crash, and MUST offer to recover that local copy if it is newer than the last confirmed server save when the author returns to the article.
- **FR-005**: The system MUST only warn an author before navigating away or closing the editor when there is a genuine risk of unsaved data loss (i.e., autosave has not yet caught up), not on every exit.
- **FR-006**: Automatic saving MUST apply consistently whether the article is a draft or already published, for every field that remains editable in each state.
- **FR-007**: The system MUST guarantee that an older, delayed autosave request can never overwrite a newer edit (last-writer-wins by edit recency, not by request arrival order).
- **FR-008**: No user-entered information (including tags) MUST be lost when an article is saved for the first time.

**Simplified settings panel (User Story 2)**

- **FR-009**: The settings panel MUST present its fields grouped into clearly labeled sections by purpose (e.g. cover & tags, pricing, revenue split, references, collection) rather than as one undifferentiated list of fields.
- **FR-010**: Fields that are platform-fixed or auto-derived from another selection MUST be visually and unambiguously distinguished from fields the author can directly edit.
- **FR-011**: The revenue split MUST be presented with a plain-language, at-a-glance summary of each party's resulting share (author, early readers, platform, references, collection where applicable) in addition to (or instead of, for the common case) raw percentage fields.
- **FR-012**: The system MUST validate the revenue split in real time as the author adjusts it, giving immediate, specific, plain-language feedback when the configuration is invalid — not only at publish/submit time.
- **FR-013**: New articles MUST offer a sensible default revenue split so that an author is not required to review or understand every individual ratio field to publish a reasonably-configured article. By default, the panel MUST show only the plain-language split summary; the raw, individually-editable ratio fields MUST be tucked behind an explicit "Advanced" control that any author can opt into to manually adjust the split.
- **FR-014**: Field-level validation errors MUST always be displayed adjacent to the field they describe.
- **FR-015**: The full settings panel (cover, tags, collection, pricing, revenue split, references) MUST be available and usable on a newly created, not-yet-saved article, not hidden until after a first save.
- **FR-016**: When a setting becomes non-editable because the article is published, the system MUST show a brief, clear explanation of why, rather than presenting an unexplained disabled control.
- **FR-017**: The settings panel MUST remain fully legible and usable — no overlapping or awkwardly stacked fields — at mobile widths.
- **FR-018**: All editor-facing labels, placeholders, and messages MUST be localized through the existing translation system rather than hard-coded.

**Unified editing experience (User Story 3)**

- **FR-019**: Content changes and settings changes MUST be captured by one consistent, single save/status mechanism rather than two separate save flows with different reliability or triggers.
- **FR-020**: Publishing MUST remain an explicit, deliberate author action, always operating on the latest autosaved state of the article, regardless of the autosave changes introduced by this feature.

**Confident publishing (User Story 4)**

- **FR-021**: When an article does not meet the requirements to publish, the system MUST tell the author specifically what is missing or invalid (e.g. missing content, invalid revenue split) rather than a generic failure message.
- **FR-022**: The system MUST prevent publishing an article whose revenue split does not resolve to a valid configuration, with a specific explanation of the problem.

**Correctness fixes (cross-cutting, surfaced by audit)**

- **FR-023**: The automatic content-save mechanism MUST reliably identify and update the correct article on every request (fixing the current mismatch between the autosave endpoint's expected identifier and the one actually sent).
- **FR-024**: The publish and other confirmation flows MUST correctly target and update the visible article on screen after completing (fixing any current mismatch that could leave stale content displayed after a successful action).

**Focus mode (User Story 5)**

- **FR-025**: The editor MUST offer an optional focus/distraction-free mode that minimizes non-essential chrome around the writing surface while preserving visible or trivially accessible save status.
- **FR-026**: Exiting focus mode MUST restore the full editor to the exact state it was in before entering — no loss of content, cursor context, or save state.

**Live reader preview (User Story 6)**

- **FR-027**: The editor MUST let an author preview their article's current autosaved state exactly as a reader would see it, without leaving the editor.
- **FR-028**: For priced articles, the preview MUST show the free-content boundary and paywall presentation exactly as an unpurchased reader would experience it, using the platform's existing paywall-preview logic rather than a separate/new implementation.

### Key Entities

- **Autosave State**: The per-article, per-session record of what has been locally captured versus confirmed saved to the author's account, including timestamps used to resolve which copy (local vs. server) is newer and to drive the save-status indicator.
- **Revenue Split**: The set of proportions (author, early readers, platform, references, collection) that together must account for 100% of an article's future revenue; includes both platform-fixed and author-adjustable components.
- **Article Settings**: The non-content configuration of an article — cover image, tags, collection membership, price, currency, revenue split, and references — as distinct from its title/subtitle/body content.
- **Publish Readiness**: The evaluated state of whether an article currently satisfies everything required to be published, and the specific reasons if it does not.
- **Focus Mode**: A temporary, toggleable editor display state that minimizes non-essential chrome around the writing surface without altering the underlying article data or autosave behavior.
- **Reader Preview**: A read-only rendering of an article's current autosaved state using the exact same presentation (typography, layout, paywall boundary) a reader would experience on the public article page.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Authors can leave the editor at any point after making a change (content or settings) without clicking any save control and find 100% of that work preserved when they return.
- **SC-002**: Zero instances of an author's tags, cover, or other settings being silently lost between a new article's first save and its next load.
- **SC-003**: An author can determine, within one glance at the editor and without reading documentation, whether their latest change is saved, saving, or at risk of not being saved.
- **SC-004**: An author configuring the revenue split can state their own resulting take-home share correctly without needing to manually compute or explain any ratio arithmetic (verified via usability review of the redesigned summary).
- **SC-005**: 100% of validation errors shown in the settings panel appear directly next to the field they describe (zero misplaced/mismatched error messages).
- **SC-006**: The settings panel remains fully usable (no overlapping elements, no horizontal scrolling) at common mobile widths, matching the standard already met by the rest of the redesigned product.
- **SC-007**: Publish attempts that fail do so with a specific, actionable reason 100% of the time — zero generic/unexplained publish failures.
- **SC-008**: No functional regressions: every currently-working editor capability (content editing, pricing, revenue split, cover, tags, collection, references, publish, hide, delete draft) continues to work, verified by the existing automated test suite continuing to pass alongside new coverage for autosave and validation behavior.
- **SC-009**: Authors can toggle focus mode on and off with zero loss of content, cursor position, or save state, verified across repeated toggles.
- **SC-010**: Authors can preview any article — free or priced — exactly as a reader would experience it, including the paywall boundary, without leaving the editor, in 100% of manual verification passes.

## Assumptions

- Per the Clarifications above, this feature reuses the core design tokens shipped in `specs/002-editorial-ui-redesign/` and `specs/003-editorial-redesign-rollout/` (colors, typography scale, `-soft` components, `i-tabler-*` icons) as its foundation, but is explicitly free to introduce new editor-specific layout structures, chrome, spacing rhythm, and motion/transitions where they serve a more modern, focused writing experience. This is a from-scratch reimagining of the editor's structure and interaction, not a constrained reorganization of the current tab layout — it supersedes `003`'s editor chrome restyle wherever the two conflict.
- The terms "settings panel" and "options" used throughout this spec refer generically to wherever the redesigned editor surfaces non-content settings (price, revenue split, cover, tags, collection, references) — this does not mandate any specific layout mechanism (tabs, sidebar, drawer, slide-over, or single continuous view); the concrete layout is a planning-phase decision guided by the "fully open" structural freedom recorded in Clarifications.
- The two new complementary capabilities (focus mode, live reader preview) are additive: they introduce no new business rules, revenue logic, or publishing rules of their own. Live reader preview specifically reuses the platform's existing paywall/free-content-boundary logic (already implemented for the public article page) rather than introducing a parallel implementation.
- "Automatic saving" means the author is never required to click a save control for routine content or settings edits to be persisted to their account; it does not mean publishing itself becomes automatic — publishing remains an explicit, separate, deliberate action (per FR-020).
- **Autosave applies uniformly to drafts and already-published articles alike**, per explicit user decision — an author editing a live article does not need to click an explicit "Save" for their changes (to whatever fields remain editable post-publish) to take effect; there is no separate manual-save mode for published articles.
- **The revenue-split panel defaults to a guided, plain-language view**, per explicit user decision — the individually-editable ratio fields (readers/author/references shares) are shown only when an author opts into an explicit "Advanced" control, rather than always being visible to every author. Full manual control remains available; it is just not the default surface.
- The underlying revenue-split business rules (platform's fixed share, minimum/maximum bounds on each ratio, the requirement that all shares sum to 100%) are unchanged by this feature; only how those rules are presented, explained, and validated in the UI changes.
- No new pricing/currency/revenue-model capabilities are introduced (e.g. no new currencies, no new split types) — this is a UX and reliability overhaul of the existing settings, not a new monetization feature.
- Existing publish/hide/delete-draft flows and their underlying authorization rules are unchanged; only the readiness feedback shown to the author around publishing (User Story 4) is new.
- The autosave mechanism's underlying transport (how and how often the client talks to the server) is an implementation detail left to the planning phase, as long as the author-facing behavior in FR-001 through FR-008 is satisfied.
