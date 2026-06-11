# Set up local development

> **30-second summary:** Install Ruby 4.0.5 (via `mise` or `rbenv`), PostgreSQL, and Bun 1.x. Copy `config/settings.yml` to `config/settings.local.yml`, edit credentials with `bin/rails credentials:edit --development`, then run `bin/dev` to boot the app on `http://localhost:3000`.

This guide assumes a fresh Linux or macOS machine. If anything here drifts, the authoritative source is the [AGENTS.md](../../AGENTS.md) and the [README](../../README.md) at the repository root — please update this page when you fix a step.

## 1. Install system dependencies

### Ruby 4.0.5

Quill pins the Ruby version in `.ruby-version` and `mise.toml`. Either of the following works:

```bash
# Using mise (recommended)
mise install

# Or using rbenv
rbenv install 4.0.5
rbenv global 4.0.5
```

Verify with `ruby -v`. You should see `ruby 4.0.5`.

### PostgreSQL

PostgreSQL is required for both the primary database and the Solid Queue/Cable/Cache database.

```bash
# Ubuntu
sudo apt update
sudo apt install -y postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql.service

# macOS (Homebrew)
brew install postgresql
brew services start postgresql
```

Create a Postgres role that can create databases, e.g.:

```bash
sudo -u postgres createuser -s quill
sudo -u postgres createdb -O quill quill_development
```

### Node.js 18+ and Bun 1.x

`esbuild` bundles the JavaScript and Tailwind CSS, both of which Bun orchestrates.

```bash
# Bun (provides its own Node runtime)
curl -fsSL https://bun.sh/install | bash
```

## 2. Clone and bootstrap

```bash
git clone git@github.com:baizhiheizi/quill.git
cd quill
bundle install
bun install
```

## 3. Configure credentials

Quill uses Rails encrypted credentials for secrets and a YAML file for non-secret config.

```bash
EDITOR=vim bin/rails credentials:edit --development
```

A minimal development credentials file looks like:

```yaml
# Register a Mixin bot at https://developers.mixin.one/dashboard first.
quill_bot:
  client_id:
  client_secret:
  pin:
  session_id:
  pin_token:
  private_key:

# Generate with: bin/rails db:encryption:init
active_record_encryption:
  primary_key:
  deterministic_key:
  key_derivation_salt:
```

Copy the non-secret settings:

```bash
cp config/settings.yml config/settings.local.yml
```

Edit `host` in `config/settings.local.yml` to match the URL you reach the app from (default `https://quill.im`; for local work use `http://localhost:3000`).

## 4. Prepare the database

```bash
bin/rails db:prepare
```

This creates both the primary database and the Solid Queue/Cable/Cache database, then runs migrations.

## 5. Boot the app

```bash
bin/dev
```

`bin/dev` reads `Procfile.dev` and starts:

- the Rails server
- the Solid Queue worker (`bin/jobs`)
- the CSS and JS watchers (esbuild + Tailwind)
- the Mixin blaze client (when `blaze_enable: true` in `settings.local.yml`)

App: [http://localhost:3000](http://localhost:3000)
Admin: [http://localhost:3000/admin](http://localhost:3000/admin)

To create an admin account:

```bash
bin/rails console
```

```ruby
Administrator.create name: 'admin', password: 'admin'
```

## 6. Verify with the test suite

```bash
bin/rails test
bin/rails zeitwerk:check
```

CI also runs `bin/rubocop` and `bun run lint-check`. Run those locally before opening a pull request.

## Troubleshooting

- **"quill_bot credentials missing"** — re-open `bin/rails credentials:edit --development` and fill in the `quill_bot.*` keys.
- **"PG::ConnectionBad"** — confirm PostgreSQL is running and that your `config/database.yml` user can create databases.
- **"Cannot find module 'tailwindcss'"** — re-run `bun install`.
- **Solid Queue backlogs piling up** — confirm `bin/jobs` is running (it is part of `bin/dev`). Check `bin/rails solid_queue:start` if you want to run it standalone.

## Next steps

- Read [Explanation → Architecture](../explanation/architecture.md) for the subsystems you just brought up.
- Skim [Reference → Services](../reference/services.md) to find the code that wires the request flow.
- Open an issue with the `documentation` label if any step is wrong or unclear.