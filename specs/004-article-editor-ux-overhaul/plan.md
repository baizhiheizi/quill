# Implementation Plan: Article Editor Redesign — Modern, Unified Writing & Publishing Experience

**Branch**: `004-article-editor-ux-overhaul` | **Date**: 2026-07-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-article-editor-ux-overhaul/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Rebuild the article create/edit flow's behavior and structure — not just its visuals (which `specs/003-editorial-redesign-rollout/` already restyled) — around one principle: the author should never have to think about saving. Autosave is unified into a single mechanism (`PATCH /articles/:uuid`) covering both content and settings, for drafts and published articles alike, backed by optimistic locking (`lock_version`) for reliable last-writer-wins semantics; a brand-new article is created transparently on the first meaningful autosave rather than via an explicit "Save Draft" click, with tags no longer dropped on that first save. The current two-tab "Edit / Options" structure is replaced with a persistent two-pane layout (writing surface + collapsible Settings rail), reorganizing the 12-field settings panel into five labeled sections with a guided, plain-language revenue-split summary (raw ratio fields behind an explicit "Advanced" toggle) and real-time validation. Two complementary, low-risk additions round out the "modern, pro" goal: a client-only Focus Mode, and a Live Reader Preview that revives the currently-dormant `articles#preview` endpoint to render exactly what a reader (including the paywall boundary) would see. Three confirmed bugs are fixed as part of this work: the `update_content` endpoint's broken identifier lookup, a misplaced validation error, and a stale turbo_stream target on failed publish. No new pricing/currency/revenue-model business rules, no changes to authorization, and no changes to the already-shipped visual design tokens from `specs/002-editorial-ui-redesign/`/`specs/003-editorial-redesign-rollout/` — this is a behavior/structure/interaction redesign built on top of that visual system, per the Clarifications in `spec.md`.

## Technical Context

**Language/Version**: Ruby 4.0.5 (`.ruby-version`, `mise.toml`), Rails 8.1.x

**Primary Dependencies**: Hotwire (`@hotwired/turbo-rails`, `@hotwired/stimulus`), `@rails/request.js` (already used for the existing `put()`-based autosave call; extended with a `post()` call for first-save creation), `underscore` (`debounce`, already used), Lexxy/ActionText rich text editor (unchanged), TomSelect (tags/references/collection selects, unchanged), Tailwind CSS v4 + FlyonUI (existing editorial design tokens from `specs/002-editorial-ui-redesign/`/`003`, reused not replaced), `@iconify/tailwind4` Tabler icon set (existing), AASM (state machine, unchanged), Pundit (unchanged authorization)

**Storage**: PostgreSQL — one additive, reversible schema change: `lock_version` integer column on `articles` for optimistic locking (see `data-model.md`). No other schema changes; no changes to `Order`/`Transfer`/revenue-distribution tables or logic.

