---

description: "Task list for Article Editor Progressive Disclosure"
---

# Tasks: Article Editor Progressive Disclosure

**Input**: Design documents from `/specs/010-editor-progressive-disclosure/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/editor-ui-contract.md, quickstart.md

**Tests**: Per Quill Constitution §II, include test tasks for all non-trivial behavior (controllers, system/interaction flows). Omit tests only for purely presentational changes with no behavioral impact.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Ruby/Rails monolith: paths relative to repository root (`app/`, `config/`, `test/`)
- No new project directories; all changes extend existing structure per plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add shared i18n strings and the standalone bug fix that existing views already reference.

- [X] T001 Add all new i18n locale keys to `config/locales/articles.en.yml` — keys listed in `specs/010-editor-progressive-disclosure/contracts/editor-ui-contract.md` under "Locale Keys" section (settings open/close, price usd/presets/crypto-equivalent/feed-unavailable, revenue customize/default-summary, references cite-advanced, conflict title/reload/keep-mine/description, readiness things-to-fix/ready)
- [X] T002 [P] Create `app/javascript/controllers/textarea_controller.js` — Stimulus controller with `resize()` method that sets `element.style.height = "auto"` then `element.style.height = element.scrollHeight + "px"` on `input` event; call `resize()` on `connect()`. Register in `app/javascript/controllers/index.js` as `"textarea"`. This fixes B1 — the existing view at `app/views/articles/_form.html.erb:29` already references `data-controller="textarea"` and `input->textarea#resize`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: None required — this feature extends existing infrastructure with no blocking prerequisites. All user stories can begin immediately after Phase 1.

**Checkpoint**: Setup complete — user story implementation can now begin in priority order.

---

## Phase 3: User Story 1 — Distraction-Free Writing Surface (Priority: P1) MVP

**Goal**: When an author opens the editor (new or existing draft), only title, intro, and content are visible. All settings hide behind the existing gear toggle. Desktop layout changes from always-two-column to single-column default.

**Independent Test**: Open `/articles/new` — verify only title, intro, content visible. Click gear — settings panel appears. Click gear again — settings hide, no data lost.

### Implementation for User Story 1

- [X] T003 [US1] Adjust desktop CSS in `app/assets/stylesheets/lexxy_overrides.css` — in the `@media (min-width: 1024px)` block (lines 182–219): change `.article-editor__layout` grid to single-column by default (`grid-template-columns: minmax(0, 1fr)`); add rule for `.article-editor--settings-open .article-editor__layout` that switches to two-column (`grid-template-columns: minmax(0, 1fr) 22rem`); hide `.article-editor__settings` by default (`display: none`) and show it when `.article-editor--settings-open` is present (reuse the mobile overlay pattern or a sidebar slide-in). The mobile pattern at lines 156–180 already works correctly — do not change it.
- [X] T004 [P] [US1] Verify gear toggle button is present and visible in editor chrome in `app/views/articles/new.html.erb` and `app/views/articles/_edit_form.html.erb` — ensure it calls `article-form#toggleSettingsRail` and has an appropriate icon (e.g., `i-[tabler--settings]`). Add `aria-expanded` binding to the gear button reflecting `settingsRailOpenValue`.
- [X] T005 [US1] Add system test in `test/system/article_editor_test.rb` — "test editor shows only title intro content by default" (visit new article path, assert settings rail not visible, assert title/intro/content fields present) and "test settings panel toggles" (click gear, assert settings visible, click gear again, assert settings hidden).

**Checkpoint**: User Story 1 is fully functional — the editor is distraction-free by default. This is the MVP.

---

## Phase 4: User Story 2 — Intuitive, USD-First Pricing (Priority: P2)

**Goal**: Price input is USD-primary with preset chips and crypto shown as secondary read-only. Decimal formatting is consistent (fixes B2). Currency selection is a lightweight inline control.

**Independent Test**: Open settings, enter a USD price, verify crypto equivalent updates and presets work. Verify formatting stays at 2 decimals.

### Implementation for User Story 2

