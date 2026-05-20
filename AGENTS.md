# AGENTS.md

> Context for AI coding agents working in this repository.

## Project Overview

Quill is a Web3 paid-publishing platform ([quill.im](https://quill.im/)) where authors publish priced articles and readers pay to access them. Its distinguishing feature is **early reader rewards**: a share of each article's new revenue (default 40%) is distributed proportionally to readers who paid earlier. The stack is a Rails monolith with Hotwire (Turbo + Stimulus), ViewComponents, PostgreSQL, Redis, and background jobs via Good Job. Integrations include Mixin Network, MVM (Ethereum L2), MixPay, Arweave permanence, and wallet login (MetaMask, Coinbase, WalletConnect).

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Ruby | 4.0.5 (see `.ruby-version`, `mise.toml`) |
| Framework | Rails | 8.1.x |
| Database | PostgreSQL | — |
| Cache / jobs | Redis, Solid Cache, Good Job | — |
| Frontend | Turbo, Stimulus, Tailwind, esbuild | Node 20+, Yarn 1.x |
| Components | ViewComponent | 4.x |
| Testing | Minitest, Capybara | minitest ~> 5.25 (Ruby 4 compat) |
| Lint | RuboCop (rails-omakase), Prettier | — |
| Deploy | Kamal, Docker | manual `workflow_dispatch` |

## Architecture

Classic Rails MVC with namespaced controllers, route draws, service objects, and ActiveJob workers. Public site, author **dashboard**, **admin**, JSON **API**, and **mvm**/**grover** sub-apps share models but use separate controllers.

### Directory Structure

```
quill/
├── app/
│   ├── controllers/     # Web, dashboard, admin, api, mvm, grover
│   ├── models/          # ActiveRecord + concerns (AASM, Arweave, etc.)
│   ├── components/      # ViewComponent UI (Ruby + optional templates)
│   ├── views/           # ERB templates
│   ├── javascript/      # Stimulus controllers, MVM wallet TS, esbuild entry
│   ├── jobs/            # Good Job background work (orders, transfers, arweave)
│   ├── services/        # Query/command objects (e.g. ArticleSearchService)
│   ├── notifications/   # Noticed notification classes
│   └── libs/            # Non-Rails Ruby helpers
├── config/
│   ├── routes/          # Route draws: admin, dashboard, api, mvm, grover
│   ├── settings/        # Config gem YAML (copy to settings.local.yml)
│   └── credentials/     # Encrypted secrets (Mixin bot, encryption keys)
├── db/migrate/          # Schema migrations
├── test/                # Minitest (models, controllers, jobs, components)
└── .github/workflows/   # check.yml (CI), deploy.yml (Kamal)
```

## Development

### Setup

```bash
bundle install
yarn install
EDITOR=vim bin/rails credentials:edit --development   # Mixin bot + AR encryption keys
cp config/settings.yml config/settings.local.yml       # edit host for local URL
bin/rails db:prepare
```

Requires PostgreSQL and Redis running locally (or via Docker). See `CONTRIBUTING.md` for credential field examples (note: README versions are authoritative over CONTRIBUTING's Ruby 3.2 note).

### Run

```bash
bin/dev   # Procfile.dev: Rails, Good Job, CSS/JS watch, mixin_blaze
```

App: `http://localhost:3000`. Admin: `http://localhost:3000/admin` (create `Administrator` in console).

### Test

```bash
bin/rails db:setup   # or db:prepare
bin/rails test
bin/rails zeitwerk:check
```

CI also runs `bin/rubocop` and `yarn lint-check`.

### Lint

```bash
bin/rubocop
yarn lint-check          # Prettier check on app/javascript
yarn lint                # Prettier write
```

### Build assets (without bin/dev)

```bash
yarn build
yarn build:css
```

## Code Conventions

- **Frozen string**: `# frozen_string_literal: true` at top of Ruby files
- **Naming**: snake_case files/methods; PascalCase classes; `API::` namespace for API controllers
- **Models**: schema annotations via `annotaterb`; AASM `state` columns; counter caches; `second_level_cache` on hot reads
- **Services**: class with `.call` factory (see `ArticleSearchService`)
- **Components**: inherit `ApplicationComponent`; ViewComponent 4 uses explicit `initialize(*_args, **_kwargs)` in base
- **Controllers**: concerns in `app/controllers/concerns/` (`Localizable`, `RenderingHelper`, `API::RenderingHelper`)
- **Routes**: partial routes in `config/routes/*.rb`, loaded via `draw :name` in `config/routes.rb`
- **JS**: Stimulus controllers in `app/javascript/controllers/`; TypeScript in `app/javascript/mvm/`; entry `app/javascript/application.js`
- **Comments**: sparse; schema comments auto-generated on models

## Testing Conventions

- **Location**: `test/` mirrors `app/` (`test/models/`, `test/controllers/`, `test/jobs/`, `test/components/`)
- **Naming**: `*_test.rb`; fixtures in `test/fixtures/`
- **Style**: Minitest; many component tests are placeholder skips
- **Env**: `RAILS_ENV=test`; CI uses Postgres + Redis service containers

## Common Tasks

### Add a web route + controller action

1. Add route in `config/routes.rb` or appropriate `config/routes/*.rb` draw file
2. Implement action in `app/controllers/` (or namespaced submodule)
3. Add view under `app/views/` or ViewComponent under `app/components/`
4. Add `test/controllers/..._test.rb` when behavior is non-trivial

### Add an API endpoint

1. Route under `config/routes/api.rb` inside `namespace :api`
2. Controller inheriting `API::BaseController` in `app/controllers/api/`
3. Auth via `HTTP_X_ACCESS_TOKEN` → `AccessToken` → `current_user`; call `authenticate_user!` when required
4. Use `API::RenderingHelper` JSON helpers; rescue patterns already in base controller

### Add a background job

1. Create `app/jobs/<namespace>/<name>_job.rb` inheriting `ApplicationJob`
2. Enqueue with `perform_later`; Good Job runs via `bundle exec good_job start` (in `bin/dev`)
3. Add `test/jobs/..._test.rb`

### Database migration

```bash
bin/rails generate migration DescriptiveName
bin/rails db:migrate
```

Re-run `annotaterb` in development if model annotations are stale.

## Gotchas

- **Launch gate**: `ApplicationController#ensure_launched!` redirects to landing until `Settings.launch_time` passes (unless user is `accessable?`)
- **Revenue math**: Article defaults — 40% early readers, 10% platform, 50% author (`readers_revenue_ratio`, `platform_revenue_ratio`, `author_revenue_ratio`); changing splits affects `Order` distribution jobs
- **Paid content**: Article body often gated; API `show` omits content without valid access token
- **Secrets**: Never commit `config/master.key`, `config/settings.local.yml`, or credential values; Mixin bot keys live in encrypted credentials
- **Ruby 4 / minitest**: Gemfile pins `minitest ~> 5.25` — Rails 8.1 test runner breaks on minitest 6
- **ViewComponent 4**: Subclass `initialize` must call `super()`; base accepts and discards args
- **CONTRIBUTING.md** lists Ruby 3.2; project actually targets Ruby 4.0.5 per README and `.ruby-version`
- **Deploy**: Production deploy is manual (`gh workflow run Deploy`); uses Kamal + Docker Hub image `anleework/quill`
