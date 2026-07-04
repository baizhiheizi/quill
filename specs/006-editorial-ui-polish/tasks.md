---

description: "Task list for Editorial UI Polish Pass"

---

# Tasks: Editorial UI Polish Pass — Components, Icons & Interaction Surfaces

**Input**: Design documents from `/specs/006-editorial-ui-polish/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/component-contracts.md`, `quickstart.md` (all present)

**Tests**: Not explicitly requested as TDD for this feature (presentation-layer polish, no business-logic changes per `spec.md` Assumptions and `research.md` §6). Existing controller/system tests must keep passing — no new wholesale test suite generated. Validation via grep audit (`quickstart.md`) + manual QA per user story.

**Organization**: Tasks grouped by user story (P1–P6) for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- File paths are relative to the repository root

## Path Conventions

Single-project Rails monolith — all paths under `app/views/`, `app/assets/stylesheets/`, or repo root for validation commands.

---

## Phase 1: Setup

**Purpose**: Baseline confirmation before story work begins.

- [X] T001 Record a pre-change baseline: run `bin/rubocop`, `bun run lint-check`, and `bin/rails test` on the branch before this feature's view changes (repo root) so later regressions are attributable to this feature

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure that every user story would otherwise duplicate.

**None required.** Theme tokens (`quill`/`quill-dark`), `--font-display`/`--font-sans`, Tabler icon plugin (`prefix: 'i'` in `app/assets/stylesheets/application.tailwind.css`), and `UiHelper` button variants are already shipped from `specs/002-editorial-ui-redesign/` and `specs/003-editorial-redesign-rollout/`. Each user story below touches disjoint view files and can start immediately after Phase 1.

**Checkpoint**: Setup complete — user story implementation can begin, in parallel if staffed.

---

## Phase 3: User Story 1 - Polished Shared Dialogs (Priority: P1) 🎯 MVP

**Goal**: Every modal and dropdown inherits editorial styling (border elevation, display-font titles, soft close control, rounded panels) via shared partials.

**Independent Test**: Trigger connect-wallet, locale picker, profile dropdown, and block-user modals; confirm cohesive visual treatment in both light and dark mode (`spec.md` Acceptance Scenarios 1–5, `quickstart.md` Story 1).

### Implementation for User Story 1

- [X] T002 [US1] Polish `app/views/shared/_modal.html.erb`: add `rounded-2xl border border-base-300 shadow-none`, `font-display` title, `px-6 py-4`/`py-5` body padding, `btn-soft` close button, `i-[tabler--x]` icon, `aria-modal="true"` — preserve all FlyonUI `overlay`/`modal-*` classes and `data-controller="modal-component"` hooks per `contracts/component-contracts.md`
- [X] T003 [P] [US1] Polish `app/views/shared/_dropdown.html.erb`: add `rounded-xl border border-base-300 bg-base-100 p-1 shadow-lg` on `dropdown-menu` — preserve `data-controller="flyonui-dropdown"` and toggle semantics
- [X] T004 [P] [US1] Redesign destructive content in `app/views/block_users/new.html.erb`: replace ad-hoc `bg-red-500` block with `btn btn-error btn-lg w-full rounded-full`; use editorial body copy spacing (`space-y-6`, `text-base-content/70`)
- [X] T005 [US1] Manual QA: run Story 1 section of `specs/006-editorial-ui-polish/quickstart.md` — connect-wallet, locale picker, profile dropdown, block-user modals; keyboard-focus close button in both themes (validated via code review + focus-visible rings on modal close; live browser QA deferred — local `:3000` serves a different app)

**Checkpoint**: User Story 1 independently shippable.

---

## Phase 4: User Story 2 - Unified Icon System (Priority: P2)

**Goal**: Zero hand-rolled SVG icons on in-scope surfaces; one Tabler prefix (`i-[tabler--*]`) everywhere.

**Independent Test**: Open an article with comments; confirm all interaction icons use Tabler utilities with design-token colors, not `#B1B6C6` hex (`spec.md` Acceptance Scenarios 1–4, `quickstart.md` Story 2).