- [X] T006 [US2] Refactor pricing section in `app/views/articles/_option_fields.html.erb` (lines 48–131) — replace the crypto-native `price` number field with: (a) a visible USD number input (name `article[price_usd]`, step 0.01, min 0.10) with preset chip buttons ($0.50, $1, $2, $5) that set the USD value on click; (b) a hidden field that stores the crypto `article[price]` value (converted from USD via JS); (c) a read-only secondary line showing the crypto equivalent (e.g., "≈ 0.000031 BTC") using the existing `data-article-form-target="priceUsd"` pattern inverted. Fix B2: ensure server-rendered estimate at line 116 uses the same decimal format as the JS update. Add graceful-degradation note when `currency.price_usd` is 0.
- [X] T007 [US2] Extend `app/javascript/controllers/article_form_controller.js` — add USD-to-crypto conversion: new method `calCryptoFromUsd()` that reads the USD input, divides by `currencyPriceUsdValue`, writes to the hidden `article[price]` field, and updates the crypto-equivalent display target. Wire the USD input's `input` event to this method. Fix B2: change `calPriceUsd()` (line 455–457) from `.toFixed(4)` to `.toFixed(2)` to match the server-side `.floor(2)` at `_option_fields.html.erb:116`. Add preset-chip click handler that sets the USD input value and triggers conversion. Guard against `currencyPriceUsdValue === 0` (disable USD input, show feed-unavailable message).
- [X] T008 [US2] Add system test in `test/system/article_editor_test.rb` — "test usd price input updates crypto equivalent" (enter USD amount, assert crypto line updates) and "test price formatting is consistent" (change price multiple times, assert no decimal-place jump).

**Checkpoint**: Pricing is USD-first with consistent formatting. User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 — Reliable Editing with No Silent Data Loss (Priority: P2)

**Goal**: Save conflicts show a resolution UI with "Reload latest" / "Keep my version" options (fixes B6). Intro text area auto-resizes (T002 already created the controller).

**Independent Test**: Edit article in two tabs, trigger conflict, verify resolution UI appears. Type a long intro, verify field grows.

### Implementation for User Story 3

- [X] T009 [P] [US3] Create `app/views/articles/_conflict_resolution.html.erb` — a banner/modal partial showing conflict title (`t("articles.conflict.title")`), description text, and two buttons: "Reload latest" (a link to `edit_article_path(@article.uuid)` with `data-turbo-frame="_top"`) and "Keep my version" (a button with `data-action="article-form#keepMyVersion"`). Use existing `render_modal` UiHelper pattern or a simple banner div.
- [X] T010 [US3] Extend `app/views/articles/update_conflict.turbo_stream.erb` — add a `turbo_stream.append` or `turbo_stream.replace` that renders the `_conflict_resolution` partial into the editor (e.g., into a `#conflict-resolution` container in the editor chrome). Keep the existing save-status and lock-version updates.
- [X] T011 [US3] Extend `app/javascript/controllers/article_form_controller.js` — in the 409 conflict branch of `runAutosave()` (lines 297–299), keep existing `syncLockVersionFromMeta()` and `setSaveStatus("conflict")` but do NOT silently proceed. Add method `keepMyVersion()` that reads the latest lock_version from `#article-form-meta`, sets `saveStatusValue = "idle"`, and re-queues autosave so the author's in-flight edits are submitted against the new lock_version. Ensure local form DOM edits are never cleared on conflict. (The "Reload latest" action is a simple link — no JS method needed beyond what the link provides.)
- [X] T012 [US3] Add system test in `test/system/article_editor_test.rb` — "test conflict resolution keep my version preserves edits" (open article in two tabs, save in tab A, edit in tab B, assert conflict UI appears, click "Keep my version", assert tab B edits are saved). Test intro auto-resize: "test intro textarea auto-resizes" (type multi-line intro, assert `scrollHeight` grew beyond initial height).
- [X] T013 [P] [US3] Add controller test in `test/controllers/articles_controller_test.rb` — "test update returns 409 conflict with resolution payload" (create article, save with stale lock_version, assert response status 409, assert conflict turbo stream rendered).

**Checkpoint**: Editing is reliable — conflicts are resolved explicitly, intro auto-resizes. User Stories 1, 2, AND 3 all work independently.

---

## Phase 6: User Story 4 — Power Features Behind Explicit Gates (Priority: P3)

