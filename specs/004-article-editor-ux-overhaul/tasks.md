---

description: "Task list template for feature implementation"

---

# Tasks: Article Editor Redesign — Modern, Unified Writing & Publishing Experience

**Input**: Design documents from `/specs/004-article-editor-ux-overhaul/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/component-contracts.md`, `quickstart.md` (all present)

**Tests**: Not explicitly requested as TDD, but this feature introduces genuinely new server-side behavior (autosave consolidation, optimistic locking, tag persistence on create, publish-readiness surfacing, live preview) with currently zero controller-test coverage (`test/controllers/articles_controller_test.rb` has no `new`/`create`/`edit`/`update` tests today) — model/controller-level Minitest coverage is included per user story. No new wholesale Capybara suite is generated (Selenium can't launch a browser in this sandbox, per `specs/002-editorial-ui-redesign/research.md` §8 and `specs/003-editorial-redesign-rollout/tasks.md`); manual QA via `quickstart.md` substitutes where browser-driven coverage isn't feasible here.

**Organization**: Tasks are grouped by user story (P1–P6, from `spec.md`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US6)
- File paths are relative to the repository root

## Path Conventions

Single-project Rails monolith (existing structure) — no new top-level directories. All paths are under `app/`, `config/`, `db/`, or `test/`.

**Unlike `specs/003-editorial-redesign-rollout/`, this feature has real cross-story dependencies** (a presentation-only restyle has none; a behavior/structure redesign does): US2 depends on US1's unified autosave being in place before reorganizing the settings panel; US3 depends on both US1 and US2; US5 (Focus Mode) depends on US3's new persistent layout existing before it can hide/show it. US4 and US6 are independent of the US1→US2→US3 chain and of each other.

---

## Phase 1: Setup

**Purpose**: Baseline confirmation before any story work begins.

- [X] T001 Record a pre-change baseline: run `bin/rubocop`, `bun run lint-check`, and `bin/rails test` on the unmodified `004-article-editor-ux-overhaul` branch (repo root) so later regressions are attributable to this feature

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The one piece of shared infrastructure every reliability-related story task in User Story 1 assumes exists.

- [X] T002 Add the optimistic-locking column: create `db/migrate/<timestamp>_add_lock_version_to_articles.rb` (`add_column :articles, :lock_version, :integer, default: 0, null: false`, per `data-model.md`), then run `bin/rails db:migrate` to update `db/schema.rb`

**Checkpoint**: Schema ready — User Story 1 (and everything that depends on it) can now begin.

---

## Phase 3: User Story 1 - Never Lose Work: Automatic, Continuous Saving (Priority: P1) 🎯 MVP

**Goal**: Autosave is unified into one reliable mechanism covering both content and settings, for new and existing articles, with optimistic-locking-backed last-writer-wins semantics — no explicit "Save Draft" click required.

**Independent Test**: Create a new article and type content without clicking any button; confirm it's saved and the URL updates to the edit page. On an existing article, change a setting (price/tags/cover) without clicking any button; confirm it autosaves the same way content does (spec.md Acceptance Scenarios 1–7).

### Implementation for User Story 1

- [X] T003 [US1] Consolidate `update_content` into `update` in `app/controllers/articles_controller.rb`: remove the `update_content` action (fixes the confirmed `params[:article_uuid]` vs. route's `:uuid` bug per `research.md` §1), rescue `ActiveRecord::StaleObjectError` alongside the existing `ActiveRecord::RecordInvalid` rescue and respond with a 409/conflict turbo_stream per `contracts/component-contracts.md` §1
- [X] T004 [US1] Extend `create` in `app/controllers/articles_controller.rb`: respond with a JSON/turbo_stream payload (`uuid`, `edit_path`, `lock_version`) instead of always redirecting, and call `CreateTagService.call(@article, params[:article][:tag_names] || [])` so tags entered before the first save are no longer dropped (fixes audit finding #3 / FR-008, per `contracts/component-contracts.md` §2)
- [X] T005 [US1] Remove the `put :update_content` route in `config/routes.rb` (resource block at `resources :articles, ..., param: :uuid`)
- [X] T006 [US1] [P] Rewrite `app/views/articles/update.turbo_stream.erb`: targeted updates only (save-status indicator, `#{dom_id article}_words_count`, `#{dom_id article}_updated_at`, new `lock_version`) instead of replacing the entire `_edit_form`, plus a new branch for the conflict (409) response
- [X] T007 [US1] [P] Remove `app/views/articles/update_content.turbo_stream.erb` (superseded by T006)
- [X] T008 [US1] [P] Add a `lock_version` data value and a save-status indicator target (replacing the narrower `notSavedAlert`) in `app/views/articles/_edit_form.html.erb` and `app/views/articles/_form.html.erb`
- [X] T009 [US1] [P] Rewrite `app/javascript/controllers/article_form_controller.js`: introduce the save-status state machine (`idle`/`dirty`/`saving`/`saved`/`error`/`conflict`), unify autosave to cover settings fields as well as content, serialize in-flight autosave requests (never more than one concurrent request), thread `lock_version` through every request/response, and change new-record saving to `post()` (via `@rails/request.js`, mirroring the existing `put()` usage) followed by `history.replaceState(null, "", edit_path)` on success — no full-page reload (per `research.md` §1–§3, `contracts/component-contracts.md` §1–§2)
- [X] T010 [US1] Remove the "Save Draft" button and the `form.submit()` full-page-POST path from `app/views/articles/new.html.erb`; saving now happens exclusively through the autosave flow from T009
- [X] T011 [US1] [P] Extend `test/controllers/articles_controller_test.rb`: coverage for `create` returning the new background/JSON response and persisting tags on first save, `update` accepting partial content-or-settings params through the single endpoint, and the optimistic-locking conflict path (stale `lock_version` → 409, not a silent overwrite)
- [X] T012 [US1] Manual QA: run Scenarios 1 and 2 of `specs/004-article-editor-ux-overhaul/quickstart.md`

**Checkpoint**: User Story 1 is fully functional and independently shippable — every save (new or existing article, content or settings) is automatic and reliable.

---

## Phase 4: User Story 2 - A Settings Panel That's Easy to Understand and Trust (Priority: P2)

**Goal**: The 12-field flat settings list becomes five clearly labeled, grouped sections with a guided, plain-language revenue-split summary (raw ratios behind an "Advanced" toggle) and real-time validation.

**Independent Test**: Open the settings for a new and an existing article; confirm grouped sections, read-only vs. editable fields visually distinguished, and a plain-language revenue-split summary shown before raw percentage fields (spec.md Acceptance Scenarios 1–9).

**Depends on**: User Story 1 (reorganizing settings must not reintroduce a manual "Save" step — it needs T009's unified autosave already in place).

### Implementation for User Story 2

- [X] T013 [US2] Split `app/views/articles/_option_fields.html.erb` into five grouped sections — Cover & Tags, Pricing & Access (price/currency/free-content ratio), Revenue Split, References, Collection — and fix the misplaced validation-error bug (renders `:intro` errors under the Collection field; correct it to show `:collection_id`/`:collection_revenue_ratio` errors there instead, per `research.md` §6)
- [X] T014 [US2] In the Revenue Split section of `app/views/articles/_option_fields.html.erb`, add the plain-language summary markup (default view) plus an "Advanced" disclosure wrapping the raw `readers_revenue_ratio`/`author_revenue_ratio`/`references_revenue_ratio` fields; `platform_revenue_ratio` and `collection_revenue_ratio` remain always-visible, clearly read-only info (never inside the editable "Advanced" set)
- [X] T015 [US2] [P] Add disabled-field explanatory captions (e.g. "Locked after publishing") next to currency and revenue-ratio fields when `form.object.published_at?`, in `app/views/articles/_option_fields.html.erb`
- [X] T016 [US2] Extend `app/javascript/controllers/article_form_controller.js`: add `renderRevenueSummary()` (reusing the existing `updateReadersRevenueRatio`/`calReferenceRatio`/`calAuthorRevenueRatio` calculations), the Advanced-toggle open/close behavior, and real-time sum/bounds validation mirroring `Article#ensure_revenue_ratios_sum_to_one`/`#ensure_references_ratios_correct` so invalid splits are flagged inline before submission
- [X] T017 [US2] Remove the `hideOptionFieldsForNewRecord()` gating in `app/javascript/controllers/article_form_controller.js` and the corresponding hidden state in `app/views/articles/new.html.erb`, so the full (now-grouped) settings panel is visible immediately on a new, unsaved article (FR-015)
- [X] T018 [US2] [P] Replace hard-coded editor strings (subtitle placeholder, price placeholder, new disabled-field captions from T015) with translations in `config/locales/views.en.yml`, `config/locales/views.zh-CN.yml`, `config/locales/views.ja.yml`
- [X] T019 [US2] Manual QA: run Scenario 2 of `specs/004-article-editor-ux-overhaul/quickstart.md`, including the mobile-width check

**Checkpoint**: User Stories 1 AND 2 both work independently — settings are grouped, guided, and autosave the same way content does.

---

## Phase 5: User Story 3 - One Unified Editing Experience (Priority: P3)

**Goal**: The current two-tab "Edit / Options" switcher is replaced by a persistent two-pane layout (writing surface + collapsible Settings rail), so content and settings are simultaneously reachable and captured by one save-status indicator.

**Independent Test**: Move between writing content and adjusting settings on the same article without any tab switch; confirm both are reflected by the same save-status indicator (spec.md Acceptance Scenarios 1–3).

**Depends on**: User Story 1 (unified autosave) and User Story 2 (the five grouped sections that populate the new Settings rail).

### Implementation for User Story 3

- [X] T020 [US3] Redesign `app/views/articles/_form.html.erb`: persistent two-pane layout — the writing surface (title, intro, rich-text body) as the primary column, with the five grouped settings sections (from T013–T014) docked in a collapsible Settings rail, both simultaneously reachable
- [X] T021 [US3] Rework the top bar in `app/views/articles/_edit_form.html.erb`: remove the Edit/Options tab buttons, add a Settings-rail toggle affordance (for mobile), keep the save-status indicator (T008) and the Publish action
- [X] T022 [US3] Update `app/javascript/controllers/article_form_controller.js`: remove the `edit()`/`options()` tab-switching methods and their target show/hide logic, replace with Settings-rail open/close behavior (persistent on desktop, slide-over/bottom-sheet on mobile)
- [X] T023 [US3] [P] Adjust mobile breakpoint styles so the Settings rail collapses into a bottom-sheet/slide-over without horizontal scrolling, overlapping elements, or awkward field stacking
- [X] T024 [US3] Manual QA: run Scenarios 3 and 4 of `specs/004-article-editor-ux-overhaul/quickstart.md`

**Checkpoint**: User Stories 1–3 all work independently — the editor is one continuous, unified surface with no separate save flows.

---

## Phase 6: User Story 4 - Confident, Error-Free Publishing (Priority: P4)

**Goal**: Publish attempts show a specific, itemized reason for any blocker instead of a generic or silent failure.

**Independent Test**: Attempt to publish an article missing required content, and one with an invalid revenue split; confirm each shows a specific, actionable message (spec.md Acceptance Scenarios 1–3).

**Depends on**: Nothing in this feature beyond Phase 2 — independent of the US1→US2→US3 chain, can be implemented in parallel with US2/US3.

### Implementation for User Story 4

- [X] T025 [US4] [P] Update `app/controllers/dashboard/published_articles_controller.rb#new`: compute `@article.valid?` (full validation context, not just the AASM `ensure_content_valid` guard) and expose `@article.errors.full_messages` to the confirmation view (per `research.md` §7, `contracts/component-contracts.md` §3)
- [X] T026 [US4] [P] Update `app/views/dashboard/published_articles/_form.html.erb`: render the itemized readiness list when errors are present; keep the existing "ready to publish" confirmation when the list is empty
- [X] T027 [US4] [P] Fix the stale turbo_stream target in `app/views/dashboard/published_articles/update.turbo_stream.erb`: `turbo_stream.replace "edit_article_#{@article.id}"` → `turbo_stream.replace "#{dom_id @article}_edit_form"` (FR-024, confirmed bug per `research.md` §10)
- [X] T028 [US4] [P] Extend or create `test/controllers/dashboard/published_articles_controller_test.rb`: coverage for the readiness list rendering on an incomplete article and successful publish of a fully valid one
- [X] T029 [US4] Manual QA: run Scenario 5 of `specs/004-article-editor-ux-overhaul/quickstart.md`

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - Distraction-Free Focus Mode (Priority: P5)

**Goal**: An author can collapse the editor's chrome down to just the writing surface (plus a minimal save-status pill) and restore it exactly as it was.

**Independent Test**: Enable Focus Mode while writing; confirm chrome hides, save-status remains visible, and exiting restores the exact prior state (spec.md Acceptance Scenarios 1–4).

**Depends on**: User Story 3 (needs the new persistent top bar + Settings rail to exist before it can be hidden/restored).

### Implementation for User Story 5

- [X] T030 [US5] Add a `focusModeValue` toggle and `Esc`/keyboard-shortcut handling to `app/javascript/controllers/article_form_controller.js`, hiding/restoring the top bar and Settings rail without touching article data or scroll/cursor state
- [X] T031 [US5] Add focus-mode-hideable wrapper classes to the top bar and Settings rail in `app/views/articles/_edit_form.html.erb`, keeping a minimal floating save-status pill visible even while the rest of the chrome is hidden
- [X] T032 [US5] Manual QA: run Scenario 6 of `specs/004-article-editor-ux-overhaul/quickstart.md`

**Checkpoint**: User Stories 1–5 all work independently.

---

## Phase 8: User Story 6 - See It As Readers Will (Live Reader Preview) (Priority: P6)

**Goal**: An author can preview their article exactly as a reader (including the paywall boundary for priced articles) would see it, without leaving the editor.

**Independent Test**: Open the preview for a free article and a priced article; confirm typography parity with the public page and correct paywall-boundary rendering for the priced one (spec.md Acceptance Scenarios 1–4).

**Depends on**: Nothing functionally, but sequenced after User Story 3 to avoid both stories editing the `_edit_form.html.erb` top bar at the same time.

### Implementation for User Story 6

- [X] T033 [US6] [P] Change `preview_article_path` in `config/routes.rb` from `post "/articles/preview"` to a `get :preview` member route under the existing `resources :articles` block
- [X] T034 [US6] Rewrite `articles#preview` in `app/controllers/articles_controller.rb`: load the persisted article by `:uuid` scoped to `current_user.articles` (author-only, mirroring `load_article`), branch on `article.free?` rather than `authorized?(current_user)` (per `research.md` §8)
- [X] T035 [US6] [P] Create `app/views/articles/preview.html.erb` reusing `articles/_full_content` (free articles) and `articles/_partial_content` (priced articles, always the paywall/unlock-card view); remove `app/views/articles/_preview.html.erb` and `app/views/articles/preview.turbo_stream.erb`
- [X] T036 [US6] Add a Preview toggle to the top bar in `app/views/articles/_edit_form.html.erb`, with open/close handling added to `app/javascript/controllers/article_form_controller.js`
- [X] T037 [US6] [P] Extend `test/controllers/articles_controller_test.rb`: preview coverage for a free article (full content), a priced article (paywall boundary rendered), and author-only access enforcement
- [X] T038 [US6] Manual QA: run Scenario 7 of `specs/004-article-editor-ux-overhaul/quickstart.md`

**Checkpoint**: All 6 user stories independently functional.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span multiple stories, plus final validation gates.

- [X] T039 [P] Confirm zero remaining references to the removed `update_content` action/route and the removed `_preview.html.erb`/`preview.turbo_stream.erb` views (`grep -rn "update_content\|preview\.turbo_stream" app config`)
- [X] T040 [P] Full dark-mode + mobile pass across the redesigned editor (top bar, Settings rail, Focus Mode, Preview) reusing the existing `quill`/`quill-dark` tokens from `specs/002-editorial-ui-redesign/`/`specs/003-editorial-redesign-rollout/` — verify WCAG AA contrast for text and interactive-control states
- [X] T041 Run `bin/rubocop` and `bun run lint-check`; fix any offenses introduced by this feature
- [X] T042 Run the full `bin/rails test` suite; fix any regressions (compare against the T001 baseline)
- [X] T043 Update/open the draft PR for this feature: summarize the P1–P6 rollout, check off the `quickstart.md` scenarios, and mark ready for review

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS User Story 1 (and transitively, everything that depends on it).
- **User Story 1 (Phase 3)**: Depends on Phase 2 (`lock_version` column must exist).
- **User Story 2 (Phase 4)**: Depends on User Story 1 (needs unified autosave in place before reorganizing settings).
- **User Story 3 (Phase 5)**: Depends on User Story 1 AND User Story 2 (needs both the unified autosave and the grouped sections to populate the new rail).
- **User Story 4 (Phase 6)**: Depends only on Phase 2 — independent of US1/US2/US3, can run in parallel with them.
- **User Story 5 (Phase 7)**: Depends on User Story 3 (needs the new persistent layout to exist before it can be hidden/restored).
- **User Story 6 (Phase 8)**: Depends only on Phase 2 functionally; sequenced after User Story 3 here to avoid simultaneous edits to `_edit_form.html.erb`'s top bar — could be reordered earlier if staffed by a different contributor working from a rebase plan.
- **Polish (Phase 9)**: Depends on all desired user stories being complete.

### User Story Dependencies (summary)

```
Phase 2 (Foundational)
   └── US1 (P1) ──► US2 (P2) ──► US3 (P3) ──► US5 (P5)
   └── US4 (P4)  [independent, parallel-safe with US2/US3]
   └── US6 (P6)  [independent; sequenced after US3 to avoid file contention]
```

### Within Each User Story

- US1: T003/T004 (controller) and T005 (routes) and T006/T007 (turbo_stream views) and T008 (edit_form/form views) and T009 (JS) can all be drafted in parallel (different files); T010 (remove Save Draft button) depends on T009's new autosave-driven creation flow existing; T011 (tests) depends on T003/T004; T012 (QA) last.
- US2: T013 → T014 (same file, sequential: grouping must land before the Advanced-toggle markup is added inside the Revenue Split section) → T015 (same file, after T013/T014); T016 → T017 (same JS file, sequential — both build on US1's T009 rewrite); T018 (locale files) can run in parallel with T013–T017; T019 (QA) last.
- US3: T020 → T021 (top bar depends on the new two-pane layout existing) → T022 (JS depends on the new DOM structure from T020/T021); T023 (mobile CSS) can run in parallel with T022; T024 (QA) last.
- US4: T025, T026, T027, T028 all touch different files and can run fully in parallel; T029 (QA) last.
- US5: T030 (JS) and T031 (view) can be drafted in parallel but must both land before T032 (QA), since Focus Mode needs both halves working together.
- US6: T033 (routes) and T035 (views) can run in parallel; T034 (controller) depends on T033's route change; T036 (top bar + JS) depends on T034 existing; T037 (tests) depends on T034; T038 (QA) last.

### Parallel Opportunities

- T006, T007, T008, T009 (US1) touch 4 different files and can be drafted in parallel once T003–T005 establish the consolidated endpoint's shape.
- T015 and T018 (US2) can run in parallel with the T013/T014/T016/T017 chain (different files).
- T023 (US3, mobile CSS) can run in parallel with T022 (JS).
- T025–T028 (US4, all 4 tasks) are fully parallelizable — the largest parallelization opportunity in this feature, and the whole story can proceed alongside US2/US3 by a different contributor.
- T033 and T035 (US6) can run in parallel.
- Once Phase 2 completes: US1 must go first; US4 can start immediately in parallel with US1; once US1 finishes, US2 can start while US4 (if not already done) continues; US6 can start any time after Phase 2, though sequencing it after US3 avoids a `_edit_form.html.erb` merge conflict.

---

## Parallel Example: User Story 4 (fully independent story)

```bash
# After Phase 2 completes, launch all of User Story 4 in parallel with User Story 1's work:
Task: "Update dashboard/published_articles_controller.rb#new to compute @article.valid?"
Task: "Update dashboard/published_articles/_form.html.erb with an itemized readiness list"
Task: "Fix the stale turbo_stream target in dashboard/published_articles/update.turbo_stream.erb"
Task: "Extend dashboard/published_articles_controller_test.rb for readiness-list coverage"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (`lock_version` migration — CRITICAL, blocks US1)
3. Complete Phase 3: User Story 1 (Never Lose Work)
4. **STOP and VALIDATE**: run Scenarios 1–2 of `quickstart.md` independently
5. This alone eliminates the highest-cited, highest-risk pain point (silent data loss / manual save) and is a reasonable point to ship regardless of the rest of this feature's timeline

### Incremental Delivery

1. Setup + Foundational → ready
2. US1 → validate independently → ship (autosave everywhere, MVP)
3. US2 → validate independently → ship (grouped, guided settings panel)
4. US3 → validate independently → ship (unified, tab-free layout)
5. US4 → validate independently → ship (can be delivered any time after Phase 2 — doesn't have to wait for US2/US3)
6. US5 → validate independently → ship (requires US3 first)
7. US6 → validate independently → ship (can be delivered any time after Phase 2; sequenced late here only to avoid a merge conflict with US3)
8. Polish (Phase 9) → cross-cutting QA, regression checks, final PR update

### Parallel Team Strategy

With multiple contributors:

1. One contributor drives the US1 → US2 → US3 → US5 chain in order (real dependencies, cannot be parallelized across contributors without heavy coordination).
2. A second contributor can start User Story 4 immediately after Phase 2, fully in parallel with the chain above.
3. A third contributor can start User Story 6 immediately after Phase 2 (accepting a likely rebase against US3's top-bar changes near the end), or wait until US3 lands to avoid that conflict entirely.
4. Integrate and run Phase 9 (Polish) once all desired stories are merged.

---

## Notes

- `[P]` tasks = different files, no dependencies on incomplete tasks in the same phase.
- `[Story]` label maps each task to its user story for traceability back to `spec.md`.
- Unlike `specs/003-editorial-redesign-rollout/`, this feature has **real sequential dependencies** between US1 → US2 → US3 → US5 — respect that order even when parallelizing US4/US6 alongside it.
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently before moving to the next.
- Avoid: touching `app/views/admin/**`, `app/controllers/admin/**`, any `Order`/`Transfer`/revenue-distribution logic, or the AASM state machine's transitions/guards — all explicitly out of scope per `spec.md`'s Assumptions.