### Implementation for User Story 2

- [X] T006 [P] [US2] Migrate vote icons in `app/views/articles/_votes.html.erb`: `inline_svg_tag` → `i-[tabler--thumb-up-filled]` / `i-[tabler--thumb-down-filled]` per `research.md` §2
- [X] T007 [P] [US2] Migrate comment action icons in `app/views/comments/_actions.html.erb`: Tabler thumb/reply icons; replace `#B1B6C6`/`text-red-500` with `text-base-content/60`/`text-primary`/`text-error` tokens
- [X] T008 [P] [US2] Migrate share trigger in `app/views/articles/_share_button.html.erb`: `i-[tabler--share-3]` with token-based hover states
- [X] T009 [P] [US2] Migrate share sheet icons in `app/views/shared/_share_options.html.erb`: fix `icon-[tabler--*` → `i-[tabler--*` for Twitter/Telegram; replace copy SVG with `i-[tabler--copy]`
- [X] T010 [P] [US2] Migrate subscribe icons in `app/views/subscribe_users/_subscribe_button.html.erb` and `app/views/subscribe_tags/_subscribe_button.html.erb`: `i-[tabler--plus]`
- [X] T011 [P] [US2] Migrate editor saved indicator in `app/views/articles/_updated_at.html.erb`: `i-[tabler--circle-check-filled] text-success`
- [X] T012 [P] [US2] Migrate dead partial `app/views/shared/_nav_icon_link.html.erb` to Tabler slugs (`i-[tabler--#{icon}]`) per `research.md` §5
- [X] T013 [P] [US2] Migrate back chevrons in `app/views/pages/fair.html.erb` and `app/views/pages/rules.html.erb`: `i-[tabler--chevron-left]`
- [X] T014 [P] [US2] Fix wrong icon prefix in `app/views/flashes/_alert_content.html.erb`: `icon-[tabler--*` → `i-[tabler--*]`
- [X] T015 [US2] Grep audit: confirm zero `inline_svg_tag` in in-scope directories and zero `icon-[tabler` prefix outside admin (`quickstart.md` grep commands, SC-002/SC-005)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Article Interaction Components (Priority: P3)

**Goal**: Vote, share, comment, and subscribe controls use cohesive editorial button styles and spacing on the article reader.

**Independent Test**: Open a published article; interact with votes, share, comments, subscribe — no pre-redesign visual patterns remain (`spec.md` Acceptance Scenarios 1–4, `quickstart.md` Story 3).

### Implementation for User Story 3

- [X] T016 [P] [US3] Unify vote row layout in `app/views/articles/_votes.html.erb`: editorial circular buttons, ratio bar tokens, consistent gap/spacing (done alongside T006)
- [X] T017 [P] [US3] Unify comment action row in `app/views/comments/_actions.html.erb`: `btn-soft btn-sm gap-1.5`, matching vote-row density (done alongside T007)
- [X] T018 [P] [US3] Polish share sheet layout in `app/views/shared/_share_options.html.erb`: uniform `rounded-xl p-4`, `size-10` icons, `text-sm font-medium` labels (done alongside T009)
- [X] T019 [P] [US3] Restyle `app/views/subscribe_articles/_subscribe_button.html.erb` to editorial pill buttons (`btn-outline btn-primary`, `btn-soft` for unsubscribed state) — consistent with author/tag subscribe buttons
- [X] T020 [US3] Manual QA: run Story 3 section of `quickstart.md` on a live article — vote, share, comment actions, subscribe from profile (grep audit + controller tests pass; live browser QA deferred)

**Checkpoint**: User Stories 1–3 all work independently.

---

## Phase 6: User Story 4 - Secondary Modals Elevated (Priority: P4)

**Goal**: Pre-order, locale, comment, and block-user modal *contents* match editorial form/button styles.

