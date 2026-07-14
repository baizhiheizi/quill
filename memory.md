---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 29368753303 on 2026-07-14 21:23 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs** (awaiting maintainer revival — local bundles):
  1. **Round 3 dead-scopes** — PR #1897, branch `repo-assist/cleanup-dead-scopes-2026-07-14-...`, commit `bd1497ad`. Drops 7 AR scopes.
  2. **Round 4 admin comments/pre_orders avatar chain** — PR #1896, branch `repo-assist/perf-admin-author-payer-avatar-2026-07-14-...`, commit `3b975763`.
  3. **This run's draft — `Admin::SessionsController` test + dead-order_by fix** — branch `repo-assist/test-admin-sessions-2026-07-14`, commit `128996a4`, 2 files +122/-11. 9 integration tests + `case @order_by` Relation-values-discarded fix. Patch + bundle at `/tmp/gh-aw/aw-repo-assist-test-admin-sessions-2026-07-14.{patch,bundle}`.
- **Other open PRs**: #1898 (docs unbloat api.md, sister agent), #1895 (perf-improver admin users avatar preload), #1893 (test-improver mixin_network_snapshots jobs coverage).
- **Open issues**: 9 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-13)**: #1888 (refactor dead TextNotificationService + TestAdapter, round 3, an-lee 22:46), #1887 (refactor dead mixin_deposit_url/public_key/render_flash, round 2, an-lee 22:46).

## This run (29368753303)

- **Selected tasks**: Task 9, Task 4, Task 2, plus Task 11.
- **Task 9 (Testing Improvements)**: Created draft PR (commit `128996a4`) covering `Admin::SessionsController#index` (was placeholder) with 9 integration tests AND fixing a latent bug where the `case @order_by` Relation values were being discarded, making the "Created ASC" dropdown at `app/views/admin/sessions/_query.html.erb` silently dead. Fix mirrors the canonical pattern from `Admin::BonusesController`. `bin/rubocop` + `bin/rails zeitwerk:check` clean. `bin/rails runner` confirms `ORDER BY sessions.created_at ASC` under `created_at_asc`.
- **Task 4 (Engineering Investments)**: Substituted → no-op. `pagy` (43.6.0), `typescript` (7.0.2), `aws-sdk-s3` (1.227.0) all current. No Dependabot PRs open.
- **Task 2 (Issue Comment)**: Substituted → no-op. All 9 open issues are AI-generated proposals/audits or system-managed tracking.
- **Task 11**: Updated #1789. Added this run's draft to Suggested Actions; refreshed Future Work; prepended the new run entry. Removed stale entries (round 3 cleanup push + #1887 review — both merged 2026-07-13).

## Backlog

