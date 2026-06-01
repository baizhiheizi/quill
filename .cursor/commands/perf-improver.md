---
name: /perf-improver
description: Full Perf Improver round-robin run (local substitute for scheduled workflow)
---

# /perf-improver

Full Perf Improver run locally — round-robin Tasks 1–6 (2–3 per run) plus mandatory Task 7 (monthly activity issue). Equivalent to the scheduled GitHub Agentic Workflow, without GitHub Actions.

## Prerequisites

- `gh auth login` and network access for issues/PRs
- Default branch up to date if you will create branches
- PostgreSQL available if Task 3 may run tests

## Steps

1. **Pre-check open PR cap**

   ```bash
   MAX_OPEN_PRS=8
   COUNT=$(gh pr list --state open --search 'in:title "[perf-improver]"' --json number --jq 'length')
   ```

   If `COUNT >= MAX_OPEN_PRS`, report to the user and **do not open new perf PRs** this run. You may still maintain existing PRs (Task 4) and update the monthly issue (Task 7).

2. Read [AGENTS.md](AGENTS.md).
3. Read [.cursor/perf-improver/memory.md](.cursor/perf-improver/memory.md); verify stale entries against `gh` and the repo.
4. Follow **Non-Command Mode** and **Workflow** in [.cursor/skills/perf-improver/SKILL.md](.cursor/skills/perf-improver/SKILL.md):
   - Round-robin: 2–3 tasks least recently run (per memory) + **Task 7 always**
   - Identify as **Perf Improver (local Cursor)** in PRs and comments
   - Run History in the monthly issue: `### YYYY-MM-DD HH:MM UTC - Local Cursor run`
5. Update memory at end (commands, backlog, task timestamps, WIP, completed work, checked-off items).

## Guardrails

- Respect skill limits: max 4 new PRs/issues per run, max 10 comments, max 3 issue comments in Task 5.
- Skip Task 7 issue update if nothing was done this run.
- Never merge PRs yourself.

For a single focused request, use `/perf-assist <instructions>` instead.
