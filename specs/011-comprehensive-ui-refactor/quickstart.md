# Quickstart: Validate the Comprehensive UI Refactor

> Phase 1 of `/speckit.plan`. Runnable validation scenarios that prove the design system + every refactored surface works end-to-end. Use this to verify a fresh checkout, to gate a PR, and to onboard a new contributor.

## Prerequisites

- Ruby 4.0.5 (`rbenv install` or `mise install` — see `.ruby-version`, `mise.toml`)
- Node 20+, Bun 1.x
- PostgreSQL running locally (or via Docker)
- `bundle install` + `bun install` already run
- `bin/rails db:prepare` already run
- Dev credentials configured (`EDITOR=vim bin/rails credentials:edit --development` if first run)

## Setup commands

```bash
bundle install
bun install
cp config/settings.yml config/settings.local.yml 2>/dev/null || true
bin/rails db:prepare
bin/rails zeitwerk:check           # confirms autoloading sees the new constants
```

## Run the design system reference page

```bash
bin/dev                            # starts Rails + Solid Queue + esbuild
# Open http://localhost:3000/design-system
# Log in as Administrator) to see the page.
```

Expected: a single, server-rendered page with one section per primitive (Tokens, Type, Buttons, Chips, List Row, Cards, Forms, Tabs, Modal, Dropdown, Value Net, Notifications, States, Masthead, Page Shell). Every section renders a working example using the same partial the rest of the app uses.

## Run the lint check

```bash
bin/lint-design-system             # full check
bin/lint-design-system --phase a   # scope to current phase + earlier
```

Expected: exit code 0, no violations printed.

To check a refactor mid-progress:

```bash
bin/lint-design-system --phase b 2>&1 | tee /tmp/lint-b.log
wc -l /tmp/lint-b.log             # should be 0 lines for a clean phase
```

## Run the test suite

```bash
bin/rails test                                    # full suite
bin/rails test test/system/design_system_test.rb  # reachability
bin/rails test test/lib/design_system_lint_test.rb # lint enforcement
bin/rails zeitwerk:check                          # autoloading
```

Expected: all green. The design-system reachability test asserts every primitive renders on `/design-system`; the lint enforcement test asserts `DesignSystem::Lint.run` returns zero violations on `main`.

## Run the lint + style gates

```bash
bin/rubocop                       # Ruby style
bun run lint-check                # JS style
bin/rails zeitwerk:check           # autoloading
```

Expected: all green.

## Frontend efficiency baseline

```bash
bin/measure-frontend-efficiency   # bundle sizes, lazy-loading, listener-leak sweep
```

Compare before/after each phase:

```bash
git stash
bin/measure-frontend-efficiency > /tmp/perf-before.txt
git stash pop
bin/measure-frontend-efficiency > /tmp/perf-after.txt
diff /tmp/perf-before.txt /tmp/perf-after.txt
```

Expected: no individual metric regresses by more than 5%.

## Manual walkthrough — Public surfaces (Phase B)

1. Open `http://localhost:3000` — home feed.
2. Click an article — article reader.
3. Click an author name — author profile.
4. Open search from the masthead, type a query — search results.
5. Visit a collection — collection page.
6. Open the dark mode toggle — every page above must flip consistently without a flash.
7. Open `/404` and `/500` — error pages must use the design system.

Expected: every page renders the same masthead, the same column rhythm, the same typography ramp, the same chip styles. Dark mode is consistent everywhere.

## Manual walkthrough — Authoring surfaces (Phase C)

1. Log in as an author.
2. Open `http://localhost:3000/dashboard` — overview.
3. Navigate to Write, Read, Finances, Account — each renders the dashboard nav + stat cards + value-note figures.
4. Open `http://localhost:3000/articles/new` — article editor.
5. Toggle dark mode — every authoring surface flips consistently.

Expected: the editor uses the same tokens, primitives, and shells as the public surfaces. No bespoke Lexxy chrome colors leak through.

## Manual walkthrough — Admin / API / Errors / Notifications (Phase D)

1. Log in as an Administrator.
2. Open `http://localhost:3000/admin` — admin overview.
3. Visit a few admin destinations (Users, Articles, Payments) — confirm tables use the new `_table` primitive.
4. Trigger an API error (e.g. `curl -H 'X-Access-Token: invalid' http://localhost:3000/api/v1/articles/0`) — the JSON response uses the existing `API::RenderingHelper` shape; a browser hit on `/api/v1/articles/0` (or any HTML error path) renders the design-system error page.
5. Trigger a real-time notification (send yourself a notification from a notifier or via the rails console: `ApplicationNotifier.with(...).deliver_later(User.first)`) — the toast appears with `i-[tabler--alert-circle]` etc., matching the design-system state section.

Expected: every surface uses the design system; the notification inbox row and the real-time toast look identical.

## CI gating

`.github/workflows/check.yml` should include:

```yaml
- name: Lint design system
  run: bin/lint-design-system
```

If a PR violates a `DSxxx` rule, CI fails. The PR description should reference `contracts/lint-rules.md` and either (a) fix the violation, (b) update `contracts/primitives.md` / `contracts/tokens.md` to add the new pattern, or (c) update the allowlist in `lib/design_system/lint.rb` with a justifying comment.

## Acceptance gate

A PR is ready to merge when **all** of the following are true:

- [ ] `bin/rubocop` passes.
- [ ] `bun run lint-check` passes.
- [ ] `bin/rails zeitwerk:check` passes.
- [ ] `bin/rails test` passes (including `test/system/design_system_test.rb` and `test/lib/design_system_lint_test.rb`).
- [ ] `bin/lint-design-system` passes (exit code 0).
- [ ] `bin/measure-frontend-efficiency` shows no regression > 5% on any metric.
- [ ] Manual screenshot review of every touched surface in both light and dark mode is captured in the PR description.
- [ ] `CHANGELOG.md` and `AGENTS.md` are updated to reflect any new primitives or tokens.

## Onboarding a new contributor

When a new contributor joins, point them at:

1. `http://localhost:3000/design-system` — the live reference page.
2. `specs/011-comprehensive-ui-refactor/contracts/tokens.md` — the tokens.
3. `specs/011-comprehensive-ui-refactor/contracts/primitives.md` — the primitives.
4. `specs/011-comprehensive-ui-refactor/contracts/lint-rules.md` — the rules their code must follow.
5. `docs/superpowers/specs/2026-07-03-ui-redesign-design.md` — the approved design direction.

That is the entire onboarding ramp. No tribal knowledge required.