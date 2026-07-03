# Quickstart: Cross-Locale Article Visibility

**Feature**: Cross-Locale Article Visibility
**Spec**: `specs/001-unified-article-translations/spec.md`
**Date**: 2026-07-03

This document describes how to **validate** that the feature works end-to-end after implementation. It does **not** include implementation code — that lives in tasks.md and the implementation phase.

## Prerequisites

- Ruby 4.0.5, Rails 8.1.x (per AGENTS.md)
- PostgreSQL running (or via Docker)
- Local credentials for development (Mixin bot keys optional for this feature — chrome-related credentials only)
- The feature branch checked out and dependencies installed

## Setup

```bash
bundle install
bun install
bin/rails db:prepare          # creates main + cable + queue + cache + test DBs
bin/rails test                # full test suite (must pass before and after)
bin/rubocop                   # lint must pass
```

No new migrations. No new seeds. No new environment variables.

## Manual Validation Scenarios

Run `bin/dev` to start the server, then walk through these scenarios in a browser.

### Scenario 1: Home feed is global (FR-001, SC-001)

1. Ensure the database has at least 3 published articles with different locales (one each in `zh`, `en`, `ja`). If seeding, create them via the dashboard or `rails console`:
   ```ruby
   User.first.articles.create!(title: "...", intro: "...", content: "<p>...</p>",
                               asset_id: "...", price: 0.1, state: :published,
                               locale: "zh", published_at: Time.current)
   # repeat for "en" and "ja"
   ```
2. Open `/` as a signed-in or anonymous user whose preferred locale is `zh-CN` (set via the sidebar language picker).
3. **Expected**: the home feed shows all three articles, each with a language chip (`ZH`, `EN`, `JA`) on its card. The order is determined by the active sort (revenue / lately / popularity); locale does not reorder.

### Scenario 2: Switching UI locale does not change article set (FR-001, SC-006)

1. From Scenario 1, click the language picker and switch to `日本語`.
2. **Expected**: the same three articles appear. The button labels and navigation switch to Japanese; the article set is identical. The `<html lang>` attribute updates to `ja`.

### Scenario 3: Search returns cross-locale matches (FR-002, SC-002)

1. Type a keyword that appears in two articles written in different languages into the search box.
2. **Expected**: both articles appear in the result set. No locale parameter is required. If the keyword is unique enough that only one article matches, replace one article's body to share the keyword and re-test.

### Scenario 4: Subscribed and bought filters are global (FR-003, SC-003)

1. Follow an author who has published in two languages (visit their profile and click follow).
2. Open the home feed filtered by `subscribed` (the "Subscribed" tab).
3. **Expected**: articles by that author appear in every language they have published. No locale narrowing.

### Scenario 5: Hot tags are global (FR-004)

1. As in Scenario 1, ensure tags exist with different locales (`Tag.create!(name: "区块链", locale: "zh")`, `Tag.create!(name: "web3", locale: "en")`, `Tag.create!(name: "ブロックチェーン", locale: "ja")`).
2. Tag some articles with each, publish them, and ensure they have orders (`Order.create!(article: article, ...)`).
3. Open `/` and view the sidebar "Hot tags" widget.
4. **Expected**: tags from all three locales appear.

### Scenario 6: Active authors are global (FR-005)

1. As in Scenario 5, ensure users exist with different locales (`User.create!(locale: "zh-CN", ...)` etc.) and have qualifying articles with orders.
2. Open `/` and view the sidebar "Active authors" widget.
3. **Expected**: authors from all locales appear.

### Scenario 7: Article page renders in its own language; chrome follows visitor (US2)

1. Open `/articles/<uuid>` for a Japanese article from a Chinese-locale session.
2. **Expected**: the article body, title, intro render in Japanese. The chrome (button labels, header) renders in Chinese. The card-level language chip (`JA`) is visible on the article header.

### Scenario 8: Admin locale filter still works (FR-008, SC-004)

1. Sign in as an administrator. Visit `/admin/articles`.
2. Select the locale filter `ZH`.
3. **Expected**: result set is restricted to articles whose `articles.locale = "zh"` — exactly as today. (Admin behavior is unchanged.)

### Scenario 9: Article URLs are preserved (FR-007, SC-005)

1. Open any article URL that was valid before the change: `/articles/<uuid>` and `/:uid/<uuid>`.
2. **Expected**: same article body, same UUID. No 404.

### Scenario 10: Data is unchanged (FR-006, US6, SC-005)

1. Before deploy, run the verification script and capture a timestamped dump:
   ```bash
   bin/rails runner script/data_diff_check.rb > /tmp/data_before_$(date +%Y%m%d_%H%M%S).yaml
   ```
   The script dumps `articles`, `orders`, `comments`, `article_snapshots`, and `transfers` (stable columns + identifying fields) to YAML and prints a SHA256 checksum at the end.
2. Deploy (Kamal-based; see AGENTS.md).
3. After deploy, capture the same dump:
   ```bash
   bin/rails runner script/data_diff_check.rb > /tmp/data_after_$(date +%Y%m%d_%H%M%S).yaml
   ```
4. Compare:
   ```bash
   diff /tmp/data_before_*.yaml /tmp/data_after_*.yaml
   # Or compare the printed SHA256 checksums for a quick smoke check.
   ```
5. **Expected**: zero diff. The Cross-Locale Article Visibility feature is a behavior change (visitor-facing locale filter removed) — it does NOT touch any row in `articles`, `orders`, `comments`, `article_snapshots`, or `transfers`.

## Automated Test Validation

Run the test suite. New tests are added per research.md §D7:

```bash
bin/rails test test/services/article_search_service_test.rb
bin/rails test test/controllers/home_controller_test.rb
bin/rails test test/controllers/articles_controller_test.rb
bin/rails test                                     # full suite
```

Expected: full suite passes. New tests cover FR-001 through FR-005.

## Lint

```bash
bin/rubocop
bun run lint-check
```

Expected: zero lint errors.

## Zeitwerk autoload

```bash
bin/rails zeitwerk:check
```

Expected: passes (no new constants added — change is layer-level).

## Benchmarks (optional)

The benchmark `bin/benchmark` is stdlib-only and not run in CI. It is helpful to confirm the home-feed SQL is unchanged in shape aside from the dropped `WHERE locale = ...` clause. Per research.md §1.b, the `where(locale: ...)` removal produces a small SQL simplification (one fewer predicate); expected to be neutral or slightly faster.

## Rollout

The change is small and reversible. Deploy steps:

1. Merge to the deploy branch.
2. Run `gh workflow run Deploy` (Kamal-based; see AGENTS.md).
3. Monitor for the first hour:
   - Sidekiq-style job queue depth (no impact expected)
   - Cache hit rate on the new `hot_tags` key (will jump from 0% to 100% after the first read of each pod)
   - 4xx/5xx error rate (no impact expected)
4. If a regression appears (e.g., a notifier crashes due to a `nil` locale on a card), `git revert` and redeploy.

## Rollback

```bash
git revert <merge-sha>
gh workflow run Deploy
```

No data rollback is needed — the schema is unchanged. The hot-tags cache will repopulate under the old per-locale keys within 5 minutes.