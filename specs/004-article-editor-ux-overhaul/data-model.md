# Phase 1 Data Model: Article Editor Redesign

This feature is overwhelmingly a presentation/interaction-layer change. Exactly one schema change is introduced (optimistic locking, research item 3); everything else reuses existing `Article` columns, associations, and validations as-is. No new tables.

## Article (existing model, one new column)

`app/models/article.rb` — no new business columns. One infrastructure column added to support reliable autosave conflict detection:

| Column | Type | Notes |
|---|---|---|
| `lock_version` | `integer`, `default: 0, null: false` | **NEW**. Standard Rails optimistic-locking column name — `ActiveRecord` automatically enables optimistic locking on any model with a column named exactly `lock_version`; no extra model code required beyond the migration itself. Incremented automatically by Rails on every successful `update`/`update!`. Client includes the `lock_version` it last saw with each autosave `PATCH`; a mismatch raises `ActiveRecord::StaleObjectError`, caught in `articles#update` and turned into a 409 "conflict, reload" response rather than a silent overwrite (research item 3, FR-007). |

**Migration** (new file under `db/migrate/`, timestamp per repo convention):

```ruby
class AddLockVersionToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :lock_version, :integer, default: 0, null: false
  end
end
```

No `down` ambiguity — a straightforward additive, reversible column.

**Existing columns/validations reused as-is** (all already present, per direct inspection of `app/models/article.rb`):

- `title`, `intro`, `content` (ActionText, via `RichTextContent` concern) — content fields, unchanged.
- `price`, `asset_id` (currency), `free_content_ratio` — pricing/access fields, unchanged validations (`ensure_price_not_too_low`, presence/numericality).
- `author_revenue_ratio`, `readers_revenue_ratio`, `platform_revenue_ratio`, `collection_revenue_ratio`, `references_revenue_ratio` — revenue-split fields; `ensure_revenue_ratios_sum_to_one` and `ensure_references_ratios_correct` remain the single source of truth for validity, now also mirrored client-side for real-time feedback (research item 6) but never duplicated server-side.
- `collection_id`, `cover` (ActiveStorage attachment), `tags`/`taggings` (via `CreateTagService`) — settings fields, unchanged.
- `article_references` (`CiterReference` join model, `accepts_nested_attributes_for`) — References section, unchanged.
- `state` (AASM: `drafted` → `published`/`hidden`/`blocked`), `ensure_content_valid` guard — Publish Readiness (User Story 4) reuses this guard plus the model's own `valid?` rather than introducing a parallel readiness concept.
- `cannot_edit_frozen_attributes_once_published` — governs which settings become read-only post-publish; the redesigned panel now explains *why* a field is disabled (FR-016) by referencing which of these frozen-attribute rules applies, but the rule itself is unchanged.

## Key Entities (from spec.md) mapped to implementation

- **Autosave State** → Not a persisted model. Client-side Stimulus values (`saveStatusValue`: `idle`/`dirty`/`saving`/`saved`/`error`) plus the existing `localStorage` draft-recovery mechanism (`draftKeyValue`, extended to also snapshot settings fields, not just title/intro/content) and the new `lock_version` value threaded through each request/response.
- **Revenue Split** → The existing five ratio columns on `Article` plus the client-side computed summary (not persisted — derived and re-rendered from the same column values on every change).
- **Article Settings** → No new model; a UI-layer grouping (Cover & Tags / Pricing & Access / Revenue Split / References / Collection) over existing `Article` attributes/associations, replacing the current single flat `_option_fields.html.erb` list.
- **Publish Readiness** → Not persisted; computed on demand from `@article.valid?` (full validation set) + `@article.errors`, surfaced in the publish-confirmation modal (`dashboard/published_articles#new`).
- **Focus Mode** → Not persisted, not modeled server-side at all; pure client-side (Stimulus) view state with no data implications.
- **Reader Preview** → Not persisted; a read-only rendering of the existing, already-saved `Article` record via existing partials (`articles/_full_content`, `articles/_partial_content`), gated by `article.free?` rather than a new column.

## State Transitions (unchanged)

The AASM state machine (`drafted → published → hidden`, `hidden → published`, `published/hidden → blocked`, `blocked → hidden`) is unchanged by this feature. What changes is only the *feedback* an author receives before/while attempting the `publish` transition (User Story 4) — no new states, no new transitions, no new guards beyond the existing `ensure_content_valid`.
