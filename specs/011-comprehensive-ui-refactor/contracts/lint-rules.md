# Lint Rules

> The exact rules enforced by `bin/lint-design-system` (which invokes `lib/design_system/lint.rb`). One violation per line as `file:line: <rule-id>: <message>`. CI fails on any violation.

## Rule index

| Rule ID | Severity | What it catches |
|---|---|---|
| `DS001` | error | Raw hex color outside the token layer or coin-brand allowlist. |
| `DS002` | error | Hand-rolled `<svg>` icon in a view (outside the allowlist). |
| `DS003` | error | `tag-style-0` through `tag-style-5` class remnant. |
| `DS004` | error | `bg-reward` or `border-reward` Tailwind utility (reward is text-only). |
| `DS005` | error | Raw `<button class="btn btn-primary">` outside `shared/_button.html.erb` (must use `render_button`). |
| `DS006` | error | Raw `<span class="chip chip-*">` outside `shared/_chip.html.erb` (must use `render_chip`). |
| `DS007` | warning | Raw `<table>` outside `shared/_table.html.erb` (use `render_table`). |
| `DS008` | warning | Literal `border-radius:` value outside the `:root` block. |
| `DS009` | warning | `font-display` / `font-mono` applied to an element that also has `bg-base-200 text-base-content/60` (semantic conflict — display fonts on muted chrome). |
| `DS010` | info | New `i-[tabler--*]` slug not in the allowlist (auto-allowlisted on first occurrence; informational only). |
| `DS011` | error | Raw `<input class="input">` outside `shared/_ui_input.html.erb`. |
| `DS012` | error | Raw modal markup outside `shared/_modal.html.erb`. |
| `DS013` | error | Raw dropdown markup outside `shared/_dropdown.html.erb`. |

## DS001 — Raw hex colors

**Bad**:
```erb
<div class="bg-[#5C6BEF]">…</div>
```
**Good**:
```erb
<div class="bg-primary">…</div>
```

**Detection**: regex `#[0-9A-Fa-f]{3,8}\b` against `app/views/**/*.erb`, `app/javascript/**/*.js`, `app/helpers/**/*.rb`. Allowlist: `:root` in `application.tailwind.css`, the four `--coin-*` declarations, `<meta name="theme-color">` content attributes.

## DS002 — Hand-rolled SVG icons

**Bad**:
```erb
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7">
  <path d="M12 3a9 9 0 1 0 9 9c0-.46-.04-.92-.1-1.36…"/>
</svg>
```
**Good**:
```erb
<span class="i-[tabler--moon]"></span>
```

**Detection**: any `<svg …>` block in `app/views/**/*.erb` outside the allowlist. Allowlist:
- `app/views/articles/_card_cover.html.erb` (procedural cover-art generator)
- `app/javascript/utils/notify.js` (toast icons; **to be migrated to `i-[tabler--*]`** during Phase D — after Phase D the lint allowlist shrinks to just `_card_cover.html.erb`)

## DS003 — `tag-style-*` remnants

**Bad**:
```erb
<span class="tag-style-0">Bitcoin</span>
```
**Good**:
```erb
<%= render_chip "Bitcoin", kind: :topic %>
```

**Detection**: regex `tag-style-[0-5]` against `app/views/**/*.erb` and `app/javascript/**/*.js`. (Expected to be 0 hits today; defensive rule.)

## DS004 — `bg-reward` / `border-reward`

**Bad**:
```erb
<span class="bg-reward text-white">+18%</span>
```
**Good**:
```erb
<%= render_value_note "+18%", label: "early reader", format: :percent %>
```

**Detection**: regex `\b(bg|border)-reward\b` against `app/views/**/*.erb`. (Brand spec: reward is text-only.)

## DS005 — Raw primary button

**Bad**:
```erb
<button class="btn btn-primary">Unlock article</button>
```
**Good**:
```erb
<%= render_button t(".unlock"), icon: "lock-open", size: :lg %>
```

**Detection**: regex `class\s*=\s*["'][^"']*\bbtn\b[^"']*\bbtn-primary\b[^"']*["']` against `app/views/**/*.erb`. Allowlist: `app/views/shared/_button.html.erb` itself.

