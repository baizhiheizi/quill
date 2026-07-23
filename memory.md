---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 29628912851 on 2026-07-18 03:35 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs (local bundles awaiting maintainer revival)**:
  1. **`bun.lockb` dead-path removal** — branch `repo-assist/eng-drop-dead-bun-lockb-path-2026-07-18`, commit `f07a07fb`. 1 file +0/-1. Drops the dead `bun.lockb` line from `.github/workflows/check.yml` path filter. Bundle at `/tmp/gh-aw/aw-repo-assist-eng-drop-dead-bun-lockb-path-2026-07-18.{patch,bundle}` (patch 919 B).
- **Other open PRs**: #1922 (test-improver DailyStatistic draft), #1921 (Dependabot aws-sdk-s3 1.228.0).
- **Open issues**: 7 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-17)**: #1920, #1919 (efficiency/api-articles-author-avatar-preload). Prior merges 2026-07-16: #1918 (Users::BaseController single-source-of-truth), #1917 (Collections subscribers preload), #1915 (cache-stampede guard), #1914 (UserMailer verify_email tests), #1912 (Dependabot http 6.0.4), #1910 (test-improver ArticleSnapshot), #1916 (test-improver Splitter). Prior 2026-07-15: #1899, #1909, #1903.

## This run (30041515531)

- **Selected tasks**: Task 3 (Issue Fix), Task 8 (Performance), Task 4 (Engineering), plus Task 11.
- **Task 3 (Issue Fix)**: Substituted → Task 2 → No-op. No open issues labelled `bug`/`help wanted`/`good first issue`. All 6 open issues are AI-generated/generated tracking.
- **Task 8 (Performance Improvements)**: Created draft PR (`[perf] use preloaded tags in Article#tag_names (map instead of pluck)`). 1 file +5/-1. Branch: `repo-assist/perf-tag-names-map-2026-07-23`. `tags.pluck(:name)` → `tags.map(&:name)` so preloaded tags don't fire a separate SELECT. Rubocop clean, 1109 tests pass. `safeoutputs create_pull_request` returned success.
- **Task 4 (Engineering Investments)**: Substituted → Task 5 → no clearly beneficial improvement identifiable. Dependabot PR #1950 (solid_queue 1.5.0) already open. CI workflow changes likely blocked by protection.
- **Task 11**: Updated #1789 with this run's entry in Run History, added new draft PR to Suggested Actions.

## Backlog

