# Set up local development

> **30-second summary:** Install Ruby 4.0.5 (via `mise` or `rbenv`), PostgreSQL, and Bun 1.x. Copy `config/settings.yml` to `config/settings.local.yml`, edit credentials with `bin/rails credentials:edit --development`, then run `bin/dev` to boot the app on `http://localhost:3000`.

This guide assumes a fresh Linux or macOS machine. The authoritative sources are [AGENTS.md](../../AGENTS.md) and [README](../../README.md) at the repository root — update this page when you fix a step.

## 1. Install system dependencies

### Ruby 4.0.5

Quill pins Ruby in `.ruby-version` and `mise.toml`. Use either:

```bash
# Using mise (recommended)
mise install

# Or using rbenv
rbenv install 4.0.5
rbenv global 4.0.5
```

### PostgreSQL

PostgreSQL is required for the **primary** database only — Solid Queue/Cable/Cache each use their own SQLite file under `storage/`, created and migrated by `bin/rails db:prepare`.

```bash
# Ubuntu
sudo apt update
sudo apt install -y postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql.service

# macOS (Homebrew)
brew install postgresql
brew services start postgresql

# Then on either platform, create a role that can create databases:
sudo -u postgres createuser -s quill && sudo -u postgres createdb -O quill quill_development
```

### Node.js 18+ and Bun 1.x

`esbuild` bundles JavaScript and Tailwind CSS via Bun (which ships its own Node runtime, so no separate Node install):

```bash
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

Quill uses Rails encrypted credentials for secrets and a YAML file for non-secret config. Edit development credentials with:

```bash
EDITOR=vim bin/rails credentials:edit --development
```

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

Then copy the non-secret settings and edit `host` in `config/settings.local.yml` to match your local URL (default `https://quill.im`; for local work use `http://localhost:3000`):

```bash
cp config/settings.yml config/settings.local.yml
```

## 4. Run, verify, and troubleshoot

```bash
bin/rails db:prepare
bin/dev
```

`db:prepare` creates and migrates the primary database and the Solid Queue/Cable/Cache database. `bin/dev` reads `Procfile.dev` and starts Rails on [http://localhost:3000](http://localhost:3000) (admin at [/admin](http://localhost:3000/admin)), the Solid Queue worker (`bin/jobs`), the CSS/JS watchers (esbuild + Tailwind), and — when `blaze_enable: true` in `settings.local.yml` — the Mixin blaze client.

```ruby
# Create the admin account from bin/rails console:
Administrator.create name: 'admin', password: 'admin'
```

Then verify with the test suite — CI also runs `bin/rubocop` and `bun run lint-check`, so run them locally too:

```bash
bin/rails test
bin/rails zeitwerk:check
bin/rubocop
bun run lint-check
```

## Troubleshooting

- **"quill_bot credentials missing"** — re-open `bin/rails credentials:edit --development` and fill in the `quill_bot.*` keys.
- **"PG::ConnectionBad"** — confirm PostgreSQL is running and that your `config/database.yml` user can create databases.
- **"Cannot find module 'tailwindcss'"** — re-run `bun install`.
- **Solid Queue backlogs piling up** — confirm `bin/jobs` is running (it is part of `bin/dev`). Check `bin/rails solid_queue:start` if you want to run it standalone.

## Next steps

- Read [Explanation → Architecture](../explanation/architecture.md) for the subsystems you just brought up.
- Skim [Reference → Services](../reference/services.md) to find the code that wires the request flow.
- Open an issue with the `documentation` label if any step is wrong or unclear.