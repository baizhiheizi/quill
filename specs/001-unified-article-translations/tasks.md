---
description: "Task list for Cross-Locale Article Visibility"
---

# Tasks: Cross-Locale Article Visibility

**Input**: Design documents from `/specs/001-unified-article-translations/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/contracts.md, quickstart.md

**Tests**: The spec's success criteria (SC-001 to SC-008) require verifiable assertions. The project's testing culture (Minitest, fixtures, `test/` mirroring `app/`) is followed. Test tasks are included for every behavior change and every "unchanged surface" verification story.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. The feature has 6 user stories (US1, US2, US3, US4, US5, US6) at priorities P1 / P1 / P2 / P2 / P2 / P1. Stories US1 and US3 contain the implementation work; US2, US4, US5, US6 are verification / regression stories that depend on US1 and US3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5, US6)
- Include exact file paths in descriptions

## Path Conventions

This is a single-project Rails app. All paths are absolute under `/home/an-lee/projects/quill/`. Application code lives under `app/`, tests under `test/`, fixtures under `test/fixtures/`, configuration under `config/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the development environment is ready and the existing test suite passes before changes are made.

- [X] T001 Verify baseline: run `bin/rails db:prepare` and `bin/rails test` to confirm the existing suite passes before any change. Document baseline in commit message.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Multi-locale fixtures that every user story needs for verification. Without these, the new tests cannot assert cross-locale visibility.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Add `published_zh` article fixture to `test/fixtures/articles.yml` (state: published, locale: zh, similar shape to `published_paid`)
- [X] T003 [P] Add `published_ja` article fixture to `test/fixtures/articles.yml` (state: published, locale: ja, similar shape to `published_paid`)
- [X] T004 [P] Add `tech_zh` and `tech_ja` tag fixtures to `test/fixtures/tags.yml` (locale: zh and ja respectively, so Tag.hot returns them)
- [X] T005 [P] Add `author_zh` and `author_ja` user fixtures to `test/fixtures/users.yml` (locale: zh-CN and ja, each with at least one qualifying published article and order so User.active returns them)
- [X] T006 Run `bin/rails db:fixtures:load` (or `bin/rails test` setup) to confirm all four new fixtures load without errors and the existing tests still pass

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Visitor sees every article regardless of their locale (Priority: P1) 🎯 MVP

**Goal**: Remove the locale-based filter from the home feed and article search so a Chinese-locale visitor sees articles in every language on `/`, `/articles`, and search results.

**Independent Test**: With `published_zh`, `published_ja`, `published_paid` (existing en) fixtures loaded, visit `/` as a user whose `current_locale` is `zh-CN` and assert that all three articles appear in the home feed (verified via the service-layer test).

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T007 [P] [US1] Add failing test in `test/services/article_search_service_test.rb` asserting that `ArticleSearchService.call(filter: nil, current_user:)` returns articles in all three fixture locales (`zh`, `en`, `ja`) regardless of the caller's `current_user.locale`

### Implementation for User Story 1

- [X] T008 [US1] Delete `@locale` ivar (line 10), `.localize` call (line 33), and entire `#localize` method (lines 57-66) in `app/services/article_search_service.rb`
- [X] T009 [P] [US1] Drop `locale: current_locale` kwarg from `ArticlesController#index` service call at `app/controllers/articles_controller.rb:15`
- [X] T010 [P] [US1] Drop `locale: current_locale` kwarg from `HomeController#selected_articles` service call at `app/controllers/home_controller.rb:11`

**Checkpoint**: User Story 1 should be fully functional and testable independently. The home feed (`/` and `/articles`) returns articles in every language; test T007 passes.

---

## Phase 4: User Story 2 - Search returns matches across all languages (Priority: P1)

**Goal**: Prove that text search and the `subscribed` / `bought` filters return matches in every language (no locale narrowing). The service change already happened in Phase 3 (US1); this phase adds the verification tests.