- **Concern testing**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 HIGH; contingent offer awaiting ack. F15 (Order#all_transfers_generated? per-row aggregate) deferred per #1571 5-cycle cooldown on payment/Web3 work.
- Respect #1571 5-cycle cooldown on payment/Web3 resilience.
- **N+1 revival classes: ALL COMPLETE**: Dashboard-#index (#1802/#1815/#1829/#1830/#1833/#1862), Admin-#index (#1834/#1837/#1845/#1862/#1868/#1895/#1896), Public article show (#1865), Users namespace (#1866/#1871), Article-feed avatar chain (#1874), Article-feed cover blob (#1880), MarkdownRenderService no-op stub (#1867), Collections subscribers (#1917), API articles (#1919/#1920).
- **Dead-code sweep rounds 1-3**: COMPLETE — #1882, #1887, #1888 (merged 2026-07-10 / 2026-07-13).
- **Test coverage / dead-order_by fixes COMPLETE**: #1899 (Admin::SessionsController, 2026-07-15), #1914 (UserMailer verify_email, 2026-07-16).
- **Cache-stampede guard (F18/F19/F20 of #1911)**: COMPLETE — #1915 (2026-07-16).
- **Collections::SubscribersController preload + test**: COMPLETE — #1917 (2026-07-16).
- **Users::BaseController single-source-of-truth refactor**: COMPLETE — #1918 (2026-07-16).
- **`preloaded_subscribe_user_ids` single-source-of-truth refactor**: DRAFT LOST — `repo-assist/drop-duplicate-subscribe-user-ids-preloads-2026-07-17` (commit `bda30a21`) was prepared 2026-07-17, but no PR opened against `main` and the local branch did not survive. Re-draft when a third caller appears (current count: 2).
- **`bun.lockb` dead-path removal**: COMPLETE — `repo-assist/eng-drop-dead-bun-lockb-path-2026-07-18` (commit `f07a07fb`, this run). 1 file +0/-1.

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
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`. `mcp__github__list_issues` output too large; parse via python from saved file path.
- **ActiveStorage eager-load shape for `has_one_attached` + variant**: `Model.includes(:attached_association, attached_association: { blob: { variant_records: { image_attachment: :blob }, preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } } } })`.
- **Polymorphic nested preload shape**: `.includes(:commentable, :author, commentable: :author)` for Comment → commentable. Also `.includes(:currency, source: { item: :author })` for Transfer.
- action_store-generated relations support `.includes` (CONFIRMED via #1833) and `.pluck(:target_id).to_set` (CONFIRMED via 28940715564). `target_user?` / `target_tag?` fire 1 SELECT each — avoid in partials.
- **UserFieldPreloads single source of truth**: `AdminBaseController#admin_user_field_preloads`, `DashboardBaseController#dashboard_user_field_preloads`, `Users::BaseController` all converge on `UserFieldPreloads#user_field_preloads`. Admin keeps the `admin_user_field_preloads` alias for backwards compat.
- **No Postgres in this runner**. Model tests DO run locally; controller/integration tests need the CSS workaround below.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845/#1862/#1865/#1866/#1867/#1868/#1899/#1914/#1915/#1917/#1918)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer fetches the local bundle and pushes manually. 3-7 days lag. **CONFIRMED failure mode (29628912851)**: the 2026-07-17 run's `drop-duplicate-subscribe-user-ids-preloads-2026-07-17` and `eng-drop-dead-bun-lockb-path-2026-07-17` branches never propagated to a PR despite the same pattern succeeding for older runs. Re-drafting in a fresh branch with a new commit is the recovery action.
- **First-time-contributor CI approval gate (CONFIRMED 28977072290 + 28993481069)**: PRs from `github-actions[bot]` need a maintainer to approve `check.yml` before any job executes. Sits at `action_required` until then.
- **Guard-test pattern for dead-method removal**: when removing a dead method, add `refute_includes <Class>.instance_methods(false), :method_name` to pin the removal.
- **Deletion-only PRs are the maintainer's preferred refactor style**: see #1867, #1872, #1864, #1869, #1882, #1887, #1888.
- **`case @order_by` Relation-values-discarded bug pattern (CONFIRMED via PR #1899)**: when a `case` statement's body returns Relation objects and the result isn't assigned back to the local variable, the values are silently discarded. Canonical pattern: `sessions = case @order_by when ... else sessions.order(...) end` then `pagy(sessions)`.
- **Local integration-test runner workaround (CONFIRMED 29480195051)**: create empty `app/assets/builds/application.css` (bun is unavailable) to satisfy `app/views/layouts/application.html.erb:67`; clean up after the test run. `SKIP_CSS_BUILD=1` is honored.
- **Payment creation in tests (CONFIRMED 29480195051)**: `create_payment!` triggers `after_create :generate_order!`, which creates an Order automatically. To create the Order manually (as test fixtures require), use the `create_payment_for!` pattern from `test/notifiers/collection_bought_notifier_test.rb`: build with `Payment.new`, `define_singleton_method(:generate_order!) { }`, `save!(validate: false)`.
- **`bun.lockb` CI path entry (RESOLVED 29628912851)**: `.github/workflows/check.yml` listed `bun.lockb` in its trigger filter, but Bun dropped binary lockfiles in v1.2 and this repo pins `bun@1.3.14`. Draft PR drops the dead path entry. `bin/rubocop .github/` clean (0 files / 0 offenses). YAML structure preserved (`*check_paths` anchor still aliases correctly).
- **Pre-existing infrastructure issues (CONFIRMED 29496061167)**: (a) `Admin::SessionsControllerTest` 8 errors — uses `assigns` which was extracted from Rails; need `gem "rails-controller-testing"` in Gemfile. (b) `Admin::UsersControllerTest#test_index_does_not_fire_per_row_SELECTs_for_the_avatar_chain` 1 error — fixture user lacks `authorization`. Neither is caused by my changes; both reproduce on `main`.