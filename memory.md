---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 30396031882 on 2026-07-28 20:34 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). `AGENTS.md` exists.
- Six open issues are automation/system-managed; all are labelled. No human issue required a comment or fix. Monthly issue: #1789.
- GitHub read-only state showed no open PRs at the start of this run. Dependabot #1965 and the 2026-07-27 Repo Assist changes are merged on main.
- **Current draft PR intents**:
  1. `repo-assist/improve-currency-btc-method-2026-07-28` — makes `Currency.btc` an explicit class method and tests the nil contract.
  2. `repo-assist/eng-ci-install-reliability-2026-07-28` — uses retryable/parallel Bundler installation and frozen Bun lockfiles in CI.

## This run

- Selected tasks: Task 3 (Issue Fix), Task 5 (Coding Improvements), Task 4 (Engineering Investments), plus Task 11.
- Task 3 was not applicable because all open issues are generated and labelled; Task 2 fallback found no human issue requiring a comment.
- Task 5 PR intent: class-method API clarification for `Currency.btc`; no dependency or migration changes.
- Task 4 PR intent: `.github/workflows/check.yml` install reliability and lockfile enforcement.
- Task 11 rewrote #1789 in the required July format and removed actions for merged work.

## Backlog

- Monitor maintainer review of the two 2026-07-28 draft PR intents.
- Keep #1824 performance, #1801 testing, and #1817 efficiency backlog items in the monthly suggested-actions list until closed or acknowledged.
- Respect the payment/Web3 resilience cooldown and avoid duplicating merged performance/testing work.

## Test and workflow notes

- `bin/rubocop` and `bin/rails zeitwerk:check` pass locally.
- PostgreSQL is unavailable in this runner; focused Rails tests fail before execution with network-unreachable at the configured database address.
- Bun is unavailable; `bun run lint-check` fails with command-not-found and full Rails test preparation stops in cssbundling-rails.
- `bundle check` passes. CI workflow YAML parses successfully with Ruby Psych.
- Minitest 6 removed `Object#stub`; use `define_singleton_method` with `ensure`. `Currency#save` raises in test env; use in-memory `Currency.new` where applicable.
- When safeoutputs PR creation succeeds but no visible PR appears, preserve the branch commit and bundle for maintainer revival. Safeoutputs CLI payloads should be written to `/tmp/gh-aw/agent/` when markdown contains apostrophes/backticks.
