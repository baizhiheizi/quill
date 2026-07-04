# Phase 0 Research: Dashboard UI/UX Redesign — From Zero

No `NEEDS CLARIFICATION` markers remain in `spec.md` — the one major scope-defining question (freedom from the left-sidebar constraint) was already resolved by explicit user direction and is recorded in spec.md's Assumptions. This document resolves the *structural/technical approach* questions needed to plan confidently, grounded in direct inspection of the current codebase (not assumption).

## 1. What does the dashboard actually consist of today, precisely?

**Decision**: Treat the dashboard as 24 controllers / ~80 views under `Dashboard::`, reachable today through exactly 4 sidebar links (Home→redirects, Notifications, My Reading, My Authoring) plus in-page horizontal tab strips:
- **My Reading** (`dashboard/home#readings`) tabs: bought articles, my comments, my subscriptions, my orders, reader-role transfers ("readers_revenue").
- **My Authoring** (`dashboard/home#authorings`) tabs: drafted, collections, published, hidden, author-role transfers ("author_revenue").
- **Settings** (`dashboard/home#settings`, reached only via the avatar dropdown, not the main rail) tabs: profile, notification.
- **My Subscriptions** (nested a level deeper, inside the "my subscriptions" tab of My Reading) sub-tabs: subscribing authors, comment subscriptions, tag subscriptions, blocked users.
- **Orphaned / unreachable**: `Dashboard::AccessTokensController` (index/create/destroy fully implemented, zero navigation entry point anywhere in the current view tree — confirmed via repo-wide search for `dashboard_access_tokens_path`, only match is the route helper itself, no `link_to` call site).
- **Empty/unused**: `app/views/dashboard/home/stats.html.erb` exists (routed at `dashboard#stats` / `dashboard_stats_path`) but is a 0-byte file — a stats page was scaffolded but never built out.

**Rationale**: Confirmed by reading `config/routes/dashboard.rb`, all 24 controllers' source, and the view tree directly (not inferred), plus grepping for every dashboard path helper's call sites. This precise inventory is what FR-002 ("every existing feature MUST remain reachable... no feature becoming harder to find") is checked against.

**Alternatives considered**: Rely on `specs/003-*`'s own scope description of "~77 view files across 24 controllers" as sufficient — rejected as a sole source; that count was accurate for the *restyle* pass but this feature needs the *navigation reachability* map (which routes are actually linked from where), which required fresh inspection.

## 2. Why does the original design doc recommend keeping the sidebar, and why override it now?

**Decision**: Override it, per explicit user direction, but preserve the *rationale* that motivated the original recommendation (a "studio" context benefits from persistent navigation, unlike public reading pages) by keeping a **rail-shaped** shell — just restructured (grouped/relabeled/collapsible) rather than removed in favor of a top-nav-only pattern.

**Rationale**: `docs/superpowers/specs/2026-07-03-ui-redesign-design.md` §8 explicitly deferred the dashboard with "keep a restyled left-sidebar shell here (denser navigation genuinely earns its keep in a studio context), rather than top-nav." That reasoning (studio contexts benefit from a persistent nav surface) is still sound; what was wrong wasn't the *rail* shape, it was the *flat, unlabeled, under-grouped* 4-item content inside it, which forced every one of the ~20 real features into ad hoc nested tab strips instead of the rail doing any organizing work. Restructuring the rail's *content* (grouped sections, collapsible, current-location indication) while keeping its *general position* satisfies the user's "no lock-in" instruction (we are not mechanically preserving the old rail) while still landing on a persistent-nav pattern because it remains the right tool for this context — a genuine redesign decision, not inertia.

**Alternatives considered**:
- *Top-nav masthead (public-page pattern)*: rejected — would need to either flatten all ~20 features into a dropdown-heavy top bar (harder to scan than a grouped rail) or introduce a secondary in-page nav layer anyway (defeating the simplification goal); the original design doc's studio-context reasoning still applies.
- *Command-palette-only navigation (no visible persistent nav)*: rejected — too large a UX departure with no precedent elsewhere in the product, high risk for average users unfamiliar with the pattern, and doesn't solve FR-005 (always show current location) as directly as a persistent rail with active-state highlighting.

