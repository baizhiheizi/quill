# Quickstart: Validating the Editorial Redesign Rollout

Manual + automated validation guide for this feature. Run after implementation tasks land, or incrementally per completed user story (independently testable, per priority order P1–P6 — see `spec.md`).

## Prerequisites

```bash
bundle install
bun install
bin/rails db:prepare
```

Standard local setup per `AGENTS.md` — `config/settings.local.yml` and Rails credentials (including the `grover` token, needed for the default-cover story) must already be configured.

## Run the app

```bash
bin/dev   # Rails + Solid Queue (bin/jobs — needed for the async default-cover job) + CSS/JS watchers
```

Visit `http://localhost:3000`.

## Automated checks (run first, fast feedback)

```bash
bin/rubocop
bun run lint-check
bin/rails test test/models/concerns/articles/poster_generator_test.rb   # default-cover behavior (new cases)
bin/rails test test/controllers/dashboard/notifications_controller_test.rb
bin/rails test test/controllers/articles_controller_test.rb
bin/rails test test/system/article_paywall_test.rb
bin/rails test                                                          # full suite — no regressions expected
```

## Manual validation per user story

For each story below, check **both** light and dark mode (toggle via the dark-mode control) and **both** desktop (~1280px) and mobile (~375px) widths, unless noted otherwise.

### Story 1 — Correct Button & Badge Styling

1. Load any page with the masthead. Hover/focus the notification, dark-mode toggle, locale switcher, and login icon buttons — confirm a visible subtle background appears (not unstyled), in both themes.
2. Open an article (or view a feed card) with a non-default locale. Confirm the locale badge shows a visible pill background.
3. Open the article page and confirm `_comments_card`/`_buyers` now use the same headline typeface (`font-display`) as the rest of the page (discovered consistency fix, see `research.md` §2).
4. `grep -rn "btn-ghost\|badge-ghost" app/views` returns zero results (SC-001).

### Story 2 — Unique Default Cover for Articles Without One

1. Find or create 2+ published articles with no uploaded cover and no in-content image (or a paid article with no cover).
2. View each in the feed, search, its author's profile, and a collection (if applicable). Confirm each shows a generated cover, not a blank/icon placeholder (FR-003).
3. Confirm the two articles' generated covers are visually distinct from each other (FR-004, SC-004).
4. Reload the same article's page repeatedly — confirm the generated cover looks identical every time (FR-004, SC-003).
5. Open the article's public share link/preview (or inspect the `og:image`/`twitter:image` meta tag via view-source) — confirm it points to a real generated image URL, not the old shared generic fallback asset (FR-005).
6. Upload a real cover to a previously cover-less article. Confirm the real cover now shows everywhere, immediately (FR-006).
7. Confirm the Solid Queue job (`bin/jobs` output, or `/admin/jobs` Mission Control if reachable outside the excluded admin-panel scope for this feature) shows the default-cover job completing without errors.

### Story 3 — Home Page as a Distinct Landing Experience

1. Log out, use a desktop-width browser. Visit `/`.
2. Confirm introductory/value-proposition content is visible that is not present on `/articles` (SC-005).
3. Confirm at least two working CTAs: one into `/articles`, one to write/connect wallet (SC-006).
4. Confirm a curated/featured article section is shown, visually distinct from the full infinite-scroll feed, and that it is NOT simply the same feed re-embedded (FR-011).
5. Confirm the curated section respects visibility rules — a blocked-author or drafted article never appears there (FR-012).
6. Temporarily test with a fixture/dev DB that has very few qualifying articles — confirm the page still renders cleanly (FR-013).
7. Log in (or use a mobile user agent) and confirm you're still redirected straight to `/articles` per existing, unchanged routing behavior.

### Story 4 — Author Dashboard/Studio Redesign

1. Log in. Visit each top-level dashboard section: home/stats, my readings, my authoring, notifications + notification settings, orders, payments, transfers, subscriptions (articles/tags/users sub-tabs), block list, access tokens, dashboard-side collection management (listed/hidden), profile settings.
2. On desktop, confirm the left sidebar is present with unchanged links/structure, restyled to the new colors/typography/icons (FR-016).
3. On mobile width, confirm the top bar + bottom tab bar are present, restyled, with unchanged navigation targets.
4. Spot-check buttons, badges, tags, tabs, and any empty state (e.g., zero notifications) use the same component styles as public pages (FR-017).
5. Confirm no `inline_svg_tag` icons remain in the 10 previously-identified dashboard files (`grep -rl "inline_svg_tag" app/views/dashboard`) (FR-018).
6. Confirm every dashboard action still works end-to-end (e.g., block a user, generate an access token, change notification settings) — no functional regression (FR-020, SC-010).

### Story 5 — Article Editor Redesign

1. Create a new article (`/articles/new`) and edit an existing draft.
2. Confirm the sticky top bar, title/intro fields, and settings panels (price, revenue split, cover, tags, references) are visually restyled (FR-021).
3. Confirm the title field renders in the headline (serif/`font-display`) typeface, matching how it will appear to readers (FR-022).
4. Confirm autosave, draft-dirty indicator, save, and publish actions all still function exactly as before (FR-025, SC-010).
5. At ~375px width, confirm the editor remains fully usable (FR-024).

### Story 6 — Wallet-Connect / Login Modal Redesign

1. Log out. Trigger the modal from a public-page CTA and from a dashboard-adjacent entry point (e.g., masthead login icon vs. left-sidebar login row).
2. Confirm the modal's visual design (colors, typography, buttons) matches the editorial system in both trigger contexts (FR-026).
3. Complete the connection flow (or confirm the link correctly navigates to `auth_mixin_path`) — confirm behavior is unchanged (FR-028).

## Cross-cutting checks

- **Dark mode parity (FR-002/FR-019/FR-023/FR-027, SC-009)**: for every surface above, toggle dark mode and confirm WCAG AA contrast on body text and interactive-control states.
- **Admin panel untouched (FR-030)**: spot-check `/admin` still renders with its current, unchanged styling.
- **No functional regressions (SC-010)**: full `bin/rails test` suite passes; dashboard/editor/modal behavior (routes, params, validations, auth) is identical to before this feature.

## Expected outcome

All checks above pass, `bin/rubocop` and `bun run lint-check` are clean, and the full Minitest suite (`bin/rails test`) passes with no new failures.
