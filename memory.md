---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 28940715564 on 2026-07-08 12:30 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs**:
  1. **Draft PR — perf articles show page** — branch `repo-assist/perf-article-show-action-store-2026-07-08` (commit `3ce8c929`, 5 files +233/-49). Adds `Article.with_show_associations` scope; batches per-call action_store / order / readers queries with `pluck(:target_id).to_set` + grouped Order count; preloads random_readers sample with avatar chain. Patch + bundle at `/tmp/gh-aw/aw-repo-assist-perf-article-show-action-store-2026-07-08.{patch,bundle}`. Awaiting maintainer-revival.
  2. **Draft PR — perf users subscribe lists** — branch `repo-assist/perf-users-subscribe-action-store-2026-07-08` (commit `40b5648b`, 3 files +53/-0). Adds shared `preloaded_subscribe_user_ids` + `users_user_field_preloads` helpers to `Users::BaseController`; applies both to `Users::SubscribeUsersController#index` and `Users::SubscribeByUsersController#index`. Patch + bundle at `/tmp/gh-aw/aw-repo-assist-perf-users-subscribe-action-store-2026-07-08.{patch,bundle}`. Awaiting maintainer-revival.
- **Other open PRs**: none.
- **Open issues**: 9 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-08)**: PR #1862 (perf dashboard block/subscribe users) — the prior run's draft revived by an-lee. Earlier this week: #1861, #1860, #1859, #1858, #1857, #1856, #1852, #1850, #1849, #1848, #1845, #1844, #1843, #1842, #1838, #1837 — all by `an-lee`.

## This run (28940715564)

- **Selected tasks**: Task 3, Task 8, Task 5, plus Task 11.
- **Task 3 (Issue Investigation and Fix)**: No bug/help-wanted/good-first-issue open. Substituted (no-op).
- **Task 8 (Performance Improvements)**: Created draft PR (commit `3ce8c929`) closing the public article show page N+1 — adds `Article.with_show_associations` scope separate from the index-side `with_associations`; batches per-call `user.upvote_article?` / `downvote_article?` / `article.buy_orders.count` / `reward_orders.count` / `readers.count` / `random_readers(24)` via primed Sets; partials (`_votes`, `_floating_bar`, `_buyers`) consult primed values with `defined?(@var)` fallback so the same partials still render correctly from the unprimed `turbo_stream` responses of UpvotedArticles/DownvotedArticles controllers.
- **Task 5 (Coding Improvements)**: Created draft PR (commit `40b5648b`) extending the #1862 pattern to the public profile subscribers / subscribing lists (`Users::SubscribeUsersController`, `Users::SubscribeByUsersController`). The user-card subscribes-link modal rendering fires the same `shared/_avatar` chain and `subscribe_users/_subscribe_button` partial per row. Helpers (`preloaded_subscribe_user_ids`, `users_user_field_preloads`) live in `Users::BaseController` (guest-safe: empty Set when `current_user` is nil, partial falls through to live helper). Considered but rejected: refactor between `MarkdownRenderService` / `RichTextRenderService` (real duplication but too risky without maintainer signal).
- **Task 11**: Updated #1789 body. Suggested Actions pruned: removed now-merged #1862 entry; added the two new draft PRs (article show + users subscribe); retained #1847, #1840, #1839, #1821. Run History prepended with the 2026-07-08 12:30 UTC entry; trimmed earlier entries to fit the 10 KB safe-output cap.
- **Environmental note**: `test/controllers/articles_controller_test.rb` and `test/integration/dashboard_tabbar_guest_test.rb` fail on the pre-existing `application.css` asset-pipeline error (no `bun`/`esbuild` in this runner); reproduced on `origin/main` without this branch's changes. Documented in both PR bodies.

## Earlier runs — see #1789 Run History

