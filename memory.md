---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 29496061167 on 2026-07-16 12:30 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs (local bundles awaiting maintainer revival)**:
  1. **`Users::BaseController` single-source-of-truth refactor** — branch `repo-assist/drop-users-user-field-preloads-2026-07-16`, commit `f08bce66`. 4 files +57/-29. Bundle at `/tmp/gh-aw/aw-repo-assist-drop-users-user-field-preloads-2026-07-16.{patch,bundle}` (patch 7,891 B).
- **Other open PRs**: #1912 (Dependabot http 6.0.4), #1910 (test-improver ArticleSnapshot), #1898 (docs unbloat api.md).
- **Open issues**: 8 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-16)**: #1917 (Collections subscribers preload + test, revived from local bundle), #1915 (cache-stampede guard F18/F19/F20), #1914 (UserMailer#verify_email tests), #1910 (test-improver ArticleSnapshot), #1912 (Dependabot http 6.0.4). Prior merges 2026-07-15: #1909, #1903, #1899.

## This run (29496061167)

- **Selected tasks**: Task 2, Task 5, Task 3, plus Task 11.
- **Task 5 (Coding Improvements)**: Created draft PR (commit `f08bce66`) addressing the last `Users::BaseController` single-source-of-truth gap. `Users::BaseController#users_user_field_preloads` was a literal-copy duplicate of the canonical `UserFieldPreloads#user_field_preloads` chain (same `[:authorization, { avatar_attachment: { blob: { ... } } }]` shape). Refactored to `include UserFieldPreloads` (matching `Admin::BaseController` and `Dashboard::BaseController`), dropped the duplicate, updated the two consumers (`Users::SubscribeUsersController`, `Users::SubscribeByUsersController`). New `test/controllers/concerns/user_field_preloads_test.rb` pins the contract across all three bases and guard-tests that the removed helper stays removed (4 / 5 / 0F / 0E / 0S). `bin/rubocop app/ test/` clean (363 files / 0 offenses). `bin/rails zeitwerk:check` clean. Existing controller tests still green (`test/controllers/users_controller_test.rb`, `test/controllers/dashboard/`, `test/controllers/collections/`, `test/controllers/home_controller_test.rb`). PR created as bundle per the maintainer-revival pattern.
- **Task 2 (Issue Investigation and Comment)**: Substituted → no-op. All 8 open issues are AI-generated audits/proposals or system-managed tracking (#1789, #1801, #1817, #1824 monthlies + #1810, #1818 aw + #1911, #1913 audit/proposal). No human-submitted issues requiring substantive engagement.
- **Task 3 (Issue Investigation and Fix)**: Substituted → no-op. No issues labelled `bug`, `help wanted`, or `good first issue` remain open. All 8 open issues are AI-generated.
- **Task 11**: Updated #1789. Removed the three now-merged drafts (test-user-mailer, cache-stampede, fix-subscribers-preload) from Suggested Actions since they're merged as #1914 / #1915 / #1917. Added the new `drop-users-user-field-preloads-2026-07-16` draft to Suggested Actions. Refreshed Future Work to mark merged PRs (#1914 / #1915 / #1917) and the new refactor as complete. Prepended this run entry. Body now 8.8 KB (well under 10 KB cap). Trimmed older 2026-07-13 run entries to keep within budget.

## Backlog

- **Concern testing**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 HIGH; contingent offer awaiting ack. F15 (Order#all_transfers_generated? per-row aggregate) deferred per #1571 5-cycle cooldown on payment/Web3 work.
- Respect #1571 5-cycle cooldown on payment/Web3 resilience.
- **N+1 revival classes: ALL COMPLETE**: Dashboard-#index (#1802/#1815/#1829/#1830/#1833/#1862), Admin-#index (#1834/#1837/#1845/#1862/#1868/#1895/#1896), Public article show (#1865), Users namespace (#1866/#1871), Article-feed avatar chain (#1874), Article-feed cover blob (#1880), MarkdownRenderService no-op stub (#1867), Collections subscribers (#1917).
- **Dead-code sweep rounds 1-3**: COMPLETE — #1882 (merged 2026-07-10), #1887 (merged 2026-07-13), #1888 (merged 2026-07-13).
- **Admin::SessionsController test coverage + dead-order_by fix**: COMPLETE — merged as #1899 on 2026-07-15.
- **UserMailer#verify_email test coverage**: COMPLETE — merged as #1914 on 2026-07-16.
- **Cache-stampede guard (F18/F19/F20 of #1911)**: COMPLETE — merged as #1915 on 2026-07-16.
- **Collections::SubscribersController preload + test**: COMPLETE — merged as #1917 on 2026-07-16.
- **`Users::BaseController` single-source-of-truth refactor**: COMPLETE — `repo-assist/drop-users-user-field-preloads-2026-07-16` (this run's draft).

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
- **AdminBaseController#admin_user_field_preloads / DashboardBaseController#dashboard_user_field_preloads / Users::BaseController#users_user_field_preloads**: all now converge on `UserFieldPreloads#user_field_preloads` (single source of truth, since this run). Admin keeps the `admin_user_field_preloads` alias for backwards compat; dashboard and users use `user_field_preloads` directly.
- **No Postgres in this runner**. Model tests DO run locally; controller/integration tests need the CSS workaround below.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845/#1862/#1865/#1866/#1867/#1868/#1899/#1914/#1915/#1917)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer fetches the local bundle and pushes manually. 3-7 days lag.
- **First-time-contributor CI approval gate (CONFIRMED 28977072290 + 28993481069)**: PRs from `github-actions[bot]` need a maintainer to approve `check.yml` before any job executes. Sits at `action_required` until then.
- **Guard-test pattern for dead-method removal**: when removing a dead method, add `refute_includes <Class>.instance_methods(false), :method_name` to pin the removal.
- **Deletion-only PRs are the maintainer's preferred refactor style**: see #1867, #1872, #1864, #1869, #1882, #1887, #1888.
- **Dead-code confidence ladders**: (a) before deleting a constant, grep `app/`, `lib/`, AND `test/`; constants referenced only in tests = safe to delete with the test reference. (b) before deleting a Ruby method, grep `app/views/`, `app/controllers/`, `app/jobs/`, `app/services/`, `app/libs/`, `app/notifiers/`, AND `test/`; methods referenced only in their own self-referential test = safe to delete with the test reference AND a guard test.
- **`case @order_by` Relation-values-discarded bug pattern (CONFIRMED via PR #1899)**: when a `case` statement's body returns Relation objects and the result isn't assigned back to the local variable, the values are silently discarded. Sibling admin controllers (`pre_orders`, `transfers`, `articles`, `bonuses`, `comments`) all assign the case result back. Canonical pattern: `sessions = case @order_by when ... else sessions.order(...) end` then `pagy(sessions)`.
- **Local integration-test runner workaround (CONFIRMED 29480195051)**: create empty `app/assets/builds/application.css` (bun is unavailable) to satisfy `app/views/layouts/application.html.erb:67`; clean up after the test run. `SKIP_CSS_BUILD=1` is honored.
- **Payment creation in tests (CONFIRMED 29480195051)**: `create_payment!` triggers `after_create :generate_order!`, which creates an Order automatically. To create the Order manually (as test fixtures require), use the `create_payment_for!` pattern from `test/notifiers/collection_bought_notifier_test.rb`: build with `Payment.new`, `define_singleton_method(:generate_order!) { }`, `save!(validate: false)`. Otherwise you'll hit `Validation failed: Order type has already been taken, Trace has already been taken`.
- **`Collections::SubscribersController` N+1 fix shape (NEW 29480195051)**: inline `user_field_preloads_chain` (canonical `UserFieldPreloads#user_field_preloads` shape) + `preloaded_subscribe_user_ids` helper (mirrors `Users::BaseController#preloaded_subscribe_user_ids`, returns empty `Set` for guests). If a second `has_many :through` user-list appears in collections, lift both into a shared module.
- **`Users::BaseController#users_user_field_preloads` duplicate (RESOLVED 29496061167)**: was a literal-copy of `UserFieldPreloads#user_field_preloads`. Comment in the original method said *"if a third caller appears, lift it to a shared module instead of copy-pasting again"*. Two callers existed (`Users::SubscribeUsersController#index`, `Users::SubscribeByUsersController#index`); the shared module (`UserFieldPreloads`) already existed. Now `Users::BaseController` includes the concern (matching `Admin::BaseController` and `Dashboard::BaseController`) and uses `user_field_preloads` directly. `test/controllers/concerns/user_field_preloads_test.rb` pins the contract across all three bases + guard-tests the removed helper.
- **Pre-existing infrastructure issues (CONFIRMED 29496061167)**: (a) `Admin::SessionsControllerTest` 8 errors — uses `assigns` which was extracted from Rails; need `gem "rails-controller-testing"` in Gemfile. (b) `Admin::UsersControllerTest#test_index_does_not_fire_per_row_SELECTs_for_the_avatar_chain` 1 error — fixture user lacks `authorization`. Neither is caused by my changes; both reproduce on `main`.
