#!/usr/bin/env bash
# exit on error
set -o errexit

yarn install
bundle install
bundle exec bin/rails assets:precompile
# bundle exec rake db:migrate
