# Implementation Plan: Comprehensive UI Refactor on the Value-Net Design System

**Branch**: `011-comprehensive-ui-refactor` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-comprehensive-ui-refactor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Build a single, well-maintained design system in `app/views/design_system/` and `app/assets/stylesheets/application.tailwind.css` that absorbs the editorial visual direction already shipped in fragments by `specs/002/003/005/006/010`, then refactor every public, authoring, admin, error, and notification surface in the Rails app to consume that system. Deliver an in-app design-system documentation page that is generated from the same partials the rest of the app uses (no drift), enforce the system with a new RuboCop + Tailwind lint check, and migrate every hand-rolled inline SVG icon, every stray hex color, every duplicated partial into the system. The visual source-of-truth is OpenDesign project `f69be881-fe22-4183-87c7-4cb7179540ff` (brand spec + 8 surface HTMLs); this plan translates those prototypes into Rails.

## Technical Context

**Language/Version**: Ruby 4.0.5 (Rails 8.1.x), Node 20+, Bun 1.x — see `.ruby-version` and `mise.toml`.

**Primary Dependencies**: Rails 8.1.3.1, Tailwind CSS v4.3.2, FlyonUI 2.4.1, Hotwire (Turbo 2.0.23 + Stimulus 3.2.2), Lexxy editor (37signals) for article body, TomSelect 2.6.2 for picker inputs, `@iconify/tailwind4` 1.2.3 with the `@iconify-json/tabler` icon set. Minitest ~> 6.0.6 for tests, RuboCop (rails-omakase) for Ruby lint, Prettier for JS lint.

**Storage**: PostgreSQL — presentational refactor only; no schema migrations expected unless lint data demands them.

**Testing**: Minitest (`bin/rails test`) + Capybara for system tests + a new design-system reachability system test + a new `bin/lint-design-system` script that fails CI on violations.

**Target Platform**: Server-rendered web app on Rails 8.1, runs under Kamal + Docker in production; desktop + mobile web; supports a PWA-style install. Existing browsers: latest 2 versions of Chrome, Safari, Firefox, plus Android Mixin Webview.

**Project Type**: Web application (Rails monolith with Hotwire frontend). Five sub-apps in one repo: public site, dashboard, admin, JSON API, grover.

**Performance Goals**: LCP / INP / CLS on home feed, article reader, article editor no worse than 5% above the pre-refactor baseline (measured with `bin/measure-frontend-efficiency`). Frontend bundle size within ±5% of baseline; design-system reference page renders in ≤ 200ms server-side (it is a Rails page, not an SPA).

**Constraints**: Keep existing FlyonUI radius tokens (`--radius-selector: 1rem`, `--radius-field: 0.5rem`, `--radius-box: 0.75rem`); keep FlyonUI `quill` and `quill-dark` themes as the token layer; do not introduce a new frontend framework; do not fork Lexxy / TomSelect / Photoswipe / Mission Control internals; preserve all existing routes, controllers, models, jobs, notifiers, and Solid Queue semantics; no behavior changes.

**Scale/Scope**: ~150 ERB view files across 5 sub-apps (public, dashboard, editor, admin, API) + 4 error pages + 8 layout files + 21 shared partials + 38 Stimulus controllers. Roughly 50 surfaces to refactor (counting one per controller action), grouped into 4 priorities: design-system foundation (P1) → public surfaces (P2) → authoring surfaces (P3) → admin/API/errors/notifications (P4).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Reference: `.specify/memory/constitution.md` (Quill v1.0.0)

