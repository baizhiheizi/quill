---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 28699967377 on 2026-07-04 08:07 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs**: 1 draft pending self-hosted CI:
  1. **PR #1830** (`[repo-assist] perf(payments): eager-load currency in dashboard index`) — branch `repo-assist/perf-dashboard-payments-eager-load-2026-07-04-89658ab122c39c75` (commit `0416d2da`). `.includes(:currency)` on `Dashboard::PaymentsController#index`. Closes out the dashboard-#index N+1 revival class. **Opened successfully by `safeoutputs create_pull_request` this run (no manual revival needed)**.
- **Open issues**: 13 (unchanged).
- **Recent merges (this run window)**: #1829 transfers eager-load, #1828 REDUND→REFUND fix, #1827 docs, #1826 Mixpay::API tests, #1825 perf-improver monthly, #1824 perf-improver monthly, #1823 perf-improver transfers (revival of my branch), #1822 Editorial Web3 UI redesign, #1820 MixinNetworkUser tests, #1819 articles-public visibility, #1815 articles eager-load, #1814 docs unbloat, #1813 lexxy 0.9.22.

## This run (28699967377)

- **Selected tasks**: Task 5, Task 3, Task 4, plus Task 11.
- **Task 3 (Issue Fix)**: No `bug` / `help wanted` / `good first issue` issues open in the repo. Substituted to Task 2 per the fallback chain.
- **Task 2 (Issue Comment — substitute for Task 3)**: Commented on #1717 — flagged that both Dependabot PRs it referenced (#1715 graphql 2.6.3→2.6.4 merged 2026-06-24; #1716 lexxy 0.9.18→0.9.19 closed/merged 2026-06-23) have shipped, and the lexxy line advanced further to 0.9.22 via #1813. Applying the bundle's patch on current `main` would downgrade lexxy. Suggested action: close #1717.
- **Task 5 (Coding Improvements)**: No fresh low-risk coding improvement identified this run. PR #1830 already covers the recent coding-improvement theme (`.includes(:currency)` on `Dashboard::PaymentsController#index`). A `dashboard/orders_controller.rb` DRY refactor (`case @order_type / when "buy_article" / :buy_article / ...` → `if Order.order_types.key?(@order_type)`) was identified but is too small to justify its own PR. Also considered: extracting a `prefetch_link_to` helper for the `data: { controller: 'prefetch', turbo_frame: "_top" }` pattern used 35+ times — too invasive for a single PR.
- **Task 4 (Engineering Investments)**: No actionable dependency / CI / build improvement identifiable. The bundle PR (#1717) is now obsolete (its deps were merged individually); Dependabot auto-flow handles ongoing patch updates. Substituted to Task 5 (no-op this run).
- **Task 11**: Updated #1789. Body rewritten with the standard format; "Suggested Actions" now points at PR #1830 directly (was branch+patch+bundle reference in the prior run since the PR wasn't yet opened). Added new "Check comment on #1717" bullet for the closure-suggestion comment posted this run. Run History: prepended 2026-07-04 08:07 UTC entry, kept 2026-07-04 04:09 UTC, 2026-07-03 21:32 UTC, and 2026-07-03 16:56 UTC entries, dropped older entries.

## Previous run (28694259683) — see #1789 Run History

- Selected 2/3/8. PR #1830 (payments eager-load) was created via `safeoutputs create_pull_request` this run — no manual revival needed. Commented on #1821 (F9 closed via #1828, F1+F2 offered contingent, F3–F8 deferred per #1571).

## Earlier runs — see #1789 Run History

- 28684209719: Task 10, Task 4 (→ Task 10 substitute), Task 3. Three drafts revived and merged by maintainer (#1826, #1828, #1829).
- 28673327022: Task 9 (Mixpay::API tests revived → #1826), Task 3 no-op, Task 2 no-op, Task 11.
- 28660097062: Task 1/2/3 no-ops, Task 11.
- 28637693543: Task 2/3/5 (deferred).
- 28622852314, 28607591885: Task 3 no-op (auth-name fix already merged as PR #1811), Task 2 no-op, Task 5 deferred, Task 11.
- 28589515383: Task 3 (auth-name fix, merged as PR #1811 same day), Task 2 no-op, Task 10 (articles perf deferred), Task 11.

## Backlog

- **Concern testing (1 remaining)**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1778** (AGENTS.md codify concern-test convention): CLOSED 2026-07-01 as `not_planned`.
- **Open perf (RESOLVED this window)**: `Dashboard::PaymentsController#index` `:currency` eager-load — PR #1830 (commit `0416d2da`). Awaiting self-hosted CI.
- **Open perf (RESOLVED in prior window)**: `Dashboard::TransfersController#index` — merged as PR #1829.
- **Open perf (RESOLVED)**: `Dashboard::ArticlesController#index` — merged as PR #1815 on 2026-07-03.
- **Open perf (RESOLVED)**: `Dashboard::CollectionsController#index` — merged as PR #1802 on 2026-07-01.
- **Dashboard-#index N+1 revival class: COMPLETE**. No remaining `Dashboard::XxxController#index` actions with obvious single-association eager-load gaps that aren't memo-decoded lookups.
- **Issue #1717** (bundle graphql+lexxy): commented this run noting #1715 + #1716 were merged individually and lexxy advanced to 0.9.22 via #1813. Suggested action: close the bundle. Awaiting maintainer ack.
- **Potential refactor candidates** (next-round, very small): `dashboard/orders_controller.rb` `case @order_type` simplification; `prefetch_link_to` helper for the `data: { controller: 'prefetch', turbo_frame: "_top" }` pattern (35+ usages, too invasive for a single PR).
- Respect issue #1571's 5-cycle cooldown on payment/Web3 resilience.
- #1667 + #1686 + #1694 + #1771 + #1790 + #1794-#1798: maintainer-led design discussions, out of scope.
- **Duplicated perf-improver PRs** (#1783 + #1784): both merged; workflow-determinism issue deferred.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828 (prior run). F1/F2/F3 still HIGH; offer contingent in #1821 comment awaiting maintainer ack.
- **Test gaps** (next-round, lower priority): `MarkdownRenderService`, `RichTextRenderService`, `admin_notification_service`, `text_notification_service` lack direct unit tests.

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`.
- `safeoutputs update_issue` body limit: 10 KB hard cap. This run's body ~5500 bytes — within budget.
- `safeoutputs push_repo_memory` limit: 12 KB total per push.
- **Concern testing pattern**: one canonical instance per concern. Pin decision table for predicates.
- **Test env cache**: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore in teardown.
- **AR association re-query on update**: `article.association` re-queries DB and replaces in-memory object. Singleton-method stubs lost.
- **Pre-existing CI-clean test errors**: `test/controllers/articles_controller_test.rb` (asset pipeline), `test/controllers/pre_orders_controller_test.rb` (SSL to Mixpay), `test/services/rich_text_render_service_test.rb` (Net::HTTPClientException 403 from `FastImage.size`). CI stubs them.
- `User#available_articles` perf: push `.uniq` to SQL via `.or.or.distinct` (PR #1735).
- `includes(:currency).sum(...)` antipattern: use `joins(:currency)`. Closed in PR #1737.
- `Currency#save` raises in test env (`QuillBot.api.asset(asset_id)` in `before_validation`). Use `Currency.new(price_usd: ...)` in memory.
- `Settings.twitter_account` is `prsdigg` in `config/settings/test.yml`. `QuillBotStub#with_quill_bot_stub` provides `FakeApi` with `FAKE_CLIENT_ID`.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`.
- MCP `dependabot alerts`: returns 400 "Pagination using the `page` parameter is not supported". Unreliable.
- **`UserAuthorization` store_accessor quirk (RESOLVED via PR #1811)**: `auth.name` reads `raw["name"]` — but Mixin API populates `full_name`, not `name`. Always use `auth.raw["full_name"]`.
- **ActiveStorage eager-load shape**: `Model.includes(:attached_association, attached_association: :blob)` for `has_one_attached`. Confirmed via PR #1802, #1815, #1829, this-run #5d91eeab.
- **Polymorphic nested preload shape**: `.includes(:currency, source: { item: :author })` for `Transfer → source (Order) → item (Article/Collection) → author`. Confirmed via PR #1802, #1815, #1823, #1829.
- **No Postgres in this runner**. `bin/rails test` unreliable locally for DB-touching specs; rely on `bin/rails zeitwerk:check` + `bin/rubocop`. Pure unit tests (`test/libs/`, `test/services/`) DO run locally. Model tests (DB-backed) ALSO run locally.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded via `includes`. To reduce the per-row `Article.find_by uuid:` query you'd need a schema change (denormalize article_uuid / collection_uuid onto `payments`) or a controller-level preload that bypasses the memoization. Out of scope for a perf-only PR.
- **Maintainer-revival pattern (CONFIRMED via PR #1826, #1828, #1829)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer can fetch the local bundle and push it manually. Three successful revivals in one window confirms the pattern is the project's intended recovery mechanism.
- **`mcp__github__list_issues` output too large**: 95 KB+ for 13 issues. Use a saved file path and parse with python.
- **`MCP list_issues` defaults to ALL states**: pass `state: "OPEN"` to filter.
- **`define_singleton_method` block scoping**: when defining on a target instance, the block runs in context of THAT instance. `@recording` would resolve to the API's @recording (nil), not the test's. Always capture value in a local first.
- **`ActiveSupport::Cache::Entry` semantics**: `attr_reader :@expires_in` is the *absolute expires-at timestamp*, not the duration. Use `entry.expires_at - Time.now.to_f` to get the remaining TTL in seconds.
- **`REDUND` memo typo (CLOSED via PR #1828 this window)**: F9 from #1821. Pure user-visible on-chain label, no lookup-key usage anywhere. Single-hit grep confirmed.
- **No-controller-test perf PR pattern**: PRs #1802 (collections eager-load), #1815 (articles eager-load), #1829 (transfers eager-load), and this run's `repo-assist/perf-dashboard-payments-eager-load-2026-07-04` (commit `5d91eeab`) — all merged code + commit-message-only — no controller-test file added. Regression-guard test shape if ever needed: `ActionController::TestCase` overriding `render`, signing in via `users(:reader_one)`, asserting one `Currency` SELECT and ≤ N `Article`/`Collection`/`User` SELECTs via `ActiveSupport::Notifications.subscribed`.
- **Counter for safe-output Python parsing**: if bash heredoc returns `TypeError: string indices must be integers, not 'str'` on a JSON dict iteration, the issue is usually a nested field (like `labels` or `user`) returning a string when the parser assumed a dict. Wrap field accesses in `isinstance(x, dict)` checks.
- **Pre-existing system-reminder "task tools" nudges fire periodically**: track multi-task work with `TaskCreate` / `TaskUpdate`. Mark in_progress when starting work, completed when finished.
