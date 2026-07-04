# Phase 1 Data Model: Editorial UI Polish Pass

**No database or domain model changes.** This feature is presentation-layer only (spec FR-016).

The "entities" below are **view-layer components**, not ActiveRecord models.

## Shared Modal Shell

| Attribute | Description |
|---|---|
| Title | Modal heading; uses `font-display` typography after polish |
| Header | Optional custom header block; default renders title + close control |
| Body | Turbo-rendered content from each modal view |
| Backdrop | FlyonUI overlay backdrop (`default` or `static`) |
| Close control | `btn-soft btn-circle` with `i-[tabler--x]` icon |

**Relationships**: Wrapped by `turbo_frame_tag 'modal'` in ~20 modal entry views. Rendered via `UiHelper#render_modal`.

**Validation**: MUST preserve `role="dialog"`, `data-controller="modal-component"`, and `turbo:submit-end->modal-component#submitEnd`.

## Shared Dropdown Shell

| Attribute | Description |
|---|---|
| Toggle button | Passed as `button` local (avatar, icon button, etc.) |
| Menu panel | Passed as `menu` local (usually a `<ul class="menu">`) |

**Relationships**: Used by masthead profile menu and any `render_dropdown` call site.

**Validation**: MUST preserve `data-controller="flyonui-dropdown"` and `aria-haspopup`/`aria-expanded` on toggle.

## Article Interaction Cluster

Components rendered on or around `articles/show`:

| Component | File | Key states |
|---|---|---|
| Vote controls | `articles/_votes.html.erb` | upvoted, downvoted, logged-out |
| Share button | `articles/_share_button.html.erb` | opens share modal |
| Share options | `shared/_share_options.html.erb` | Twitter, Telegram, Mixin, copy URL |
| Comment actions | `comments/_actions.html.erb` | upvote, downvote, reply per comment |
| Subscribe buttons | `subscribe_*/*_subscribe_button.html.erb` | logged-out, subscribed, default |

**State transitions**: Unchanged — same Turbo/HTTP methods as before; only CSS classes and icon markup change.

## Secondary Modal Content

| Modal | View | Primary action |
|---|---|---|
| Locale picker | `locales/edit.html.erb` | Link to `/{locale}` |
| Pre-order | `pre_orders/_form.html.erb` | Submit pre-order form |
| Comment | `comments/new.html.erb` + `_form.html.erb` | Submit comment |
| Block user | `block_users/new.html.erb` | `button_to` block action |
| Currency picker | `currencies/index.html.erb` | Select currency from list |

**Validation**: Form field names, routes, and Stimulus `data-*` hooks MUST NOT change.
