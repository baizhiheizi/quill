# Research: Comprehensive UI Refactor

> Phase 0 of `/speckit.plan`. Resolves every `NEEDS CLARIFICATION` from the Technical Context, captures best practices for the chosen stack, and records decisions + alternatives for downstream `tasks.md` to consume.

## Inputs

- Spec: `specs/011-comprehensive-ui-refactor/spec.md`
- Plan: `specs/011-comprehensive-ui-refactor/plan.md`
- Visual source-of-truth: OpenDesign project `f69be881-fe22-4183-87c7-4cb7179540ff` ("Quill 界面重设计规划") — `brand-spec.md` + `assets/style.css` + 8 HTML prototypes (`index.html`, `feed.html`, `search.html`, `author-profile.html`, `collection.html`, `reader.html`, `editor.html`, `dashboard.html`, `components.html`).
- Approved visual direction: `docs/superpowers/specs/2026-07-03-ui-redesign-design.md`.
- Constitution: `.specify/memory/constitution.md` (Quill v1.0.0).
- Prior specs to absorb (not preserve in parallel): `002-editorial-ui-redesign`, `003-editorial-redesign-rollout`, `005-dashboard-ux-redesign`, `006-editorial-ui-polish`, `010-editor-progressive-disclosure`.
- Inventory: see `plan.md` §"Files Touched" — 50+ surfaces across 5 sub-apps.

## Unknowns & Resolutions

### U1 — How should the design-system reference page be served?

**Decision**: Mounted as a single Rails controller `DesignSystemController#show` at `/design-system`, wrapped in a layout that uses the same `application.html.erb` chrome (so the reference page renders in the dashboard layout by default for logged-in developers, with a public-layout variant for logged-out visitors). No new frontend framework.

**Rationale**: The reference page is itself a Quill view; it must consume the same partials the rest of the app consumes. A separate Storybook/MDX pipeline would introduce a parallel source-of-truth and drift — exactly what the spec forbids.

**Alternatives considered**:
- *Storybook* — out; new toolchain, new build pipeline, drift risk.
- *Static MDX site* — out; loses the "live partial" guarantee.
- *In-repo Rails controller* — chosen. The reference page is a Rails view; the cheapest way to render real partials is to render real partials.

### U2 — What CSS-in-Tailwind mechanism do we use for new primitives?

**Decision**: Tailwind v4 `@utility` (already supported; one example `tag-chip` already exists in `application.tailwind.css`) for primitive utility classes that mirror the brand-spec tokens. No `@apply` chains that re-define tokens; all color/typography references go through Tailwind theme tokens (`bg-base-200`, `text-base-content`, `text-reward`) or the new `:root` CSS custom properties (`--ring`, `--gap-md`, etc.).

**Rationale**: Tailwind v4 utilities are the documented mechanism in `app/assets/stylesheets/application.tailwind.css`; `@apply` chains are already in use; promoting the brand-spec tokens into `@theme` keeps them discoverable in the IDE while still being CSS variables for the few cases where `@apply` is needed.

**Alternatives considered**:
- *BEM-style hand-rolled CSS* — out; harder to lint for token compliance.
- *CSS Modules* — out; Rails asset pipeline does not support them natively.
- *Tailwind utilities + `@theme` tokens* — chosen.

### U3 — How do we enforce the design system in CI?

**Decision**: A new `bin/lint-design-system` shell script that invokes `DesignSystem::Lint.run(Rails.root)`. Lives next to `bin/rubocop` and `bun run lint-check`; same exit-code semantics; emits one violation per line as `file:line: rule: message`.

**Rationale**: The existing quality gates (`bin/rubocop`, `bun run lint-check`, `bin/rails zeitwerk:check`) are bash scripts invoking a tool. A fourth bash script invoking a Ruby tool fits the pattern exactly. No new gem is needed because the rules are domain-specific.

**Alternatives considered**:
- *RuboCop custom cops* — possible but requires a gem; the rules are not general Ruby style.
- *Stylelint* — adds JS toolchain complexity; the rules must read ERB, not just CSS.
- *Custom Ruby tool, in-tree* — chosen.

### U4 — Which Rails layout owns the dashboard right rail?

**Decision**: Keep `content_for(:sidebar)` opt-in. No dashboard view currently uses it; the design system does not add a default right rail. Pages that need extra panels (e.g. a future "drafts" sidebar) opt in via `content_for(:sidebar)` and get a 20rem right rail with the same styling the public surface uses.

**Rationale**: The dashboard benefits from width (research surface, stat cards, table); a default right rail reclaims width and reduces density. Pages that explicitly want it can still get it.

**Alternatives considered**:
- *Always-on right rail* — rejected: density regression on the most common dashboard views.
- *Always-off right rail* — current state; kept.
- *Opt-in right rail* — chosen.

### U5 — How do we migrate the inline SVG toast icons in `app/javascript/utils/notify.js`?

**Decision**: Replace the 8 hand-rolled SVG strings with `i-[tabler--alert-circle]`, `i-[tabler--alert-triangle]`, `i-[tabler--circle-check]`, `i-[tabler--x]` rendered by Stimulus. The toast component already drives its own DOM; the SVG is the only hand-rolled piece. Keep the procedural cover-art generator (`articles/_card_cover.html.erb`) in the lint allowlist — it draws circles/ellipses/rects, not icons.

**Rationale**: Tabler already provides the exact four symbols the toast uses; migrating removes one of the last hand-rolled SVG sources and aligns with the spec's "every icon is rendered via `i-tabler-*`" rule.

**Alternatives considered**:
- *Inline SVG strings via ERB partial* — out: Stimulus components can't render ERB.
- *Hand-rolled SVG kept, added to allowlist* — out: spec mandates migration.
- *Tabler classes via Stimulus* — chosen.

