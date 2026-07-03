# Implementation Plan: Editorial Web3 UI Redesign — Public Pages

**Branch**: `002-editorial-ui-redesign` | **Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-editorial-ui-redesign/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Redesign Quill's five highest-traffic public surfaces (home feed, article reader, author profile, search results, collection pages) into the editorial, monochrome-plus-one-accent visual system approved in `docs/superpowers/specs/2026-07-03-ui-redesign-design.md`. The technical leverage point: **`app/views/articles/_card.html.erb` is already the single shared partial** rendered by the home feed (`articles#index`), the author-profile articles tab (`users/articles#index`), and collection articles (`collections/articles#index`) — and article search is not a separate page, it's the same `articles#index` action filtered by a `query` param. Redesigning that one partial plus a new shared masthead (replacing the left-sidebar/navbar composition for these five pages only) delivers most of the visual transformation with a small, well-contained set of view/asset changes — no new routes, controllers, models, or migrations.

## Technical Context

**Language/Version**: Ruby 4.0.5 (`.ruby-version`, `mise.toml`), Rails 8.1.x

**Primary Dependencies**: Hotwire (`@hotwired/turbo-rails`, `@hotwired/stimulus`), Tailwind CSS v4 + `flyonui` theme plugin, `@tailwindcss/typography`, `@iconify/tailwind4` with the Tabler icon set (installed, currently unused — this feature adopts it), Pagy (`pagy(:countless, ...)`) for feed pagination, `browser` gem for device detection

**Storage**: PostgreSQL — N/A for this feature (no schema changes; presentation-layer only)

**Testing**: Minitest (`bin/rails test`), Capybara + Selenium system tests (`test/system/*`, e.g. `article_paywall_test.rb`), RuboCop (`rails-omakase`), Prettier (`bun run lint-check`) — all per existing CI (`check.yml`)

**Target Platform**: Server-rendered Rails web app; desktop + mobile browsers, and the Mixin Messenger in-app webview (`from_mixin_messenger?`)

**Project Type**: Single Rails monolith (no frontend/backend split)

**Performance Goals**: No new performance budget requested. Preserve current perceived-load characteristics: Google Fonts already serves CJK families (Noto Serif/Sans SC) pre-split by unicode-range, so adding the new type pairing should not materially change payload versus today's single Noto Sans SC font load. No new JS frameworks/bundles.

**Constraints**:
- Presentation-layer only: no changes to routes, controller params/redirects, revenue-split logic, payment flows, or data models.
- Must follow existing Rails/Hotwire conventions per `AGENTS.md` and `.cursor/rules/*.mdc`: `# frozen_string_literal: true`, `rubocop-rails-omakase`, Stimulus controllers (not vanilla JS) for interactivity, Turbo Frames preserved for infinite scroll (`data-controller="infinite-scroll"`) and lazy-loaded widgets (`turbo_frame_tag ..., loading: :lazy`), FlyonUI component classes (`btn`, `badge`, `dropdown`, `tabs`) over hand-rolled equivalents where FlyonUI already provides the primitive.
- Both light (`quill` theme) and dark (`quill-dark` theme) FlyonUI themes must be updated and reviewed together — never just one.
- Out of scope pages (dashboard/studio, editor, admin, login modal internals) must not regress — only their trigger buttons (e.g. "Write", "Connect Wallet") pick up the new primary-button treatment.

**Scale/Scope**: 5 pages, 1 shared list-row partial reused across 4 of them, ~12–15 view/partial files touched, 1 Tailwind theme file, 2 new/updated Stimulus controllers, 0 new routes/models/migrations.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` in this repository is still the unfilled template (`[PROJECT_NAME] Constitution` placeholders, never ratified) — there are no formal Spec Kit constitution gates to evaluate. In its place, this repo's `AGENTS.md` and `.cursor/rules/*.mdc` files serve as the de facto engineering constitution and are treated as binding for this plan:

- ✅ Ruby files start with `# frozen_string_literal: true`; RuboCop (`rails-omakase`) must pass.
- ✅ Views/partials follow existing patterns (`app/views/**/_*.html.erb`, `UiHelper` block/slot helpers like `render_modal`/`render_dropdown`).
- ✅ No new gems introduced (icon system already installed but unused; no new dependency needed).
- ✅ Tests live under `test/` mirroring `app/`; existing system tests must keep passing.
- ✅ No bypassing `authenticate_user!`/authorization; no change to controller logic at all in this feature.

No violations identified. Complexity Tracking table is not needed (see bottom of this document).

## Project Structure

### Documentation (this feature)

```text
specs/002-editorial-ui-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── component-contracts.md   # Phase 1 output — partial/Stimulus contracts
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created by this command)
```

### Source Code (repository root)

Single Rails monolith — real paths, grouped by what changes vs. what's explicitly untouched:

```text
app/assets/stylesheets/
└── application.tailwind.css       # CHANGED: color tokens (both quill/quill-dark themes),
                                    #   --font-display token, remove tag-style-0..5 utilities,
                                    #   add neutral tag-chip utility