**Independent Test**: With multi-locale fixtures, run a text query that matches content in `zh` and `en` articles; assert both return. Run `subscribed` and `bought` filters and assert results span every language.

### Tests for User Story 2 ⚠️

- [X] T011 [P] [US2] Add failing tests in `test/services/article_search_service_test.rb` asserting: (a) text query returns matches in multiple languages, (b) `subscribed` filter returns articles from every locale the followed author has published, (c) `bought` filter returns articles from every locale the visitor has purchased

**Checkpoint**: User Stories 1 AND 2 should both work independently. Search and filter behaviors are confirmed cross-locale.

---

## Phase 5: User Story 3 - Tag pages and active-author lists are global (Priority: P2)

**Goal**: Remove the locale filter from the home page's "hot tags" and "active authors" widgets, and surface each article's language on its card and on the article header so visitors can tell what language they will read.

**Independent Test**: With `tech_zh`, `tech_ja`, `web3` (existing en) tag fixtures loaded, fetch `/hot_tags` and assert tags from all three locales appear. With `author_zh`, `author_ja` user fixtures loaded, fetch `/active_authors` and assert all three locales appear. Visit any article page and assert a language chip is rendered.

### Tests for User Story 3 ⚠️

- [X] T012 [P] [US3] Add failing test in `test/controllers/home_controller_test.rb` asserting that `GET /hot_tags` returns tags from every locale (`zh`, `en`, `ja`) for a Chinese-locale visitor
- [X] T013 [P] [US3] Add failing test in `test/controllers/home_controller_test.rb` asserting that `GET /active_authors` returns authors from every locale for a Chinese-locale visitor
- [X] T014 [P] [US3] Add failing test in `test/controllers/articles_controller_test.rb` asserting that `GET /articles` index contains language chips for cards in every locale

### Implementation for User Story 3

- [X] T015 [US3] In `app/controllers/home_controller.rb`: change `Rails.cache.fetch "#{current_locale}_hot_tags"` (line 23) to `Rails.cache.fetch "hot_tags"`; delete `.where(locale: current_locale.to_s.split("-").first)` (line 26) from the `hot_tags` method
- [X] T016 [P] [US3] Delete `.where(locale: current_locale)` (line 37) from the `active_authors` method in `app/controllers/home_controller.rb`
- [X] T017 [P] [US3] Add a small language chip to `app/views/articles/_card.html.erb` rendering `article.locale&.upcase` with a `title` attribute showing the human-readable language name (e.g., `中文`, `English`, `日本語`)
- [X] T018 [P] [US3] Add a language indicator to `app/views/articles/_header.html.erb` near the title, same shape as the card chip (FR-010, SC-007)

**Checkpoint**: Hot tags, active authors, and article card / header language indicators all work. User Stories 1, 2, AND 3 are independently functional.

---

## Phase 6: User Story 4 - Admin and back-office filtering stays available (Priority: P2)

**Goal**: Confirm that the admin articles index locale filter (`EN / ZH / JA / Others`) continues to work exactly as today. No implementation change is required (the admin filter is preserved by FR-008); this phase adds a regression test so the behavior is locked in.

**Independent Test**: Sign in as an admin, visit `/admin/articles?locale=zh`, assert the result set is restricted to articles whose `locale = "zh"`.

### Tests for User Story 4 ⚠️

- [X] T019 [P] [US4] Add regression test in `test/controllers/admin/articles_controller_test.rb` asserting that the admin locale filter narrows results by `articles.locale` for each of `en`, `zh`, `ja`, and `others` (FR-008, SC-004)

**Checkpoint**: Admin back-office filtering is verified to be unchanged. US4 is independently testable.

---

## Phase 7: User Story 5 - Visitor UI language preference is preserved (Priority: P2)

**Goal**: Confirm that the visitor's preferred locale continues to drive UI chrome (buttons, labels, `<html lang>`, navigation) even though it no longer drives article visibility. The locale resolution chain and chrome rendering are unchanged (FR-006, FR-011); this phase adds a regression test.

