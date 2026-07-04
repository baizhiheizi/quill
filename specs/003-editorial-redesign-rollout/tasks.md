---

description: "Task list template for feature implementation"

---

# Tasks: Editorial Redesign Rollout — Dashboard, Editor, Modal & Remaining Polish

**Input**: Design documents from `/specs/003-editorial-redesign-rollout/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/component-contracts.md`, `quickstart.md` (all present)

**Tests**: Not explicitly requested as TDD for this feature (presentation-layer rollout, no business-logic changes for 5 of 6 stories). One story (US2, default covers) introduces genuinely new behavior and gets model-level test coverage; existing test suites across dashboard/articles/system tests must keep passing — no new wholesale Capybara suite is generated (Selenium can't launch a browser in this sandbox, per `research.md` §8, same limitation documented in `specs/002-editorial-ui-redesign/tasks.md`).

**Organization**: Tasks are grouped by user story (P1–P6, from `spec.md`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- File paths are relative to the repository root

## Path Conventions

Single-project Rails monolith (existing structure) — no new top-level directories. All paths are under `app/`, `config/`, or `test/`.

---

## Phase 1: Setup

**Purpose**: Baseline confirmation before any story work begins.

- [X] T001 Record a pre-change baseline: run `bin/rubocop`, `bun run lint-check`, and `bin/rails test` on the unmodified `003-editorial-redesign-rollout` branch (repo root) so later regressions are attributable to this feature

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure that every user story would otherwise duplicate.

**None required.** Unlike `specs/002-editorial-ui-redesign/` (which had to build the theme tokens, masthead, and a new layout from scratch as blocking prerequisites), this feature builds entirely on infrastructure already shipped in that prior feature: the `quill`/`quill-dark` FlyonUI theme tokens, `--font-display`/`--font-sans`, the neutral `tag-chip` utility, and `i-tabler-*` icons are all already defined and already content-scanned globally (`app/assets/stylesheets/application.tailwind.css`'s `@source '../../views/**/*.{html,turbo_stream}.erb'` covers every view in the app, including `app/views/dashboard/**`, confirmed during planning — no Tailwind config change needed). Each of the 6 user stories below can therefore start immediately after Phase 1, independently and in any order.

**Checkpoint**: Setup complete — user story implementation can begin, in parallel if staffed.

---

## Phase 3: User Story 1 - Correct Button & Badge Styling (Priority: P1) 🎯 MVP

**Goal**: Every `-ghost` button/badge (unstyled today, since FlyonUI only ships `-soft`) is corrected to `-soft`, plus a small discovered `font-serif` inconsistency on the article page is cleaned up.

**Independent Test**: Load any page with the masthead visible and any article card/header with a locale badge; confirm every control has a visible low-emphasis background/hover treatment in both light and dark mode (spec.md Acceptance Scenarios 1–3).

### Implementation for User Story 1

- [X] T002 [P] [US1] Replace all 4 `btn-ghost` occurrences with `btn-soft` in `app/views/shared/_masthead.html.erb` (notification bell, dark-mode toggle ×2, locale-switcher/login icon buttons) — verify hover/focus states in both `quill` and `quill-dark` themes
- [X] T003 [P] [US1] Replace `badge-ghost` with `badge-soft` in `app/views/articles/_header.html.erb` (locale indicator)
- [X] T004 [P] [US1] Replace `badge-ghost` with `badge-soft` in `app/views/articles/_card.html.erb` (locale indicator)
- [X] T005 [P] [US1] Replace the leftover `font-serif` usage with `font-display` in `app/views/articles/_comments_card.html.erb` and `app/views/articles/_buyers.html.erb` (both rendered on the already-redesigned `articles/show.html.erb` — discovered consistency gap, `research.md` §2)
- [X] T006 [US1] Manual QA: run the "Story 1" section of `specs/003-editorial-redesign-rollout/quickstart.md`; confirm `grep -rn "btn-ghost\|badge-ghost" app/views` returns zero results (SC-001), and check keyboard-focus states (not just hover) in both themes (Edge Cases)

**Checkpoint**: User Story 1 is fully functional and independently shippable.

---

## Phase 4: User Story 2 - Unique Default Cover for Articles Without One (Priority: P2)

**Goal**: Every cover-less article gets a deterministic, per-article-unique generated cover — reusing the `Collection#generate_cover`/Grover pattern already in the codebase — instead of a blank or generic shared placeholder.

**Independent Test**: Find/create cover-less articles and confirm each shows its own distinct, stable generated cover everywhere thumbnails appear, including social-share/OG-image contexts (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 2

- [X] T007 [US2] Add a `#cover` action to `app/controllers/grover/articles_controller.rb` (mirrors `Grover::CollectionsController#cover`): loads `@article` by `params[:article_uuid]`, sets `@width`/`@height` for the template
- [X] T008 [P] [US2] Create `app/views/grover/articles/cover.html.erb`: a deterministic gradient/pattern background seeded by `@article.uuid` (port the hash-to-hue approach already used client-side in `app/javascript/utils/avatar.js`'s `colorFromSeed` to a Ruby/ERB equivalent), showing only public-safe metadata (title, author name/avatar) consistent with the existing `grover/articles/poster.html.erb` template's scope — MUST be fully deterministic (no `Time.current`/`SecureRandom`)
- [X] T009 [US2] Add `get :cover` under the existing `resources :articles, only: %i[], param: :uuid do ... end` block in `config/routes/grover.rb`, alongside `get :poster`, producing `grover_article_cover_url(uuid, token:, format: :png)`
- [X] T010 [US2] Create `app/jobs/articles/generate_default_cover_job.rb` modeled on `app/jobs/articles/generate_poster_job.rb`: `queue_as :low`, loads the article by id, re-checks `cover.attached?` before generating (idempotent, defends against the real-upload race per FR-006) (depends on T007–T009)
- [X] T011 [US2] Update `app/models/concerns/articles/poster_generator.rb`: `thumb_url`/`cover_url` fall back to enqueuing `Articles::GenerateDefaultCoverJob` and resolving to the generated cover's URL when no real cover is attached and (for paid articles, or free articles with no in-content image) no other image exists — preserve the existing priority order (real cover → in-content image for free articles → generated default) (depends on T010)
- [X] T012 [P] [US2] Update the thumbnail block in `app/views/articles/_card.html.erb`: simplify now that `thumb_url` always resolves to a real URL for published articles, while keeping a defensive blank-check fallback for the drafted/unpublished edge case (per `contracts/component-contracts.md`)
- [X] T013 [US2] Extend `test/models/concerns/articles/poster_generator_test.rb`: new cases for deterministic-per-uuid, visually-distinct-across-articles (assert different seeds → different generated URLs/params), and real-upload-overrides-generated (depends on T011)
- [ ] T014 [US2] Manual QA: run the "Story 2" section of `quickstart.md` — feed/search/profile/collection thumbnails, repeat-view stability, OG/`twitter:image` meta tag inspection, dashboard article listings picking up the same `thumb_url` automatically with no dashboard-side code changes

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Home Page as a Distinct Landing Experience (Priority: P3)

**Goal**: The home page becomes a real landing page — value-proposition content, illustrative platform activity, dual CTAs, and a curated article section — distinct from the plain `/articles` feed it currently re-embeds.

**Independent Test**: Visit `/` as a logged-out desktop visitor and confirm distinct introductory content, working CTAs, and a curated (not raw-feed) article section (spec.md Acceptance Scenarios 1–7).

### Implementation for User Story 3

- [X] T015 [US3] Restyle `app/views/home/selected_articles.html.erb` (existing but currently orphaned since the prior redesign's T010): present its `ArticleSearchService.call(filter: "revenue", time_range: "month").limit(6)` results in a visually distinct "featured" presentation, not the plain `_card` list-row treatment, so it reads as curated rather than a slice of the same feed
- [X] T016 [US3] Rewrite `app/views/home/index.html.erb`: expand the existing one-line value proposition into a fuller introductory section, add an illustrative platform-activity highlight (e.g., article/author counts or aggregate reward figures already computed elsewhere), add two clear CTAs (`articles_path` to read, `new_article_path`/`login_path` to write — matching the masthead's existing primary action per `current_user.present?`), and replace the raw `turbo_frame_tag 'articles', src: articles_path` embed with `turbo_frame_tag 'selected_articles', src: selected_articles_path` (depends on T015)
- [X] T017 [US3] Update `app/controllers/home_controller.rb` if needed: confirm `#selected_articles` still excludes blocked authors/drafts via `ArticleSearchService` (FR-012), and handle the case where fewer than the desired count of qualifying articles exist so the section still renders cleanly (FR-013)
- [X] T018 [P] [US3] Add/update locale strings for the expanded value-proposition and CTA copy in `config/locales/views.en.yml`, `views.zh-CN.yml`, `views.ja.yml`
- [ ] T019 [US3] Manual QA: run the "Story 3" section of `quickstart.md` — logged-out desktop view, near-empty-data case, confirm logged-in/mobile visitors are still redirected to `/articles` unchanged

**Checkpoint**: User Stories 1–3 all work independently.

---

## Phase 6: User Story 4 - Author Dashboard/Studio Redesign (Priority: P4)

**Goal**: Every dashboard section (~77 view files across 24 controllers) visually matches the editorial system, on its existing (restyled, not restructured) left-sidebar/mobile-tabbar shell.

**Independent Test**: Log in and visit every top-level dashboard section; confirm shell + component styling matches the editorial system with zero functional regressions (spec.md Acceptance Scenarios 1–7).

### Implementation for User Story 4

- [X] T020 [US4] Restyle `app/views/shared/_left_bar.html.erb`: colors/typography/spacing to the editorial tokens, migrate its `inline_svg_tag` icons to `i-tabler-*` — navigation links, routes, and `@active_page` matching logic unchanged (per `contracts/component-contracts.md`)
- [X] T021 [P] [US4] Restyle `app/views/shared/_navbar.html.erb` and `app/views/shared/_tabbar.html.erb` (mobile top bar / bottom tab bar) — same restyle-only treatment, structure/behavior unchanged
- [X] T022 [US4] Restyle `app/views/layouts/application.html.erb`: theme-token/typography parity with `layouts/public.html.erb`, restyle the right-aside widget rail (join-Quill card / `active_authors` / `hot_tags` / footer) — depends on T020, T021 for a visually consistent shell
- [X] T023 [P] [US4] Restyle dashboard home/overview pages: `app/views/dashboard/home/{index,stats,readings,authorings,settings}.html.erb`
- [X] T024 [P] [US4] Restyle dashboard articles management: `app/views/dashboard/articles/{index,index.turbo_stream,show,_drafted_article,_hidden_article,_published_article}.html.erb`, `app/views/dashboard/published_articles/{_form,new,update.turbo_stream,destroy.turbo_stream}.html.erb`, `app/views/dashboard/deleted_articles/{new,update.turbo_stream}.html.erb`
- [X] T025 [P] [US4] Restyle dashboard collections management: `app/views/dashboard/collections/{_collection,edit,index,new,show}.html.erb`, `app/views/dashboard/hidden_collections/new.html.erb`, `app/views/dashboard/listed_collections/new.html.erb`
- [X] T026 [P] [US4] Restyle `app/views/dashboard/comments/{_article_comment,_article_comments,_comment,index,index.turbo_stream}.html.erb`
- [X] T027 [P] [US4] Restyle dashboard notifications: `app/views/dashboard/notifications/{index,index.turbo_stream,_notification,show.turbo_stream}.html.erb`, `app/views/dashboard/notification_settings/update.turbo_stream.erb`, `app/views/dashboard/read_notifications/{new,update.turbo_stream}.html.erb`, `app/views/dashboard/deleted_notifications/new.html.erb`
- [X] T028 [P] [US4] Restyle dashboard financial/tabular pages: `app/views/dashboard/orders/{_article_order,_article_orders,index,index.turbo_stream,_user_orders}.html.erb`, `app/views/dashboard/payments/{index,index.turbo_stream,_payment}.html.erb`, `app/views/dashboard/transfers/{index,index.turbo_stream,stats,_transfer}.html.erb` — verify tables/lists remain fully readable under the new typography/color tokens (Edge Cases)
- [X] T029 [P] [US4] Restyle dashboard subscriptions: `app/views/dashboard/subscriptions/index.html.erb`, `app/views/dashboard/subscribe_articles/{_article,index,index.turbo_stream}.html.erb`, `app/views/dashboard/subscribe_tags/{index,index.turbo_stream,_tag}.html.erb` (note: `_tag.html.erb` already migrated to the `tag-chip` utility in the prior redesign — verify, don't regress), `app/views/dashboard/subscribe_users/{index,index.turbo_stream,_user}.html.erb`
- [X] T030 [P] [US4] Restyle `app/views/dashboard/block_users/{index,index.turbo_stream,_user}.html.erb`
- [X] T031 [P] [US4] Restyle `app/views/dashboard/access_tokens/{_access_token,create.turbo_stream,destroy.turbo_stream,_form,index,index.turbo_stream}.html.erb`
- [X] T032 [P] [US4] Restyle `app/views/dashboard/profile_settings/{_avatar_field,_biography_field,edit,_email_field,_name_field,update.turbo_stream,verify_email}.html.erb` and `app/views/dashboard/settings/{_notification,_profile}.html.erb`
- [X] T033 [US4] Confirm zero remaining `inline_svg_tag` usages in `app/views/dashboard` (`grep -rl "inline_svg_tag" app/views/dashboard` returns empty) — depends on T023–T032
- [ ] T034 [US4] Manual QA: run the "Story 4" section of `quickstart.md` across every dashboard section, desktop + mobile, light + dark; confirm every existing action (block a user, generate an access token, change notification settings, etc.) still works end-to-end (FR-020, SC-010)

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - Article Editor Redesign (Priority: P5)

**Goal**: The article creation/editing chrome (toolbar, fields, settings panels) is fully redesigned to the editorial system, with the title field and content surface visually matching how readers see them.

**Independent Test**: Create a new article and edit an existing one; confirm the editor's full chrome is redesigned and every existing capability (autosave, save, publish, settings) still works (spec.md Acceptance Scenarios 1–5).

### Implementation for User Story 5

- [X] T035 [US5] Restyle `app/views/layouts/editor.html.erb`: theme-token/typography parity with the rest of the product; preserve `turbo_frame_tag 'modal'`, `#flashes`, `#toast-slot`, the dark-mode bootstrap script, and `turbo_stream_from` for the current user (per `contracts/component-contracts.md`) — do NOT introduce a masthead or sidebar into this layout
- [X] T036 [US5] Restyle the sticky top bar in `app/views/articles/_edit_form.html.erb` and `app/views/articles/new.html.erb`: button styles (save/publish/edit/options), icon migration (`inline_svg_tag` → `i-tabler-*`) — all `data-action`/`data-*-target` Stimulus wiring preserved verbatim
- [X] T037 [US5] Restyle `app/views/articles/_form.html.erb`: title field typography moves to `font-display` (headline font), intro field restyle — field names/params/autosave wiring unchanged
- [X] T038 [P] [US5] Restyle `app/views/articles/_content_fields.html.erb`: typography parity (`font-sans`/Inter+Noto Sans SC) with the public article reader's body copy
- [X] T039 [US5] Restyle `app/views/articles/_option_fields.html.erb` (271 lines — price, revenue split, cover upload, tags, references panels): component-level restyle of buttons/inputs/tabs/badges to match the rest of the redesigned product; every field/param/validation unchanged
- [ ] T040 [US5] Manual QA: run the "Story 5" section of `quickstart.md` — new/edit article flows, autosave/dirty-indicator/save/publish all function unchanged, mobile-width usability (FR-024, FR-025)

**Checkpoint**: User Stories 1–5 all work independently.

---

## Phase 8: User Story 6 - Wallet-Connect / Login Modal Redesign (Priority: P6)

**Goal**: The login/connect-wallet modal's visual design matches the editorial system from every trigger point, with authentication behavior unchanged.

**Independent Test**: Trigger the modal from both a public page and a dashboard-adjacent entry point; confirm consistent redesigned appearance and an unchanged connection flow (spec.md Acceptance Scenarios 1–3).

### Implementation for User Story 6

- [X] T041 [US6] Redesign `app/views/sessions/new.html.erb`: full visual redesign of the modal content (Mixin Messenger button, terms/privacy links) — preserve both the `from_mixin_messenger?` branch and the `return_to`/`request.referer` param handling on `auth_mixin_path` exactly as today (per `contracts/component-contracts.md`)
- [X] T042 [US6] Verify `app/views/shared/_modal.html.erb` wrapper consistency with the redesigned content (it already uses `btn-text`/`icon-[tabler--x]`, close to the target system) — adjust only if a genuine inconsistency is found; do not restructure it, since it's shared by out-of-scope modals too
- [ ] T043 [US6] Manual QA: run the "Story 6" section of `quickstart.md` — trigger from a public-page CTA and a dashboard-adjacent entry point, both themes, confirm the connection flow still works

**Checkpoint**: All 6 user stories independently functional.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span multiple stories, plus final validation gates.

- [ ] T044 [P] Full dark-mode pass across all 6 stories' surfaces (public pages already covered by `specs/002-editorial-ui-redesign/`, plus dashboard/editor/modal from this feature): verify WCAG AA contrast for text and interactive-control states in both `quill` and `quill-dark` themes (SC-009)
- [X] T045 Regression check: confirm the admin panel (`/admin`, `layouts/admin.html.erb`) renders exactly as before — untouched by this feature (FR-030)
- [X] T046 Run `bin/rubocop` and `bun run lint-check`; fix any offenses introduced by this feature
- [X] T047 Run the full `bin/rails test` suite; fix any regressions (compare against the T001 baseline)
- [ ] T048 Update/open the draft PR for this feature: summarize the P1–P6 rollout, check off the `quickstart.md` test-plan items, and mark ready for review

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: None required — see explanation above. All 6 user stories can start immediately after Phase 1.
- **User Stories (Phase 3–8)**: All depend only on Phase 1 (Setup) completion. Unlike `specs/002-editorial-ui-redesign/`, there is **no cross-story dependency** here (no shared partial like `_card` that multiple stories redesign in lockstep) — each of US1–US6 touches a fully disjoint set of files and can be implemented, tested, and shipped in any order or in parallel.
  - Recommended order (matches spec.md priority, smallest/lowest-risk first): US1 → US2 → US3 → US4 → US5 → US6, since P4 (dashboard) is by far the largest story and benefits from the smaller stories' patterns (e.g., the `-soft` correction from US1, the simplified thumbnail handling from US2) already being fresh/proven before tackling it.
- **Polish (Phase 9)**: Depends on all 6 user stories being complete.

### Within Each User Story

- US2: T007 → T008 → T009 → T010 → T011 → T012/T013 (route/template/job must exist before the model concern wires them up; the test extension depends on the model change).
- US3: T015 → T016 → T017 (restyle the curated partial before embedding it in the rewritten home page; controller check comes after both view changes are drafted so it's validated against the final markup).
- US4: T020/T021 (shell restyle) → T022 (layout, depends on both) → T023–T032 (content groups, all parallel — different files, no dependencies on each other) → T033 (verification, depends on all content groups) → T034 (QA, depends on T033).
- US5: T035 (layout) → T036 → T037 → T038 (parallel with T037, different file) → T039 → T040 (QA last).
- US6: T041 → T042 (verify wrapper after content is redesigned, so any inconsistency is visible) → T043 (QA last).

### Parallel Opportunities

- T002–T005 (US1) touch 5 different files and can all run in parallel.
- T008 and T012 (US2) touch different files than the T007/T009/T010/T011 chain and can be drafted in parallel, though T011 must land after T007–T010 to wire them together.
- T018 (US3, locale files) can run in parallel with T015/T016/T017 (different files).
- T023–T032 (US4, 10 content-group tasks) are the largest parallelization opportunity in this feature — all touch disjoint dashboard subdirectories and can be split across multiple contributors/sessions simultaneously once T020–T022 (shell) land.
- T038 (US5) can run in parallel with T037 (different files).
- Once Phase 1 completes, US1, US2, US3, US4, US5, and US6 can all be started in parallel by different contributors, since none of them share a file.

---

## Parallel Example: User Story 4 (largest story)

```bash
# After T020-T022 (shell) land, launch all 10 content-group tasks together:
Task: "Restyle dashboard home/overview pages (dashboard/home/*)"
Task: "Restyle dashboard articles management (dashboard/articles/*, published_articles/*, deleted_articles/*)"
Task: "Restyle dashboard collections management (dashboard/collections/*, hidden_collections/*, listed_collections/*)"
Task: "Restyle dashboard/comments/*"
Task: "Restyle dashboard notifications (notifications/*, notification_settings/*, read_notifications/*, deleted_notifications/*)"
Task: "Restyle dashboard financial pages (orders/*, payments/*, transfers/*)"
Task: "Restyle dashboard subscriptions (subscriptions/*, subscribe_articles/*, subscribe_tags/*, subscribe_users/*)"
Task: "Restyle dashboard/block_users/*"
Task: "Restyle dashboard/access_tokens/*"
Task: "Restyle dashboard/profile_settings/* and dashboard/settings/*"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 3: User Story 1 (Correct Button & Badge Styling)
3. **STOP and VALIDATE**: run `quickstart.md`'s Story 1 checklist independently
4. This alone fixes a real, visible correctness bug across every already-shipped page in under an hour of work — a reasonable point to ship immediately regardless of the rest of this feature's timeline

### Incremental Delivery

1. Setup → ready immediately (no foundational blockers)
2. US1 → validate independently → ship (smallest, highest-confidence win)
3. US2 → validate independently → ship (self-contained new behavior, well-precedented pattern)
4. US3 → validate independently → ship (public-facing, rounds out the original 002 rollout)
5. US4 → validate independently → ship (largest; consider splitting its 10 content-group tasks across multiple PRs if reviewability is a concern, since they have no interdependencies)
6. US5 → validate independently → ship
7. US6 → validate independently → ship
8. Polish (Phase 9) → cross-cutting QA, regression checks, final PR update

### Parallel Team Strategy

With multiple contributors, since this feature has **no cross-story dependencies** (unlike `specs/002-editorial-ui-redesign/`'s shared `_card` partial):

1. One contributor per user story, all starting immediately after Phase 1.
2. Within US4 alone, the 10 content-group tasks (T023–T032) can be further split across contributors.
3. Integrate and run Phase 9 (Polish) once all desired stories are merged.

---

## Notes

- `[P]` tasks = different files, no dependencies on incomplete tasks in the same phase.
- `[Story]` label maps each task to its user story for traceability back to `spec.md`.
- Unlike the prior feature, stories here are **fully independent** — no story's file changes block another's.
- Commit after each task or logical group (e.g., all of T023–T032 as separate "restyle dashboard X" commits, or grouped by contributor).
- Stop at any checkpoint to validate a story independently before moving to the next.
- Avoid: touching any file under `app/views/admin/`, `app/controllers/admin/`, or `app/views/layouts/admin.html.erb` — explicitly out of scope per `spec.md` FR-030.
