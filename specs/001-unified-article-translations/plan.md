# Implementation Plan: Cross-Locale Article Visibility

**Branch**: `[001-unified-article-translations]` | **Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-unified-article-translations/spec.md`

## Summary

Remove locale-based filtering on article visibility so every locale user sees every published article. The change is contained to the controller / service / view layers — no schema migration, no data backfill, no commerce-flow changes. The visitor's preferred locale continues to drive only UI chrome (buttons, labels, notification copy); it no longer drives which articles the visitor can see. A small additive change to two view partials (article card, article header) surfaces a language chip so visitors can tell what language they are about to read.

The primary technical work is:
- Delete `ArticleSearchService#localize` and stop passing `locale:` from its two callers.
- Delete `.where(locale: ...)` predicates from `HomeController#hot_tags` and `#active_authors`; change `hot_tags` cache key from per-locale to global.
- Add a language chip to `app/views/articles/_card.html.erb` and a language indicator to `app/views/articles/_header.html.erb`.
- Add new test fixtures (`published_zh`, `published_ja` articles; `author_zh`, `author_ja` users; `tech_zh`, `tech_ja` tags) and new tests asserting cross-locale visibility.

## Technical Context

**Language/Version**: Ruby 4.0.5 (per `.ruby-version`, `mise.toml`)

**Primary Dependencies**: Rails 8.1.x; PostgreSQL; Solid Cable / Cache / Queue; Turbo + Stimulus + Tailwind + esbuild (frontend); Minitest ~> 6.0 (locked to 6.0.6); Ransack (admin filter); CLD gem (locale detection); Action Text (article body); Noticed 3 (notifications)

**Storage**: PostgreSQL. No schema change for this feature.

**Testing**: Minitest + Capybara. Tests live under `test/` mirroring `app/`. Benchmarks (`bin/benchmark`) are stdlib-only and not run in CI.

**Target Platform**: Linux server (Rails monolith) accessed via web browser. Hotwire-driven pages. Mobile web views reuse the same templates as desktop.

**Project Type**: Web application — Rails monolith with namespaced controllers (web, dashboard, admin, api, grover). Per AGENTS.md, this is a single-project layout.

**Performance Goals**: No new performance targets. The change removes one `WHERE locale = ?` predicate per affected query; expected to be neutral or marginally faster on the home feed and home-page widgets. No N+1 introduced.

**Constraints**:
- No new gems; no Gemfile changes.
- No new migrations; no schema changes.
- No new I18n keys required (chip uses existing `article.locale`; chrome stays the same).
- All existing tests must continue to pass (FR-006, US6).
- The revenue distribution test suite must pass unchanged (SC-008).

**Scale/Scope**:
- ~6 controllers touched (`ArticlesController`, `HomeController`, two view partials)
- ~3 service-layer changes (one method removed in `ArticleSearchService`)
- ~4 new test files / sections (`ArticleSearchService` tests, `HomeController` tests, new fixtures)
- Total change: estimated <200 lines of code and <300 lines of test additions.

## Constitution Check

*Gate: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file (`.specify/memory/constitution.md`) is a template-only document (placeholder `[PRINCIPLE_X_NAME]` headings); no project-specific principles are defined. There are no gates to violate.

**Implicit alignment** (carried over from project conventions in `AGENTS.md`):
- Frozen string literals on Ruby files — preserved (no new Ruby files introduced; touched files already comply).
- `# frozen_string_literal: true` — N/A.
- Service objects with `.call` factory — `ArticleSearchService.call` is the existing pattern; we are deleting part of it, not introducing a new service.
- AASM state machines on Article — preserved (no state changes).
- Counter caches on Article — preserved (no counter-cache changes).
- ERB partials under `app/views/**/_*.html.erb` — partials for card and header are the existing pattern.
- Stimulus controllers — not touched.
- Noticed 3 notifiers — not touched.
- Solid Cable / Queue / Cache — `hot_tags` cache key is the only cache change; consistent with existing usage.
- Mixin / MixPay integrations — not touched.
- Test conventions (Minitest, fixtures under `test/fixtures/`) — preserved; new fixtures added.

**Re-evaluation after Phase 1 design**: still no violations. No new patterns introduced; the change is a layer-level simplification that aligns with the existing architecture.

## Project Structure

### Documentation (this feature)

