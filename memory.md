---
name: repo-assist-memory
description: Repo Assist run state — selected tasks, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 28505722701 on 2026-07-01 09:39 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs (1, draft)**: branch `repo-assist/perf-collections-dashboard-eager-load-2026-07-01` (commit `5d7e675c`). PR number not yet visible to GitHub MCP search; `create_pull_request` returned `success` and the patch/bundle survive locally.
- **Open issues**: ~22 from MCP scan; net new since prior run is the maintainer's cleanup cascade (#1790 + #1794-#1798). All an-lee-authored are the maintainer's design plan. Auto-generated ones include #1792, #1781, #1780, #1779, #1778, #1776, #1771, #1720. No human-submitted this run.
- **Concern testing**: 11 of 12 model concerns covered. 1 remains: `rich_text_content` (ActionText + Ransacker SQL + `track_content_change`).
- **Prior `repo-assist` PRs (merged this run)**: #1782 (poster_generator), #1785 (swappable), #1788 (authenticatable).
- **PR #1787**: does not exist on GitHub. The prior run hit the protected-files wall (the runner did not have `contents: write` on AGENTS.md). The AGENTS.md convention is still un-codified — issue #1778 remains OPEN, with the convention enforced only in PR review memory.

## This run (28505722701)

- **Selected tasks**: Task 2, Task 3 (fallback to Task 2), Task 8, plus Task 11.
- **Task 2 (engagement)**: Commented on #1792 (`User#linked_identities`). Three codebase-specific notes (per-provider `external_id` validation; suggested extending `UserAuthorization` rather than adding a second identity table; encryption posture from #1771 audit). Did NOT engage on #1780 (Efficiency Improver already had substantive comment), #1720 (similar — auto-proposal awaits maintainer signal), or #1790 (an-lee posted a tracking comment + sub-issues immediately; engagement on the 6 design questions would be AI-on-AI noise).
- **Task 8 (perf)**: `Dashboard::CollectionsController#index` N+1 fix. Branch `repo-assist/perf-collections-dashboard-eager-load-2026-07-01` (commit `5d7e675c`). 1 file, +6/-1. `.includes(:currency, cover_attachment: :blob)` collapses 3 per-row SELECTs into 3 follow-up SELECTs; load is O(N)+3 instead of 3N+1. `bin/rails zeitwerk:check` clean, `bin/rubocop app/controllers/dashboard/collections_controller.rb` clean. PR opened in draft (number not yet visible).
- **Task 11**: Updated #1789 (Monthly Activity 2026-07). Refreshed Suggested Actions: removed the three merged PRs (#1782, #1785, #1788), added the new perf branch entry, added a "Check comment on #1792" action, moved the `find_or_create_user_by_auth` bug from a "future work" note to a review-actionable "Apply one-line fix" action, and added "Close issue #1778" as an action (PR #1787 push rejection documented). Prepended the new run entry at the top of Run History.
- **Task 3**: Substituted as Task 2 per substitution rule (no human-submitted `bug`/`help wanted`/`good first issue` issues).

## Backlog