app/javascript/controllers/
├── masthead_controller.js         # NEW: sticky top-nav (mobile menu toggle, scroll shadow)
├── paywall_fade_controller.js     # NEW: reveal state for the fade-to-unlock treatment
├── index.js                       # CHANGED: register the two new controllers
└── (unchanged behaviorally, restyled only via view classes:
     infinite_scroll_controller.js, search_controller.js, tabs_controller.js,
     dropdown_controller.js, darkmode_controller.js)

app/views/layouts/
└── application.html.erb           # CHANGED: swap left_bar/navbar composition for the new
                                    #   masthead on the 5 in-scope pages; dashboard/studio
                                    #   layout usage of left_bar is preserved (out of scope)

app/views/shared/
├── _masthead.html.erb             # NEW: top-nav bar for in-scope public pages
├── _left_bar.html.erb             # UNCHANGED (still used by out-of-scope dashboard pages)
├── _navbar.html.erb                # UNCHANGED (still used by out-of-scope mobile dashboard pages)
└── _footer.html.erb                # CHANGED: restyle only

app/views/home/
└── index.html.erb                 # CHANGED: hero → slim masthead + one-line value prop
                                    #   (logged-out only, per FR-002); this view keeps its
                                    #   existing redirect-based routing (HomeController#index)

app/views/articles/
├── _card.html.erb                 # CHANGED (primary): redesign into the "Minimal List" row;
                                    #   reused by home feed, profile articles tab, collection
                                    #   articles, and search (all render this same partial)
├── index.html.erb                 # CHANGED: restyle filter bar + search form container
├── _filter_bar.html.erb           # CHANGED: restyle only, same tabs/links/params
├── _header.html.erb               # CHANGED: serif headline treatment
├── _content.html.erb              # CHANGED: body copy → sans (Inter/Noto Sans SC) per FR-012
├── _buy_article_button.html.erb   # CHANGED: sticky compact control per FR-007
├── _widgets.html.erb              # CHANGED: remove sidebar-card framing (moves inline/below)
└── show.html.erb                  # CHANGED: single-column layout, no persistent side panel

app/views/users/
├── show.html.erb                  # CHANGED: profile layout restyle
└── _user_card.html.erb            # CHANGED: modest-public-stats treatment per FR-008

app/views/collections/
├── show.html.erb                  # CHANGED: header restyle
└── _detail.html.erb               # CHANGED: restyle only

app/views/tags/
└── _tag_card.html.erb             # CHANGED: neutral chip style (drop tag-style-N) per FR-005

app/views/shared/
└── _empty.html.erb                # CHANGED: friendlier empty-state copy/treatment per FR-014

test/system/
└── article_paywall_test.rb        # VERIFY unchanged behavior still passes; extend if the
                                    #   fade/unlock markup changes selectors the test depends on
```

**Explicitly NOT touched** (out of scope per spec §8): `app/views/dashboard/**`, `app/views/layouts/editor.html.erb`, `app/views/admin/**`, `app/controllers/**` (no controller changes at all), any model/migration/job, `app/views/dashboard/*` sidebar usage of `_left_bar`.

**Structure Decision**: Single-project Rails monolith structure (existing). No new top-level directories. All changes are additive-or-restyle within `app/views`, `app/assets/stylesheets`, and `app/javascript/controllers` — matching Option 1 (single project) from the template, adapted to this repo's actual Rails conventions rather than the generic `src/`/`lib/` layout.

## Complexity Tracking

*No constitution violations identified — table intentionally omitted.*

## Post-Design Constitution Re-check

Phase 1 artifacts (`data-model.md`, `contracts/component-contracts.md`, `quickstart.md`) introduce no new dependencies, no new architectural layers, and no data-model changes beyond what Technical Context already declared. The same conclusion as the initial Constitution Check holds: no ratified constitution to gate against; `AGENTS.md`/`.cursor/rules/*.mdc` conventions remain satisfied by the plan as designed. No new complexity to track.

**Note on agent-context sync**: The Spec Kit "update agent context" step (running an agent script to sync `AGENTS.md`/CLAUDE.md/etc. with plan output) was skipped — this repository's `.specify/scripts/bash/` does not include an `update-agent-context.sh` script, so there is no script to run for this step.
