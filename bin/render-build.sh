#!/usr/bin/env bash
# exit on error
set -o errexit

cp config/credentials/main.yml.enc config/credentials.yml.enc
cp config/settings.main.example.yml config/settings.yml
yarn install
bundle install
# bundle exec rake db:migrate
