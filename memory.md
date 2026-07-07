---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 28853214649 on 2026-07-07 12:30 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs**: 3 draft branches still awaiting revival:
  1. **Draft PR #1837 — admin N+1 sweep Comments/PreOrders/MixinNetworkUsers** — branch `repo-assist/perf-admin-comments-pre-orders-mixin-eager-load-2026-07-06-5529bd72f8720414` (commit `5e9a2c50`, 3 files +37/-3). `bin/rubocop` + `bin/rails zeitwerk:check` clean. `mergeable_state: unstable` (head behind main).
  2. **Draft PR #1838 — AdminNotificationService + TextNotificationService test coverage** — branch `repo-assist/test-admin-text-notification-services-2026-07-06-f0f07409721855e4` (commit `a3ed6cc5`, 2 files +362). 15 tests / 51 assertions / 0 failures. `bin/rubocop` + `bin/rails zeitwerk:check` clean. `mergeable_state: unstable` (head behind main).
  3. **Draft PR — Admin::ArticlesController#index author avatar preload** (NEW this run) — branch `repo-assist/perf-admin-articles-avatar-preload-2026-07-07` (commit `c2dd8e67`, 1 file +1/-1). One-line `.includes(author: admin_user_field_preloads)` chained on `Article.with_associations` to close the last admin `Article.with_associations`-based N+1 (avatar chain). `bin/rubocop` + `bin/rails zeitwerk:check` clean. Patch + bundle preserved at `/tmp/gh-aw/aw-repo-assist-perf-admin-articles-avatar-preload-2026-07-07.{patch,bundle}`.
- **Other open PRs**: #1842 (Dependabot: bump aasm 5.5.2 → 6.0.0 — major version, breaking `whiny_persistence: true` default flip).
- **Open issues**: 10 (all AI-generated). New since prior run: #1839 (large-file-simplifier: split article_form_controller.js), #1840 (repository-quality-improver: Solid Queue background job reliability audit, 15 findings F1–F15).
- **Recent merges (this run window)**: PR #1833 (subscribe/comments dashboard eager-load) merged 2026-07-06 01:56 UTC by `an-lee` — final entry in the dashboard-#index N+1 revival class (#1802 / #1815 / #1829 / #1830 / #1833 all merged).

## This run (28853214649)

- **Selected tasks**: Task 10, Task 2, Task 1, plus Task 11.
- **Task 1 (Issue Labelling)**: All 10 open issues already labelled (`unlabelled_issues: 0`). Substituted to Task 2.
- **Task 2 (Issue Comment)**: No engagement opportunities. All comments on open issues are from `github-actions[bot]`; no human activity to act on. Substituted (no-op).
- **Task 10 (Take the Repository Forward)**: Draft PR (one-line admin articles avatar preload, commit `c2dd8e67`). Closes the last admin `Article.with_associations`-based N+1 — the partial's user-field render via `admin/users/_field` did not use `admin_user_field_preloads` for `:author`. Per-request SELECT estimate (pagy page of 50): ~50–200 extra avatar-chain SELECTs/req → 0. `bin/rubocop` + `bin/rails zeitwerk:check` clean. `Article.with_associations` intentionally left unchanged.
- **Task 11**: **FAILED — `update_issue` quota exhausted without write.** First `cat file.json | safeoutputs update_issue --issue_number 1789 .` returned success but the `--issue_number` CLI flag overshadowed the stdin body (CLI bug: when `--issue_number` is given, the stdin body is dropped). The second test call (no flag, stdin-only) confirmed the body would have been accepted, but the quota was already spent. **Body remains the prior-run version (run 28825462623 from 2026-07-06 21:52 UTC).** Fallback: posted run summary as `add_comment` on #1789 (id `#aw_VwOhl9GP`). The body update will need to happen in the next run with the corrected stdin pattern: `cat payload.json | safeoutputs update_issue .` (no `--issue_number` flag, include `"issue_number": 1789` in the JSON body).

## Previous run (28825462623)

