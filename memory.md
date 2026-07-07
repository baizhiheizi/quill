---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 28885552691 on 2026-07-07 16:30 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs**:
  1. **Draft PR — Bundle Dependabot #1849 + #1850** — branch `repo-assist/eng-bundle-deps-2026-07-07-graphql-lexxy` (commit `55cb1805`, 2 files +8/-8). Single Gemfile/Gemfile.lock change covering `graphql 2.6.3 → 2.6.5` (skips yanked 2.6.4; AsyncDataloader fix) and `lexxy 0.9.22 → 0.9.23` (paste cell shading strip, table toolbar a11y). Patch + bundle at `/tmp/gh-aw/aw-repo-assist-eng-bundle-deps-2026-07-07-graphql-lexxy.{patch,bundle}`. Awaiting maintainer-revival.
- **Other open PRs**: #1849 (Dependabot: graphql 2.6.3→2.6.5), #1850 (Dependabot: lexxy 0.9.22→0.9.23) — both superseded by the bundle PR once it merges.
- **Open issues**: 11 (all AI-generated). New since prior run: #1847 (Rate Limiting & Abuse Prevention audit, 16 findings, top 7 HIGH).
- **Recent merges (2026-07-07)**: PR #1845 (admin articles avatar preload, last admin N+1 — commit `2182ef51`), #1837 (admin N+1 sweep), #1838 (admin/text notification tests), #1842 (aasm 5.5.2→6.0.0, major version) — all merged by `an-lee`.

## This run (28885552691)

- **Selected tasks**: Task 4, Task 3, Task 2, plus Task 11.
- **Task 4 (Engineering Investments)**: Bundled Dependabot #1849 + #1850 into a single PR (commit `55cb1805`). Both patch-level safe updates within existing `~>` constraints. `safeoutputs create_pull_request` returned success; PR opening hit the maintainer-revival pattern (no #1851 visible). Patch + bundle preserved.
- **Task 3 (Issue Fix)**: No `bug` / `help wanted` / `good first issue` issues open. Substituted to Task 2.
- **Task 2 (Issue Comment)**: No engagement opportunities. All 11 open issues are AI-generated proposals/audits or system-managed tracking issues. Substituted (no-op).
- **Task 11**: Updated #1789 body (7,288 bytes — under 10 KB cap) via stdin-only `safeoutputs update_issue` pattern. Suggested Actions pruned: removed merged #1837/#1838/#1842/#1845; added "Close Dependabot PR #1849 + #1850" actions referencing the bundle; added #1847 audit; retained #1839, #1840, #1821.

## Previous run (28853214649)

- **Selected tasks**: Task 10, Task 2, Task 1, plus Task 11.
- Draft PR (one-line admin articles avatar preload, commit `c2dd8e67`). Closes the last admin `Article.with_associations`-based N+1. Per-request SELECT estimate (pagy page of 50): ~50–200 extra avatar-chain SELECTs/req → 0. **Merged 2026-07-07 as PR #1845.**
- Task 11: **FAILED body update** — `--issue_number` CLI flag overshadowed stdin body. Fallback: posted run summary as `add_comment` on #1789. **The stdin-only pattern (corrected this run) verified working.**

## Previous run (28825462623)

