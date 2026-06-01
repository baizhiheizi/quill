---
name: /test-improver
description: Full Test Improver round-robin run (local substitute for scheduled workflow)
---

# /test-improver

Full Test Improver run locally — round-robin Tasks 1–6 (2–3 per run) plus mandatory Task 7 (monthly activity issue). Equivalent to the scheduled GitHub Agentic Workflow, without GitHub Actions.

## Prerequisites

- `gh auth login` and network access for issues/PRs
- Default branch up to date if you will create branches
- PostgreSQL available for `bin/rails test`

## Steps

1. **Pre-check open PR cap**

   ```bash
   MAX_OPEN_PRS=8
   COUNT=$(gh pr list --state open --search 'in:title "[test-improver]"' --json number --jq 'length')
   ```

   If `COUNT >= MAX_OPEN_PRS`, report to the user and **do not open new test PRs** this run. You may still maintain existing PRs (Task 4) and update the monthly issue (Task 7).

2. Read [AGENTS.md](AGENTS.md).
3. Read [.cursor/test-improver/memory.md](.cursor/test-improver/memory.md); verify stale entries against `gh` and the repo.
4. Follow **Non-Command Mode** and **Workflow** in [.cursor/skills/test-improver/SKILL.md](.cursor/skills/test-improver/SKILL.md):
   - Round-robin: 2–3 tasks least recently run (per memory) + **Task 7 always**
   - Identify as **Test Improver (local Cursor)** in PRs and comments
   - Run History in the monthly issue: `### YYYY-MM-DD HH:MM UTC - Local Cursor run`
5. Update memory at end (commands, maintainer priorities, backlog, task timestamps, WIP, completed work, checked-off items).

## Guardrails

- Respect skill limits: max 4 new PRs/issues per run, max 10 comments, max 3 issue comments in Task 5.
- Skip Task 7 issue update if nothing was done this run.
- Never merge PRs yourself.

For a single focused request, use `/test-assist <instructions>` instead.
