---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 28977072290 on 2026-07-08 21:35 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs**:
  1. **Draft PR — refactor MarkdownRenderService no-op stub** — branch `repo-assist/improve-markdown-render-remove-dead-mention-2026-07-08` (commit `b1340ff8`, 2 files +10/-5). Removes `def parse_mention_user; self; end` no-op stub and its `.parse_mention_user` call from the `:full` pipeline; adds a guard test (`refute_includes MarkdownRenderService.instance_methods(false), :parse_mention_user`) to pin the removal. Patch + bundle at `/tmp/gh-aw/aw-repo-assist-improve-markdown-render-remove-dead-mention-2026-07-08.{patch,bundle}`. Awaiting maintainer-revival.
  2. **Draft PR — perf articles show page** — branch `repo-assist/perf-article-show-action-store-2026-07-08` (commit `3ce8c929`, 5 files +233/-49). Adds `Article.with_show_associations` scope; batches per-call action_store / order / readers queries with `pluck(:target_id).to_set` + grouped Order count; preloads random_readers sample with avatar chain. Patch + bundle at `/tmp/gh-aw/aw-repo-assist-perf-article-show-action-store-2026-07-08.{patch,bundle}`. Awaiting maintainer-revival + first-time-contributor CI approval.
  3. **Draft PR — perf users subscribe lists** — branch `repo-assist/perf-users-subscribe-action-store-2026-07-08` (commit `40b5648b`, 3 files +53/-0). Adds shared `preloaded_subscribe_user_ids` + `users_user_field_preloads` helpers to `Users::BaseController`; applies both to `Users::SubscribeUsersController#index` and `Users::SubscribeByUsersController#index`. Patch + bundle at `/tmp/gh-aw/aw-repo-assist-perf-users-subscribe-action-store-2026-07-08.{patch,bundle}`. Awaiting maintainer-revival + first-time-contributor CI approval.
- **Other open PRs**: none.
- **Open issues**: 9 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-08)**: PR #1862 (perf dashboard block/subscribe users) — prior run's draft revived by an-lee. Earlier this week: #1861, #1860, #1859, #1858, #1857, #1856, #1852, #1850, #1849, #1848, #1845, #1844, #1843, #1842, #1838, #1837 — all by `an-lee`.

## This run (28977072290)