```text
specs/001-unified-article-translations/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── contracts.md     # Phase 1 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
├── spec.md              # /speckit.specify output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

This feature uses the existing single-project Rails layout (`AGENTS.md`). No new directories, no reorganization.

```text
app/
├── controllers/
│   ├── articles_controller.rb                 # MODIFIED: drop `locale: current_locale` from #index
│   ├── home_controller.rb                     # MODIFIED: drop locale filter from hot_tags + active_authors; cache key change; drop `locale:` from selected_articles
│   ├── admin/articles_controller.rb           # UNCHANGED
│   ├── api/articles_controller.rb             # UNCHANGED
│   └── api/base_controller.rb                 # UNCHANGED
├── services/
│   └── article_search_service.rb              # MODIFIED: remove #localize, @locale ivar, .localize call
├── views/
│   └── articles/
│       ├── _card.html.erb                     # MODIFIED: add language chip
│       ├── _header.html.erb                   # MODIFIED: add language indicator
│       ├── _list.html.erb                     # UNCHANGED (consumes _card)
│       └── _related_articles_card.html.erb    # UNCHANGED
├── models/
│   ├── article.rb                             # UNCHANGED (to_param, detected_locale, etc. preserved)
│   └── concerns/
│       └── rich_text_content.rb               # UNCHANGED
├── jobs/articles/
│   └── detect_locale_job.rb                   # UNCHANGED
├── notifiers/
│   ├── application_notifier.rb                # UNCHANGED (chrome wrapping preserved)
│   └── delivery_methods/mixin_bot.rb          # UNCHANGED
└── ...

test/
├── fixtures/
│   ├── articles.yml                           # MODIFIED: add published_zh, published_ja fixtures
│   ├── tags.yml                               # MODIFIED: add tech_zh, tech_ja fixtures
│   └── users.yml                              # MODIFIED: add author_zh, author_ja fixtures
├── services/
│   └── article_search_service_test.rb         # MODIFIED: add cross-locale visibility tests
├── controllers/
│   ├── home_controller_test.rb                # MODIFIED: add hot_tags / active_authors cross-locale tests
│   └── articles_controller_test.rb            # MODIFIED (optional): add cross-locale index test
└── jobs/articles/
    └── detect_locale_job_test.rb              # UNCHANGED

config/
└── routes.rb                                  # UNCHANGED
```

**Structure Decision**: Single-project Rails layout (the existing layout). No new top-level directories. No reorganization. The change adds 4 files (new fixtures and possibly 1 new partial include) and modifies 7 existing files.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. No complexity to justify.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    |            |                                     |

## Touchpoints Summary

For tasks.md (Phase 2), the precise touchpoints are:

| # | File | Lines | Action |
|---|---|---|---|
| 1 | `app/services/article_search_service.rb` | 10, 33, 57-66 | Delete `@locale` ivar; delete `.localize` call; delete `#localize` method |
| 2 | `app/controllers/articles_controller.rb` | 15 | Drop `locale: current_locale` from service call |
| 3 | `app/controllers/home_controller.rb` | 11 | Drop `locale: current_locale` from service call |
| 4 | `app/controllers/home_controller.rb` | 23 | Change cache key from `"#{current_locale}_hot_tags"` to `"hot_tags"` |
| 5 | `app/controllers/home_controller.rb` | 26 | Delete `.where(locale: current_locale.to_s.split("-").first)` |
| 6 | `app/controllers/home_controller.rb` | 37 | Delete `.where(locale: current_locale)` |
| A | `app/views/articles/_card.html.erb` | (insert) | Add language chip |
| B | `app/views/articles/_header.html.erb` | (insert) | Add language indicator |
| C | `test/fixtures/articles.yml` | (append) | Add `published_zh`, `published_ja` |
| D | `test/fixtures/tags.yml` | (append) | Add `tech_zh`, `tech_ja` |
| E | `test/fixtures/users.yml` | (append) | Add `author_zh`, `author_ja` |
| F | `test/services/article_search_service_test.rb` | (append) | Tests for FR-001, FR-002, FR-003 |
| G | `test/controllers/home_controller_test.rb` | (append) | Tests for FR-004, FR-005 |
| H | `test/controllers/articles_controller_test.rb` | (append, optional) | Test for FR-001 / SC-001 |