# Research: Article Editor Progressive Disclosure

**Date**: 2026-07-22 | **Feature**: 010-editor-progressive-disclosure

---

## R1: How to implement the distraction-free default editor (settings rail hidden by default)

**Decision**: Extend the existing `settingsRailOpen` Stimulus value (default `false`, already in `article_form_controller.js:18`) and CSS infrastructure. On desktop, change the grid layout from always-two-column to single-column by default, expanding to two-column (or an overlay panel) when settings open. On mobile, the pattern already works (`display: none` → `block` via `.article-editor--settings-open`).

**Rationale**: The toggle infrastructure already exists — `settingsRailOpenValueChanged()` toggles `.article-editor--settings-open` (line 145–150), and `toggleSettingsRail()` (line 156–158) is already wired. The CSS at `lexxy_overrides.css:156–180` already hides the rail on mobile by default and shows it on open. Only the desktop CSS (`@media (min-width: 1024px)`, lines 182–219) needs adjustment: default `grid-template-columns` to single-column, and switch to two-column (or overlay) when `.article-editor--settings-open` is present. A "Settings" gear button is already rendered in the editor chrome (`new.html.erb`, `_edit_form.html.erb`) and already calls `toggleSettingsRail`.

**Alternatives considered**:
- *New Stimulus controller for disclosure*: rejected — reuses existing infrastructure, no new controller needed.
- *Server-side show/hide (separate routes)*: rejected — adds latency and breaks the single-page editor mental model.
- *Remove settings rail entirely, put everything in publish flow*: rejected — too large a scope change; settings rail is still the right place for non-publish-time config (cover, tags).

---

## R2: How to hide the revenue section by default

**Decision**: In `_option_fields.html.erb`, wrap the entire revenue `<section>` in a collapsed disclosure by default. Show only a "Customize revenue split" affordance. When clicked, reveal the existing revenue controls (summary, readers/author/references ratios). The `article_revenue_controller.js#toggleRevenueAdvanced` method already exists (line 138) — extend it to manage `aria-expanded` and icon rotation. Auto-expand the section if the article has non-default values (e.g., `readers_revenue_ratio != 0.4` or references present).

