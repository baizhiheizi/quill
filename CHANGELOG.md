# Changelog

## Unreleased

### mixin_bot 3.0 and the Blaze async reactor

`mixin_bot` is now `~> 3.0` (locked 3.0.2). The gem replaced its EventMachine
Blaze client with `MixinBot::Blaze::Reactor` (async-websocket), which owns
connect, keepalive, read, ack and reconnect-with-backoff. `bin/mixin_blaze`
shrinks accordingly; the standalone process, its Kamal role, and the
`Settings.blaze_enable` gate are unchanged — only the Blaze half of the feed
moved.

`QuillBot` gained the reactor wiring and `MixinMessage` gained the message
model, both covered by new tests.

### The `json` pin, lifted

`json` is no longer pinned (locked 3.1.0, #2206).

The pin was necessary on Rails 8.1.3.1, which called `JSON.parse(source,
options)` positionally; json 3 dropped the positional options hash, so **every
json column read raised `ArgumentError` and 500ed any controller that touched
one**. Dependabot #2125 bumped to json 3.0.2 and broke main; #2130 reverted it.

Rails 8.1.4 (locked since #2152) calls `JSON.parse(source, **options)`, which
json 3 accepts, so the condition the pin was waiting for was met and #2206
dropped the pin: `gem "json"` is unversioned and the suite runs green on json
3.1. The constraint moved into the `Gemfile` comment, where it belongs — the
real requirement is `rails >= 8.1.4`, not a json version.

### Crash fixes

- **Profile tab crash (#2105)** — any `tab` param other than
  `published`/`bought` left the articles relation `nil` and blew up on
  `.with_associations` (`NoMethodError`). Unknown tabs now fall back to
  `published`.
- **Output buffer encoding (#2107)** — a binary-tagged (ASCII-8BIT) string
  carrying non-ASCII bytes raised `Encoding::CompatibilityError` against a
  UTF-8 output buffer, 500ing the page for every visitor (PostHog 01a0918e:
  14 users hit `/articles` in a 7-second window). Binary-tagged strings are
  re-tagged to UTF-8 on each `append=` path, since `append=`/`concat` are
  class-body aliases of `<<` and would otherwise bypass a prepended `<<`.
- **Unvalidated query params (#2181)** — three pre-order actions and twelve
  admin index actions raised `NoMethodError` on an unknown value. The
  pre-order flow now redirects for an unknown article or an unsupported order
  type, and validates the order type before it can skip authorization; the
  price helper falls back to the item's own price instead of `nil`; the turbo
  stream falls back to the pre-order's currency for an unknown
  `pay_asset_id`; `MixpayPreOrder#pay_url` takes the same optional argument
  as the base class; and the twelve admin indexes match `order_by`/`filter`
  against an allow-list.
- **`Pagy::OptionError` on an out-of-range `?page=` (#2163)** — pagy's
  `CountlessPaginator` raises when `?page=` is out of range, and the first
  fix only covered `ApplicationController`. `Admin::BaseController` is a
  separate hierarchy, so all thirteen admin paginating actions still 500'd on
  `?page=0`. A shared `CoercesPaginationParams` concern now coerces the
  parameter in both base controllers.
- **Unknown dashboard tab (#2178)** — an unrecognised `?tab=` on the dashboard
  articles index left the scope nil and raised `NoMethodError`. It now falls
  back to `drafted`, with the same `presence_in` guard the users' articles
  index adopted for #2105.
- **Nil currency on an article create (#2171)** — `Article#setup_attributes`
  forced every new article to BTC, discarding the asset the author picked in
  the editor, and `ensure_price_not_too_low` dereferenced `currency`
  unconditionally, so an `asset_id` with no `Currency` row raised
  `NoMethodError` (HTTP 500) instead of failing validation.
- **Blank cache keys from user input (#2232)** — three live paths raised
  `ArgumentError: key cannot be blank` (the PostHog alert in #2222).
  `Dashboard::ProfileSettingsController#verify_email` is public and fetched
  `Rails.cache.fetch params[:code]` before checking the param, so a request
  without `code` crashed; it now renders the existing failure UI.
  `HtmlPostProcessor#decorate_image` fetched image dimensions with the raw
  `src` attribute, so an article body containing an `<img>` without a src
  500ed the whole render; src-less images are now left undecorated.
  `SessionsController#twitter` read `params[:state]` unguarded, and its
  early `redirect_to` guards fell through to `auth[:uid]` on `nil`
  (`redirect_to` does not halt); the handler now returns after each guard
  and bounces on a blank state. The Twitter handler itself is still
  unreachable — the omniauth catch-all at `config/routes.rb:21` shadows
  `auth/twitter/callback` — and a routing test pins that shadowing so a
  re-order is a visible, deliberate change rather than an accident.
- **Stale or crafted Mixpay pre-order links (#2234)** — the mixpay button
  encodes the item's class and id in the query string, and
  `MixpayPreOrdersController#show` trusted both. Four inputs raised before
  the action could redirect: an unknown `item_id` hit
  `ActiveRecord::RecordNotFound` in the failure branch, a missing
  `item_type`/`item_id` called `payment_trace_id` on `nil`, a garbage
  `item_type` was constantized (`NameError`), and a failed save for a
  collection built an article-only URL (`UrlGenerationError` — the URL
  generation predates collection pre-orders). Following the #2181
  hardening, the action resolves the item up front (a `presence_in`
  allow-list on `Article` and `Collection`, `find_by` instead of `find`)
  and redirects home when it does not resolve; the failed-save branch routes
  by item class, mirroring `PreOrdersController#show`, so a collection
  failure now lands on the collection page.
- **A client-supplied `Client-Ip` header 500ed the request (#2243)** —
  `ActionDispatch::RemoteIp` raises `IpSpoofAttackError` when a request
  carries both a `Client-Ip` header and an `X-Forwarded-For` chain that
  disagrees with it. kamal-proxy sets `X-Forwarded-For` itself and forwards
  client headers untouched, so any caller could 500 a request at will by
  sending a stale `Client-Ip`. The spoofing check is now off
  (`config.action_dispatch.ip_spoofing_check = false`); the client address
  still resolves from the proxy-set chain.

### Security

- **Stored XSS in article HTML (#2176)** — ActionText only sanitizes a
  `RichText` when it is rendered through `ActionText::ContentHelper`, and
  all three render paths read the raw fragment instead, so a `<script>` tag
  posted alongside an article reached every reader's page. An allow-list
  sanitizer (`HtmlSanitizer`) now runs inside both render services, covering
  the article body, the API's paid-content body and collection
  descriptions. A disallowed element is pruned together with its content, so
  a `<script>` never survives even as inert text. `iframe` stays allowed in
  the sanitizer on purpose, so the narrow per-source policy lives in one
  place: `HtmlPostProcessor#escape_iframes` removes every iframe whose `src`
  is not a YouTube URL.
- **A client-chosen rate-limit bucket via the `Forwarded` header** — Rack
  resolves the client address by preferring the RFC 7239 `Forwarded` header
  over `X-Forwarded-For`, and kamal-proxy forwards `Forwarded` untouched, so
  a caller could rotate `Forwarded: for=<random>` and land in a fresh
  `Rack::Attack` bucket on every request — defeating the admin-login
  brute-force limit (5 per 20s), the OAuth callback limit (10 per minute) and
  the catch-all IP limit. `Rack::Request.forwarded_priority` is now
  `[:x_forwarded]`, so only the header kamal-proxy actually sets is trusted.

### Corrections

- **Admin "Created ASC" sort (#2184)** — the `created_at_asc` branch of the
  sort switch in `Admin::ArticlesController` and `Admin::CommentsController`
  ordered by `updated_at DESC`, the opposite of the label and of the other
  ten admin indexes. Both now order by `created_at ASC`.
- **Article asset selection (#2171)** — the editor's asset selector was
  silently discarded on create (it was honoured on update). The chosen
  `asset_id` is now preserved.
- **Admin sort options that did not match their columns (#2186)** — the admin
  users list renders `author_revenue_total_usd`, but its "Revenue" option
  ordered by author *and* reader revenue (`User.order_by_revenue_total`), so
  the list was never ordered by the number on screen. The collections list
  offered only `created_at` sorts, labelled just "DESC"/"ASC", leaving it
  ambiguous which timestamp was being sorted. Users now sort by the author
  revenue the column displays (total revenue remains as its own labelled
  option), and collections gained the missing `updated_at` sorts; all four
  options are named after the column they order.
- **Design-system source links 404ed (#2189)** — the `/design-system` page
  built each primitive's "source" link from the app host, a URL that does not
  exist. The links now point at each primitive's file in the GitHub
  repository.

### Performance

Two indexes the article surfaces needed but the schema did not have, one
authorization lookup the article page was repeating, and two per-row query
chains — the comments list and header live search — collapsed into preloads.
The landing page also stops running its discovery work on the visits that end
in the feed redirect.

- **`articles (state, published_at)`** — `state` was unindexed, so every
  `Article.only_published` query seq-scanned the table: the web feed, the
  JSON API index, the home page's article count and revenue sum, and the
  admin articles index. `published_at` was unindexed too, so the "lately"
  feed sort (`ORDER BY published_at DESC`) sorted the whole published set
  before taking 50 rows. With the composite index the "lately" feed is a
  backward index scan that returns rows already in order.
- **`taggings (article_id)`** — the only index on `taggings` was
  `(tag_id, article_id)`, which cannot answer a lookup by `article_id`
  alone. Every article list preloads `:tags` through that join
  (`Article.with_associations` → `includes(:tags)`), so the preload seq-scanned
  `taggings` on every feed page.
- **`Article#authorized?` asks the database once per reader** — the article
  page asks the same question about the same reader seven times: the policy,
  the content partial, the comments card, the buyers list, the mobile
  floating bar and the controller's impression tag all call `authorized?`.
  Each call re-ran the same buy-order lookup, rebuilding the relation and
  regenerating the SQL every time. The answer is now cached on the instance,
  which lasts exactly one request — an order for the article and the reader
  is only ever created by `Payment#generate_order!`, and that runs in a
  background job, never in the request that renders the page.

  On a paid article viewed by a signed-in reader who has not bought it, the
  seven lookups cost about 5.8 ms; the cached answer costs about 0.2 ms.
- **Comments list preloads everything one row touches (#2219)** — the
  article page's comments turbo frame fired a SELECT per comment row: each
  row's rich text, its commentable plus that article's buy-order lookup for
  the reply gate, the quoted comment with its author and body, and the
  viewer's per-row upvote/downvote checks. On a representative 13-comment
  page that measured 69 SQL statements for a signed-in reader and 39 for a
  guest. The index now preloads author avatar chains (`User::AVATAR_PRELOADS`),
  the commentable with its author, both rich-text bodies and the quote chain,
  and primes page-scoped viewer vote sets via `ViewerActionSets#ids_for`,
  which gains the `upvote_comment`/`downvote_comment` verbs and an optional
  `target_ids:` scope. Measured on the same page: 22 signed-in, 14 guest.
  Query-count tests pin the budgets and fail on the unpatched code.
- **Live search preloads the avatar chain (#2221)** — the header live search
  fires one turbo-stream request per keystroke (300 ms debounce) and rendered
  `shared/_avatar` with `thumb: true` per user hit, each hit walking the
  avatar chain unpaged: an authorization SELECT plus an attachment SELECT per
  row, measuring 22 SQL statements on a full page of 10 hits. The ransack
  result now applies the shared `User::AVATAR_PRELOADS`, as every other
  avatar surface already does; the same page costs 4 statements regardless of
  hit count, and a query-budget test pins the page to 8.
- **The landing page skips its discovery work when it redirects (#2236)** —
  `HomeController#index` short-circuits signed-in and mobile visitors to the
  feed, but `redirect_to` does not halt the action, so the platform-stat
  aggregates, the hot-tags sample and the active-authors sample still ran and
  were discarded on every redirecting visit — the two `RANDOM()` sample
  queries in production, four aggregate queries when the caches are cold.
  The action now returns the redirect, and query-count tests pin the redirect
  path to zero discovery SQL (both fail with the full wasted query list on
  the unpatched code).

The migration also runs `ANALYZE` on both tables. Postgres collects per-index
statistics during `ANALYZE`, and an index added to a populated table has
none — without them the planner will not choose the ordered index scan, so
the index would sit unused until the next autovacuum.

`bin/measure-feed-indexes` reproduces the measurement: it seeds a synthetic
dataset inside a transaction it rolls back, then runs `EXPLAIN (ANALYZE,
BUFFERS)` on the queries the feed issues, with and without the indexes. On
20,000 articles with 30% published, the "lately" feed sort goes from a
seq-scan-and-sort to an index scan (3.49 ms → 0.05 ms), the tags preload
goes from 0.77 ms to 0.01 ms, and the home page's published-article count
goes from 1.57 ms to 0.64 ms. The default feed sort (popularity) is
unchanged — it orders on a computed expression, so it reads and sorts the
published set regardless.

### Dependencies

`ransack` 4.4.1 → 5.0.0 (#2128, now locked 6.0.0). Also bumped since the
release: lexxy 0.9.31 → 1.0.1 (crossed 1.0, #2157), posthog-rails 3.18.4 →
3.19.1, pagy 43.6.2 → 43.8.1, sqlite3 2.9.6 → 2.10.0, simplecov 1.1.1 →
1.3.2, bootsnap 1.25.0 → 1.26.0, aws-sdk-s3 1.229.0 → 1.233.2,
image_processing 2.0.3 → 2.2.0, mission_control-jobs 1.2.0 → 1.3.1,
selenium-webdriver 4.48.0 → 4.51.0.

Bundled into one lockfile update (supersedes #2191 and #2192): aws-sdk-s3
1.233.2 → 1.235.0, sqlite3 2.10.0 → 2.10.1, posthog-rails 3.19.2 → 3.19.6,
pghero 4.0.1 → 4.1.0, mailjet 1.8.3 → 1.9.0, rubocop 1.92.0 → 1.92.1.

The Ruby 4.0.9 upgrade's bundle (#2206) carried omniauth 2.1.4 → 2.3.1
(#2200) plus omniauth-oauth2 1.9.0 → 1.10.0, json 2.21.2 → 3.1.0 (the pin
lift above), aws-sdk-s3 1.235.0 → 1.236.0 and lexxy 1.0.1 → 1.0.2.

The 2026-11-03 Dependabot batch: annotaterb 4.25.0 → 4.26.0 (#2212),
selenium-webdriver 4.51.0 → 4.52.0 (#2213), lexxy 1.0.2 → 1.0.3 (#2214),
aws-sdk-s3 1.236.0 → 1.237.0 (#2215), addressable 2.9.0 → 2.9.1 (#2216).

The 2026-11-04 bundle update: **Rails 8.1.4 → 8.1.4.1**, **grover 1.2.10 →
2.0.0 (major)**, posthog-rails 3.19.6 → 3.20.0, posthog-ruby 3.28.4 →
3.29.0, solid_queue 1.7.0 → 1.7.2, noticed 3.1.0 → 3.1.1, rubocop 1.92.1 →
1.92.2, addressable 2.9.1 → 2.9.2, nokogiri 1.19.6 → 1.19.7, kaminari
1.3.1 → 1.3.2, and transitive bumps (bls12-381 0.5.0, httpclient 2.10.0,
h2c 0.4.0, net-scp 4.2.1, net-sftp 4.1.1, msgpack 1.8.7). The full suite
runs green on grover 2.

The 2026-11-10 Dependabot round was bundled twice. The first bundle (#2245,
lockfile-identical to the union of the three open Dependabot PRs) carried
aws-sdk-s3 1.237.0 → 1.238.0 (#2242), grover 2.0.0 → 2.0.1 (#2241) and
posthog-rails 3.20.0 → 3.20.4 (#2240), with aws-partitions 1.1303.0,
aws-sdk-core 3.265.0, aws-sdk-kms 1.140.0, posthog-ruby 3.30.2 and
irb 1.19.0 transitively.

The second bundle (#2247) was a conservative update — a plain `bundle
update` also dragged minitest 6.1.0 and prism 2.x in through the shared
graph, so they stay locked — carrying aws-sdk-s3 1.238.0 → 1.240.0,
kaminari 1.3.2 → 1.3.3, lexxy 1.0.3 → 1.0.4, pagy 43.8.1 → 43.8.2,
posthog-rails 3.20.4 → 3.22.0, ransack 6.0.1 → 6.1.0 and rubocop-ast
1.50.0 → 1.51.0, with aws-sdk-core 3.266.0 and posthog-ruby 3.32.1
transitively (rubocop-ast's prism floor moved from `~> 1.7` to `>= 1.7`).

### Tooling and docs corrections

- `docs/how-to/deploy-with-kamal.md` corrected against the real deployment:
  app host IP, `Release` (not `Deploy`) as the workflow name,
  `bin/kamal deploy --skip-push`, `KAMAL_REGISTRY_PASSWORD` as a ghcr.io
  login, and the rollback snippet (`workflow_dispatch` takes a branch or tag,
  not a bare SHA).
- `bin/measure-frontend-efficiency` now reports `reduced_motion_rule`
  alongside `motion_reduce_aware`. Motion is gated by one
  `@media (prefers-reduced-motion: reduce)` rule in the token layer, so the
  view-level count alone read as a false gap.
- `AGENTS.md` corrected: Docker Hub image name, `deploy.yml` → `release.yml`.
- `API::RenderingHelper` gained a contract test covering all seven render
  helpers (#2169), pinning the JSON response shape the API returns.
- Ruby 4.0.5 → 4.0.9 across `.ruby-version`, `mise.toml`, the Dockerfile, the
  CI runtime and the docs; the Gemfile constraint loosened to `ruby "~> 4"`
  (#2206).
- The rack-attack throttle tests no longer depend on the counter bucket:
  Rack::Attack keys its counters per `Time.now.to_i / period`, so a request
  landing in the next bucket started a fresh counter and the fixed-count
  admin-login, OAuth-callback and API throttle tests failed whenever their
  requests straddled a boundary. They now drive until the throttle fires
  through a shared helper, asserting the documented minimum was served and
  the throttle does fire (#2187).
- Three untested helpers gained test files: `DashboardHelper`,
  `DesignSystemHelper` and the `HtmlPostProcessor` service (#2188).
- Dev tooling: the `gh-aw` workflow lock and actions were upgraded, and
  OpenSpec skill definitions were added under `.agents/skills/`.
- Integration tests sign in through the real OAuth callback (#2233).
  `IntegrationTestCase#sign_in` wrote `session[:current_session_id]` between
  requests, but in an integration test `session` wraps the *last* request's
  env, so the write never reached the cookie jar and every signed-in
  integration test silently ran as a guest. `sign_in` now drives the real
  mixin callback in OmniAuth test mode (pre-creating the bound
  `UserAuthorization`), and raises loudly if the callback does not produce a
  session, so a silently-broken sign-in can never happen again. Three tests
  that were passing vacuously as guests now exercise their real branches.
- `agent.project.yaml` added — an agent-facing repo manifest (stack, command
  entry points, review rubric, and merge gates) for the automation agents
  that work in this repository.
- `Admin::WalletsController` gained controller tests (#2238), covering all
  three actions through both wallet-resolution paths — the platform wallet
  (QuillBot client_id) and a `MixinNetworkUser` wallet (`mixin_api` stubbed
  at class level, since the controller loads the record itself) — plus the
  pagination `has_next` behavior on full and short pages and the raise on an
  unknown `wallet_id`. Writing the lookup test surfaced a small dedupe:
  `load_wallet` ran `MixinNetworkUser.find_by` twice per request (once for
  the truthiness check, then again for the value); it now finds once and
  chains `mixin_api` (2 → 1 lookups, pinned by capturing the
  `sql.active_record` stream directly — the duplicate hid behind the
  statement cache, whose events `assert_queries_match` skips as cached).
  Also fixed the raise message typo ("Wallet nof found"), which the message
  assertion pins.
- `Admin::LoginController` and `Admin::OverviewController` gained controller
  tests (#2239). The credential path is covered both ways — a valid password
  signs in, a wrong password and an unknown name are rejected without
  signing in, logout clears the session — using purpose-built
  `Administrator`s, because the shared fixture's `password_digest` is not a
  real bcrypt hash. The overview render is wrapped in the quill-bot stub its
  view needs: it resolves
  `admin_wallet_safe_outputs_path(QuillBot.api.client_id)`, and an unstubbed
  `client_id` is nil in the test env, so the route helper raises.
- `PagesController` gained its first tests (#2248): `/fair` and `/rules`
  render 200 with their i18n headings under the public layout.
- `Admin::OrdersController`, `Admin::PaymentsController` and
  `Admin::StatisticsController` gained controller tests (#2251) — the last
  three untested admin controllers. Each index pins its filter semantics
  (buyer/payer, item type/id, state, and the statistics STI type filter),
  the `order_by` allow-list fallbacks through `allowed_param` (including the
  unknown-value fallback), ransack OR-query matching, and the show actions.
  Because the shipped fixtures for all three tables are near-empty and the
  index partials dereference `currency.icon_url` and `datetime` unguarded,
  each setup wipes the shipped fixtures and builds well-formed records via
  the shared commerce helpers.

### specs/011-comprehensive-ui-refactor

#### Design system foundation

Quill now has a single, well-maintained design system. Open `/design-system`
in development (or as an Administrator in production) to see every token and
every primitive in one place.

**New shared primitives** (`app/views/shared/_*.html.erb`, all wrapped in
`UiHelper`):

- `render_button` (`_button.html.erb`) — five variants × three sizes; icon-first.
- `render_chip` (`_chip.html.erb`) — topic / price / status / reward.
- `render_list_row` (`_list_row.html.erb`) — Minimal List row used by feed /
  search / author profile / collection.
- `render_value_note` (`_value_note.html.erb`) — text-only muted-amber reward
  figure (never a filled badge, per brand spec).
- `render_notification_card` (`_notification_card.html.erb`) — inbox card
  + real-time toast.
- `render_skeleton` (`_skeleton.html.erb`) — loading placeholder.
- `render_state_empty` (`_state_empty.html.erb`) — empty/error state block;
  used by every error page.
- `render_table` (`_table.html.erb`) — generic data table; replaces bespoke
  dashboard + admin tables.

**New tooling**:

- `bin/lint-design-system` — Ruby static analyzer that walks every view +
  helper + Stimulus controller + stylesheet and enforces the design-system
  contracts DS001–DS013. Wired into `bin/ci` (CI) and `bin/rubocop`
  (developer workflow). Only `:error` and `:warning` severities block.
- `bin/perf-baseline-capture` — captures `bin/measure-frontend-efficiency`
  output to `specs/011-comprehensive-ui-refactor/perf/` for regression
  detection.
- `lib/design_system/{lint,primitives,violation}.rb` — the design-system
  core. `DesignSystem::Primitives::Registry` is populated from a directory
  scan of `app/views/shared/_*.html.erb`, so the registry and the
  filesystem never drift.

**Token layer** (`app/assets/stylesheets/application.tailwind.css`):

- 8pt spacing scale (`--gap-xs/sm/md/lg/xl/2xl`)
- Brand-spec radii (`--radius`, `--radius-lg`, `--radius-full`)
- Container / measure / gutter variables
- `--ring` focus-ring token
- `--coin-*` payment-asset marks
- New `@utility` rules: `reward-text`, `focus-ring`, `scrollbar-thin`,
  `content-prose`

**Routes**:

- `GET /design-system` → `DesignSystemController#show` (development-only;
  production requests are redirected to `root_path` with status `:not_found`).

**Snapshots**:

- `docs/superpowers/specs/opendesign-011/` — frozen copy of the OpenDesign
  brand spec + 9 HTML prototypes + style.css. The live source-of-truth
  remains the OpenDesign project; the snapshot is for diffability.

#### Layout refresh

- `app/views/layouts/admin.html.erb` — body class switched to design-system
  base (`min-h-screen bg-base-100 text-base-content`).
- `app/views/errors/{not_found,internal_server_error,not_acceptable,unprocessable_entity}.html.erb`
  — rewritten to use `render_state_empty` + `render_button` (serif display
  headline, neutral palette, accent CTA).
- `app/views/pages/fair.html.erb` — Stats page refactored: editorial
  header (`PLATFORM` eyebrow + serif headline + subhead), stat cards in
  `rounded-[14px]` containers, transfers list in a bordered section.
- `app/views/pages/rules.html.erb` — Long-form content page matched to
  the same header pattern; body wrapped in the existing `prose-article`
  utility.
- `app/views/transfers/stats.html.erb` — Stat cards refactored to use
  `render_value_note` + `bg-base-200` token; the six `bg-[#F4F4F4]`
  arbitrary-value cells (DS001 violations) are gone.
- New i18n keys (`ds_platform_label`, `ds_fair_subhead`,
  `ds_transfers_heading`, `ds_transfers_last_n`, `ds_rules_subhead`) in
  `config/locales/views.{en,ja,zh-CN}.yml`.

#### Documented follow-up

The foundation is in place; mechanical migration of all 116 raw `<button
class="btn btn-*">` and 16 raw `<table>` occurrences across the rest of the
app is tracked as `DS005` / `DS007` violations by `bin/lint-design-system`.
Each is a single, well-defined refactor — see the lint output and
`specs/011-comprehensive-ui-refactor/contracts/lint-rules.md` for the
target. The design system entry point renders every primitive so the
migration destination is unambiguous.