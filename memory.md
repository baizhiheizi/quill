---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 29480195051 on 2026-07-16 12:00 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs (local bundles awaiting maintainer revival)**:
  1. **UserMailer#verify_email test coverage** — branch `repo-assist/test-user-mailer-2026-07-16`, commit `e8ea74a4`. 1 file +164/-3. Bundle at `/tmp/gh-aw/aw-repo-assist-test-user-mailer-2026-07-16.{patch,bundle}`.
  2. **Cache-stampede guard (F18/F19/F20 of #1911)** — branch `repo-assist/eng-cache-stampede-guard-2026-07-16`, commit `767f37b2`. 3 files +5/-5. Bundle at `/tmp/gh-aw/aw-repo-assist-eng-cache-stampede-guard-2026-07-16.{patch,bundle}`.
  3. **Collections::SubscribersController preload + test** — branch `repo-assist/fix-subscribers-preload-2026-07-16`, commit `deeba150`. 2 files +228/-4. Bundle at `/tmp/gh-aw/aw-repo-assist-fix-subscribers-preload-2026-07-16.{patch,bundle}`.
- **Other open PRs**: #1912 (Dependabot http 6.0.4), #1910 (test-improver ArticleSnapshot), #1898 (docs unbloat api.md).
- **Open issues**: 8 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-15)**: #1909 (concurrency hazards payment/ledger), #1903 (code-simplifier), #1899 (SessionsController test + dead-order_by fix, revived from local bundle by an-lee).

## This run (29480195051)