**Goal**: Revenue split section and references/citations section are collapsed by default inside Settings, revealed by explicit disclosure buttons. Tag suggestions are scoped (fixes B3). Dead code cleaned (fixes B4). Disclosure toggles show expanded/collapsed state (fixes B5).

**Independent Test**: Open settings, verify revenue and references are collapsed. Click "Customize revenue split", verify all controls present and functional. Verify tag suggestions are popularity-ordered.

### Implementation for User Story 4

- [X] T014 [US4] Refactor revenue section in `app/views/articles/_option_fields.html.erb` (lines 133–213) — wrap the entire `<section aria-labelledby="settings-revenue">` content (except the heading) in a collapsed disclosure. Add a "Customize revenue split" button (`t("articles.revenue.customize")`) with `data-action="article-revenue#toggleRevenueSection"` and a chevron icon. Move the existing `revenueSummary` target and ratio fields inside the collapsible container (new `data-article-revenue-target="revenueSection"`). Conditionally remove the `hidden` class if the article has non-default values (`readers_revenue_ratio != 0.4 || article_references.any? || collection_revenue_ratio.positive?`). Fix B5: add `aria-expanded` attribute to the toggle button.
- [X] T015 [US4] Refactor references section in `app/views/articles/_option_fields.html.erb` (lines 215–237) — wrap the nested-form template, existing references, and "Add reference" button in a collapsed disclosure behind a "Cite articles & share revenue (advanced)" button (`t("articles.references.cite_advanced")`). Add chevron + `aria-expanded`. Conditionally auto-expand if `form.object.article_references.any?`.
- [X] T016 [P] [US4] Extend `app/javascript/controllers/article_revenue_controller.js` — rename/extend `toggleRevenueAdvanced` to also handle the full-section toggle (`toggleRevenueSection`): set `aria-expanded` on trigger, rotate chevron icon (toggle a `rotate-180` class on the chevron span), toggle `hidden` on the section container. Apply the same aria-expanded + icon-rotation pattern to the references disclosure toggle.
- [X] T017 [P] [US4] Remove dead `article-form#touchDirty` dispatch from `app/views/article_references/_form.html.erb` (the remove button's `data-action` chain). The `touchDirty()` method in `article_form_controller.js` is an intentional no-op (issue #1839) — the autosave already fires via `article-revenue#calReferenceRatio`. Optionally remove the empty `touchDirty()` method from `article_form_controller.js` if no other references remain.
- [X] T018 [US4] Scope tag suggestions in `app/views/articles/_option_fields.html.erb` line 36 — change `Tag.all.first(10).pluck(:name)` to `Tag.recommended.limit(10).pluck(:name)`. The `Tag.recommended` scope (`order(articles_count: :desc, created_at: :desc)`) already exists at `app/models/tag.rb:28`. Fixes B3.
- [X] T019 [US4] Add system test in `test/system/article_editor_test.rb` — "test revenue section collapsed by default" (open settings, assert revenue fields not visible, assert customize button present) and "test revenue expands and validates" (click customize, adjust readers ratio, assert author ratio recalculates) and "test references collapsed by default" (assert cite-advanced button present, references not visible).

**Checkpoint**: All power features are behind explicit gates. User Stories 1–4 all work independently. All confirmed bugs (B1–B5) are resolved.

---

## Phase 7: User Story 5 — Confident Publishing with Inline Readiness (Priority: P3)

**Goal**: A readiness indicator in the editor chrome shows what needs fixing before publishing. The author sees blockers before clicking "Publish."

**Independent Test**: Open a draft with no title, verify readiness indicator shows a blocker count. Complete the draft, verify "Ready to publish."

### Implementation for User Story 5

- [X] T020 [US5] Add readiness indicator element to `app/views/articles/_edit_form.html.erb` editor chrome — a small pill/badge next to the publish button (e.g., `<span data-article-form-target="readinessIndicator">`). Initial content from server: a count of missing required fields (title, intro, content) or "Ready" if all present. Use `t("articles.readiness.things_to_fix", count: N)` and `t("articles.readiness.ready")`.
- [X] T021 [US5] Extend `app/javascript/controllers/article_form_controller.js` — add a `readinessIndicator` target and an `updateReadiness()` method that checks: title present (`#article_title` value non-blank), intro present (`#article_intro` value non-blank), content present (`contentValue` non-blank). Update the indicator text and styling (warning color if blockers, success color if ready). Call `updateReadiness()` on title `input`, intro `input`, and content `lexxy:change` events (reuse existing action wiring). Only show the indicator on persisted records (not new records before first autosave).
- [X] T022 [US5] Add system test in `test/system/article_editor_test.rb` — "test readiness indicator shows blocker count" (open incomplete draft, assert indicator shows "N things to fix") and "test readiness indicator shows ready" (complete all fields, assert "Ready to publish").

**Checkpoint**: All user stories complete. Publishing has inline readiness feedback.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Lint, test, and validate the complete feature.

- [X] T023 [P] Run `bin/rubocop` and fix any offenses in touched Ruby files (`app/controllers/articles_controller.rb`)
- [X] T024 [P] Run `bun run lint-check` and fix any offenses in touched JS files (`app/javascript/controllers/article_form_controller.js`, `article_revenue_controller.js`, `textarea_controller.js`, `index.js`)
- [X] T025 Run `bin/rails zeitwerk:check` — verify no autoloading errors from the new `textarea_controller.js` registration
- [X] T026 Run `bin/rails test` — verify all existing tests pass (no regression) and all new tests pass
- [X] T027 Run all 9 validation scenarios from `specs/010-editor-progressive-disclosure/quickstart.md` manually in the browser

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Empty — no blocking prerequisites
- **User Stories (Phase 3–7)**: All depend on Phase 1 (T001 i18n keys, T002 textarea controller)
- **Polish (Phase 8)**: Depends on all user stories being complete

### Same-File Conflict Chains (MUST be sequential)

These files are modified across multiple stories. Tasks touching the same file MUST be executed sequentially:

| File | Tasks (in order) |
|------|-----------------|
| `app/views/articles/_option_fields.html.erb` | T006 (US2 pricing) → T014 (US4 revenue) → T015 (US4 references) → T018 (US4 tags) |
| `app/javascript/controllers/article_form_controller.js` | T007 (US2 pricing) → T011 (US3 conflict) → T021 (US5 readiness) |
| `app/views/articles/_edit_form.html.erb` | T004 (US1 chrome) → T020 (US5 readiness) |
| `test/system/article_editor_test.rb` | T005 → T008 → T012 → T019 → T022 |

### User Story Dependencies

- **US1 (P1)**: Depends on T001, T002 only. No dependencies on other stories. **MVP.**
- **US2 (P2)**: Depends on T001. No dependencies on other stories (but shares `_option_fields.html.erb` and `article_form_controller.js` — coordinate sequentially).
- **US3 (P2)**: Depends on T001, T002 (textarea controller). No dependencies on other stories.
- **US4 (P3)**: Depends on T001. No dependencies on other stories (but shares `_option_fields.html.erb` — must follow US2's changes to that file).
- **US5 (P3)**: Depends on T001. No dependencies on other stories (but shares `article_form_controller.js` and `_edit_form.html.erb`).

### Parallel Opportunities

- T001 (locale YAML) ∥ T002 (textarea controller) — different files
- T003 (CSS) ∥ T004 (views) — different files within US1
- T006 (_option_fields) ∥ T007 (article_form_controller) — different files within US2
- T009 (new conflict partial) ∥ T013 (controller test) — different files within US3
- T016 (revenue controller) ∥ T017 (references form) — different files within US4
- T023 (rubocop) ∥ T024 (lint-check) — different tools in Polish
- Different user stories can be worked on in parallel by different developers IF same-file conflicts are coordinated (see table above)

---

## Parallel Example: User Story 2

```bash
# These touch different files and can run in parallel:
Task: "T006 Refactor pricing section in app/views/articles/_option_fields.html.erb"
Task: "T007 Extend app/javascript/controllers/article_form_controller.js with USD conversion"
```

## Parallel Example: User Story 4

```bash
# These touch different files and can run in parallel:
Task: "T016 Extend article_revenue_controller.js with disclosure toggle indicators"
Task: "T017 Remove dead touchDirty dispatch from article_references/_form.html.erb"
# But T014, T015, T018 all touch _option_fields.html.erb — MUST be sequential:
Task: "T014 Refactor revenue section" → "T015 Refactor references section" → "T018 Scope tag suggestions"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001 i18n keys, T002 textarea controller)
2. Complete Phase 3: User Story 1 (T003 CSS, T004 chrome, T005 test)
3. **STOP and VALIDATE**: Open editor — verify distraction-free surface works
4. Deploy/demo if ready — the editor is now clean by default

### Incremental Delivery

1. Setup → Foundation ready
2. US1 (distraction-free) → Test → Deploy (MVP — immediate UX win)
3. US2 (USD pricing) → Test → Deploy (pricing is intuitive)
4. US3 (conflict resolution + intro resize) → Test → Deploy (reliability win)
5. US4 (power features gated) → Test → Deploy (clean settings panel)
6. US5 (readiness indicator) → Test → Deploy (confident publishing)
7. Polish → Lint + full test suite + manual validation

### Bug Fix Delivery (can ship independently)

The confirmed bugs map to specific tasks and can be shipped as hotfixes if needed:
- B1 (missing textarea controller) → T002 (foundational, standalone)
- B2 (price formatting) → T007 (within US2)
- B3 (tag leak) → T018 (within US4)
- B4 (dead touchDirty) → T017 (within US4)
- B5 (no toggle indicator) → T016 (within US4)
- B6 (silent conflict loss) → T009–T011 (within US3)

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- The `_option_fields.html.erb` file is the hottest — 4 tasks touch it; execute sequentially
- The `article_form_controller.js` file is the second hottest — 3 tasks touch it; execute sequentially
- Zero migrations, zero model changes — all work is views, JS, CSS, locale YAML, and one controller method refinement
- Verify `bin/rubocop`, `bun run lint-check`, `bin/rails test`, `bin/rails zeitwerk:check` all pass before merge

---

## Phase 9: Convergence

- [X] T028 CRITICAL: On autosave HTTP 409 in `app/javascript/controllers/article_form_controller.js`, explicitly `renderTurboStream()` (or equivalent) for the conflict response so `_conflict_resolution` appears and `#article-form-meta` lock_version updates — `@rails/request.js` only auto-streams 200/422, not 409; without this, `keepMyVersion` reuses a stale lock and the resolution UI never mounts per FR-009 / FR-010 / US3/AC1 / US3/AC2 (partial)
- [X] T029 Implement the missing system coverage in `test/system/article_editor_test.rb` claimed by T005/T008/T012/T019/T022 — progressive disclosure defaults + settings toggle, USD price/presets/formatting, conflict keep-my-version + intro auto-resize, revenue/references collapsed gates, readiness blocker/ready states — per Constitution II / SC-003 / SC-004 / SC-005 / SC-006 (missing)
- [X] T030 Replace the currency `turbo_frame: :modal` full-grid picker in `app/views/articles/_option_fields.html.erb` with a lightweight inline selector (default BTC) that updates the crypto equivalent without a full-screen modal grid per FR-006 / US2/AC4 / plan:editor-ui-contract (contradicts)
- [X] T031 Wire publish-readiness i18n end-to-end: pass `articles.readiness.*` into the Stimulus controller (e.g. `data-article-form-readiness-translations-value` on `_edit_form.html.erb`) and stop hardcoding English `"N thing(s) to fix"` in `updateReadiness()` per FR-020 / Constitution III (partial)
- [X] T032 When the revenue section is collapsed, surface `t("articles.revenue.default_summary")` next to the Customize affordance in `app/views/articles/_option_fields.html.erb` (locale key exists but is unused) per plan:editor-ui-contract revenue section (missing)
- [X] T033 Extend `updateReadiness()` in `app/javascript/controllers/article_form_controller.js` to treat invalid/missing price as a blocker (not only blank title/intro/content) per FR-015 / plan:R10 (partial)
- [X] T034 Review or remove `dismissConflict` / the X button on `_conflict_resolution.html.erb` so authors cannot dismiss the resolution affordance without choosing Reload latest or Keep my version per FR-009 (unrequested)
- [X] T035 Remove the leftover no-op `touchDirty()` (and stale comment claiming views still bind it) from `app/javascript/controllers/article_form_controller.js` now that `article_references/_form.html.erb` no longer dispatches it per plan:B4 / T017 (unrequested)
