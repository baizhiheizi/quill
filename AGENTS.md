# AGENTS.md

> Context for AI coding agents working in this repository.

## Project Overview

Quill is a Web3 paid-publishing platform ([quill.im](https://quill.im/)) where authors publish priced articles and readers pay to access them. Its distinguishing feature is **early reader rewards**: a share of each article's new revenue (default 40%) is distributed proportionally to readers who paid earlier.

Stack: Rails monolith with Hotwire (Turbo + Stimulus), ERB partials, PostgreSQL, Solid Cable, Solid Cache, and Solid Queue (separate queue database). Integrations: Mixin Network (OAuth) and MixPay (cross-asset payment rail).

## Tech Stack

| Layer | Stack |
|-------|-------|
| Language | Ruby 4.0.5 (see `.ruby-version`, `mise.toml`) |
| Framework | Rails 8.1.x |
| Database | PostgreSQL |
| Real-time | Solid Cable (separate `*_cable` DB) |
| Cache / jobs | Solid Cache + Solid Queue (separate queue DB) |
| Frontend | Turbo, Stimulus, Tailwind, esbuild (Node 20+, Bun 1.x) |
| Testing | Minitest ~> 6.0.6 + Capybara |
| Lint | RuboCop (rails-omakase), Prettier |
| Deploy | Kamal + Docker (manual `workflow_dispatch`) |

## Architecture

Five sub-apps share models but use separate controllers: public site, **dashboard**, **admin**, JSON **API**, and **grover**.

### Directory Structure

```
quill/
├── app/{controllers,models,views,helpers,javascript,jobs,services,notifiers,libs}
├── config/{routes,settings,credentials}/
├── db/migrate/
├── test/                # mirrors app/ (models, controllers, jobs, notifiers)
└── .github/workflows/   # check.yml (CI), deploy.yml (Kamal)
```

Notable: `UiHelper` (`render_modal`, `render_dropdown`); Noticed 3 notifiers in `app/notifiers/` plus `app/notifiers/delivery_methods/`; encrypted Mixin bot + AR encryption keys in `config/credentials/`.

## Development

### Setup

```bash
bundle install
bun install
EDITOR=vim bin/rails credentials:edit --development   # Mixin bot + AR encryption keys
cp config/settings.yml config/settings.local.yml       # edit host for local URL
bin/rails db:prepare
```

PostgreSQL required (locally or via Docker). For credential fields see `CONTRIBUTING.md` — its Ruby version is outdated; `.ruby-version` and `mise.toml` are authoritative.

### Run

```bash
bin/dev   # Procfile.dev: Rails, Solid Queue (bin/jobs), CSS/JS watch, mixin_blaze
```

App: `http://localhost:3000`. Admin: `http://localhost:3000/admin` (create `Administrator` in console).

### Test

```bash
bin/rails db:setup   # or db:prepare
bin/rails test
bin/rails zeitwerk:check
```

### Benchmarks & frontend efficiency

```bash
bin/benchmark article_search       # hot-path scenarios (filter by name)
bin/measure-frontend-efficiency    # bundle sizes, lazy-loading & motion coverage, listener-leak sweep
```

Both are stdlib-only and not run in CI. `measure-frontend-efficiency` gracefully reports `not built` / `null` when `app/assets/builds/` or `node_modules/` are absent; see `test/benchmarks/README.md` for env vars and limitations.

### Lint & build assets

```bash
bin/rubocop
bin/lint-design-system      # design-system contracts (DS001..DS013)
bun run lint-check          # Prettier check on app/javascript
bun run lint                # Prettier write
bun run build               # one-off asset build
bun run build:css
```

`bin/rubocop`, `bin/lint-design-system`, and `bun run lint-check` also run in CI.

### Design system

Every view, partial, and Stimulus controller in Quill consumes one in-app
design system. The single source-of-truth is:

- **`/design-system`** — in-app reference page (`DesignSystemController#show`),
  development-only. Production requests to the route get a generic 404 redirect
  to `root_path`; the page is internal documentation, not a public surface.
- **`app/views/shared/_*.html.erb`** — every primitive lives here as an ERB
  partial; each has a thin wrapper in `UiHelper` (`render_button`,
  `render_chip`, `render_list_row`, `render_value_note`,
  `render_notification_card`, `render_skeleton`, `render_state_empty`,
  `render_table`, `render_modal`, `render_dropdown`, `ui_input`, `ui_card`).
- **`app/assets/stylesheets/application.tailwind.css`** — the token layer
  (color, type, radius, spacing). No view should declare a new hex literal;
  register it in the token layer and consume it via Tailwind utilities.
- **`specs/011-comprehensive-ui-refactor/contracts/`** — the written
  contracts each primitive must satisfy.
- **`bin/lint-design-system`** — enforces DS001..DS013; CI fails on any
  blocking violation.

## Code Conventions

- **Ruby**: `# frozen_string_literal: true` at top of files; snake_case files/methods, PascalCase classes, `API::` namespace for API controllers; schema annotations via `annotaterb` with AASM `state` columns and counter caches on models.
- **Services**: class with `.call` factory (see `ArticleSearchService`).
- **Views**: reusable UI in `app/views/**/_*.html.erb` partials; block/slot patterns via `UiHelper` (`render_modal`, `render_dropdown`, etc.).
- **Controllers**: concerns in `app/controllers/concerns/` (`Localizable`, `RenderingHelper`, `API::RenderingHelper`).
- **Routes**: partials in `config/routes/*.rb`, loaded via `draw :name` in `config/routes.rb`.
- **JS**: Stimulus controllers in `app/javascript/controllers/`; entry `app/javascript/application.js`.
- **Comments**: sparse; schema comments auto-generated on models.

## UI/UX Skills

This project is a **server-rendered Rails web app** (Turbo, Stimulus, Tailwind, ERB). Two UI/UX skills are installed but target different platforms:

| When to use | Skill | Scope |
|---|---|---|
| **Web UI review, accessibility audit, or web interface compliance** | `web-design-guidelines` | Desktop/web — matches this project's stack |
| **Mobile-app design system generation** (colors, typography, chart selection, UX patterns) | `ui-ux-pro-max` | Mobile/React-Native-oriented design intelligence DB — **do not use its stack-specific steps or checklist for this Rails web project** |

**Routing rule:** For any UI review, accessibility check, or web UX work in this repository, use `web-design-guidelines`. The `ui-ux-pro-max` skill provides platform-agnostic design-system data (color palettes, font pairings, UX guidelines) that may supplement design decisions, but its stack examples (`react-native-vector-icons`, `hitSlop`, `safe-area`, bottom tab bars) do not apply to this web stack.

## Testing Conventions

`test/` mirrors `app/` (models, controllers, jobs, notifiers). Tests use `*_test.rb` names with fixtures in `test/fixtures/`, run under Minitest with `RAILS_ENV=test`; CI runs against a Postgres service container.

## Common Tasks

### Add a web route + controller action

1. Add route in `config/routes.rb` (or a draw file in `config/routes/`)
2. Implement action in `app/controllers/` (or namespaced submodule) plus view/partial in `app/views/`
3. Add `test/controllers/..._test.rb` when behavior is non-trivial

### Add an API endpoint

1. Route under `config/routes/api.rb` inside `namespace :api`; controller inheriting `API::BaseController` in `app/controllers/api/`
2. Auth via `HTTP_X_ACCESS_TOKEN` (call `authenticate_user!` when required); use `API::RenderingHelper` JSON helpers (rescue patterns already in base controller)

### Add a background job

1. Create `app/jobs/<namespace>/<name>_job.rb` inheriting `ApplicationJob`
2. Enqueue with `perform_later`. Solid Queue runs via `bin/jobs` (in `bin/dev`'s Procfile); recurring tasks in `config/recurring.yml`, queues in `config/queue.yml`
3. Add `test/jobs/..._test.rb`

### Add a notifier (Noticed 3)

1. Create `app/notifiers/<name>_notifier.rb` inheriting `ApplicationNotifier`; declare `required_param(s)` and wrap UI helpers (`message`, `url`, `icon_url`) in `notification_methods do ... end`
2. Configure delivery methods with blocks (`deliver_by :mixin_bot do |config| ... end`). Database persistence is automatic — do **not** add `deliver_by :database`
3. Pass `record:` in `.with(record: model, ...)` when the notifier relates to an ActiveRecord object (enables `has_many :noticed_events, as: :record`)
4. Add translations under `config/locales/notifications.*.yml` at `notifiers.<notifier_name>.notification.*` and tests in `test/notifiers/`; use `NotifierHelpers#deliver_notifier!` and assert on `Noticed::Event` / `Noticed::Notification`

### Database migration

```bash
bin/rails generate migration DescriptiveName
bin/rails db:migrate
```

Re-run `annotaterb` in development if model annotations are stale.

### Cursor agents (local)

Each domain has a focused assistant and a self-contained full runner. The full runner spins up a clean worktree, dedicates a branch, round-robins tasks, commits memory in the run draft PR, updates the monthly issue, and returns to your starting branch.

| Domain | Focused | Full runner | Memory |
|---|---|---|---|
| Tests | `/test-assist <instructions>` | `/test-improver` | `.cursor/test-improver/memory.md` (see `.cursor/skills/test-improver/SKILL.md`) |
| Perf | `/perf-assist <instructions>` | `/perf-improver` | `.cursor/perf-improver/memory.md` (see `.cursor/skills/perf-improver/SKILL.md`) |

Both require `gh auth login`.

## Gotchas

- **Access control**: `ApplicationController#ensure_launched!` redirects to landing until `Settings.launch_time` passes (unless `accessable?`); paid-article bodies (API `show`) are gated without a valid access token.
- **Revenue math**: Article defaults — 40% early readers, 10% platform, 50% author (`readers_revenue_ratio`, `platform_revenue_ratio`, `author_revenue_ratio`); changing splits affects `Order` distribution jobs.
- **Secrets**: Never commit `config/master.key`, `config/settings.local.yml`, or credential values; Mixin bot keys live in encrypted credentials.
- **Ruby 4 / minitest**: Gemfile pins `minitest ~> 6.0` (locked `6.0.6`); bump with Ruby upgrades. Consult `.ruby-version`/`mise.toml` for authoritative Ruby/Bun/Node versions; `CONTRIBUTING.md` lags behind.
- **Deploy**: Production deploy is manual (`gh workflow run Deploy`); uses Kamal + Docker Hub image `anleework/quill`.
- **Noticed 3**: Notifiers in `app/notifiers/` inherit via `ApplicationNotifier`; user inbox uses `Noticed::Notification` (`User#notifications`). Web UI filters with `visible_in_web?` / `for_web` since DB records always exist. Custom delivery in `DeliveryMethods::{MixinBot, FlashBroadcast}`; gem extensions in `config/initializers/noticed.rb`.
- **Solid Cable / Solid Queue**: Solid Cable backs the WebSocket layer; Solid Queue runs jobs (admin at `/admin/jobs`, Mission Control). Both use separate databases (`config/database.yml`) — `bin/rails db:prepare` creates and migrates all of them.
