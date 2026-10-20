# Changelog

## Unreleased

### mixin_bot 3.0 and the Blaze async reactor

`mixin_bot` is now `~> 3.0` (locked 3.0.2). The gem replaced its EventMachine
Blaze client with `MixinBot::Blaze::Reactor` (async-websocket), which owns
connect, keepalive, read, ack and reconnect-with-backoff. `bin/mixin_blaze`
shrinks accordingly; the standalone process, its Kamal role, and the
`Settings.blaze_enable` gate are unchanged — only the Blaze half of the feed
moved.

`QuillBot` gained the reactor wiring and `MixinMessage` gained the message
model, both covered by new tests.

### Deliberate `json` pin — do not bump

`json` is held at `~> 2.21`. Rails 8.1 calls `JSON.parse(source, options)`
positionally; json 3 dropped the positional options hash, so **every json
column read raises `ArgumentError` and 500s any controller that touches one**.

Dependabot #2125 bumped to json 3.0.2 and broke main; #2130 reverted it. The
pin carries an explanatory comment in the `Gemfile` — keep it until a Rails
release adopts the json 3 signature.

### Crash fixes

- **Profile tab crash (#2105)** — any `tab` param other than
  `published`/`bought` left the articles relation `nil` and blew up on
  `.with_associations` (`NoMethodError`). Unknown tabs now fall back to
  `published`.
- **Output buffer encoding (#2107)** — a binary-tagged (ASCII-8BIT) string
  carrying non-ASCII bytes raised `Encoding::CompatibilityError` against a
  UTF-8 output buffer, 500ing the page for every visitor (PostHog 01a0918e:
  14 users hit `/articles` in a 7-second window). Binary-tagged strings are
  re-tagged to UTF-8 on each `append=` path, since `append=`/`concat` are
  class-body aliases of `<<` and would otherwise bypass a prepended `<<`.

### Dependencies

`ransack` 4.4.1 → 5.0.0 (#2128, now locked 6.0.0), plus routine patch bumps
(lexxy, posthog-rails, sqlite3, simplecov, bootsnap, aws-sdk-s3,
image_processing, mission_control-jobs, selenium-webdriver).

### Tooling and docs corrections

- `docs/how-to/deploy-with-kamal.md` corrected against the real deployment:
  storage server IP, `Release` (not `Deploy`) as the workflow name,
  `bin/kamal deploy --skip-push`, `KAMAL_REGISTRY_PASSWORD` as a ghcr.io
  login, and the rollback snippet (`workflow_dispatch` takes a branch or tag,
  not a bare SHA).
- `bin/measure-frontend-efficiency` now reports `reduced_motion_rule`
  alongside `motion_reduce_aware`. Motion is gated by one
  `@media (prefers-reduced-motion: reduce)` rule in the token layer, so the
  view-level count alone read as a false gap.
- `AGENTS.md` corrected: Docker Hub image name, `deploy.yml` → `release.yml`.

## Unreleased — specs/011-comprehensive-ui-refactor

### Design system foundation

Quill now has a single, well-maintained design system. Open `/design-system`
in development (or as an Administrator in production) to see every token and
every primitive in one place.

**New shared primitives** (`app/views/shared/_*.html.erb`, all wrapped in
`UiHelper`):

- `render_button` (`_button.html.erb`) — five variants × three sizes; icon-first.
- `render_chip` (`_chip.html.erb`) — topic / price / status / reward.
- `render_list_row` (`_list_row.html.erb`) — Minimal List row used by feed /
  search / author profile / collection.
- `render_value_note` (`_value_note.html.erb`) — text-only muted-amber reward
  figure (never a filled badge, per brand spec).
- `render_notification_card` (`_notification_card.html.erb`) — inbox card
  + real-time toast.
- `render_skeleton` (`_skeleton.html.erb`) — loading placeholder.
- `render_state_empty` (`_state_empty.html.erb`) — empty/error state block;
  used by every error page.
- `render_table` (`_table.html.erb`) — generic data table; replaces bespoke
  dashboard + admin tables.

**New tooling**:

- `bin/lint-design-system` — Ruby static analyzer that walks every view +
  helper + Stimulus controller + stylesheet and enforces the design-system
  contracts DS001–DS013. Wired into `bin/ci` (CI) and `bin/rubocop`
  (developer workflow). Only `:error` and `:warning` severities block.
- `bin/perf-baseline-capture` — captures `bin/measure-frontend-efficiency`
  output to `specs/011-comprehensive-ui-refactor/perf/` for regression
  detection.
- `lib/design_system/{lint,primitives,violation}.rb` — the design-system
  core. `DesignSystem::Primitives::Registry` is populated from a directory
  scan of `app/views/shared/_*.html.erb`, so the registry and the
  filesystem never drift.

**Token layer** (`app/assets/stylesheets/application.tailwind.css`):

- 8pt spacing scale (`--gap-xs/sm/md/lg/xl/2xl`)
- Brand-spec radii (`--radius`, `--radius-lg`, `--radius-full`)
- Container / measure / gutter variables
- `--ring` focus-ring token
- `--coin-*` payment-asset marks
- New `@utility` rules: `reward-text`, `focus-ring`, `scrollbar-thin`,
  `content-prose`

**Routes**:

- `GET /design-system` → `DesignSystemController#show` (development-only;
  production requests are redirected to `root_path` with status `:not_found`).

**Snapshots**:

- `docs/superpowers/specs/opendesign-011/` — frozen copy of the OpenDesign
  brand spec + 9 HTML prototypes + style.css. The live source-of-truth
  remains the OpenDesign project; the snapshot is for diffability.

### Layout refresh

- `app/views/layouts/admin.html.erb` — body class switched to design-system
  base (`min-h-screen bg-base-100 text-base-content`).
- `app/views/errors/{not_found,internal_server_error,not_acceptable,unprocessable_entity}.html.erb`
  — rewritten to use `render_state_empty` + `render_button` (serif display
  headline, neutral palette, accent CTA).
- `app/views/pages/fair.html.erb` — Stats page refactored: editorial
  header (`PLATFORM` eyebrow + serif headline + subhead), stat cards in
  `rounded-[14px]` containers, transfers list in a bordered section.
- `app/views/pages/rules.html.erb` — Long-form content page matched to
  the same header pattern; body wrapped in the existing `prose-article`
  utility.
- `app/views/transfers/stats.html.erb` — Stat cards refactored to use
  `render_value_note` + `bg-base-200` token; the six `bg-[#F4F4F4]`
  arbitrary-value cells (DS001 violations) are gone.
- New i18n keys (`ds_platform_label`, `ds_fair_subhead`,
  `ds_transfers_heading`, `ds_transfers_last_n`, `ds_rules_subhead`) in
  `config/locales/views.{en,ja,zh-CN}.yml`.

### Documented follow-up

The foundation is in place; mechanical migration of all 116 raw `<button
class="btn btn-*">` and 16 raw `<table>` occurrences across the rest of the
app is tracked as `DS005` / `DS007` violations by `bin/lint-design-system`.
Each is a single, well-defined refactor — see the lint output and
`specs/011-comprehensive-ui-refactor/contracts/lint-rules.md` for the
target. The design system entry point renders every primitive so the
migration destination is unambiguous.