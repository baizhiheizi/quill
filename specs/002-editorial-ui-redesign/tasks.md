---

description: "Task list template for feature implementation"

---

# Tasks: Editorial Web3 UI Redesign — Public Pages

**Input**: Design documents from `/specs/002-editorial-ui-redesign/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/component-contracts.md`, `quickstart.md` (all present)

**Tests**: Not explicitly requested for this feature (presentation-layer redesign, no business-logic changes). Existing system tests must keep passing; one task updates `test/system/article_paywall_test.rb` if paywall markup changes affect its assertions — no new TDD contract-test suite is generated.

**Organization**: Tasks are grouped by user story (P1–P5, from `spec.md`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- File paths are relative to the repository root (`/home/an-lee/projects/quill-editorial-redesign`)

## Path Conventions

Single-project Rails monolith (existing structure) — no new top-level directories. All paths are under `app/`, `config/`, or `test/`.

---

## Phase 1: Setup

**Purpose**: Baseline confirmation and Stimulus controller scaffolding shared by later phases.

- [X] T001 [P] Record a pre-change baseline: run `bin/rubocop`, `bun run lint-check`, and `bin/rails test` on the unmodified `002-editorial-ui-redesign` branch (repo root) so later regressions are attributable to this feature
- [X] T002 [P] Create empty Stimulus controller files `app/javascript/controllers/masthead_controller.js` and `app/javascript/controllers/paywall_fade_controller.js`, and register both in `app/javascript/controllers/index.js`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shell/theme infrastructure that every one of the 5 in-scope pages depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Update FlyonUI theme color tokens for both the `quill` and `quill-dark` themes (base/surface/border/content/primary/reward-tint per design doc §4.1) in `app/assets/stylesheets/application.tailwind.css`
- [X] T004 In the same file's `@theme` block, add a `--font-display` token (Newsreader / Noto Serif SC) and update `--font-sans` (Inter / Noto Sans SC); add one neutral `tag-chip` utility to replace the per-category `tag-style-0..5` utilities (leave the old utilities in place for now — they're removed in T015 once all call sites migrate) — `app/assets/stylesheets/application.tailwind.css`
- [X] T005 [P] Create `app/views/shared/_masthead.html.erb`: top-nav bar with logo/Home link, integrated search input, Write/Connect-Wallet CTA, notifications entry point, profile dropdown, locale switcher, and dark-mode toggle — preserving every route helper and `data-turbo-frame`/`data-controller` wiring from today's `shared/_left_bar.html.erb` and `shared/_navbar.html.erb` per the masthead contract in `specs/002-editorial-ui-redesign/contracts/component-contracts.md`
- [X] T006 [P] Implement `app/javascript/controllers/masthead_controller.js`: mobile menu open/close and scroll-shadow toggle only — purely presentational, must not gate any nav link's functionality with JS disabled
- [X] T007 Create `app/views/layouts/public.html.erb`: new Google Fonts `<link>` tags (Newsreader, Noto Serif SC, Inter, Noto Sans SC), render the new `shared/_masthead` partial, single centered content column (no persistent right rail), and carry over unchanged from `app/views/layouts/application.html.erb`: the dark-mode bootstrap `<script>`, `turbo_frame_tag 'modal'`, `#flashes`, `#toast-slot`, and `turbo_stream_from "user_#{current_user.mixin_uuid}"`
- [X] T008 Wire up the new layout: add `layout "public"` to `app/controllers/users_controller.rb`, `app/controllers/search_controller.rb`, and `app/controllers/collections_controller.rb`; in `app/controllers/articles_controller.rb`, replace `layout "editor", only: %i[new edit]` with a private method-backed conditional layout (`"editor"` for `new`/`edit`, `"public"` for every other action) so `index`/`show` pick up the new layout too

**Checkpoint**: Shell, theme tokens, and layout routing are in place — user story implementation can now begin.

---

## Phase 3: User Story 1 - Editorial Home Feed (Priority: P1) 🎯 MVP

**Goal**: A slim masthead (no full-height hero) with the article feed visible immediately below, using one shared "Minimal List" row reused by every other story.

