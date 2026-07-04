# Phase 1 Contracts: Dashboard UI/UX Redesign — From Zero

This is a server-rendered Rails monolith with no public API surface for this feature (dashboard-only, session-authenticated HTML/Turbo Stream views). "Contracts" here means the navigation-shell partial contract, the route-redirect contract, and the per-controller behavior-preservation contract — the things `/speckit-tasks` and implementers must not violate.

## 1. Navigation shell partial contract

**`app/views/shared/_dashboard_rail.html.erb`** (new, replaces `_left_bar.html.erb` for dashboard pages)

- MUST render exactly the 5 sections defined in `data-model.md`'s Dashboard Navigation Structure (Overview, Write, Read, Finances, Account), in that order, plus a persistent Notifications icon+badge (not a 6th section) — per Research §4.
- MUST accept/derive `@active_section` (and optionally `@active_subsection`) from the rendering controller and visually mark the current section (FR-005). Controllers set this the same way `@active_page` is set today (a plain instance variable, no new abstraction required).
- MUST link to `new_article_path`/login modal as the primary CTA, exactly as `_left_bar.html.erb` does today (unchanged behavior, restyled/repositioned only).
- MUST preserve the existing unread-notification badge behavior (`current_user.has_unread_notification?`) on the Notifications icon (Edge Cases: badge must still be visible after the IA change).
- MUST NOT change `Dashboard::BaseController#authenticate_user!` or any authorization check — it is a pure presentation/navigation component.

**`app/views/shared/_dashboard_tabbar.html.erb`** (new, replaces `_tabbar.html.erb` for dashboard pages on mobile)

- MUST expose the same 5 sections (+ Notifications) as the desktop rail — same groupings, no divergent mobile-only IA (FR-006).
- MUST continue to be conditionally rendered only when `browser.device.mobile?`, matching the existing pattern in `layouts/application.html.erb`.

## 2. Route redirect contract (FR-030 / SC-008)

For every "old path" row in `data-model.md`'s Route Redirect Map:

- The route helper (e.g., `dashboard_readings_path`) MUST continue to exist and MUST continue to resolve to a `2xx` or `3xx` response — never a `404` or `500` — after this feature ships.
- Where the underlying page moved, the controller action backing the old route MUST issue a `redirect_to` to the new equivalent path, translating any meaningful `tab:`/`role:` query param to its new equivalent per the mapping table (best-effort; if no clean equivalent sub-tab exists, redirect to the new section's default view rather than erroring).
- This contract is mechanically testable: `test/controllers/dashboard/routing_redirects_test.rb` (new) enumerates every row in the Route Redirect Map and asserts a non-error response for a signed-in user.

## 3. Controller behavior-preservation contract (FR-029)

For every existing `Dashboard::*Controller`, this feature MUST NOT change:

- Authorization checks (`authenticate_user!`, `authorize @article, :update?`, etc.)
- Query scopes/business logic that determine *what* records are shown (e.g., `current_user.articles.drafted`, `current_user.reader_revenue_transfers`)
- Mutation actions' effects (`@article.publish!`, `@article.hide!`, token create/destroy, block/unblock, notification-setting update)

This feature MAY change:

- Which route/URL a given controller action is reached from (per the redirect contract above)
- Which view template renders a given controller's data (restructured into the new section layouts)
- How multiple controllers' output is composed onto one page (e.g., Finances combining `Orders`, `Payments`, `Transfers` controller data into one section)

**Verification**: existing controller tests (`test/controllers/dashboard/{notifications,published_articles}_controller_test.rb`) must keep passing unmodified in their assertions about *behavior* (they may need path/route updates if the specific route they hit moved, but the assertions about what happens — records created/destroyed/updated — must not change).

## 4. Dashboard Overview contract (new behavior)

**`Dashboard::HomeController#index`**

- MUST render a distinct view (no `redirect_to`) — this is the one intentional behavior change to an existing action, explicitly required by FR-007.
- MUST expose the fields defined in `data-model.md`'s Dashboard Overview entity to the view.
- MUST render successfully (with empty states, per FR-011) for a user with zero activity in every category — verified by a new controller test using a freshly-created user fixture with no articles/orders/transfers.
- MUST render role-appropriate content without a separate route/action per role (FR-009) — a single `#index` branches internally (e.g., `@is_author = current_user.articles_count > 0`), not `Dashboard::AuthorHomeController` vs `Dashboard::ReaderHomeController`.

## 5. Account "access tokens" reachability contract (closes existing gap)

- `app/views/shared/_dashboard_rail.html.erb`'s Account section (and `_dashboard_tabbar.html.erb`'s mobile equivalent) MUST include a `link_to`/navigable entry to `dashboard_access_tokens_path`.
- No change to `Dashboard::AccessTokensController` itself (index/create/destroy already fully implemented and correct) — this is purely a new navigation entry point, verified by a new assertion in a view/system-level check that the rendered Account nav contains this link (or, given sandbox system-test limitations per `research.md` §7, a controller test asserting the link's `href` appears in the Account section's rendered HTML).