**Independent Test**: Switch `current_locale` from `:en` to `:zh-CN` and assert that chrome strings (e.g., the search button label) change while the article set is identical.

### Tests for User Story 5 ⚠️

- [X] T020 [P] [US5] Add regression test in `test/controllers/articles_controller_test.rb` (or a new system test under `test/system/` if Capybara is wired up) asserting: switching `session[:current_locale]` from `:en` to `:zh-CN` changes the rendered chrome but the article set returned by `GET /articles` is identical (FR-006, FR-011, SC-006)

**Checkpoint**: Chrome locale preservation is verified. US5 is independently testable.

---

## Phase 8: User Story 6 - Existing data is unchanged (Priority: P1)

**Goal**: Confirm the deployment is a behavior change, not a data migration. Every existing `articles`, `users`, `tags`, `orders`, `comments`, `snapshots`, `transfers` row is byte-identical before and after the deploy. No implementation change is required; this phase adds a verification script and a runbook entry.

**Independent Test**: Run the pre-deploy dump script, deploy, run the post-deploy dump script, diff — there must be zero differences (FR-006, US6, SC-005, SC-008).

### Verification for User Story 6

- [X] T021 [P] [US6] Create verification script `script/data_diff_check.rb` that dumps every `Article`, `Order`, `Comment`, `ArticleSnapshot`, `Transfer` row (id, key fields) to YAML and prints a checksum; the script must be runnable via `bin/rails runner script/data_diff_check.rb` both before and after deploy
- [X] T022 [P] [US6] Update `specs/001-unified-article-translations/quickstart.md` "Rollout" section to reference the verification script and the manual `diff` step (the script is referenced; the manual command remains the acceptance step)
- [X] T023 [US6] Confirm `test/services/orders/distribute_service_article_test.rb` (and any other revenue distribution tests) still pass after all earlier phases land (SC-008)

**Checkpoint**: Rollout gate verified — no data touched. US6 is independently testable.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final quality gates and manual smoke validation.

- [X] T024 [P] Run the full Minitest suite: `bin/rails test`. Confirm zero failures and zero regressions.
- [X] T025 [P] Run `bin/rubocop`. Confirm zero lint errors on the touched files.
- [X] T026 [P] Run `bin/rails zeitwerk:check`. Confirm autoload integrity (no new constants added, but verify).
- [X] T027 [P] Run `bun run lint-check`. Confirm Prettier passes on the unchanged JS bundle.
- [X] T028 [P] Manual smoke test: walk through scenarios 1-10 in `specs/001-unified-article-translations/quickstart.md`. Confirm each acceptance scenario holds.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) completion — **BLOCKS all user stories**. Fixtures must exist before tests can reference them.
- **User Stories (Phase 3+)**: All depend on Foundational (Phase 2) completion.
  - **US1 (P1)**: No dependencies on other stories — pure home-feed change.
  - **US2 (P1)**: Depends on US1 (the service change must be in place for the test to pass); verification only.
  - **US3 (P2)**: No dependencies on other stories — independent home-widget / view change.
  - **US4 (P2)**: Depends on US1 / US3 (must run after any behavior change); verification only.
  - **US5 (P2)**: Depends on US1 (the service change must be in place for the article-set comparison to be meaningful); verification only.
  - **US6 (P1)**: Depends on US1 / US3 / US4 / US5 — final verification gate.
- **Polish (Phase 9)**: Depends on all user stories being complete.

### User Story Dependencies

```
Phase 1 (Setup)
    └── Phase 2 (Foundational: fixtures)
            ├── Phase 3 (US1: home feed global)
            │       ├── Phase 4 (US2: search/subscribed/bought global)
            │       │       └── Phase 8 (US6: data unchanged)
            │       └── Phase 7 (US5: UI locale preserved)
            │               └── Phase 8 (US6)
            ├── Phase 5 (US3: hot tags / active authors / language chip)
            │       └── Phase 6 (US4: admin filter preserved)
            │               └── Phase 8 (US6)
            └── Phase 9 (Polish)
```