## DS006 — Raw chip

**Bad**:
```erb
<span class="chip chip-topic">Bitcoin</span>
```
**Good**:
```erb
<%= render_chip "Bitcoin", kind: :topic %>
```

**Detection**: regex `class\s*=\s*["'][^"']*\bchip\s+chip-[a-z-]+[^"']*["']` against `app/views/**/*.erb`. Allowlist: `app/views/shared/_chip.html.erb` itself.

## DS007 — Raw `<table>`

**Bad**:
```erb
<table class="table">…</table>
```
**Good**:
```erb
<%= render_table columns: COLUMNS, rows: @orders %>
```

**Detection**: regex `<table\b` against `app/views/**/*.erb`. Allowlist: `app/views/shared/_table.html.erb`, admin views that pre-date the refactor (tracked in `lib/design_system/lint.rb`'s `@allowlist` set; the set shrinks every phase).

## DS008 — Raw `border-radius`

**Bad**:
```css
.card { border-radius: 14px; }
```
**Good**:
```css
.card { border-radius: var(--radius-lg); }
```

**Detection**: regex `border-radius:\s*\d` against `app/assets/stylesheets/**/*.css`. Allowlist: `:root` block declarations.

## DS009 — Semantic font/color conflict

**Bad**:
```erb
<span class="font-display bg-base-200 text-base-content/60">…</span>
```
**Good**:
```erb
<span class="font-mono text-base-content/60">…</span>
```

**Detection**: AST-light heuristic — when an element has both `font-display` and a muted-style color (`text-base-content/60` or `text-muted`), flag as a warning. Phase A may refine this rule.

## DS010 — New `i-[tabler--*]` slug

**Info only**. The lint script tracks every distinct `i-[tabler--*]` slug it sees; new slugs are reported as informational so reviewers can confirm the slug exists in `@iconify-json/tabler`.

## DS011 — Raw input

**Bad**:
```erb
<input type="text" class="input">
```
**Good**:
```erb
<%= ui_input :article, :title %>
```

**Detection**: regex `<input\b[^>]*\bclass\s*=\s*["'][^"']*\binput\b[^"']*["']` against `app/views/**/*.erb`. Allowlist: `app/views/shared/_ui_input.html.erb` itself + Lexxy internals (handled separately).

## DS012 — Raw modal

**Bad**:
```erb
<div class="modal">…</div>
```
**Good**:
```erb
<%= render_modal(title: t(".title")) do %>…<% end %>
```

**Detection**: regex `<div\b[^>]*\bclass\s*=\s*["'][^"']*\bmodal\b[^"']*["']` against `app/views/**/*.erb`. Allowlist: `app/views/shared/_modal.html.erb` itself + `app/javascript/controllers/flyonui_modal_controller.js` (FlyonUI internals).

## DS013 — Raw dropdown

**Bad**:
```erb
<div class="dropdown">…</div>
```
**Good**:
```erb
<%= render_dropdown(button: …) do %>…<% end %>
```

**Detection**: regex `<div\b[^>]*\bclass\s*=\s*["'][^"']*\bdropdown\b[^"']*["']` against `app/views/**/*.erb`. Allowlist: `app/views/shared/_dropdown.html.erb` itself + `app/javascript/controllers/flyonui_dropdown_controller.js`.

## CI integration

`.github/workflows/check.yml` adds a new step after `bin/rubocop`:

```yaml
- name: Lint design system
  run: bin/lint-design-system
```

`bin/lint-design-system` is a shell wrapper that loads the Rails environment and invokes `DesignSystem::Lint.run(Rails.root)`. Exit code 0 = clean; exit code 1 = violations (printed to stderr).

Phased development (Phases A→D) accepts `--phase <a|b|c|d>` to scope the lint to the current phase plus all earlier phases. CI always runs the full check.

## Allowlist management

The allowlist is a frozen `Set` declared at the top of `lib/design_system/lint.rb`. Each entry is a file path (relative to `Rails.root`) plus a comment explaining why it is allowed.

Removing an entry is a deliberate change; it should accompany the migration that makes the file comply with the rule.