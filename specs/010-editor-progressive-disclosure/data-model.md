# Data Model: Article Editor Progressive Disclosure

**Date**: 2026-07-22 | **Feature**: 010-editor-progressive-disclosure

---

## Persistent Data Model — UNCHANGED

This feature introduces **zero schema changes**. The existing `articles` table, `article_references` (CiterReference), `collections`, `currencies`, and ActionText rich-text storage remain exactly as-is. All revenue-split math, price storage, and publish-state transitions are preserved.

### Article (existing, unchanged columns relevant to the editor)

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `title` | string | nil | ≤ 64 chars; presence required unless drafted |
| `intro` | string | nil | ≤ 140 chars; auto-truncated in `set_defaults` |
| `content` | ActionText rich_text | nil | via `has_rich_text :content`; presence required unless drafted |
| `price` | decimal | `currency.minimal_price_amount` (~$0.10) | stored in crypto units; **unchanged** |
| `asset_id` | uuid | `BTC_ASSET_ID` | FK → currencies; frozen after publish |
| `free_content_ratio` | float | 0.1 | 0.0–0.9; controls paywall position |
| `platform_revenue_ratio` | float | 0.1 | **locked**; validated to equal 0.1 |
| `readers_revenue_ratio` | float | 0.4 | ≥ 0.1 |
| `author_revenue_ratio` | float | 0.5 | ≤ 0.8; auto-calculated as remainder |
| `collection_revenue_ratio` | float | 0.0 | auto-set from bound collection |
| `references_revenue_ratio` | float | 0.0 | must equal sum of article_references ratios |
| `lock_version` | integer | 0 | optimistic locking; **unchanged mechanism** |
| `state` | string | "drafted" | AASM: drafted/published/hidden/blocked |
| `published_at` | datetime | nil | set on first publish |

**Validation rules (unchanged)**: `ensure_revenue_ratios_sum_to_one` (sum = 1.0), `ensure_references_ratios_correct`, `cannot_edit_frozen_attributes_once_published`, `ensure_price_not_too_low`. These all remain exactly as defined in `app/models/article.rb`.

### Article Reference / CiterReference (unchanged)

Nested attributes for revenue-sharing citations. `accepts_nested_attributes_for :article_references` with `allow_destroy`. Frozen (hidden) after publish.

### Collection (unchanged)

Optional `belongs_to :collection`. When bound, `collection_revenue_ratio` is auto-set from the collection's configured ratio.

---

## Presentation State Model (client-side, new)

These are **Stimulus controller values** that drive the UI disclosure state. They are not persisted — they exist only in the browser session.

### article-form controller values (extended)

| Value | Type | Default | Purpose |
|-------|------|---------|---------|
| `settingsRailOpen` | Boolean | **`false`** (changed from current behavior) | Controls settings panel visibility. Already exists — changing the default + desktop CSS makes it hidden by default. |
| `saveStatus` | String | "idle" | Unchanged; now also drives conflict-resolution UI visibility. |
| `lockVersion` | Number | 0 | Unchanged; updated on conflict resolution "Keep my version". |
| `currencyPriceUsd` | Number | (from server) | Unchanged; now also drives USD-first price input conversion. |
| `priceUsdInput` | String | (derived) | NEW: the USD-denominated price the author types; converted to crypto for the hidden `price` field. |

### article-revenue controller values (extended)

| Value | Type | Default | Purpose |
|-------|------|---------|---------|
| `revenueAdvancedOpen` | Boolean | `false` | NEW: tracks whether the "Customize revenue split" disclosure is expanded. Auto-set to `true` on connect if the article has non-default ratios or references. |
| `referencesOpen` | Boolean | `false` | NEW: tracks whether the "Cite articles" disclosure is expanded. Auto-set to `true` on connect if the article has existing references. |

### State transitions (presentation only)

```
Settings Rail:  closed --[click gear]--> open --[click gear/close]--> closed
                    \--[autosave continues regardless of rail state]/

Revenue Section: collapsed --[click "Customize"]--> expanded --[click]--> collapsed
                     \--[auto-expand if non-default values on load]/

References Section: collapsed --[click "Cite articles"]--> expanded --[click]--> collapsed
                        \--[auto-expand if existing references on load]/

Conflict Resolution: none --[409 response]--> conflict-shown
                      --[click "Reload latest"]--> page-reload (discards local)
                      --[click "Keep my version"]--> lock-version-bumped + autosave-retry
```

---

## No New Migrations

This feature requires **zero database migrations**. All changes are in:
- ERB views (presentation)
- Stimulus JS controllers (interaction)
- CSS (layout)
- Locale YAML files (i18n strings)
- One controller method refinement (`ArticlesController#update` conflict response shape — same HTTP 409, enriched turbo stream payload)