**Rationale**: The toggle already exists but only toggles the "Advanced" sub-panel (lines 159–211 of `_option_fields.html.erb`). We extend the same pattern to the entire revenue section. Auto-expansion on non-default values handles the edge case (spec edge case #1) where an author previously customized splits.

**Alternatives considered**:
- *Move revenue to a separate modal*: rejected — breaks the inline editing + autosave flow.
- *Merge article_revenue into article_form controller*: deferred — the one-way event coupling (`article-revenue:queue-autosave`) works correctly today; merging is a larger refactor with regression risk. Note as Phase 5 follow-up.

---

## R3: How to hide references/citations behind a gate

**Decision**: Replace the always-visible references `<section>` (lines 215–237 of `_option_fields.html.erb`) with a collapsed "Cite articles & share revenue (advanced)" disclosure button. Clicking it reveals the nested-form container and the "Add reference" button. Existing `nested_form_controller.js` and `references_select_controller.js` are unchanged. If the article already has references, auto-expand the disclosure.

**Rationale**: The nested form infrastructure (`<template>`, `nested-form#add`, `nested-form#remove`) is self-contained and works when revealed dynamically — no initialization timing issue since Stimulus connects on DOM insertion.

**Alternatives considered**:
- *Lazy-load references via Turbo Frame*: rejected — unnecessary complexity; the template is lightweight.

---

## R4: How to implement USD-first pricing

**Decision**: Replace the crypto-native `price` number field with a USD-denominated primary input. Add quick-select preset chips ($0.50, $1, $2, $5). The hidden `article[price]` field continues to store the crypto amount; a new visible USD input drives it via JS conversion: `cryptoPrice = usdAmount / currency.price_usd`. The crypto equivalent is displayed as a read-only secondary line. The existing `currencyPriceUsdValue` in `article_form_controller.js` (line 13) already carries the conversion rate.

**Rationale**: The storage model (`Article#price` in crypto, `Currency#price_usd` as the rate) is unchanged — only the input affordance changes. The `Currency#minimal_price_amount(usd)` method (line 62) already demonstrates the USD→crypto conversion pattern (`BigDecimal(price.to_f / price_usd, 1).ceil(8)`). Server-side, `assign_new_article_defaults!` already sets `price = currency.minimal_price_amount` (~$0.10 default), so the USD default is already $0.10.

**Constraints**: When `currency.price_usd` is zero or unavailable (stale feed), the USD input should be disabled with a graceful message — not show "NaN" (spec edge case #3).

**Alternatives considered**:
- *Store price in USD, convert on read*: rejected — would require migration and break all existing order/revenue math. Constitution mandates revenue-split math consistency.
- *Dual input (both editable)*: rejected — confusing; USD is primary, crypto is derived/read-only.

---

## R5: How to fix the price-USD decimal formatting inconsistency (B2)

**Decision**: Create a shared formatting helper used by both the server-side ERB render and the client-side JS update. Standardize on 2 decimal places for display (`.toFixed(2)` in JS, `.floor(2)` in Ruby — but make them match). The current bug: `_option_fields.html.erb:116` uses `.floor(2)` while `article_form_controller.js#calPriceUsd` (line 457) uses `.toFixed(4)`.

**Rationale**: The fix is a one-line change in `calPriceUsd` (`.toFixed(4)` → `.toFixed(2)`) plus ensuring the initial server render uses the same format. Centralizing in a helper prevents future drift.

**Alternatives considered**:
- *Use a number formatting library*: rejected — overkill for a 2-decimal display; native `.toFixed(2)` suffices.

---

## R6: How to implement the intro auto-resize (B1)

**Decision**: Create `app/javascript/controllers/textarea_controller.js` — a minimal Stimulus controller that resizes its element on `input` events. Register it in `index.js`. The reference at `_form.html.erb:29` (`data-controller="textarea"`, `input->textarea#resize`) is already in place and will start working once the controller exists.

**Implementation**: `resize()` sets `height = "auto"` then `height = scrollHeight + "px"`. Called on `input` and on `connect()`.

**Rationale**: The view already references this controller — creating it is the lowest-risk fix. Auto-resize is a standard UX pattern. The controller is reusable for any textarea in the app.

**Alternatives considered**:
- *Remove the reference and use CSS-only resize*: rejected — CSS `field-sizing: content` is too new (limited browser support); the JS approach is proven.
- *Use a third-party autosize library*: rejected — adds a dependency for ~10 lines of code.

---

## R7: How to implement save-conflict resolution (B6)

**Decision**: Extend the 409 conflict path to render a resolution UI. Currently `ArticlesController#update` rescues `StaleObjectError` → renders `update_conflict.turbo_stream.erb` (status 409), which only updates the save-status pill and lock_version. Add a conflict-resolution banner/modal rendered via the same turbo stream, offering two actions:
1. **"Reload latest"** — triggers a Turbo visit to `edit_article_path` (full page reload with server-fresh data).
2. **"Keep my version"** — updates `lockVersionValue` to the server's latest (from the 409 response meta), clears the conflict status, and re-queues autosave so the author's in-flight edits are submitted against the new lock_version.

The author's local edits are preserved in the form DOM throughout — they are never cleared on conflict.

**Rationale**: The current flow silently refreshes `lock_version` (via `syncLockVersionFromMeta()` at line 298) which means the next autosave will silently overwrite with the author's version — but the author has no awareness of the conflict or agency in the decision. The resolution UI gives them explicit control. "Keep my version" is safe because it just bumps the lock_version and resubmits — the same thing that happens now, just visibly. "Reload latest" discards local edits intentionally (with the author's consent).

**Constraints** (spec edge case #4): If the other session's changes included frozen-attribute changes (post-publish), the "Keep my version" resubmit will fail validation on frozen attributes — the existing `cannot_edit_frozen_attributes_once_published` validator handles this, and the error will surface via the normal validation error path.

**Alternatives considered**:
- *Auto-merge (operational transform)*: rejected — massive complexity for a rare conflict scenario in a single-author system.
- *Always discard local on conflict*: rejected — violates FR-010 (no silent data loss).
- *Always keep local on conflict*: rejected — the author should be aware and choose; silently overwriting could clobber a co-editor's work.

---

## R8: How to scope tag suggestions (B3)

**Decision**: Replace `Tag.all.first(10).pluck(:name)` (`_option_fields.html.erb:36`) with `Tag.recommended.limit(10).pluck(:name)`. The `Tag.recommended` scope already exists (`tag.rb:28`: `order(articles_count: :desc, created_at: :desc)`) — it orders by article count (popularity). For new accounts with no tag history (spec edge case #6), this returns the most popular tags globally, which is the best cold-start default.

**Rationale**: The scope already exists and is the right semantic. The fix is a one-line change. `Tag.recommended` leverages the existing `articles_count` counter cache (no N+1).

**Alternatives considered**:
- *Scope to author's previously-used tags only*: rejected — cold-start problem for new authors; recommended tags are a better default. Could be a future enhancement.
- *Live search only (no pre-loaded options)*: rejected — TomSelect needs initial options for discoverability.

---

## R9: How to add disclosure toggle state indicators (B5)

**Decision**: For every disclosure toggle (revenue section, references section, advanced revenue panel), add `aria-expanded` attribute and a chevron icon that rotates on toggle. Update `article_revenue_controller.js#toggleRevenueAdvanced` to set `aria-expanded` on the trigger button and toggle an icon class.

**Rationale**: Accessibility (constitution principle III) requires `aria-expanded` for disclosure widgets. The icon rotation is a standard Tailwind transform (`rotate-180` on the chevron `span`).

**Alternatives considered**:
- *CSS-only `:has()` selector for icon rotation*: rejected — `:has()` support is recent; explicit JS is more reliable.

---

## R10: How to surface publish-readiness inline (FR-015)

**Decision**: Add a readiness indicator in the editor chrome (next to the publish button) that shows a count of blockers or a "Ready" state. Compute readiness client-side from the form state (title present, intro present, content present, price valid). The existing `Dashboard::PublishedArticlesController#publish_readiness_errors` logic (lines 29–38) runs server-side in the publish modal — the inline indicator is a lightweight client-side mirror that catches the obvious blockers (blank fields) before the author clicks publish.

**Rationale**: The server-side validation is the source of truth (runs on publish). The inline indicator is a progressive-enhancement hint — if JS fails, the publish modal still catches errors. No backend change needed.

**Alternatives considered**:
- *Full server-side readiness API (polled)*: rejected — adds latency and load; the client-side check covers 95% of cases (blank fields).

---

## R11: Cleanup of dead code (B4)

**Decision**: The `touchDirty()` method in `article_form_controller.js` (line 460–464) is an intentional no-op with a documented comment (issue #1839). Remove the `article-form#touchDirty` dispatch from `article_references/_form.html.erb` (the reference add/remove already triggers autosave via `article-revenue#calReferenceRatio`). Optionally remove the empty `touchDirty()` method itself.

**Rationale**: Dead dispatch sites are confusing. The autosave already works via the revenue controller's recalculation path. Removing the dispatch is safe.

---

## Summary: All NEEDS CLARIFICATION resolved

No items from the Technical Context required clarification — all decisions have clear answers from the existing codebase. The feature is entirely a presentation/interaction-layer change that extends existing infrastructure.
