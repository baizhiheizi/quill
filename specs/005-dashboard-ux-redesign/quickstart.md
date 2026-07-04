# Quickstart: Validating the Dashboard UI/UX Redesign

This is a manual + automated validation guide, organized by user story (P1–P7), to be run after implementing each story. It assumes a local `bin/dev` server and at least one seeded user account (a reader-only account and an author account with drafts/published/hidden articles, comments, subscriptions, orders, payments, and transfers of both roles are needed for full coverage — use `bin/rails db:seed`/fixtures or create ad hoc test data via `bin/rails console`).

## Prerequisites

```bash
bundle install
bun install
bin/rails db:prepare
bin/dev   # Rails + Solid Queue + CSS/JS watch
```

Log in as a seeded user at `http://localhost:3000`. For role coverage, you'll want to test with:
- A brand-new account with zero activity (empty states)
- A reader-only account (bought articles, comments, subscriptions, orders, reader-role transfers)
- An author account (drafted/published/hidden articles, collections, author-role transfers)
- Ideally one account that is both (to check FR-021/Edge Cases: both roles shown clearly)

## Automated checks (run after every story)

```bash
bin/rubocop
bun run lint-check
bin/rails test
bin/rails test test/controllers/dashboard/          # dashboard-specific suite
bin/rails zeitwerk:check
```

## Story 1 — Navigation & Information Architecture

1. Log in, open the dashboard. Confirm the rail (desktop) shows exactly 5 labeled sections (Overview, Write, Read, Finances, Account) plus a persistent Notifications icon with unread badge.
2. From the rail, navigate to every one of the ~20 features enumerated in `research.md` §1; confirm each is reachable and none requires more than the two navigation actions defined in spec.md SC-001.
3. Specifically confirm **API access tokens** is now reachable (previously had zero entry point) — click through from Account.
4. Confirm the current section is visually indicated wherever you are in the dashboard.
5. Resize to mobile width (or use device emulation); confirm the mobile nav (bottom tab bar / equivalent) exposes the same 5 groupings, not a different structure.
6. Run `bin/rails test test/controllers/dashboard/routing_redirects_test.rb`; confirm every previously-bookmarkable dashboard path (see `data-model.md`'s Route Redirect Map) returns a non-error response.

## Story 2 — Dashboard Overview

1. Log in and visit the dashboard root URL directly; confirm it renders a distinct overview page, not a redirect into "My Reading."
2. As an author with published articles, confirm the overview shows an earnings snapshot and recent article activity.
3. As a reader-only account, confirm the overview shows reader-relevant content (recent reads, reader reward snapshot, a "start writing" invitation) instead of author-oriented content.
4. As a brand-new account with zero activity, confirm the overview renders cleanly with empty states — no blank gaps or errors.
5. Confirm unread-notification count is visible on the overview with a working link into the notifications center.
6. Confirm the quick-action shortcuts (write, view earnings, view notifications) are present and functional.

## Story 3 — Author Workspace

1. As an author with drafted, published, and hidden articles plus at least one collection, open the Write section.
2. Confirm each status group (drafted/published/hidden) is clearly distinguished with per-article status info (price, revenue where applicable).
3. From the workspace, edit a draft, publish a draft, hide a published article, and delete a draft — confirm each action works exactly as before (no functional regression) and stays within the workspace (no unrelated detour).
4. Create/edit a collection from within the workspace.
5. Confirm author revenue/earnings activity is visible within the same workspace.
6. As an author with no hidden articles (or another empty status group), confirm a clear empty state.

## Story 4 — Reading Library

1. As a reader with bought articles, comments, and subscriptions, open the Read section.
2. Confirm bought articles show purchase/read date; confirm your own comments are listed and link back to their articles.
3. Confirm subscriptions to authors, tags, and comment threads are each clearly organized; unsubscribe from one of each and confirm it works.
4. Confirm reader reward/earnings activity is visible within the same library.
5. As a reader with no purchases yet, confirm a clear, inviting empty state.

## Story 5 — Financial View

1. As a user with both purchases and reward transfers, open the Finances section.
2. Confirm payments/orders (spending) and reward transfers (earnings) are clearly distinguished categories, not one undifferentiated list.
3. As an author, confirm author-revenue transfers are visible and clearly distinguished from any reader-reward transfers on the same account.
4. Select an individual payment or transfer; confirm you can see the article it relates to, amount, date, and role.
5. As a user with zero financial activity, confirm a clear empty state rather than confusing blank tables.

## Story 6 — Notifications Center

1. With a mix of read/unread notifications, open the notifications center via the persistent icon.
2. Confirm unread items are visually distinguished; mark one read, delete one, and follow one to its related article.
3. Adjust a notification-type preference from within the same center; confirm it persists (check `dashboard/notification_settings`'s update behavior is unchanged).
4. With zero notifications, confirm a clear empty state.

## Story 7 — Account, Security & Preferences

1. Open the Account section. Confirm profile editing (name, avatar, bio, email) works and reflects changes.
2. Confirm notification preferences are adjustable from here (may link to/embed the Notifications center's settings).
3. Block a user elsewhere in the product, then confirm they appear in Account's blocked-users list and can be unblocked from there.
4. Create an API access token from Account; confirm it appears and can be revoked. (This is the previously-unreachable feature — the core proof point for FR-003.)
5. Change language and light/dark theme from Account; confirm both work exactly as before.

## Cross-cutting checks (run once per story, not just at the end)

- Toggle light/dark mode on every redesigned page; confirm legibility and no visual regressions in either theme (FR-027).
- View every redesigned page at common mobile, tablet, and desktop widths; confirm no horizontal scrolling or overlapping elements (FR-028).
- View pages with Chinese-language content (article titles, bios, comments); confirm no missing-glyph ("tofu") characters (SC-006).
- Confirm the right-hand widget rail (join-Quill card, active authors, hot tags) is consistently absent (or deliberately replaced) across every dashboard page — not present on some pages and missing on others (Edge Cases, Research §6).
- Re-run the full automated check block above; confirm zero regressions in the existing test suite (SC-007).
