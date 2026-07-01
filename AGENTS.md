# AGENTS.md

> Context for AI coding agents working in this repository.

## Project Overview

Quill is a Web3 paid-publishing platform ([quill.im](https://quill.im/)) where authors publish priced articles and readers pay to access them. Its distinguishing feature is **early reader rewards**: a share of each article's new revenue (default 40%) is distributed proportionally to readers who paid earlier. The stack is a Rails monolith with Hotwire (Turbo + Stimulus), ERB partials, PostgreSQL, Solid Cable, Solid Cache, and background jobs via Solid Queue (separate queue database). Integrations include Mixin Network (OAuth + Fennec login) and MixPay (cross-asset payment rail).

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Ruby | 4.0.5 (see `.ruby-version`, `mise.toml`) |
| Framework | Rails | 8.1.x |
| Database | PostgreSQL | — |
| Real-time | Solid Cable (separate `*_cable` DB) | — |
| Cache / jobs | Solid Cache, Solid Queue | — |
| Frontend | Turbo, Stimulus, Tailwind, esbuild | Node 20+, Bun 1.x |
| Testing | Minitest, Capybara | minitest ~> 6.0 (locked to 6.0.6) |
| Lint | RuboCop (rails-omakase), Prettier | — |
| Deploy | Kamal, Docker | manual `workflow_dispatch` |

## Architecture

Classic Rails MVC with namespaced controllers, route draws, service objects, and ActiveJob workers. Public site, author **dashboard**, **admin**, JSON **API**, and **grover** sub-apps share models but use separate controllers.

### Directory Structure

```
quill/
├── app/
│   ├── controllers/     # Web, dashboard, admin, api, grover
│   ├── models/          # ActiveRecord + concerns (AASM, etc.)
│   ├── views/           # ERB templates and partials
│   ├── helpers/         # View helpers (UiHelper for modal/dropdown wrappers)
│   ├── javascript/      # Stimulus controllers, esbuild entry
│   ├── jobs/            # Active Job work (orders, transfers)
│   ├── services/        # Query/command objects (e.g. ArticleSearchService)
│   ├── notifiers/       # Noticed 3 notifier classes + delivery_methods/
│   └── libs/            # Non-Rails Ruby helpers
├── config/
│   ├── routes/          # Route draws: admin, dashboard, api, grover
│   ├── settings/        # Config gem YAML (copy to settings.local.yml)
│   └── credentials/     # Encrypted secrets (Mixin bot, encryption keys)
├── db/migrate/          # Schema migrations
├── test/                # Minitest (models, controllers, jobs, notifiers)
└── .github/workflows/   # check.yml (CI), deploy.yml (Kamal)
```

## Development

### Setup

```bash
bundle install
bun install
EDITOR=vim bin/rails credentials:edit --development   # Mixin bot + AR encryption keys
cp config/settings.yml config/settings.local.yml       # edit host for local URL
bin/rails db:prepare
```

Requires PostgreSQL running locally (or via Docker). See `CONTRIBUTING.md` for credential field examples (note: README versions are authoritative over CONTRIBUTING's Ruby 3.2 note).

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

CI also runs `bin/rubocop` and `bun run lint-check`.

### Benchmarks

```bash
bin/benchmark                    # all hot-path scenarios (test fixtures)
bin/benchmark article_search     # filter by scenario name
```

See `test/benchmarks/README.md` for env vars and limitations. Stdlib-only; not run in CI.

### Lint

```bash
bin/rubocop
bun run lint-check          # Prettier check on app/javascript
bun run lint                # Prettier write
```

### Build assets (without bin/dev)

```bash
bun run build
bun run build:css
```

## Code Conventions

- **Frozen string**: `# frozen_string_literal: true` at top of Ruby files
- **Naming**: snake_case files/methods; PascalCase classes; `API::` namespace for API controllers
- **Models**: schema annotations via `annotaterb`; AASM `state` columns; counter caches
- **Services**: class with `.call` factory (see `ArticleSearchService`)
- **Views**: reusable UI in `app/views/**/_*.html.erb` partials; block/slot patterns via `UiHelper` (`render_modal`, `render_dropdown`, etc.)
- **Controllers**: concerns in `app/controllers/concerns/` (`Localizable`, `RenderingHelper`, `API::RenderingHelper`)
- **Routes**: partial routes in `config/routes/*.rb`, loaded via `draw :name` in `config/routes.rb`
- **JS**: Stimulus controllers in `app/javascript/controllers/`; entry `app/javascript/application.js`
- **Comments**: sparse; schema comments auto-generated on models

## Testing Conventions

- **Location**: `test/` mirrors `app/` (`test/models/`, `test/controllers/`, `test/jobs/`, `test/notifiers/`)
- **Naming**: `*_test.rb`; fixtures in `test/fixtures/`
- **Style**: Minitest
- **Env**: `RAILS_ENV=test`; CI uses Postgres service container

## Common Tasks

### Add a web route + controller action

1. Add route in `config/routes.rb` or appropriate `config/routes/*.rb` draw file
2. Implement action in `app/controllers/` (or namespaced submodule)
3. Add view or partial under `app/views/`
4. Add `test/controllers/..._test.rb` when behavior is non-trivial

### Add an API endpoint

1. Route under `config/routes/api.rb` inside `namespace :api`
2. Controller inheriting `API::BaseController` in `app/controllers/api/`
3. Auth via `HTTP_X_ACCESS_TOKEN` → `AccessToken` → `current_user`; call `authenticate_user!` when required
4. Use `API::RenderingHelper` JSON helpers; rescue patterns already in base controller

### Add a background job

1. Create `app/jobs/<namespace>/<name>_job.rb` inheriting `ApplicationJob`
2. Enqueue with `perform_later`; Solid Queue runs via `bin/jobs` (in `bin/dev` Procfile). Recurring tasks in `config/recurring.yml`; queues in `config/queue.yml`
3. Add `test/jobs/..._test.rb`

### Add a notifier (Noticed 3)

1. Create `app/notifiers/<name>_notifier.rb` inheriting `ApplicationNotifier`
2. Declare `required_param(s)` and wrap UI helpers (`message`, `url`, `icon_url`) in `notification_methods do ... end`
3. Configure delivery methods with blocks (`deliver_by :mixin_bot do |config| ... end`); database persistence is automatic — do **not** add `deliver_by :database`
4. Pass `record:` in `.with(record: model, ...)` when the notifier relates to an ActiveRecord object (enables `has_many :noticed_events, as: :record`)
5. Add translations under `config/locales/notifications.*.yml` at `notifiers.<notifier_name>.notification.*`
6. Add tests in `test/notifiers/`; use `NotifierHelpers#deliver_notifier!` and assert on `Noticed::Event` / `Noticed::Notification`

### Database migration

```bash
bin/rails generate migration DescriptiveName
bin/rails db:migrate
```

Re-run `annotaterb` in development if model annotations are stale.

### Testing improvements (local Cursor)

Run `/test-assist <instructions>` for focused test work. For a full run, `/test-improver` is self-contained: clean worktree, dedicated branch, round-robin tasks, memory committed in the run draft PR, monthly issue update, then return to your starting branch. State in `.cursor/test-improver/memory.md`; see `.cursor/skills/test-improver/SKILL.md`. Requires `gh auth login`.

### Performance improvements (local Cursor)

Run `/perf-assist <instructions>` for focused perf work. For a full run, `/perf-improver` is self-contained: clean worktree, dedicated branch, round-robin tasks, memory committed in the run draft PR, monthly issue update, then return to your starting branch. State in `.cursor/perf-improver/memory.md`; see `.cursor/skills/perf-improver/SKILL.md`. Requires `gh auth login`.

## Gotchas

- **Launch gate**: `ApplicationController#ensure_launched!` redirects to landing until `Settings.launch_time` passes (unless user is `accessable?`)
- **Revenue math**: Article defaults — 40% early readers, 10% platform, 50% author (`readers_revenue_ratio`, `platform_revenue_ratio`, `author_revenue_ratio`); changing splits affects `Order` distribution jobs
- **Paid content**: Article body often gated; API `show` omits content without valid access token
- **Secrets**: Never commit `config/master.key`, `config/settings.local.yml`, or credential values; Mixin bot keys live in encrypted credentials
- **Ruby 4 / minitest**: Gemfile pins `minitest ~> 6.0` (locked to `6.0.6`); Rails 8.1 test runner works on minitest 6 in this stack — bump together with Ruby upgrades.
- **CONTRIBUTING.md**: matches the README's Ruby 4.0.5 target; consult `.ruby-version` and `mise.toml` for the authoritative versions of Ruby, Bun, and Node
- **Deploy**: Production deploy is manual (`gh workflow run Deploy`); uses Kamal + Docker Hub image `anleework/quill`
- **Noticed 3**: Notifiers live in `app/notifiers/`, inherit `Noticed::Event` via `ApplicationNotifier`; user inbox uses `Noticed::Notification` (`User#notifications`). Web UI filters with `visible_in_web?` / `for_web` because DB records are always created (including Mixin-only delivery). Custom delivery: `DeliveryMethods::MixinBot`, `DeliveryMethods::FlashBroadcast`. Extend gem models in `config/initializers/noticed.rb`.
- **Solid Cable**: Real-time WebSocket backend uses a separate `cable` database (`config/database.yml`). Run `bin/rails db:prepare` to create/migrate all databases.
- **Solid Queue**: Jobs use a separate `queue` database (`config/database.yml`); admin dashboard at `/admin/jobs` (Mission Control). Run `bin/rails db:prepare` to create/migrate all databases.
