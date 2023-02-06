## Requirements

- Ruby v3.2
- Postgresql

### Install Ruby

[rbenv](https://github.com/rbenv/rbenv) is recommended to used for managing Ruby installation.

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
echo 'source ~/.bashrc' >> ~/.bash_profile
source ~/.bash_profile

rbenv install 3.2.0
rbenv global 3.2.0
rbenv rehash

ruby -v
gem update --system
gem install bundler
```

### Install Postgresql

If you're using Ubuntu

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql.service
```

### Install Redis

Check it up at https://redis.io/docs/getting-started/installation/

## Clone repo

```bash
git clone git@github.com:baizhiheizi/quill.git
```

Install dependencies.

```bash
bundle install
yarn install
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
  pin_code:
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
