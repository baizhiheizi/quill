# Editor UI Interaction Contract

**Date**: 2026-07-22 | **Feature**: 010-editor-progressive-disclosure

This contract defines the user-facing interaction surface of the article editor after refactoring. It describes what the user sees and does — not implementation internals.

---

## Default Editor State (new article or existing draft)

**Visible by default** (3 elements only):
1. Title text field (full width)
2. Intro text area (auto-resizing)
3. Rich-text content editor (full width)

**Chrome elements** (always visible):
- Logo / brand link (exit to dashboard)
- Save status indicator (idle / saving / saved / error / conflict)
- Settings toggle button (gear icon)
- Publish button (only on persisted drafts; disabled while dirty/saving/error/conflict)
- Author avatar + "Draft" label

**Hidden by default** (revealed via Settings toggle):
- Cover image upload
- Tag selector
- Pricing section (USD-first price + currency)
- Revenue split section (collapsed to "Customize" affordance)
- References/citations section (collapsed to "Cite articles" affordance)
- Collection selector

---

## Settings Panel Interaction

| Action | Trigger | Result |
|--------|---------|--------|
| Open settings | Click gear button | Settings panel slides in (desktop: sidebar expands; mobile: bottom sheet) |
| Close settings | Click gear button again, or click outside | Settings panel hides; writing surface returns to full width |
| Edit a setting | Change any field inside settings | Autosave fires (debounced 1s); status → "saving" → "saved" |
| Close settings with unsaved changes | Close while autosave pending | Changes are NOT lost — autosave continues in background |

**Constraint**: Closing settings never discards entered values. The autosave pipeline is independent of panel visibility.

---

## Pricing Section (inside Settings)

**Layout**:
- Primary: USD price input with preset chips ($0.50, $1, $2, $5, Custom)
- Secondary (read-only): crypto equivalent line, e.g., "≈ 0.000031 BTC"
- Currency: inline control showing current currency (default BTC) with a "Change" link

**Interaction**:
| Action | Result |
|--------|--------|
| Click a preset chip | USD input updates; crypto equivalent recalculates |
| Type custom USD amount | Crypto equivalent updates on change |
| Click "Change" currency | Inline selector appears (not full modal grid); selecting updates crypto equivalent |
| Price below minimum | Validation error shown inline ("Minimum price is ~$0.10") |

**Formatting contract**: USD display is always 2 decimal places. No decimal-place jumps between server render and client update.

**Graceful degradation**: If `currency.price_usd` is 0 or unavailable, USD input is disabled with message "Price feed unavailable — try again later."

---

## Revenue Split Section (inside Settings)

**Default state**: Collapsed. Shows only a "Customize revenue split" button with a brief default summary ("50% you · 40% early readers · 10% platform").

**Auto-expand**: If the article has non-default ratios (readers ≠ 0.4, or references present, or collection bound), the section auto-expands on editor load.

| Action | Result |
|--------|--------|
| Click "Customize revenue split" | Section expands; chevron rotates; `aria-expanded=true` |
| Adjust readers ratio | Author ratio auto-recalculates; summary updates; split validates to 100% |
| Add/remove references | References ratio recalculates; author ratio adjusts |
| Bind a collection | Collection ratio appears; author ratio adjusts |
| Split does not sum to 100% | Summary shows error styling |
| Published article (frozen) | All ratio fields visibly disabled with "Locked after publishing" note |

---

## References/Citations (inside Settings)

**Default state**: Collapsed. Shows only a "Cite articles & share revenue (advanced)" button.

**Auto-expand**: If the article has existing references, auto-expands on load.

| Action | Result |
|--------|--------|
| Click "Cite articles" | Disclosure expands; existing references shown; "Add reference" button visible |
| Click "Add reference" | New reference row appears with article picker + ratio field |
| Select an article to cite | TomSelect picker with author avatars; loads from author's available articles |
| Set reference ratio | Ratio field (0.01–0.5); updates references_revenue_ratio total |
| Remove a reference | Row hides; references_revenue_ratio recalculates |
| Published article | Entire section hidden (add/remove disabled post-publish) |

---

## Save Conflict Resolution (new)

**Trigger**: Autosave receives HTTP 409 (another session saved the same article first).

**Response**: A conflict-resolution banner appears (not just a status pill), offering:

| Option | Action | Data outcome |
|--------|--------|--------------|
| "Reload latest" | Full page reload to `edit_article_path` | Local edits are discarded; server-fresh content loads. Author is warned before discarding. |
| "Keep my version" | Lock version updated to server's latest; autosave re-queued | Local edits are submitted against the new lock version. |

**Constraint**: The author's in-flight edits are NEVER silently discarded. The conflict UI must appear within 1 second of the 409. The form DOM retains all local edits until the author explicitly chooses "Reload latest."

**Edge case**: If "Keep my version" resubmit hits a frozen-attribute validation error (post-publish), the normal validation error path surfaces the error inline.

---

## Publish Readiness Indicator (inside Chrome)

**Location**: Next to the Publish button in the editor chrome.

**States**:
| State | Condition | Display |
|-------|-----------|---------|
| "N things to fix" | Title, intro, or content blank; or price invalid | Subtle pill with count |
| "Ready to publish" | All required fields valid | Green check / "Ready" |
| Hidden | New record (not yet persisted) | Not shown until first autosave creates the record |

**Constraint**: This is a client-side hint. The publish modal's server-side validation remains the source of truth.

---

## Locale Keys (new i18n strings)

All new user-visible strings must be added to `config/locales/articles.*.yml`. Keys to add (names approximate):

- `articles.settings.open` / `articles.settings.close` — gear button labels
- `articles.price.usd_label` — "Price (USD)"
- `articles.price.presets.*` — preset chip labels
- `articles.price.crypto_equivalent` — "≈ %{amount} %{symbol}"
- `articles.price.feed_unavailable` — graceful degradation message
- `articles.price.minimum_error` — minimum price validation
- `articles.revenue.customize` — "Customize revenue split"
- `articles.revenue.default_summary` — collapsed revenue summary
- `articles.references.cite_advanced` — "Cite articles & share revenue (advanced)"
- `articles.conflict.title` — "Save conflict detected"
- `articles.conflict.reload_latest` — "Reload latest"
- `articles.conflict.keep_mine` — "Keep my version"
- `articles.conflict.description` — explanation text
- `articles.readiness.things_to_fix` — "N things to fix before publishing"
- `articles.readiness.ready` — "Ready to publish"
