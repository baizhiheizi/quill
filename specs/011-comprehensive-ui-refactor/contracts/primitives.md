# Primitives Contract

> The list of design-system primitives. Every primitive is backed by exactly one ERB partial under `app/views/shared/` (or one Stimulus controller under `app/javascript/controllers/`). Views MUST consume primitives by `render` (or the helper that wraps them) — never by re-implementing the markup.

## Button

**Backing**: `app/views/shared/_button.html.erb` + `UiHelper#render_button`.

**Helper signature**:
```ruby
render_button(label, variant: :primary, size: :md, icon: nil, href: nil, type: "button", **html_options)
```

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `label` | `String` / `I18n.t` | yes | — | visible button text |
| `variant` | `:primary` / `:secondary` / `:soft` / `:ghost` / `:danger` | no | `:primary` | visual style |
| `size` | `:sm` / `:md` / `:lg` | no | `:md` | size ramp |
| `icon` | `String` (Tabler slug) | no | `nil` | renders `i-[tabler--<slug>]` next to the label |
| `href` | `String` | no | `nil` | if set, renders `<a>`; otherwise `<button>` |
| `type` | `String` | no | `"button"` | `<button type>` |
| `**html_options` | — | no | — | forwarded to the rendered element |

**Variants** (light → dark):
- `:primary` — `bg-primary text-primary-content` (the cobalt accent)
- `:secondary` — `bg-base-200 text-base-content border border-base-300`
- `:soft` — `bg-base-200 text-base-content`
- `:ghost` — `bg-transparent text-base-content hover:bg-base-200`
- `:danger` — `bg-error text-error-content`

**Sizes**:
- `:sm` — `h-8 px-3 text-sm`
- `:md` — `h-10 px-4`
- `:lg` — `h-12 px-6 text-lg`

**Icon slugs** (must exist in `@iconify-json/tabler`; the lint script verifies):
- 42 distinct slugs already in use across views; see `app/views/**` for the canonical list.
- New slugs are added by importing the slug into `@iconify-json/tabler` (already installed).

**Example**:
```erb
<%= render_button t(".unlock"), icon: "lock-open", size: :lg %>
```

## Chip

**Backing**: `app/views/shared/_chip.html.erb` + `UiHelper#render_chip`.

**Helper signature**:
```ruby
render_chip(label, kind: :topic, **html_options)
```

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `label` | `String` / `I18n.t` | yes | — | visible text |
| `kind` | `:topic` / `:price` / `:status` / `:reward` | no | `:topic` | visual style |
| `**html_options` | — | no | — | forwarded to the rendered element |

**Kinds**:
- `:topic` — neutral chip (`bg-base-200 text-base-content/70 rounded-full px-2 py-0.5 text-sm`)
- `:price` — solid pill (`bg-base-content text-base-100 rounded-full px-2 py-0.5 text-sm`)
- `:status` — outlined (`border border-base-300 rounded-full px-2 py-0.5 text-sm`)
- `:reward` — text-only muted-amber (renders a `<span class="text-reward">` instead of a chip; **never a filled badge**)

## Card

**Backing**: `app/views/shared/_ui_card.html.erb` + `UiHelper#ui_card`.

(Already exists; restyled to consume tokens. No signature change required; new optional locals `padding:`, `border:`, `header:`, `footer:` accepted.)

## Input

**Backing**: `app/views/shared/_ui_input.html.erb` + `UiHelper#ui_input`.

(Already exists; restyled to consume tokens. No signature change required; new optional locals `hint:`, `error:` accepted.)

## List row (Minimal List)

**Backing**: `app/views/shared/_list_row.html.erb` + `UiHelper#render_list_row`.

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `article` | `Article` | yes | — | the article to render |
| `show_topic` | `Boolean` | no | `true` | render the topic chip |
| `show_excerpt` | `Boolean` | no | `true` | render the one-line muted excerpt |
| `show_meta` | `Boolean` | no | `true` | render author + date + reward |
| `show_thumbnail` | `Boolean` | no | `true` | render the right thumbnail |
| `target` | `:_blank` / `:self` | no | `:self` | link target |

**Used by**: home feed (`articles/_card.html.erb`), search (`search/_result.html.erb`), author profile (`users/articles/_article_feed.html.erb`), collection (`collections/articles/_article.html.erb`), dashboard reads (`dashboard/subscribe_articles/_article.html.erb`).

## Masthead (public top-nav)

**Backing**: `app/views/shared/_masthead.html.erb`.

(Already exists; restyled to consume tokens. No signature change required.)

## Modal

**Backing**: `app/views/shared/_modal.html.erb` + `UiHelper#render_modal`.

(Already exists; restyled to consume tokens. No signature change required; **single source-of-truth**: every modal across the app funnels through this partial.)

## Dropdown

**Backing**: `app/views/shared/_dropdown.html.erb` + `UiHelper#render_dropdown`.

(Already exists; restyled to consume tokens. No signature change required; **single source-of-truth**: every dropdown across the app funnels through this partial.)

## Value note (reward / earnings text)

