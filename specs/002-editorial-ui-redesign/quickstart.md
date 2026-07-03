# Quickstart: Validating the Editorial UI Redesign

Manual + automated validation guide for this feature. Run after implementation tasks land, or incrementally per completed user story (the spec's stories are independently testable — see `spec.md`).

## Prerequisites

```bash
bundle install
bun install
bin/rails db:prepare
```

Standard local setup per `AGENTS.md` — `config/settings.local.yml` and Rails credentials must already be configured for this to run at all (unrelated to this feature).

## Run the app

```bash
bin/dev   # Rails + Solid Queue + CSS/JS watchers
```

Visit `http://localhost:3000`.

## Automated checks (run first, fast feedback)

```bash
bin/rubocop                 # Ruby style — must pass with zero offenses on changed files
bun run lint-check           # Prettier check on app/javascript (new Stimulus controllers)
bin/rails test test/system/article_paywall_test.rb   # existing paywall system test must still pass
bin/rails test                                        # full suite — no regressions expected (presentation-only change)
```

## Manual validation per user story

For each story below, check **both** light and dark mode (toggle via the dark-mode control in the masthead) and **both** desktop (~1280px) and mobile (~375px) widths.

### Story 1 — Editorial Home Feed

1. Log out. Visit `/`. Confirm: slim masthead (no full-height banner), one-line value-prop visible, feed starts immediately below (SC-001).
2. Log in. Visit `/` (or wherever the feed lands post-redirect). Confirm the value-prop message is **not** shown (FR-002).
3. Scan the feed. Confirm every row shows: title, one-line excerpt, author, relative date, thumbnail (or neutral placeholder if the article has none), and a price/free badge (SC-002).
4. Find an article with `revenue_usd > 0`. Confirm the reward/revenue indicator renders inline without opening the article (FR-004).
5. Confirm topic tags render in one neutral chip style everywhere (no per-category colors) (FR-005, SC covered qualitatively).

### Story 2 — Focused Article Reading & Paywall

1. Open a free article. Confirm single-column layout, no competing side panel (FR-007).
2. Open a locked (paid) article you have not purchased. Scroll to the paid boundary. Confirm the content fades gradually (not an abrupt cutoff) into an inline unlock prompt showing price + action (FR-006, SC-003).
3. Confirm a compact, non-intrusive unlock/support control stays reachable while reading (FR-007).
4. Purchase/unlock the article (or use a fixture already marked purchased) and reload — confirm no fade/prompt appears (Story 2, Acceptance Scenario 4).

### Story 3 — Author Public Profile

1. Visit any author's profile (`/u/:uid` or equivalent).
2. Confirm avatar, name, bio, article count, reader count, and join date are visible (FR-008).
3. Inspect the full page (view source if needed) and confirm **no** earnings/on-chain financial figures appear anywhere (FR-008, SC-007 — should be zero instances).
4. Confirm the author's articles render using the same Minimal List row as the home feed (FR-003).

### Story 4 — Search (via the feed)

1. Use the masthead search box, submit a query.
2. Confirm results land on the feed (`articles_path(query: ...)`) using the same Minimal List rows (FR-009) — per `research.md`, there is no separate search-results template.
3. Search for a query with no matches. Confirm a clear, friendly empty state (FR-014).

### Story 5 — Collection Pages

1. Visit a collection page.
2. Confirm title, description, and curator are shown.
3. Confirm member articles render as Minimal List rows (FR-010).
4. If a collection has zero articles (or via a fixture), confirm the empty state (FR-014).

## Cross-cutting checks

- **Dark mode parity (FR-011)**: for every page above, toggle dark mode and confirm text remains legible (no low-contrast surprises) — a quick way to sanity-check contrast is browser DevTools' contrast checker on body text in both themes (target: WCAG AA, per SC-005).
- **CJK rendering (FR-012, SC-006)**: view an article/profile/collection with Chinese titles and body text; confirm no "tofu" (missing-glyph) boxes and that the serif headline / sans body split is visually applied.
- **Mobile usability (SC-008)**: at ~375px width, confirm no horizontal scrolling and no overlapping elements on any of the 5 pages.
- **Out-of-scope pages untouched**: spot-check the dashboard (`/dashboard`) and article editor (`/articles/:uuid/edit`) still render with their current (unchanged) styling — regression check for the layout-split work described in `research.md`.

## Expected outcome

All checks above pass, `bin/rubocop` and `bun run lint-check` are clean, and the full Minitest suite (`bin/rails test`) passes with no new failures.
