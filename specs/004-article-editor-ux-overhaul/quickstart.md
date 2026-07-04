# Quickstart: Validating the Article Editor Redesign

Run these scenarios after implementation to confirm the feature works end-to-end. All scenarios assume a local dev environment (`bin/dev`) with a signed-in author account. See `contracts/component-contracts.md` for exact request/response shapes and `data-model.md` for the schema change.

## Prerequisites

```bash
bundle install
bun install
bin/rails db:prepare   # picks up the new lock_version migration
bin/dev                # Rails + Solid Queue + asset watch
```

Sign in as an author (Mixin OAuth in dev, or an existing fixture user via console/session helper).

## Scenario 1 — Never Lose Work (User Story 1, SC-001)

1. Visit `/articles/new`.
2. Type a title only; wait ~2 seconds. Confirm the save-status indicator moves `dirty → saving → saved` without clicking anything.
3. Confirm the browser address bar has updated to `/articles/:uuid/edit` (via `history.replaceState`, no visible reload/flash).
4. Reload the page. Confirm the title persisted.
5. Change the price in the (now-visible-by-default) settings rail. Wait ~2 seconds. Confirm the same save-status cycle fires for a settings-only change.
6. Reload. Confirm the price persisted.
7. Kill network (devtools offline mode), make an edit. Confirm the indicator shows the error/offline state, not a silent "saved." Restore network. Confirm it retries and reaches `saved` without user action.

## Scenario 2 — Tags Survive First Save (audit finding #3, FR-008)

1. On `/articles/new`, add 2–3 tags in the Cover & Tags section before any autosave has fired.
2. Wait for the first autosave to complete (creates the record per contract §2).
3. Reload the edit page. Confirm all tags are present (not dropped).

## Scenario 3 — Settings Panel Grouping & Guided Revenue Split (User Story 2, SC-004/SC-005)

1. Open an existing draft's editor. Confirm the settings rail shows five labeled sections: Cover & Tags, Pricing & Access, Revenue Split, References, Collection.
2. In Revenue Split, confirm the default view is a plain-language summary (no raw ratio number fields visible) with an "Advanced" control.
3. Open "Advanced." Change `readers_revenue_ratio` to an out-of-bounds value. Confirm an inline, field-adjacent error appears immediately (no page submit needed).
4. Trigger a `title`/`intro` validation error (e.g., clear the title on a non-draft article) and confirm the error renders next to the title field, not near the Collection section (fixes audit finding #5).
5. Resize the browser to a mobile width. Confirm the settings rail becomes a bottom-sheet/slide-over and every field remains legible with no horizontal scroll.

## Scenario 4 — One Unified Editing Experience (User Story 3)

1. On the same article, edit body content, then immediately edit a setting (e.g., tags), without any explicit save action.
2. Confirm both changes are reflected by the same single save-status indicator (no separate "settings saved" vs. "content saved" states).
3. Attempt to close the tab immediately after an edit with autosave still in flight. Confirm a leave-confirmation appears only in that narrow window — not when the indicator already shows `saved`.

## Scenario 5 — Confident, Error-Free Publishing (User Story 4, SC-007)

1. Create a draft with no content. Attempt to publish. Confirm the confirmation modal lists the specific missing requirement(s) (e.g., "Content can't be blank"), not a generic failure.
2. Force an invalid revenue split (e.g., via the Advanced panel) and attempt to publish. Confirm the specific revenue-split error is listed.
3. Fix all issues and publish a fully valid draft. Confirm no unexpected warnings appear and the article transitions to `published`.
4. (Regression check for FR-024) Deliberately trigger a failed publish and confirm the editor form visibly refreshes (does not silently no-op).

## Scenario 6 — Distraction-Free Focus Mode (User Story 5, SC-009)

1. While editing, enable Focus Mode. Confirm the top bar and settings rail hide/minimize, leaving the writing surface as the primary element, with a minimal save-status pill still visible.
2. Make an edit while in Focus Mode; confirm the save-status pill still updates.
3. Exit Focus Mode. Confirm content, cursor position, and save state are unchanged from just before entering.

## Scenario 7 — Live Reader Preview (User Story 6, SC-010)

1. On a **free** article, open the preview. Confirm it renders full content with the same typography as the public article page.
2. On a **priced** article with `free_content_ratio` set, open the preview. Confirm it shows the free-content boundary fade and the unlock/paywall card — exactly as `articles#show` renders it to a non-purchasing reader — even though the viewer is the article's own author.
3. Edit content, wait for autosave to complete, reopen the preview. Confirm it reflects the latest saved text.

## Scenario 8 — No Functional Regressions (SC-008)

```bash
bin/rails test test/controllers/articles_controller_test.rb
bin/rails test test/controllers/dashboard/published_articles_controller_test.rb   # if present, else add per tasks.md
bin/rails test test/models/article_test.rb
bin/rubocop
bun run lint-check
```

Confirm the full existing suite still passes, plus new tests added for: the unified autosave endpoint (content + settings + tag persistence on create), the optimistic-locking conflict path, and publish-readiness error surfacing.

**Known sandbox limitation** (per `specs/002-editorial-ui-redesign/research.md` §8 and `specs/003-editorial-redesign-rollout/tasks.md`): Capybara/Selenium system tests cannot launch a browser in this sandbox environment. Manual QA against the scenarios above substitutes for browser-driven system tests where automated coverage isn't feasible here; controller/model-level Minitest coverage is still required for all new server-side behavior (autosave consolidation, optimistic locking, tag persistence on create, publish readiness).