## 3. Where do the "unread notifications," "earnings snapshot," and "recent activity" figures for the new Overview come from?

**Decision**: Compose the Overview entirely from already-existing, already-optimized aggregate methods on `Users::Statable` (a `User` model concern) plus two small `.limit(N)` recency queries following the exact `.includes(...)` eager-loading pattern already used in `Dashboard::ArticlesController`/`Dashboard::TransfersController`. No new queries, jobs, or caching layer needed.

**Rationale**: Direct inspection of `app/models/concerns/users/statable.rb` found `unread_notifications_count`/`has_unread_notification?` (already powers the sidebar badge today), `author_revenue_total_usd`, `reader_revenue_total_usd`, `revenue_total_usd`, `articles_count` (counter-cache, O(1)), `bought_articles_count`, `payment_total_usd` — every figure the Overview needs (FR-008) already has a method. "Recent activity" (recently published/active article, recent reads) can reuse the same `current_user.articles.published.order(updated_at: :desc).limit(3)` / `current_user.bought_articles.order(created_at: :desc).limit(3)` shape already used by `Dashboard::ArticlesController#index`, just capped to a small N and eager-loaded the same way.

**Alternatives considered**:
- *Precompute/cache an overview snapshot via a background job*: rejected as unnecessary — every underlying query is already cheap (counter caches or small `.limit()` scans on indexed foreign keys), and introducing a cache-invalidation surface for a low-traffic-per-user page (one dashboard-home render per session, not a hot path) would be premature complexity with no measured need.
- *New dedicated `DashboardOverview` service/presenter object*: worth doing at implementation time for tidiness (keeps the controller thin), but is an implementation-detail choice for `/speckit-tasks`, not a planning-blocking decision — either a plain controller method or a small `Dashboard::OverviewPresenter` PORO would satisfy every functional requirement equally; deferred.

## 4. How should the ~20 features be grouped into the new sections implied by the spec's Key Entities?