- 28915834322: Draft PR (perf dashboard block/subscribe users, `a7ec2ef8`). **Merged 2026-07-08 as PR #1862.**
- 28885552691: Bundle Dependabot #1849 + #1850 → commit `55cb1805`. **Superseded 2026-07-07** — maintainer merged #1849 + #1850 individually.
- 28853214649: Admin articles avatar preload → commit `c2dd8e67`. **Merged 2026-07-07 as PR #1845.**
- 28825462623: Task 4 no-op (single Dependabot #1842 was aasm major bump).
- 28780541117: Admin N+1 sweep → PR #1837 (merged); notification service tests → PR #1838 (merged).
- 28755231512: PR #1833 (subscribe/comments dashboard eager-load) merged 2026-07-06.
- 28699967377: PR #1830 (payments eager-load) merged 2026-07-04. Commented on #1717.
- 28694259683: PR #1830 opened. Commented on #1821.
- 28684209719: Three drafts revived and merged (#1826 test, #1828 fix, #1829 perf).
- 28673327022: Mixpay::API tests → #1826.
- 28622852314, 28607591885, 28589515383: auth-name fix merged as PR #1811.

## Backlog

- **Concern testing**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1717** (bundle graphql+lexxy): bundle patch is stale — suggested action: close. Awaiting maintainer ack.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 still HIGH; contingent offer in #1821 comment awaiting maintainer ack.
- Respect issue #1571's 5-cycle cooldown on payment/Web3 resilience.
- #1667 + #1686 + #1694 + #1771 + #1790 + #1794-#1798: maintainer-led design discussions, out of scope.
- **Dashboard-#index N+1 revival class: COMPLETE** (#1802/#1815/#1829/#1830/#1833/#1862 all merged).
- **Admin-#index N+1 revival class: COMPLETE** (Orders/Payments/Transfers/Bonuses in main + #1837 + #1845 merged).
- **Public article show N+1 revival class: IN FLIGHT** — this run's `perf-article-show-action-store` draft awaiting revival.
- **Users namespace N+1 revival class: IN FLIGHT** — this run's `perf-users-subscribe-action-store` is the first entry; `Users::ArticlesController#index` and `Users::CommentsController#index` are the obvious follow-ups (same `shared/_avatar` chain).
- **Test gaps (low-value)**: Only `MarkdownRenderService` direct unit tests remain.

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`.
- `safeoutputs update_issue` quota: 1 per run. `add_comment`: 10 per run. `create_pull_request`: 4 per run. Body limit: 10 KB hard cap.
- `safeoutputs` CLI: pipe JSON payload via `.` sentinel: `cat payload.json | safeoutputs update_issue .` (no CLI args).
- **`safeoutputs update_issue` empty-body behavior (CONFIRMED run 28755231512)**: first call without body returned "success" but did NOT modify the body. Always pass the full body.
- **`safeoutputs update_issue` CLI-args-vs-stdin precedence bug (CONFIRMED run 28853214649, FIXED run 28885552691)**: pipe entire payload (including `issue_number`) via stdin only — no CLI flags other than `.`.
- **Test env cache**: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore in teardown.
- **AR association re-query on update**: `article.association` re-queries DB and replaces in-memory object. Singleton-method stubs lost.
- `Currency#save` raises in test env. Use `Currency.new(price_usd: ...)` in memory.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`.
- `mcp__github__list_issues` output too large: 70+ KB for 12 issues. Use a saved file path and parse with python.
- **`UserAuthorization` store_accessor quirk (RESOLVED via PR #1811)**: always use `auth.raw["full_name"]`.
- **ActiveStorage eager-load shape for `has_one_attached` + variant**: `Model.includes(:attached_association, attached_association: { blob: { variant_records: { image_attachment: :blob }, preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } } } })`.
- **Polymorphic nested preload shape**: `.includes(:commentable, :author, commentable: :author)` for Comment → commentable. Also `.includes(:currency, source: { item: :author })` for Transfer.
- **action_store-generated relations support `.includes`** (CONFIRMED via #1833).
- **action_store-generated relations support `.pluck(:target_id).to_set`** (CONFIRMED via this run): returns Set<Integer> for O(1) include? in views. Bypasses the N+1 `find_by(...).present?` pattern.
- **action_store `target_user?(other)` / `target_tag?(other)` methods fire 1 SELECT each** (CONFIRMED via this run). Source: `action-store-1.1.3/lib/action_store/mixin.rb#204-210`.
- **AdminBaseController#admin_user_field_preloads / DashboardBaseController#dashboard_user_field_preloads**: helper at controller level — `.includes(author: admin_user_field_preloads)`.
- **No Postgres in this runner**. `bin/rails test` unreliable locally for DB-touching specs; rely on `bin/rails zeitwerk:check` + `bin/rubocop`. Model tests DO run locally.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer can fetch the local bundle and push it manually. 3-7 days lag between draft and merge.
- **No-controller-test perf PR pattern**: PRs #1802/#1815/#1829/#1830/#1833/#1837/#1845 — code + commit-message only.
- **`AdminNotificationService` asymmetry (CONFIRMED via PR #1838 tests)**: `#text` short-circuits on blank credentials; `#post` does NOT.
- **`TextNotificationService` shape**: single `call(text, recipient_id:)` method.
- **`QuillBotStub` singleton-method capture pattern**: `QuillBot.define_singleton_method(:api) { api }` — block captures `api` from enclosing scope. `define_singleton_method(:api) { @stub_api }` fails.
- **`enqueued_jobs.first[:job]`** returns the class object, NOT a string. Use class equality.
- **`assert_performed_jobs(only: MixinMessages::SendJob)`** runs the enqueued job in the test process.
- **`safeoutputs create_pull_request` patch + bundle pattern**: success returns `{"result":"success","patch":{...},"bundle":{...}}` — these files are the maintainer-revival bundle.
- **Dependabot bundling via git merge** (CONFIRMED 28885552691): `git merge --no-commit --no-ff origin/dependabot/bundler/<dep>` then `git reset --soft HEAD~N`.
- **Dependabot bundling race condition (NEW this run)**: maintainer can merge individual Dependabot PRs before the bundle is revived. The bundle PR becomes stale and the individual PRs must be closed post-merge as superseded.
