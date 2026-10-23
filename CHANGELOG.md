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

### The deliberate `json` pin

`json` is held at `~> 2.21` (locked 2.21.2).

The pin was necessary on Rails 8.1.3.1, which called `JSON.parse(source,
options)` positionally; json 3 dropped the positional options hash, so **every
json column read raised `ArgumentError` and 500ed any controller that touched
one**. Dependabot #2125 bumped to json 3.0.2 and broke main; #2130 reverted it.

The pin is now conservative rather than required: Rails 8.1.4 (locked since
#2152) calls `JSON.parse(source, **options)`, which json 3 accepts — the
condition the pin was waiting for ("until a Rails release adopts the json 3
signature") was already met by the locked Rails version. The `Gemfile` comment
records why the pin exists; re-test with `gem "json", "~> 3.0"` and drop the
pin if the suite stays green.

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

### Corrections

- **Admin "Created ASC" sort (#2184)** — the `created_at_asc` branch of the
  sort switch in `Admin::ArticlesController` and `Admin::CommentsController`
  ordered by `updated_at DESC`, the opposite of the label and of the other
  ten admin indexes. Both now order by `created_at ASC`.
- **Article asset selection (#2171)** — the editor's asset selector was
  silently discarded on create (it was honoured on update). The chosen
  `asset_id` is now preserved.

### Performance

Two indexes the article surfaces needed but the schema did not have.

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