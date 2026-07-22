# Implementation Plan: Article Editor Progressive Disclosure

**Branch**: `010-editor-progressive-disclosure` | **Date**: 2026-07-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-editor-progressive-disclosure/spec.md`

## Summary

Transform the article editor from a 12-field cluttered surface into a distraction-free writing experience using progressive disclosure. When an author opens the editor, they see only title, intro, and content. All configuration (cover, tags, pricing, revenue splits, references, collection) hides behind a Settings affordance and advanced-section gates. Pricing becomes USD-first with crypto shown secondary. Key bugs are fixed: intro auto-resize (missing controller), save-conflict resolution (no silent data loss), consistent price formatting, scoped tag suggestions, and disclosure toggle state indicators. The data model, revenue-split math, autosave infrastructure, and publish pipeline are unchanged — this is a presentation/interaction-layer refactoring.

## Technical Context

**Language/Version**: Ruby 4.0.5 (`.ruby-version`, `mise.toml`)

**Primary Dependencies**: Rails 8.1, Hotwire (Turbo + Stimulus), Tailwind CSS, esbuild, `@37signals/lexxy` (rich-text editor), TomSelect (tag/reference pickers), FlyonUI (modals), `@rails/request.js` (autosave fetch), Noticed 3 (notifications — unchanged)

**Storage**: PostgreSQL (article columns unchanged — no migrations); ActionText rich text (content field unchanged)

**Testing**: Minitest + Capybara; `bin/rails test`, `bin/rails zeitwerk:check`

**Target Platform**: Web (Rails monolith), desktop + mobile responsive

**Project Type**: web-service (Rails monolith with Hotwire)

**Performance Goals**: Editor first-paint < 2s (no new blocking assets); autosave debounce stays at 1s; no new DB queries on the editor path beyond existing

**Constraints**: No regression to autosave, optimistic-locking, draft-recovery, or publish-notification behavior. Revenue-split math must remain exactly as-is (sum to 1.0). No new migrations. Touched Ruby must pass `bin/rubocop`; touched JS must pass `bun run lint-check`.

**Scale/Scope**: ~5 ERB partials refactored (`articles/_form`, `articles/_option_fields`, `articles/_edit_form`, `articles/new`, `article_references/_form`); 2 Stimulus controllers extended (`article_form_controller.js`, `article_revenue_controller.js`); 1 Stimulus controller created (`textarea_controller.js`); 1 controller action refined (`ArticlesController#update` conflict path); ~6 locale keys added. No model, job, or service changes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Reference: `.specify/memory/constitution.md` (Quill v1.0.0)

- [x] **I. Code Quality**: Extends existing `article_form_controller.js` and `article_revenue_controller.js` (no parallel implementations); reuses ERB partials and `UiHelper` wrappers; new `textarea_controller.js` follows existing Stimulus conventions; RuboCop/Prettier will pass for touched files; no secrets in diff.
- [x] **II. Testing**: Test scope defined — conflict resolution (controller + integration), intro auto-resize (system/JS), progressive disclosure visibility (system), USD price formatting consistency (controller helper unit), tag suggestion scoping (controller unit). `bin/rails test` and `zeitwerk:check` will run; no new constants that break autoloading.
- [x] **III. UX Consistency**: Reuses Turbo Streams (existing `update.turbo_stream.erb` pattern), Stimulus targets/actions, Tailwind utilities, and ERB partials. New strings go into `config/locales/articles.*.yml`. Disclosure toggles use existing button + `hidden` class pattern. No API surface changed.
- [x] **IV. Performance**: Editor is an authoring path, not a read hot-path (article discovery/search/checkout/distribution). No search/order/transfer logic touched → `bin/benchmark` not required. No new blocking assets. Autosave debounce unchanged (1s). No N+1 introduced — tag scoping reuses existing `Tag` queries with `.order`/`.joins`.

> No violations. No Complexity Tracking entries needed.

## Project Structure

### Documentation (this feature)

```text
specs/010-editor-progressive-disclosure/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── editor-ui-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── articles_controller.rb          # Refine #update conflict path (409 resolution)
├── javascript/controllers/
│   ├── article_form_controller.js      # Extend: settings-rail default-hidden, conflict modal, USD price
│   ├── article_revenue_controller.js   # Extend: disclosure state indicators, default-hidden section
│   └── textarea_controller.js          # NEW: auto-resize (fixes B1 dead reference)
├── views/
│   ├── articles/
│   │   ├── new.html.erb                # Refactor: settings rail hidden by default
│   │   ├── _edit_form.html.erb         # Refactor: settings rail hidden by default
│   │   ├── _form.html.erb              # Refactor: fix textarea controller ref, settings gate
│   │   ├── _option_fields.html.erb     # Refactor: USD-first pricing, default-hidden revenue, scoped tags
│   │   ├── _conflict_resolution.html.erb # NEW: 409 conflict resolution modal/banner
│   │   └── update_conflict.turbo_stream.erb # Extend: render conflict resolution UI
│   └── article_references/
│       └── _form.html.erb              # Refactor: remove dead touchDirty dispatch (B4)
└── config/locales/ (via config/)
    └── articles.en.yml                 # Add i18n keys for new UI strings

test/
├── controllers/articles_controller_test.rb  # Conflict resolution, tag scoping
├── system/article_editor_test.rb            # Progressive disclosure, intro resize, conflict flow
└── helpers/ (or application_helper_test.rb) # USD price formatting consistency
```

**Structure Decision**: Single monolith — no new directories. All changes extend existing `app/controllers`, `app/javascript/controllers`, `app/views/articles`, and `config/locales`. One new Stimulus controller (`textarea_controller.js`) and one new partial (`_conflict_resolution.html.erb`) follow existing naming conventions. No new models, jobs, services, or migrations.

## Complexity Tracking

> No Constitution Check violations. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
