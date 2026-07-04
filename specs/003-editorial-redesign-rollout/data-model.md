# Phase 1 Data Model: Editorial Redesign Rollout

This feature makes **no database schema changes** — no new tables, columns, or migrations. It introduces exactly one new *derived, generated* artifact (the default cover image), which is stored using an **existing** ActiveStorage attachment slot (`Article#cover`) rather than a new column. Everything else below is the presentation-level shape of already-existing entities, scoped to what the dashboard/editor/modal/home rollout needs to render.

## Generated Default Cover

Not a new model or column — a *derived state* of the existing `Article#cover` ActiveStorage attachment, populated on demand instead of left blank.

| Concept | Source / Storage | Notes |
|---|---|---|
| Trigger condition | `Articles::PosterGenerator#thumb_url` resolves to `nil` under today's logic (no `cover.attached?`, and either the article is paid or no absolute image URL is found in free content) | See `research.md` §3 for the exact priority order this preserves |
| Generated image | Rendered by a new Grover template (`app/views/grover/articles/cover.html.erb`), fetched, and `.attach`ed to the **same** `Article#cover` attachment slot used for author-uploaded covers | No new attachment/column — reuses `has_one_attached :cover` (existing) |
| Seed for determinism/uniqueness | `article.uuid` (existing, stable, unique per article) | Same "hash seed → deterministic color/pattern" concept already used for user avatars (`app/javascript/utils/avatar.js`), reimplemented for a static server-rendered template rather than client-side JS |
| Distinguishing "generated" from "real"? | Not tracked as a separate boolean/flag | Once a real cover is uploaded, `cover.attach` on the same slot simply replaces the generated blob — `cover.attached?` becomes true either way, and the generator is only invoked when it's *absent*, so no extra state is needed to satisfy FR-006 |
| Trigger mechanism | New async job (e.g. `Articles::GenerateDefaultCoverJob`), modeled on the existing `Articles::GeneratePosterJob` | Enqueued lazily the first time `thumb_url` needs the fallback; idempotent (a second enqueue while one is in flight is a no-op once the attachment exists) |

**Validation rules**: None new — the generated cover is a rendering/storage side effect, not a validated user input.

**State transitions**: None new. `cover.attached?` remains a simple boolean; this feature only changes *what* can cause it to become true (author upload, as today, or the new generator) and *when* the generator runs (lazily, on first need).

## Article Preview (dashboard-side listings)

Backing model: `Article` (existing). The dashboard's own article listings (`dashboard/published_articles`, `dashboard/deleted_articles`, `dashboard/subscribe_articles`, etc.) already render article summaries via existing partials; this feature restyles their presentation only — no new fields:

| Field | Source | Notes |
|---|---|---|
| `title`, `intro`, `thumb_url` | `article.title`, `article.intro`, `article.thumb_url` | `thumb_url` now always resolves to a real image per the Generated Default Cover above, simplifying any dashboard-side "no cover" branch that previously had to render an icon placeholder |
| `state` (drafted/published/blocked) | `article.state` (AASM) | Existing status badges restyled to the neutral/soft component treatment from User Story 1, not new states |

## Dashboard Shell

Not a persisted entity — the navigation/layout structure shared by every `Dashboard::` controller.

| Concept | Source | Presentation change |
|---|---|---|
| Sidebar navigation (desktop) | `app/views/shared/_left_bar.html.erb` (existing links/routes) | Colors, typography, icons restyled; structure/links/active-state logic unchanged |
| Mobile top bar / bottom tab bar | `app/views/shared/_navbar.html.erb`, `_tabbar.html.erb` (existing) | Same restyle-only treatment |
| Right-hand widget rail | `app/views/layouts/application.html.erb`'s `<aside>` (existing: join-Quill card for logged-out, `active_authors`/`hot_tags`/footer otherwise) | Restyled to match; structure/content sources unchanged (dashboard users are always logged in, so the join-card branch is dormant here as it is today) |
| Per-page stats/figures (e.g. `dashboard/home/index.html.erb`'s revenue totals) | `current_user.articles_count`, `author_revenue_total_usd`, `reader_revenue_total_usd`, `payment_total_usd` (existing counter caches/aggregates) | Presentation restyle only — figures and their computation are untouched |

## Editor Shell

Not a persisted entity — the layout/chrome surrounding article creation/editing, distinct from both the dashboard shell and the public masthead.

| Concept | Source | Presentation change |
|---|---|---|
| Sticky top bar (logo, word count, last-saved, save/publish actions) | `app/views/articles/_edit_form.html.erb`, `new.html.erb` (existing `article-form` Stimulus target wiring) | Restyled buttons/icons; all `data-action`/`data-*-target` wiring preserved verbatim |
| Title / intro fields | `app/views/articles/_form.html.erb` (`form.text_field :title`, `form.text_area :intro`) | Title field typography moves to `font-display` (headline font), matching how the same title renders elsewhere; field names/params unchanged |
| Content editing surface | `app/views/articles/_content_fields.html.erb` | Typography parity with the public article reader's body copy (`font-sans`/Inter+Noto Sans SC, per the prior redesign's FR-012) |
| Settings panels (price, revenue split, cover, tags, references) | `app/views/articles/_option_fields.html.erb` (271 lines, existing form fields) | Component-level restyle (buttons, inputs, tabs, badges) only; every field/param/validation unchanged |

## Home Landing Content

Not a persisted entity — presentation composition for `home/index.html.erb`.

| Concept | Source | Notes |
|---|---|---|
| Value-proposition copy | New/updated locale strings (`config/locales/views.*.yml`), shown per existing `current_user.blank?` gating | Extends the single-line value prop already present (`home_value_proposition`) into a fuller introductory section |
| Illustrative platform activity (FR-011 in spec's Success Criteria sense — "reflected in some illustrative form") | Existing aggregate data already computed elsewhere in the app (e.g. article/author counts, aggregate `revenue_usd`) — exact figure(s) chosen during implementation | No new aggregation logic required to exist; reuses already-computed counters/sums |
| Curated/featured articles | Revived `HomeController#selected_articles` (`ArticleSearchService.call(filter: "revenue", time_range: "month").limit(6)`, existing) | See `research.md` §7 — inherits the main feed's visibility rules by construction |
| Primary CTAs | Existing routes: `articles_path` (read), `new_article_path`/`login_path` (write/connect wallet, matching the masthead's existing primary action) | No new routes |

## Wallet-Connect / Login Modal

Backing behavior: existing `SessionsController#new`/`auth_mixin_path` OAuth flow (unchanged). Only the rendered markup in `sessions/new.html.erb` and, if needed, small consistency adjustments to the shared `shared/_modal.html.erb` wrapper are in scope — no new fields, params, or state.

## Summary

No entities are added, removed, or altered at the persistence layer. The one genuinely new piece of *behavior* — the generated default cover — is deliberately modeled as a fallback value for an existing attachment (`Article#cover`) rather than a new concept, so every existing consumer of `cover_url`/`thumb_url` (feed cards, OG tags, Mixin bot notification cards, dashboard listings) picks it up automatically with no per-call-site special-casing.
