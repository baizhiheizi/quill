# Test Improver memory

> Persistent state for local `/test-assist` and `/test-improver` runs.
> Do not store secrets. Verify against `gh` and the repo before acting on stale entries.
>
> **Full `/test-improver` runs:** memory updates must be committed on the run branch and included in the draft PR for that run (including memory-only runs).

## build/test/coverage commands

Validated against `AGENTS.md`, `config/ci.rb`, and `.github/workflows/check.yml`.

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI locally | `bin/ci` | setup, rubocop, `bun run lint-check`, `bin/rails test`, `db:seed:replant` |
| Tests | `bin/rails test` | Minitest; `test/` mirrors `app/`; requires PostgreSQL |
| System tests | `bin/rails test:system` | Optional; commented out in CI |
| Zeitwerk | `bin/rails zeitwerk:check` | Also run in CI |
| Ruby lint | `bin/rubocop` | |
| JS lint | `bun run lint-check` | Prettier check on `app/javascript` |
| DB prep | `bin/rails db:prepare` | main + cable + queue databases |

**Coverage:** No SimpleCov, Codecov, or Coveralls in CI. Measure impact via targeted `bin/rails test` runs unless tooling is added.

**Framework:** Minitest + fixtures in `test/fixtures/`; Capybara for system tests per AGENTS.md.

**Quirks:** PostgreSQL required; `RAILS_ENV=test` for tests.

## testing notes

_(Brief patterns, helpers, and lessons learned in this repo.)_

## maintainer priorities

_(Quotes or summaries from maintainer comments on issues, PRs, or discussions.)_

## testing backlog

_(Prioritized opportunities: impact, area, suggested approach.)_

## backlog cursor

_(Issue/area index for Task 2 and Task 5 rotation.)_

## work in progress

_(Current branch, goal, coverage notes.)_

## completed work

_(PR numbers, outcomes, coverage deltas.)_

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | — |
| 2 | — |
| 3 | — |
| 4 | — |
| 5 | — |
| 6 | — |
| 7 | — |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