- Re-engage when human issues appear. All open issues either an-lee design plans or `github-actions[bot]` auto-generated.
- **Concern testing (1 remaining)**: `rich_text_content`. Now blocked only on whether maintainer wants `RichTextContent` concern split from inline `before_save :track_content_change` callback on Article.
- **Latent `find_or_create_user_by_auth` bug** (pinned by merged PR #1788). One-line fix; moved to "Apply one-line fix" Suggested Action in #1789.
- **Issue #1778** (AGENTS.md codify concern-test convention): still OPEN. PR #1787 was attempted 2026-06-30 but the runner couldn't push. The convention is *not codified in AGENTS.md* — the prior memory's claim that "PR #1787 closed #1778" is wrong; AGENTS.md still has no "Concern test files" subsection.
- **Open perf opportunity**: `Dashboard::ArticlesController#index` for the `published` + `hidden` tabs — same N+1 class as the collections fix (3 SELECTs per row from currency + cover). Unaddressed; good next Repo Assist perf candidate.
- **Open perf opportunity (lower priority)**: `Dashboard::TransfersController#index` — `transfer.source.item` polymorphic + `transfer.currency` → 3+ SELECTs per row. Polymorphic disambiguation prevents a one-line fix; deferred (the prior run's `repo-assist/perf-transfers-dashboard-eager-load-2026-07-01` branch with commit `f6ea29cf` is still locally preserved if revival is wanted).
- **Open perf opportunity (moot soon)**: `Dashboard::SwapOrdersController#index` — trivial `.includes(:pay_asset, :fill_asset)`, but Phase 0 (#1794) will remove SwapOrder entirely.
- Respect issue #1571's 5-cycle cooldown on payment/Web3 resilience work.
- #1667 + #1686 + #1694 + #1771 are maintainer-led design discussions; out of scope.
- #1790 + #1794-#1798 are the maintainer's sequenced cleanup plan; out of scope (the maintainer drives them).
- #1792 (linked_identities) now has a Repo Assist comment with concrete extension proposal — wait for maintainer direction.
- **Duplicated perf-improver PRs** (#1783 + #1784): both merged today by the perf-improver workflow, same content different branch slugs. Workflow-determinism issue; deferred.
- **Concern-test convention codified in PR review memory** (NOT in AGENTS.md). Future concern PRs without a colocated test file are still review-actionable, but only against tribal knowledge — issue #1778 should be progressed.

## Notes

- **`bundle outdated` / `dependabot alerts` MCP unreliable** in this sandbox.
- **`bin/rubocop` does NOT lint ERB or YAML.** `bin/rails zeitwerk:check` is the local CI load-path check.
- **`bin/rubocop AGENTS.md` produces 283 false positives** (markdown-as-Ruby). Not a real lint issue.
- **Minitest 6.0.6 quirk**: `Object#stub` removed. Use `define_singleton_method` + `ensure` for class- and instance-method stubs.
- **`Rails.application.credentials` stub**: tiny Struct whose `#dig` returns the configured value, restore in `ensure`.
- **`safeoutputs create_pull_request` PR-number lag**: branch may not appear in `list_pull_requests` for several seconds. Reference new PRs by branch + commit SHA in Monthly Activity summaries if PR number not yet visible. Confirmed in this run — `repo-assist/perf-collections-dashboard-eager-load-2026-07-01` not yet in GitHub MCP search 30+ seconds after `create_pull_request` returned `success`.
- **`safeoutputs update_issue` body limit**: 10 KB hard cap. This run's body was ~8 KB — within budget.
- **`safeoutputs create_pull_request` returns success even when patch path/branch file gets reverted externally**: confirmed 2026-07-01 (transfers perf branch). The branch + commit survive locally even when the file is reverted. Verify with `git show <branch>:<file>` before assuming the change was lost.
- **`PandoBot::Lake::PairRoutes` Integer `route_id` quirk**: `route_id` MUST be Integer. Use `route_id: 1` in stubs.
- **Concern testing pattern**: one canonical instance per concern (Comment for SoftDeletable, Article for Articles::*, MixinPreOrder for PreOrders::*, Order for Orders::*). Pin decision table for predicates; avoid mocking the callback chain.
- **Test env cache pattern**: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore `@previous_cache` in teardown.
- **AR association re-query on update**: `article.update!(association: x)`, `update_columns(association_id: ...)`, even `article.association` re-queries DB and replaces the in-memory object. Singleton-method stubs lost. Use a real persisted record, or skip the branch.
- **Pre-existing CI-clean test errors**: `test/controllers/articles_controller_test.rb` (asset pipeline) and `test/controllers/pre_orders_controller_test.rb` (SSL to Mixpay). CI stubs/supplies them.
- **`User#available_articles` perf**: push `.uniq` to SQL via `.or.or.distinct` (PR #1735).
- **`includes(:currency).sum(...)` antipattern**: use `joins(:currency)`. Closed in PR #1737.
- **`Currency#save` raises in test env** because `before_validation :set_defaults` calls `QuillBot.api.asset(asset_id)`. Tests use `Currency.new(price_usd: ...)` in memory.
- `Settings.twitter_account` is `prsdigg` in `config/settings/test.yml`. `QuillBotStub#with_quill_bot_stub` provides `FakeApi` with `FAKE_CLIENT_ID`.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- **GitHub MCP `list_pull_requests` defaults to ascending** — pass `direction: "desc"` for newest-first.
- **MCP `dependabot alerts` quirk**: returns 400 "Pagination using the `page` parameter is not supported". Unreliable.
- **`UserAuthorization` store_accessor quirk**: `auth.name` reads `raw["name"]` — but Mixin API populates `full_name`, not `name`. Always use `auth.raw["full_name"]` in authenticatable code paths. The existing-user branch in `find_or_create_user_by_auth` is broken (passes `auth.name` which is nil). Now pinned by merged PR #1788.
- **ActiveStorage eager-load shape**: `Model.includes(:attached_association, attached_association: :blob)` for a `has_one_attached :attached_association`. Confirmed via `Collection#cover` — `.includes(:currency, cover_attachment: :blob)` collapses the per-row attachment + blob SELECTs.
- **No Postgres in this runner**. `bin/rails test` is unreproducible locally for any controller spec that touches the database; rely on `bin/rails zeitwerk:check` + `bin/rubocop` as the local signal, defer to CI for full suite.