**Testing**: Minitest (`bin/rails test`); extend `test/controllers/articles_controller_test.rb` (currently has zero coverage of `new`/`create`/`edit`/`update`/`update_content`) with coverage for the unified autosave endpoint, tag persistence on first save, and the optimistic-locking conflict path; extend/add `test/controllers/dashboard/published_articles_controller_test.rb` for publish-readiness error surfacing; extend `test/models/article_test.rb` if the `lock_version` addition needs direct coverage. RuboCop (`rails-omakase`), Prettier (`bun run lint-check`) — all per existing CI (`check.yml`). Capybara/Selenium system tests cannot run in this sandbox (confirmed limitation, see `specs/002-editorial-ui-redesign/research.md` §8 and `003`'s `tasks.md`) — manual QA via `quickstart.md` substitutes where browser-driven coverage isn't feasible here.

**Target Platform**: Server-rendered Rails web app; desktop + mobile browsers, and the Mixin Messenger in-app webview (`from_mixin_messenger?`)

**Project Type**: Single Rails monolith (no frontend/backend split)

**Performance Goals**: No new performance budget beyond "autosave must not visibly block typing" (already achieved today via 1-second debounce + `showLoading()` reserved for explicit submits only, not autosave). Serializing autosave requests client-side (research.md §3) adds no perceptible latency for a single author's normal typing cadence.

**Constraints**:
- No changes to the already-shipped visual design tokens (colors, typography scale, `-soft` components, `i-tabler-*` icons) from `specs/002-editorial-ui-redesign/`/`specs/003-editorial-redesign-rollout/` — this feature is free to introduce new editor-specific layout/chrome/motion (per Clarifications) but must build on those tokens, not replace them.
- No new pricing/currency/revenue-model business rules; the five revenue-ratio columns and their validations (`ensure_revenue_ratios_sum_to_one`, `ensure_references_ratios_correct`, `ensure_price_not_too_low`) are reused exactly as-is — only their presentation, grouping, and client-side real-time mirroring change.
- Publishing remains an explicit, deliberate author action (FR-020) — autosave never triggers a state transition.
- Authorization is unchanged: `authenticate_user!` on all editor actions, `current_user.articles.find_by uuid:` scoping (author-only access), Pundit policies for public-facing actions — none of this feature's changes touch who can do what, only what happens once they can.
- The `lock_version` migration must be purely additive/reversible (no backfill risk, default `0`, `null: false`) per `.cursor/rules/database.mdc`'s migration guidance.
- Admin panel is untouched (out of scope, consistent with `003`'s FR-030 precedent).

**Scale/Scope**:
- Controllers: `app/controllers/articles_controller.rb` (consolidate `update_content` into `update`; extend `create` for background first-save + tag persistence; new `preview` GET semantics), `app/controllers/dashboard/published_articles_controller.rb` (publish-readiness surfacing).
- Views: `app/views/articles/{new,edit,_edit_form,_form,_content_fields,_option_fields}.html.erb` (structural redesign: persistent Settings rail replacing tabs; `_option_fields` split into 5 grouped sections), `app/views/articles/update.turbo_stream.erb` (narrowed to targeted updates, not whole-form replace), removal of `update_content.turbo_stream.erb`/`preview.turbo_stream.erb`/`_preview.html.erb`, new `articles/preview.html.erb` (or turbo_frame) reusing `_full_content`/`_partial_content`, `app/views/dashboard/published_articles/{new,_form,update.turbo_stream}.html.erb` (readiness list + FR-024 target fix).
- JavaScript: `app/javascript/controllers/article_form_controller.js` (largest single change — save-status state machine, unified autosave incl. settings, first-save-creates-record flow, `lock_version` threading, Focus Mode toggle, revenue-split summary rendering); no new npm dependencies.
- Database: 1 new migration (`lock_version` on `articles`).
- Routes: `config/routes.rb` — remove `put :update_content`, change `preview_article_path` from `POST /articles/preview` to a `GET :preview` member route under the existing `resources :articles`.
- Tests: extend 2 existing controller test files, possibly add 1 new one (`dashboard/published_articles_controller_test.rb` if not already present — confirm during implementation), extend `article_test.rb` for `lock_version`/optimistic-locking behavior.
- 0 new gems, 0 new JS dependencies, 0 new tables, 1 new column.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` in this repository is still the unfilled template (`[PROJECT_NAME] Constitution` placeholders, never ratified) — there are no formal Spec Kit constitution gates to evaluate, consistent with `specs/002-editorial-ui-redesign/` and `specs/003-editorial-redesign-rollout/`. `AGENTS.md` and `.cursor/rules/*.mdc` serve as the de facto engineering constitution and are treated as binding for this plan:

- ✅ Ruby files start with `# frozen_string_literal: true`; RuboCop (`rails-omakase`) must pass.
- ✅ Controllers extend existing patterns (`ArticlesController`, `Dashboard::PublishedArticlesController`) rather than introducing parallel controllers for autosave/preview.
- ✅ Models: `lock_version` is a zero-code, convention-based Rails feature (no new concern needed); all other model logic (validations, AASM) is reused unchanged, per `.cursor/rules/database.mdc`'s guidance to prefer extending existing models over parallel implementations.
- ✅ Migrations: additive, reversible, timestamped under `db/migrate/`, no hand-edited engine-generated files — per `.cursor/rules/database.mdc`.
- ✅ Services: `CreateTagService` (existing) is reused, now also called from `create`, not duplicated.
- ✅ JS: extends the existing `article-form` Stimulus controller and `@rails/request.js` usage per `.cursor/rules/javascript-frontend.mdc`; no second bundler/framework, no new dependency.
- ✅ Views: partials continue to live under `app/views/articles/**`; no bypass of existing `UiHelper` patterns.
- ✅ No bypassing `authenticate_user!`/Pundit; author-only scoping (`current_user.articles.find_by uuid:`) preserved and reused for the new `preview` action.
- ✅ Revenue ratio columns/logic (`Order`, `Orders::DistributeJob`) are untouched — this feature only changes how the existing, already-validated revenue split is presented and autosaved, never how it's calculated or distributed.
- ✅ Tests live under `test/` mirroring `app/`, extending existing files where they exist.

No violations identified. Complexity Tracking table is not needed (see bottom of this document).

## Project Structure

### Documentation (this feature)

```text
specs/004-article-editor-ux-overhaul/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output
├── contracts/
│   └── component-contracts.md   # Phase 1 output — route/param/response + Stimulus contracts
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created by this command)
```

### Source Code (repository root)

Single Rails monolith — real paths, grouped by user story:

```text
# Schema (prerequisite for User Story 1's conflict-safety requirement)
db/migrate/2026XXXXXXXXXX_add_lock_version_to_articles.rb   # NEW: optimistic locking column

# User Story 1 — Never Lose Work: Automatic, Continuous Saving
app/controllers/articles_controller.rb              # CHANGED: consolidate update_content into
                                                       #   update; create responds to background/
                                                       #   JSON first-save; rescue StaleObjectError
config/routes.rb                                     # CHANGED: remove `put :update_content`
app/views/articles/update.turbo_stream.erb           # CHANGED: targeted updates (save-status,
                                                       #   words count, updated_at, lock_version)
                                                       #   instead of whole-form replace
app/views/articles/update_content.turbo_stream.erb   # REMOVED: superseded by update.turbo_stream
app/javascript/controllers/article_form_controller.js # CHANGED (largest diff): save-status state
                                                       #   machine, unified autosave for content +
                                                       #   settings, lock_version threading,
                                                       #   request serialization, first-save via
                                                       #   POST + history.replaceState
app/views/articles/_edit_form.html.erb               # CHANGED: save-status indicator replaces
                                                       #   the narrower notSavedAlert target
app/views/articles/new.html.erb                       # CHANGED: no "Save Draft" button; settings
                                                       #   rail visible immediately (ties into US2)

# User Story 2 — A Settings Panel That's Easy to Understand and Trust
app/views/articles/_option_fields.html.erb           # CHANGED (or split into 5 partials):
                                                       #   Cover & Tags / Pricing & Access /
                                                       #   Revenue Split (guided + Advanced) /
                                                       #   References / Collection; fixes the
                                                       #   misplaced :intro-under-Collection error
app/javascript/controllers/article_form_controller.js # CHANGED: renderRevenueSummary(), Advanced
                                                       #   toggle, real-time sum/bounds validation
                                                       #   mirroring Article's server-side rules
config/locales/views.{en,zh-CN,ja}.yml               # CHANGED: replace hard-coded strings
                                                       #   (subtitle placeholder, price placeholder,
                                                       #   disabled-field explanations)

# User Story 3 — One Unified Editing Experience
app/views/articles/_form.html.erb                    # CHANGED: persistent two-pane layout
                                                       #   (writing surface + Settings rail)
                                                       #   replacing the Edit/Options tab switcher
app/views/articles/_edit_form.html.erb               # CHANGED: top bar restructured (save-status,
                                                       #   Focus Mode toggle, Preview toggle,
                                                       #   Publish), tab buttons removed

# User Story 4 — Confident, Error-Free Publishing
app/controllers/dashboard/published_articles_controller.rb  # CHANGED: compute @article.valid?
                                                              #   (full context) before rendering
                                                              #   the confirmation modal
app/views/dashboard/published_articles/_form.html.erb        # CHANGED: itemized readiness list
app/views/dashboard/published_articles/update.turbo_stream.erb # CHANGED: fix stale target
                                                                 #   ("edit_article_#{id}" →
                                                                 #   "#{dom_id @article}_edit_form")

# User Story 5 — Distraction-Free Focus Mode
app/javascript/controllers/article_form_controller.js # CHANGED: focusModeValue toggle,
                                                       #   Esc/keyboard-shortcut handling
app/views/articles/_edit_form.html.erb               # CHANGED: focus-mode-hideable chrome
                                                       #   wrapper classes

# User Story 6 — Live Reader Preview
config/routes.rb                                      # CHANGED: preview becomes `get :preview`
                                                       #   member route (was POST /articles/preview)
app/controllers/articles_controller.rb               # CHANGED: preview loads persisted article
                                                       #   by uuid (author-only), branches on
                                                       #   article.free? instead of authorized?
app/views/articles/preview.html.erb                   # NEW (replaces _preview.html.erb +
                                                       #   preview.turbo_stream.erb): reuses
                                                       #   articles/_full_content and
                                                       #   articles/_partial_content
app/views/articles/_preview.html.erb                  # REMOVED: superseded by preview.html.erb
app/views/articles/preview.turbo_stream.erb           # REMOVED: superseded (GET, not turbo_stream)
app/javascript/controllers/article_form_controller.js # CHANGED: Preview toggle open/close

test/controllers/articles_controller_test.rb          # EXTEND: create/update/autosave/tag-on-
                                                       #   create/conflict/preview coverage
test/controllers/dashboard/published_articles_controller_test.rb # EXTEND or NEW: readiness
                                                       #   list coverage
test/models/article_test.rb                           # EXTEND: lock_version/optimistic-locking
                                                       #   coverage if not already covered
```

**Explicitly NOT touched**: `app/views/admin/**`, `app/controllers/admin/**` (out of scope, consistent with `003`); `Order`/`Transfer`/`Orders::DistributeJob` revenue-distribution logic; authentication/authorization logic; the AASM state machine's transitions/guards (reused, not modified); the already-shipped visual tokens from `specs/002-editorial-ui-redesign/`/`specs/003-editorial-redesign-rollout/` (`application.tailwind.css` theme definitions).

**Structure Decision**: Single-project Rails monolith structure (existing), matching `specs/002-editorial-ui-redesign/` and `specs/003-editorial-redesign-rollout/`'s Option 1 (single project) adaptation. All changes are within `app/controllers`, `app/views/articles`, `app/views/dashboard/published_articles`, `app/javascript/controllers`, `config/routes.rb`, and one `db/migrate` file — no new top-level directories, no new architectural layers.

## Complexity Tracking

*No constitution violations identified — table intentionally omitted.*

## Post-Design Constitution Re-check

Phase 1 artifacts (`data-model.md`, `contracts/component-contracts.md`, `quickstart.md`) introduce exactly one schema change (`lock_version`, a zero-custom-code, convention-based Rails feature) and consolidate two existing controller actions into one rather than adding new ones — net *reduction* in the number of distinct save code paths (from two — `update_content` + `update` — to one). The new `preview` action changes HTTP verb/semantics but replaces rather than adds to the existing (unused) `preview` action. No new gems, no new JS dependencies, no new background jobs, no new authorization surface. The same conclusion as the initial Constitution Check holds: no ratified constitution to gate against; `AGENTS.md`/`.cursor/rules/*.mdc` conventions remain satisfied. No new complexity to track.

**Note on agent-context sync**: The Spec Kit "update agent context" step is skipped — this repository's `.specify/scripts/bash/` does not include an `update-agent-context.sh` script, so there is no script to run for this step (same finding as `specs/002-editorial-ui-redesign/plan.md` and `specs/003-editorial-redesign-rollout/plan.md`).