**Backing**: `app/views/shared/_value_note.html.erb`.

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `value` | `String` / `Numeric` | yes | — | the value to display |
| `label` | `String` / `I18n.t` | no | `nil` | optional label (e.g. "earnings", "early reader") |
| `format` | `:percent` / `:currency` / `:plain` | no | `:plain` | formatting hint |

**Renders**: `<span class="text-reward font-mono text-[13px]">…</span>`. **Never a filled badge**, per brand spec.

**Used by**: home feed (`articles/_card.html.erb`), article card meta row, dashboard stat cards, dashboard finances view, transfers stats grid, article reader value note.

## Notification card

**Backing**: `app/views/shared/_notification_card.html.erb`.

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `event` | `Noticed::Event` | yes | — | the notification to render |
| `unread` | `Boolean` | no | `false` | render the unread indicator |

**Used by**: `dashboard/notifications/_notification.html.erb` (inbox row) + real-time toast slot via `app/javascript/utils/notify.js` (replaces the 8 hand-rolled SVGs with `i-[tabler--alert-circle]`, `i-[tabler--alert-triangle]`, `i-[tabler--circle-check]`, `i-[tabler--x]`).

## Skeleton (loading)

**Backing**: `app/views/shared/_skeleton.html.erb`.

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `width` | `String` (Tailwind class) | no | `"w-full"` | width utility |
| `height` | `String` (Tailwind class) | no | `"h-4"` | height utility |
| `rounded` | `String` (Tailwind class) | no | `"rounded"` | radius utility |

**Renders**: `<div class="animate-pulse bg-base-200 <width> <height> <rounded>"></div>`.

## State (empty / error)

**Backing**: `app/views/shared/_state_empty.html.erb`.

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `icon` | `String` (Tabler slug) | no | `"info-circle"` | icon to render |
| `title` | `String` / `I18n.t` | yes | — | headline |
| `body` | `String` / `I18n.t` | no | `nil` | optional body copy |
| `action` | `String` (button label) | no | `nil` | optional CTA label |
| `action_href` | `String` | no | `nil` | CTA href |

**Used by**: empty-state pages (no articles, no notifications, no drafts, no search results) + every error page (`errors/not_found`, `errors/internal_server_error`, `errors/not_acceptable`, `errors/unprocessable_entity`).

## Table (dashboard)

**Backing**: `app/views/shared/_table.html.erb` + `UiHelper#render_table`.

| Local | Type | Required | Default | Description |
|---|---|---|---|---|
| `columns` | `Array<Hash>` | yes | — | column definitions (`:key`, `:label`, `:format`, `:align`) |
| `rows` | `ActiveRecord::Relation` / `Array` | yes | — | data |
| `row_path` | `Proc` / `String` | no | `nil` | optional row link |
| `empty` | `String` / `I18n.t` | no | `t(".empty")` | empty-state copy |

**Renders**: a `<table>` with `border-base-300` rows, mono numerics in the right column, sticky header on scroll. Replaces every bespoke dashboard table in `dashboard/{orders,payments,transfers,articles,collections,comments,subscribe_*}/index.html.erb`.

## Avatar

**Backing**: `app/views/shared/_avatar.html.erb`.

(Already exists; restyled to consume tokens. No signature change required.)

## Tabbar (mobile bottom nav)

**Backing**: `app/views/shared/_tabbar.html.erb` (public) + `app/views/shared/_dashboard_tabbar.html.erb` (dashboard).

(Already exist; restyled to consume tokens. No signature change required.)

## Side rail (dashboard desktop)

**Backing**: `app/views/shared/_dashboard_rail.html.erb`.

(Already exists; restyled to consume tokens. No signature change required.)

## Enforcement

`bin/lint-design-system` enforces:

1. No raw `<button class="btn btn-primary">` in views — use `render_button`. (Allowlist: `app/views/shared/_button.html.erb` itself.)
2. No raw `<span class="chip chip-topic">` in views — use `render_chip`. (Allowlist: `app/views/shared/_chip.html.erb` itself.)
3. No raw `<table>` outside `app/views/shared/_table.html.erb` and the allowlisted admin tables that pre-date the refactor (tracked in `lib/design_system/lint.rb`'s `ALLOWLIST`).
4. No raw `<svg>` outside the allowlist (procedural cover art + Lexxy internals + `app/assets/builds/application.js` bundled vendor code).
5. **DS014 — no direct `render "shared/<primitive>"` for a primitive that has a UiHelper wrapper.** This is the interface rule: the partial is a primitive's implementation, the helper is its contract. Every syntax variant counts — string, `partial:` + `locals:`, single-quoted, parenthesised. `app/views/shared/` is exempt (that is the implementation; primitives composing each other there is not a consumer bypass).

The helper-name exemptions on DS005/DS006/DS011–13 fire only for a genuine
helper *call* (`<%= render_button … %>`, `ui_input form, :email`). A line that
merely names the partial path (`render "shared/ui_input"`) no longer exempts
itself from the markup rule it would otherwise trip.

Allowlist entries are one of:

- `"path" => "reason"` — exempts the whole file; or
- `"path" => { rules: %w[DS005], reason: "…" }` — exempts only the named rules,
  so a legacy file keeps the other thirteen.

Every entry must cite a reason; a bare path list is not accepted.

Violations fail CI; the script emits one violation per line as `file:line: rule: message`.