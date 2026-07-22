# Quickstart Validation Guide

**Feature**: 010-editor-progressive-disclosure
**Date**: 2026-07-22

This guide describes runnable validation scenarios that prove the feature works end-to-end. It covers prerequisites, manual validation steps, and automated test targets. Implementation details (specific code) belong in `tasks.md`, not here.

---

## Prerequisites

- PostgreSQL running locally (or via Docker)
- `bundle install` and `bun install` completed
- `bin/rails db:prepare` run (creates/migrates primary, cable, queue databases)
- `bin/rails credentials:edit --development` configured (Mixin bot + AR encryption keys)
- `cp config/settings.yml config/settings.local.yml` with local host set
- At least one `User` record (author) and one `Currency` with `price_usd > 0`

---

## Scenario 1: Distraction-Free Default Editor (User Story 1)

**Validates**: FR-001, FR-002, SC-001, SC-004

### Manual steps
1. Sign in as an author
2. Click "Write" (navigate to `/articles/new`)
3. Observe the editor surface

**Expected**: Only title field, intro text area, and content rich-text editor are visible. No pricing, revenue, currency, references, or collection sections are visible.

4. Click the Settings (gear) button in the chrome

**Expected**: Settings panel appears containing cover upload, tag selector, pricing, revenue (collapsed), references (collapsed), and collection selector.

5. Click the gear button again

**Expected**: Settings panel hides. Writing surface returns to full width. No entered values are lost.

### Automated test target
- `test/system/article_editor_test.rb`: "test default editor shows only title intro and content"
- `test/system/article_editor_test.rb`: "test settings panel toggles open and closed"

---

## Scenario 2: USD-First Pricing (User Story 2)

**Validates**: FR-004, FR-005, FR-006, FR-007, SC-006

### Manual steps
1. Open the editor, open Settings
2. Observe the pricing section

**Expected**: Primary price input is in USD. Preset chips ($0.50, $1, $2, $5) are visible. Crypto equivalent is shown as a read-only secondary line.

3. Click the "$2" preset chip

**Expected**: USD input shows "2.00". Crypto equivalent recalculates (e.g., "≈ 0.000031 BTC").

4. Type a custom USD amount (e.g., "3.50")

**Expected**: Crypto equivalent updates. USD formatting stays at 2 decimal places — no jump to 4 decimals.

5. Change the price multiple times rapidly

**Expected**: Each update shows consistent 2-decimal USD formatting (no inconsistency between initial render and subsequent updates).

### Automated test target
- `test/system/article_editor_test.rb`: "test usd price input updates crypto equivalent"
- `test/helpers/` or unit test: "test price usd formatting is consistent at 2 decimals"

---

## Scenario 3: Save Conflict Resolution (User Story 3)

**Validates**: FR-009, FR-010, SC-003

### Manual steps
1. Open the same draft article in two browser tabs (Tab A and Tab B)
2. In Tab A, edit the title and wait for autosave to complete (status → "Saved")
3. In Tab B, edit the intro and wait for autosave

**Expected**: Tab B detects the conflict (Tab A saved first). A conflict-resolution banner appears (not just a status pill) offering "Reload latest" and "Keep my version".

4. In Tab B, click "Keep my version"

**Expected**: The intro edit from Tab B is submitted successfully (not discarded). Status returns to "Saved".

5. Repeat the conflict setup, then click "Reload latest"