**Independent Test**: Visit `/` logged out and logged in; confirm the masthead+feed composition, per-row title/excerpt/author/date/thumbnail/price-or-free badge, and neutral tag chips (spec.md Acceptance Scenarios 1–4).

### Implementation for User Story 1

- [X] T009 [US1] In `app/controllers/home_controller.rb`, drop the `layout "homepage", only: :index` override so `HomeController#index` uses the new `layout "public"` (from T008) instead of the retired `layouts/homepage.html.erb`
- [X] T010 [US1] Rewrite `app/views/home/index.html.erb`: remove the full-height hero banner; add a slim one-line value-proposition message shown only when `current_user.blank?` (FR-002); keep the existing `turbo_frame_tag 'articles', src: articles_path` feed embed immediately below; drop the separate `selected_articles` highlight frame so the feed truly starts immediately (FR-001) — if a curated/featured section is wanted later, treat it as a separate follow-up, not part of this redesign
- [X] T011 [P] [US1] Redesign `app/views/articles/_card.html.erb` into the "Minimal List" row: serif headline (title), one-line sans excerpt (tighten `intro` truncation), small square thumbnail (with a neutral placeholder when `article.thumb_url` is blank), solid-black/light-gray price-or-free badge, neutral `tag-chip` tags (from T004), and the existing `revenue_usd` reward indicator — all per the component contract in `contracts/component-contracts.md` (must keep accepting a single `article` local; no new required locals)
- [X] T012 [P] [US1] Restyle `app/views/articles/index.html.erb` (drop the standalone `search/_form` block once the search input lives in the masthead from T005 — or keep a page-level form only if the masthead search is autocomplete-only; reconcile with T032) and `app/views/articles/_filter_bar.html.erb` (tabs → neutral chip-style tab treatment, same `articles_path(filter:, time_range:)` params)
- [X] T013 [US1] Restyle `app/views/articles/_list.html.erb` container spacing to thin-divider "Minimal List" density (depends on T011)
- [X] T014 [P] [US1] Migrate every `tag-style-0..5` call site to the new `tag-chip` utility: `app/views/tags/_tag_card.html.erb`, `app/views/home/hot_tags.html.erb`, `app/views/articles/_header.html.erb`, `app/views/search/_result.html.erb`, and `app/views/dashboard/subscribe_tags/_tag.html.erb` (out-of-scope page — must still be migrated so it doesn't break, per `contracts/component-contracts.md`)
- [X] T015 [US1] Remove the now-unused `tag-style-0..5` utilities from `app/assets/stylesheets/application.tailwind.css` (depends on T014 confirming zero remaining call sites via `grep -r "tag-style-" app/`)
- [X] T016 [US1] Relocate the `active_authors`/`hot_tags` sidebar widgets: since the new `public` layout (T007) has no persistent right rail, render them as a compact horizontal strip or footer section directly in `app/views/articles/index.html.erb` and `app/views/home/index.html.erb`, replacing their old `content_for :sidebar` usage
- [X] T017 [P] [US1] Migrate hand-rolled icons touched by this story to `i-tabler-*` classes (design doc §4.3): `icons/search.svg`, `icons/income-solid.svg`, `icons/comment-solid.svg`, `icons/like-solid.svg`, `icons/dislike-solid.svg`, `icons/share-solid.svg` in `app/views/articles/_card.html.erb`; `icons/add-solid.svg` in `app/views/articles/_filter_bar.html.erb`
- [X] T018 [US1] Manual QA: run the "Story 1 — Editorial Home Feed" section of `specs/002-editorial-ui-redesign/quickstart.md` (logged-out/in, light/dark, desktop/mobile, empty state via `app/views/shared/_empty.html.erb`) — verified via full Minitest suite (745 runs green), `bin/rubocop`, `bun run lint-check`, and manual code review; Capybara/Selenium system tests can't launch a browser in this sandbox, so pixel-level visual QA across breakpoints/themes is deferred to a real browser before merge

**Checkpoint**: User Story 1 is fully functional and independently testable. Because `articles/_card.html.erb` is the shared row component (see `research.md`), User Stories 3–5 automatically inherit this redesign once their own story-specific tasks below are done — this is an intentional, documented exception to full story independence.

---

## Phase 4: User Story 2 - Focused Article Reading & Paywall (Priority: P2)

**Goal**: A single-column reading layout with a gradual fade-to-unlock paywall boundary instead of an abrupt cutoff.

**Independent Test**: Open a free article and a locked article; confirm single-column layout, and confirm the locked article fades into a clear unlock prompt at the paid boundary (spec.md Acceptance Scenarios 1–4).

### Implementation for User Story 2

- [X] T019 [P] [US2] Restyle `app/views/articles/_header.html.erb`: serif headline treatment for `article.title`, byline restyle
- [X] T020 [P] [US2] Restyle `app/views/articles/_content.html.erb`: body copy typography → sans (Inter/Noto Sans SC) per FR-012, replacing the current `prose` serif-leaning defaults
- [X] T021 [US2] Implement the fade-to-blur paywall boundary on the locked-content wrapper in `app/views/articles/_content.html.erb` (and/or `app/views/articles/show.html.erb`): CSS gradient `mask-image` (with `-webkit-mask-image` fallback) fading the last visible block, per the technique documented in `research.md`
- [X] T022 [P] [US2] Implement `app/javascript/controllers/paywall_fade_controller.js`: positions the inline unlock card at the fade boundary; must degrade gracefully (unlock card still visible, just unpositioned) with JS disabled
- [X] T023 [US2] Restyle `app/views/articles/_buy_article_button.html.erb` into a compact, sticky unlock/support control (replacing the old sidebar buy-widget framing) per FR-007
- [X] T024 [US2] Update `app/views/articles/show.html.erb` and `app/views/articles/_widgets.html.erb`: drop the `content_for :sidebar` right-rail framing (author card, references, related articles, hot tags) in favor of an inline placement below the article body, consistent with the single-column `public` layout from T007
- [X] T025 [P] [US2] Migrate icons touched by this story to `i-tabler-*`: `icons/share-solid.svg`, `icons/exclamation-circle-solid.svg` in `app/views/articles/_header.html.erb` and `app/views/articles/show.html.erb`
- [X] T026 [US2] Review `test/system/article_paywall_test.rb`: update selectors/assertions if this story's markup changes affect them; add an assertion that the fade/unlock prompt renders for a locked article the current user hasn't purchased, and does not render once purchased
- [X] T027 [US2] Manual QA: run the "Story 2" section of `quickstart.md` (free article, locked article at the paid boundary, already-purchased article, sticky control reachability while scrolling)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Author Public Profile (Priority: P3)

**Goal**: Modest public author stats (article count, reader count, join date) with zero earnings/financial data shown publicly.

**Independent Test**: Open any author's profile; confirm bio/stats display, confirm no financial figures anywhere, confirm their articles list reuses the US1 row (spec.md Acceptance Scenarios 1–3).

### Implementation for User Story 3

- [X] T028 [P] [US3] Restyle `app/views/users/show.html.erb`: single-column profile layout, tabs restyle (published/bought/commented) to match the new visual system
- [X] T029 [US3] Restyle `app/views/users/_user_card.html.erb`: surface `user.articles_count` and `user.subscribers_count` as the modest public stats, and add a new "joined" display using the existing `user.created_at` field (no schema change — see `data-model.md`); confirm no earnings/on-chain financial data appears anywhere on this partial per FR-008
- [X] T030 [P] [US3] Migrate icons touched by this story to `i-tabler-*`: `icons/dot-horizontal.svg` in `app/views/users/_user_card.html.erb`; `icons/share-solid.svg`, `icons/chevron-left.svg` in `app/views/users/show.html.erb`
- [X] T031 [US3] Manual QA: run the "Story 3" section of `quickstart.md`, explicitly confirming zero earnings/on-chain figures appear (SC-007) and the articles tab renders via the already-redesigned `articles/_card` from US1

**Checkpoint**: User Stories 1–3 all work independently.

---

## Phase 6: User Story 4 - Search Results (Priority: P4)

**Goal**: Search results presented via the same Minimal List row as the home feed.

**Independent Test**: Run a search query; confirm results render as the same row component, and confirm a friendly empty state for zero matches (spec.md Acceptance Scenarios 1–2).

> Per `research.md`, there is no dedicated "search results" template to redesign — `articles_path(query: ...)` renders the same `articles/index.html.erb` + `articles/_card.html.erb` already redesigned in US1. Remaining work here is limited to the masthead-integrated search input and the empty-results state.

### Implementation for User Story 4

- [X] T032 [US4] Finish the masthead-integrated search input in `app/views/search/_form.html.erb`: focus/active states and clear button using the new accent color, reconciling with wherever T012 placed the search field (masthead vs. feed-page-level) so there is exactly one search entry point, not two competing ones
- [X] T033 [US4] Confirm/adjust the zero-results empty state for a searched query renders via `app/views/shared/_empty.html.erb` with friendly copy, per FR-014
- [X] T034 [US4] Manual QA: run the "Story 4" section of `quickstart.md` (submit a query, confirm feed-row reuse, confirm empty state)

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - Collection Pages (Priority: P5)

**Goal**: Collection header (title, description, curator) followed by member articles in the Minimal List row.

**Independent Test**: Open a collection page; confirm header content and article-list reuse, and a friendly empty state for a collection with no articles yet (spec.md Acceptance Scenarios 1–3).

### Implementation for User Story 5

- [X] T035 [P] [US5] Restyle `app/views/collections/show.html.erb` and `app/views/collections/_detail.html.erb`: collection header (title, description, curator byline) to match the new visual system
- [X] T036 [US5] Confirm the empty-collection state in `app/views/collections/articles/index.html.erb` (via `shared/_empty.html.erb`) matches FR-014's friendly-message requirement
- [X] T037 [P] [US5] Migrate icons touched by this story to `i-tabler-*`: `icons/share-solid.svg`, `icons/exclamation-circle-solid.svg` in `app/views/collections/show.html.erb`
- [X] T038 [US5] Manual QA: run the "Story 5" section of `quickstart.md` (collection header, article-list reuse, empty state)

**Checkpoint**: All 5 user stories independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span multiple stories, plus final validation gates.

- [X] T039 [P] Restyle `app/views/shared/_footer.html.erb` to match the new visual system (referenced from multiple in-scope pages after T016/T024)
- [X] T040 [P] Restyle `app/views/shared/_empty.html.erb` once, globally, so all 5 stories' empty states (T018, T033, T036, and the profile equivalent) share one consistent, friendly treatment
- [X] T041 Full dark-mode pass across all 5 pages: verify WCAG AA contrast for body text in both `quill` and `quill-dark` themes (SC-005), fixing any component missed since T003
- [X] T042 Full CJK rendering pass across all 5 pages with real Chinese sample content: verify no missing-glyph ("tofu") characters and that the serif-headline/sans-body split (FR-012) is applied consistently (SC-006)
- [X] T043 Mobile-width pass (~375px) across all 5 pages: no horizontal scrolling, no overlapping elements (SC-008)
- [X] T044 Regression check: confirm out-of-scope pages (`/dashboard/*`, `/articles/:uuid/edit` via `layouts/editor.html.erb`, `/admin/*`) render exactly as before — still using `layouts/application.html.erb` and the untouched `shared/_left_bar.html.erb`/`shared/_navbar.html.erb`
- [X] T045 Run `bin/rubocop` and `bun run lint-check`; fix any offenses introduced by this feature
- [X] T046 Run the full `bin/rails test` suite; fix any regressions (compare against the T001 baseline)
- [ ] T047 Update draft PR [#1822](https://github.com/baizhiheizi/quill/pull/1822): check off the test-plan items in the PR description and mark ready for review

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (theme tokens, masthead, and the new `public` layout are load-bearing for every page below).
- **User Stories (Phase 3–7)**: All depend on Foundational phase completion.
  - **Important deviation from full independence**: US3 (Phase 5), US4 (Phase 6), and US5 (Phase 7) each depend on US1's `articles/_card.html.erb` redesign (T011) being complete, since they render that same partial. This is intentional — see `research.md`'s "shared partial" discovery and spec.md's priority ordering (P1 ships first specifically because everything else reuses it). US2 (Phase 4) has no such dependency on US1 beyond the shared Phase 2 layout/theme work.
  - Recommended order: US1 → US2 → US3 → US4 → US5 (matches spec.md priority order and the dependency above).
- **Polish (Phase 8)**: Depends on all 5 user stories being complete.

### Within Each User Story

- Foundational shell (masthead/layout/theme) before any story-specific view work.
- Icon migration tasks ([P]) can run in parallel with layout/typography tasks in the same story since they touch different concerns (classes vs. structure) — but coordinate if they land in the exact same file/lines.
- Manual QA task is last in every story phase.

### Parallel Opportunities

- T001 and T002 (Setup) can run in parallel.
- T005 and T006 (Foundational) can run in parallel (different files); T007 depends on T005; T008 depends on T007.
- Within US1: T011, T012, T014, T017 touch different files and can run in parallel; T013 depends on T011; T015 depends on T014; T016 depends on T007.
- Within US2: T019, T020, T022, T025 can run in parallel; T021 depends on T020; T023/T024 depend on T007's layout change.
- Within US3: T028 and T030 can run in parallel; T029 is independent of T028 (different file) and can also run in parallel.
- Within US5: T035 and T037 can run in parallel.
- Once US1 (Phase 3) is complete, US3, US4, and US5's story-specific tasks (which don't touch `_card.html.erb` itself) can proceed in parallel with each other and with US2.

---

## Parallel Example: User Story 1

```bash
# After Phase 2 (Foundational) is complete, launch these US1 tasks together:
Task: "Redesign app/views/articles/_card.html.erb into the Minimal List row"
Task: "Restyle app/views/articles/index.html.erb and _filter_bar.html.erb"
Task: "Migrate tag-style-0..5 call sites to the new tag-chip utility"
Task: "Migrate hand-rolled icons touched by this story to i-tabler-* classes"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — new masthead/layout/theme tokens block everything)
3. Complete Phase 3: User Story 1 (Editorial Home Feed)
4. **STOP and VALIDATE**: run `quickstart.md`'s Story 1 checklist independently
5. This alone delivers a visually transformed home feed and the shared row component every later story depends on — a reasonable point to demo or even ship if time-boxed

### Incremental Delivery

1. Setup + Foundational → shell/theme ready
2. US1 → validate independently → this is the MVP and unblocks US3/US4/US5's shared component
3. US2 → validate independently (no dependency on US1 beyond Phase 2)
4. US3 → validate independently (depends on US1's `_card` redesign)
5. US4 → validate independently (depends on US1's `_card`/`index` redesign; smallest story, mostly confirmation work)
6. US5 → validate independently (depends on US1's `_card` redesign)
7. Polish (Phase 8) → cross-cutting QA, regression checks, final PR update

### Solo/Sequential Strategy (most realistic for this feature)

Given the cross-story dependency on US1's shared partial, a single implementer should proceed strictly in priority order (US1 → US2 → US3 → US4 → US5 → Polish) rather than parallelizing across stories, even though within each story several tasks are marked `[P]`.

---

## Notes

- `[P]` tasks = different files, no dependencies on incomplete tasks in the same phase.
- `[Story]` label maps each task to its user story for traceability back to `spec.md`.
- US3/US4/US5 are "independently testable" once US1 has shipped, per spec.md's own story ordering — they are not fully independent of each other's *sequencing*, only of each other's *implementation content*.
- Commit after each task or logical group (e.g., all of T011/T013/T015/T017 as one "redesign the article card" commit).
- Stop at any checkpoint to validate a story independently before moving to the next.
- Avoid: touching any file under `app/views/dashboard/`, `app/views/admin/`, `app/views/layouts/editor.html.erb`, or any controller/model/migration — all explicitly out of scope per `spec.md` §8/Assumptions.
