# Implementation Plan: Editorial Redesign Rollout — Dashboard, Editor, Modal & Remaining Polish

**Branch**: `003-editorial-redesign-rollout` | **Date**: 2026-07-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-editorial-redesign-rollout/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Finish rolling the editorial design system (established in `specs/002-editorial-ui-redesign/`, PR #1822) out to every remaining authenticated surface — the author dashboard/studio (~77 view files across 24 controllers, kept on its existing left-sidebar/mobile-tabbar shell per user decision), the article editor (`layouts/editor.html.erb` + `articles/{new,edit,_edit_form,_form,_content_fields,_option_fields}`), and the wallet-connect/login modal (`sessions/new.html.erb`) — plus three smaller, independent fixes: replacing unstyled `-ghost` button/badge classes with FlyonUI's actual `-soft` modifier, generating a deterministic-but-unique default cover for articles that have none (reusing the `Collection#generate_cover`/Grover pattern already in the codebase), and turning the home page into a real landing page distinct from `/articles`. The admin panel remains explicitly out of scope. No new routes' business logic, controllers' authorization, data models, or third-party dependencies are required — this is a presentation-layer rollout onto already-adopted infrastructure (Tailwind v4 + FlyonUI, Stimulus/Turbo, `@iconify/tailwind4` Tabler icons, Grover headless-Chrome rendering).

## Technical Context

**Language/Version**: Ruby 4.0.5 (`.ruby-version`, `mise.toml`), Rails 8.1.x

**Primary Dependencies**: Hotwire (`@hotwired/turbo-rails`, `@hotwired/stimulus`), Tailwind CSS v4 + `flyonui` theme plugin (v2.4.1 — confirmed via `node_modules/flyonui/components/{button,badge}.css` to define `.btn-soft`/`.badge-soft` but no `-ghost` variant of either), `@iconify/tailwind4` with the Tabler icon set (already adopted for public pages in `specs/002-editorial-ui-redesign/`), Grover (headless-Chrome HTML→PNG rendering, already used for article posters and collection covers), Pagy, `browser` gem for device detection

**Storage**: PostgreSQL — no schema changes. The default-cover feature reuses the existing `cover` ActiveStorage attachment already present on `Article` (same attachment slot used for author-uploaded covers); no new columns or attachments needed.

**Testing**: Minitest (`bin/rails test`), existing controller tests under `test/controllers/dashboard/` (currently only `notifications_controller_test.rb`) and `test/controllers/articles_controller_test.rb`, Capybara + Selenium system tests (`test/system/*`), RuboCop (`rails-omakase`), Prettier (`bun run lint-check`) — all per existing CI (`check.yml`)

**Target Platform**: Server-rendered Rails web app; desktop + mobile browsers, and the Mixin Messenger in-app webview (`from_mixin_messenger?`)

**Project Type**: Single Rails monolith (no frontend/backend split)

**Performance Goals**: No new performance budget. The default-cover generation reuses the existing lazy/async attach-on-first-access pattern already proven by `Articles::PosterGenerator#generate_poster_async` (`Articles::GeneratePosterJob`) and `Collection#generate_cover`, so it does not add synchronous request latency once warmed, and produces a real file once per article (not regenerated per request).

**Constraints**:
- Presentation-layer for the dashboard, editor, and modal stories: no changes to dashboard routes, authorization (`Dashboard::BaseController#authenticate_user!`), revenue-split logic, payment flows, or the editor's field/validation/publish behavior (FR-020, FR-025, FR-028).
- Dashboard keeps its existing left-sidebar (desktop) / top-bar+tab-bar (mobile) navigation shell — restyle `app/views/shared/{_left_bar,_navbar,_tabbar}.html.erb` and `app/views/layouts/application.html.erb` in place; do not introduce a new layout file or move dashboard onto the `public` masthead layout (FR-016, per explicit user decision).
- Editor and modal get a full visual redesign of their own chrome/layout (per explicit user decision), but the editor's underlying Stimulus behavior (`article-form` controller: autosave, drafts, tabs) and the modal's wallet-auth flow (`auth_mixin_path`) are unchanged (FR-025, FR-028).
- Both light (`quill`) and dark (`quill-dark`) FlyonUI themes must be updated and reviewed together for every surface touched — never just one (FR-002, FR-019, FR-023, FR-027).
- Admin panel (`app/views/admin/**`, `Admin::BaseController`, `layouts/admin.html.erb`) is explicitly out of scope and MUST NOT be modified (FR-030).
- The default-cover generation must not regress the existing content-image-extraction fallback already in `Articles::PosterGenerator#thumb_url` (real uploaded cover → real in-content image for free articles → generated default, in that priority order) (FR-004, FR-006).
- Icon migration (`inline_svg_tag` → `i-tabler-*`) continues the incremental, file-by-file approach already used in `specs/002-editorial-ui-redesign/` — no big-bang icon swap required, but every file touched by this feature's stories should migrate its own icons while it's already being edited (FR-018).

**Scale/Scope**:
- Dashboard: ~77 view files across 24 controllers under `Dashboard::`, sharing 4 shell files (`_left_bar`, `_navbar`, `_tabbar`, `layouts/application.html.erb`); 10 dashboard view files still use `inline_svg_tag`.
- Editor: 1 layout (`layouts/editor.html.erb`) + 6 view/partial files (`articles/new.html.erb`, `articles/edit.html.erb`, `articles/_edit_form.html.erb`, `articles/_form.html.erb`, `articles/_content_fields.html.erb`, `articles/_option_fields.html.erb` — the largest at 271 lines).
- Modal: `sessions/new.html.erb` (content) + `shared/_modal.html.erb` (wrapper, already mostly consistent with the new system — uses `btn-text` and `icon-[tabler--x]` already).
- Default cover: 1 model concern (`Articles::PosterGenerator`), 1 new Grover template (modeled on the existing `grover/collections/cover.html.erb`), 1 new route + job (modeled on the existing `grover_collection_cover` route/`Collection#generate_cover` pattern), 1 partial (`articles/_card.html.erb`) thumbnail-block update.
- Home landing: `app/controllers/home_controller.rb`, `app/views/home/index.html.erb`, and the already-built-but-currently-orphaned `HomeController#selected_articles` / `home/selected_articles.html.erb` (from the original redesign, dropped from `home/index` at the time but left in place — candidate to revive as the curated section).
- Button/badge fix: 3 files with confirmed `-ghost` usage (`shared/_masthead.html.erb`, `articles/_header.html.erb`, `articles/_card.html.erb`) plus 2 files with a leftover `font-serif` inconsistency discovered on the already-redesigned article page (`articles/_comments_card.html.erb`, `articles/_buyers.html.erb`) folded in as small cross-cutting fixes per FR-029.
- 0 new routes' worth of business logic, 0 new controllers, 0 migrations, 1–2 new small background jobs (default-cover generation), 0 new npm/gem dependencies.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` in this repository is still the unfilled template (`[PROJECT_NAME] Constitution` placeholders, never ratified) — there are no formal Spec Kit constitution gates to evaluate, same as `specs/002-editorial-ui-redesign/`. `AGENTS.md` and `.cursor/rules/*.mdc` serve as the de facto engineering constitution and are treated as binding for this plan:

- ✅ Ruby files start with `# frozen_string_literal: true`; RuboCop (`rails-omakase`) must pass.
- ✅ Views/partials follow existing patterns (`app/views/**/_*.html.erb`, `UiHelper` block/slot helpers).
- ✅ Services/jobs follow existing patterns (`.call`-style services if needed; jobs inherit `ApplicationJob`, namespaced `Articles::`) — the default-cover generator follows the exact shape of `Collection#generate_cover`/`Articles::GeneratePosterJob`, introducing no new pattern.
- ✅ No new gems or JS dependencies introduced — Grover, FlyonUI, Tabler icons, and Stimulus are all already installed and used elsewhere for equivalent purposes.
- ✅ Tests live under `test/` mirroring `app/`; existing tests (`test/models/concerns/articles/poster_generator_test.rb`, `test/controllers/dashboard/notifications_controller_test.rb`, `test/controllers/articles_controller_test.rb`, `test/system/article_paywall_test.rb`) must keep passing; new tests added for the default-cover behavior.
- ✅ No bypassing `authenticate_user!`/`Pundit` authorization; no change to controller authorization logic in this feature.
- ✅ Revenue ratio columns/logic (`Order`, `Orders::DistributeJob`) are untouched — this feature only changes dashboard *presentation* of revenue figures already computed elsewhere (`dashboard/home/index.html.erb`'s stats block), never the calculation.

No violations identified. Complexity Tracking table is not needed (see bottom of this document).

## Project Structure

### Documentation (this feature)

```text
specs/003-editorial-redesign-rollout/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── component-contracts.md   # Phase 1 output — partial/job/route contracts
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created by this command)
```

### Source Code (repository root)

Single Rails monolith — real paths, grouped by user story:

```text
# User Story 1 — Button & badge -ghost → -soft fix, plus discovered font-serif cleanup
app/views/shared/_masthead.html.erb        # CHANGED: btn-ghost → btn-soft (4 occurrences)
app/views/articles/_header.html.erb        # CHANGED: badge-ghost → badge-soft
app/views/articles/_card.html.erb          # CHANGED: badge-ghost → badge-soft
app/views/articles/_comments_card.html.erb # CHANGED: font-serif → font-display (consistency)
app/views/articles/_buyers.html.erb        # CHANGED: font-serif → font-display (consistency)

# User Story 2 — Unique default article cover
app/models/concerns/articles/poster_generator.rb   # CHANGED: thumb_url/cover_url fall
                                                     #   back to a generated default cover
                                                     #   when no real cover/content image exists
app/views/grover/articles/cover.html.erb            # NEW: deterministic gradient/pattern
                                                     #   template, modeled on
                                                     #   grover/collections/cover.html.erb
app/jobs/articles/generate_default_cover_job.rb     # NEW: async attach, modeled on
                                                     #   Articles::GeneratePosterJob
config/routes/grover.rb                             # CHANGED: add `get :cover` under the
                                                     #   articles resource (mirrors
                                                     #   grover_collection_cover)
app/views/articles/_card.html.erb                   # CHANGED: thumbnail block simplifies
                                                     #   now that thumb_url always resolves

# User Story 3 — Home landing page
app/controllers/home_controller.rb          # CHANGED: revive/adjust selected_articles
                                              #   usage for the curated section
app/views/home/index.html.erb               # CHANGED: value-prop hero, stats highlight,
                                              #   dual CTAs, curated section (not the raw feed)
app/views/home/selected_articles.html.erb   # CHANGED: restyle the existing (currently
                                              #   orphaned) curated-articles partial for reuse

# User Story 4 — Author dashboard/studio (shell + ~77 views across 24 controllers)
app/views/shared/_left_bar.html.erb         # CHANGED: colors/typography/icons only,
                                              #   navigation structure unchanged
app/views/shared/_navbar.html.erb           # CHANGED: mobile top bar restyle
app/views/shared/_tabbar.html.erb           # CHANGED: mobile bottom tab bar restyle
app/views/layouts/application.html.erb      # CHANGED: theme tokens/typography parity with
                                              #   `layouts/public.html.erb`; right-aside
                                              #   widget restyled to match
app/views/dashboard/**/*.html.erb           # CHANGED: ~77 files — component-level restyle
                                              #   (buttons/badges/tags/tabs/empty states),
                                              #   10 files migrate inline_svg_tag → i-tabler-*

# User Story 5 — Article editor
app/views/layouts/editor.html.erb           # CHANGED: theme tokens/typography parity
app/views/articles/new.html.erb             # CHANGED: chrome restyle
app/views/articles/edit.html.erb            # CHANGED: chrome restyle (thin wrapper)
app/views/articles/_edit_form.html.erb      # CHANGED: top bar restyle, icon migration
app/views/articles/_form.html.erb           # CHANGED: title field → font-display,
                                              #   intro field restyle
app/views/articles/_content_fields.html.erb # CHANGED: editing-surface typography parity
                                              #   with the public article reader
app/views/articles/_option_fields.html.erb  # CHANGED: settings panels (price, revenue
                                              #   split, cover, tags, references) restyle

# User Story 6 — Wallet-connect / login modal
app/views/sessions/new.html.erb             # CHANGED: full visual redesign of modal content
app/views/shared/_modal.html.erb            # VERIFY: wrapper already close to the new
                                              #   system (btn-text, tabler icon) — confirm,
                                              #   adjust only if inconsistencies found

test/models/concerns/articles/poster_generator_test.rb   # EXTEND: default-cover behavior
test/controllers/dashboard/notifications_controller_test.rb  # VERIFY unchanged
test/controllers/articles_controller_test.rb              # VERIFY unchanged
test/system/article_paywall_test.rb                        # VERIFY unchanged
```

**Explicitly NOT touched** (out of scope per spec, FR-030 and Assumptions): `app/views/admin/**`, `app/controllers/admin/**`, `app/views/layouts/admin.html.erb`; no changes to any controller's authorization/business logic, no schema migrations, no changes to `Order`/`Transfer`/revenue-distribution logic.

**Structure Decision**: Single-project Rails monolith structure (existing), matching `specs/002-editorial-ui-redesign/`'s Option 1 (single project) adaptation. All changes are additive-or-restyle within `app/views`, `app/models/concerns`, `app/jobs`, and `config/routes` — no new top-level directories, no new architectural layers.

## Complexity Tracking

*No constitution violations identified — table intentionally omitted.*

## Post-Design Constitution Re-check

Phase 1 artifacts (`data-model.md`, `contracts/component-contracts.md`, `quickstart.md`) introduce one new background job (`Articles::GenerateDefaultCoverJob`) and one new Grover route/template — both directly mirroring existing, already-reviewed patterns (`Articles::GeneratePosterJob`, `Collection#generate_cover`/`grover_collection_cover`) rather than inventing a new architectural shape. No new dependencies, no data-model changes beyond reusing the existing `cover` ActiveStorage attachment. The same conclusion as the initial Constitution Check holds: no ratified constitution to gate against; `AGENTS.md`/`.cursor/rules/*.mdc` conventions remain satisfied. No new complexity to track.

**Note on agent-context sync**: The Spec Kit "update agent context" step was skipped — this repository's `.specify/scripts/bash/` does not include an `update-agent-context.sh` script, so there is no script to run for this step (same finding as `specs/002-editorial-ui-redesign/plan.md`).
