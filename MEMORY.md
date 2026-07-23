# Test Improver Memory

- [Run notes 2026-07-23](2026-07-23-notes.md) — Dashboard ArticlesController tests (9 tests), Monthly Activity updated
- [Run notes 2026-07-22](2026-07-22-notes.md) — Dashboard PaymentsController + TransfersController tests (11 tests), Monthly Activity updated

## Discovered Commands

- Tests: `SKIP_CSS_BUILD=1 bin/rails test` (Minitest 6.0.6). CSS build: `npx tailwindcss -i ...`.
- Coverage: `COVERAGE=1 bin/rails test` (SimpleCov wired, gated by ENV var).
- Lint: `bin/rubocop`, `bun run lint-check`. Zeitwerk: `bin/rails zeitwerk:check`.
- DB: `bin/rails db:prepare` (main + cable + queue). CI: `bin/ci`.

## Testing Gotchas

See `test/TESTING_GUIDE.md` for the consolidated reference (~40 gotchas). Key gotcha since guide creation:
- SimpleCov available via `COVERAGE=1` env var (zero CI burden otherwise).

## Backlog

**Model coverage**: 22 non-trivial models covered. **Testing guide**: merged. **SimpleCov**: implemented.
**Controller coverage in progress**:
- ✅ Dashboard: Home, Orders, Comments, Notifications, Payments, Transfers, Articles (10 of 25 tested)
- ❌ 15 untested dashboard controllers (collections, subscriptions, profile settings, block_users, etc.)
- ❌ Controller concerns (AdvisoryLockable, RichTextContent, Localizable)

**Known issues**:
- Bonus AASM — blocked by table-name bug
- ArticleSnapshot#previous_signed_snapshot — broken code (undefined `signed` scope)
- Splitter#collect_assets — zero callers
- Dashboard::ArticlesController#show — nil @article not guarded (template crash on invalid UUID)

## Last Run

2026-07-23 — Dashboard ArticlesController tests (9 tests). Monthly Activity updated.
