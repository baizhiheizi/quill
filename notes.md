---
name: repo-assist-notes
description: Persistent notes for Repo Assist workflow runs on baizhiheizi/quill
metadata:
  type: project
  updated: 2026-07-23
---

## Repo Assist — Persistent Notes

### Recurring state
- All open issues are AI-generated audits/tracking/summary issues (no human-submitted bugs/features).
- 6 open issues (closed: #1924 bun.lockb PR-as-issue was already noted as gone in previous run).
- 3 open PRs: #1950 (Dependabot solid_queue 1.5.0), #1951 (code-simplifier), #1952 (test-improver Dashboard::ArticlesControllerTest).
- 1 open Repo Assist draft PR from this run (perf tag_names map fix).
- 2 older Repo Assist draft PRs still pending from 2026-07-20 (dead code cleanup, batch tag lookup).

### Backlog cursor
- No issues to process — all are labelled, none need human engagement.

### Fix attempts and outcomes
- **2026-07-20**: Task 5 PR: `repo-assist/improve-dead-code-cleanup-2026-07-20` — removed Currency#sync! (no-op), PreOrdersController#should_redirect? (dead), Authenticatable concern (empty module). Rubocop clean.
- **2026-07-20**: Task 8 PR: `repo-assist/perf-batch-tag-lookup-2026-07-20` — batched CreateTagService tag lookup. Rubocop clean.
- **2026-07-23**: Task 8 PR: `repo-assist/perf-tag-names-map-2026-07-23` — `tags.pluck(:name)` → `tags.map(&:name)` to use preloaded association cache. 1 file +5/-1. Rubocop clean, 1109 tests pass.

### Suggested items checked off by maintainer
- (None checked off this run)

### Priority action items for next run
- Continue monitoring for human-submitted issues
- If the maintainer engages with any PRs or audits, follow up
- The bun.lockb CI path removal still needs manual revival from patch/bundle on disk
