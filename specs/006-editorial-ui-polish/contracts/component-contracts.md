# Phase 1 Contracts: Editorial UI Polish Pass

Presentation-layer contracts for shared partials and interaction components. No API or model interface changes.

## Partial: `shared/_modal`

**Callers**: Every `render_modal` / `turbo_frame_tag 'modal'` view (~20 entry points).

**Contract**:
- MUST preserve: `id="app-modal"`, `role="dialog"`, `tabindex="-1"`, `data-controller="modal-component"`, `data-action="turbo:submit-end->modal-component#submitEnd"`, `data-modal-component-backdrop-value`, FlyonUI `overlay modal modal-middle` classes.
- MAY add: editorial Tailwind utilities on `modal-dialog`, `modal-content`, `modal-header`, `modal-body` (radius, border, padding, typography).
- Close button MUST retain `data-action="modal-component#close"` and an accessible `aria-label`.
- Icon MUST use `i-[tabler--x]` (canonical prefix).

## Partial: `shared/_dropdown`

**Callers**: Masthead profile menu, any `render_dropdown` usage.

**Contract**:
- MUST preserve: `data-controller="flyonui-dropdown"`, `dropdown-toggle` button, `dropdown-menu` panel, `role="menu"`.
- MAY add: editorial border/radius/shadow utilities on `dropdown-menu`.

## Partial: `shared/_share_options`

**Callers**: Article/collection/user share modals.

**Contract**:
- MUST preserve: `data-action="modal-component#close"` on external links, `data-controller="clipboard"` + `data-action="clipboard#copy modal-component#close"` on copy button, `share_url`/`share_title`/`mixin_href` locals.
- All icons MUST use `i-[tabler--*]` prefix.

## Partials: `articles/_votes`, `comments/_actions`

**Callers**: `articles/show.html.erb`, comment list partials.

**Contract**:
- MUST preserve: all `link_to`/`button_to` paths, `turbo_method` values, `login_path` modal triggers, vote count display.
- MUST NOT change DOM ids (`dom_id article %>_votes`, etc.) used by Turbo Stream replacements.

## Partials: `subscribe_*/*_subscribe_button`

**Contract**:
- MUST preserve: `dom_id`-based wrapper classes, three branches (logged-out / self / subscribed / default), `turbo_frame: :modal` on login/subscribed links.

## Views: `block_users/new`, `locales/edit`, `pre_orders/_form`

**Contract**:
- MUST preserve: form actions, hidden fields, Stimulus controller targets on pre-order form, locale link targets (`/{locale}` with `turbo_frame: '_top'`).
- Block-user `button_to` MUST keep `block_users_path(uid: @user.uid)` — only button classes change.

## Partial: `shared/_nav_icon_link` (unused)

**Contract**:
- `icon` local changes from SVG file path to Tabler slug (e.g., `"bell"` → `i-[tabler--bell]`). No callers today; contract documents the new local shape if reintroduced.

## Tailwind icon prefix

**Contract**:
- All new or migrated Tabler icons MUST use `i-[tabler--*]` — never `icon-[tabler--*]`.
- Config source: `application.tailwind.css` `@plugin '@iconify/tailwind4' { prefix: 'i'; }`.

## Out of scope (MUST NOT modify)

- `app/views/admin/**`
- Routes, controllers, models, jobs, Stimulus action names