**Expected**: Page reloads with server-fresh content. The local edit is discarded (with the author's awareness).

### Automated test target
- `test/controllers/articles_controller_test.rb`: "test update returns 409 on stale object and renders conflict resolution"
- `test/system/article_editor_test.rb`: "test conflict resolution keep my version preserves edits"

---

## Scenario 4: Intro Auto-Resize (User Story 3)

**Validates**: FR-008, SC-005

### Manual steps
1. Open the editor
2. Type a multi-line intro (5+ lines)

**Expected**: The intro text area grows vertically to show all content. No internal scrollbar appears.

### Automated test target
- `test/system/article_editor_test.rb`: "test intro textarea auto-resizes on input" (verify `scrollHeight > initialHeight` after typing)

---

## Scenario 5: Revenue Split Progressive Disclosure (User Story 4)

**Validates**: FR-011, FR-012, FR-013, FR-018

### Manual steps
1. Open the editor, open Settings
2. Observe the revenue area

**Expected**: No revenue ratio fields visible by default. Only a "Customize revenue split" affordance with a brief default summary.

3. Click "Customize revenue split"

**Expected**: Section expands. Chevron icon rotates. `aria-expanded="true"` on the trigger. Readers/author/references ratio fields, live summary, and platform ratio are visible.

4. Adjust the readers ratio to 0.5

**Expected**: Author ratio auto-recalculates (0.9 - 0.5 - references - collection). Summary updates. Split validates to 100%.

5. Create a new draft with non-default ratios (e.g., readers = 0.6), save, then reopen the editor

**Expected**: Revenue section auto-expands on load (non-default values detected).

### Automated test target
- `test/system/article_editor_test.rb`: "test revenue section collapsed by default and expands on click"
- `test/system/article_editor_test.rb`: "test revenue auto-expands for non-default values"

---

## Scenario 6: References Behind Advanced Gate (User Story 4)

**Validates**: FR-012

### Manual steps
1. Open the editor, open Settings
2. Observe the references area

**Expected**: References section is collapsed. Only a "Cite articles & share revenue (advanced)" button is visible.

3. Click the button

**Expected**: Disclosure expands. "Add reference" button appears. Existing references (if any) are shown.

4. Click "Add reference", select an article, set a ratio

**Expected**: Reference row works as before. References revenue ratio recalculates.

### Automated test target
- `test/system/article_editor_test.rb`: "test references section collapsed by default"

---

## Scenario 7: Tag Suggestions Scoped (FR-017)

**Validates**: FR-017

### Manual steps
1. Open the editor, open Settings
2. Observe the tag selector pre-loaded options

**Expected**: Tags are ordered by popularity (article count), not random. The same options appear consistently across reloads (deterministic order).

### Automated test target
- `test/controllers/articles_controller_test.rb` or view test: "test tag suggestions use recommended scope (ordered by articles_count)"

---

## Scenario 8: Publish Readiness Indicator (User Story 5)

**Validates**: FR-015, SC-008

### Manual steps
1. Open a draft with no title
2. Observe the editor chrome

**Expected**: A readiness indicator shows "1 thing to fix before publishing" (or similar).

3. Enter a title

**Expected**: Indicator updates to "Ready to publish" once all required fields are valid.

4. Click "Publish"

**Expected**: Publish modal/confirmation appears with the article title and price for review.

### Automated test target
- `test/system/article_editor_test.rb`: "test readiness indicator shows blocker count"

---

## Scenario 9: No Regression (FR-019, SC-007)

### Automated validation
1. Run `bin/rails test` — all existing tests pass
2. Run `bin/rails zeitwerk:check` — no autoloading errors
3. Run `bin/rubocop` — touched Ruby files pass lint
4. Run `bun run lint-check` — touched JS files pass lint
5. Verify existing advanced features still work: custom revenue splits save correctly, references persist, collection binding works, currency change updates price estimate, publish notifications fire

---

## Summary: Coverage Matrix

| Scenario | User Story | Requirements | Success Criteria |
|----------|-----------|--------------|------------------|
| 1: Distraction-free | US1 | FR-001, FR-002 | SC-001, SC-004 |
| 2: USD pricing | US2 | FR-004–FR-007 | SC-006 |
| 3: Conflict resolution | US3 | FR-009, FR-010 | SC-003 |
| 4: Intro auto-resize | US3 | FR-008 | SC-005 |
| 5: Revenue disclosure | US4 | FR-011–FR-013, FR-018 | SC-007 |
| 6: References gate | US4 | FR-012 | SC-007 |
| 7: Tag scoping | — | FR-017 | — |
| 8: Readiness | US5 | FR-015 | SC-008 |
| 9: No regression | — | FR-019, FR-020 | SC-007 |
