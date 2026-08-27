# Data Model: Comprehensive UI Refactor

> Phase 1 of `/speckit.plan`. The refactor is presentational, so the "data model" here is the design-system entity model — the contract that connects tokens, primitives, surfaces, and lint rules to every view in the app.

## Entities

### `DesignToken`

A named design-time value (color, font, radius, spacing) referenced by every component. Lives in `app/assets/stylesheets/application.tailwind.css` (FlyonUI theme blocks + new `:root` OKLCh tokens + spacing scale) and is consumed by every primitive.

| Attribute | Type | Description |
|---|---|---|
| `name` | `Symbol` | `bg`, `surface`, `fg`, `muted`, `border`, `accent`, `reward`, `success`, `warn`, `danger`, `ring` (color); `display`, `body`, `mono` (font); `selector`, `field`, `box`, `radius`, `radius-lg`, `radius-full` (radius); `gap-xs`, `gap-sm`, `gap-md`, `gap-lg`, `gap-xl`, `gap-2xl`, `container`, `measure`, `gutter` (spacing). |
| `light` | `String` | OKLCh or hex value for the light theme. |
| `dark` | `String` | OKLCh or hex value for the dark theme. |
| `tailwind_class` | `String` | the Tailwind utility class that exposes this token (`bg-base-200`, `text-reward`, `border-base-300`, etc.). |
| `css_var` | `String` | the CSS custom property (`--accent`, `--reward`, `--bg`, etc.). |
| `role` | `String` | one-line description of where this token is used. |

**Source of truth**: `contracts/tokens.md`.

### `Primitive`

A reusable UI building block (button, chip, card, list row, form field, tab, modal, dropdown, value note, notification card, skeleton, state-empty, table, avatar, masthead, tabbar, side rail) defined as a single ERB partial + Stimulus controller where needed. Rendered by every view that uses it.