### U6 — How do we preserve existing FlyonUI radius tokens while adding the brand-spec radii?

**Decision**: Keep the existing `--radius-selector: 1rem`, `--radius-field: 0.5rem`, `--radius-box: 0.75rem` declared inside the `@plugin 'flyonui/theme'` blocks (these are consumed by the FlyonUI component library and changing them breaks FlyonUI). Add the brand-spec radii (`--radius: 10px`, `--radius-lg: 14px`, `--radius-full: 999px`) at the `:root` level for use by our own primitives. Both coexist; nothing aliases one to the other.

**Rationale**: FlyonUI components use the three selector/field/box radii internally; the brand-spec radii are a separate scale for buttons, chips, cards. They serve different audiences.

**Alternatives considered**:
- *Re-alias FlyonUI radii to brand-spec values* — out: would silently change FlyonUI component shape.
- *Keep only brand-spec, drop FlyonUI radii* — out: breaks FlyonUI internals.
- *Both coexist* — chosen.

### U7 — How do we keep the new design-system page in sync with the partials it documents?

**Decision**: The reference page imports each primitive by `render` or `render partial:` — it is the same call every consumer makes. If a partial's interface changes, every consumer (including the reference page) breaks at the same time. There is no "doc" surface to drift from the "implementation" surface; they are the same code.

**Rationale**: Single-source-of-truth for partials is a Constitution §III requirement (reuses partials and `UiHelper` block/slot wrappers before introducing new UI abstractions). The reference page embodies that requirement.

**Alternatives considered**:
- *Markdown docs + separate partials* — out: drift risk.
- *Stories as live imports of real partials* — chosen.

### U8 — How do we handle the design-system reference page in production?

**Decision**: Behind `Rails.env.development?` for unauthenticated access; available to any logged-in `Administrator` (or a new `developer` role) in production. The page is harmless in production (read-only, no privileged data) but it is internal documentation; we follow the same gate `Mission Control` uses today.

**Rationale**: Existing `Mission Control` (admin/jobs) follows this same convention. Admins are the only role that needs to see internal tooling.

**Alternatives considered**:
- *Public in production* — out: leaks internal design docs.
- *Development only* — out: ops/admin can't reference it.
- *Admin-only in production, dev-only locally* — chosen.

## Best Practices Captured

### Tailwind v4 + FlyonUI co-existence

- Tailwind v4 `@theme` block at the top of `application.tailwind.css` is the source of truth for tokens.
- FlyonUI's `@plugin 'flyonui/theme'` blocks must remain inside their respective themes (`quill` / `quill-dark`) — moving them outside breaks FlyonUI's component shapes.
- New primitives prefer `@utility <name> { @apply … }` for reusable classes that compose with utilities (`bg-base-200 text-base-content/70 rounded-full px-2 py-0.5`).
- Avoid `@apply` chains longer than 3 levels — they become un-lintable.

### Stimulus + Turbo patterns already in use

- **Single Stimulus controller per concern**, with `data-controller="<name>"` mounting and `data-<name>-target` / `data-<name>-action` patterns.
- **Modal pattern**: FlyonUI modal opened by `flyonui-modal-controller`; closed by `data-action="click->flyonui-modal#close"`.
- **Dropdown pattern**: FlyonUI dropdown via `flyonui-dropdown-controller`; closed by outside-click handler.
- **Toast pattern**: Stimulus `notify.js` mounts into `#toast-slot`; flashes via `flash_controller.js`.
- **Tab pattern**: `tabs_controller.js` toggles `active-class` on click.

These patterns are reused; no new conventions are introduced.

### i18n for user-visible strings

- All new copy goes to `config/locales/<locale>.yml`.
- No hardcoded English in views.
- Existing `t('.key')` pattern used throughout; helpers like `localize_button` are added if a string repeats more than 3 times.

### Testability

- Existing `bin/rails test` covers models/controllers/jobs/notifiers.
- New `test/system/design_system_test.rb` mounts the reference page and asserts every primitive renders, plus a screenshot regression check.
- New `test/lib/design_system_lint_test.rb` runs `DesignSystem::Lint.run` against the repo and asserts zero violations on `main`.
- Existing tests are not modified except where a helper signature changes (and even then, the change is additive — old locals remain optional).

## Final Decisions

| Decision | Choice |
|---|---|
| Reference page hosting | In-app Rails controller + view (`DesignSystemController#show`) |
| Primitive mechanism | Tailwind v4 `@utility` + `@theme` tokens |
| Lint enforcement | `bin/lint-design-system` shell script + `DesignSystem::Lint` Ruby class |
| Dashboard right rail | Opt-in via `content_for(:sidebar)`, no default |
| Toast icon migration | `i-[tabler--*]` via Stimulus |
| Radius coexistence | FlyonUI radii + brand-spec radii coexist; no alias |
| Reference page / partials sync | Reference page renders the same partials every consumer renders |
| Production gating | Admin-only in production, dev-only locally |

## Open Items for `/speckit.tasks`

These are tracked here so `tasks.md` can pick them up without re-deriving them:

- Confirm `Mission Control` admin auth pattern before deciding whether `DesignSystemController` needs its own auth (likely piggybacks on `Administrator`).
- Decide whether `lib/design_system/lint.rb` is loaded eagerly (e.g. in `config/application.rb` for `--lint` flag) or lazily (`Rails.autoloaders.main.eager_load` is fine).
- Confirm the lint script exit-code semantics with the CI workflow (`.github/workflows/check.yml`) before Phase A ships.
- Confirm the `<title>` and `<meta name="theme-color">` strategy for the design-system page (should match the dashboard so it doesn't drift in production).