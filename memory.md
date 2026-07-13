---
name: repo-assist-memory
description: Repo Assist run state, completed work, open backlog, monthly issue, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run 29250823128 on 2026-07-13 12:53 UTC.** Repo: baizhiheizi/quill (Rails 8.1, Ruby 4.0.5). AGENTS.md exists.
- **Open Repo Assist PRs**:
  1. **Draft PR — dead-code sweep round 2** — branch `repo-assist/cleanup-dead-code-2026-07-13` (commit `6e0e4d15`, 3 files +6/-22). Drops `User#mixin_deposit_url` (only invoked from its own self-referential test), `User delegate :public_key` (zero callers in app/lib/test; `authorization.public_key` is encrypted at rest), and `RenderingHelper#render_flash` (zero callers; `flashes/flash` partial appended via `turbo_stream.append` inline in callers). Adds a guard test pinning the deletion (`User#removed dead methods stay removed`). `bin/rubocop` (3 files) + `bin/rails zeitwerk:check` clean. `bin/rails test test/models/user_test.rb` 37 runs / 87 assertions / 0 failures (was 36/85, +1 run / +2 assertions from guard test). Patch + bundle at `/tmp/gh-aw/aw-repo-assist-cleanup-dead-code-2026-07-13.{patch,bundle}`. Awaiting maintainer revival.
- **Other open PRs**: #1877 (Dependabot pagy 43.5.6→43.6.0), #1878 (Dependabot typescript 6.0.3→7.0.2), #1879 (docs unbloat background-jobs.md, automation).
- **Open issues**: 7 (all AI-generated). #1789 (Monthly Activity) updated.
- **Recent merges (2026-07-08 → 2026-07-13)**: #1886 (perf admin mixin network snapshot index chains), #1884 (deps aws-sdk-s3 1.226→1.227), #1885 (docs content storage guide), #1883 (test Oauth::MixinAdapter + FlashBroadcast), #1882 (refactor dead constants/helpers), #1880 (perf article cover preload + dashboard/users migration), #1876 (perf dashboard comments + subscribe_articles indexes), #1874 (perf article with_associations author avatar), #1873 (test API ValidUsersController#filter), #1872 (refactor masthead mr-24), #1871 (perf users articles/comments preloads), #1870 (fix masthead mr-24), #1869 (Extract revenue logic from article_form_controller), #1868 (admin collections article counts prime), #1867 (MarkdownRenderService no-op stub removal), #1866 (users subscribe lists), #1865 (article show action_store), #1864 (with_all_transfers_generated! consolidation), #1862 (dashboard block/subscribe users). All by `an-lee`.

## This run (29250823128)