- [x] **I. Code Quality**: This plan extends existing Rails patterns (no parallel implementations). The design system lives under `app/views/design_system/` and `app/views/shared/`, exactly where the existing partials already live; primitives are ERB partials + Stimulus controllers. RuboCop + Prettier cover the touched Ruby + JS. `bundle exec rubocop --no-fix` runs in CI for touched files; `bun run lint-check` runs in CI for touched JS. No secrets in diff (this is a presentational refactor).
- [x] **II. Testing**: A new `test/system/design_system_test.rb` asserts the design-system reference page renders every primitive and every token. A new `test/lib/design_system_lint_test.rb` walks every ERB view + every Stimulus controller and asserts (a) no raw hex outside the token layer, (b) no hand-rolled SVG icons outside the allowlist, (c) no `tag-style-*` classes remain, (d) every interactive element mounts an `i-[tabler--*]` icon where one was previously hand-rolled. Existing controller/model/job/notifier/system tests continue to pass. `bin/rails zeitwerk:check` runs after new constants are added (notably `DesignSystem::Lint`).
- [x] **III. UX Consistency**: Reuses UiHelper (`render_modal`, `render_dropdown`, `ui_input`, `ui_card`) block/slot wrappers before introducing new UI abstractions. New strings go to `config/locales/` (per `AGENTS.md` and Constitution §III). API errors continue to use `API::RenderingHelper` JSON helpers; HTML error pages wrap the existing `errors/not_found` etc. via `render_not_found_page`. Touched partials use semantic HTML, visible focus rings from the new `--ring` token, sufficient contrast.
- [x] **IV. Performance**: Heavy work stays in Solid Queue jobs — this refactor touches no controllers/jobs. The new design-system reference page is server-rendered from existing partials; no N+1 introduced. `bin/measure-frontend-efficiency` is run before and after; regressions >5% trigger a Complexity Tracking entry. The new lint check is opt-in for CI (fail-on-violation) and runs in under 5 seconds on the full repo; its output is cached per file so re-runs are fast.

> No violations.

## Project Structure

### Documentation (this feature)

```text
specs/011-comprehensive-ui-refactor/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── README.md        # Index of design-system contracts
│   ├── tokens.md        # Color, type, spacing, radius contracts
│   ├── primitives.md    # Component contracts (buttons, chips, list row, ...)
│   └── lint-rules.md    # Lint rules enforced by CI
├── quickstart.md        # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/
├── assets/
│   └── stylesheets/
│       ├── application.tailwind.css   # Token layer (existing, extended)
│       └── lexxy_overrides.css        # Unchanged
├── views/
│   ├── design_system/                 # NEW — design-system reference page
│   │   ├── index.html.erb             # In-app, server-rendered reference
│   │   ├── _tokens.html.erb           # Color/type/spacing/radius section
│   │   ├── _type.html.erb
│   │   ├── _buttons.html.erb
│   │   ├── _chips.html.erb
│   │   ├── _list_row.html.erb
│   │   ├── _cards.html.erb
│   │   ├── _forms.html.erb
│   │   ├── _tabs.html.erb
│   │   ├── _modal.html.erb
│   │   ├── _dropdown.html.erb
│   │   ├── _value_net.html.erb
│   │   ├── _notifications.html.erb
│   │   ├── _states.html.erb
│   │   ├── _masthead.html.erb
│   │   └── _page_shell.html.erb
│   ├── shared/                        # EXISTING — primitives consolidated here
│   │   ├── _masthead.html.erb         # Public top-nav (existing)
│   │   ├── _modal.html.erb           # Single source-of-truth modal shell
│   │   ├── _dropdown.html.erb        # Single source-of-truth dropdown shell
│   │   ├── _ui_card.html.erb         # Generic card primitive
│   │   ├── _ui_input.html.erb        # Generic input primitive
│   │   ├── _button.html.erb          # NEW — extracted from .btn-* usage
│   │   ├── _chip.html.erb            # NEW — extracted from .chip-* usage
│   │   ├── _list_row.html.erb        # NEW — Minimal List row
│   │   ├── _value_note.html.erb      # NEW — reward / early-reader text
│   │   ├── _notification_card.html.erb # NEW — notification inbox card
│   │   ├── _skeleton.html.erb        # NEW — loading skeleton primitive
│   │   ├── _state_empty.html.erb     # NEW — empty/error state block
│   │   └── _avatar.html.erb          # Existing, restyled
│   └── errors/                        # EXISTING — restyled to use design system
│       ├── not_found.html.erb
│       ├── not_acceptable.html.erb
│       ├── unprocessable_entity.html.erb
│       └── internal_server_error.html.erb
├── controllers/
│   └── design_system_controller.rb   # NEW — single #show action
└── helpers/
    └── design_system_helper.rb        # NEW — helper for the reference page

lib/
└── design_system/                     # NEW — design-system core
    ├── lint.rb                        # Hex/icon/tag-style scanner
    └── primitives.rb                  # Source-of-truth primitive registry

test/
├── system/
│   └── design_system_test.rb          # NEW — reachability system test
└── lib/
    └── design_system_lint_test.rb     # NEW — runs lib/design_system/lint.rb
```

