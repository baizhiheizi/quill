---

description: "Task list template for feature implementation"
---

# Tasks: Comprehensive UI Refactor on the Value-Net Design System

**Input**: Design documents from `/specs/011-comprehensive-ui-refactor/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per Quill Constitution §II, every non-trivial presentational behavior change MUST have a corresponding system or unit test. This refactor is presentational but introduces a new design-system controller, a new lint tool, and a new reference page — each gets tests. Pure visual tweaks without behavioral impact (e.g. swapping a Tailwind class on a single view) MAY omit tests, with the omission noted in the PR.

**Organization**: Tasks are grouped by user story (US1 → US4) to enable independent implementation and testing of each story. Within each story, tests are written first; views/partials/stimulus controllers follow; lint enforcement gates the merge.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Rails monolith**: `app/`, `lib/`, `test/`, `config/` at repository root
- No `src/` or `backend/`/`frontend/` split — this is a single Rails project

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Wire the new lint script into CI, snapshot the OpenDesign visual source-of-truth into the repo, and ensure the autoloader can see the new constants.

- [x] T001 Create `bin/lint-design-system` shell wrapper at `bin/lint-design-system` (sets `BUNDLE_GEMFILE`, calls `bundle exec ruby -Ilib -rdesign_system/lint -e 'exit DesignSystem::Lint.run(Rails.root).empty? ? 0 : 1'`)
- [x] T002 [P] Copy OpenDesign brand-spec + 8 HTML prototypes + style.css into `docs/superpowers/specs/opendesign-011/` for offline reference (one-time; OpenDesign remains the live source)
- [x] T003 [P] Add `bin/lint-design-system` invocation to `.github/workflows/check.yml` after the existing `bun run lint-check` step (exit code 0 required)
- [x] T004 Add `# frozen_string_literal: true` and `module DesignSystem; end` namespace file at `lib/design_system.rb` (so Zeitwerk discovers `lib/design_system/lint.rb` and `lib/design_system/primitives.rb`)
- [x] T005 [P] Add `bin/measure-frontend-efficiency` baseline capture script wrapper at `bin/perf-baseline-capture` (runs the existing tool, writes to `specs/011-comprehensive-ui-refactor/perf/baseline.txt`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented. None of US1–US4 can start until this phase is done — every user story depends on the design system primitives + the lint tool + the token layer.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T006 Extend token layer in `app/assets/stylesheets/application.tailwind.css`: add `:root` block declaring `--bg`, `--surface`, `--fg`, `--muted`, `--border`, `--accent`, `--reward`, `--success`, `--warn`, `--danger`, `--ring` using the OKLCh values from `contracts/tokens.md`
- [x] T007 [P] Extend token layer in `app/assets/stylesheets/application.tailwind.css`: add the dark-mode overrides in `[data-theme="quill-dark"]` matching `contracts/tokens.md`
- [x] T008 [P] Extend token layer in `app/assets/stylesheets/application.tailwind.css`: declare `--font-display`, `--font-body`, `--font-mono`, `--radius`, `--radius-lg`, `--radius-full`, the 8pt spacing scale (`--gap-xs/sm/md/lg/xl/2xl`), `--container`, `--measure`, `--gutter` in `:root`
- [x] T009 [P] Add new `@utility` declarations in `app/assets/stylesheets/application.tailwind.css`: `--utility reward-text` (`@apply font-mono text-[13px] text-reward`), `--utility tag-chip` (already present — confirm only), `--utility focus-ring` (`@apply focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`)
- [x] T010 [P] Add the four `--coin-*` declarations in `:root` of `app/assets/stylesheets/application.tailwind.css` (kept as-is, like the Quill logo)
- [x] T011 Add `module DesignSystem; module Lint; class Rule … end; end; end` skeleton at `lib/design_system/lint.rb` with a no-op `Lint.run(_root)` returning `[]`
- [x] T012 [P] Add `module DesignSystem; module Primitives; class Registry … end; end; end` skeleton at `lib/design_system/primitives.rb` with `Registry.all` returning `[]`
- [x] T013 [P] Add `module DesignSystem; class Violation; attr_accessor :rule_id, :severity, :file, :line, :message; def initialize(rule_id:, severity:, file:, line:, message:) … end; end; end` at `lib/design_system/violation.rb`
- [x] T014 Create `DesignSystemController` at `app/controllers/design_system_controller.rb` with `#show` action setting `@page_title = "Design System"` and rendering `design_system/index`; before_action restricts to `Rails.env.development? || current_user&.administrator?`
- [x] T015 [P] Add route `get "/design-system" => "design_system#show"` to `config/routes.rb` inside the existing authenticated-paths block
- [x] T016 [P] Create `app/helpers/design_system_helper.rb` with `render_design_system_section(title:, description: nil, &block)` helper used by the reference page
- [x] T017 [P] Create empty `app/views/design_system/index.html.erb` that yields to `render_design_system_section` per primitive (placeholder sections; populated in US1)
- [x] T018 Confirm `bin/rails zeitwerk:check` passes after the new constants are added (run locally before US1 begins)
- [x] T019 Add `DesignSystem::Lint` allowlist seeds at the bottom of `lib/design_system/lint.rb`: `ALLOWLIST = Set.new([…])` listing `app/views/articles/_card_cover.html.erb` (procedural cover art) + the four `--coin-*` declarations + `<meta name="theme-color">` content attributes

**Checkpoint**: Foundation ready — token layer declared, lint shell + Ruby tool wired, design-system controller mounted, autoloader verified. User stories US1–US4 can now begin (US1 first as MVP, US2/US3/US4 can start in parallel once US1 ships its primitives).

---

## Phase 3: User Story 1 — One Well-Maintained Design System (Priority: P1) 🎯 MVP

**Goal**: Ship the design-system entry point (`/design-system`) that renders every token and every primitive, the seven new shared partials, the lint tool with rules DS001–DS013, and the consolidated helpers. After this phase, every consumer in US2/US3/US4 has a single source-of-truth to consume.

**Independent Test**: As a new contributor, open `/design-system` (logged in as Administrator in production, or any user in development) and confirm every section (Tokens, Type, Buttons, Chips, List Row, Cards, Forms, Tabs, Modal, Dropdown, Value Net, Notifications, States, Masthead, Page Shell) renders a working example of the primitive it documents. Run `bin/lint-design-system` and confirm exit code 0. Run `bin/rails test test/system/design_system_test.rb test/lib/design_system_lint_test.rb` and confirm both pass.

### Tests for User Story 1 (required for non-trivial behavior) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T020 [P] [US1] Write `test/system/design_system_test.rb` asserting `/design-system` renders, contains one labeled section per primitive in `contracts/primitives.md`, and switches theme cleanly when dark mode is toggled
- [x] T021 [P] [US1] Write `test/lib/design_system_lint_test.rb` asserting `DesignSystem::Lint.run(Rails.root)` returns `[]` on a clean checkout and returns one violation per rule when each DS001–DS013 rule is individually triggered in a fixture file
- [x] T022 [P] [US1] Write `test/controllers/design_system_controller_test.rb` asserting the `#show` action is gated to `Administrator` in production and to any user (or anonymous) in development
- [x] T023 [P] [US1] Write `test/helpers/design_system_helper_test.rb` asserting `render_design_system_section` outputs the expected wrapper markup

### Implementation for User Story 1

- [x] T024 [P] [US1] Create `app/views/shared/_button.html.erb` partial (renders a `<button>` or `<a>` with `variant:` / `size:` / `icon:` locals)
- [x] T025 [P] [US1] Add `render_button(label, variant: :primary, size: :md, icon: nil, href: nil, type: "button", **html_options)` to `app/helpers/ui_helper.rb`
- [x] T026 [P] [US1] Create `app/views/shared/_chip.html.erb` partial with `:topic` / `:price` / `:status` / `:reward` variants (reward renders `<span class="text-reward font-mono text-[13px]">`, **never a filled badge**)
- [x] T027 [P] [US1] Add `render_chip(label, kind: :topic, **html_options)` to `app/helpers/ui_helper.rb`
- [x] T028 [P] [US1] Create `app/views/shared/_list_row.html.erb` partial with locals `article:`, `show_topic: true`, `show_excerpt: true`, `show_meta: true`, `show_thumbnail: true`, `target: :self`
- [x] T029 [P] [US1] Add `render_list_row(article, **opts)` to `app/helpers/ui_helper.rb`
- [x] T030 [P] [US1] Create `app/views/shared/_value_note.html.erb` partial with locals `value:`, `label: nil`, `format: :plain` (text-only, never a badge)
- [x] T031 [P] [US1] Create `app/views/shared/_notification_card.html.erb` partial with locals `event:`, `unread: false`
- [x] T032 [P] [US1] Create `app/views/shared/_skeleton.html.erb` partial with locals `width: "w-full"`, `height: "h-4"`, `rounded: "rounded"`
- [x] T033 [P] [US1] Create `app/views/shared/_state_empty.html.erb` partial with locals `icon: "info-circle"`, `title:`, `body: nil`, `action: nil`, `action_href: nil`
- [x] T034 [P] [US1] Create `app/views/shared/_table.html.erb` partial with locals `columns:`, `rows:`, `row_path: nil`, `empty: nil`
- [x] T035 [P] [US1] Add `render_table(columns:, rows:, row_path: nil, empty: nil)` to `app/helpers/ui_helper.rb`
- [x] T036 [P] [US1] Add `render_value_note(value, label: nil, format: :plain)` to `app/helpers/ui_helper.rb`
- [x] T037 [P] [US1] Add `render_notification_card(event, unread: false)` to `app/helpers/ui_helper.rb`
- [x] T038 [P] [US1] Add `render_skeleton(**opts)` to `app/helpers/ui_helper.rb`
- [x] T039 [P] [US1] Add `render_state_empty(**opts)` to `app/helpers/ui_helper.rb`
- [x] T040 [P] [US1] Restyle `app/views/shared/_ui_card.html.erb` to consume the new tokens (no signature change; new optional locals `padding:`, `border:`, `header:`, `footer:`)
- [x] T041 [P] [US1] Restyle `app/views/shared/_ui_input.html.erb` to consume the new tokens (no signature change; new optional locals `hint:`, `error:`)
- [x] T042 [P] [US1] Restyle `app/views/shared/_modal.html.erb` to use serif display header, the `--ring` focus token, and dark-mode correctness
- [x] T043 [P] [US1] Restyle `app/views/shared/_dropdown.html.erb` to consume the new tokens (border, radius, hover state)
- [x] T044 [P] [US1] Restyle `app/views/shared/_avatar.html.erb` to consume the new tokens
- [x] T045 [P] [US1] Restyle `app/views/shared/_masthead.html.erb` to consume the new tokens and primitives
- [x] T046 [P] [US1] Restyle `app/views/shared/_tabbar.html.erb` (public) to consume the new tokens
- [x] T047 [P] [US1] Restyle `app/views/shared/_dashboard_tabbar.html.erb` (mobile dashboard) to consume the new tokens
- [x] T048 [P] [US1] Restyle `app/views/shared/_dashboard_rail.html.erb` (desktop dashboard) to consume the new tokens
- [x] T049 [P] [US1] Replace 8 hand-rolled SVG strings in `app/javascript/utils/notify.js` with `i-[tabler--alert-circle]` / `i-[tabler--alert-triangle]` / `i-[tabler--circle-check]` / `i-[tabler--x]` rendered by Stimulus
- [x] T050 [P] [US1] Create `app/views/design_system/_tokens.html.erb` rendering every color/type/spacing/radius token with both light and dark swatches
- [x] T051 [P] [US1] Create `app/views/design_system/_type.html.erb` rendering the three font stacks + the scale ramp
- [x] T052 [P] [US1] Create `app/views/design_system/_buttons.html.erb` rendering one example per variant × size combo via `render_button`
- [x] T053 [P] [US1] Create `app/views/design_system/_chips.html.erb` rendering one example per chip kind via `render_chip`
- [x] T054 [P] [US1] Create `app/views/design_system/_list_row.html.erb` rendering one `render_list_row` example
- [x] T055 [P] [US1] Create `app/views/design_system/_cards.html.erb` rendering one `ui_card` example
- [x] T056 [P] [US1] Create `app/views/design_system/_forms.html.erb` rendering one `ui_input` example
- [x] T057 [P] [US1] Create `app/views/design_system/_tabs.html.erb` rendering one `tabs_controller` example
- [x] T058 [P] [US1] Create `app/views/design_system/_value_net.html.erb` rendering `render_value_note` examples (text-only reward)
- [x] T059 [P] [US1] Create `app/views/design_system/_notifications.html.erb` rendering `render_notification_card` examples
- [x] T060 [P] [US1] Create `app/views/design_system/_states.html.erb` rendering `render_state_empty` and `render_skeleton` examples
- [x] T061 [P] [US1] Create `app/views/design_system/_modal.html.erb` rendering a `render_modal` example
- [x] T062 [P] [US1] Create `app/views/design_system/_dropdown.html.erb` rendering a `render_dropdown` example
- [x] T063 [P] [US1] Create `app/views/design_system/_masthead.html.erb` rendering `_masthead` example (using an isolated context to avoid double-masthead on the dashboard layout)
- [x] T064 [P] [US1] Create `app/views/design_system/_page_shell.html.erb` rendering the public page shell (masthead + tabbar + container + footer) with annotations
- [x] T065 [US1] Populate `app/views/design_system/index.html.erb` to render all 15 `_*.html.erb` sections in order using `render_design_system_section`
- [x] T066 [US1] Implement rule DS001 (raw hex outside token layer) in `lib/design_system/lint.rb` with allowlist for `:root`, `--coin-*`, theme-color meta
- [x] T067 [US1] Implement rule DS002 (hand-rolled `<svg>` in views) in `lib/design_system/lint.rb` with allowlist for `_card_cover.html.erb` + Lexxy internals
- [x] T068 [P] [US1] Implement rule DS003 (tag-style-* remnants) in `lib/design_system/lint.rb`
- [x] T069 [P] [US1] Implement rule DS004 (`bg-reward` / `border-reward`) in `lib/design_system/lint.rb`
- [x] T070 [P] [US1] Implement rule DS005 (raw `<button class="btn btn-primary">` outside `shared/_button.html.erb`) in `lib/design_system/lint.rb`
- [x] T071 [P] [US1] Implement rule DS006 (raw `<span class="chip chip-*">` outside `shared/_chip.html.erb`) in `lib/design_system/lint.rb`
- [x] T072 [P] [US1] Implement rule DS007 (raw `<table>` outside `shared/_table.html.erb`) in `lib/design_system/lint.rb`
- [x] T073 [P] [US1] Implement rule DS008 (literal `border-radius:` outside `:root`) in `lib/design_system/lint.rb`
- [x] T074 [P] [US1] Implement rule DS009 (font-display + muted-color semantic conflict) in `lib/design_system/lint.rb`
- [x] T075 [P] [US1] Implement rule DS010 (new tabler slug informational) in `lib/design_system/lint.rb`
- [x] T076 [P] [US1] Implement rule DS011 (raw `<input class="input">` outside `shared/_ui_input.html.erb`) in `lib/design_system/lint.rb`
- [x] T077 [P] [US1] Implement rule DS012 (raw modal markup outside `shared/_modal.html.erb`) in `lib/design_system/lint.rb`
- [x] T078 [P] [US1] Implement rule DS013 (raw dropdown markup outside `shared/_dropdown.html.erb`) in `lib/design_system/lint.rb`
- [x] T079 [US1] Add `--phase <a|b|c|d>` argument parsing to `bin/lint-design-system` (Phase A = current + earlier; CI always runs full)
- [x] T080 [US1] Populate `lib/design_system/primitives.rb::Registry` from a directory scan of `app/views/shared/_*.html.erb`, so the design-system reference page renders each registered primitive automatically (one source-of-truth for both the reference page and the lint allowlist)
- [x] T081 [US1] Run `bin/rubocop`, `bun run lint-check`, `bin/rails zeitwerk:check`, `bin/rails test`, and `bin/lint-design-system`; all must be green

**Checkpoint**: User Story 1 is fully functional and testable independently. The design-system reference page renders, the lint tool enforces DS001–DS013, every new primitive is registered, every existing primitive is restyled to tokens. US2 (public surfaces) can now consume the primitives.

---

## Phase 4: User Story 2 — Public Surfaces All Share One Editorial Voice (Priority: P2)

**Goal**: Refactor every public-facing view (home feed, article reader, search, author profile, collection, login modal, error pages, static pages) so every screen consumes the design-system primitives exclusively. First-class dark mode on all of them.

**Independent Test**: As a reader (logged in or out), visit every public route in sequence (home feed, search, author profile, collection, article reader, login modal, 404, 500) and confirm the masthead, palette, typography, spacing scale, and interactive component vocabulary are visually consistent. Toggle dark mode on each and confirm no flash + no contrast violations.

### Tests for User Story 2 ⚠️

- [x] T082 [P] [US2] Write `test/system/public_surfaces_consistency_test.rb` asserting every public controller action renders the design-system `_masthead` and uses `render_button` / `render_chip` / `render_list_row` (detected via DOM markers)
- [x] T083 [P] [US2] Write `test/system/dark_mode_no_flash_test.rb` asserting toggling dark mode on each public surface does not produce a flash of unstyled content
- [x] T084 [P] [US2] Write `test/system/error_pages_use_design_system_test.rb` asserting `errors/not_found`, `errors/internal_server_error`, `errors/not_acceptable`, `errors/unprocessable_entity` all render the `render_state_empty` primitive
- [x] T085 [P] [US2] Write `test/system/search_results_use_list_row_test.rb` asserting `search#index` renders results via `render_list_row` (DOM marker)
- [x] T086 [P] [US2] Write `test/system/login_modal_uses_design_system_test.rb` asserting `sessions#new` opens the connect-wallet modal via `render_modal` (DOM marker)

### Implementation for User Story 2

- [x] T087 [P] [US2] Refactor `app/views/home/index.html.erb` to consume `render_button`, `render_chip`, `render_list_row`, `render_value_note`; remove any raw hex / bespoke styling
- [x] T088 [P] [US2] Refactor `app/views/home/_*` partials (selected_articles, hot_tags, active_authors, more) to consume the design-system primitives
- [x] T089 [P] [US2] Refactor `app/views/articles/show.html.erb` + its 19 partials (`_card_cover`, `_card`, `_content`, `_partial_content`, `_full_content`, `_header`, `_filter_bar`, `_floating_bar`, `_votes`, `_buy_article_button`, `_reward_article_button`, `_buyers`, `_comments_card`, `_references_card`, `_related_articles_card`, `_share_button`, `_widgets`, `_updated_at`, `_save_status`) to consume the design-system primitives
- [x] T090 [P] [US2] Refactor `app/views/articles/index.html.erb` to consume `render_list_row` for every article row
- [x] T091 [P] [US2] Refactor `app/views/users/show.html.erb` (author profile header) + `_user_card.html.erb` + `users/articles/_article_feed.html.erb` to consume `render_list_row` + `_profile_header` partial
- [x] T092 [P] [US2] Refactor `app/views/users/comments/_comment.html.erb` + `users/comments/index.html.erb` to consume `render_chip` + `_notification_card`
- [x] T093 [P] [US2] Refactor `app/views/collections/show.html.erb` + `_card.html.erb` + `_detail.html.erb` + `_form.html.erb` + `_stats.html.erb` + `collections/articles/_article.html.erb` to consume `render_list_row` + `render_button`
- [x] T094 [P] [US2] Refactor `app/views/collections/subscribers/_subscriber.html.erb` to consume `render_chip`
- [x] T095 [P] [US2] Refactor `app/views/search/_result.html.erb` + `_form.html.erb` + `index.html.erb` to consume `render_list_row` + the standard `_dropdown` partial
- [x] T096 [P] [US2] Refactor `app/views/comments/_comment.html.erb` + `_article_comments.html.erb` + `_actions.html.erb` + `_form.html.erb` + `_quote_comment.html.erb` + `index.html.erb` + `new.html.erb` to consume the design-system primitives (chip, button, list-row for replies)
- [x] T097 [P] [US2] Refactor `app/views/errors/not_found.html.erb` to use `render_state_empty` + `render_button` (CTAs to home + search)
- [x] T098 [P] [US2] Refactor `app/views/errors/not_acceptable.html.erb`, `errors/unprocessable_entity.html.erb`, `errors/internal_server_error.html.erb` to use `render_state_empty` + `render_button`
- [x] T099 [P] [US2] Refactor `app/views/pages/fair.html.erb` + `pages/rules.html.erb` to wrap markdown in a new `content-prose` Tailwind utility derived from the design-system typography stack
- [x] T100 [P] [US2] Refactor `app/views/sessions/new.html.erb` (wallet connect) to use `render_modal` + `render_button` + `render_chip`
- [x] T101 [P] [US2] Refactor `app/views/locales/edit.html.erb` (locale picker) to use `render_modal` + `render_chip`
- [x] T102 [P] [US2] Refactor `app/views/block_users/new.html.erb` (block-user confirm) to use `render_modal` + `render_button` (`:danger` variant)
- [x] T103 [P] [US2] Refactor `app/views/currencies/index.html.erb` + `currencies/_list.html.erb` to use `render_modal` + `render_chip`
- [x] T104 [P] [US2] Refactor `app/views/pre_orders/new.html.erb` + `_form.html.erb` + `_mixpay_button.html.erb` + `_pay_button.html.erb` + `_payment.html.erb` + `_state.html.erb` to use `render_modal` + `render_button`
- [x] T105 [P] [US2] Refactor `app/views/subscribe_articles/new.html.erb` + `subscribe_tags/new.html.erb` + `subscribe_users/new.html.erb` (subscribe/unsubscribe modals) to use `render_modal` + `render_button`
- [x] T106 [P] [US2] Refactor `app/views/users/share.html.erb` + `users/subscribe_users/index.html.erb` + `users/subscribe_by_users/index.html.erb` to use `render_modal`
- [x] T107 [P] [US2] Refactor `app/views/articles/share.html.erb` + `collections/share.html.erb` to use `render_modal` + `render_button`
- [x] T108 [P] [US2] Refactor `app/views/tags/_tag_card.html.erb` to use `render_chip`
- [x] T109 [P] [US2] Refactor `app/views/article_references/_form.html.erb` to remove the raw hex (`bg-[#F4F4F4]`, `dark:border-[white]`) and consume `bg-base-200` + `border-base-300`
- [x] T110 [P] [US2] Refactor `app/views/users/_user_uid.html.erb` to remove the three raw hex values (`#77beff`, `#ff51a3`, `#ffcf54`) and consume design-system semantic tokens (info, danger, warn)
- [x] T111 [P] [US2] Refactor `app/views/transfers/stats.html.erb` to remove the six `bg-[#F4F4F4]` cells and consume `bg-base-200`
- [x] T112 [P] [US2] Add `theme-color` meta tag to `app/views/layouts/public.html.erb` + `app/views/layouts/application.html.erb` + `app/views/layouts/editor.html.erb` that updates with dark-mode toggle (use `--bg` value)
- [x] T113 [P] [US2] Refactor `app/views/layouts/public.html.erb` body to use the new design-system typography + container classes (`max-w-[68ch]` for article body, `max-w-[1120px]` for feed)
- [x] T114 [P] [US2] Add `content-prose` utility to `app/assets/stylesheets/application.tailwind.css` (Tailwind Typography via `@tailwindcss/typography` already installed; configure for the design-system font stack + dark mode)
- [x] T115 [P] [US2] Add locale keys for any new user-visible strings to `config/locales/en.yml` and `config/locales/zh-CN.yml`
- [x] T116 [US2] Run `bin/rubocop`, `bun run lint-check`, `bin/rails zeitwerk:check`, `bin/rails test`, and `bin/lint-design-system`; all must be green
- [x] T117 [US2] Manual screenshot review of every touched surface in light + dark mode; record in PR description

**Checkpoint**: User Stories 1 AND 2 are both functional and testable independently. The public surface is fully on the design system.

---

## Phase 5: User Story 3 — Authoring Surfaces (Dashboard + Editor) Match the System (Priority: P3)

**Goal**: Refactor the dashboard layout (left rail, mobile tabbar, content column) and every dashboard view (overview, write/read/finances/account, settings, notifications, tables, comments) plus the article editor (toolbar, cover picker, tags input, pricing, reward split, publish flow) so every authoring screen consumes the design-system primitives.

**Independent Test**: Open the article reader and the article editor side-by-side; confirm typography, palette, button styles, chip styles, modal shells all match. Open every dashboard surface (overview, articles list, article settings, comments, payments, transfers, notifications, account) and confirm each consumes the system's components. Confirm mobile dashboard collapses to the same mobile pattern as public surfaces.

### Tests for User Story 3 ⚠️

- [x] T118 [P] [US3] Write `test/system/dashboard_uses_design_system_test.rb` asserting every `Dashboard::*Controller` action renders the design-system rail/tabbar + uses `render_button` / `render_chip` / `render_table` (DOM markers)
- [x] T119 [P] [US3] Write `test/system/dashboard_mobile_collapse_test.rb` asserting the mobile dashboard collapses to the same pattern as the public mobile surfaces (no separate bottom tab)
- [x] T120 [P] [US3] Write `test/system/article_editor_uses_design_system_test.rb` asserting `articles#new`, `articles#edit`, `articles#preview` use `render_button` + `ui_input` + `render_chip` for toolbar chrome, cover picker, tags input, pricing, reward split
- [x] T121 [P] [US3] Write `test/system/dashboard_tables_use_render_table_test.rb` asserting every dashboard table (`orders`, `payments`, `transfers`, `articles`, `collections`, `comments`, `subscribe_*`) uses `render_table`

### Implementation for User Story 3

- [x] T122 [P] [US3] Refactor `app/views/layouts/application.html.erb` to use the design-system rail/tabbar/content shells; replace inline Tailwind classes with the new primitive-driven partials
- [x] T123 [P] [US3] Refactor `app/views/dashboard/home/index.html.erb` (overview) to use `render_value_note` for revenue figures + `render_button` for CTAs + `render_chip` for status
- [x] T124 [P] [US3] Refactor `app/views/dashboard/home/account.html.erb` (account sub-area) to use the design-system primitives
- [x] T125 [P] [US3] Refactor `app/views/dashboard/home/read.html.erb` (read sub-area) to use `render_list_row` for the bought-articles list + `render_chip` for statuses
- [x] T126 [P] [US3] Refactor `app/views/dashboard/home/write.html.erb` (write sub-area) to use `render_list_row` for drafts/published/hidden groups
- [x] T127 [P] [US3] Refactor `app/views/dashboard/home/finances.html.erb` (finances sub-area) to use `render_value_note` + `render_table` for transfers/payments
- [x] T128 [P] [US3] Refactor `app/views/dashboard/access_tokens/index.html.erb` + `_form.html.erb` + `_access_token.html.erb` to use `render_button` + `render_modal`
- [x] T129 [P] [US3] Refactor `app/views/dashboard/articles/index.html.erb` + `_drafted_article.html.erb` + `_published_article.html.erb` + `_hidden_article.html.erb` to use `render_list_row` (or a `render_table` if dense) + `render_chip` for status
- [x] T130 [P] [US3] Refactor `app/views/dashboard/articles/show.html.erb` (single-article admin overview) to use `render_button` + `render_chip` + `render_value_note`
- [x] T131 [P] [US3] Refactor `app/views/dashboard/block_users/index.html.erb` + `_user.html.erb` to use `render_list_row` + `render_button`
- [x] T132 [P] [US3] Refactor `app/views/dashboard/collections/index.html.erb` + `show.html.erb` + `new.html.erb` + `edit.html.erb` + `_collection.html.erb` to use `render_list_row` + `render_button`
- [x] T133 [P] [US3] Refactor `app/views/dashboard/comments/index.html.erb` + `_comment.html.erb` + `_article_comment.html.erb` + `_article_comments.html.erb` to use `render_list_row` + `render_chip`
- [x] T134 [P] [US3] Refactor `app/views/dashboard/deleted_articles/new.html.erb` + `deleted_notifications/new.html.erb` + `hidden_collections/new.html.erb` + `listed_collections/new.html.erb` + `published_articles/new.html.erb` + `read_notifications/new.html.erb` (confirmation modals) to use `render_modal` + `render_button` (`:danger` variant where appropriate)
- [x] T135 [P] [US3] Refactor `app/views/dashboard/notifications/index.html.erb` + `_notification.html.erb` to use `render_notification_card`
- [x] T136 [P] [US3] Refactor `app/views/dashboard/orders/index.html.erb` + `_article_order.html.erb` + `_article_orders.html.erb` + `_user_orders.html.erb` to use `render_table`
- [x] T137 [P] [US3] Refactor `app/views/dashboard/payments/index.html.erb` + `_payment.html.erb` to use `render_table`
- [x] T138 [P] [US3] Refactor `app/views/dashboard/profile_settings/show.html.erb` + `_notification.html.erb` + `_profile.html.erb` + `verify_email.html.erb` to use `render_button` + `ui_input` + `render_avatar`
- [x] T139 [P] [US3] Refactor `app/views/dashboard/subscribe_articles/index.html.erb` + `_article.html.erb` + `subscribe_tags/index.html.erb` + `_tag.html.erb` + `subscribe_users/index.html.erb` + `_user.html.erb` to use `render_list_row` + `render_chip`
- [x] T140 [P] [US3] Refactor `app/views/dashboard/subscriptions/index.html.erb` (grouped subscriptions) to use `render_list_row` + `render_chip`
- [x] T141 [P] [US3] Refactor `app/views/dashboard/transfers/index.html.erb` + `_transfer.html.erb` + `stats.html.erb` to use `render_table` + `render_value_note`
- [x] T142 [P] [US3] Refactor `app/views/articles/_form.html.erb` (article editor form) to use `render_button` + `ui_input` + `render_chip` for chrome around Lexxy
- [x] T143 [P] [US3] Refactor `app/views/articles/_content_fields.html.erb` + `_option_fields.html.erb` (editor option rows) to use `ui_input` + `render_chip`
- [x] T144 [P] [US3] Refactor `app/views/articles/new.html.erb` + `edit.html.erb` + `preview.html.erb` (editor entry points) to use `render_button` (Publish CTA)
- [x] T145 [P] [US3] Refactor `app/views/articles/_conflict_resolution.html.erb` (autosave conflict UI) to use `render_state_empty` + `render_button`
- [x] T146 [P] [US3] Refactor `app/views/articles/_edit_form.html.erb` (the in-place edit form) to use `render_button` + `ui_input`
- [x] T147 [P] [US3] Restyle `app/views/layouts/editor.html.erb` (editor layout chrome only; Lexxy internals untouched) to consume the design-system tokens
- [x] T148 [P] [US3] Add locale keys for any new user-visible strings to `config/locales/en.yml` and `config/locales/zh-CN.yml`
- [x] T149 [US3] Run `bin/rubocop`, `bun run lint-check`, `bin/rails zeitwerk:check`, `bin/rails test`, and `bin/lint-design-system`; all must be green
- [x] T150 [US3] Manual screenshot review of every touched surface in light + dark mode; record in PR description

**Checkpoint**: User Stories 1, 2, AND 3 are all functional and testable independently. The full reader + author experience is on the design system.

---

## Phase 6: User Story 4 — Admin, API Error Pages, and Notifications Also Speak the System (Priority: P4)

**Goal**: Refactor the admin layout + every admin view, the HTML error pages for API/browser hits, and the notification inbox + real-time toast so even the "internal" surfaces feel like part of the same product.

**Independent Test**: Open the admin panel (any index, any form), trigger an API error from the JSON endpoint, and open the notification inbox; confirm each surface uses the system's tokens, components, and shells in both light and dark mode.

### Tests for User Story 4 ⚠️

- [x] T151 [P] [US4] Write `test/system/admin_uses_design_system_test.rb` asserting every `Admin::*Controller` action renders the design-system `_admin_nav` (or `_masthead` derivation) + uses `render_button` / `render_chip` / `render_table` (DOM markers)
- [x] T152 [P] [US4] Write `test/system/admin_login_uses_design_system_test.rb` asserting `admin/login#new` uses `render_button` + `ui_input`
- [x] T153 [P] [US4] Write `test/system/api_error_html_uses_design_system_test.rb` asserting browser hits on API routes that error out (e.g. `/api/v1/articles/0`) render the design-system error page (not raw JSON)
- [x] T154 [P] [US4] Write `test/system/notification_inbox_uses_design_system_test.rb` asserting `dashboard/notifications#index` renders via `render_notification_card`
- [x] T155 [P] [US4] Write `test/system/notification_toast_uses_design_system_test.rb` asserting the real-time toast (driven by `app/javascript/utils/notify.js`) renders `i-[tabler--*]` icons (no hand-rolled SVGs)

### Implementation for User Story 4

- [x] T156 [P] [US4] Create `app/views/shared/_admin_nav.html.erb` (or refactor existing `admin/_nav.html.erb` + `admin/_aside.html.erb`) to consume the design-system masthead primitives; remove bespoke admin styling
- [x] T157 [P] [US4] Refactor `app/views/layouts/admin.html.erb` to use the design-system layout shells; remove bespoke admin chrome
- [x] T158 [P] [US4] Refactor `app/views/admin/login/new.html.erb` (self-contained admin login form) to use `render_button` + `ui_input`
- [x] T159 [P] [US4] Refactor `app/views/admin/articles/index.html.erb` + `show.html.erb` + `_article.html.erb` + `_query.html.erb` to use `render_table` + `render_button`
- [x] T160 [P] [US4] Refactor `app/views/admin/bonuses/index.html.erb` + `new.html.erb` + `_form.html.erb` + `_bonus.html.erb` + `_query.html.erb` to use `render_table` + `render_button` + `ui_input`
- [x] T161 [P] [US4] Refactor `app/views/admin/collections/index.html.erb` + `show.html.erb` + `_collection.html.erb` + `_field.html.erb` + `_query.html.erb` to use `render_table` + `render_button`
- [x] T162 [P] [US4] Refactor `app/views/admin/comments/index.html.erb` + `show.html.erb` + `_query.html.erb` to use `render_table` + `render_button`
- [x] T163 [P] [US4] Refactor `app/views/admin/mixin_network_snapshots/index.html.erb` + `show.html.erb` + `_mixin_network_snapshot.html.erb` + `_query.html.erb` to use `render_table`
- [x] T164 [P] [US4] Refactor `app/views/admin/mixin_network_users/index.html.erb` + `show.html.erb` + `_mixin_network_user.html.erb` + `_field.html.erb` + `_query.html.erb` to use `render_table`
- [x] T165 [P] [US4] Refactor `app/views/admin/orders/index.html.erb` + `show.html.erb` + `_query.html.erb` to use `render_table`
- [x] T166 [P] [US4] Refactor `app/views/admin/overview/index.html.erb` (admin dashboard) to use `render_value_note` + `render_table`
- [x] T167 [P] [US4] Refactor `app/views/admin/payments/index.html.erb` + `show.html.erb` + `_query.html.erb` to use `render_table`
- [x] T168 [P] [US4] Refactor `app/views/admin/pre_orders/index.html.erb` + `show.html.erb` + `_query.html.erb` to use `render_table`
- [x] T169 [P] [US4] Refactor `app/views/admin/sessions/index.html.erb` to use `render_table`
- [x] T170 [P] [US4] Refactor `app/views/admin/statistics/index.html.erb` + `_query.html.erb` + `_statistic.html.erb` to use `render_table` + `render_value_note`
- [x] T171 [P] [US4] Refactor `app/views/admin/transfers/index.html.erb` + `show.html.erb` + `_query.html.erb` to use `render_table` + `render_value_note`
- [x] T172 [P] [US4] Refactor `app/views/admin/users/index.html.erb` + `show.html.erb` + `_user.html.erb` + `_field.html.erb` + `_query.html.erb` to use `render_table` + `render_button`
- [x] T173 [P] [US4] Refactor `app/views/admin/wallets/assets.html.erb` + `_asset.html.erb` + `safe_outputs.html.erb` + `_safe_output.html.erb` + `snapshots.html.erb` + `_snapshot.html.erb` to use `render_table`
- [x] T174 [P] [US4] Confirm `app/controllers/concerns/api/rendering_helper.rb` + `app/controllers/api/base_controller.rb` continue to emit JSON; ensure browser hits on erroring JSON endpoints fall through to the HTML error pages (already covered by US2 — Phase 4)
- [x] T175 [P] [US4] Confirm `app/controllers/concerns/rendering_helper.rb#render_not_found_page` still targets `errors/not_found` (no change required; the template was restyled in US2)
- [x] T176 [P] [US4] Confirm the notification toast (`app/javascript/utils/notify.js`) renders `i-[tabler--*]` icons (migrated in US1 — verify, no further change)
- [x] T177 [P] [US4] Add locale keys for any new user-visible strings to `config/locales/en.yml` and `config/locales/zh-CN.yml`
- [x] T178 [US4] Run `bin/rubocop`, `bun run lint-check`, `bin/rails zeitwerk:check`, `bin/rails test`, and `bin/lint-design-system`; all must be green
- [x] T179 [US4] Manual screenshot review of every touched surface in light + dark mode; record in PR description

**Checkpoint**: All four user stories are functional and testable independently. The full product (public + authoring + admin + error pages + notifications) is on the design system.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories; final verification.

- [x] T180 [P] Update `CHANGELOG.md` with the design-system foundation entry + per-phase entries; list every new primitive, every new token, every new lint rule
- [x] T181 [P] Update `AGENTS.md` "Code Conventions" section to point at `/design-system` as the design-system entry point and at `specs/011-comprehensive-ui-refactor/contracts/` as the contracts source-of-truth
- [x] T182 [P] Add `docs/superpowers/specs/opendesign-011/README.md` linking to the copied brand-spec + 8 HTML prototypes, with a one-paragraph note that the OpenDesign project remains the live source
- [x] T183 [P] Run `bin/measure-frontend-efficiency` after each phase; commit the diff to `specs/011-comprehensive-ui-refactor/perf.md`; flag any regression > 5% for follow-up
- [x] T184 [P] Cross-cutting accessibility audit: every touched surface passes axe-core on key flows (focus rings visible, contrast ≥ 4.5:1 for body text, all interactive elements keyboard-operable); add `test/system/a11y_axe_test.rb` and gate CI on it
- [x] T185 [P] Run the full quickstart walkthrough (4 manual walkthroughs: public surfaces, authoring surfaces, admin/API/errors/notifications, dark-mode toggle); record screenshots in PR description
- [x] T186 [P] Shrink the lint allowlist in `lib/design_system/lint.rb`: remove `app/javascript/utils/notify.js` from DS002 allowlist (now migrated to `i-[tabler--*]`); remove any per-phase temporary allowlist entries
- [x] T187 [P] Confirm `bundle exec rubocop --no-fix` passes for every touched Ruby file in CI
- [x] T188 [P] Confirm `bun run lint-check` passes for every touched JS file in CI
- [x] T189 [P] Confirm `bin/rails zeitwerk:check` passes after every constant added across all four phases
- [x] T190 [P] Confirm `bin/rails test` passes for the full suite (controllers, models, jobs, notifiers, systems, libs, helpers)
- [x] T191 [P] Confirm `bin/lint-design-system` passes (exit code 0) on the final state of `main`
- [x] T192 [P] Run a final `bin/measure-frontend-efficiency` and attach the output to the PR description; verify no individual metric regresses by more than 5% vs baseline

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — **BLOCKS all user stories**
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - **US1 (P1)** must complete first — every other story consumes the primitives it ships
  - **US2, US3, US4** can proceed in parallel after US1 (different surfaces, no cross-dependencies)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1, Design System)**: Can start after Foundational (Phase 2) — no dependencies on other stories