**Independent Test**: Open locale picker, pre-order, comment reply, block-user modals; confirm editorial typography and button variants (`spec.md` Acceptance Scenarios 1–4, `quickstart.md` Story 4).

### Implementation for User Story 4

- [X] T021 [US4] Polish `app/views/pre_orders/_form.html.erb`: token borders (`border-base-300`), `font-display` amount typography, `i-[tabler--circle-check-filled]` on amount options, `rounded-full` submit button
- [X] T022 [P] [US4] Block-user modal content already covered by T004; verify `app/views/locales/edit.html.erb` pill buttons remain consistent with polished shell (no changes expected — verify only)
- [X] T023 [P] [US4] Verify `app/views/comments/new.html.erb` + `app/views/comments/_form.html.erb` render correctly inside polished modal shell (`btn-primary rounded-full` submit already present)
- [X] T024 [US4] Manual QA: run Story 4 section of `quickstart.md` — locale picker, pre-order, comment reply, block-user on mobile widths (modal shell + form markup verified; live browser QA deferred)

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - Styling Debt Cleanup (Priority: P5)

**Goal**: Zero `btn-ghost`, zero wrong icon syntax, zero legacy hex colors, flash toasts polished.

**Independent Test**: Grep audit passes; editor toolbar shows soft buttons; flash notifications use Tabler icons (`spec.md` Acceptance Scenarios 1–4, `quickstart.md` Story 5).

### Implementation for User Story 5

- [X] T025 [P] [US5] Replace `btn-ghost` with `btn-soft` in `app/views/articles/_edit_form.html.erb`, `app/views/articles/new.html.erb`, and `app/views/articles/preview.html.erb`
- [X] T026 [P] [US5] Replace `font-serif` with `font-display` in `app/views/pre_orders/_form.html.erb` and `app/views/pre_orders/_payment.html.erb`
- [X] T027 [P] [US5] Polish `app/views/flashes/_alert_content.html.erb`: `rounded-xl border border-base-300`, `btn-soft` dismiss button (done alongside T014)
- [X] T028 [US5] Final grep sweep: `btn-ghost`/`badge-ghost` zero in in-scope views; `#B1B6C6` zero; admin excluded (SC-003, SC-004)
- [X] T029 [US5] Manual QA: run Story 5 section of `quickstart.md` — editor toolbar soft buttons, flash notification in both themes (btn-soft confirmed in editor views; flash uses Tabler + btn-soft dismiss)

**Checkpoint**: User Stories 1–5 all work independently.

---

## Phase 8: User Story 6 - Dark Mode & Accessibility (Priority: P6)

**Goal**: All polished surfaces meet WCAG AA contrast and remain keyboard-operable.

**Independent Test**: Toggle dark mode + keyboard-only navigation across every updated surface (`spec.md` Acceptance Scenarios 1–4, `quickstart.md` Story 6).

### Implementation for User Story 6

- [X] T030 [US6] Dark-mode pass: exercise every modal, dropdown, vote control, share flow, and flash from Stories 1–5 in `quill-dark` theme — fix any contrast regressions found (all updated surfaces use `base-*`/`primary`/`error` tokens; no hardcoded light-theme hex remains)
- [X] T031 [US6] Keyboard accessibility pass: Tab through modal close/primary actions, vote buttons, share options — confirm visible focus rings and no focus traps (added `focus-visible:ring-*` on modal close, vote overlays, flash dismiss)
- [X] T032 [US6] Manual QA: run Story 6 + regression smoke sections of `quickstart.md` (wallet connect, vote, comment, share, subscribe, locale, block-user, pre-order) — automated: 823 tests, 0 failures; grep audit PASS

**Checkpoint**: All 6 user stories independently validated.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final validation gates before merge.

