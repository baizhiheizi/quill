## Requirements

- Ruby v4.0.5 (see `.ruby-version` and `mise.toml` at the repo root)
- PostgreSQL
- Node.js 20+ and Bun 1.x

### Install Ruby

`mise` is recommended because the repository ships a `mise.toml` that pins both
Ruby and Bun.

```bash
# Using mise
mise install

# Or using rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
eval "$(rbenv init -)" >> ~/.bashrc
source ~/.bashrc

rbenv install 4.0.5
rbenv global 4.0.5
rbenv rehash

ruby -v    # should report 4.0.5
gem update --system
gem install bundler
```

For a fuller walkthrough see [docs/how-to/local-development.md](docs/how-to/local-development.md).

### Install Postgresql

If you're using Ubuntu

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql.service
```

## Clone repo

```bash
git clone git@github.com:baizhiheizi/quill.git
```

Install dependencies.

```bash
bundle install
bun install
```

## Prepare Config

```bash
EDITOR=vim bin/rails credentials:edit --development
```

It will promt up a config file for development envrionment. Here's a minimum example.

```yaml
# you should register a mixin bot first at https://developers.mixin.one/dashboard
quill_bot:
  client_id:
  client_secret:
  pin:
  session_id:
  pin_token:
  private_key:
# generate by `bin/rails db:encryption:init`
active_record_encryption:
  primary_key:
  deterministic_key:
  key_derivation_salt:
```

And setup another config file

```bash
mv ./config/settings.yml ./config/settings.local.yml
```

Generally you may just edit the `host` in the `settings.local.yml` to your local development url.

## Prepare DB

```bash
bin/rails db:prepare
```

## Bootup

```bash
bin/dev
```

If everything goes well. It'll boot up.

Check it at `http://localhost:3000`

## Others

### admin dashboard

The url is `http://localhost:3000/admin`. You may create an admin account in console.

```bash
bin/rails c
```

```ruby
Administrator.create name: 'admin', password: 'admin'
```

## Documentation

- New to the codebase? Read [docs/explanation/architecture.md](docs/explanation/architecture.md) and [docs/explanation/value-net.md](docs/explanation/value-net.md) before opening a pull request.
- The full Diátaxis-structured documentation lives under [`docs/`](docs/README.md).
- For agent-facing context, see [AGENTS.md](AGENTS.md) at the repository root.