### Within Each User Story

- Tests are written first and asserted to fail before implementation (per project TDD convention).
- Service-layer changes happen before caller updates.
- View changes are independent of service changes and can run in parallel within US3.

### Parallel Opportunities

- All Setup tasks are sequential (only T001).
- All Foundational fixture tasks (T002, T003, T004, T005) are **[P]** — different files, no dependencies.
- Within US1: T007 (test) → T008 (service change) → T009 and T010 (callers, [P]). After T008 lands, T009 and T010 can run in parallel.
- Within US2: only T011, which depends on US1's T008 being complete.
- Within US3: T012, T013, T014 (tests, [P]) → T015 (home_controller hot_tags) → T016, T017, T018 (view changes, [P]). After T015 lands, T016 / T017 / T018 can run in parallel.
- US4 (T019), US5 (T020), US6 (T021 / T022 / T023) tests/scripts are [P] within their phase.
- Polish tasks T024 / T025 / T026 / T027 are all [P] and can run concurrently (different tools).

---

## Parallel Example: User Story 1

```bash
# Step 1: write the failing test (T007)
# Run only this test to confirm it fails:
bin/rails test test/services/article_search_service_test.rb -n test_global_feed_includes_all_locales

# Step 2: implement the service change (T008)
# Then re-run the test — it should pass.

# Step 3: drop the locale: kwarg from both callers (T009, T010) in parallel
# (different files, no dependency between them once T008 is done)
```

---

## Parallel Example: User Story 3

```bash
# Step 1: write all three failing tests (T012, T013, T014) in parallel
# (different test files, no dependencies)

# Step 2: implement the hot_tags controller change (T015)

# Step 3: in parallel, run T016 (active_authors controller), T017 (card chip), T018 (header chip)
# (T016 is a separate method in the same controller but can be done independently;
#  T017 and T018 are in different view partials)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 + 6)

The minimum viable deliverable is the core visibility change plus its verification:

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (fixtures)
3. Complete Phase 3: User Story 1 (home feed global)
4. Complete Phase 4: User Story 2 (search/subscribed/bought global)
5. Complete Phase 8: User Story 6 (data unchanged verification gate)
6. **STOP and VALIDATE**: Run full test suite and manual smoke. The home feed and search are now global; admin and chrome are unchanged; data is untouched. **This is shippable as MVP.**

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. Add US1 → home feed global; tests prove it → Demo MVP
3. Add US2 → search/filters verified → Demo
4. Add US3 → hot tags / active authors / language chip → Demo
5. Add US4 → admin filter regression coverage → Demo
6. Add US5 → UI locale regression coverage → Demo
7. Add US6 → data integrity verification gate → Pre-deploy gate
8. Polish → lint, full suite, manual smoke → Deploy

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T006).
2. After Phase 2:
   - **Developer A**: User Story 1 (T007-T010) — service-layer change.
   - **Developer B**: User Story 3 (T012-T018) — controller + view change. Can run in parallel with A; different files.
3. After US1 and US3 complete:
   - **Developer A**: User Story 2 (T011) — search regression.
   - **Developer B**: User Story 4 (T019) — admin regression.
4. After both A and B:
   - **Anyone**: User Story 5 (T020) — UI locale regression.
   - **Anyone**: User Story 6 (T021-T023) — data integrity verification.
5. Polish (T024-T028) — anyone can run lint / zeitwerk / smoke in parallel.

---

## Notes

- [P] tasks = different files, no dependencies. Same-file tasks are sequential even if marked conceptually "parallel".
- [Story] label maps each task to its user story for traceability.
- Each user story is independently completable and testable.
- Tests are written first and asserted to fail before implementation, per project TDD convention.
- Commit after each task or logical group (recommended: one commit per phase).
- Stop at any checkpoint to validate the story independently before moving on.
- Avoid: vague task descriptions, same-file conflicts, cross-story dependencies that break independence.
- The feature is a layer-level change with no schema migration. Deploy = `git pull && bin/rails restart`.