**Structure Decision**: This is a single Rails monolith with no separate frontend/backend split — Option 1 from the template (single project) is the correct fit. All new code lives inside the existing `app/` + `lib/` + `test/` trees; the only new top-level directory is `app/views/design_system/` for the reference page. No new gems, no new build tools.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | — | — |

## Implementation Strategy

The refactor is large but mechanical. We execute it in **4 sequential phases**, each one independently shippable and independently testable. Every phase ends with `bin/rails test` + `bin/rubocop` + `bun run lint-check` + `bin/rails zeitwerk:check` green, plus a manual screenshot review of the touched surfaces in both light and dark mode.

### Phase A — Design-System Foundation (US1, P1)

Goal: one place to discover every token and every primitive, and a single source-of-truth partial per pattern.

1. **Extend the token layer** in `app/assets/stylesheets/application.tailwind.css`:
   - Add the six OKLCh tokens from the OpenDesign brand-spec as raw CSS custom properties on `:root` and `[data-theme="quill-dark"]` (the brand spec is already aligned with the existing FlyonUI theme tokens; this is a thin restatement, not a replacement).
   - Add the 8pt spacing scale (`--gap-xs/sm/md/lg/xl/2xl`) and container / measure / gutter variables.
   - Add the three font stacks (`--font-display`, `--font-body`, `--font-mono`); already partially declared on the layout — promote to global.
   - Add `--radius: 10px`, `--radius-lg: 14px`, `--radius-full: 999px`.
   - Add `--ring` focus-ring token (cobalt in light, lighter cobalt in dark).

2. **Author the design-system reference page** under `app/views/design_system/`:
   - `DesignSystemController#show` (single action; not namespaced under any sub-app, but mounted at `/design-system`).
   - One partial per primitive, each rendering the primitive inside a labeled `<section>` with a "Source" link to the partial file.
   - The reference page itself is server-rendered; it pulls in the actual partials from `app/views/shared/` and the actual token values from the stylesheet. It is the same code path the app uses; there is no separate "design tool" version.

3. **Consolidate the partials** under `app/views/shared/`:
   - Extract `shared/_button.html.erb` (and a `render_button` helper in `UiHelper`) to wrap the most common `.btn.btn-primary` / `.btn.btn-soft` / `.btn.btn-ghost` patterns with semantic locals (`variant:`, `size:`, `icon:`, `label:`).
   - Extract `shared/_chip.html.erb` for the `tag-chip` / price-pill / status-pill patterns.
   - Extract `shared/_list_row.html.erb` for the Minimal List row used by feed / search / author-profile / collection.
   - Extract `shared/_notification_card.html.erb` for the notification inbox row (used by `app/views/dashboard/notifications/_notification.html.erb` and the toast slot).
   - Extract `shared/_value_note.html.erb` for the muted-amber "early reader +18%" / "earnings: $X" text element (text-only; never a badge, per brand spec).
   - Extract `shared/_skeleton.html.erb` for loading placeholders (already partially done by `app/views/shared/_loading.html.erb`; promote to a generic skeleton primitive with width/height/rounded variants).
   - Extract `shared/_state_empty.html.erb` for the centered empty-state pattern (supersede `_empty.html.erb`).