- **Selected tasks**: Task 5, Task 3, Task 2, plus Task 11.
- **Task 5 (Coding Improvements)**: Created draft PR (commit `6e0e4d15`) deleting 3 more pieces of dead code (round 2 of #1789 sweep): `User#mixin_deposit_url` + `User delegate :public_key` + `RenderingHelper#render_flash`. Each verified zero-callers via grep across `app/`, `lib/`, `test/`. Adds a guard test pinning the removal. 3 files +6/-22.
- **Task 3 (Issue Fix)**: Substituted → no fixable issues. All 7 open issues are AI-generated (Monthly activity summaries from sister agents, no-op run tracker, threat-detection tracker, audit PR-as-issues blocked by file-protection policy).
- **Task 2 (Issue Comment)**: Substituted → no-op. No human-submitted issues to engage on.
- **Task 11**: Updated #1789. Added this run's dead-code sweep round 2 draft to Suggested Actions; added the new run entry to Run History (prepended). Future Work: marked "Dead-code sweep round 2" COMPLETE.

## Backlog

- **Concern testing**: `rich_text_content` — blocked on whether maintainer wants the concern split from inline `before_save :track_content_change` callback.
- **Issue #1717** (bundle graphql+lexxy): bundle patch is stale — suggested action: close. Awaiting maintainer ack.
- **Issue #1821** (BigDecimal/DistributeService audit, F1-F12): F9 closed via #1828. F1/F2/F3 still HIGH; contingent offer in #1821 comment awaiting maintainer ack.
- Respect #1571 5-cycle cooldown on payment/Web3 resilience.
- #1667 + #1686 + #1694 + #1771 + #1790 + #1794-#1798: maintainer-led design discussions, out of scope.
- **N+1 revival classes: ALL COMPLETE**: Dashboard-#index (#1802/#1815/#1829/#1830/#1833/#1862), Admin-#index (#1834/#1837/#1845/#1862/#1868), Public article show (#1865), Users namespace (#1866/#1871), Article-feed avatar chain (#1874), Article-feed cover blob (#1880, merged 2026-07-10), MarkdownRenderService no-op stub (#1867).
- **Dead-code sweep round 1**: COMPLETE — PR #1882 (commit `0c470542`, merged 2026-07-10 by an-lee).
- **Dead-code sweep round 2**: COMPLETE — this run (commit `6e0e4d15`).
- **Test gaps**: Oauth::MixinAdapter COMPLETE (#1883); DeliveryMethods::FlashBroadcast COMPLETE (#1883). Low-value remaining: `HtmlPostProcessor` direct unit tests (covered indirectly via both render services).

## Notes

- `bin/rubocop` does NOT lint ERB/YAML. `bin/rails zeitwerk:check` is the local CI load-path check.
- Minitest 6.0.6: `Object#stub` removed — use `define_singleton_method` + `ensure`.
- `safeoutputs` quotas: `update_issue` 1/run, `add_comment` 10/run, `create_pull_request` 4/run. Body limit: 10 KB hard cap.
- `safeoutputs` CLI: pipe JSON payload via `.` sentinel: `safeoutputs <cmd> . < /tmp/gh-aw/agent/payload.json`. Use stdin-from-file pattern; inline `printf` + pipe breaks on backticks/apostrophes in markdown.
- **`safeoutputs update_issue` quota hard cap**: only 1 successful call per run. Build full body in one shot.
- Test env cache: `Rails.cache = ActiveSupport::Cache::MemoryStore.new` in setup, restore in teardown.
- AR association re-query on update: `article.association` re-queries DB and replaces in-memory object. Singleton-method stubs lost.
- `Currency#save` raises in test env. Use `Currency.new(price_usd: ...)` in memory.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring.
- `ERB::Util.url_decode` does not exist in Rails 8.1; use `CGI.unescape`.
- GitHub MCP `list_pull_requests` defaults to ascending — pass `direction: "desc"`.
- `mcp__github__list_issues` output too large: 70+ KB for 12 issues. Use a saved file path and parse with python.
- **`UserAuthorization` store_accessor quirk (RESOLVED via PR #1811)**: always use `auth.raw["full_name"]`.
- **ActiveStorage eager-load shape for `has_one_attached` + variant**: `Model.includes(:attached_association, attached_association: { blob: { variant_records: { image_attachment: :blob }, preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } } } })`.
- **Polymorphic nested preload shape**: `.includes(:commentable, :author, commentable: :author)` for Comment → commentable. Also `.includes(:currency, source: { item: :author })` for Transfer.
- action_store-generated relations support `.includes` (CONFIRMED via #1833) and `.pluck(:target_id).to_set` (CONFIRMED via 28940715564). `target_user?` / `target_tag?` fire 1 SELECT each — avoid in partials.
- **AdminBaseController#admin_user_field_preloads / DashboardBaseController#dashboard_user_field_preloads / Users::BaseController#users_user_field_preloads**: helper at controller level — `.includes(author: admin_user_field_preloads)`.
- **No Postgres in this runner**. `bin/rails test` unreliable locally for DB-touching specs; rely on `bin/rails zeitwerk:check` + `bin/rubocop`. Model tests DO run locally.
- **`Payment#article` / `#collection` / `#citer` are memo-decoded lookups, NOT AR associations**: cannot be eager-loaded.
- **Maintainer-revival pattern (CONFIRMED via #1815/#1826/#1828/#1829/#1830/#1833/#1837/#1838/#1845/#1862/#1865/#1866/#1867/#1868)**: when `safeoutputs create_pull_request` returns success but no PR opens, the maintainer fetches the local bundle and pushes manually. 3-7 days lag between draft and merge.
- **No-controller-test perf PR pattern**: code + commit-message only — no controller tests.
- **`AdminNotificationService` asymmetry (CONFIRMED via PR #1838 tests)**: `#text` short-circuits on blank credentials; `#post` does NOT.
- **`TextNotificationService` shape**: single `call(text, recipient_id:)` method.
- **`QuillBotStub` singleton-method capture pattern**: `QuillBot.define_singleton_method(:api) { api }` — block captures `api` from enclosing scope. `define_singleton_method(:api) { @stub_api }` fails.
- `enqueued_jobs.first[:job]` returns the class object, NOT a string. Use class equality. `assert_performed_jobs(only: MixinMessages::SendJob)` runs the enqueued job in the test process.
- **`safeoutputs create_pull_request` patch + bundle artifact paths**: `/tmp/gh-aw/aw-<branch-suffix>.{patch,bundle}`. `git format-patch -1 -o /tmp/gh-aw/` then `mv` to canonical name.
- **Dependabot bundling via git merge**: `git merge --no-commit --no-ff origin/dependabot/bundler/<dep>` then `git reset --soft HEAD~N`. Race condition: maintainer can merge individual Dependabot PRs before the bundle is revived.
- **First-time-contributor CI approval gate (CONFIRMED 28977072290 + 28993481069)**: PRs from `github-actions[bot]` need a maintainer to approve `check.yml` before any job executes. Sits at `action_required` until then. Wait for maintainer revival.
- **`MarkdownRenderService#parse_mention_user` was a no-op stub (REMOVED via PR #1867)**: returned `self` without mutating `@html`. Method + its `.parse_mention_user` call in the `:full` pipeline both dropped.
- **Guard-test pattern for dead-method removal**: when removing a dead method, add `refute_includes <Class>.instance_methods(false), :method_name` to pin the removal.
- **`Users::ArticlesController#index` and `Users::CommentsController#index` N+1 closure pattern (NEW 28993481069)**: `.includes(:author, :currency, :tags, cover_attachment: :blob)` for articles; `.includes(:commentable, :author, commentable: :author)` for comments.
- **`Article.with_associations` scope-extension pattern (NEW 29005693993)**: scope reads `includes(:currency, :tags, author: User::AVATAR_PRELOADS)`. Search-feed SELECT-count drops from 4N+1 to ~7.
- **`Article.with_associations` cover-preload extension (NEW 29052269991)**: scope reads `includes(:currency, :tags, cover_attachment: :blob, author: User::AVATAR_PRELOADS)`. Duplicate key in `with_show_associations` is merged by Rails. Dashboard / Users tabs' SELECT-count drops from ~5N+1 to ~7 for a pagy page of 50.
- **`Minitest::Mock` is gone in Minitest 6.0.6**: use `Object.new` + `define_singleton_method` + a closure-captured flag, then assert on the flag. Pattern in `test/notifiers/delivery_methods/flash_broadcast_test.rb`. The deleted memory note about `Object#stub` still applies for general stubs.
- **`deep_stringify_keys` does not coerce values**: only keys are stringified. Integer values stay integer. Test should assert on keys, not on stringified values.
- **Dead-constant confidence ladder**: before deleting, grep across `app/`, `lib/`, AND `test/`. Constants referenced only in tests = safe to delete with the test reference.
- **Deletion-only PRs are the maintainer's preferred refactor style**: see #1867, #1872, #1864, #1869, #1882.
- **Dead-method confidence ladder (NEW 29250823128)**: before deleting a Ruby method, grep across `app/views/`, `app/controllers/`, `app/jobs/`, `app/services/`, `app/libs/`, `app/notifiers/`, AND `test/`. Methods referenced only in their own self-referential test = safe to delete with the test reference AND a guard test pinning the removal (`refute_includes <Class>.instance_methods(false), :method_name`).
