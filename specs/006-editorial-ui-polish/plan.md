# Implementation Plan: Editorial UI Polish Pass

**Branch**: `006-editorial-ui-polish` | **Date**: 2026-07-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-editorial-ui-polish/spec.md`

## Summary

Close the remaining quality gaps after `002`/`003` editorial rollout: polish the shared modal and dropdown shells, migrate all remaining hand-rolled SVG icons to Tabler (`i-[tabler--*]`), unify article interaction components (votes, share, comments, subscribe), elevate secondary modal contents, sweep styling debt (`btn-ghost`, hardcoded hex colors), and verify dark-mode/accessibility. Presentation-only — no routes, models, or business logic changes.

## Technical Context

**Language/Version**: Ruby 4.0.5, Rails 8.1.x  
**Primary Dependencies**: FlyonUI (Tailwind v4 plugin), `@iconify/tailwind4` (prefix `i`), Hotwire (Turbo + Stimulus), ERB partials, `UiHelper`  
**Storage**: N/A (no schema changes)  
**Testing**: Minitest — existing suite must pass; grep audit for SC-002–SC-005  
**Target Platform**: Web (desktop + mobile browsers)  
**Project Type**: Rails monolith — view-layer polish  
**Performance Goals**: No hot-path impact; icon utilities are CSS-only  
**Constraints**: Admin panel untouched; no dashboard IA changes (`005`); preserve all Stimulus/Turbo wiring  
**Scale/Scope**: ~25 ERB files across shared partials, article interactions, secondary modals, editor toolbar, static pages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

- [x] **I. Code Quality**: Extends existing partials/helpers; no parallel UI framework; RuboCop/Prettier on touched files
- [x] **II. Testing**: Presentation-only — existing suite + grep audit; no new model/controller behavior
- [x] **III. UX Consistency**: Reuses `UiHelper`, FlyonUI tokens, Tabler icons, i18n for any new copy
- [x] **IV. Performance**: No DB/job changes; lean CSS icon utilities only

> No violations — Complexity Tracking table empty.

## Project Structure

### Documentation (this feature)

```text
specs/006-editorial-ui-polish/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/component-contracts.md
└── checklists/requirements.md
```

### Source Code (touch list)

```text
app/views/shared/_modal.html.erb          # P1: modal shell polish
app/views/shared/_dropdown.html.erb       # P1: dropdown shell polish
app/views/shared/_share_options.html.erb  # P2/P3: icons + copy
app/views/shared/_nav_icon_link.html.erb  # P2: dead partial migration
app/views/flashes/_alert_content.html.erb # P5: icon prefix fix
app/views/articles/_votes.html.erb        # P2/P3
app/views/articles/_share_button.html.erb
app/views/articles/_updated_at.html.erb
app/views/articles/_edit_form.html.erb    # P5: btn-ghost → btn-soft
app/views/articles/new.html.erb
app/views/articles/preview.html.erb
app/views/comments/_actions.html.erb      # P2/P3
app/views/subscribe_users/_subscribe_button.html.erb
app/views/subscribe_tags/_subscribe_button.html.erb
app/views/pre_orders/_form.html.erb       # P4
app/views/pre_orders/_payment.html.erb    # P5: font-serif → font-display
app/views/block_users/new.html.erb        # P1/P4
app/views/pages/fair.html.erb             # P2
app/views/pages/rules.html.erb
```

**Structure Decision**: Single Rails monolith; all changes under `app/views/` (presentation layer).

## Complexity Tracking

> Empty — no constitution violations.

## Phase 0 Output

See [research.md](./research.md) — icon prefix, Tabler mappings, modal approach, hex→token table, admin boundary.

## Phase 1 Output

- [data-model.md](./data-model.md) — view-layer component entities
- [contracts/component-contracts.md](./contracts/component-contracts.md) — partial preservation contracts
- [quickstart.md](./quickstart.md) — validation guide

**Note on agent-context sync**: Skipped — `.specify/scripts/bash/` has no `update-agent-context.sh` (same as prior specs).

## Implementation Order

1. **P1** Shared `_modal` + `_dropdown` shells; block-user modal content
2. **P2** Icon migration (`inline_svg_tag` → `i-[tabler--*]`); fix `icon-[tabler` → `i-[tabler`
3. **P3** Article interaction layout polish (votes, comments, share, subscribe)
4. **P4** Secondary modal contents (pre-order form tokens/typography)
5. **P5** Editor `btn-ghost` sweep, flash alerts, `font-serif` leftovers
6. **P6** Manual dark-mode + keyboard QA per quickstart