4. **Add `DesignSystem::Lint`** (`lib/design_system/lint.rb`):
   - Single class method `Lint.run(root_path = Rails.root)` returns an array of violations.
   - Walks every `app/views/**/*.erb`, `app/javascript/**/*.js`, `app/helpers/**/*.rb`, and `app/assets/stylesheets/**/*.css`.
   - Flags: raw hex colors outside the token layer; hand-rolled `<svg>` icons in views (allowlist: `articles/_card_cover.html.erb` procedural cover art + `app/javascript/utils/notify.js` toast icons for now, migrate to `i-[tabler--*]` if not in allowlist); `tag-style-0..5` remnants; `@apply` chains referencing deprecated tokens.
   - Wired into CI via `bin/lint-design-system` shell script; mirrors `bin/rubocop` invocation style.
   - Exit code 1 on any violation; exit code 0 otherwise. Output is one violation per line, file:line prefixed.

5. **Add `app/helpers/design_system_helper.rb`** with `render_design_system_section(title:, &block)` and any other section-rendering helpers the reference page needs.

### Phase B — Public Surfaces (US2, P2)

Goal: every public page consumes the design system exclusively; no per-view bespoke styling; first-class dark mode everywhere.

1. **Home (`app/views/home/`)**: refactor `index.html.erb` to use the new `render_button`/`render_chip` helpers, the new `_list_row` partial, the value-note primitive; replace the remaining raw hex references in `home/stats` (none expected, but lint will catch them).
2. **Article reader (`app/views/articles/show.html.erb` + its 19 partials)**: migrate the paywall fade, the floating bar, the buy/reward buttons, the comments card, the related-articles card, the share-button group, the author byline card to design-system primitives.
3. **Search (`app/views/search/`)**: replace the bespoke dropdown with the standard `_dropdown` partial and the standard `_list_row`; ensure the search input uses `ui_input`.
4. **Author profile (`app/views/users/show.html.erb` + `_user_card` + `users/articles/`)**: use `_list_row` for the article list; use a new `_profile_header` partial that consumes the avatar + bio + follow CTA primitives.
5. **Collection (`app/views/collections/show.html.erb` + `collections/articles/`)**: replace its bespoke row with `_list_row`; replace its share/CTA buttons with `render_button`.
6. **Static pages (`app/views/pages/fair.html.erb`, `rules.html.erb`)**: ensure markdown rendering wraps in the design system (new `content-prose` utility derived from the typography stack).
7. **Login / connect-wallet modal**: rewrite the trigger inside `_masthead` and the modal opened from any public page to use the standard `_modal` partial and the design-system button primitives.
8. **Error pages (`app/views/errors/*.html.erb`)**: rewrite each of `not_found`, `not_acceptable`, `unprocessable_entity`, `internal_server_error` to use the design-system headline + body + CTA primitives; ensure the `render_not_found_page` controller helper targets the new template unchanged.

### Phase C — Authoring Surfaces (US3, P3)

1. **Dashboard layout (`app/views/layouts/application.html.erb`)**: keep the existing two-column shell (left rail + center) but restyle the rail, the mobile tabbar, the right rail (if present) to use design-system primitives. Right rail opt-in only (`content_for(:sidebar)`).
2. **Dashboard overview (`app/views/dashboard/home/`)**: rewrite `index`, `account`, `finances`, `read`, `write` to use the new stat-card primitive, the value-note primitive, the list-row primitive.
3. **Article editor (`app/views/articles/{new,edit,preview}.html.erb` + `_form.html.erb` + `_content_fields.html.erb` + `_option_fields.html.erb`)**: refactor the toolbar chrome (Lexxy internals untouched) to use design-system buttons and inputs; refactor the cover picker, tags input (TomSelect chrome only), pricing/currency controls, reward-split calculator to use the new primitives.
4. **Dashboard settings (`dashboard/notifications`, `notification_settings`, `profile_settings`, `access_tokens`, `block_users`)**: use design-system primitives.
6. **Dashboard tables (`dashboard/orders`, `payments`, `transfers`, `articles`, `collections`, `comments`, `subscribe_*`, `subscriptions`)**: introduce a new `_table.html.erb` primitive (a generic data table using design-system tokens) and migrate every existing dashboard table to use it; preserve column semantics.