| Attribute | Type | Description |
|---|---|---|
| `name` | `Symbol` | `:button`, `:chip`, `:card`, `:input`, `:list_row`, `:value_note`, `:notification_card`, `:skeleton`, `:state_empty`, `:table`, `:avatar`, `:masthead`, `:modal`, `:dropdown`, `:tabbar_public`, `:tabbar_dashboard`, `:rail_dashboard`. |
| `partial_path` | `String` | absolute path to the backing ERB partial (`app/views/shared/_button.html.erb`). |
| `controller_path` | `String?` | optional Stimulus controller path (`app/javascript/controllers/flyonui_modal_controller.js`). |
| `helper` | `String?` | optional helper that wraps the partial (`render_button`, `render_modal`, etc.). |
| `locals` | `Array<Hash>` | required + optional locals with type + default. |
| `consumers` | `Array<String>` | absolute paths to every view that calls the partial (populated by `lib/design_system/lint.rb`'s reachability scan). |

**Source of truth**: `contracts/primitives.md`.

### `Surface`

A user-visible screen (one per controller action family). Each surface lists the primitives it composes from and is verified by the design-system entry page.

| Attribute | Type | Description |
|---|---|---|
| `controller` | `String` | fully-qualified controller class (`ArticlesController`, `Admin::ArticlesController`, `ErrorsController`, `Dashboard::HomeController`). |
| `action` | `Symbol` | `:index`, `:show`, `:edit`, etc. |
| `layout` | `String` | the layout that wraps the action (`application`, `public`, `admin`, `editor`, `grover`, `homepage`, `mailer`, `none`). |
| `path` | `String` | absolute path to the entry template. |
| `primitives` | `Array<Symbol>` | primitives the surface consumes (filled in by the reachability scan). |
| `priority` | `Symbol` | `:p1`, `:p2`, `:p3`, `:p4` per spec US1/US2/US3/US4. |

**Priority assignment** (per spec):
- **P1** — design-system entry page itself (`DesignSystemController#show`).
- **P2** — public surfaces: `home#index`, `articles#index`, `articles#show`, `users#show`, `collections#show`, `search#index`, `comments#index`, `pages#fair`, `pages#rules`, `sessions#new`, `errors#not_found`, `errors#not_acceptable`, `errors#unprocessable_entity`, `errors#internal_server_error`.
- **P3** — authoring surfaces: every `Dashboard::*Controller` action + every `ArticlesController` action under `editor.html.erb` layout (`new`, `edit`, `preview`) + `articles#share` + `collections#share`.
- **P4** — admin surfaces: every `Admin::*Controller` action + every `API::*Controller` HTML error response + `dashboard/notifications` inbox + `dashboard/notifications/_notification` row + real-time toast (driven by `app/javascript/utils/notify.js`).

**Source of truth**: `plan.md` §"Implementation Strategy" and the reachability scan output.

### `DesignSystemLintViolation`

A CI-detected occurrence of a hand-rolled color, type ramp, icon, or component outside the design system.

| Attribute | Type | Description |
|---|---|---|
| `rule_id` | `String` | `DS001`..`DS013`. |
| `severity` | `Symbol` | `:error`, `:warning`, `:info`. |
| `file` | `String` | path relative to `Rails.root`. |
| `line` | `Integer` | 1-indexed line number. |
| `message` | `String` | one-line explanation. |

**Source of truth**: `contracts/lint-rules.md`.

### `DesignSystemReference`

The in-app design-system documentation page, generated from the same partials the rest of the app uses.

| Attribute | Type | Description |
|---|---|---|
| `controller` | `String` | `DesignSystemController#show`. |
| `path` | `String` | `/design-system`. |
| `sections` | `Array<Symbol>` | tokens, type, buttons, chips, list_row, cards, forms, tabs, value_net, notifications, states, masthead, page_shell, modal, dropdown. |
| `production_visibility` | `Symbol` | `:admin_only` in production, `:developer` in development (Rails.env.development? OR Administrator role). |

**Source of truth**: `plan.md` §"Phase A".

## Relationships

```text
DesignToken ──consumed by──> Primitive (every primitive consumes zero or more tokens)
Primitive ──composed into──> Surface (every surface consumes one or more primitives)
Surface ──owns──> DesignSystemReference (the reference page lists every surface + every primitive)
DesignSystemLintViolation ──emitted by──> lib/design_system/lint.rb (walks every view, partial, controller, helper, and stylesheet)
DesignSystemLintViolation ──blocks──> CI (bin/lint-design-system exit code 1)
```

## Cardinalities

- One `DesignToken` is consumed by N `Primitive`s (N ≥ 1).
- One `Primitive` is composed into N `Surface`s (N ≥ 1; usually N >> 1 for shared primitives like `:button`).
- One `Surface` consumes N `Primitive`s (N ≈ 3–8 typical).
- One `DesignSystemReference` lists all `Primitive`s and all `Surface`s (1:1).
- One `DesignSystemLintViolation` is emitted by exactly one rule against exactly one file:line.

## Migrations

This refactor introduces **no schema migrations**. The four "entities" above are design-time concepts, not ActiveRecord models. The Rails database schema is untouched.

The only Rails-internal change that requires `bin/rails zeitwerk:check` is the new `DesignSystemController`, `DesignSystemHelper`, and `lib/design_system/lint.rb` constant — all autoloaded via the existing Zeitwerk setup (`app/controllers/design_system_controller.rb`, `app/helpers/design_system_helper.rb`, `lib/design_system/lint.rb`).

## Invariants

These invariants are checked by `lib/design_system/lint.rb` on every CI run:

1. Every `Primitive` listed in `contracts/primitives.md` exists as an ERB partial at the listed path.
2. Every `Primitive` partial has at most one variant block per `variant:` value.
4. No `DesignSystemLintViolation` of severity `:error` exists on `main`.
5. No `Surface` is missing from `DesignSystemReference` (every controller-action listed in the priority assignment above is reachable via the reference page; partials reachability is asserted by the system test).
6. Every consumer of a `Primitive` passes a `label` / `title` / `name` local that is I18n-translated (i.e. starts with `t(`.` or is wrapped in `I18n.t(`).