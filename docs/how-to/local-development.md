# Set up local development

> **30-second summary:** Install Ruby 4.0.5 (via `mise` or `rbenv`), PostgreSQL, and Bun 1.x. Copy `config/settings.yml` to `config/settings.local.yml`, edit credentials with `bin/rails credentials:edit --development`, then run `bin/dev` to boot the app on `http://localhost:3000`.

Fresh Linux or macOS only. Authoritative sources are [AGENTS.md](../../AGENTS.md) and [README](../../README.md); update this page if you fix a step.

## 1. Install system dependencies

### Ruby 4.0.5

Quill pins Ruby in `.ruby-version` and `mise.toml`; install via either:

```bash
# Using mise (recommended)
mise install

# Or using rbenv
rbenv install 4.0.5
rbenv global 4.0.5
```

### PostgreSQL

PostgreSQL for app data; Solid Queue / Cable / Cache use separate SQLite files under `storage/`. All are migrated by `bin/rails db:prepare` (run in §4).

```bash
# Ubuntu
sudo apt update
sudo apt install -y postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql.service

# macOS (Homebrew)
brew install postgresql
brew services start postgresql

# Create a role that can create databases (either platform):
sudo -u postgres createuser -s quill && sudo -u postgres createdb -O quill quill_development
```

### Bun 1.x

`esbuild` bundles JavaScript and Tailwind CSS via Bun (no separate Node install needed):

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

Secrets live in encrypted credentials; non-secret config in YAML. Edit development credentials with:

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

Then copy the settings file and set `host` to your local URL (`https://quill.im` → `http://localhost:3000` for local work):

```bash
cp config/settings.yml config/settings.local.yml
```

## 4. Run and verify

```bash
bin/rails db:prepare
bin/dev
```

`db:prepare` creates and migrates the primary database plus the Solid Queue/Cable/Cache SQLite files. `bin/dev` reads `Procfile.dev` and starts Rails on <http://localhost:3000> (admin at `/admin`), `bin/jobs`, the CSS/JS watchers, and the Mixin blaze client when `blaze_enable: true` in `settings.local.yml`.

```ruby
# Create the admin account from bin/rails console:
Administrator.create name: 'admin', password: 'admin'
```

Then match what CI runs:

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
- **Solid Queue backlogs piling up** — confirm `bin/jobs` is running (it is part of `bin/dev`); use `bin/rails solid_queue:start` to run it standalone.

## Next steps

Read [Explanation → Architecture](../explanation/architecture.md) for the subsystems you just brought up, or [Reference → Services](../reference/services.md) to map them to code. Spotted a wrong step? File a `documentation`-labelled issue.