**Decision**: Five rail groups plus one persistent icon (not a rail group): **Overview** (landing) · **Write** (drafted/published/hidden articles, collections, author-role earnings — spec's "Author Workspace") · **Read** (bought articles, my comments, subscriptions to authors/tags/comments, reader-role earnings — spec's "Reading Library") · **Finances** (orders/payments plus a unified reader+author transfer view — spec's "Financial View"; author/reader-role earnings *also* surface contextually inside Write/Read per FR-015/FR-018, with Finances as the canonical, complete drill-down) · **Account** (profile, notification preferences, blocked users, access tokens, language/theme — spec's "Account Area"). **Notifications** (spec's "Notifications Center") is reachable via a persistent icon button in the rail/top area (matching the existing bell-icon convention from `_left_bar`/`_navbar` today) rather than a 6th rail entry, since it's a cross-cutting, frequently-checked utility rather than a "browse my stuff" destination — consistent with how it already behaves today (icon + badge, not a full nav item).

**Rationale**: This mapping is a direct, literal translation of spec.md's 7 user stories/Key Entities into a concrete IA — no invention beyond deciding Notifications' rail-vs-icon treatment, which is called out explicitly here as the one implementation decision with two reasonable options. Grouping blocked-user management under Account rather than leaving it nested inside "My Subscriptions" (as today) directly serves spec.md's Edge Cases note that Account should be "one predictable place" and that blocking isn't conceptually a subscription.

**Alternatives considered**:
- *Notifications as a 6th rail group*: viable and not wrong, but demotes the always-visible badge-on-icon pattern (which every user already recognizes from the current sidebar/navbar) to a click-to-expand-then-see-badge pattern — rejected in favor of keeping the icon+badge pattern, which is strictly more glanceable and change-minimal for a feature users check very frequently.
- *Merge Finances entirely into Write/Read (no separate section)*: rejected — spec User Story 5 explicitly calls for "a single, trustworthy place" for money, and orders/payments (which don't belong in either Write or Read alone) need a home; a dedicated Finances section is the only mapping that satisfies FR-019/FR-021 without splitting a user's total financial picture across two unrelated sections.

## 5. How should existing dashboard URLs stay valid once routes are regrouped (FR-030)?

**Decision**: Use plain Rails `redirect_to`/route-alias patterns — for every dashboard route that moves, merges, or is renamed, keep the old route helper/path defined in `config/routes/dashboard.rb` pointing at a controller action that issues a `redirect_to` (301 or 302, decided at implementation time) to the new equivalent path, preserving any meaningful query params (e.g., `tab:`) by mapping old tab names to new section/sub-tab anchors where a clean mapping exists.

**Rationale**: This is the same mechanism Rails apps use for any URL-structure change and requires no new infrastructure; `Dashboard::HomeController#index`'s current `redirect_to dashboard_readings_path` already demonstrates the codebase already uses exactly this technique. No third-party redirect-management gem is justified for ~20 known, enumerable old paths.

**Alternatives considered**: A generic catch-all "legacy dashboard path" redirect table/middleware — rejected as over-engineering for a small, fully-enumerable set of known old paths; explicit per-route redirects are more legible and directly testable (`test/controllers/dashboard/routing_redirects_test.rb`).

## 6. What happens to the right-hand widget rail (join-Quill card, active-authors/hot-tags turbo frames, footer) on dashboard pages?

**Decision**: Suppress the public-page right-aside widget rail entirely on dashboard pages (it is `content_for?(:sidebar)`-overridable per page already in `layouts/application.html.erb`; dashboard pages will consistently opt out rather than each page needing its own override). No replacement dashboard-specific right-rail content is introduced as a *requirement* of this feature — the spec's Edge Cases require a *deliberate* decision (kept/removed/replaced), and "deliberately removed, consistently, for all dashboard pages" satisfies that requirement without inventing new right-rail content that no user story asked for.

**Rationale**: The current right rail (join-Quill prompt, active authors, hot tags, footer) is unambiguously public-page marketing/discovery content with no dashboard relevance — a logged-in user managing their drafts doesn't need a "join Quill" prompt. Removing it also reclaims horizontal space for the wider, denser workspace layouts (author workspace article lists, finance tables) the new sections need. This is a one-line-per-page decision (`content_for :sidebar do %><% end` — an empty override) rather than new component work.

**Alternatives considered**: Repurpose the right rail for contextual quick-stats/shortcuts on every dashboard page — considered, but rejected as a *requirement* here (would be new speculative content not tied to any spec.md acceptance scenario); individual workspace sections may still choose to use that space for section-specific content at implementation time if it clearly serves an FR (e.g., Finances could use it for a running-total card), but that's a per-section implementation choice, not a cross-cutting mandate.

## 7. Testing approach given continued sandbox limitations

**Decision**: Same approach as `specs/002-*`/`specs/003-*` — no new Capybara/Selenium system-test suite (documented sandbox limitation: no browser available). Add controller-level Minitest coverage for the two genuinely new behaviors: `dashboard#index` rendering a real overview (not redirecting) with role-aware content, and a redirect test asserting every pre-existing bookmarkable dashboard path (`dashboard_readings_path(tab: ...)`, `dashboard_authorings_path(tab: ...)`, `dashboard_settings_path(tab: ...)`, etc. — the full enumerable set from Research §1) still resolves to a 2xx/3xx response, not a 404, satisfying SC-008. Run the full existing suite (`bin/rails test`, `bin/rubocop`, `bun run lint-check`) after each user story.

**Rationale**: Matches the testing depth and rationale already established and accepted for `specs/002-*`/`003-*`; this feature's genuinely new logic (overview composition, redirect coverage) is exactly what controller tests are suited for, while the bulk of the change (view/layout restructuring) is verified by manual QA per `quickstart.md`, consistent with prior features in this same series.

**Alternatives considered**: Skip redirect testing entirely and rely on manual QA — rejected; FR-030/SC-008 (no broken old links) is a concrete, enumerable, automatable regression risk given the scale of route restructuring in this feature (larger than either prior redesign phase), so it earns dedicated automated coverage rather than being manual-only.
