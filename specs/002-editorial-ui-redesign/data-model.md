# Phase 1 Data Model: Editorial Web3 UI Redesign

This feature makes **no database schema changes** — no new tables, columns, or migrations. Every entity below already exists as an ActiveRecord model; this document describes the **presentation-level shape** each redesigned view/partial consumes, derived from the feature spec's Key Entities section, so the tasks phase knows exactly which existing attributes to render and where.

## Article Preview (row shown in feed / profile / collection / search)

Backing model: `Article` (existing, `app/models/article.rb`). No new attributes needed — all fields below already exist on the model or its associations.

| Field | Source | Notes |
|---|---|---|
| `title` | `article.title` | Rendered in headline typeface (serif) |
| `intro` | `article.intro` | One-line excerpt, sans typeface, truncated (existing `line-clamp-3` → tighten to match "Minimal List" density) |
| `author` | `article.author` (`User`) | Renders avatar (`shared/_avatar`), name, `users/_user_uid` |
| `published_at` | `article.published_at` | Relative/short date via existing `render_time_format` |
| `thumb_url` | `article.thumb_url` | Small square thumbnail; falls back to a neutral placeholder when blank (Edge Case) |
| `free?` / `price_tag` / `currency` | `article.free?`, `article.price_tag`, `article.currency` | Drives the price/free badge (FR-003) |
| `revenue_usd` | `article.revenue_usd` | Aggregate early-reader reward/revenue indicator (FR-004) — **not personalized**, see `research.md` |
| `tags` | `article.tags` (first N) | Neutral chip style, replacing per-category color (FR-005) |
| `locale` | `article.locale` | Existing language badge, unaffected by this feature |
| `comments_count`, `upvote_ratio` | `article.comments_count`, `article.upvote_ratio` | Existing secondary meta, kept but restyled |

**Validation rules**: None new — this is read-only presentation of already-validated data.

**State transitions**: None new. The existing `free?` / paid / locked distinction (via `article.authorized?(current_user)`, referenced in `ArticlesController#show`) continues to drive whether the paywall fade (see below) renders.

## Locked Article Content (paywall fade boundary)

Not a persisted entity — a rendering-time concept derived from `Article#free_content_ratio` / the point at which `article.authorized?(current_user)` becomes false within the rendered content. The redesign changes only how that boundary is *presented* (FR-006):

| Concept | Source | Presentation change |
|---|---|---|
| Free preview content | Existing content-splitting logic (unchanged) | Last visible block gets a CSS gradient mask (see `research.md`) instead of a hard cutoff |
| Unlock action | `articles/_buy_article_button.html.erb` (existing) | Becomes a compact, sticky control instead of a sidebar card (FR-007) |

## Author Profile (public-facing)

Backing model: `User` (existing). Only a subset of existing counter-cache fields is surfaced publicly, per FR-008:

| Field | Source | Publicly shown? |
|---|---|---|
| `name`, `bio`, avatar | `user.name`, `user.bio`, `shared/_avatar` | ✅ |
| `articles_count` | `user.articles_count` (existing counter cache) | ✅ — satisfies "article count" |
| `subscribers_count` | `user.subscribers_count` (existing counter cache — readers following this author) | ✅ — satisfies "total reader count" |
| `created_at` | `user.created_at` | ✅ — satisfies "join date" (not currently rendered on `_user_card`; **new** display of an existing field, no schema change) |
| Earnings / wallet balance / on-chain transaction history | N/A — not currently rendered on the public profile either | ❌ — confirmed absent today; FR-008 formalizes keeping it that way |

**Validation rules**: None new.

**State transitions**: None.

## Collection (curated grouping)

Backing model: `Collection` (existing). No new attributes:

| Field | Source |
|---|---|
| `name`, `description` | `collection.name`, `collection.description` (rendered via existing `MarkdownRenderService`) |
| `author` (curator) | `collection.author` |
| Member articles | `collection.articles`, rendered via the same redesigned Article Preview row |

## Summary

No entities are added, removed, or altered at the persistence layer. This document exists to pin down exactly which existing fields the redesigned views must render (and, for `User#created_at`, surface for the first time on the public profile) so `tasks.md` can generate concrete, scoped tasks without re-deriving this from the models during implementation.
