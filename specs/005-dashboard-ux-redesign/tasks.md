---

description: "Task list template for feature implementation"

---

# Tasks: Dashboard UI/UX Redesign — From Zero

**Input**: Design documents from `/specs/005-dashboard-ux-redesign/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/component-contracts.md`, `quickstart.md` (all present)

**Tests**: Per Quill Constitution §II and `research.md` §7/`contracts/component-contracts.md` §3, this feature adds automated test coverage only for the two genuinely new behaviors it introduces — `Dashboard::HomeController#index` rendering a real overview (US2) and the old-URL redirect contract (US1/FR-030). Every other user story is a presentational/structural restructuring of already-implemented, already-correct controllers (FR-029) — no new business logic, so no new test tasks are generated for US3–US7; existing controller tests must simply keep passing (verified in Polish). Capybara/Selenium system tests are not introduced (sandbox cannot launch a browser, per `research.md` §7, same documented limitation as `specs/002-*`/`specs/003-*`).

**Organization**: Tasks are grouped by user story (P1–P7, from `spec.md`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- File paths are relative to the repository root

## Path Conventions

Single-project Rails monolith (existing structure) — no new top-level directories. All paths are under `app/` or `config/`.

---

## Phase 1: Setup

**Purpose**: Baseline confirmation before any story work begins.

- [X] T001 Record a pre-change baseline: run `bin/rubocop`, `bun run lint-check`, and `bin/rails test` on the unmodified `005-dashboard-ux-redesign` branch (repo root) so later regressions are attributable to this feature — baseline: rubocop 487 files/no offenses, prettier clean, `bin/rails test` 813 runs/1977 assertions/0 failures/0 errors/2 skips

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The new navigation shell that every one of the 7 user stories renders inside of. Unlike `specs/003-*` (which restyled the existing shell in place), this feature replaces the shell's structure — every dashboard page would break without it, so it must land first.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Add `@active_section`/`@active_subsection` support to `app/controllers/dashboard/base_controller.rb` (plain instance variables set per-controller, mirroring the existing `@active_page` pattern already used for the old sidebar's highlighting) — per `data-model.md`'s Dashboard Navigation Structure
- [X] T003 [P] Create `app/views/shared/_dashboard_rail.html.erb`: the new grouped rail (Overview / Write / Read / Finances / Account + a persistent Notifications icon+badge, Write CTA, profile dropdown, language/theme controls — carrying over every route helper and Stimulus wiring from today's `shared/_left_bar.html.erb`), initially linking each section to its current best-available existing route (e.g., Write → `dashboard_authorings_path`, Read → `dashboard_readings_path`, Finances → `dashboard_transfers_path`, Account → `dashboard_settings_path`) per `contracts/component-contracts.md` §1 — final canonical section paths land in T008–T010
- [X] T004 [P] Create `app/views/shared/_dashboard_tabbar.html.erb`: mobile bottom-tab equivalent of `_dashboard_rail`, exposing the same 5 groupings + Notifications icon (no divergent mobile-only IA, per FR-006) — carries over wiring from today's `shared/_tabbar.html.erb`
- [X] T005 Wire `app/views/layouts/application.html.erb` to render `_dashboard_rail`/`_dashboard_tabbar` (in place of `_left_bar`/`_tabbar`) for dashboard requests, and suppress the public-page right-aside widget rail (join-Quill card, active-authors/hot-tags frames, footer) for dashboard pages via a `content_for :sidebar` override, per `research.md` §6 — depends on T003, T004
- [X] T006 [P] Add additive top-level route groupings for Overview/Write/Read/Finances/Account under `config/routes/dashboard.rb` (new named routes pointing at existing controller actions; no existing route removed yet) — config/routes/dashboard.rb
- [X] T007 Remove `app/views/shared/_left_bar.html.erb` once T005 is confirmed to be the only remaining reference point (depends on T005). **Deviation**: `shared/_tabbar.html.erb` is NOT removed — it is also rendered by `layouts/public.html.erb` for the public articles-feed page (mobile), which is out of scope for this feature (FR-031); only `layouts/application.html.erb`'s reference was swapped to `_dashboard_tabbar`.

**Checkpoint**: Every dashboard page renders under the new rail/tabbar shell; nothing's internal content has moved yet — user story implementation can now begin.

---

## Phase 3: User Story 1 - A Navigation Structure That Matches How People Actually Use the Dashboard (Priority: P1) 🎯 MVP

**Goal**: Every one of the ~20 existing dashboard features is reachable through the new grouped rail/tabbar within two navigation actions, with a consistent current-location indicator and a closed discoverability gap for API access tokens.

**Independent Test**: Starting only from the dashboard's landing view, locate and open every distinct dashboard feature enumerated in `research.md` §1; confirm each is reachable via the same navigation mechanism and the rail/tabbar indicates current location (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 1

- [X] T008 [US1] Finalize the route redirect map in `config/routes/dashboard.rb` per `data-model.md`'s Route Redirect Map: regroup/rename routes under the Foundational phase's new section groupings, and define redirect targets for every old bookmarkable path (`dashboard_readings_path(tab:)`, `dashboard_authorings_path(tab:)`, `dashboard_settings_path(tab:)`, `dashboard_stats_path`, `dashboard_subscriptions_path(tab:)`, `dashboard_articles_path(tab:)`, etc.) — renamed `Dashboard::HomeController#{authorings,readings,settings}` to `#{write,read,account}`; old actions now issue redirects
- [X] T009 [US1] Update the controller actions backing every old path from T008 to `redirect_to` its new equivalent, translating `tab:`/`role:` params where a clean mapping exists and falling back to the new section's default view otherwise (FR-030) — `app/controllers/dashboard/home_controller.rb`; also repointed internal `redirect_to`/link call sites that used the old path helpers (`dashboard/collections_controller.rb`, `listed_collections_controller.rb`, `hidden_collections_controller.rb`, `sessions_controller.rb`, `views/articles/{new,_edit_form}.html.erb`, `views/collections/_form.html.erb`, `views/dashboard/profile_settings/verify_email.html.erb`) to the new canonical paths directly, avoiding an unnecessary extra redirect hop. **Deviation**: left `shared/_masthead.html.erb` and `shared/_tabbar.html.erb` on the old path helpers — both are out of scope (public-page nav, FR-031) and the paths still resolve correctly via the new redirects.
- [X] T010 [US1] Update `_dashboard_rail.html.erb`/`_dashboard_tabbar.html.erb` (from T003/T004) to link at the new canonical section paths from T008 instead of the Foundational phase's temporary landing routes; wire current-location highlighting using `@active_section`/`@active_subsection` (T002) on every dashboard controller — already used canonical path helpers (`dashboard_write_path` etc.) since Foundational, only `Dashboard::HomeController`'s per-action `@active_section` needed updating for the renamed actions
- [X] T011 [US1] Add a visible Account-section entry point for API access tokens (`dashboard_access_tokens_path`) to `_dashboard_rail.html.erb`/`_dashboard_tabbar.html.erb` — closes the existing zero-entry-point gap (FR-003). Added to the rail's profile dropdown; mobile tabbar reaches it one tap further via the Account icon (documented inline) to avoid a 7th bottom-bar icon, still within SC-001's "two navigation actions"
- [X] T012 [P] [US1] Write `test/controllers/dashboard/routing_redirects_test.rb`: enumerate every old path from `data-model.md`'s Route Redirect Map and assert a non-error (2xx/3xx) response for a signed-in user (FR-030, SC-008) — 7 tests, all passing
- [X] T013 [US1] Manual QA: run the "Story 1" section of `quickstart.md` — confirm every ~20 feature is reachable within two navigation actions (SC-001), the current-location indicator works everywhere, and mobile nav exposes the same groupings as desktop. **Sandbox has no browser** (per research.md §7) — substituted with full-render `ActionController::TestCase` smoke checks (no `render` stub) across all 24 `Dashboard::` controllers confirming 200/302 responses under the new shell; full suite green (820 runs/0 failures) and `bin/rubocop` clean.

**Checkpoint**: User Story 1 is fully functional and independently shippable — MVP.

---

## Phase 4: User Story 2 - A Real Dashboard Home That Shows Me What Matters (Priority: P2)

**Goal**: Opening the dashboard renders a distinct, role-aware overview (unread notifications, earnings snapshot, recent activity, quick actions) instead of redirecting into "My Reading".

**Independent Test**: Open the dashboard's root URL; confirm it renders a distinct overview (not a redirect), and confirm content is accurate for both a reader-only account and an author account (spec.md Acceptance Scenarios 1–6).

### Implementation for User Story 2

- [ ] T014 [US2] Implement `Dashboard::HomeController#index`: replace `redirect_to dashboard_readings_path` with a real action composing `Users::Statable` methods (`unread_notifications_count`, `author_revenue_total_usd`, `reader_revenue_total_usd`, `articles_count`) plus small `.limit(3)` recency queries (`recent_articles`, `recent_reads`) and an `@is_author` flag, per `data-model.md`'s Dashboard Overview entity
- [ ] T015 [P] [US2] Build `app/views/dashboard/home/index.html.erb`: unread-notification indicator with a link into the notifications center, role-aware earnings snapshot, recent-activity list, quick-action shortcuts (write / view earnings / view notifications), and sensible empty states for zero-activity accounts (FR-007–FR-011)
- [ ] T016 [US2] Retire or repurpose `app/views/dashboard/home/stats.html.erb` (confirmed empty/unused in `research.md` §1) — delete it and its now-superseded route/redirect target, or extract a shared stats partial from T015 if useful
- [ ] T017 [P] [US2] Write `test/controllers/dashboard/home_controller_test.rb`: `#index` renders (does not redirect) for a zero-activity user, a reader-only user, and an author user, asserting role-appropriate content is present in each case
- [ ] T018 [US2] Manual QA: run the "Story 2" section of `quickstart.md`

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - An Author Workspace That Feels Like a Writer's Control Center (Priority: P3)

**Goal**: Drafted, published, and hidden articles, collections, and author earnings are consolidated into one purpose-built workspace with inline per-article actions, replacing today's flat 5-tab strip.

**Independent Test**: As an author with a mix of drafted/published/hidden articles and a collection, confirm each status group is clearly distinguished, per-article actions work inline, collections are manageable, and author earnings are visible — all within the same workspace (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 3

- [ ] T019 [US3] Design and build the consolidated authoring workspace view (replacing `app/views/dashboard/home/authorings.html.erb`'s flat 5-tab strip) with status-grouped sections for drafted/published/hidden articles, reusing `Dashboard::ArticlesController#index`/`Dashboard::PublishedArticlesController` unchanged (FR-012, FR-013)
- [ ] T020 [P] [US3] Restructure `app/views/dashboard/articles/{_drafted_article,_hidden_article,_published_article}.html.erb` presentation to fit the new status-grouped workspace layout — no controller/query changes
- [ ] T021 [P] [US3] Embed collection management (`app/views/dashboard/collections/**`, `dashboard/hidden_collections/new.html.erb`, `dashboard/listed_collections/new.html.erb`) as a sub-area within the workspace view, reusing `Dashboard::CollectionsController` unchanged (FR-014)
- [ ] T022 [P] [US3] Embed author-role earnings (`Dashboard::TransfersController#index(tab: "author")`, `app/views/dashboard/transfers/**`) as a sub-area within the workspace view (FR-015)
- [ ] T023 [US3] Manual QA: run the "Story 3" section of `quickstart.md` — edit/publish/hide/delete a draft, create/edit a collection, and view author earnings, all without leaving the workspace

**Checkpoint**: User Stories 1–3 all work independently.

---

## Phase 6: User Story 4 - A Reading Library That Feels Personal (Priority: P4)

**Goal**: Bought articles, comments, subscriptions, and reader-reward activity are consolidated into one coherent personal library, replacing today's flat 5-tab strip.

**Independent Test**: As a reader with purchases, comments, and subscriptions, confirm each category is clearly organized and browsable within one library (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 4

- [ ] T024 [US4] Design and build the consolidated reading-library view (replacing `app/views/dashboard/home/readings.html.erb`'s flat 5-tab strip) with sub-areas for bought articles, my comments, subscriptions, and reader-role earnings (FR-016)
- [ ] T025 [P] [US4] Restructure `app/views/dashboard/comments/**` presentation to fit within the library — no controller/query changes
- [ ] T026 [P] [US4] Restructure `app/views/dashboard/subscriptions/**`, `subscribe_articles/**`, `subscribe_tags/**`, `subscribe_users/**` presentation to fit within the library, each subscription type its own clearly-labeled sub-area with inline unsubscribe (FR-017) — **excluding blocked users**, which moves to the Account area (see T040, per `research.md` §4)
- [ ] T027 [P] [US4] Embed reader-role earnings (`Dashboard::TransfersController#index(tab: "reader")`) as a sub-area within the library view (FR-018)
- [ ] T028 [US4] Manual QA: run the "Story 4" section of `quickstart.md`

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - A Single, Trustworthy Place to Understand My Money (Priority: P5)

**Goal**: Spending (orders/payments) and earnings (reader-reward and author-revenue transfers) are presented as clearly distinguished, article-traceable categories in one Finances section, replacing today's scattered order/payment/transfer tabs.

**Independent Test**: As a user with both purchases and reward transfers, confirm spending and earnings are clearly distinguished, each traceable to its article (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 5

- [ ] T029 [US5] Design and build the consolidated Finances section view: spending (orders/payments) and earnings (reader-reward + author-revenue transfers) as clearly distinguished categories, reusing `Dashboard::OrdersController`, `Dashboard::PaymentsController`, `Dashboard::TransfersController` unchanged (FR-019)
- [ ] T030 [P] [US5] Restructure `app/views/dashboard/payments/**` presentation for the Finances section, ensuring each payment is traceable to its article (FR-020)
- [ ] T031 [P] [US5] Restructure `app/views/dashboard/orders/**` presentation for the Finances section's per-article drill-down (FR-020)
- [ ] T032 [US5] Update `app/views/dashboard/transfers/**` to present reader-reward and author-revenue transfers together for users with both, each clearly attributed to its role (FR-021) — this is the canonical, complete money view (the Write/Read workspaces' T022/T027 embeds remain role-scoped shortcuts into the same underlying data)
- [ ] T033 [US5] Manual QA: run the "Story 5" section of `quickstart.md`

**Checkpoint**: User Stories 1–5 all work independently.

---

## Phase 8: User Story 6 - A Notifications Center I Can Actually Manage (Priority: P6)

**Goal**: Notifications are browsable, markable-as-read, deletable, and configurable from one self-contained center reachable via the persistent icon wired in Foundational/US1.

**Independent Test**: With a mix of read/unread notifications, confirm browsing, marking read, deleting, following to related content, and adjusting preferences all work from the same center (spec.md Acceptance Scenarios 1–4).

### Implementation for User Story 6

- [ ] T034 [US6] Restructure `app/views/dashboard/notifications/**` as a self-contained notifications center reachable via the persistent rail/tabbar icon (T003/T004/T010), reusing `Dashboard::NotificationsController` unchanged (FR-022, FR-023)
- [ ] T035 [P] [US6] Embed notification-type preferences (`Dashboard::NotificationSettingsController`, `app/views/dashboard/notification_settings/update.turbo_stream.erb`) within the same center rather than a separate destination (FR-024)
- [ ] T036 [P] [US6] Verify `app/controllers/dashboard/{read_notifications,deleted_notifications}_controller.rb` mark-read/delete actions integrate cleanly with the restructured center — no logic changes expected
- [ ] T037 [US6] Manual QA: run the "Story 6" section of `quickstart.md`

**Checkpoint**: User Stories 1–6 all work independently.

---

## Phase 9: User Story 7 - Account, Security & Preferences in One Predictable Place (Priority: P7)

**Goal**: Profile, notification preferences, blocked users, API access tokens, and language/theme are all reachable from one predictable Account area — closing the access-tokens discoverability gap for good.

**Independent Test**: Locate and successfully use profile editing, notification preferences, blocked-user management, access-token creation/revocation, and language/theme switching, all from the Account area (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 7

- [ ] T038 [US7] Design and build the consolidated Account area view (replacing `app/views/dashboard/home/settings.html.erb`'s 2-tab strip) with sub-areas for profile, notification preferences (link into US6's center), blocked users, access tokens, and language/theme — reusing existing controllers unchanged (FR-025)
- [ ] T039 [P] [US7] Restructure `app/views/dashboard/profile_settings/**` presentation for the Account area — no controller/validation changes
- [ ] T040 [P] [US7] Move blocked-user management (`app/views/dashboard/block_users/**`) from its current home inside "My Subscriptions" into the Account area, reusing `Dashboard::BlockUsersController` unchanged (per `research.md` §4)
- [ ] T041 [P] [US7] Restyle/embed `app/views/dashboard/access_tokens/**` within the Account area — controller/view already correct; this closes the FR-003 discoverability gap together with T011's nav link
- [ ] T042 [US7] Manual QA: run the "Story 7" section of `quickstart.md` — specifically confirm access-token creation/revocation is reachable end-to-end from Account

**Checkpoint**: All 7 user stories independently functional.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span multiple stories, plus final validation gates.

- [ ] T043 [P] Full light/dark-mode pass across all 7 stories' surfaces: verify WCAG AA contrast for text and interactive-control states in both `quill` and `quill-dark` themes (SC-005)
- [ ] T044 [P] Chinese-glyph rendering check across all redesigned dashboard pages — no missing-glyph ("tofu") characters (SC-006)
- [ ] T045 [P] Responsive check at common mobile, tablet, and desktop widths across all redesigned pages — no horizontal scrolling or overlapping elements (SC-004, FR-028)
- [ ] T046 Regression check: confirm the admin panel, article editor, wallet-connect modal, and public pages render exactly as before — untouched by this feature (FR-031)
- [ ] T047 Run `bin/rubocop` and `bun run lint-check`; fix any offenses introduced by this feature
- [ ] T048 Run the full `bin/rails test` suite (including `test/controllers/dashboard/{notifications,published_articles}_controller_test.rb` to confirm unmodified behavior per `contracts/component-contracts.md` §3) and `bin/rails zeitwerk:check`; fix any regressions against the T001 baseline
- [ ] T049 Update/open the draft PR for this feature: summarize the P1–P7 rollout, check off `quickstart.md`'s test-plan items, and mark ready for review

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — **BLOCKS all user stories**, since it replaces the shell every dashboard page renders inside of.
- **User Stories (Phase 3–9)**: All depend on Foundational (Phase 2) completion.
  - US1 (navigation/redirects) is the recommended first story — it finalizes the canonical section paths (T008) that US2–US7's views will link into, even though each story is independently testable per its own Independent Test.
  - US2–US7 do not depend on each other's *file changes* (each touches a disjoint set of dashboard views/controllers), but US4/US7 have one cross-story note: blocked-user management moves from its current "My Subscriptions" home (touched conceptually by US4) into Account (US7) — see T026/T040.
- **Polish (Phase 10)**: Depends on all 7 user stories being complete.

### Within Each User Story

- US1: T008 → T009 (redirects need the finalized route map) → T010 (nav links need the finalized canonical paths) → T011 (parallel-ish with T010, same files) → T012 [P] (independent test file) → T013 (QA last).
- US2: T014 → T015 (view needs the controller's data) → T016 (depends on T015 confirming nothing still needs `stats.html.erb`) → T017 [P] (independent test file, can be drafted alongside T014) → T018 (QA last).
- US3: T019 → T020/T021/T022 [P] (different files, all depend on T019's overall workspace shell existing) → T023 (QA last).
- US4: T024 → T025/T026/T027 [P] (different files, depend on T024's shell) → T028 (QA last).
- US5: T029 → T030/T031 [P] (different files) → T032 (depends on T029's shell) → T033 (QA last).
- US6: T034 → T035/T036 [P] (different files) → T037 (QA last).
- US7: T038 → T039/T040/T041 [P] (different files) → T042 (QA last).

### Parallel Opportunities

- T002–T004 and T006 (Foundational) touch different files and can run in parallel; T005 and T007 depend on them and run after.
- T012 (US1's redirect test) and T017 (US2's controller test) can be drafted in parallel with their respective story's implementation tasks, different files.
- T020, T021, T022 (US3) are the largest same-story parallelization opportunity after T019 lands — different files, no interdependencies.
- Similarly T025/T026/T027 (US4), T030/T031 (US5), T035/T036 (US6), and T039/T040/T041 (US7) are each parallelizable once their story's shell task lands.
- Once Foundational (Phase 2) completes, US2–US7 can all start in parallel by different contributors even before US1 finalizes canonical paths — they can initially link against the Foundational phase's temporary landing routes (T003) and be re-pointed once T008 lands, since the underlying controllers/views are unaffected by the exact URL.

---

## Parallel Example: User Story 3 (Author Workspace)

```bash
# After T019 (workspace shell) lands, launch all 3 sub-area tasks together:
Task: "Restructure drafted/hidden/published article partials for the new workspace layout"
Task: "Embed collection management as a workspace sub-area"
Task: "Embed author-role earnings as a workspace sub-area"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — replaces the shell every page depends on)
3. Complete Phase 3: User Story 1 (Navigation Structure)
4. **STOP and VALIDATE**: run `quickstart.md`'s Story 1 checklist independently
5. This alone delivers a fully navigable, IA-corrected dashboard (every feature reachable, access tokens finally discoverable) even before any individual section's *content* is restructured — a reasonable point to ship and gather feedback before continuing

### Incremental Delivery

1. Setup + Foundational → shell ready, nothing else has moved yet
2. US1 → validate independently → ship (the foundation every later story's links point at)
3. US2 → validate independently → ship (highest-leverage single page — every session touches it)
4. US3 → validate independently → ship (core producer-side workspace)
5. US4 → validate independently → ship (core consumer-side library)
6. US5 → validate independently → ship (unifies the money story)
7. US6 → validate independently → ship
8. US7 → validate independently → ship (closes the access-tokens gap for good)
9. Polish (Phase 10) → cross-cutting QA, regression checks, final PR update

### Parallel Team Strategy

With multiple contributors, once Foundational (Phase 2) is done:

1. One contributor takes US1 first (finalizes canonical paths quickly, since it's the smallest story after Foundational).
2. Remaining contributors can start US2–US7 in parallel against the Foundational phase's temporary landing routes, re-pointing links once US1's T008 lands (a small, mechanical follow-up per story).
3. Within US3 (largest of the remaining stories), T020–T022 can be further split across contributors.
4. Integrate and run Phase 10 (Polish) once all desired stories are merged.

---

## Notes

- `[P]` tasks = different files, no dependencies on incomplete tasks in the same phase.
- `[Story]` label maps each task to its user story for traceability back to `spec.md`.
- Every controller listed as "reused unchanged" or "no controller/query changes" must stay that way per FR-029 — if implementation reveals a genuine need to change query/authorization logic, stop and revisit the plan rather than silently expanding scope.
- Commit after each task or logical group (e.g., T020/T021/T022 as separate "workspace: articles/collections/earnings" commits).
- Stop at any checkpoint to validate a story independently before moving to the next.
- Avoid: touching `app/views/admin/**`, `app/controllers/admin/**`, `layouts/admin.html.erb`, `layouts/editor.html.erb`, `app/views/shared/_masthead.html.erb` (public top-nav), or any `Order`/`Transfer`/`Payment`/`Article` model or revenue-distribution logic — all explicitly out of scope per `spec.md` FR-031.