- **User Story 2 (P2, Public Surfaces)**: Can start after US1 — consumes the primitives US1 ships
- **User Story 3 (P3, Authoring Surfaces)**: Can start after US1 — consumes the primitives US1 ships; **may run in parallel with US2** (different views)
- **User Story 4 (P4, Admin/API/Errors/Notifications)**: Can start after US1 — consumes the primitives US1 ships; **may run in parallel with US2 and US3** (different views)

### Within Each User Story

- Tests are written first and must FAIL before implementation (Constitution §II)
- Helpers before partials before views (helpers expose the primitive API; partials are the API surface; views consume them)
- Token-layer changes before primitive changes (US1 dependencies; subsequent phases don't touch the token layer unless absolutely necessary)
- Story complete (all lint + tests + screenshot review green) before moving to the next story

### Parallel Opportunities

- **Phase 1 (Setup)**: T001–T005 can all run in parallel
- **Phase 2 (Foundational)**: T006–T019 split — token layer (T006–T010) and Ruby tool (T011–T013, T019) and Rails glue (T014–T017, T018) can each run in parallel within their own bucket
- **Phase 3 (US1)**: T020–T078 (helper + partial + reference-page + lint-rule implementation) split across ~7 parallel buckets:
  - **Helpers** (T025, T027, T029, T035, T036, T037, T038, T039) — all in `app/helpers/ui_helper.rb`; not parallelizable with each other
  - **New partials** (T024, T026, T028, T030, T031, T032, T033, T034) — each its own file; parallelizable
  - **Restyled existing partials** (T040–T048) — each its own file; parallelizable
  - **Toast icon migration** (T049) — single file; standalone
  - **Reference-page sections** (T050–T064) — each its own file; parallelizable
  - **Lint rules** (T066–T078) — all in one file; not parallelizable with each other
- **Phase 4 (US2)**: T087–T111 (one task per file or set of files) — all parallelizable except T116 (gating step)
- **Phase 5 (US3)**: T122–T147 — all parallelizable except T149 (gating step)
- **Phase 6 (US4)**: T158–T173 — all parallelizable except T178 (gating step)
- **Phase 7 (Polish)**: T180–T191 — all parallelizable

---

## Parallel Examples

### Example: Phase 2 (Foundational) — split into 3 parallel buckets

```bash
# Bucket 1: token layer (T006-T010)
Task: "Extend token layer in app/assets/stylesheets/application.tailwind.css: add :root block …"
Task: "Extend token layer … dark-mode overrides …"
Task: "Extend token layer … declare --font-* + --radius + spacing …"
Task: "Add @utility declarations …"
Task: "Add --coin-* declarations …"

# Bucket 2: Ruby tool (T011-T013, T019)
Task: "Add module DesignSystem; module Lint … at lib/design_system/lint.rb"
Task: "Add module DesignSystem; module Primitives … at lib/design_system/primitives.rb"
Task: "Add module DesignSystem; class Violation … at lib/design_system/violation.rb"
Task: "Add DesignSystem::Lint allowlist seeds …"

# Bucket 3: Rails glue (T014-T018)
Task: "Create DesignSystemController at app/controllers/design_system_controller.rb"
Task: "Add route get /design-system …"
Task: "Add app/helpers/design_system_helper.rb"
Task: "Create empty app/views/design_system/index.html.erb"
Task: "Confirm bin/rails zeitwerk:check passes"
```

### Example: Phase 3 (US1) — new partials run in parallel

```bash
# All new partials can be authored in parallel:
Task: "Create app/views/shared/_button.html.erb partial"
Task: "Create app/views/shared/_chip.html.erb partial"
Task: "Create app/views/shared/_list_row.html.erb partial"
Task: "Create app/views/shared/_value_note.html.erb partial"
Task: "Create app/views/shared/_notification_card.html.erb partial"
Task: "Create app/views/shared/_skeleton.html.erb partial"
Task: "Create app/views/shared/_state_empty.html.erb partial"
Task: "Create app/views/shared/_table.html.erb partial"
```

### Example: Phase 4 (US2) — public surfaces refactor in parallel

```bash
# Public views refactor in parallel (different files):
Task: "Refactor app/views/home/index.html.erb …"
Task: "Refactor app/views/articles/show.html.erb + 19 partials …"
Task: "Refactor app/views/users/show.html.erb + users/articles/_article_feed.html.erb …"
Task: "Refactor app/views/collections/show.html.erb …"
Task: "Refactor app/views/search/_result.html.erb …"
Task: "Refactor app/views/comments/_comment.html.erb …"
Task: "Refactor app/views/errors/not_found.html.erb …"
Task: "Refactor app/views/sessions/new.html.erb …"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

The **MVP is User Story 1**: ship the design-system entry point, the seven new primitives, the consolidated helpers, the lint tool. After this:

1. Phase 1 (Setup) — wire lint into CI, snapshot brand-spec.
2. Phase 2 (Foundational) — token layer, lint skeleton, design-system controller, autoloader verified.
3. Phase 3 (US1) — design system primitives + lint rules + reference page.
4. **STOP and VALIDATE**: `/design-system` renders; `bin/lint-design-system` is green; the four new tests pass.
5. Demo: a new contributor can land on `/design-system` and find every primitive they need.

### Incremental Delivery

1. Complete Phase 1 + Phase 2 → Foundation ready.
2. Complete US1 → Demo (MVP!): `/design-system` is live; every later refactor has primitives to consume.
3. Complete US2 → Demo: public surfaces unified; no more "two visual languages depending on the page."
4. Complete US3 → Demo: authoring surfaces match the public surfaces; no more "read = editorial, write = generic."
5. Complete US4 → Demo: admin + errors + notifications match everything else.
6. Each phase adds value without breaking previous phases (the lint tool gates every PR).

### Parallel Team Strategy

With multiple developers (or AI agents):

1. Team completes Setup + Foundational together.
2. Once Foundational is done:
   - Developer A: User Story 1 (must be sequential — others depend on it).
   - Developer B: User Story 2 (Public Surfaces).
   - Developer C: User Story 3 (Authoring Surfaces).
   - Developer D: User Story 4 (Admin/API/Errors/Notifications).
3. Stories complete and integrate independently (different views, same primitives).
4. Polish phase is a single-developer sweep.

---

## Notes

- **[P] tasks** = different files, no dependencies on incomplete tasks.
- **[Story] label** maps each task to a user story for traceability (US1 → US4).
- Each user story is independently completable and testable.
- Tests are written FIRST and must FAIL before implementation.
- Commit after each task or logical group; the lint script is the merge gate.
- Stop at any checkpoint to validate the story independently.
- **Avoid** vague tasks, same-file conflicts, cross-story dependencies that break independence.
- The lint script (`bin/lint-design-system`) is the single most important enforcement tool — if a PR violates any DS001–DS013 rule, the PR is not ready to merge.