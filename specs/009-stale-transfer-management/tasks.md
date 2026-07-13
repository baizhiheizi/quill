# Tasks: Stale Transfer Management

**Input**: Design documents from `/specs/009-stale-transfer-management/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Per Quill Constitution §II, include test tasks for all non-trivial behavior (models, controllers). Omit tests only for purely presentational changes with no behavioral impact.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Rails monolith: `app/`, `db/`, `config/`, `test/` at repository root
- Paths shown below reflect the project structure in plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure development environment is ready and required tools are available

- [x] T001 Verify `bin/rails db:setup` and `bin/rails zeitwerk:check` pass clean before starting

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database migration, model changes, routes, and locale that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Create migration `db/migrate/*_add_stale_fields_to_transfers.rb` adding `stale_at :datetime`, `staled_by_id :bigint`, and composite index `[:processed_at, :stale_at]` on `transfers`
- [x] T003 Run `bin/rails db:migrate` and verify columns and index exist via `bin/rails runner "puts Transfer.columns_hash.keys"`  
- [x] T004 [P] Update `Transfer` model in `app/models/transfer.rb`: modify `unprocessed` scope to exclude `stale_at IS NOT NULL`; add `stale` scope, `stale?`, `stale!(admin)`, and `reactivate!` methods per data-model.md
- [x] T005 [P] Add `stale` and `reactivate` member routes in `config/routes/admin.rb` under existing `resources :transfers` block
- [x] T006 [P] Create `config/locales/admin.en.yml` with transfer state labels (Stale, Unprocessed, Processed), action labels (Mark Stale, Reactivate), and confirmation prompt per research.md

**Checkpoint**: Foundation ready — schema migrated, Transfer model updated, routes registered, locales available

---

## Phase 3: User Story 1 - Mark Transfer as Stale (Priority: P1) 🎯 MVP

**Goal**: Administrator can mark an unprocessed transfer as stale from the admin list, immediately excluding it from all automated processing (both `process_pending!` and the monitor job).

**Independent Test**: Mark an unprocessed transfer as stale via the admin interface, then run `Transfer.process_pending!` — the transfer must NOT be processed. Verify `stale_at` and `staled_by_id` are set, `retry_at` is cleared.

### Implementation for User Story 1

- [x] T007 [US1] Update `app/views/admin/transfers/_transfer.html.erb`: add stale badge (`badge badge-warning`) in the state column and "Mark Stale" action button for unprocessed transfers using `button_to` with `data: { confirm: }` confirmation prompt
- [x] T008 [US1] Create `app/views/admin/transfers/stale.turbo_stream.erb` that replaces the transfer row via `turbo_stream.replace dom_id(@transfer)` re-rendering the updated partial
- [x] T009 [US1] Add `stale` action to `app/controllers/admin/transfers_controller.rb`: find transfer, guard against processed transfers, call `transfer.stale!(current_admin)`, respond with Turbo Stream

### Tests for User Story 1 (Constitution §II)

- [x] T010 [P] [US1] Add model tests in `test/models/transfer_test.rb`: `stale?` returns true when `stale_at` is set; `stale!` sets `stale_at`/`staled_by_id` and clears `retry_at`; `stale!` raises when transfer is already processed; `unprocessed` scope excludes stale transfers; `process_pending!` skips stale transfers
- [x] T011 [US1] Add controller tests in `test/controllers/admin/transfers_controller_test.rb` (new file): POST stale returns Turbo Stream success for unprocessed transfer; POST stale returns 422 for processed transfer; stale action sets `stale_at` and `staled_by_id`; unauthenticated access redirects to login

**Checkpoint**: Admin can mark transfers as stale; stale transfers are excluded from processing queue

---

## Phase 4: User Story 2 - View and Filter Stale Transfers (Priority: P2)

**Goal**: Administrator can filter the transfer list by stale state and see a visually distinct badge on stale transfer rows.

**Independent Test**: Mark several transfers as stale, filter the admin list by "Stale" state — only stale transfers appear. Filter by "Unprocessed" — stale transfers are excluded. View a stale transfer row — badge shows "Stale" (yellow).

### Implementation for User Story 2

- [x] T012 [US2] Update `app/views/admin/transfers/_query.html.erb`: add `['Stale', 'stale']` option to the state select dropdown
- [x] T013 [US2] Update `app/controllers/admin/transfers_controller.rb#index`: add `when "stale"` branch using `transfers.stale` to the existing state filter case statement
- [x] T014 [US2] Update `app/views/admin/transfers/show.html.erb`: display stale state badge in the transfer detail view when `transfer.stale?`

### Tests for User Story 2 (Constitution §II)

- [x] T015 [P] [US2] Add controller tests in `test/controllers/admin/transfers_controller_test.rb`: GET index with `state=stale` returns only stale transfers; GET index with `state=unprocessed` excludes stale transfers; transfer row partial renders stale badge for stale transfers

**Checkpoint**: Admin can filter and visually identify stale transfers in the list and detail view

---

## Phase 5: User Story 3 - Reactivate a Stale Transfer (Priority: P3)

**Goal**: Administrator can reverse a stale marking, returning the transfer to eligible unprocessed status for retry.

**Independent Test**: Mark a transfer as stale, then click "Reactivate" — the row updates to show "Unprocessed" badge and the "Process"/"Mark Stale" buttons reappear. Run `Transfer.process_pending!` — the reactivated transfer is processed normally.

### Implementation for User Story 3

- [x] T016 [US3] Update `app/views/admin/transfers/_transfer.html.erb`: add "Reactivate" action button (`button_to`) that appears only for stale transfers alongside the existing "Detail" button
- [x] T017 [US3] Create `app/views/admin/transfers/reactivate.turbo_stream.erb` that replaces the transfer row via `turbo_stream.replace dom_id(@transfer)` showing the unprocessed badge and restored action buttons
- [x] T018 [US3] Add `reactivate` action to `app/controllers/admin/transfers_controller.rb`: find transfer, guard against processed transfers, call `transfer.reactivate!`, respond with Turbo Stream

### Tests for User Story 3 (Constitution §II)

- [x] T019 [P] [US3] Add model tests in `test/models/transfer_test.rb`: `reactivate!` clears `stale_at` and `staled_by_id`; `reactivate!` raises when transfer is processed; reactivated transfer is included in `unprocessed` scope; `process_pending!` processes reactivated transfers
- [x] T020 [US3] Add controller tests in `test/controllers/admin/transfers_controller_test.rb`: POST reactivate returns Turbo Stream success for stale transfer; POST reactivate returns 422 for already-processed transfer; POST reactivate returns 422 for non-stale transfer

**Checkpoint**: All user stories independently functional — stale, filter, and reactivate complete

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, linting, and quality assurance

- [x] T021 Run full test suite: `bin/rails test` — all tests pass
- [x] T022 Run autoloading check: `bin/rails zeitwerk:check` — no errors
- [x] T023 [P] Run Ruby lint: `bin/rubocop` — clean on all changed files
- [x] T024 [P] Run JS lint: `bun run lint-check` — clean (no JS changes expected, but verify)
- [x] T025 Validate against `specs/009-stale-transfer-management/quickstart.md` scenarios: verify all 6 validation scenarios pass end-to-end
- [x] T026 Run model annotations: `bin/rails annotate_routes` or verify `bin/annotaterb` updates schema annotations in `app/models/transfer.rb`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) — MVP
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2); may depend on US1 for the stale badge in the row partial (already implemented in T007)
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2); may depend on US1 for the row partial base
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories. Can start after Phase 2.
- **User Story 2 (P2)**: Depends on US1's _transfer.html.erb changes (T007) for the stale badge. Filter logic is independent. Can start after T007 completes.
- **User Story 3 (P3)**: Depends on US1's _transfer.html.erb changes (T007) for the row partial. Adds Reactivate button. Can start after T007 completes.

### Within Each User Story

- Views before controller actions (controller renders views)
- Controller actions before controller tests (tests hit endpoints)
- Model tests [P] can run in parallel with other same-story tasks
- Turbo Stream views [P] can run in parallel with each other

### Parallel Opportunities

- T004, T005, T006 (Foundational) can all run in parallel — different files
- T007, T008 (US1 views) can run in parallel — different files
- T010, T011 (US1 tests) can run in parallel — different files
- T016, T017 (US3 views) can run in parallel — different files
- T019, T020 (US3 tests) can run in parallel — different files
- T023, T024 (Polish lint) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch view tasks for US1 together (different files):
Task: "Update _transfer.html.erb: stale badge + Mark Stale button"
Task: "Create stale.turbo_stream.erb"

# Launch test tasks for US1 together (different files):
Task: "Add model tests in test/models/transfer_test.rb"
Task: "Add controller tests in test/controllers/admin/transfers_controller_test.rb"
```

---

## Parallel Example: Foundational Phase

```bash
# Launch all [P] foundational tasks together (different files):
Task: "Update Transfer model in app/models/transfer.rb"
Task: "Add routes in config/routes/admin.rb"
Task: "Create config/locales/admin.en.yml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently — mark a transfer as stale, verify it's excluded from `process_pending!`
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (filter + visibility)
4. Add User Story 3 → Test independently → Deploy/Demo (reactivation)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:
1. Team completes Setup + Foundational together
2. Once Foundational is done and T007 (row partial) completes:
   - Developer A: User Story 1 (stale action + controller + tests)
   - Developer B: User Story 2 (filter + show view + tests, after T007)
   - Developer C: User Story 3 (reactivate + views + tests, after T007)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- The `_transfer.html.erb` partial is modified by both US1 (T007) and US3 (T016) — implement sequentially
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