- **Selected tasks**: Task 4, Task 3, Task 2, plus Task 11.
- **Task 4 (Engineering Investments)**: No actionable item this run. Single Dependabot PR (#1842, aasm 5.5.2→6.0.0) is a major-version bump with `whiny_persistence: true` default flip — risky to bundle without maintainer sign-off; CI uses self-hosted runner (no gap to address). Substituted (no-op).
- **Task 3 (Issue Fix)**: No `bug` / `help wanted` / `good first issue` issues open. Substituted to Task 2.
- **Task 2 (Issue Comment)**: No engagement opportunities. All 10 open issues are AI-generated proposals/audits (efficiency-improver, perf-improver, test-improver, repository-quality-improver, large-file-simplifier) or system-managed tracking issues — none warrant a new Repo Assist comment. Substituted (no-op).
- **Task 11**: Updated #1789 body (7,756 bytes — under 10 KB cap) via single `safeoutputs update_issue` call. Refreshed Suggested Actions (removed merged #1830, added draft PRs #1837 + #1838 and Dependabot #1842, added pending #1839 / #1840 audit/proposal items, removed stale #1717 / #1821 "Check comment" lines). Prepended this run's entry to Run History; backfilled 28780541117 (2026-07-06 09:13 UTC) and 28755231512 (2026-07-06 01:56 UTC) which were missing.

## Previous run (28780541117)

- **Selected tasks**: Task 8, Task 2, Task 9, plus Task 11.
- **Task 8 (Performance Improvements)**: Draft PR (3 admin controllers eager-load, commit `7e49c304`). Closes the last 3 remaining `Admin::XxxController#index` actions with obvious association eager-load gaps (Comments/PreOrders/MixinNetworkUsers). `bin/rubocop` + `bin/rails zeitwerk:check` clean.
- **Task 2 (Issue Comment)**: No engagement opportunities. All 8 open issues auto-generated by other AI agents or my own monthly activity issue (#1789). The 5th and final entry in the dashboard-#index N+1 revival class (#1833) was merged 01:56 UTC by `an-lee`.
- **Task 9 (Testing Improvements)**: Draft PR (15 tests / 51 assertions for AdminNotificationService + TextNotificationService, commit `be5a28d0`). Closes the last two service-class test gaps from the prior backlog. `bin/rails test test/services/{admin_notification_service,text_notification_service}_test.rb` clean; `bin/rubocop` clean.
- **Task 11**: Updated #1789 body (single `safeoutputs update_issue` call, full body 9,665 bytes — under 10KB cap). Confirmed safe-output cap respected.

## Previous run (28755231512) — see #1789 Run History

- Selected 5/2/8. Draft PR (subscribe/comments dashboard eager-load, commit `7b517b36`). Both `safeoutputs create_pull_request` calls returned success; PR #1833 was eventually merged 2026-07-06 01:56 UTC by `an-lee` via the standard draft → revival flow.

## Earlier runs — see #1789 Run History

- 28699967377: PR #1830 (payments eager-load) merged by maintainer 2026-07-04 08:23 UTC. Commented on #1717.
- 28694259683: PR #1830 opened. Commented on #1821.
- 28684209719: Three drafts revived and merged (#1826 test, #1828 fix, #1829 perf).
- 28673327022: Mixpay::API tests → #1826.
- 28660097062: Task 1/2/3 no-ops.
- 28622852314, 28607591885, 28589515383: auth-name fix merged as PR #1811.

## Backlog

- **Concern testing (1 remaining)**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Test gaps (lower priority, low-value)**: Only `MarkdownRenderService` direct unit tests remain (but its existing test file is comprehensive at 212 lines; nothing to add).
- **Issue #1717** (bundle graphql+lexxy): bundle patch is stale — suggested action: close. Awaiting maintainer ack.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 still HIGH; contingent offer in #1821 comment awaiting maintainer ack.
- Respect issue #1571's 5-cycle cooldown on payment/Web3 resilience.
- #1667 + #1686 + #1694 + #1771 + #1790 + #1794-#1798: maintainer-led design discussions, out of scope.
- **Dashboard-#index N+1 revival class: COMPLETE** (#1802 collections, #1815 articles, #1829 transfers, #1830 payments, #1833 subscribe+comments — all merged).
- **Admin-#index N+1 revival class: COMPLETE** for Orders/Payments/Transfers/Bonuses (already in main) + Comments/PreOrders/MixinNetworkUsers (PR #1837) + Admin::ArticlesController#index avatar preload (this run). Awaiting revival.

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`.
- `safeoutputs update_issue` quota: 1 per run. `add_comment`: 10 per run. `create_pull_request`: 4 per run. Body limit: 10 KB hard cap.
- `safeoutputs` CLI: `--body @-` and `@filename` DO NOT expand — pipe a JSON payload via the `.` sentinel: `printf '{...}' | safeoutputs update_issue .` (or `add_comment .`).
- **`safeoutputs update_issue` empty-body behavior (CONFIRMED run 28755231512)**: first call without body returned "success" but did NOT modify the body. So the quota was spent without an actual write. Always pass the full body in the first call.
- **`safeoutputs update_issue` CLI-args-vs-stdin precedence bug (CONFIRMED run 28853214649)**: when `--issue_number NNN` is passed as a CLI flag AND stdin has a JSON payload with `body`, the CLI uses ONLY the CLI args (`{"issue_number": NNN}`) — the stdin body is dropped. Result: "success" returned, but no body change. Quota wasted. **Fix: pipe the entire payload (including `issue_number`) via stdin only — no CLI flags other than `.`:** `cat payload.json | safeoutputs update_issue .` where `payload.json = {"body": "...", "issue_number": 1789}`.
- **Test env cache**: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore in teardown.
- **AR association re-query on update**: `article.association` re-queries DB and replaces in-memory object. Singleton-method stubs lost.
- `Currency#save` raises in test env (`QuillBot.api.asset(asset_id)` in `before_validation`). Use `Currency.new(price_usd: ...)` in memory.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`.
- `mcp__github__list_issues` output too large: 70+ KB for 12 issues. Use a saved file path and parse with python.
- **`UserAuthorization` store_accessor quirk (RESOLVED via PR #1811)**: `auth.name` reads `raw["name"]` — but Mixin API populates `full_name`, not `name`. Always use `auth.raw["full_name"]`.
- **ActiveStorage eager-load shape**: `Model.includes(:attached_association, attached_association: :blob)` for `has_one_attached`. Confirmed via #1802, #1815, #1829, #1830.
- **Polymorphic nested preload shape**: `.includes(:commentable, :author, commentable: :author)` for `Comment → commentable (Article) → author`. Also `.includes(:currency, source: { item: :author })` for `Transfer → source (Order) → item (Article/Collection) → author`. Confirmed via #1802, #1815, #1823, #1829, #1830, #1833.
- **action_store-generated relations support `.includes`** (CONFIRMED via #1833): `current_user.commenting_subscribe_articles.includes(:author).order(...)` works as expected.
- **AdminBaseController#admin_user_field_preloads** (CONFIRMED via this run): reuse the existing helper at the controller level — `.includes(author: admin_user_field_preloads)` — instead of inlining the chain. Avoids widening the scope of shared scopes like `Article.with_associations` that have other callers.
- **No Postgres in this runner**. `bin/rails test` unreliable locally for DB-touching specs; rely on `bin/rails zeitwerk:check` + `bin/rubocop`. Pure unit tests (`test/libs/`, `test/services/`) DO run locally. Model tests (DB-backed) ALSO run locally.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded via `includes`. Out of scope for a perf-only PR.
- **Maintainer-revival pattern (CONFIRMED via #1815, #1826, #1828, #1829, #1830, #1833)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer can fetch the local bundle and push it manually. All 3 prior+this-run drafts are in revival-pending state.
- **No-controller-test perf PR pattern**: PRs #1802 / #1815 / #1829 / #1830 / #1833 + this run's perf draft — all merged/drafted code + commit-message-only — no controller-test file added. Regression-guard shape if ever needed: `ActionController::TestCase` overriding `render`, signing in via `users(:reader_one)`, asserting one `Currency` SELECT and ≤ N `Article`/`Collection`/`User` SELECTs via `ActiveSupport::Notifications.subscribed`.
- **Counter for safe-output Python parsing**: if bash heredoc returns `TypeError: string indices must be integers, not 'str'` on a JSON dict iteration, the issue is usually a nested field returning a string when the parser assumed a dict. Wrap field accesses in `isinstance(x, dict)` checks.
- **`AdminNotificationService` asymmetry (CONFIRMED via this-run test)** — `#text` short-circuits on blank `Rails.application.credentials.dig(:admin, :group_conversation_id)`; `#post` does NOT short-circuit. Future refactors would have to decide explicitly. The test file documents this with a comment.
- **`TextNotificationService` shape** — single `call(text, recipient_id:)` method. `QuillBot.api.unique_conversation_id(recipient_id)` resolves to a String; pass it to `plain_text(conversation_id:, data:)`. Whatever `plain_text` returns is what `.stringify_keys` is applied to before enqueueing `MixinMessages::SendJob`.
- **`QuillBotStub` singleton-method capture pattern** (CONFIRMED via the existing `with_quill_bot_stub` helper + this run's tests): `QuillBot.define_singleton_method(:api) { api }` — the block captures `api` from the enclosing scope as a block-local, so when the block evaluates under `QuillBot`, the captured stub is returned (not `nil`). The naive `QuillBot.define_singleton_method(:api) { @stub_api }` form fails because `@stub_api` resolves to `QuillBot.@stub_api` (always nil).
- **`enqueued_jobs.first[:job]`** returns the class object (e.g. `MixinMessages::SendJob`), NOT a string. Use class equality.
- **`assert_performed_jobs(only: MixinMessages::SendJob) do ... end`** runs the enqueued job in the test process. For services that wrap `QuillBot.api.send_message`, stub `send_message` on the api first.
- **`safeoutputs create_pull_request` patch + bundle pattern (CONFIRMED via this run)**: a successful `create_pull_request` call returns `{"result":"success","patch":{"path":"/tmp/gh-aw/aw-<branch>.patch","size":N,"lines":M},"bundle":{"path":"/tmp/gh-aw/aw-<branch>.bundle","size":N}}` — these files are the maintainer-revival bundle if no PR URL opens.