- **Selected tasks**: Task 4, Task 3, Task 2, plus Task 11.
- Task 4: No actionable item this run. Single Dependabot PR (#1842, aasm 5.5.2→6.0.0) was a major-version bump with `whiny_persistence: true` default flip — risky to bundle without maintainer sign-off. Substituted (no-op).
- Task 11: Updated #1789 body (7,756 bytes).

## Previous run (28780541117)

- **Selected tasks**: Task 8, Task 2, Task 9, plus Task 11.
- Draft PR #1837 (admin N+1 sweep, commit `7e49c304`). **Merged 2026-07-07 as PR #1837.**
- Draft PR #1838 (15 tests / 51 assertions for AdminNotificationService + TextNotificationService). **Merged 2026-07-07 as PR #1838.**
- Task 11: Updated #1789 body (9,665 bytes).

## Earlier runs — see #1789 Run History

- 28755231512: PR #1833 (subscribe/comments dashboard eager-load) merged 2026-07-06 01:56 UTC by `an-lee`.
- 28699967377: PR #1830 (payments eager-load) merged 2026-07-04 08:23 UTC. Commented on #1717.
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
- **Dashboard-#index N+1 revival class: COMPLETE** (#1802/#1815/#1829/#1830/#1833 — all merged).
- **Admin-#index N+1 revival class: COMPLETE** (Orders/Payments/Transfers/Bonuses in main + #1837 merged + #1845 merged).
- **Test gaps (low-value)**: Only `MarkdownRenderService` direct unit tests remain (existing file 212 lines; nothing to add).

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`.
- `safeoutputs update_issue` quota: 1 per run. `add_comment`: 10 per run. `create_pull_request`: 4 per run. Body limit: 10 KB hard cap.
- `safeoutputs` CLI: `--body @-` and `@filename` DO NOT expand — pipe a JSON payload via the `.` sentinel: `printf '{...}' | safeoutputs update_issue .` (or `add_comment .`).
- **`safeoutputs update_issue` empty-body behavior (CONFIRMED run 28755231512)**: first call without body returned "success" but did NOT modify the body. Always pass the full body in the first call.
- **`safeoutputs update_issue` CLI-args-vs-stdin precedence bug (CONFIRMED run 28853214649, FIXED run 28885552691)**: when `--issue_number NNN` is passed as a CLI flag AND stdin has a JSON payload with `body`, the CLI uses ONLY the CLI args — the stdin body is dropped. **Fix: pipe the entire payload (including `issue_number`) via stdin only — no CLI flags other than `.`:** `cat payload.json | safeoutputs update_issue .` where `payload.json = {"body": "...", "issue_number": 1789}`.
- **Test env cache**: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore in teardown.
- **AR association re-query on update**: `article.association` re-queries DB and replaces in-memory object. Singleton-method stubs lost.
- `Currency#save` raises in test env (`QuillBot.api.asset(asset_id)` in `before_validation`). Use `Currency.new(price_usd: ...)` in memory.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`.
- `mcp__github__list_issues` output too large: 70+ KB for 12 issues. Use a saved file path and parse with python.
- **`UserAuthorization` store_accessor quirk (RESOLVED via PR #1811)**: `auth.name` reads `raw["name"]` — but Mixin API populates `full_name`, not `name`. Always use `auth.raw["full_name"]`.
- **ActiveStorage eager-load shape**: `Model.includes(:attached_association, attached_association: :blob)` for `has_one_attached`.
- **Polymorphic nested preload shape**: `.includes(:commentable, :author, commentable: :author)` for `Comment → commentable (Article) → author`. Also `.includes(:currency, source: { item: :author })` for `Transfer → source (Order) → item (Article/Collection) → author`.
- **action_store-generated relations support `.includes`** (CONFIRMED via #1833): `current_user.commenting_subscribe_articles.includes(:author).order(...)` works as expected.
- **AdminBaseController#admin_user_field_preloads**: reuse the existing helper at the controller level — `.includes(author: admin_user_field_preloads)` — instead of inlining the chain.
- **No Postgres in this runner**. `bin/rails test` unreliable locally for DB-touching specs; rely on `bin/rails zeitwerk:check` + `bin/rubocop`. Pure unit tests (`test/libs/`, `test/services/`) DO run locally. Model tests (DB-backed) ALSO run locally.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded via `includes`.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer can fetch the local bundle and push it manually. Reliable but laggy (3-7 days between draft and merge).
- **No-controller-test perf PR pattern**: PRs #1802/#1815/#1829/#1830/#1833/#1837/#1845 — all merged code + commit-message-only — no controller-test file added.
- **`AdminNotificationService` asymmetry (CONFIRMED via PR #1838 tests)**: `#text` short-circuits on blank `Rails.application.credentials.dig(:admin, :group_conversation_id)`; `#post` does NOT short-circuit.
- **`TextNotificationService` shape**: single `call(text, recipient_id:)` method. `QuillBot.api.unique_conversation_id(recipient_id)` resolves to a String.
- **`QuillBotStub` singleton-method capture pattern**: `QuillBot.define_singleton_method(:api) { api }` — the block captures `api` from the enclosing scope. The naive `QuillBot.define_singleton_method(:api) { @stub_api }` form fails.
- **`enqueued_jobs.first[:job]`** returns the class object, NOT a string. Use class equality.
- **`assert_performed_jobs(only: MixinMessages::SendJob)`** runs the enqueued job in the test process.
- **`safeoutputs create_pull_request` patch + bundle pattern**: a successful call returns `{"result":"success","patch":{"path":"/tmp/gh-aw/aw-<branch>.patch","size":N,"lines":M},"bundle":{"path":"/tmp/gh-aw/aw-<branch>.bundle","size":N}}` — these files are the maintainer-revival bundle.
- **Dependabot bundling via git merge** (CONFIRMED this run): use `git merge --no-commit --no-ff origin/dependabot/bundler/<dep>` for each Dependabot branch. After all merges, `git reset --soft HEAD~N` to squash into one commit.
- **Dependabot constraint bumps**: include the Gemfile + Gemfile.lock update together. `~> 0.9.22` does NOT allow 0.9.23.