# Phase 1 Contracts: Article Editor Redesign

This is a server-rendered Rails monolith (Turbo/Stimulus, no separate frontend/backend or public API for this feature). "Contracts" here means the internal route/param/response and Stimulus-target contracts that both the server (views/controllers) and client (JS) code must agree on, so the pieces described in `research.md` and `data-model.md` fit together. No externally-consumed API is introduced.

## 1. Unified autosave/update endpoint

**Route**: `PATCH/PUT /articles/:uuid` → `articles#update` (existing route, unchanged signature; `update_content` route/action are removed).

**Request** (`Content-Type: application/json` or standard form-encoded, both supported since this reuses the existing `update_article_params`):

```json
{
  "article": {
    "title": "…",
    "intro": "…",
    "content": "…",
    "lock_version": 4,
    "price": "0.001",
    "free_content_ratio": 0.1,
    "readers_revenue_ratio": 0.4,
    "author_revenue_ratio": 0.5,
    "references_revenue_ratio": 0.0,
    "collection_id": "…",
    "tag_names": ["…"],
    "article_references_attributes": { "0": { "reference_id": "…", "revenue_ratio": 0.05 } }
  }
}
```

Any subset of `article` keys may be present — a content-only autosave omits settings keys and vice versa; `update_article_params`'s existing conditional permitting (published vs. drafted) is unchanged and still applies per-request.

**Response** (turbo_stream, `format.turbo_stream`):

- **Success (200)**: updates the save-status indicator to `saved`, updates `#{dom_id article}_words_count`, updates `#{dom_id article}_updated_at`, and returns the new `lock_version` (embedded as a `data-` attribute the Stimulus controller reads back into `lockVersionValue`) so the next autosave includes the correct value. Does **not** replace the whole settings panel (unlike today's full `update.turbo_stream.erb`, which replaces the entire `_edit_form`) — only the small, specific regions that changed, to avoid disrupting cursor/scroll/focus in the untouched parts of the form.
- **Validation failure (422, `ActiveRecord::RecordInvalid`)**: returns turbo_stream updates targeting only the specific field(s) with errors (per FR-014, errors render adjacent to their field), plus a `dirty`/`error` save-status update. Does not replace unrelated sections of the form.
- **Conflict (409, `ActiveRecord::StaleObjectError`, new)**: returns a turbo_stream instructing the client to re-fetch and reconcile (research item 3) plus a distinct "saved elsewhere" save-status state; does not attempt automatic field-level merging.

**Stimulus contract**: `article-form` controller (extended, not replaced) exposes:
- `saveStatusValue: String` (`"idle" | "dirty" | "saving" | "saved" | "error" | "conflict"`), consumed by a save-status indicator partial/target visible in both normal and Focus Mode chrome.
- `lockVersionValue: Number`, updated after every successful save, sent with every subsequent request.
- Requests are serialized: a new autosave request is only issued once the previous one has resolved; if edits happen mid-flight, the *latest* field values at resolution time are sent in the next request (no queued stack of stale partial diffs).

## 2. New-article creation (first autosave on `/articles/new`)

**Route**: `POST /articles` → `articles#create` (existing route; response format extended).

**Request**: same `article` params shape as above (whatever the author has entered so far — title/intro/content and/or any settings field, since the settings panel is now visible immediately on `new`, per FR-015), plus `tag_names` (fixes audit finding #3 / FR-008 — `CreateTagService` must now also run inside `create`, not only `update`).

**Response**:
- **Success**: JSON (or turbo_stream carrying a small script/data payload) containing `{ "uuid": "…", "edit_path": "/articles/:uuid/edit", "lock_version": 0 }`. Client updates `articleUuidValue`, `autosaveUrlValue` (now pointing at `PATCH /articles/:uuid`), `newRecordValue = false`, and calls `history.replaceState(null, "", edit_path)` — no Turbo visit, no full reload.
- **Validation failure**: same shape as the unified endpoint's 422 case above (field-level, non-disruptive).

**Contract note**: after this first successful creation, all subsequent autosaves for this article use contract §1 exclusively — `create` is never called again for the same article.

## 3. Publish readiness + publish action

**Route**: `GET /dashboard/published_articles/new?uuid=:uuid` (existing, confirmation modal) and `PUT /dashboard/published_articles/:uuid` (existing, `update` action performs the `publish!` AASM transition).

**Contract change**: `dashboard/published_articles#new` now computes `@article.valid?` (full validation context, not just the AASM `ensure_content_valid` guard) before rendering the modal, and passes `@article.errors.full_messages` to the confirmation view for display as a specific, itemized readiness list (FR-021/FR-022) — rendered even when the list is empty (in which case the modal shows its existing "ready to publish" confirmation, unchanged).

**Turbo_stream fix**: `dashboard/published_articles/update.turbo_stream.erb`'s failure branch changes its `turbo_stream.replace` target from the non-existent `"edit_article_#{@article.id}"` to the real container id `"#{dom_id @article}_edit_form"` (FR-024), so a failed publish attempt actually refreshes the visible form with current article state/errors.

## 4. Live Reader Preview

**Route**: `GET /articles/:uuid/preview` → `articles#preview` (changed from the current unused `POST /articles/preview`, which accepted raw unsaved `params[:content]`). New route replaces the old one; old `preview_article_path` route/action/turbo_stream view (`app/views/articles/preview.turbo_stream.erb`, `_preview.html.erb`) are removed.

**Request**: No body — reads the current, persisted (autosaved) `Article` state by `:uuid`, author-only (`current_user.articles.find_by uuid:`, mirroring `load_article`'s existing pattern).

**Response**: Renders a preview frame/overlay reusing `articles/_full_content` (if `article.free?`) or `articles/_partial_content` (if priced — always the paywall/unlock-card view, regardless of the fact that the viewer is the article's own author, per research item 8) — the same partials the public `articles#show` page renders, guaranteeing visual parity (FR-027/FR-028) by construction. Includes a "Back to editing" affordance that returns to the editor without losing any editor-side unsaved state (edge case: preview never mutates the article).

## 5. Focus Mode

No server contract — pure client-side Stimulus state (`focusModeValue: Boolean` on the `article-form` controller, or a small dedicated Stimulus controller if that keeps `article-form` from growing unwieldy). Toggling adds/removes visibility classes on the top bar and Settings rail DOM already rendered by the server; no additional request is made when entering/exiting.

## 6. Settings panel field-grouping contract (view-layer)

`app/views/articles/_option_fields.html.erb` is restructured into five sub-partials (or five clearly-delimited `<fieldset>` sections within one file, implementation's choice at build time) with these exact groupings, replacing the current single flat list:

1. **Cover & Tags** — `cover` (file upload/preview), `tag_names` (TomSelect).
2. **Pricing & Access** — `price`, `asset_id` (currency), `free_content_ratio`.
3. **Revenue Split** — plain-language summary (default view) + "Advanced" disclosure containing `readers_revenue_ratio`, `author_revenue_ratio`, `references_revenue_ratio` (editable, subject to existing bounds); `platform_revenue_ratio` and `collection_revenue_ratio` always rendered as read-only info (never inside the editable "Advanced" set).
4. **References** — existing nested `article_references` rows (TomSelect + per-row revenue ratio), unchanged mechanics.
5. **Collection** — `collection_id` select.

Each section's fields keep their existing `name`/`id` attributes (`article[price]`, `article[readers_revenue_ratio]`, etc.) so no controller-side param-key changes are needed beyond what's already described in contract §1.
