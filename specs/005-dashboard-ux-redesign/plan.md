# Implementation Plan: Dashboard UI/UX Redesign — From Zero

**Branch**: `005-dashboard-ux-redesign` | **Date**: 2026-07-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-dashboard-ux-redesign/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the dashboard/studio's current shape — a 4-item left sidebar plus five-to-six-item nested horizontal tab strips per page, spread across 24 controllers and ~80 views — with a new information architecture organized around seven task-oriented workspaces (Overview, Authoring, Reading, Finances, Notifications, Account, plus the navigation shell itself), explicitly freed from the left-sidebar constraint that `specs/003-editorial-redesign-rollout/` deliberately imposed (its FR-016) and that the original design doc (`docs/superpowers/specs/2026-07-03-ui-redesign-design.md` §8) recommended keeping. This is a structural + presentation redesign, not a data or business-logic change: every existing controller action, model, and route's *behavior* is preserved; what changes is how the ~20 existing dashboard features are grouped, navigated to, and laid out, plus two genuinely new pieces of user-facing behavior the spec calls for — a real dashboard landing/overview (today's `dashboard#index` just redirects to `readings`) and a discoverable entry point for API access-token management (today unreachable from any UI). The chosen shell pattern is a **collapsible left rail reorganized into 5 labeled top-level groups** (Overview · Write · Read · Finances · Account, with Notifications as a persistent icon-button rather than a 6th group) rather than a flat 4-link list — kept as a rail (not moved to a public-style top masthead) because a studio/control-center context still benefits from persistent, glanceable navigation, but restructured, relabeled, and viewport-adaptive (icon-only rail on narrower desktop widths, full labels on wide) instead of simply restyled in place.

## Technical Context

**Language/Version**: Ruby 4.0.5 (`.ruby-version`, `mise.toml`), Rails 8.1.x

**Primary Dependencies**: Hotwire (`@hotwired/turbo-rails`, `@hotwired/stimulus`), Tailwind CSS v4 + `flyonui` (v2.4.1, `-soft` component modifiers per `specs/003-*`), `@iconify/tailwind4` Tabler icons (`i-tabler-*`), Pagy, `browser` gem (mobile device detection), Ransack (dashboard list filtering where already used) — no new dependency is required for this feature.

**Storage**: PostgreSQL — no schema changes. All data already exists and is already queried by the current controllers (see `Users::Statable` concern: `unread_notifications_count`, `author_revenue_total_usd`, `reader_revenue_total_usd`, `articles_count`, `bought_articles_count`, `payment_total_usd` — all pre-computed helpers ready to power the new Overview without new queries).

**Testing**: Minitest (`bin/rails test`), existing `test/controllers/dashboard/{notifications,published_articles}_controller_test.rb`, RuboCop (`rails-omakase`), Prettier (`bun run lint-check`). Capybara/Selenium system tests cannot launch a browser in this sandbox (same documented limitation as `specs/002-*`/`specs/003-*`) — new controller-level tests are added where routes/redirects change; manual QA covers visual/navigation verification.

**Target Platform**: Server-rendered Rails web app; desktop + mobile browsers, and the Mixin Messenger in-app webview (`browser.device.mobile?` / `from_mixin_messenger?`).

**Project Type**: Single Rails monolith (no frontend/backend split).

**Performance Goals**: No new performance budget. The new Overview page must not introduce N+1 patterns — it reuses already-existing, already-optimized aggregate helpers (`Users::Statable`) and counter-cache columns rather than issuing new per-item queries; a small number of "recent N" queries (recent articles, recent transfers) follow the same `.includes(...)` eager-loading discipline already established in `Dashboard::ArticlesController`/`TransfersController`.

**Constraints**:
- No changes to dashboard authorization (`Dashboard::BaseController#authenticate_user!`), revenue-split logic, payment flows, notification delivery, or any model validation/state-machine behavior (FR-029). Every existing dashboard action (publish, hide, delete, subscribe, block, generate/revoke token, adjust notification setting, update profile) keeps its exact current implementation; only which controller/route/view surfaces it and how it's navigated to may change.
- The left-sidebar navigation shell is **not** preserved as-is — this feature explicitly supersedes `specs/003-editorial-redesign-rollout/` FR-016 for the dashboard (FR-001). It is replaced with a restructured rail (grouped, relabeled, collapsible) rather than removed outright, per the Summary above; mobile keeps a bottom-tab-bar pattern but re-grouped to match the new IA (FR-006).
- Any dashboard route that is renamed, merged, or removed as part of the IA restructuring MUST leave a redirect (or route alias) so previously-valid URLs still resolve to a sensible equivalent page (FR-030) — no route may simply 404 or silently drop query-string tab state that used to work.
- Both light (`quill`) and dark (`quill-dark`) themes must be reviewed together for every new/changed view (FR-027).
- The right-hand widget rail inherited from `layouts/application.html.erb` (join-Quill card, active-authors/hot-tags turbo frames, footer) is public-page content bleeding into the dashboard layout today — this feature must decide, per dashboard page, to remove it, or replace it with dashboard-relevant content (e.g., quick stats, shortcuts) consistent with Edge Cases in spec.md.
- Admin panel and article editor layouts (`layouts/admin.html.erb`, `layouts/editor.html.erb`) are untouched — this feature only touches `layouts/application.html.erb`'s dashboard-facing usage and `app/views/dashboard/**`.

**Scale/Scope**:
- 24 controllers under `Dashboard::`, ~80 view files, 4 shared shell partials (`_left_bar`, `_navbar`, `_tabbar`, plus `layouts/application.html.erb`) — all in scope for structural change (not just restyle, since `specs/003-*` already completed the token-level restyle of every one of these files; this feature builds on top of that restyle, re-plumbing structure/navigation/grouping around the same already-updated visual language).
- 2 genuinely new behaviors: a real `dashboard#index` overview (replacing the `redirect_to dashboard_readings_path`), and a reachable access-tokens entry point in the new Account group.
- Routes: `config/routes/dashboard.rb` is restructured (new top-level group routes for Overview/Authoring/Reading/Finances/Notifications/Account) while preserving redirects from every currently-bookmarkable path (`dashboard_readings_path(tab: ...)`, `dashboard_authorings_path(tab: ...)`, `dashboard_settings_path(tab: ...)`, etc.).
- 0 schema migrations, 0 new background jobs, 0 new gems/npm packages, 0 changes to `Order`/`Transfer`/`Payment`/revenue-distribution logic.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` in this repository is still the unfilled template (`[PROJECT_NAME] Constitution` placeholders, never ratified) — there are no formal Spec Kit constitution gates to evaluate, same finding as `specs/002-*`/`specs/003-*`. `AGENTS.md` and `.cursor/rules/*.mdc` serve as the de facto engineering constitution and are treated as binding for this plan:

- ✅ Ruby files start with `# frozen_string_literal: true`; RuboCop (`rails-omakase`) must pass.
- ✅ Views/partials follow existing patterns (`app/views/**/_*.html.erb`, `UiHelper` block/slot helpers, Turbo Frames for lazy-loaded tab content — same pattern already used throughout the dashboard).
- ✅ Controllers keep inheriting `Dashboard::BaseController`; no new authorization pattern introduced — grouping controllers under new route namespaces reuses the exact same `authenticate_user!`/`current_user` scoping already in place.
- ✅ No new gems or JS dependencies — Turbo Frames, Stimulus `tabs` controller, Pagy, and FlyonUI/Tabler icons (already adopted in `specs/002-*`/`003-*`) cover every UI need here.
- ✅ Tests live under `test/` mirroring `app/`; existing controller tests must keep passing (adjusted for any route renames), and new tests are added for the new `dashboard#index` overview behavior and for redirect coverage on any renamed routes.
- ✅ No bypassing `authenticate_user!`/authorization; no change to any controller's authorization logic in this feature (FR-029).
- ✅ Revenue ratio columns/logic (`Order`, `Transfer`, `Orders::DistributeJob`) are untouched — this feature only changes dashboard *presentation and grouping* of figures already computed by `Users::Statable` and existing controllers, never the calculation.
- ✅ Route changes preserve backward compatibility via redirects (FR-030) rather than breaking existing bookmarks/links, consistent with not introducing regressions for existing users.

No violations identified. Complexity Tracking table is not needed (see bottom of this document).

## Project Structure

### Documentation (this feature)

```text
specs/005-dashboard-ux-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output
├── contracts/
│   └── component-contracts.md   # Phase 1 output — IA, route, and partial contracts
├── checklists/
│   └── requirements.md
└── tasks.md              # Phase 2 output (/speckit-tasks — not created by this command)
```

### Source Code (repository root)

Single Rails monolith — real paths, grouped by user story:

```text
# User Story 1 — Navigation shell & information architecture
config/routes/dashboard.rb                     # CHANGED: regroup routes under new top-level
                                                 #   sections; add redirects for renamed/merged paths
app/views/shared/_dashboard_rail.html.erb      # NEW: replaces `_left_bar` — grouped, relabeled,
                                                 #   collapsible rail (Overview/Write/Read/
                                                 #   Finances/Account + Notifications icon)
app/views/shared/_dashboard_tabbar.html.erb    # NEW: replaces `_tabbar` for dashboard mobile nav,
                                                 #   re-grouped to match the new IA
app/views/shared/_left_bar.html.erb            # REMOVED (public masthead nav is unaffected —
                                                 #   this file was dashboard-only; public pages
                                                 #   already use `shared/_masthead` per specs/002-*)
app/views/shared/_tabbar.html.erb              # REMOVED (superseded by `_dashboard_tabbar`)
app/views/layouts/application.html.erb         # CHANGED: dashboard-facing usage renders
                                                 #   `_dashboard_rail`/`_dashboard_tabbar`;
                                                 #   right-aside widget rail suppressed or
                                                 #   replaced per-page for dashboard contexts
app/controllers/dashboard/base_controller.rb   # CHANGED: sets grouped @active_section/@active_page
                                                 #   for the new rail's current-location highlighting

# User Story 2 — Dashboard Overview (new landing page)
app/controllers/dashboard/home_controller.rb    # CHANGED: #index renders a real overview
                                                 #   (no more redirect_to dashboard_readings_path);
                                                 #   #readings/#authorings/#settings kept as
                                                 #   redirect targets for FR-030 compatibility
                                                 #   where their routes move under new sections
app/views/dashboard/home/index.html.erb         # CHANGED: real overview — unread-notification
                                                 #   count, role-aware earnings snapshot, recent
                                                 #   activity, quick-action shortcuts
app/views/dashboard/home/stats.html.erb         # VERIFY: currently empty/unused — confirmed no
                                                 #   longer needed once overview absorbs its intent,
                                                 #   or repurposed as the overview's stats partial

# User Story 3 — Author workspace ("Write" section)
config/routes/dashboard.rb                      # (same file as above) new `dashboard/write/*`
                                                 #   grouping for articles, collections, transfers
app/views/dashboard/home/authorings.html.erb    # REPLACED by a dedicated authoring workspace view
                                                 #   (status-grouped sections instead of a flat
                                                 #   5-tab strip)
app/views/dashboard/articles/{index,index.turbo_stream,_drafted_article,_hidden_article,_published_article}.html.erb  # CHANGED: restructured within the new workspace
app/views/dashboard/collections/**              # CHANGED: embedded within the workspace, not a
                                                 #   separate top-level nav destination
app/views/dashboard/transfers/**                 # CHANGED: author-role transfer view embedded in
                                                 #   the workspace's earnings sub-section

# User Story 4 — Reading library ("Read" section)
app/views/dashboard/home/readings.html.erb      # REPLACED by a dedicated reading-library view
app/views/dashboard/comments/**                  # CHANGED: embedded within the library
app/views/dashboard/subscriptions/**             # CHANGED: embedded within the library
app/views/dashboard/subscribe_articles/**        # CHANGED: embedded sub-section
app/views/dashboard/subscribe_tags/**            # CHANGED: embedded sub-section
app/views/dashboard/subscribe_users/**           # CHANGED: embedded sub-section

# User Story 5 — Financial / earnings clarity ("Finances" section)
app/controllers/dashboard/orders_controller.rb   # VERIFY: reused for per-article order drill-down
app/controllers/dashboard/payments_controller.rb # VERIFY: reused, surfaced under Finances
app/controllers/dashboard/transfers_controller.rb# CHANGED: unified reader+author view (tab within
                                                 #   one Finances page, not two separate contexts)
app/views/dashboard/payments/**                  # CHANGED: restyled/regrouped under Finances
app/views/dashboard/orders/**                    # CHANGED: restyled/regrouped under Finances
app/views/dashboard/transfers/**                 # CHANGED: single Finances-section presentation
                                                 #   distinguishing reader-reward vs author-revenue

# User Story 6 — Notifications center
app/controllers/dashboard/notifications_controller.rb        # VERIFY: unchanged behavior
app/views/dashboard/notifications/**                          # CHANGED: restructured as its own
                                                               #   center reachable via persistent
                                                               #   icon button (not a rail group)
app/controllers/dashboard/notification_settings_controller.rb # VERIFY: unchanged behavior, UI
                                                               #   embedded within the same center
app/controllers/dashboard/{read_notifications,deleted_notifications}_controller.rb  # VERIFY unchanged

# User Story 7 — Account, security & preferences ("Account" section)
app/views/dashboard/home/settings.html.erb       # REPLACED by a dedicated Account area view
app/views/dashboard/profile_settings/**          # CHANGED: embedded within Account
app/controllers/dashboard/access_tokens_controller.rb  # VERIFY: unchanged behavior — now linked
app/views/dashboard/access_tokens/**              # CHANGED: restyled + linked from Account nav
                                                  #   (closes the current zero-entry-point gap)
app/views/dashboard/block_users/**                # CHANGED: embedded within Account (moved out of
                                                  #   the "My Subscriptions" tab strip, since
                                                  #   blocking isn't a subscription concept)

test/controllers/dashboard/home_controller_test.rb       # NEW: overview renders (not redirects);
                                                          #   role-aware content
test/controllers/dashboard/notifications_controller_test.rb  # VERIFY unchanged
test/controllers/dashboard/published_articles_controller_test.rb  # VERIFY unchanged
test/controllers/dashboard/routing_redirects_test.rb     # NEW: every pre-existing bookmarkable
                                                          #   dashboard path still resolves (FR-030)
```

**Explicitly NOT touched**: `app/views/admin/**`, `app/controllers/admin/**`, `layouts/admin.html.erb`, `layouts/editor.html.erb`, `app/views/shared/_masthead.html.erb` (public top-nav, unrelated to the dashboard rail), any `Order`/`Transfer`/`Payment`/`Article` model or revenue-distribution logic, article/notification/comment business logic and validations.

**Structure Decision**: Single-project Rails monolith structure (existing), matching `specs/002-*`/`003-*`'s Option 1 (single project) adaptation. Route restructuring stays within `config/routes/dashboard.rb` (no new route-file split needed at this scope); view restructuring stays within `app/views/dashboard/**` and `app/views/shared/`; no new top-level directories or architectural layers.

## Complexity Tracking

*No constitution violations identified — table intentionally omitted.*

## Post-Design Constitution Re-check

Phase 1 artifacts (`data-model.md`, `contracts/component-contracts.md`, `quickstart.md`) confirm the redesign stays within the existing architectural shape: no new models, no new background jobs, no new external services. The two behavior-level additions (real `dashboard#index` overview; reachable access-token entry point) are both pure read/navigation additions — the overview composes already-existing `Users::Statable` aggregate methods and small `.limit(N)` recency queries mirroring the eager-loading discipline already used in `Dashboard::ArticlesController`/`TransfersController`; the access-token entry point adds a nav link to an already-fully-implemented, already-tested controller/view (`Dashboard::AccessTokensController`), not new code. Route redirects (FR-030) use standard Rails `redirect_to`/route-alias patterns, not a new routing concept. The same conclusion as the initial Constitution Check holds: no ratified constitution to gate against; `AGENTS.md`/`.cursor/rules/*.mdc` conventions remain satisfied. No new complexity to track.

**Note on agent-context sync**: The Spec Kit "update agent context" step was skipped — this repository's `.specify/scripts/bash/` does not include an `update-agent-context.sh` script, so there is no script to run for this step (same finding as `specs/002-*`/`specs/003-*` plans).