### Phase D — Admin, API, Errors, Notifications (US4, P4)

1. **Admin layout (`app/views/layouts/admin.html.erb`)**: rewrite to use design-system primitives; remove the bespoke admin styling; reuse `_masthead` or a new `_admin_nav` derived from it.
2. **Admin login (`app/views/admin/login/new.html.erb`)**: rewrite the self-contained form to use design-system primitives.
3. **Admin tables and forms (`app/views/admin/**`)**: use the new `_table` and the standard form primitives.
4. **API error HTML (`app/controllers/concerns/rendering_helper.rb` + `errors/*`)**: HTML error pages already covered in Phase B. The JSON `render_*` helpers in `app/controllers/concerns/api/rendering_helper.rb` continue to emit JSON; no changes needed.
5. **Notification inbox (`app/views/dashboard/notifications/`)**: use the new `_notification_card` primitive for both the inbox row and the real-time toast; ensure `app/javascript/utils/notify.js` toast icons migrate to `i-[tabler--alert-circle]`, `i-[tabler--alert-triangle]`, `i-[tabler--circle-check]`, `i-[tabler--x]` (the same primitives used by the design-system state section).

### Phase E — Verification & Hardening

1. Run `bin/measure-frontend-efficiency` before and after each phase; commit the diff to `specs/011-comprehensive-ui-refactor/perf.md`.
2. Run `bin/rubocop`, `bun run lint-check`, `bin/rails zeitwerk:check`, `bin/rails test`, `bin/lint-design-system` — all green.
3. Manual screenshot review of every touched surface in both light and dark mode; record in the PR description.
4. Update `CHANGELOG.md` and the `AGENTS.md` "Code Conventions" section to point at the new design-system entry point.

## Files Touched (estimated)

| Area | Files added | Files modified | Files removed |
|---|---|---|---|
| Design system (Phase A) | 16 (controller + helper + 14 partials) + 3 (lib + 2 tests) | 1 (stylesheet) | 0 |
| Public surfaces (Phase B) | 1 (`_profile_header`) | ~25 | 0 |
| Authoring surfaces (Phase C) | 1 (`_table`) | ~30 | 0 |
| Admin/API/errors/notifications (Phase D) | 0 | ~15 | 0 |
| Documentation / lint | 4 (research, plan, quickstart, contracts) + 1 (CI script) | 2 (`AGENTS.md`, `CHANGELOG.md`) | 0 |
| **Totals** | ~22 | ~73 | 0 |

These are estimates; exact counts emerge from `/speckit.tasks`.

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Frontend bundle size grows beyond the 5% budget. | Phase A introduces one extra stylesheet (already cached). Phases B–D only consolidate; no new deps. If budget is exceeded, defer the inline cover-art procedural SVG in `articles/_card_cover.html.erb` to a later pass (it is in the lint allowlist). |
| Dark mode regresses on previously-untouched surfaces (error pages, admin). | Phase D explicitly covers both. Manual screenshot review is a hard gate before merge. |
| Lexxy editor internals leak custom colors into the redesigned chrome. | Limit Phase C to the chrome around Lexxy (toolbar buttons, cover picker, tags input, pricing controls). Do not edit `app/assets/stylesheets/lexxy_overrides.css`; extend it only with new editor-specific overrides if necessary. |
| Existing dashboard tables regress in density after the new `_table` primitive. | Phase C preserves the existing column semantics and styling density; the new `_table` is a thin wrapper, not a redesign. |
| `bin/lint-design-system` produces noise during the refactor (every phase temporarily introduces new violations before the migration completes). | The script accepts `--phase <a\|b\|c\|d>` to limit the lint scope to a phase, and exits 0 for the current phase + exits 1 for violations on already-completed phases. CI runs the full check; local dev runs the phased check. |
| OpenDesign project is removed or restructured mid-refactor. | The visual source-of-truth is committed to the repo as a one-time copy under `docs/superpowers/specs/opendesign-011/` (HTML + CSS + brand-spec). The OpenDesign project remains the live reference for future iterations but is not required for this refactor to complete. |