- **Selected tasks**: Task 10, Task 3, Task 1, plus Task 11.
- **Task 10 (Take the Repository Forward)**: Created draft PR (commit `deeba150`) addressing the last open `has_many :through` user-list N+1 in the public surface. `Collections::SubscribersController#index` rendered two partials that fired per-row queries: `shared/_avatar` (5+ SELECTs per subscriber for avatar/authorization/blob/variant_records) and `subscribe_users/_subscribe_button` (1 SELECT per row for `current_user.subscribe_user?(user)`). Fix: added inline `user_field_preloads_chain` (same shape as `UserFieldPreloads#user_field_preloads`) + `preloaded_subscribe_user_ids` helper that mirrors `Users::BaseController#preloaded_subscribe_user_ids` (returns empty `Set` for guests since this endpoint is public). Test: filled the placeholder `test/controllers/collections/subscribers_controller_test.rb` with 5 integration tests including an explicit query-count regression guard (≤ 12 SELECTs). `bin/rubocop` + `bin/rails zeitwerk:check` clean. `SKIP_CSS_BUILD=1 bin/rails test test/controllers/collections/` clean (14 / 31 / 0F / 0E / 0S). PR created as bundle per the maintainer-revival pattern.
- **Task 3 (Issue Investigation and Fix)**: Substituted → no-op. No issues labelled `bug`, `help wanted`, or `good first issue` remain open. All 8 open issues are AI-generated proposals/audits or system-managed tracking.
- **Task 1 (Issue Labelling)**: Substituted → no-op. All 8 open issues already labelled (verified: #1913 documentation, #1911 performance/quality/database, #1824 performance, #1817 efficiency, #1810 agentic-workflows, #1801 testing, #1789 repo-assist, #1818 agentic-workflows).
- **Task 11**: Updated #1789. Added this run's draft to Suggested Actions (third entry); refreshed Future Work to remove the now-closed `subscribers_controller_test.rb` gap; prepended the new run entry. Run history retained at 5 entries to stay under the 10 KB hard cap.

## Backlog

- **Concern testing**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 HIGH; contingent offer awaiting ack. F15 (Order#all_transfers_generated? per-row aggregate) deferred per #1571 5-cycle cooldown on payment/Web3 work.
- Respect #1571 5-cycle cooldown on payment/Web3 resilience.
- **N+1 revival classes: ALL COMPLETE**: Dashboard-#index (#1802/#1815/#1829/#1830/#1833/#1862), Admin-#index (#1834/#1837/#1845/#1862/#1868/#1895/#1896), Public article show (#1865), Users namespace (#1866/#1871), Article-feed avatar chain (#1874), Article-feed cover blob (#1880), MarkdownRenderService no-op stub (#1867), **Collections subscribers index (this run)**.
- **Dead-code sweep rounds 1-3**: COMPLETE — #1882 (merged 2026-07-10), #1887 (merged 2026-07-13), #1888 (merged 2026-07-13).
- **Admin::SessionsController test coverage + dead-order_by fix**: COMPLETE — merged as #1899 on 2026-07-15 (revived from local bundle).
- **UserMailer#verify_email test coverage**: COMPLETE — `repo-assist/test-user-mailer-2026-07-16` (this codebase draft from prior run).
- **Cache-stampede guard (F18/F19/F20 of #1911)**: COMPLETE — `repo-assist/eng-cache-stampede-guard-2026-07-16` (this codebase draft from prior run).
- **Collections::SubscribersController preload + test**: COMPLETE — this run's draft.
- **Test gaps remaining**: `test/services/oauth/sign_in_test.rb` (6 tests). Lower priority than `UserMailerTest` / `SubscribersControllerTest`.

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
- **No Postgres in this runner**. Model tests DO run locally; controller/integration tests need the CSS workaround below.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845/#1862/#1865/#1866/#1867/#1868/#1899)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer fetches the local bundle and pushes manually. 3-7 days lag.
- **First-time-contributor CI approval gate (CONFIRMED 28977072290 + 28993481069)**: PRs from `github-actions[bot]` need a maintainer to approve `check.yml` before any job executes. Sits at `action_required` until then.
- **Guard-test pattern for dead-method removal**: when removing a dead method, add `refute_includes <Class>.instance_methods(false), :method_name` to pin the removal.
- **Deletion-only PRs are the maintainer's preferred refactor style**: see #1867, #1872, #1864, #1869, #1882, #1887, #1888.
- **Dead-code confidence ladders**: (a) before deleting a constant, grep `app/`, `lib/`, AND `test/`; constants referenced only in tests = safe to delete with the test reference. (b) before deleting a Ruby method, grep `app/views/`, `app/controllers/`, `app/jobs/`, `app/services/`, `app/libs/`, `app/notifiers/`, AND `test/`; methods referenced only in their own self-referential test = safe to delete with the test reference AND a guard test.
- **`case @order_by` Relation-values-discarded bug pattern (CONFIRMED via PR #1899)**: when a `case` statement's body returns Relation objects and the result isn't assigned back to the local variable, the values are silently discarded. Sibling admin controllers (`pre_orders`, `transfers`, `articles`, `bonuses`, `comments`) all assign the case result back. Canonical pattern: `sessions = case @order_by when ... else sessions.order(...) end` then `pagy(sessions)`.
- **Local integration-test runner workaround (CONFIRMED 29480195051)**: create empty `app/assets/builds/application.css` (bun is unavailable) to satisfy `app/views/layouts/application.html.erb:67`; clean up after the test run. `SKIP_CSS_BUILD=1` is honored.
- **Payment creation in tests (CONFIRMED 29480195051)**: `create_payment!` triggers `after_create :generate_order!`, which creates an Order automatically. To create the Order manually (as test fixtures require), use the `create_payment_for!` pattern from `test/notifiers/collection_bought_notifier_test.rb`: build with `Payment.new`, `define_singleton_method(:generate_order!) { }`, `save!(validate: false)`. Otherwise you'll hit `Validation failed: Order type has already been taken, Trace has already been taken`.
- **`Collections::SubscribersController` N+1 fix shape (NEW 29480195051)**: inline `user_field_preloads_chain` (canonical `UserFieldPreloads#user_field_preloads` shape) + `preloaded_subscribe_user_ids` helper (mirrors `Users::BaseController#preloaded_subscribe_user_ids`, returns empty `Set` for guests). If a second `has_many :through` user-list appears in collections, lift both into a shared module.