# Implementation Plan: Stale Transfer Management

**Branch**: `009-stale-transfer-management` | **Date**: 2026-07-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-stale-transfer-management/spec.md`

## Summary

Allow administrators to mark unprocessed Mixin Network transfers as "stale," removing them from the automated processing queue (`process_pending!` and the monitor job). Stale transfers are excluded from recurring retries, can be filtered independently in the admin list, and can be reactivated if needed. An audit trail records which admin performed the action and when.

## Technical Context

**Language/Version**: Ruby 4.0.5

**Primary Dependencies**: Rails 8.1.x, Hotwire (Turbo + Stimulus), Tailwind CSS, PostgreSQL, Solid Queue

**Storage**: PostgreSQL (primary database, table `transfers`)

**Testing**: Minitest with fixtures; `bin/rails test`

**Target Platform**: Linux server (Kamal/Docker deploy)

**Project Type**: Rails monolith — admin-facing web feature

**Performance Goals**: `process_pending!` queries must not regress; stale filter on index page within standard admin pagy limits (50/page)

**Constraints**: Must follow existing admin UI patterns (Turbo Stream updates, Tailwind badges, existing controller structure); no new JS frameworks or CSS approaches

**Scale/Scope**: Thousands of stale transfers; admin index with existing infinite scroll pagination

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Reference: `.specify/memory/constitution.md` (Quill v1.0.0)

- [x] **I. Code Quality**: Extends existing `Transfer` model, `Admin::TransfersController`, and existing admin partials. No parallel implementations or new abstractions. All Ruby files include `# frozen_string_literal: true`. No secrets in diff.
- [x] **II. Testing**: Tests will cover model scope changes (`unprocessed` excluding stale), controller actions (`stale`/`reactivate` Turbo Stream responses), and guard conditions (processed transfers cannot be staled). `bin/rails test` and `zeitwerk:check` will be verified.
- [x] **III. UX Consistency**: Reuses existing admin table partial (`_transfer.html.erb`), same Turbo Stream pattern as `process_now`, Tailwind badge classes, and existing filter form (`_query.html.erb`). New UI strings use locale files. No new Stimulus controllers needed.
- [x] **IV. Performance**: Adding `WHERE stale_at IS NULL` to `unprocessed` scope — a composite index on `(processed_at, stale_at)` will maintain query performance. `process_pending!` uses `unprocessed` scope directly, so no separate hot-path changes needed. Admin list filter is bounded by pagy.

### Post-Design Re-Evaluation (Phase 1 Complete)

- [x] **I. Code Quality**: No deviations. Implementation plan extends only existing classes and follows established patterns. Migration is standard (two columns + one index). No new abstractions introduced.
- [x] **II. Testing**: Test plan covers model scopes (`unprocessed` exclusion, `stale` scope), guard methods (`stale!`, `reactivate!`), controller actions (Turbo Stream responses), and admin filter behavior. `zeitwerk:check` passes — no new constants.
- [x] **III. UX Consistency**: Reuses `_transfer.html.erb` partial, Turbo Stream row replacement pattern (`process_now` precedent), Tailwind badge classes, existing `_query.html.erb` filter form. New locale file `config/locales/admin.en.yml`. No new Stimulus controllers or JS changes.
- [x] **IV. Performance**: Composite index `(processed_at, stale_at)` ensures `unprocessed` scope query remains index-only. `process_pending!` runs every minute — the added `WHERE stale_at IS NULL` condition is covered by the composite index and adds negligible overhead. Admin list pagination is bounded by pagy (50/page). No benchmark regression expected for the transfer processing path.

> Record any violations in **Complexity Tracking** below with rejected simpler alternatives.

## Project Structure

### Documentation (this feature)

```text
specs/009-stale-transfer-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── admin-api.md     # Admin transfer actions contract
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/
├── models/
│   └── transfer.rb                  # + stale_at, staled_by_id, stale/unstale scopes
├── controllers/admin/
│   └── transfers_controller.rb      # + stale, reactivate actions, stale filter
├── views/admin/transfers/
│   ├── _transfer.html.erb            # + stale badge rendering
│   ├── _query.html.erb               # + Stale option in state select
│   ├── show.html.erb                 # + stale state display
│   ├── stale.turbo_stream.erb        # NEW
│   └── reactivate.turbo_stream.erb   # NEW
├── jobs/transfers/
│   └── process_pending_job.rb       # unchanged (uses Transfer.unprocessed)
db/
├── migrate/
│   └── *_add_stale_fields_to_transfers.rb  # NEW
config/
├── locales/
│   └── admin.en.yml                 # + transfer state strings
└── routes/admin.rb                  # + stale/reactivate member routes
test/
├── models/
│   └── transfer_test.rb             # + scope & guard tests
└── controllers/admin/
    └── transfers_controller_test.rb # + stale/reactivate action tests
```

**Structure Decision**: Single Rails monolith project. Feature touches only the `app/`, `db/`, `config/`, and `test/` directories listed above. No new top-level modules or engines.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations.