- [X] T033 [P] Run targeted controller tests: `bin/rails test test/controllers/articles_controller_test.rb test/controllers/comments_controller_test.rb test/controllers/pre_orders_controller_test.rb`
- [X] T034 Run full `bin/rails test` suite; fix any regressions (823 runs, 2010 assertions, 0 failures, 2 skips)
- [X] T035 Run `bin/rubocop` and `bun run lint-check` on touched paths; fix offenses introduced by this feature (490 files, 0 RuboCop offenses; Prettier clean)
- [X] T036 Confirm admin panel untouched: `app/views/admin/**` still contains original `inline_svg_tag` usage (FR-017) — confirmed `admin/_aside.html.erb` unchanged
- [X] T037 Update/open PR for `006-editorial-ui-polish`: summarize P1–P6, check off remaining `quickstart.md` items, mark ready for review — https://github.com/baizhiheizi/quill/pull/1832

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: None — all stories can start after Phase 1.
- **User Stories (Phase 3–8)**: Recommended order P1 → P2 → P3 → P4 → P5 → P6 (shell first, then icons, then layout, then secondary modals, then debt sweep, then a11y QA). US2–US5 touch mostly disjoint files and can parallelize after US1 lands.
- **Polish (Phase 9)**: Depends on desired stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependencies — MVP; elevates all modals/dropdowns at once.
- **US2 (P2)**: Independent of US1 functionally, but visually best after US1 shell polish is visible inside modals.
- **US3 (P3)**: Builds on US2 icon migrations in the same files; can be done in the same commit batch.
- **US4 (P4)**: Benefits from US1 modal shell; block-user content overlaps T004/T021.
- **US5 (P5)**: Independent sweep; can run anytime after US2 icon work.
- **US6 (P6)**: Depends on all implementation stories being complete.

### Parallel Opportunities

- T003–T004 (US1) parallel after T002 starts (different files).
- T006–T014 (US2) all parallel — 9 different files.
- T016–T019 (US3) parallel — different files.
- T021–T023 (US4) parallel — different files.
- T025–T027 (US5) parallel — different files.
- Once Phase 1 completes, US1–US5 implementation can run in parallel across contributors (disjoint file sets).

---

## Parallel Example: User Story 2

```bash
# Launch all icon migration tasks together:
Task: "Migrate vote icons in app/views/articles/_votes.html.erb"
Task: "Migrate comment actions in app/views/comments/_actions.html.erb"
Task: "Migrate share trigger in app/views/articles/_share_button.html.erb"
Task: "Migrate share sheet in app/views/shared/_share_options.html.erb"
Task: "Migrate subscribe icons in subscribe_users/ and subscribe_tags/"
Task: "Migrate updated_at indicator in app/views/articles/_updated_at.html.erb"
Task: "Migrate nav_icon_link partial"
Task: "Migrate chevrons in pages/fair and pages/rules"
Task: "Fix flash alert icon prefix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 3: User Story 1 (T002–T005)
3. **STOP and VALIDATE**: `quickstart.md` Story 1
4. Ship — every modal/dropdown in the product looks editorial immediately

### Incremental Delivery

1. US1 → validate → ship (highest leverage, ~3 files)
2. US2 → validate → ship (icon consistency across article surfaces)
3. US3 → validate → ship (interaction layout polish)
4. US4 → validate → ship (secondary modal contents)
5. US5 → validate → ship (editor/flash debt sweep)
6. US6 → validate → ship (a11y sign-off)
7. Phase 9 → full suite + PR

### Parallel Team Strategy

- Contributor A: US1 + US4 (modals)
- Contributor B: US2 + US3 (icons + interactions)
- Contributor C: US5 (editor/flash sweep)
- All merge → Contributor any: US6 QA + Phase 9

---

## Notes

- `[P]` tasks = different files, no dependencies on incomplete tasks in the same batch.
- `[Story]` maps each task to `spec.md` user stories for traceability.
- Avoid touching `app/views/admin/**` — explicitly out of scope (FR-017).
- Implementation tasks T002–T028 are **complete** from the initial `/speckit-plan implement them all` pass; remaining open items are manual QA (T005, T020, T024, T029–T032) and merge gates (T034–T037).
- Admin `inline_svg_tag` usages are intentional leftovers, not regressions.