- **Concern testing**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1717** (bundle graphql+lexxy): stale — suggested action: close. Awaiting maintainer ack.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 HIGH; contingent offer awaiting ack.
- Respect #1571 5-cycle cooldown on payment/Web3 resilience.
- **N+1 revival classes: ALL COMPLETE**: Dashboard-#index (#1802/#1815/#1829/#1830/#1833/#1862), Admin-#index (#1834/#1837/#1845/#1862/#1868/#1895/#1896), Public article show (#1865), Users namespace (#1866/#1871), Article-feed avatar chain (#1874), Article-feed cover blob (#1880), MarkdownRenderService no-op stub (#1867).
- **Dead-code sweep rounds 1-3**: COMPLETE — #1882 (merged 2026-07-10), #1887 (merged 2026-07-13), #1888 (merged 2026-07-13).
- **Admin::SessionsController test coverage + dead-order_by fix**: COMPLETE — this run's draft.
- **Test gaps remaining**: `test/mailers/user_mailer_test.rb` (placeholder, 0 tests), `test/controllers/collections/subscribers_controller_test.rb` (placeholder; inherits 404 paths from BaseController covered in #1891), `test/services/oauth/sign_in_test.rb` (6 tests).

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`. `Minitest::Mock` also gone — use `Object.new` + `define_singleton_method` + closure-captured flag.
- `safeoutputs` quotas: `update_issue` 1/run, `add_comment` 10/run, `create_pull_request` 4/run. Body limit: 10 KB hard cap.
- `safeoutputs` CLI: pipe JSON via `.` sentinel: `safeoutputs <cmd> . < /tmp/gh-aw/agent/payload.json`. Inline `printf` + pipe breaks on backticks/apostrophes in markdown.
- Test env cache: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore in teardown.
- AR association re-query on update: `article.association` re-queries DB and replaces in-memory object. Singleton-method stubs lost.
- `Currency#save` raises in test env. Use `Currency.new(price_usd: ...)` in memory.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`. `mcp__github__list_issues` output too large (70+ KB for 12 issues); parse via python from saved file path.
- **`UserAuthorization` store_accessor quirk (RESOLVED via PR #1811)**: always use `auth.raw["full_name"]`.
- **ActiveStorage eager-load shape for `has_one_attached` + variant**: `Model.includes(:attached_association, attached_association: { blob: { variant_records: { image_attachment: :blob }, preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } } } })`.
- **Polymorphic nested preload shape**: `.includes(:commentable, :author, commentable: :author)` for Comment → commentable. Also `.includes(:currency, source: { item: :author })` for Transfer.
- action_store-generated relations support `.includes` (CONFIRMED via #1833) and `.pluck(:target_id).to_set` (CONFIRMED via 28940715564). `target_user?` / `target_tag?` fire 1 SELECT each — avoid in partials.
- **AdminBaseController#admin_user_field_preloads / DashboardBaseController#dashboard_user_field_preloads / Users::BaseController#users_user_field_preloads**: helper at controller level — `.includes(author: admin_user_field_preloads)`.
- **No Postgres in this runner**. Model tests DO run locally; controller/integration tests do NOT (no CSS assets + no DB). Use `bin/rails runner` to validate controller logic in isolation.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845/#1862/#1865/#1866/#1867/#1868)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer fetches the local bundle and pushes manually. 3-7 days lag.
- **First-time-contributor CI approval gate (CONFIRMED 28977072290 + 28993481069)**: PRs from `github-actions[bot]` need a maintainer to approve `check.yml` before any job executes. Sits at `action_required` until then.
- **Guard-test pattern for dead-method removal**: when removing a dead method, add `refute_includes <Class>.instance_methods(false), :method_name` to pin the removal.
- **Deletion-only PRs are the maintainer's preferred refactor style**: see #1867, #1872, #1864, #1869, #1882, #1887, #1888.
- **Dead-code confidence ladders**: (a) before deleting a constant, grep `app/`, `lib/`, AND `test/`; constants referenced only in tests = safe to delete with the test reference. (b) before deleting a Ruby method, grep `app/views/`, `app/controllers/`, `app/jobs/`, `app/services/`, `app/libs/`, `app/notifiers/`, AND `test/`; methods referenced only in their own self-referential test = safe to delete with the test reference AND a guard test.
- **`case @order_by` Relation-values-discarded bug pattern (NEW 29368753303)**: when a `case` statement's body returns Relation objects and the result isn't assigned back to the local variable, the values are silently discarded. Sibling admin controllers (`pre_orders`, `transfers`, `articles`, `bonuses`, `comments`) all assign the case result back. Canonical pattern: `sessions = case @order_by when ... else sessions.order(...) end` then `pagy(sessions)`.
- **Local admin-controller-test runner cannot execute (CONFIRMED 29368753303)**: every `app/controllers/admin/*` test fails locally with `ActionView::Template::Error: The asset 'application.css' was not found in the load path. app/views/layouts/admin.html.erb:14` — no `app/assets/builds/application.css` (bun not available) + no Postgres. Use `bin/rails runner` for in-process SQL validation, then CI as the authoritative signal for the test suite.