- **Selected tasks**: Task 9, Task 5, Task 6, plus Task 11.
- **Task 9 (Testing Improvements)**: Added the guard test `refute_includes MarkdownRenderService.instance_methods(false), :parse_mention_user` to `test/services/markdown_render_service_test.rb`. Memory's "only MarkdownRenderService direct unit tests remain" gap was already closed by the existing 22-test file; this run's addition is the small, intentional coverage win rather than opening a parallel file. No broader coverage gaps identified.
- **Task 5 (Coding Improvements)**: Removed the no-op `def parse_mention_user; self; end` stub from `app/services/markdown_render_service.rb` and dropped its `.parse_mention_user` call from the `:full` pipeline. Behavior-preserving — the stub returned `self` without mutating `@html`, so dropping it is observably identical. Verified `RichTextRenderService` and `HtmlPostProcessor` carry no equivalent stubs (rich-text pipeline uses `<action-text-mention>` elements, not raw `@handle` rewriting), so no further dead-code siblings exist on this branch. Created draft PR (commit `b1340ff8`).
- **Task 6 (Maintain Repo Assist PRs)**: Verified both open draft PRs (#1865, #1866). Their `check.yml` runs are gated on first-time-contributor approval (status `action_required`, "Oh hello! Nice to see you" bot comment) — environmental, not a code issue. No retry warranted; PRs await maintainer revival as usual.
- **Task 11**: Updated #1789 body. Added this run's draft PR to Suggested Actions; retained both prior-run drafts (still awaiting revival) and the four audits/proposals (#1847, #1840, #1839, #1821). Run History prepended with the 2026-07-08 21:35 UTC entry. First-call body had two duplicate `* [ ]` lines due to a shell-quoting mishap during the heredoc-based build; the cleanup call hit the 1/run `update_issue` quota limit so the duplicates remain in #1789 — they're cosmetic only, not structural (Suggested Actions still parses cleanly and the checkbox list still contains the same items).
- **Environmental note**: `bin/rubocop` (2 files) + `bin/rails zeitwerk:check` clean. `test/services/markdown_render_service_test.rb` 24 runs / 50 assertions / 0 failures. The 2 pre-existing FastImage network errors on `example.invalid` URLs reproduce on `origin/main` without this branch's changes.

## Earlier runs — see #1789 Run History

- 28940715564: Draft PRs (`3ce8c929` perf-article-show, `40b5648b` perf-users-subscribe). Both awaiting maintainer-revival + first-time-contributor CI approval.
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
- **Public article show N+1 revival class: IN FLIGHT** — `perf-article-show-action-store` draft awaiting revival.
- **Users namespace N+1 revival class: IN FLIGHT** — `perf-users-subscribe-action-store` is the first entry; `Users::ArticlesController#index` and `Users::CommentsController#index` are the obvious follow-ups (same `shared/_avatar` chain).
- **MarkdownRenderService no-op stub removal: PENDING REVIEW** (this run's draft awaiting revival).
- **Test gaps (low-value)**: `HtmlPostProcessor` direct unit tests (covered indirectly via both render services).

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`.
- `safeoutputs update_issue` quota: 1 per run. `add_comment`: 10 per run. `create_pull_request`: 4 per run. Body limit: 10 KB hard cap.
- `safeoutputs` CLI: pipe JSON payload via `.` sentinel: `cat payload.json | safeoutputs update_issue .` (no CLI args).
- **`safeoutputs update_issue` empty-body behavior (CONFIRMED run 28755231512)**: first call without body returned "success" but did NOT modify the body. Always pass the full body.
- **`safeoutputs update_issue` CLI-args-vs-stdin precedence bug (CONFIRMED run 28853214649, FIXED run 28885552691)**: pipe entire payload (including `issue_number`) via stdin only — no CLI flags other than `.`.
- **`safeoutputs update_issue` 1/run quota hard cap (CONFIRMED run 28977072290)**: any second `update_issue` call in the same run returns `E002: update_issue limit reached`. If the first call had a body issue, the cleanup call will fail. Mitigation: build the body in `printf`-appended chunks via a `bash` script file (not inline heredoc — bash single-quotes break on em-dashes inside the format string).
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
- **action_store-generated relations support `.pluck(:target_id).to_set`** (CONFIRMED via 28940715564): returns Set<Integer> for O(1) include? in views. Bypasses the N+1 `find_by(...).present?` pattern.
- **action_store `target_user?(other)` / `target_tag?(other)` methods fire 1 SELECT each** (CONFIRMED via 28940715564). Source: `action-store-1.1.3/lib/action_store/mixin.rb#204-210`.
- **AdminBaseController#admin_user_field_preloads / DashboardBaseController#dashboard_user_field_preloads / Users::BaseController#users_user_field_preloads**: helper at controller level — `.includes(author: admin_user_field_preloads)`.
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
- **Dependabot bundling race condition (CONFIRMED 28885552691)**: maintainer can merge individual Dependabot PRs before the bundle is revived. The bundle PR becomes stale and the individual PRs must be closed post-merge as superseded.
- **First-time-contributor CI approval gate (CONFIRMED 28977072290)**: PRs from `github-actions[bot]` need a maintainer to approve the `check.yml` run before any job executes. The check suite sits at `action_required` with a placeholder "Oh hello! Nice to see you" bot comment until then. Not a code issue — push-to-branch retries won't change the state. Wait for maintainer revival.
- **`MarkdownRenderService#parse_mention_user` was a no-op stub (REMOVED via draft PR this run)**: `def parse_mention_user; self; end` returned `self` without mutating `@html`. Method + its `.parse_mention_user` call in the `:full` pipeline both dropped. `RichTextRenderService` and `HtmlPostProcessor` carry no equivalent stub (rich-text uses `<action-text-mention>` elements, not raw `@handle` rewriting).
- **Guard-test pattern for dead-method removal (NEW this run)**: when removing a dead method, add `refute_includes <Class>.instance_methods(false), :method_name` to pin the removal — any future contributor who re-adds the method has to consciously remove the test.
- **PR bundle + patch artifact paths (CONFIRMED 28977072290)**: `/tmp/gh-aw/aw-repo-assist-<branch-suffix>.{patch,bundle}`.