---
runtimes:
  ruby:
    version: "4.0.5"
  bun:
    version: "1.3.14"

env:
  DATABASE_HOST: host.docker.internal
  REDIS_URL: redis://host.docker.internal:6379/0
  RAILS_ENV: test

# NOTE: workflows importing this file must declare in their own frontmatter:
#   sandbox:
#     agent:
#       runtime: docker-sudo-iptables
# (the sandbox block is not merged from imports, but is required for the
# published postgres port below to be reachable from the sandboxed agent)

services:
  postgres:
    image: pgvector/pgvector:pg16-trixie
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - 5432:5432
    options: >-
      --health-cmd="pg_isready -U postgres"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=5

pre-agent-steps:
  - name: Install Ruby gems
    run: bundle install --jobs 4 --retry 3

  - name: Install node modules
    run: bun install --frozen-lockfile

  - name: Set up database schema
    run: DATABASE_HOST=localhost bin/rails db:prepare
---
