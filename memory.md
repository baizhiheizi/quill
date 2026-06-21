---
name: repo-assist-memory
description: Repo Assist run state — selected tasks, completed work, open backlog, monthly issue number, and notes
metadata:
  type: project
---

# Repo Assist Memory

## Current state

- **Run of repo-assist workflow on 2026-06-21 16:58 UTC (run 27911156543).**
- Repo is baizhiheizi/quill (Rails 8.1, Ruby 4.0.5).
- AGENTS.md exists; read before any code PR.
- **All prior PRs from earlier runs are merged**: PRs #1682, #1684, #1689, #1690, #1691, #1692, #1693, #1695, #1696, #1698, #1699, #1700, #1701, #1702, #1703, #1704, #1705, #1707, #1708, #1709, #1710.
- **Open PRs at run start**: none.
- **New PR from this run**: `repo-assist/fix-preview-upload-audio-fallback` (commit `25b7d974`). Patch: `/tmp/gh-aw/aw-repo-assist-fix-preview-upload-audio-fallback.patch` (1799 bytes, 44 lines). Bundle: `/tmp/gh-aw/aw-repo-assist-fix-preview-upload-audio-fallback.bundle` (1130 bytes).

## Selected tasks for this run (2026-06-21, run 27911156543)

- **Task 5 (Coding Improvements)** — found a clearly beneficial, low-risk fix: pre-existing audio-fallback bug in `app/javascript/controllers/preview_upload_controller.js` line 37. The `case "audio":` branch's `innerHTML` fallback emitted a `<video>` element (copy-paste from the branch above). Switched to `<audio>`, matching the matched-target path and case label. Same class of fix as PR #1709. **PR opened** (`repo-assist/fix-preview-upload-audio-fallback`, commit `25b7d974`, 1 file, 2+/2-).
- **Task 9 (Testing Improvements)** — not applicable. 3 notifiers (`collection_listed`, `payment_refunded`, `swap_order_finished`) still lack dedicated tests. `test-improver` is the natural owner (issue #1517 last updated 2026-06-21) and runs frequently. Deferring to avoid duplicating its work.
- **Task 4 (Engineering Investments)** — not applicable. Dependabot queue is clean (nokogiri 1.19.4, faraday 2.14.3, mini_racer 0.21.3, kamal 2.12.0 all recently bumped). Specialized `efficiency-improver`/`perf-improver`/`repository-quality-improver` workflows own the natural engineering work.
- **Task 11 (Update Monthly Activity Summary)** — posted run entry on issue #1564 via `safeoutputs add_comment` (temporary_id `aw_zKWdT2bz`).

## Completed this run (run 27911156543)

- Posted run entry on issue #1564 via `safeoutputs add_comment` (temporary_id `aw_zKWdT2bz`).
- Opened draft PR `repo-assist/fix-preview-upload-audio-fallback` (commit `25b7d974`) for the audio-fallback `<video>` → `<audio>` fix.

## Selected tasks for prior run (2026-06-20, run 27870715573)

- **Task 5 (Coding Improvements)** — 4 dead `data-controller="player"` / `data-player-target="media"` references in `preview_upload_controller.js`. **PR opened** (`repo-assist/remove-dead-player-controller-refs`, commit `0140ad72`). **Merged as PR #1709.**
- Other tasks not applicable: 8 open issues all auto-generated, 0 unlabelled, Dependabot queue clean, perf-improver own work, latent `Currency` JSONB bug deferred per maintainer signal.
- Posted run entry on issue #1564 (temporary_id `aw_run_27870715`).

## Selected tasks for prior run (2026-06-19 22:00 UTC, run 27849427694)

- **Task 5** — defined `Settings.icon_file` (PR #1700, merged).
- **Task 6** — verified open Repo Assist PRs clean.
- **Task 9** — 8 tests for `SubscribeUserActionCreatedNotifier` (PR #1701, merged).

## Open issue landscape (6 open at run start, all auto-generated)

- #1636 ([aw] Detection Runs), #1567 ([aw] No-Op Runs), #1564 ([repo-assist] Monthly Activity 2026-06), #1561 ([efficiency-improver] Monthly Activity 2026-06), #1517 ([test-improver] Monthly Activity 2026-06), #1513 ([perf-improver] Monthly Activity 2026-06)
- **No human-submitted issues to engage on.**

## Open PRs

- **NEW this run**: `repo-assist/fix-preview-upload-audio-fallback` (commit `25b7d974`) — switches the audio-fallback `innerHTML` from `<video>` to `<audio>`. Patch: `/tmp/gh-aw/aw-repo-assist-fix-preview-upload-audio-fallback.patch` (1799 B, 44 lines). Bundle: `/tmp/gh-aw/aw-repo-assist-fix-preview-upload-audio-fallback.bundle` (1130 B). PR number assigned by workflow runner.

## Backlog / future work

- Re-engage when human issues appear. Watch for first-time contributors; welcome them and point to README/CONTRIBUTING.
- 3 notifiers in `app/notifiers/` still lack dedicated tests: `collection_listed`, `payment_refunded`, `swap_order_finished`. Test-improver is the natural owner; defer.
- **Latent `Currency#store :raw` JSONB bug, confirmed reproducible in prior runs**: `currency.name` / `currency.icon_url` raise `TypeError: no implicit conversion of Hash into String` on freshly loaded records. The fix pattern (manual accessors) exists but the maintainer has not actioned prior attempts; not re-attempting.
- **Settings inconsistency fully resolved**: dead `logo_file` / `favicon_file` removed from `config/settings/test.yml` (PR #1698); `Settings.icon_file` defined in `config/settings.yml` (PR #1700); dead `|| "icon.png"` fallbacks removed at all 5 call sites (PR #1705, still open).
- Respect issue #1571's 5-cycle cooldown on payment/Web3 resilience work.
- The natural notifier-testing / efficiency / perf work is handled by other workflows (test-improver, efficiency-improver, perf-improver) at higher fidelity than repo-assist can match.
- #1667 + #1686 (Authorization Boundary Hygiene) and #1694 (Webhook/Callback/Payment-Replay Integrity) describe maintainer-led design discussions; out of scope for unilateral repo-assist PRs.
- 858b5779 production Solid Cache/Cable/Queue SQLite migration opens up future work to verify there's no SQLITE_BUSY contention with multi-container Kamal deploys (maintainer-led).
- **Pre-existing audio-fallback bug** in `preview_upload_controller.js` line 37: the audio-fallback `innerHTML` emitted a `<video>` element instead of `<audio>`. **Fixed in this run** by PR `repo-assist/fix-preview-upload-audio-fallback` (commit `25b7d974`).

## Notes

- `gh aw compile` produces a `.patch` + `.bundle` artefact under `/tmp/gh-aw/`; PR finalised by workflow runner via `safeoutputs create_pull_request`. The actual PR number is assigned by the workflow runner, so PR-intent items reference branch + commit + patch path.
- `update_issue` body size limit is 10 KB; queued body updates from `schedule` / `workflow_dispatch` are unreliable. Monthly Activity update is therefore being delivered via `add_comment` for reliability.
- `bin/rubocop` and `bin/rails zeitwerk:check` run successfully locally. `bin/rubocop` does **not** lint ERB files (no `erb-lint`) or YAML files. When verifying changes touching only ERB/YAML, skip from rubocop invocation — CI uses the same config.
- `ERB::Util.url_decode` does **not** exist in Rails 8.1; use `CGI.unescape` for round-tripping `ERB::Util.url_encode` output in tests.
- `User#create_action` (from the `action-store` gem) returns a boolean, not the `Action` record. To get an Action instance in tests, instantiate `Action.create!(action_type:, user:, target:, user_type: "User", target_type: "User")` directly. `Action#after_create :notify_target` is the production hook; in notifier tests that re-deliver manually, wrap the `create!` in `Action.skip_callback :create, :after, :notify_target` … `Action.set_callback …` (with `ensure`) to avoid doubling every event/job count.
- Noticed 3 with a `record: <model>` param fails with `NoMethodError: undefined method 'has_query_constraints?' for class TrueClass` if `record` is not a real ActiveRecord instance. Always pass an actual AR record.
- `Settings.twitter_account` is configured in `config/settings/test.yml` as `prsdigg`; tests assert against this value (the `Config::Options` class does not support mocha's `.stubs`).
- The `QuillBotStub#with_quill_bot_stub` helper in `test/support/quill_bot_stub.rb` provides a `FakeApi` with the standard `FAKE_CLIENT_ID` (`d4444444-4444-4444-8444-444444444444`).
- Module-vs-class constant ownership: when a module is the sole consumer of a constant, prefer `module M; CONST = ...; end` over `module M; CONST = SomeIncluder::CONST; end`. The former keeps the dependency direction natural.
- Stimulus controller dead-code detection must scan for both `data-controller="xxx"` and `data-controller='xxx'` (single quotes), the `controller: 'xxx'` Rails helper invocation, and JS assignments like `element.dataset["controller"] = "xxx"` — they set the same dead attribute programmatically and were missed by view-only grep scans in prior runs. Use `re.findall(r'data-controller=["\']([^"\']+)["\']', content)`.
- The `bin/ci` script uses `ActiveSupport::ContinuousIntegration` with steps: `Setup`, `Style: Ruby` (rubocop), `Style: JavaScript` (bun lint-check), `Tests: Rails`, `Tests: Seeds`.
- `Action` model extends `ActiveRecord::Base` directly (not `ApplicationRecord`), uses polymorphic `target`/`user` with `optional: true`, and has `after_create :notify_target` + `before_destroy :destroy_notifications`. Wrap in `skip_callback`/`set_callback` for notifier tests.
- `config/routes.rb` includes a domain redirect for `prsdigg.com|bunshow.jp` → `https://quill.im/$path` at the top; preserve when refactoring routes.
- GitHub's "unstable" mergeable_state for draft PRs is often transient — full CI hasn't necessarily been run yet on draft PRs. Use `git merge-tree <merge-base> <main> <branch>` locally to confirm there are no real conflicts before treating it as a problem.
- For JS-only changes, the local-toolchain equivalent of `bun run lint-check` is `node_modules/.bin/prettier --check app/javascript/<changed-file>`; `node esbuild.config.js` produces the same bundle CI builds (and prints one pre-existing `DEP0180` deprecation warning unrelated to changes).
